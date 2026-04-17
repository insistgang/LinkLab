// =====================================================
// 共感 LinkAble - 推送通知触发 Edge Function
// AGENTS.md §4.2 / §4.4：竞赛版默认走 Demo fallback；
// 真实函数仅使用根 supabase/ schema 中保留的基础设施表。
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface PushMessage {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  priority?: 'high' | 'normal';
}

interface PushResult {
  userId: string;
  success: boolean;
  error?: string;
  messageId?: string;
  mock?: boolean;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function createSupabaseClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
  return createClient(supabaseUrl, supabaseKey);
}

async function getPushTokens(
  supabase: ReturnType<typeof createSupabaseClient>,
  userId: string,
): Promise<string[]> {
  const { data, error } = await supabase
    .from('user_devices')
    .select('fcm_token')
    .eq('user_id', userId)
    .eq('is_active', true)
    .not('fcm_token', 'is', null);

  if (error || !data) {
    console.error(`获取推送令牌失败 [${userId}]`, error);
    return [];
  }

  return data
    .map((item) => item.fcm_token as string | null)
    .filter((token): token is string => token != null && token.trim().length > 0);
}

async function logPush(
  supabase: ReturnType<typeof createSupabaseClient>,
  result: PushResult,
  title: string,
): Promise<void> {
  await supabase.from('push_logs').insert({
    user_id: result.userId,
    title: title.substring(0, 100),
    success: result.success,
    error_msg: result.error,
    message_id: result.messageId,
  });
}

async function sendFCM(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  priority: 'high' | 'normal',
): Promise<{ success: boolean; messageId?: string; error?: string; mock?: boolean }> {
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY') || '';
  if (!fcmServerKey) {
    return {
      success: true,
      messageId: `mock_${Date.now()}`,
      mock: true,
    };
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
        notification: { title, body, sound: 'default' },
        data,
        priority,
      }),
    });

    const result = await response.json();
    if (result.success === 1 || result.message_id) {
      return {
        success: true,
        messageId: result.message_id || result.multicast_id?.toString(),
      };
    }

    return {
      success: false,
      error: result.results?.[0]?.error || 'Unknown FCM error',
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function sendSinglePush(
  supabase: ReturnType<typeof createSupabaseClient>,
  message: PushMessage,
): Promise<PushResult> {
  const { userId, title, body, data = {}, priority = 'normal' } = message;
  const tokens = await getPushTokens(supabase, userId);

  if (tokens.length === 0) {
    const mockResult: PushResult = {
      userId,
      success: true,
      messageId: `mock_${Date.now()}`,
      mock: true,
    };
    await logPush(supabase, mockResult, title);
    return mockResult;
  }

  for (const token of tokens) {
    const result = await sendFCM(token, title, body, data, priority);
    if (result.success) {
      const pushResult: PushResult = {
        userId,
        success: true,
        messageId: result.messageId,
        mock: result.mock,
      };
      await logPush(supabase, pushResult, title);
      return pushResult;
    }
  }

  const failedResult: PushResult = {
    userId,
    success: false,
    error: '所有推送令牌都失败了',
  };
  await logPush(supabase, failedResult, title);
  return failedResult;
}

async function sendBatchPush(
  supabase: ReturnType<typeof createSupabaseClient>,
  messages: PushMessage[],
): Promise<Response> {
  if (!messages.length) {
    return jsonResponse({ error: '消息列表不能为空' }, 400);
  }

  const results = await Promise.all(
    messages.map((message) => sendSinglePush(supabase, message)),
  );
  const successCount = results.filter((item) => item.success).length;

  return jsonResponse({
    success: true,
    summary: {
      total: results.length,
      success: successCount,
      failed: results.length - successCount,
    },
    results,
  });
}

async function handleSOSBroadcast(
  supabase: ReturnType<typeof createSupabaseClient>,
  body: Record<string, unknown>,
): Promise<Response> {
  const urgency = (body.urgency as string | undefined) ?? 'emergency';
  const seekerId =
    (body.seekerId as string | undefined) ??
    (body.helpRequestId as string | undefined) ??
    (body.sosId as string | undefined);

  if (!seekerId) {
    return jsonResponse({ error: '缺少 seekerId / helpRequestId / sosId' }, 400);
  }

  const { data: volunteers, error } = await supabase
    .from('volunteer_profiles')
    .select('user_id')
    .eq('is_online', true)
    .eq('is_verified', true)
    .eq('is_available', true);

  if (error) {
    return jsonResponse({ error: error.message }, 500);
  }

  const messages: PushMessage[] = (volunteers ?? []).map((volunteer) => ({
    userId: volunteer.user_id as string,
    title: urgency == 'emergency' ? '紧急求助' : '新的求助请求',
    body: '有新的求助广播，请尽快查看',
    data: {
      type: 'sos',
      requestId: seekerId,
      urgency,
    },
    priority: 'high',
  }));

  return sendBatchPush(supabase, messages);
}

async function handleLegacyRequest(req: Request): Promise<Response> {
  const body = await req.json() as Record<string, unknown>;
  const supabase = createSupabaseClient();
  const type = (body.type as string | undefined) ?? '';

  if (type == 'sos_broadcast' || type == 'sos_escalation') {
    return handleSOSBroadcast(supabase, body);
  }

  if (type == 'emergency_sms' || type == 'emergency_call') {
    return jsonResponse({
      success: true,
      mock: true,
      message: '竞赛分支保留为可见状态回执，不依赖真实短信/外呼服务。',
    });
  }

  return jsonResponse({ error: '不支持的 push-notifier 请求类型' }, 400);
}

async function handleSinglePush(req: Request): Promise<Response> {
  const body = await req.json() as PushMessage;
  if (!body.userId || !body.title || !body.body) {
    return jsonResponse({ error: '缺少必要参数: userId, title, body' }, 400);
  }

  const supabase = createSupabaseClient();
  const result = await sendSinglePush(supabase, body);
  return jsonResponse(result);
}

async function handleBatchPushRequest(req: Request): Promise<Response> {
  const body = await req.json() as { messages?: PushMessage[] };
  const messages = body.messages ?? [];
  const supabase = createSupabaseClient();
  return sendBatchPush(supabase, messages);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);

  if (url.pathname === '/push-notifier' && req.method === 'POST') {
    return handleLegacyRequest(req);
  }

  if (url.pathname === '/push-notifier/send' && req.method === 'POST') {
    return handleSinglePush(req);
  }

  if (url.pathname === '/push-notifier/batch' && req.method === 'POST') {
    return handleBatchPushRequest(req);
  }

  if (url.pathname === '/push-notifier/sos' && req.method === 'POST') {
    const supabase = createSupabaseClient();
    const body = await req.json() as Record<string, unknown>;
    return handleSOSBroadcast(supabase, body);
  }

  return jsonResponse({ error: 'Not Found' }, 404);
});
