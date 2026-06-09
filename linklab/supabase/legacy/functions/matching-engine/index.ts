import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 匹配權重配置
const MATCHING_WEIGHTS = {
  urgency: 0.30,      // 緊急度
  distance: 0.25,     // 地理距離
  skills: 0.20,       // 技能匹配
  credit: 0.15,       // 信譽分
  intimacy: 0.10,     // 歷史親密度
};

// 緊急度映射值
const URGENCY_VALUES: Record<string, number> = {
  normal: 0.4,
  important: 0.6,
  urgent: 0.8,
  emergency: 1.0,
};

// 地球半徑（km）
const EARTH_RADIUS_KM = 6371;

interface Location {
  lat: number;
  lng: number;
}

interface VolunteerProfile {
  id: string;
  user_id: string;
  skills: string[];
  level: number;
  points: number;
  credit_score: number;
  is_online: boolean;
  is_available: boolean;
  latitude: number;
  longitude: number;
  last_heartbeat_at: string;
}

interface MatchResult {
  id: string;
  userId: string;
  score: number;
  distance: number;
  skills: string[];
  creditScore: number;
  intimacyScore: number;
}

/**
 * 主入口函數
 */
export async function matchingEngine(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname;

    // 路由分發
    if (path.endsWith('/matching-engine') && req.method === 'POST') {
      return await handleMatching(req);
    } else if (path.endsWith('/matching-engine/timeout') && req.method === 'POST') {
      return await handleTimeout(req);
    } else if (path.endsWith('/matching-engine/accept') && req.method === 'POST') {
      return await handleAccept(req);
    } else if (path.endsWith('/matching-engine/reject') && req.method === 'POST') {
      return await handleReject(req);
    }

    return new Response(
      JSON.stringify({ error: 'Not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Matching engine error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 處理匹配請求
 */
async function handleMatching(req: Request): Promise<Response> {
  const supabase = createSupabaseClient(req);
  const body = await req.json();

  const {
    seekerId,
    urgency = 'normal',
    location,
    skills = [],
    helpType = '一般求助',
    excludeVolunteers = [], // 已拒絕的志願者ID列表
  } = body;

  if (!seekerId || !location) {
    return new Response(
      JSON.stringify({ error: 'Missing required parameters: seekerId, location' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 1. 創建求助記錄
  const helpRequest = await createHelpRequest(supabase, {
    seekerId,
    urgency,
    location,
    skills,
    helpType,
  });

  // 2. 獲取在線志願者
  const volunteers = await getOnlineVolunteers(supabase, location, excludeVolunteers);

  if (volunteers.length === 0) {
    // 無可用的志願者，轉爲異步
    await convertToAsync(supabase, helpRequest.id);
    return new Response(
      JSON.stringify({
        success: false,
        helpRequestId: helpRequest.id,
        message: 'No available volunteers, converted to async task',
        convertedToAsync: true,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 3. 計算匹配分數
  const matches = calculateMatchScores(volunteers, {
    urgency,
    location,
    skills,
    seekerId,
  });

  // 4. 獲取Top 5
  const topMatches = matches.slice(0, 5);

  // 5. 創建匹配記錄併發送推送
  await createMatchRecordsAndNotify(supabase, helpRequest.id, topMatches);

  // 6. 返回結果
  const timeoutAt = new Date(Date.now() + 60 * 1000); // 60秒超時

  return new Response(
    JSON.stringify({
      success: true,
      helpRequestId: helpRequest.id,
      volunteers: topMatches.map(m => ({
        id: m.id,
        userId: m.userId,
        score: Math.round(m.score * 100) / 100,
        distance: Math.round(m.distance * 100) / 100,
        skills: m.skills,
      })),
      timeoutAt: timeoutAt.toISOString(),
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 處理超時/擴大搜索範圍
 */
async function handleTimeout(req: Request): Promise<Response> {
  const supabase = createSupabaseClient(req);
  const body = await req.json();

  const { helpRequestId, expandRange = false } = body;

  if (!helpRequestId) {
    return new Response(
      JSON.stringify({ error: 'Missing helpRequestId' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 獲取求助記錄
  const { data: helpRequest, error } = await supabase
    .from('help_requests')
    .select('*')
    .eq('id', helpRequestId)
    .single();

  if (error || !helpRequest) {
    return new Response(
      JSON.stringify({ error: 'Help request not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  if (expandRange) {
    // 擴大搜索範圍至Top 10
    const location = {
      lat: helpRequest.location_lat,
      lng: helpRequest.location_lng,
    };

    // 獲取已拒絕的志願者
    const { data: rejectedMatches } = await supabase
      .from('help_request_matches')
      .select('volunteer_id')
      .eq('help_request_id', helpRequestId)
      .eq('status', 'rejected');

    const excludeVolunteers = rejectedMatches?.map(m => m.volunteer_id) || [];

    // 重新獲取志願者（擴大範圍）
    const volunteers = await getOnlineVolunteers(supabase, location, excludeVolunteers, 10);

    if (volunteers.length > 0) {
      // 計算匹配分數
      const matches = calculateMatchScores(volunteers, {
        urgency: helpRequest.urgency,
        location,
        skills: helpRequest.required_skills || [],
        seekerId: helpRequest.seeker_id,
      });

      // 獲取新的志願者（排除已推送過的）
      const { data: existingMatches } = await supabase
        .from('help_request_matches')
        .select('volunteer_id')
        .eq('help_request_id', helpRequestId);

      const existingIds = new Set(existingMatches?.map(m => m.volunteer_id) || []);
      const newMatches = matches.filter(m => !existingIds.has(m.id)).slice(0, 5);

      if (newMatches.length > 0) {
        // 發送給新的志願者
        await createMatchRecordsAndNotify(supabase, helpRequestId, newMatches);

        const newTimeoutAt = new Date(Date.now() + 30 * 1000);

        return new Response(
          JSON.stringify({
            success: true,
            expanded: true,
            newVolunteersCount: newMatches.length,
            timeoutAt: newTimeoutAt.toISOString(),
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }
  }

  // 轉爲異步留言
  await convertToAsync(supabase, helpRequestId);

  return new Response(
    JSON.stringify({
      success: true,
      expanded: false,
      convertedToAsync: true,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 處理志願者接單
 */
async function handleAccept(req: Request): Promise<Response> {
  const supabase = createSupabaseClient(req);
  const body = await req.json();

  const { helpRequestId, volunteerId } = body;

  if (!helpRequestId || !volunteerId) {
    return new Response(
      JSON.stringify({ error: 'Missing required parameters' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 使用事務確保只有一個志願者能接單
  const { data: updatedRequest, error } = await supabase
    .from('help_requests')
    .update({
      volunteer_id: volunteerId,
      status: 'connected',
      matched_at: new Date().toISOString(),
    })
    .eq('id', helpRequestId)
    .eq('status', 'matching') // 確保只有在matching狀態才能接單
    .select()
    .single();

  if (error || !updatedRequest) {
    // 可能已被其他志願者接單
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Request already accepted by another volunteer',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 更新匹配記錄狀態
  await supabase
    .from('help_request_matches')
    .update({ status: 'accepted' })
    .eq('help_request_id', helpRequestId)
    .eq('volunteer_id', volunteerId);

  // 拒絕其他志願者
  await supabase
    .from('help_request_matches')
    .update({ status: 'expired' })
    .eq('help_request_id', helpRequestId)
    .neq('volunteer_id', volunteerId)
    .eq('status', 'pending');

  // 發送通知給求助者
  await notifySeekerMatched(supabase, helpRequestId, volunteerId);

  return new Response(
    JSON.stringify({
      success: true,
      helpRequestId,
      volunteerId,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 處理志願者拒絕
 */
async function handleReject(req: Request): Promise<Response> {
  const supabase = createSupabaseClient(req);
  const body = await req.json();

  const { helpRequestId, volunteerId } = body;

  // 更新匹配記錄
  await supabase
    .from('help_request_matches')
    .update({ status: 'rejected' })
    .eq('help_request_id', helpRequestId)
    .eq('volunteer_id', volunteerId);

  return new Response(
    JSON.stringify({ success: true }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * 創建Supabase客戶端
 */
function createSupabaseClient(req: Request) {
  const authHeader = req.headers.get('Authorization') || '';
  const token = authHeader.replace('Bearer ', '');

  return createClient(
    Deno.env.get('SUPABASE_URL') || '',
    Deno.env.get('SUPABASE_ANON_KEY') || '',
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    }
  );
}

/**
 * 創建求助記錄
 */
async function createHelpRequest(
  supabase: any,
  params: {
    seekerId: string;
    urgency: string;
    location: Location;
    skills: string[];
    helpType: string;
  }
) {
  const { data, error } = await supabase
    .from('help_requests')
    .insert({
      seeker_id: params.seekerId,
      type: 'realtime_voice',
      urgency: params.urgency,
      status: 'matching',
      location_lat: params.location.lat,
      location_lng: params.location.lng,
      required_skills: params.skills,
      help_type: params.helpType,
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to create help request: ${error.message}`);
  }

  return data;
}

/**
 * 獲取在線志願者
 */
async function getOnlineVolunteers(
  supabase: any,
  location: Location,
  excludeIds: string[] = [],
  limit: number = 20
): Promise<VolunteerProfile[]> {
  // 計算5分鐘前的時間
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

  let query = supabase
    .from('volunteer_profiles')
    .select('*')
    .eq('is_online', true)
    .eq('is_available', true)
    .not('latitude', 'is', null)
    .not('longitude', 'is', null)
    .gte('last_heartbeat_at', fiveMinutesAgo);

  if (excludeIds.length > 0) {
    query = query.not('id', 'in', `(${excludeIds.join(',')})`);
  }

  const { data, error } = await query.limit(limit);

  if (error) {
    console.error('Error fetching volunteers:', error);
    return [];
  }

  return data || [];
}

/**
 * 計算匹配分數
 */
function calculateMatchScores(
  volunteers: VolunteerProfile[],
  params: {
    urgency: string;
    location: Location;
    skills: string[];
    seekerId: string;
  }
): MatchResult[] {
  const urgencyValue = URGENCY_VALUES[params.urgency] || 0.4;

  return volunteers.map(volunteer => {
    // 1. 緊急度分數（所有志願者相同）
    const urgencyScore = urgencyValue;

    // 2. 距離分數（使用Haversine公式）
    const distance = calculateHaversineDistance(
      params.location.lat,
      params.location.lng,
      volunteer.latitude,
      volunteer.longitude
    );
    const distanceScore = Math.max(0, 1 - Math.min(distance / 5, 1)); // 5km內線性衰減

    // 3. 技能匹配分數
    const skillScore = calculateSkillMatch(params.skills, volunteer.skills);

    // 4. 信譽分數
    const creditScore = (volunteer.credit_score || 5) / 5;

    // 5. 歷史親密度分數（這裏簡化處理，實際應查詢歷史配對記錄）
    const intimacyScore = 0.5; // 默認值

    // 加權計算總分
    const totalScore =
      MATCHING_WEIGHTS.urgency * urgencyScore +
      MATCHING_WEIGHTS.distance * distanceScore +
      MATCHING_WEIGHTS.skills * skillScore +
      MATCHING_WEIGHTS.credit * creditScore +
      MATCHING_WEIGHTS.intimacy * intimacyScore;

    return {
      id: volunteer.id,
      userId: volunteer.user_id,
      score: totalScore,
      distance,
      skills: volunteer.skills || [],
      creditScore: volunteer.credit_score || 5,
      intimacyScore,
    };
  }).sort((a, b) => b.score - a.score); // 按分數降序排序
}

/**
 * Haversine公式計算兩點間距離
 */
function calculateHaversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS_KM * c;
}

function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * 計算技能匹配度
 */
function calculateSkillMatch(required: string[], volunteerSkills: string[]): number {
  if (required.length === 0) return 1; // 無特定技能要求，視爲完全匹配
  if (volunteerSkills.length === 0) return 0;

  const matched = required.filter(skill =>
    volunteerSkills.some(vs => vs.toLowerCase() === skill.toLowerCase())
  ).length;

  return matched / required.length;
}

/**
 * 創建匹配記錄併發送推送通知
 */
async function createMatchRecordsAndNotify(
  supabase: any,
  helpRequestId: string,
  matches: MatchResult[]
) {
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 60 * 1000); // 60秒後過期

  // 創建匹配記錄
  const matchRecords = matches.map((match, index) => ({
    help_request_id: helpRequestId,
    volunteer_id: match.id,
    match_score: match.score,
    distance: match.distance,
    status: 'pending',
    priority: index + 1, // 優先級順序
    notified_at: now.toISOString(),
    expires_at: expiresAt.toISOString(),
  }));

  await supabase.from('help_request_matches').insert(matchRecords);

  // 發送推送通知（通過調用push-notifier函數）
  for (const match of matches) {
    try {
      await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/push-notifier`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({
          type: 'matching_request',
          userId: match.userId,
          title: '有新的求助需要您的幫助',
          body: `距離您 ${match.distance.toFixed(1)}km 有人需要幫助，匹配度 ${Math.round(match.score * 100)}%`,
          data: {
            helpRequestId,
            type: 'matching_request',
            priority: 'high',
          },
        }),
      });
    } catch (error) {
      console.error(`Failed to notify volunteer ${match.id}:`, error);
    }
  }
}

/**
 * 轉爲異步任務
 */
async function convertToAsync(supabase: any, helpRequestId: string) {
  // 更新求助記錄
  await supabase
    .from('help_requests')
    .update({ status: 'async_pending' })
    .eq('id', helpRequestId);

  // 創建異步任務
  await supabase.from('async_tasks').insert({
    help_request_id: helpRequestId,
    status: 'pending',
    deadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24小時
  });
}

/**
 * 通知求助者已匹配
 */
async function notifySeekerMatched(supabase: any, helpRequestId: string, volunteerId: string) {
  // 獲取求助者信息
  const { data: helpRequest } = await supabase
    .from('help_requests')
    .select('seeker_id')
    .eq('id', helpRequestId)
    .single();

  if (!helpRequest) return;

  // 獲取志願者信息
  const { data: volunteer } = await supabase
    .from('volunteer_profiles')
    .select('user_id, level')
    .eq('id', volunteerId)
    .single();

  if (!volunteer) return;

  // 發送推送
  try {
    await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/push-notifier`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      },
      body: JSON.stringify({
        type: 'matching_confirmed',
        userId: helpRequest.seeker_id,
        title: '志願者已接單',
        body: '有志願者接受了您的求助，即將開始通話',
        data: {
          helpRequestId,
          volunteerId,
          type: 'matching_confirmed',
        },
      }),
    });
  } catch (error) {
    console.error('Failed to notify seeker:', error);
  }
}
