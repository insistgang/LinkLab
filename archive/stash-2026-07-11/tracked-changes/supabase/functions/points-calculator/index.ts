// =====================================================
// 共感 LinkAble - 积分计算 Edge Function
// 功能：监听help_requests变更，自动计算和更新积分
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS头
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 积分配置
const POINTS_CONFIG = {
  // 实时帮助积分
  realtime_help: {
    base: 10,           // 基础积分
    duration_bonus: {   // 时长奖励
      '5min': 5,
      '10min': 10,
      '15min': 15,
      '30min': 25,
    },
    rating_bonus: {     // 评价奖励
      5: 10,
      4: 5,
      3: 2,
      2: 0,
      1: -5,
    },
  },
  // 异步任务积分
  async_task: {
    base: 5,
    priority_bonus: {
      low: 0,
      normal: 2,
      high: 5,
      urgent: 10,
    },
  },
  // SOS紧急帮助积分
  sos_help: {
    base: 20,
    duration_bonus: {
      '5min': 10,
      '10min': 20,
    },
  },
  // 连续签到积分
  daily_signin: {
    base: 1,
    streak_bonus: [0, 0, 1, 1, 2, 2, 5], // 第1-7天额外奖励
  },
};

// 等级配置
const LEVEL_CONFIG = [
  { level: 1, minPoints: 0, title: '新手志愿者' },
  { level: 2, minPoints: 50, title: '初级志愿者' },
  { level: 3, minPoints: 150, title: '中级志愿者' },
  { level: 4, minPoints: 300, title: '高级志愿者' },
  { level: 5, minPoints: 500, title: '资深志愿者' },
  { level: 6, minPoints: 800, title: '专家志愿者' },
  { level: 7, minPoints: 1200, title: '大师志愿者' },
];

/**
 * 计算帮助积分
 */
function calculateHelpPoints(
  helpType: string,
  durationSeconds: number,
  rating: number,
  isSOS: boolean = false
): { points: number; breakdown: any } {
  const breakdown: any = {};
  let totalPoints = 0;

  if (isSOS) {
    // SOS紧急帮助
    const config = POINTS_CONFIG.sos_help;
    totalPoints += config.base;
    breakdown.base = config.base;

    // 时长奖励
    const durationMin = durationSeconds / 60;
    if (durationMin >= 10) {
      totalPoints += config.duration_bonus['10min'];
      breakdown.duration = config.duration_bonus['10min'];
    } else if (durationMin >= 5) {
      totalPoints += config.duration_bonus['5min'];
      breakdown.duration = config.duration_bonus['5min'];
    }
  } else if (helpType === 'realtime_voice' || helpType === 'realtime_video') {
    // 实时帮助
    const config = POINTS_CONFIG.realtime_help;
    totalPoints += config.base;
    breakdown.base = config.base;

    // 时长奖励
    const durationMin = durationSeconds / 60;
    if (durationMin >= 30) {
      totalPoints += config.duration_bonus['30min'];
      breakdown.duration = config.duration_bonus['30min'];
    } else if (durationMin >= 15) {
      totalPoints += config.duration_bonus['15min'];
      breakdown.duration = config.duration_bonus['15min'];
    } else if (durationMin >= 10) {
      totalPoints += config.duration_bonus['10min'];
      breakdown.duration = config.duration_bonus['10min'];
    } else if (durationMin >= 5) {
      totalPoints += config.duration_bonus['5min'];
      breakdown.duration = config.duration_bonus['5min'];
    }

    // 评价奖励
    if (rating && config.rating_bonus[rating as keyof typeof config.rating_bonus] !== undefined) {
      const ratingBonus = config.rating_bonus[rating as keyof typeof config.rating_bonus];
      totalPoints += ratingBonus;
      breakdown.rating = ratingBonus;
    }
  }

  return { points: totalPoints, breakdown };
}

/**
 * 计算异步任务积分
 */
function calculateAsyncTaskPoints(priority: string): { points: number; breakdown: any } {
  const config = POINTS_CONFIG.async_task;
  const breakdown: any = { base: config.base };
  let totalPoints = config.base;

  const priorityBonus = config.priority_bonus[priority as keyof typeof config.priority_bonus] || 0;
  totalPoints += priorityBonus;
  breakdown.priority = priorityBonus;

  return { points: totalPoints, breakdown };
}

/**
 * 根据积分计算等级
 */
function calculateLevel(points: number): { level: number; title: string } {
  for (let i = LEVEL_CONFIG.length - 1; i >= 0; i--) {
    if (points >= LEVEL_CONFIG[i].minPoints) {
      return { level: LEVEL_CONFIG[i].level, title: LEVEL_CONFIG[i].title };
    }
  }
  return { level: 1, title: LEVEL_CONFIG[0].title };
}

/**
 * 添加积分流水
 */
async function addPointTransaction(
  supabase: any,
  userId: string,
  type: 'earn' | 'spend' | 'bonus' | 'penalty',
  amount: number,
  source: string,
  sourceId: string | null,
  description: string,
  currentBalance: number
): Promise<void> {
  const newBalance = currentBalance + amount;

  const { error } = await supabase.from('point_transactions').insert({
    user_id: userId,
    type,
    amount,
    balance: newBalance,
    source,
    source_id: sourceId,
    description,
  });

  if (error) {
    console.error('添加积分流水失败:', error);
    throw error;
  }
}

/**
 * 更新志愿者积分和等级
 */
async function updateVolunteerPoints(
  supabase: any,
  userId: string,
  pointsToAdd: number
): Promise<void> {
  // 获取当前积分
  const { data: profile, error: fetchError } = await supabase
    .from('volunteer_profiles')
    .select('points, level')
    .eq('user_id', userId)
    .single();

  if (fetchError || !profile) {
    console.error('获取志愿者资料失败:', fetchError);
    throw fetchError;
  }

  const newPoints = profile.points + pointsToAdd;
  const { level: newLevel, title } = calculateLevel(newPoints);

  // 更新积分和等级
  const updateData: any = {
    points: newPoints,
    total_help_count: supabase.rpc('increment', { x: 1 }),
  };

  // 如果等级提升，更新等级
  if (newLevel > profile.level) {
    updateData.level = newLevel;
  }

  const { error: updateError } = await supabase
    .from('volunteer_profiles')
    .update(updateData)
    .eq('user_id', userId);

  if (updateError) {
    console.error('更新志愿者积分失败:', updateError);
    throw updateError;
  }

  // 如果等级提升，发送通知
  if (newLevel > profile.level) {
    await supabase.from('notifications').insert({
      user_id: userId,
      type: 'level_up',
      title: '等级提升！',
      content: `恭喜您升级到${title}！`,
      data: { newLevel, newPoints },
    });
  }
}

/**
 * 处理求助完成积分
 */
async function handleHelpCompleted(supabase: any, helpRequest: any): Promise<void> {
  const {
    id,
    volunteer_id,
    type,
    duration_seconds,
    seeker_rating,
  } = helpRequest;

  if (!volunteer_id) return;

  const isSOS = type === 'sos';
  const { points, breakdown } = calculateHelpPoints(
    type,
    duration_seconds || 0,
    seeker_rating,
    isSOS
  );

  if (points <= 0) return;

  // 获取当前积分余额
  const { data: profile } = await supabase
    .from('volunteer_profiles')
    .select('points')
    .eq('user_id', volunteer_id)
    .single();

  const currentBalance = profile?.points || 0;

  // 添加积分流水
  await addPointTransaction(
    supabase,
    volunteer_id,
    'earn',
    points,
    'help_complete',
    id,
    `完成${isSOS ? '紧急' : ''}帮助获得积分`,
    currentBalance
  );

  // 更新志愿者积分
  await updateVolunteerPoints(supabase, volunteer_id, points);

  console.log(`志愿者 ${volunteer_id} 获得 ${points} 积分`, breakdown);
}

/**
 * 处理异步任务完成积分
 */
async function handleAsyncTaskCompleted(supabase: any, task: any): Promise<void> {
  const { id, volunteer_id, priority } = task;

  if (!volunteer_id) return;

  const { points, breakdown } = calculateAsyncTaskPoints(priority || 'normal');

  // 获取当前积分余额
  const { data: profile } = await supabase
    .from('volunteer_profiles')
    .select('points')
    .eq('user_id', volunteer_id)
    .single();

  const currentBalance = profile?.points || 0;

  // 添加积分流水
  await addPointTransaction(
    supabase,
    volunteer_id,
    'earn',
    points,
    'task_complete',
    id,
    '完成异步任务获得积分',
    currentBalance
  );

  // 更新志愿者积分
  await updateVolunteerPoints(supabase, volunteer_id, points);

  console.log(`志愿者 ${volunteer_id} 获得 ${points} 积分(异步任务)`, breakdown);
}

/**
 * 手动触发积分计算(用于补偿或测试)
 */
async function handleManualCalculate(req: Request): Promise<Response> {
  try {
    const body = await req.json();
    const { helpRequestId, asyncTaskId } = body;

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    if (helpRequestId) {
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

      await handleHelpCompleted(supabase, helpRequest);

      return new Response(
        JSON.stringify({ success: true, message: '求助积分已计算' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (asyncTaskId) {
      const { data: task, error } = await supabase
        .from('async_tasks')
        .select('*')
        .eq('id', asyncTaskId)
        .single();

      if (error || !task) {
        return new Response(
          JSON.stringify({ error: '异步任务不存在' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      await handleAsyncTaskCompleted(supabase, task);

      return new Response(
        JSON.stringify({ success: true, message: '任务积分已计算' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: '缺少helpRequestId或asyncTaskId' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('手动计算积分错误:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 获取积分配置
 */
async function handleGetConfig(): Promise<Response> {
  return new Response(
    JSON.stringify({
      points_config: POINTS_CONFIG,
      level_config: LEVEL_CONFIG,
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * Webhook处理函数(用于数据库触发器)
 */
async function handleWebhook(req: Request): Promise<Response> {
  try {
    const body = await req.json();
    const { type, record, old_record } = body;

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 处理help_requests状态变更
    if (type === 'help_request_completed') {
      await handleHelpCompleted(supabase, record);
    }

    // 处理async_tasks状态变更
    if (type === 'async_task_completed') {
      await handleAsyncTaskCompleted(supabase, record);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Webhook处理错误:', error);
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

  // Webhook端点(数据库触发器调用)
  if (url.pathname === '/points-calculator/webhook' && req.method === 'POST') {
    return handleWebhook(req);
  }

  // 手动计算端点
  if (url.pathname === '/points-calculator/calculate' && req.method === 'POST') {
    return handleManualCalculate(req);
  }

  // 获取配置端点
  if (url.pathname === '/points-calculator/config' && req.method === 'GET') {
    return handleGetConfig();
  }

  return new Response(
    JSON.stringify({ error: 'Not Found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
