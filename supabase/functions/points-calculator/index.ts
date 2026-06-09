// =====================================================
// 共感 LinkAble - 積分計算 Edge Function
// 功能：監聽help_requests變更，自動計算和更新積分
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS頭
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// 積分配置
const POINTS_CONFIG = {
  // 實時幫助積分
  realtime_help: {
    base: 10,           // 基礎積分
    duration_bonus: {   // 時長獎勵
      '5min': 5,
      '10min': 10,
      '15min': 15,
      '30min': 25,
    },
    rating_bonus: {     // 評價獎勵
      5: 10,
      4: 5,
      3: 2,
      2: 0,
      1: -5,
    },
  },
  // 異步任務積分
  async_task: {
    base: 5,
    priority_bonus: {
      low: 0,
      normal: 2,
      high: 5,
      urgent: 10,
    },
  },
  // SOS緊急幫助積分
  sos_help: {
    base: 20,
    duration_bonus: {
      '5min': 10,
      '10min': 20,
    },
  },
  // 連續簽到積分
  daily_signin: {
    base: 1,
    streak_bonus: [0, 0, 1, 1, 2, 2, 5], // 第1-7天額外獎勵
  },
};

// 等級配置
const LEVEL_CONFIG = [
  { level: 1, minPoints: 0, title: '新手志願者' },
  { level: 2, minPoints: 50, title: '初級志願者' },
  { level: 3, minPoints: 150, title: '中級志願者' },
  { level: 4, minPoints: 300, title: '高級志願者' },
  { level: 5, minPoints: 500, title: '資深志願者' },
  { level: 6, minPoints: 800, title: '專家志願者' },
  { level: 7, minPoints: 1200, title: '大師志願者' },
];

/**
 * 計算幫助積分
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
    // SOS緊急幫助
    const config = POINTS_CONFIG.sos_help;
    totalPoints += config.base;
    breakdown.base = config.base;

    // 時長獎勵
    const durationMin = durationSeconds / 60;
    if (durationMin >= 10) {
      totalPoints += config.duration_bonus['10min'];
      breakdown.duration = config.duration_bonus['10min'];
    } else if (durationMin >= 5) {
      totalPoints += config.duration_bonus['5min'];
      breakdown.duration = config.duration_bonus['5min'];
    }
  } else if (helpType === 'realtime_voice' || helpType === 'realtime_video') {
    // 實時幫助
    const config = POINTS_CONFIG.realtime_help;
    totalPoints += config.base;
    breakdown.base = config.base;

    // 時長獎勵
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

    // 評價獎勵
    if (rating && config.rating_bonus[rating as keyof typeof config.rating_bonus] !== undefined) {
      const ratingBonus = config.rating_bonus[rating as keyof typeof config.rating_bonus];
      totalPoints += ratingBonus;
      breakdown.rating = ratingBonus;
    }
  }

  return { points: totalPoints, breakdown };
}

/**
 * 計算異步任務積分
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
 * 根據積分計算等級
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
 * 添加積分流水
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
    console.error('添加積分流水失敗:', error);
    throw error;
  }
}

/**
 * 更新志願者積分和等級
 */
async function updateVolunteerPoints(
  supabase: any,
  userId: string,
  pointsToAdd: number
): Promise<void> {
  // 獲取當前積分
  const { data: profile, error: fetchError } = await supabase
    .from('volunteer_profiles')
    .select('points, level')
    .eq('user_id', userId)
    .single();

  if (fetchError || !profile) {
    console.error('獲取志願者資料失敗:', fetchError);
    throw fetchError;
  }

  const newPoints = profile.points + pointsToAdd;
  const { level: newLevel, title } = calculateLevel(newPoints);

  // 更新積分和等級
  const updateData: any = {
    points: newPoints,
    total_help_count: supabase.rpc('increment', { x: 1 }),
  };

  // 如果等級提升，更新等級
  if (newLevel > profile.level) {
    updateData.level = newLevel;
  }

  const { error: updateError } = await supabase
    .from('volunteer_profiles')
    .update(updateData)
    .eq('user_id', userId);

  if (updateError) {
    console.error('更新志願者積分失敗:', updateError);
    throw updateError;
  }

  // 如果等級提升，發送通知
  if (newLevel > profile.level) {
    await supabase.from('notifications').insert({
      user_id: userId,
      type: 'level_up',
      title: '等級提升！',
      content: `恭喜您升級到${title}！`,
      data: { newLevel, newPoints },
    });
  }
}

/**
 * 處理求助完成積分
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

  // 獲取當前積分餘額
  const { data: profile } = await supabase
    .from('volunteer_profiles')
    .select('points')
    .eq('user_id', volunteer_id)
    .single();

  const currentBalance = profile?.points || 0;

  // 添加積分流水
  await addPointTransaction(
    supabase,
    volunteer_id,
    'earn',
    points,
    'help_complete',
    id,
    `完成${isSOS ? '緊急' : ''}幫助獲得積分`,
    currentBalance
  );

  // 更新志願者積分
  await updateVolunteerPoints(supabase, volunteer_id, points);

  console.log(`志願者 ${volunteer_id} 獲得 ${points} 積分`, breakdown);
}

/**
 * 處理異步任務完成積分
 */
async function handleAsyncTaskCompleted(supabase: any, task: any): Promise<void> {
  const { id, volunteer_id, priority } = task;

  if (!volunteer_id) return;

  const { points, breakdown } = calculateAsyncTaskPoints(priority || 'normal');

  // 獲取當前積分餘額
  const { data: profile } = await supabase
    .from('volunteer_profiles')
    .select('points')
    .eq('user_id', volunteer_id)
    .single();

  const currentBalance = profile?.points || 0;

  // 添加積分流水
  await addPointTransaction(
    supabase,
    volunteer_id,
    'earn',
    points,
    'task_complete',
    id,
    '完成異步任務獲得積分',
    currentBalance
  );

  // 更新志願者積分
  await updateVolunteerPoints(supabase, volunteer_id, points);

  console.log(`志願者 ${volunteer_id} 獲得 ${points} 積分(異步任務)`, breakdown);
}

/**
 * 手動觸發積分計算(用於補償或測試)
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
          JSON.stringify({ error: '求助記錄不存在' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      await handleHelpCompleted(supabase, helpRequest);

      return new Response(
        JSON.stringify({ success: true, message: '求助積分已計算' }),
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
          JSON.stringify({ error: '異步任務不存在' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      await handleAsyncTaskCompleted(supabase, task);

      return new Response(
        JSON.stringify({ success: true, message: '任務積分已計算' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: '缺少helpRequestId或asyncTaskId' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('手動計算積分錯誤:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * 獲取積分配置
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
 * Webhook處理函數(用於數據庫觸發器)
 */
async function handleWebhook(req: Request): Promise<Response> {
  try {
    const body = await req.json();
    const { type, record, old_record } = body;

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 處理help_requests狀態變更
    if (type === 'help_request_completed') {
      await handleHelpCompleted(supabase, record);
    }

    // 處理async_tasks狀態變更
    if (type === 'async_task_completed') {
      await handleAsyncTaskCompleted(supabase, record);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Webhook處理錯誤:', error);
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

  // Webhook端點(數據庫觸發器調用)
  if (url.pathname === '/points-calculator/webhook' && req.method === 'POST') {
    return handleWebhook(req);
  }

  // 手動計算端點
  if (url.pathname === '/points-calculator/calculate' && req.method === 'POST') {
    return handleManualCalculate(req);
  }

  // 獲取配置端點
  if (url.pathname === '/points-calculator/config' && req.method === 'GET') {
    return handleGetConfig();
  }

  return new Response(
    JSON.stringify({ error: 'Not Found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
