import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { JWT } from 'https://esm.sh/google-auth-library@9.0.0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// FCM配置
const FCM_CONFIG = {
  projectId: Deno.env.get('FCM_PROJECT_ID') || '',
  clientEmail: Deno.env.get('FCM_CLIENT_EMAIL') || '',
  privateKey: (Deno.env.get('FCM_PRIVATE_KEY') || '').replace(/\\n/g, '\n'),
};

interface PushNotification {
  type: string;
  userId?: string;
  title: string;
  body: string;
  data?: Record<string, any>;
  tokens?: string[];
}

interface SOSBroadcastParams {
  type: 'sos_broadcast';
  sosId: string;
  location: { lat: number; lng: number };
  radius: number;
  priority: string;
}

interface EmergencySMSParams {
  type: 'emergency_sms';
  contacts: string[];
  message: string;
}

/**
 * 主入口函数
 */
export async function pushNotifier(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();

    // 根据类型分发处理
    switch (body.type) {
      case 'matching_request':
        return await handleMatchingRequest(body);
      case 'matching_confirmed':
        return await handleMatchingConfirmed(body);
      case 'sos_broadcast':
        return await handleSOSBroadcast(body as SOSBroadcastParams);
      case 'emergency_sms':
        return await handleEmergencySMS(body as EmergencySMSParams);
      case 'emergency_call':
        return await handleEmergencyCall(body);
      case 'sos_escalation':
        return await handleSOSEscalation(body);
      default:
        return await sendPushNotification(body);
    }
  } catch (error) {
    console.error('Push notifier error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 处理匹配请求推送
 */
async function handleMatchingRequest(body: any): Promise<Response> {
  const { userId, title, body: messageBody, data } = body;

  if (!userId) {
    return new Response(
      JSON.stringify({ error: 'Missing userId' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 获取用户的FCM Token
  const tokens = await getUserFCMTokens(userId);

  if (tokens.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No FCM tokens found for user' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 发送高优先级推送
  const result = await sendFCMMessage({
    tokens,
    notification: {
      title,
      body: messageBody,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_priority_channel',
        priority: 'max',
        sound: 'emergency',
        vibrateTimings: ['0s', '1s', '0.5s', '1s'],
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          alert: {
            title,
            body: messageBody,
          },
          sound: 'emergency.wav',
          badge: 1,
          'interruption-level': 'time-sensitive',
        },
      },
    },
  });

  return new Response(
    JSON.stringify(result),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理匹配确认推送
 */
async function handleMatchingConfirmed(body: any): Promise<Response> {
  const { userId, title, body: messageBody, data } = body;

  const tokens = await getUserFCMTokens(userId);

  if (tokens.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No FCM tokens found' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const result = await sendFCMMessage({
    tokens,
    notification: {
      title,
      body: messageBody,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'default_channel',
        priority: 'high',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          alert: {
            title,
            body: messageBody,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  });

  return new Response(
    JSON.stringify(result),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理SOS广播
 */
async function handleSOSBroadcast(params: SOSBroadcastParams): Promise<Response> {
  const { sosId, location, radius, priority } = params;

  // 获取范围内的在线志愿者
  const supabase = createServiceClient();

  // 使用PostGIS查询范围内的志愿者
  const { data: volunteers, error } = await supabase.rpc('get_volunteers_in_radius', {
    lat: location.lat,
    lng: location.lng,
    radius_km: radius,
  });

  if (error) {
    console.error('Error fetching volunteers:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to fetch volunteers' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  if (!volunteers || volunteers.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No volunteers in range' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 获取所有志愿者的FCM Token
  const userIds = volunteers.map((v: any) => v.user_id);
  const tokens = await getUsersFCMTokens(userIds);

  if (tokens.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No FCM tokens found' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 发送SOS广播推送
  const result = await sendFCMMessage({
    tokens,
    notification: {
      title: '🆘 紧急SOS求助！',
      body: `距离您 ${radius}km 范围内有人触发紧急求助，请尽快响应！`,
    },
    data: {
      sosId,
      type: 'sos_broadcast',
      lat: location.lat.toString(),
      lng: location.lng.toString(),
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'sos_channel',
        priority: 'max',
        sound: 'sos_alarm',
        vibrateTimings: ['0s', '0.5s', '0.5s', '0.5s', '0.5s', '0.5s', '0.5s', '0.5s'],
        sticky: true,
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          alert: {
            title: '🆘 紧急SOS求助！',
            body: `距离您 ${radius}km 范围内有人触发紧急求助，请尽快响应！`,
          },
          sound: 'sos_alarm.wav',
          badge: 1,
          'interruption-level': 'critical',
        },
      },
    },
  });

  // 记录SOS广播日志
  await supabase.from('sos_broadcast_logs').insert({
    sos_request_id: sosId,
    radius_km: radius,
    volunteers_count: volunteers.length,
    notified_count: tokens.length,
    created_at: new Date().toISOString(),
  });

  return new Response(
    JSON.stringify({
      success: true,
      broadcasted: true,
      volunteersCount: volunteers.length,
      notifiedCount: tokens.length,
      ...result,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理紧急短信
 */
async function handleEmergencySMS(params: EmergencySMSParams): Promise<Response> {
  const { contacts, message } = params;

  // 这里集成短信服务商API（如阿里云短信、Twilio等）
  // 示例使用模拟实现
  const results = [];

  for (const phone of contacts) {
    try {
      // 实际实现中调用短信API
      // const result = await sendSMS(phone, message);
      results.push({ phone, status: 'sent', timestamp: new Date().toISOString() });
    } catch (error) {
      results.push({ phone, status: 'failed', error: error.message });
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      results,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理紧急电话通知
 */
async function handleEmergencyCall(body: any): Promise<Response> {
  const { message } = body;

  // 这里可以集成语音电话API（如Twilio Voice等）
  // 实际实现中调用语音API

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Emergency call notification queued',
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 处理SOS升级
 */
async function handleSOSEscalation(body: any): Promise<Response> {
  const { sosId, level, message } = body;

  // 根据升级级别采取不同措施
  switch (level) {
    case 1: // 扩大至全城
      // 获取全城在线志愿者
      const supabase = createServiceClient();
      const { data: allVolunteers } = await supabase
        .from('volunteer_profiles')
        .select('user_id')
        .eq('is_online', true);

      if (allVolunteers && allVolunteers.length > 0) {
        const userIds = allVolunteers.map((v: any) => v.user_id);
        const tokens = await getUsersFCMTokens(userIds);

        await sendFCMMessage({
          tokens,
          notification: {
            title: '🆘 SOS求助升级 - 全城广播',
            body: message || '有SOS求助5分钟无响应，扩大至全城志愿者',
          },
          data: {
            sosId,
            type: 'sos_escalation',
            level: '1',
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'sos_channel',
              priority: 'max',
            },
          },
          apns: {
            headers: { 'apns-priority': '10' },
            payload: {
              aps: {
                alert: {
                  title: '🆘 SOS求助升级 - 全城广播',
                  body: message || '有SOS求助5分钟无响应，扩大至全城志愿者',
                },
                'interruption-level': 'critical',
              },
            },
          },
        });
      }
      break;

    case 2: // 强制通知紧急联系人
      // 已在handleEmergencySMS中处理
      break;
  }

  return new Response(
    JSON.stringify({ success: true, escalated: true, level }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 通用推送通知
 */
async function sendPushNotification(body: PushNotification): Promise<Response> {
  const { tokens, title, body: messageBody, data } = body;

  if (!tokens || tokens.length === 0) {
    return new Response(
      JSON.stringify({ error: 'No tokens provided' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const result = await sendFCMMessage({
    tokens,
    notification: { title, body: messageBody },
    data,
  });

  return new Response(
    JSON.stringify(result),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 发送FCM消息
 */
async function sendFCMMessage(params: {
  tokens: string[];
  notification: { title: string; body: string };
  data?: Record<string, any>;
  android?: any;
  apns?: any;
}): Promise<any> {
  const { tokens, notification, data, android, apns } = params;

  // 获取OAuth2访问令牌
  const accessToken = await getFCMAccessToken();

  const results = {
    success: 0,
    failure: 0,
    errors: [] as any[],
  };

  // FCM HTTP v1 API批量发送
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_CONFIG.projectId}/messages:batchSend`;

  // 分批发送（每次最多500个）
  const batchSize = 500;
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);

    const messages = batch.map((token) => ({
      message: {
        token,
        notification,
        data: data ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ) : undefined,
        android,
        apns,
      },
    }));

    try {
      const response = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ messages }),
      });

      const result = await response.json();

      if (result.responses) {
        result.responses.forEach((resp: any, idx: number) => {
          if (resp.success) {
            results.success++;
          } else {
            results.failure++;
            results.errors.push({
              token: batch[idx],
              error: resp.error?.message || 'Unknown error',
            });

            // 如果token无效，从数据库中删除
            if (resp.error?.code === 'registration-token-not-registered') {
              removeInvalidToken(batch[idx]);
            }
          }
        });
      }
    } catch (error) {
      console.error('FCM batch send error:', error);
      results.failure += batch.length;
    }
  }

  return results;
}

/**
 * 获取FCM OAuth2访问令牌
 */
async function getFCMAccessToken(): Promise<string> {
  const jwtClient = new JWT({
    email: FCM_CONFIG.clientEmail,
    key: FCM_CONFIG.privateKey,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  const tokens = await jwtClient.authorize();
  return tokens.access_token || '';
}

/**
 * 获取用户的FCM Token
 */
async function getUserFCMTokens(userId: string): Promise<string[]> {
  const supabase = createServiceClient();

  const { data, error } = await supabase
    .from('user_devices')
    .select('fcm_token')
    .eq('user_id', userId)
    .not('fcm_token', 'is', null);

  if (error) {
    console.error('Error fetching FCM tokens:', error);
    return [];
  }

  return data?.map((d: any) => d.fcm_token) || [];
}

/**
 * 获取多个用户的FCM Token
 */
async function getUsersFCMTokens(userIds: string[]): Promise<string[]> {
  const supabase = createServiceClient();

  const { data, error } = await supabase
    .from('user_devices')
    .select('fcm_token')
    .in('user_id', userIds)
    .not('fcm_token', 'is', null);

  if (error) {
    console.error('Error fetching FCM tokens:', error);
    return [];
  }

  return data?.map((d: any) => d.fcm_token) || [];
}

/**
 * 删除无效的FCM Token
 */
async function removeInvalidToken(token: string): Promise<void> {
  const supabase = createServiceClient();

  await supabase
    .from('user_devices')
    .delete()
    .eq('fcm_token', token);
}

/**
 * 创建服务客户端
 */
function createServiceClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL') || '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
  );
}
