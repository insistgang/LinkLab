// =====================================================
// 共感 LinkAble - AI服务调度 Edge Function
// 功能：统一调度各种AI服务(OCR、ASR、TTS、VL)
// =====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS头
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// AI服务类型
enum AIServiceType {
  OCR = 'ocr',                    // 文字识别
  SCENE_DESC = 'scene_desc',     // 场景描述
  ASR = 'asr',                    // 语音识别
  TTS = 'tts',                    // 语音合成
  CHAT = 'chat',                  // 对话
  TRANSLATION = 'translation',   // 翻译
}

// AI服务配置
interface AIServiceConfig {
  baseUrl: string;
  apiKey: string;
  timeout: number;
}

// 请求类型
interface AIDispatchRequest {
  service: AIServiceType;
  input: string | { text?: string; imageUrl?: string; audioUrl?: string };
  options?: {
    stream?: boolean;
    language?: string;
    voice?: string;
    speed?: number;
  };
  cache?: boolean;
}

// 响应类型
interface AIDispatchResponse {
  success: boolean;
  data?: any;
  error?: string;
  cached?: boolean;
  cost?: number;
}

/**
 * 计算查询哈希(用于缓存)
 */
function computeHash(input: string): string {
  // 简化哈希实现
  let hash = 0;
  for (let i = 0; i < input.length; i++) {
    const char = input.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(16);
}

/**
 * 检查缓存
 */
async function checkCache(
  supabase: any,
  queryHash: string,
  queryType: string
): Promise<any | null> {
  const { data, error } = await supabase
    .from('ai_response_cache')
    .select('response, expires_at')
    .eq('query_hash', queryHash)
    .eq('query_type', queryType)
    .gt('expires_at', new Date().toISOString())
    .single();

  if (error || !data) return null;

  // 更新命中次数
  await supabase.rpc('increment_cache_hit', { hash: queryHash });

  return data.response;
}

/**
 * 写入缓存
 */
async function writeCache(
  supabase: any,
  queryHash: string,
  queryType: string,
  response: any,
  ttlHours: number = 24
): Promise<void> {
  const expiresAt = new Date();
  expiresAt.setHours(expiresAt.getHours() + ttlHours);

  await supabase.from('ai_response_cache').upsert({
    query_hash: queryHash,
    query_type: queryType,
    response,
    expires_at: expiresAt.toISOString(),
    hit_count: 1,
  });
}

/**
 * 调用百度OCR
 */
async function callBaiduOCR(imageUrl: string, apiKey: string, secretKey: string): Promise<any> {
  // 1. 获取access token
  const tokenRes = await fetch(
    `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${apiKey}&client_secret=${secretKey}`,
    { method: 'POST' }
  );
  const tokenData = await tokenRes.json();

  // 2. 调用OCR
  const ocrRes = await fetch(
    `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${tokenData.access_token}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ url: imageUrl }),
    }
  );

  return await ocrRes.json();
}

/**
 * 调用通义千问VL(视觉理解)
 */
async function callQwenVL(imageUrl: string, prompt: string, apiKey: string): Promise<any> {
  const res = await fetch('https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'qwen-vl-plus',
      input: {
        messages: [
          {
            role: 'user',
            content: [
              { image: imageUrl },
              { text: prompt || '请详细描述这张图片的内容，包括场景、物体、文字等' },
            ],
          },
        ],
      },
    }),
  });

  return await res.json();
}

/**
 * 调用科大讯飞ASR
 */
async function callXunfeiASR(audioUrl: string, apiKey: string, appId: string): Promise<any> {
  // 科大讯飞ASR API调用
  const res = await fetch('https://iat-api.xfyun.cn/v2/iat', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      audio_url: audioUrl,
      engine_type: 'sms16k',
    }),
  });

  return await res.json();
}

/**
 * 调用科大讯飞TTS
 */
async function callXunfeiTTS(text: string, apiKey: string, options: any): Promise<any> {
  const res = await fetch('https://tts-api.xfyun.cn/v2/tts', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      text,
      voice: options.voice || 'xiaoyan',
      speed: options.speed || 50,
      volume: 50,
      pitch: 50,
    }),
  });

  return await res.json();
}

/**
 * 调用通义千问对话
 */
async function callQwenChat(messages: any[], apiKey: string, stream: boolean = false): Promise<any> {
  const res = await fetch('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'qwen-turbo',
      input: { messages },
      parameters: {
        result_format: 'message',
        stream,
      },
    }),
  });

  if (stream) {
    return res.body;
  }

  return await res.json();
}

/**
 * 主调度函数
 */
async function dispatchAI(request: AIDispatchRequest): Promise<AIDispatchResponse> {
  const { service, input, options = {}, cache = true } = request;

  // 获取环境变量
  const baiduApiKey = Deno.env.get('BAIDU_OCR_API_KEY') || '';
  const baiduSecretKey = Deno.env.get('BAIDU_OCR_SECRET_KEY') || '';
  const qwenApiKey = Deno.env.get('DASHSCOPE_API_KEY') || '';
  const xunfeiApiKey = Deno.env.get('XUNFEI_API_KEY') || '';
  const xunfeiAppId = Deno.env.get('XUNFEI_APP_ID') || '';

  // 检查缓存
  if (cache && typeof input === 'string') {
    const queryHash = computeHash(`${service}:${input}`);
    // 缓存检查逻辑在handleRequest中处理
  }

  try {
    switch (service) {
      case AIServiceType.OCR: {
        const imageUrl = typeof input === 'string' ? input : input.imageUrl;
        if (!imageUrl) throw new Error('OCR需要图片URL');

        const result = await callBaiduOCR(imageUrl, baiduApiKey, baiduSecretKey);
        return {
          success: true,
          data: {
            text: result.words_result?.map((w: any) => w.words).join('\n') || '',
            words: result.words_result || [],
          },
          cost: 0.002, // 估算成本
        };
      }

      case AIServiceType.SCENE_DESC: {
        const imageUrl = typeof input === 'string' ? input : input.imageUrl;
        if (!imageUrl) throw new Error('场景描述需要图片URL');

        const result = await callQwenVL(
          imageUrl,
          '请详细描述这张图片的内容，包括场景、物体、人物、文字等，用中文回答',
          qwenApiKey
        );

        return {
          success: true,
          data: {
            description: result.output?.choices?.[0]?.message?.content?.[0]?.text || '',
          },
          cost: 0.003, // 估算成本
        };
      }

      case AIServiceType.ASR: {
        const audioUrl = typeof input === 'string' ? input : input.audioUrl;
        if (!audioUrl) throw new Error('ASR需要音频URL');

        const result = await callXunfeiASR(audioUrl, xunfeiApiKey, xunfeiAppId);
        return {
          success: true,
          data: {
            text: result.data || '',
          },
          cost: 0.008,
        };
      }

      case AIServiceType.TTS: {
        const text = typeof input === 'string' ? input : input.text;
        if (!text) throw new Error('TTS需要文本');

        const result = await callXunfeiTTS(text, xunfeiApiKey, options);
        return {
          success: true,
          data: {
            audioUrl: result.data?.audio_url || '',
          },
          cost: 0.005,
        };
      }

      case AIServiceType.CHAT: {
        const messages = typeof input === 'string'
          ? [{ role: 'user', content: input }]
          : input;

        if (options.stream) {
          const stream = await callQwenChat(messages, qwenApiKey, true);
          return {
            success: true,
            data: { stream },
            cost: 0,
          };
        }

        const result = await callQwenChat(messages, qwenApiKey, false);
        return {
          success: true,
          data: {
            text: result.output?.choices?.[0]?.message?.content || '',
          },
          cost: 0.001,
        };
      }

      default:
        throw new Error(`不支持的AI服务类型: ${service}`);
    }
  } catch (error) {
    console.error(`AI服务调用失败 [${service}]:`, error);
    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * 处理请求
 */
async function handleRequest(req: Request): Promise<Response> {
  try {
    const request: AIDispatchRequest = await req.json();

    // 验证请求
    if (!request.service || !request.input) {
      return new Response(
        JSON.stringify({ error: '缺少必要参数: service, input' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 创建Supabase客户端(用于缓存)
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 检查缓存
    let cached = false;
    let cacheData = null;
    const inputStr = typeof request.input === 'string' ? request.input : JSON.stringify(request.input);
    const queryHash = computeHash(`${request.service}:${inputStr}`);

    if (request.cache !== false) {
      cacheData = await checkCache(supabase, queryHash, request.service);
      if (cacheData) {
        cached = true;
      }
    }

    if (cached && cacheData) {
      return new Response(
        JSON.stringify({
          success: true,
          data: cacheData,
          cached: true,
          cost: 0,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 调用AI服务
    const result = await dispatchAI(request);

    // 写入缓存(成功的非流式响应)
    if (result.success && request.cache !== false && !request.options?.stream) {
      await writeCache(supabase, queryHash, request.service, result.data);
    }

    // 记录调用日志
    await supabase.from('ai_call_logs').insert({
      service_type: request.service,
      input_preview: inputStr.substring(0, 200),
      success: result.success,
      error_msg: result.error,
      cost: result.cost || 0,
      cached,
    });

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('AI调度错误:', error);
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

  if (req.method === 'POST') {
    return handleRequest(req);
  }

  return new Response(
    JSON.stringify({ error: 'Method Not Allowed' }),
    { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
