// 志愿者匹配引擎 Edge Function
// AGENTS.md §4.2 / §4.4：竞赛版默认走 Demo 主线；
// 当前真实函数仅与根 supabase/ schema 对齐，不再依赖 linklab/supabase 历史分叉表。

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
    throw new Error(`查询匹配志愿者失败: ${error.message}`);
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
      intent: request.helpType || '志愿者协助',
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
    throw new Error(`创建求助记录失败: ${error?.message ?? 'unknown error'}`);
  }

  return data.id as string;
}

async function handleMatching(req: Request): Promise<Response> {
  try {
    const request = await req.json() as MatchingRequest;

    if (!request.seekerId || !request.urgency || !request.location) {
      return jsonResponse(
        { error: '缺少必填字段: seekerId, urgency, location' },
        400,
      );
    }

    const supabase = createSupabaseClient();
    const volunteers = await rankVolunteers(supabase, request, 5000);

    if (volunteers.length === 0) {
      return jsonResponse({
        success: false,
        error: '5km范围内没有可用志愿者',
        code: 'NO_VOLUNTEERS_IN_RANGE',
        suggestion: '请稍候重试，或转为异步留言',
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
        name: volunteer.name ?? '志愿者',
        avatarUrl: volunteer.avatar_url,
        score: Math.min(1, Math.max(0, (volunteer.credit_score ?? 5) / 5)),
        distance: volunteer.distance / 1000,
        skills: volunteer.skills ?? [],
      })),
      timeoutAt: new Date(Date.now() + 30 * 1000).toISOString(),
    });
  } catch (error) {
    console.error('匹配引擎错误:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleTimeout(req: Request): Promise<Response> {
  try {
    const { helpRequestId, expandRange } = await req.json() as {
      helpRequestId: string;
      expandRange: boolean;
    };

    if (!helpRequestId) {
      return jsonResponse({ error: '缺少 helpRequestId' }, 400);
    }

    const supabase = createSupabaseClient();
    const { data: helpRequest, error } = await supabase
      .from('help_requests')
      .select('id, seeker_id, urgency, latitude, longitude, required_skills, help_type, intent, status')
      .eq('id', helpRequestId)
      .single();

    if (error || !helpRequest) {
      return jsonResponse({ error: '求助记录不存在' }, 404);
    }

    if (expandRange) {
      const volunteers = await rankVolunteers(
        supabase,
        {
          seekerId: helpRequest.seeker_id as string,
          urgency: (helpRequest.urgency as string?) ?? 'normal',
          location: {
            lat: Number(helpRequest.latitude ?? 0),
            lng: Number(helpRequest.longitude ?? 0),
          },
          skills: (helpRequest.required_skills as string[]?) ?? [],
          helpType: (helpRequest.help_type as string?) ?? 'general',
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
      title: (helpRequest.help_type as string?) ?? '异步协助',
      description: (helpRequest.intent as string?) ?? '匹配超时后自动转为异步留言',
      type: 'other',
      status: 'pending',
      deadline_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    });

    return jsonResponse({
      success: true,
      convertedToAsync: true,
      message: '匹配超时，已转为异步留言',
    });
  } catch (error) {
    console.error('匹配超时处理错误:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleAccept(req: Request): Promise<Response> {
  try {
    const { helpRequestId, volunteerId } = await req.json() as {
      helpRequestId: string;
      volunteerId: string;
    };

    if (!helpRequestId || !volunteerId) {
      return jsonResponse({ error: '缺少 helpRequestId 或 volunteerId' }, 400);
    }

    const supabase = createSupabaseClient();
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
      throw new Error(`接单失败: ${error.message}`);
    }

    if (!data) {
      return jsonResponse({
        success: false,
        code: 'ALREADY_CLAIMED',
        message: '该求助已被其他志愿者接单或已结束',
      });
    }

    return jsonResponse({
      success: true,
      helpRequestId,
      volunteerId,
      status: data.status,
    });
  } catch (error) {
    console.error('接受匹配失败:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

async function handleReject(req: Request): Promise<Response> {
  try {
    const { helpRequestId, volunteerId } = await req.json() as {
      helpRequestId: string;
      volunteerId: string;
    };

    if (!helpRequestId || !volunteerId) {
      return jsonResponse({ error: '缺少 helpRequestId 或 volunteerId' }, 400);
    }

    return jsonResponse({
      success: true,
      helpRequestId,
      volunteerId,
      ignored: true,
      message: '根 schema 不再维护逐志愿者匹配历史表，拒绝结果仅用于实验性客户端本地状态。',
    });
  } catch (error) {
    console.error('拒绝匹配失败:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);

  if (url.pathname === '/matching-engine' && req.method === 'POST') {
    return handleMatching(req);
  }

  if (url.pathname === '/matching-engine/timeout' && req.method === 'POST') {
    return handleTimeout(req);
  }

  if (url.pathname === '/matching-engine/accept' && req.method === 'POST') {
    return handleAccept(req);
  }

  if (url.pathname === '/matching-engine/reject' && req.method === 'POST') {
    return handleReject(req);
  }

  return jsonResponse({ error: 'Not Found' }, 404);
});
