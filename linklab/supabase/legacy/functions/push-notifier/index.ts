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
 * 主入口函數
 */
export async function pushNotifier(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();

    // 根據類型分發處理
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
 * 處理匹配請求推送
 */
async function handleMatchingRequest(body: any): Promise<Response> {
  const { userId, title, body: messageBody, data } = body;

  if (!userId) {
    return new Response(
      JSON.stringify({ error: 'Missing userId' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 獲取用戶的FCM Token
  const tokens = await getUserFCMTokens(userId);

  if (tokens.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No FCM tokens found for user' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 發送高優先級推送
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
 * 處理匹配確認推送
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
 * 處理SOS廣播
 */
async function handleSOSBroadcast(params: SOSBroadcastParams): Promise<Response> {
  const { sosId, location, radius, priority } = params;

  // 獲取範圍內的在線志願者
  const supabase = createServiceClient();

  // 使用PostGIS查詢範圍內的志願者
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

  // 獲取所有志願者的FCM Token
  const userIds = volunteers.map((v: any) => v.user_id);
  const tokens = await getUsersFCMTokens(userIds);

  if (tokens.length === 0) {
    return new Response(
      JSON.stringify({ success: false, message: 'No FCM tokens found' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 發送SOS廣播推送
  const result = await sendFCMMessage({
    tokens,
    notification: {
      title: '🆘 緊急SOS求助！',
      body: `距離您 ${radius}km 範圍內有人觸發緊急求助，請儘快響應！`,
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
            title: '🆘 緊急SOS求助！',
            body: `距離您 ${radius}km 範圍內有人觸發緊急求助，請儘快響應！`,
          },
          sound: 'sos_alarm.wav',
          badge: 1,
          'interruption-level': 'critical',
        },
      },
    },
  });

  // 記錄SOS廣播日誌
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
 * 處理緊急短信
 */
async function handleEmergencySMS(params: EmergencySMSParams): Promise<Response> {
  const { contacts, message } = params;

  // 這裏集成短信服務商API（如阿里雲短信、Twilio等）
  // 示例使用模擬實現
  const results = [];

  for (const phone of contacts) {
    try {
      // 實際實現中調用短信API
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
 * 處理緊急電話通知
 */
async function handleEmergencyCall(body: any): Promise<Response> {
  const { message } = body;

  // 這裏可以集成語音電話API（如Twilio Voice等）
  // 實際實現中調用語音API

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Emergency call notification queued',
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 處理SOS升級
 */
async function handleSOSEscalation(body: any): Promise<Response> {
  const { sosId, level, message } = body;

  // 根據升級級別採取不同措施
  switch (level) {
    case 1: // 擴大至全城
      // 獲取全城在線志願者
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
            title: '🆘 SOS求助升級 - 全城廣播',
            body: message || '有SOS求助5分鐘無響應，擴大至全城志願者',
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
                  title: '🆘 SOS求助升級 - 全城廣播',
                  body: message || '有SOS求助5分鐘無響應，擴大至全城志願者',
                },
                'interruption-level': 'critical',
              },
            },
          },
        });
      }
      break;

    case 2: // 強制通知緊急聯繫人
      // 已在handleEmergencySMS中處理
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
 * 發送FCM消息
 */
async function sendFCMMessage(params: {
  tokens: string[];
  notification: { title: string; body: string };
  data?: Record<string, any>;
  android?: any;
  apns?: any;
}): Promise<any> {
  const { tokens, notification, data, android, apns } = params;

  // 獲取OAuth2訪問令牌
  const accessToken = await getFCMAccessToken();

  const results = {
    success: 0,
    failure: 0,
    errors: [] as any[],
  };

  // FCM HTTP v1 API批量發送
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_CONFIG.projectId}/messages:batchSend`;

  // 分批發送（每次最多500個）
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

            // 如果token無效，從數據庫中刪除
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
 * 獲取FCM OAuth2訪問令牌
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
 * 獲取用戶的FCM Token
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
 * 獲取多個用戶的FCM Token
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
 * 刪除無效的FCM Token
 */
async function removeInvalidToken(token: string): Promise<void> {
  const supabase = createServiceClient();

  await supabase
    .from('user_devices')
    .delete()
    .eq('fcm_token', token);
}

/**
 * 創建服務客戶端
 */
function createServiceClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL') || '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
  );
}
