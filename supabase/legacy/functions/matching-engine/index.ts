// 历史实验函数：依赖当前最小 schema 之外的匹配字段、异步任务与 RPC。
// 志願者匹配引擎 Edge Function
// AGENTS.md §4.2 / §4.4：競賽版默認走 Demo 主線；
// 當前真實函數僅與根 supabase/ schema 對齊，不再依賴 linklab/supabase 歷史分叉表。

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface MatchingRequest {
  seekerId: string;
  urgency: string;
  location: {
    lat: number;
    lng: number;
  };
  skills?: string[];
  helpType?: string;
}

interface RankedVolunteer {
  user_id: string;
  name: string | null;
  avatar_url: string | null;
  skills: string[] | null;
  level: number | null;
  credit_score: number | null;
  total_help_count: number | null;
  distance: number;
}

interface AuthenticatedUser {
  id: string;
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

async function authenticateRequest(
  req: Request,
  supabase: ReturnType<typeof createSupabaseClient>,
): Promise<AuthenticatedUser | null> {
  const authorization = req.headers.get('authorization') || '';
  if (!authorization.startsWith('Bearer ')) {
    return null;
  }

  const token = authorization.slice('Bearer '.length).trim();
  if (!token) {
    return null;
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return null;
  }

  return { id: data.user.id };
}

async function rankVolunteers(
  supabase: ReturnType<typeof createSupabaseClient>,
  request: MatchingRequest,
  radiusMeters: number,
): Promise<RankedVolunteer[]> {
  const { data, error } = await supabase.rpc('find_matching_volunteers', {
    seeker_lat: request.location.lat,
    seeker_lng: request.location.lng,
    max_dist: radiusMeters,
    required_skills: request.skills ?? [],
    result_limit: 5,
  });

  if (error) {
    throw new Error(`查詢匹配志願者失敗: ${error.message}`);
  }

  return (data ?? []) as RankedVolunteer[];
}

async function createHelpRequest(
  supabase: ReturnType<typeof createSupabaseClient>,
  request: MatchingRequest,
): Promise<string> {
  const { data, error } = await supabase
    .from('help_requests')
    .insert({
      seeker_id: request.seekerId,
      type: 'realtime_voice',
      intent: request.helpType || '志願者協助',
      urgency: request.urgency,
      status: 'matching',
      help_type: request.helpType || 'general',
      required_skills: request.skills ?? [],
      latitude: request.location.lat,
      longitude: request.location.lng,
      ai_response: {
        source: 'matching-engine',
        mode: 'experimental-real',
      },
    })
    .select('id')
    .single();

  if (error || !data) {
    throw new Error(`創建求助記錄失敗: ${error?.message ?? 'unknown error'}`);
  }

  return data.id as string;
}

async function handleMatching(
  req: Request,
  supabase: ReturnType<typeof createSupabaseClient>,
  user: AuthenticatedUser,
): Promise<Response> {
  try {
    const request = await req.json() as MatchingRequest;

    if (!request.seekerId || !request.urgency || !request.location) {
      return jsonResponse(
        { error: '缺少必填字段: seekerId, urgency, location' },
        400,
      );
    }

    if (request.seekerId !== user.id) {
      return jsonResponse({ error: '不能为其他用户创建求助记录' }, 403);
    }

    const volunteers = await rankVolunteers(supabase, request, 5000);

    if (volunteers.length === 0) {
      return jsonResponse({
        success: false,
        error: '5km範圍內沒有可用志願者',
        code: 'NO_VOLUNTEERS_IN_RANGE',
        suggestion: '請稍候重試，或轉爲異步留言',
      });
    }

    const helpRequestId = await createHelpRequest(supabase, request);

    return jsonResponse({
      success: true,
      helpRequestId,
      matchedCount: volunteers.length,
      volunteers: volunteers.map((volunteer) => ({
        id: volunteer.user_id,
        userId: volunteer.user_id,
        name: volunteer.name ?? '志願者',
        avatarUrl: volunteer.avatar_url,
        score: Math.min(1, Math.max(0, (volunteer.credit_score ?? 5) / 5)),
        distance: volunteer.distance / 1000,
        skills: volunteer.skills ?? [],
      })),
      timeoutAt: new Date(Date.now() + 30 * 1000).toISOString(),
    });
  } catch (error) {
    console.error('匹配引擎錯誤:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleTimeout(
  req: Request,
  supabase: ReturnType<typeof createSupabaseClient>,
  user: AuthenticatedUser,
): Promise<Response> {
  try {
    const { helpRequestId, expandRange } = await req.json() as {
      helpRequestId: string;
      expandRange: boolean;
    };

    if (!helpRequestId) {
      return jsonResponse({ error: '缺少 helpRequestId' }, 400);
    }

    const { data: helpRequest, error } = await supabase
      .from('help_requests')
      .select('id, seeker_id, urgency, latitude, longitude, required_skills, help_type, intent, status')
      .eq('id', helpRequestId)
      .single();

    if (error || !helpRequest) {
      return jsonResponse({ error: '求助記錄不存在' }, 404);
    }

    if (helpRequest.seeker_id !== user.id) {
      return jsonResponse({ error: '无权修改该求助记录' }, 403);
    }

    if (expandRange) {
      const volunteers = await rankVolunteers(
        supabase,
        {
          seekerId: helpRequest.seeker_id as string,
          urgency: (helpRequest.urgency as string | null) ?? 'normal',
          location: {
            lat: Number(helpRequest.latitude ?? 0),
            lng: Number(helpRequest.longitude ?? 0),
          },
          skills: (helpRequest.required_skills as string[] | null) ?? [],
          helpType: (helpRequest.help_type as string | null) ?? 'general',
        },
        10000,
      );

      return jsonResponse({
        success: true,
        expanded: true,
        newVolunteersCount: volunteers.length,
        timeoutAt: new Date(Date.now() + 30 * 1000).toISOString(),
      });
    }

    await supabase
      .from('help_requests')
      .update({ status: 'expired' })
      .eq('id', helpRequestId);

    await supabase.from('async_tasks').insert({
      request_id: helpRequestId,
      seeker_id: helpRequest.seeker_id,
      title: (helpRequest.help_type as string | null) ?? '異步協助',
      description: (helpRequest.intent as string | null) ?? '匹配超時後自動轉爲異步留言',
      type: 'other',
      status: 'pending',
      deadline_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    });

    return jsonResponse({
      success: true,
      convertedToAsync: true,
      message: '匹配超時，已轉爲異步留言',
    });
  } catch (error) {
    console.error('匹配超時處理錯誤:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleAccept(
  req: Request,
  supabase: ReturnType<typeof createSupabaseClient>,
  user: AuthenticatedUser,
): Promise<Response> {
  try {
    const { helpRequestId, volunteerId } = await req.json() as {
      helpRequestId: string;
      volunteerId: string;
    };

    if (!helpRequestId || !volunteerId) {
      return jsonResponse({ error: '缺少 helpRequestId 或 volunteerId' }, 400);
    }

    if (volunteerId !== user.id) {
      return jsonResponse({ error: '不能代替其他志愿者接单' }, 403);
    }

    const { data: volunteer, error: volunteerError } = await supabase
      .from('volunteer_profiles')
      .select('user_id, is_available')
      .eq('user_id', user.id)
      .eq('is_available', true)
      .maybeSingle();

    if (volunteerError) {
      throw new Error(`验证志愿者身份失败: ${volunteerError.message}`);
    }
    if (!volunteer) {
      return jsonResponse({ error: '当前用户不是可接单志愿者' }, 403);
    }

    const { data, error } = await supabase
      .from('help_requests')
      .update({
        volunteer_id: volunteerId,
        status: 'connected',
        matched_at: new Date().toISOString(),
      })
      .eq('id', helpRequestId)
      .eq('status', 'matching')
      .select('id, volunteer_id, status')
      .maybeSingle();

    if (error) {
      throw new Error(`接單失敗: ${error.message}`);
    }

    if (!data) {
      return jsonResponse({
        success: false,
        code: 'ALREADY_CLAIMED',
        message: '該求助已被其他志願者接單或已結束',
      });
    }

    return jsonResponse({
      success: true,
      helpRequestId,
      volunteerId,
      status: data.status,
    });
  } catch (error) {
    console.error('接受匹配失敗:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleReject(
  req: Request,
  user: AuthenticatedUser,
): Promise<Response> {
  try {
    const { helpRequestId, volunteerId } = await req.json() as {
      helpRequestId: string;
      volunteerId: string;
    };

    if (!helpRequestId || !volunteerId) {
      return jsonResponse({ error: '缺少 helpRequestId 或 volunteerId' }, 400);
    }

    if (volunteerId !== user.id) {
      return jsonResponse({ error: '不能代替其他志愿者拒绝求助' }, 403);
    }

    return jsonResponse({
      success: true,
      helpRequestId,
      volunteerId,
      ignored: true,
      message: '根 schema 不再維護逐志願者匹配歷史表，拒絕結果僅用於實驗性客戶端本地狀態。',
    });
  } catch (error) {
    console.error('拒絕匹配失敗:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const supabase = createSupabaseClient();
  const user = await authenticateRequest(req, supabase);
  if (!user) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  if (url.pathname === '/matching-engine' && req.method === 'POST') {
    return handleMatching(req, supabase, user);
  }

  if (url.pathname === '/matching-engine/timeout' && req.method === 'POST') {
    return handleTimeout(req, supabase, user);
  }

  if (url.pathname === '/matching-engine/accept' && req.method === 'POST') {
    return handleAccept(req, supabase, user);
  }

  if (url.pathname === '/matching-engine/reject' && req.method === 'POST') {
    return handleReject(req, user);
  }

  return jsonResponse({ error: 'Not Found' }, 404);
});
