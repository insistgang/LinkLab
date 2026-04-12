// 志愿者匹配引擎 Edge Function
// 简化版MVP实现：匹配分 = 0.5×紧急度 + 0.5×地理距离

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 紧急度映射
const urgencyMap: Record<string, number> = {
  'normal': 0.4,
  'important': 0.6,
  'urgent': 0.8,
  'emergency': 1.0,
};

// 志愿者类型定义
interface Volunteer {
  id: string;
  user_id: string;
  skills: string[];
  credit_score: number;
  is_online: boolean;
  is_verified: boolean;
  location_lat: number;
  location_lng: number;
  current_help_count: number;
  last_active_at: string;
}

// 匹配请求类型
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

// 匹配结果类型
interface MatchedVolunteer extends Volunteer {
  score: number;
  distance: number;
}

/**
 * 计算两点间的距离（单位：公里）
 * 使用Haversine公式
 */
function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371; // 地球半径（公里）
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

/**
 * 计算匹配分数
 * MVP简化版：匹配分 = 0.5×紧急度 + 0.5×地理距离
 */
function calculateScore(
  volunteer: Volunteer,
  request: MatchingRequest
): { score: number; distance: number } {
  const urgencyScore = urgencyMap[request.urgency] || 0.4;

  // 计算地理距离
  const distance = calculateDistance(
    request.location.lat,
    request.location.lng,
    volunteer.location_lat,
    volunteer.location_lng
  );

  // 距离分数：5km内线性衰减，超出为0
  const distanceScore = Math.max(0, 1 - distance / 5);

  // MVP简化算法
  const score = urgencyScore * 0.5 + distanceScore * 0.5;

  return { score, distance };
}

/**
 * 查询在线志愿者
 */
async function queryOnlineVolunteers(supabase: any): Promise<Volunteer[]> {
  const { data, error } = await supabase
    .from('volunteer_profiles')
    .select('*')
    .eq('is_online', true)
    .eq('is_verified', true)
    .lt('current_help_count', 3) // 最多同时帮助3人
    .gt('last_active_at', new Date(Date.now() - 5 * 60 * 1000).toISOString()); // 5分钟内活跃

  if (error) {
    throw new Error(`查询志愿者失败: ${error.message}`);
  }

  return data || [];
}

/**
 * 创建求助记录
 */
async function createHelpRequest(
  supabase: any,
  request: MatchingRequest,
  matchedVolunteers: MatchedVolunteer[]
): Promise<string> {
  const { data, error } = await supabase
    .from('help_requests')
    .insert({
      seeker_id: request.seekerId,
      urgency: request.urgency,
      location_lat: request.location.lat,
      location_lng: request.location.lng,
      skills_needed: request.skills || [],
      help_type: request.helpType || 'general',
      status: 'matching',
      matched_volunteers: matchedVolunteers.map(v => v.id),
    })
    .select('id')
    .single();

  if (error) {
    throw new Error(`创建求助记录失败: ${error.message}`);
  }

  return data.id;
}

/**
 * 发送推送通知给志愿者
 */
async function sendPushNotifications(
  supabase: any,
  volunteers: MatchedVolunteer[],
  helpRequestId: string,
  helpType: string
): Promise<void> {
  const notifications = volunteers.map(v => ({
    user_id: v.user_id,
    type: 'help_request',
    title: '有新的求助需要您的帮助',
    body: `求助类型: ${helpType}，距离您 ${v.distance.toFixed(1)}km`,
    data: {
      help_request_id: helpRequestId,
      distance: v.distance,
      priority: 'high',
    },
    created_at: new Date().toISOString(),
  }));

  const { error } = await supabase.from('push_notifications').insert(notifications);

  if (error) {
    console.error('推送通知失败:', error);
  }
}

/**
 * 主处理函数
 */
async function handleMatching(req: Request): Promise<Response> {
  try {
    // 解析请求
    const request: MatchingRequest = await req.json();

    // 验证必填字段
    if (!request.seekerId || !request.urgency || !request.location) {
      return new Response(
        JSON.stringify({ error: '缺少必填字段: seekerId, urgency, location' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 创建Supabase客户端
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 1. 查询在线志愿者
    const volunteers = await queryOnlineVolunteers(supabase);

    if (volunteers.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: '当前没有在线志愿者',
          code: 'NO_VOLUNTEERS_AVAILABLE',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. 计算匹配分数并排序
    const ranked: MatchedVolunteer[] = volunteers
      .map(v => {
        const { score, distance } = calculateScore(v, request);
        return { ...v, score, distance };
      })
      .filter(v => v.distance <= 5) // 只保留5km内的志愿者
      .sort((a, b) => b.score - a.score);

    // 3. 取Top 5
    const topVolunteers = ranked.slice(0, 5);

    if (topVolunteers.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: '5km范围内没有可用志愿者',
          code: 'NO_VOLUNTEERS_IN_RANGE',
          suggestion: '扩大搜索范围或转为异步留言',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. 创建求助记录
    const helpRequestId = await createHelpRequest(supabase, request, topVolunteers);

    // 5. 发送推送通知
    await sendPushNotifications(
      supabase,
      topVolunteers,
      helpRequestId,
      request.helpType || '一般求助'
    );

    // 6. 返回结果
    return new Response(
      JSON.stringify({
        success: true,
        helpRequestId,
        matchedCount: topVolunteers.length,
        volunteers: topVolunteers.map(v => ({
          id: v.id,
          userId: v.user_id,
          score: v.score,
          distance: v.distance,
          skills: v.skills,
        })),
        timeoutAt: new Date(Date.now() + 30 * 1000).toISOString(), // 30秒超时
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('匹配引擎错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 处理匹配超时（扩大搜索范围）
 */
async function handleTimeout(req: Request): Promise<Response> {
  try {
    const { helpRequestId, expandRange } = await req.json();

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 获取原求助记录
    const { data: helpRequest, error } = await supabase
      .from('help_requests')
      .select('*')
      .eq('id', helpRequestId)
      .single();

    if (error || !helpRequest) {
      return new Response(
        JSON.stringify({ error: '求助记录不存在' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (expandRange) {
      // 扩大搜索范围到10km
      const { data: moreVolunteers } = await supabase
        .from('volunteer_profiles')
        .select('*')
        .eq('is_online', true)
        .eq('is_verified', true)
        .not('id', 'in', `(${helpRequest.matched_volunteers.join(',')})`);

      // 重新计算匹配
      const request: MatchingRequest = {
        seekerId: helpRequest.seeker_id,
        urgency: helpRequest.urgency,
        location: {
          lat: helpRequest.location_lat,
          lng: helpRequest.location_lng,
        },
      };

      const additionalVolunteers = (moreVolunteers || [])
        .map((v: Volunteer) => {
          const { score, distance } = calculateScore(v, request);
          return { ...v, score, distance };
        })
        .filter((v: MatchedVolunteer) => v.distance <= 10)
        .sort((a: MatchedVolunteer, b: MatchedVolunteer) => b.score - a.score)
        .slice(0, 5);

      // 更新求助记录
      await supabase
        .from('help_requests')
        .update({
          matched_volunteers: [
            ...helpRequest.matched_volunteers,
            ...additionalVolunteers.map((v: MatchedVolunteer) => v.id),
          ],
          search_range: 10,
        })
        .eq('id', helpRequestId);

      // 发送推送
      await sendPushNotifications(
        supabase,
        additionalVolunteers,
        helpRequestId,
        helpRequest.help_type
      );

      return new Response(
        JSON.stringify({
          success: true,
          expanded: true,
          newMatches: additionalVolunteers.length,
          timeoutAt: new Date(Date.now() + 30 * 1000).toISOString(),
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 转为异步留言
    await supabase
      .from('help_requests')
      .update({ status: 'async_pending' })
      .eq('id', helpRequestId);

    // 创建异步任务
    await supabase.from('async_tasks').insert({
      seeker_id: helpRequest.seeker_id,
      help_type: helpRequest.help_type,
      status: 'pending',
      deadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        convertedToAsync: true,
        message: '已转为异步留言，志愿者将在空闲时回复',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('超时处理错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

// Deno serve
Deno.serve(async (req: Request) => {
  // 处理CORS预检
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

  return new Response(
    JSON.stringify({ error: 'Not Found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
