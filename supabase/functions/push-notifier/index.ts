// =====================================================
// 共感 LinkAble - 推送通知触发 Edge Function
// 功能：处理FCM和厂商推送，支持批量推送
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS头
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 推送消息类型
interface PushMessage {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  priority?: 'high' | 'normal';
  channelId?: string;
}

// 批量推送请求
interface BatchPushRequest {
  messages: PushMessage[];
  retry?: boolean;
}

// 单条推送请求
interface SinglePushRequest {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  priority?: 'high' | 'normal';
}

// 推送结果
interface PushResult {
  userId: string;
  success: boolean;
  error?: string;
  messageId?: string;
}

/**
 * 获取用户的推送令牌
 */
async function getPushTokens(supabase: any, userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('push_tokens')
    .select('token, platform')
    .eq('user_id', userId)
    .eq('is_active', true);

  if (error || !data) {
    console.error(`获取推送令牌失败 [${userId}]:`, error);
    return [];
  }

  return data.map((t: any) => t.token);
}

/**
 * 发送FCM推送
 */
async function sendFCM(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  priority: 'high' | 'normal' = 'normal'
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY') || '';

  if (!fcmServerKey) {
    return { success: false, error: 'FCM Server Key未配置' };
  }

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${fcmServerKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title,
          body,
          sound: 'default',
          badge: '1',
        },
        data,
        priority,
        android: {
          priority: priority === 'high' ? 'high' : 'normal',
          notification: {
            channelId: 'default_channel',
            priority: priority === 'high' ? 'high' : 'default',
          },
        },
        apns: {
          headers: {
            'apns-priority': priority === 'high' ? '10' : '5',
          },
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: 'default',
            },
          },
        },
      }),
    });

    const result = await response.json();

    if (result.success === 1 || result.message_id) {
      return {
        success: true,
        messageId: result.message_id || result.multicast_id?.toString(),
      };
    } else if (result.failure === 1 && result.results?.[0]?.error) {
      const error = result.results[0].error;
      // 令牌无效，需要删除
      if (error === 'NotRegistered' || error === 'InvalidRegistration') {
        return { success: false, error: 'INVALID_TOKEN' };
      }
      return { success: false, error };
    }

    return { success: false, error: 'Unknown FCM error' };
  } catch (error) {
    console.error('FCM推送失败:', error);
    return { success: false, error: error.message };
  }
}

/**
 * 删除无效的推送令牌
 */
async function invalidateToken(supabase: any, token: string): Promise<void> {
  await supabase
    .from('push_tokens')
    .update({ is_active: false, invalidated_at: new Date().toISOString() })
    .eq('token', token);
}

/**
 * 记录推送日志
 */
async function logPush(
  supabase: any,
  userId: string,
  title: string,
  success: boolean,
  error?: string,
  messageId?: string
): Promise<void> {
  await supabase.from('push_logs').insert({
    user_id: userId,
    title: title.substring(0, 100),
    success,
    error_msg: error,
    message_id: messageId,
  });
}

/**
 * 发送单条推送
 */
async function sendSinglePush(
  supabase: any,
  message: PushMessage
): Promise<PushResult> {
  const { userId, title, body, data = {}, priority = 'normal' } = message;

  // 获取用户的推送令牌
  const tokens = await getPushTokens(supabase, userId);

  if (tokens.length === 0) {
    await logPush(supabase, userId, title, false, 'NO_TOKENS');
    return { userId, success: false, error: '用户没有注册推送令牌' };
  }

  // 尝试每个令牌
  for (const token of tokens) {
    const result = await sendFCM(token, title, body, data, priority);

    if (result.success) {
      await logPush(supabase, userId, title, true, undefined, result.messageId);
      return { userId, success: true, messageId: result.messageId };
    }

    // 令牌无效，标记为失效
    if (result.error === 'INVALID_TOKEN') {
      await invalidateToken(supabase, token);
    }
  }

  await logPush(supabase, userId, title, false, 'ALL_TOKENS_FAILED');
  return { userId, success: false, error: '所有推送令牌都失败了' };
}

/**
 * 发送批量推送
 */
async function sendBatchPush(
  supabase: any,
  request: BatchPushRequest
): Promise<Response> {
  const { messages } = request;

  if (!messages || messages.length === 0) {
    return new Response(
      JSON.stringify({ error: '消息列表不能为空' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 限制批量大小
  if (messages.length > 100) {
    return new Response(
      JSON.stringify({ error: '批量推送最多100条消息' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 并发发送(限制并发数)
  const batchSize = 10;
  const results: PushResult[] = [];

  for (let i = 0; i < messages.length; i += batchSize) {
    const batch = messages.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(msg => sendSinglePush(supabase, msg))
    );
    results.push(...batchResults);
  }

  const successCount = results.filter(r => r.success).length;
  const failCount = results.length - successCount;

  return new Response(
    JSON.stringify({
      success: true,
      summary: {
        total: messages.length,
        success: successCount,
        failed: failCount,
      },
      results,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理单条推送请求
 */
async function handleSinglePush(req: Request): Promise<Response> {
  try {
    const body: SinglePushRequest = await req.json();

    // 验证参数
    if (!body.userId || !body.title || !body.body) {
      return new Response(
        JSON.stringify({ error: '缺少必要参数: userId, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    const result = await sendSinglePush(supabase, {
      userId: body.userId,
      title: body.title,
      body: body.body,
      data: body.data,
      priority: body.priority,
    });

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('单条推送错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 处理批量推送请求
 */
async function handleBatchPush(req: Request): Promise<Response> {
  try {
    const body: BatchPushRequest = await req.json();

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    return await sendBatchPush(supabase, body);

  } catch (error) {
    console.error('批量推送错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 处理SOS广播推送
 */
async function handleSOSBroadcast(req: Request): Promise<Response> {
  try {
    const body = await req.json();
    const { seekerId, location, urgency = 'emergency' } = body;

    if (!seekerId || !location) {
      return new Response(
        JSON.stringify({ error: '缺少必要参数: seekerId, location' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 查询在线志愿者
    const { data: volunteers, error } = await supabase
      .from('volunteer_profiles')
      .select('user_id')
      .eq('is_online', true)
      .eq('is_verified', true);

    if (error || !volunteers || volunteers.length === 0) {
      return new Response(
        JSON.stringify({ error: '没有可用的在线志愿者' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 构建广播消息
    const messages: PushMessage[] = volunteers.map((v: any) => ({
      userId: v.user_id,
      title: '紧急求助！',
      body: '附近有用户发起紧急求助，请尽快响应',
      data: {
        type: 'sos',
        seekerId,
        lat: location.lat.toString(),
        lng: location.lng.toString(),
        urgency,
      },
      priority: 'high',
    }));

    // 发送批量推送
    return await sendBatchPush(supabase, { messages });

  } catch (error) {
    console.error('SOS广播错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

// Deno serve
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);

  // 单条推送
  if (url.pathname === '/push-notifier/send' && req.method === 'POST') {
    return handleSinglePush(req);
  }

  // 批量推送
  if (url.pathname === '/push-notifier/batch' && req.method === 'POST') {
    return handleBatchPush(req);
  }

  // SOS广播
  if (url.pathname === '/push-notifier/sos' && req.method === 'POST') {
    return handleSOSBroadcast(req);
  }

  return new Response(
    JSON.stringify({ error: 'Not Found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
