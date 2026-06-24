import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/ai_result_model.dart';
import '../../models/demo_ai_intent.dart';
import '../asr/unified_asr_service.dart';
import '../demo/demo_ai_service.dart';
import '../experimental/ai/baidu_ocr_service.dart';
import '../tts/unified_tts_service.dart';
import '../vision/vision_service.dart';
import 'agent_result.dart';

/// AgentServiceFacade
///
/// AGENTS.md §12.2 統一入口：AI 相關能力的唯一 facade。
/// 包裝 DemoAIService，對外屏蔽 demo/real 實現差異。
/// UI 層只允許通過本 facade 調用 AI 能力。
class AgentServiceFacade {
  final DemoAIService _demoService;
  final UnifiedTtsService? _ttsServiceOverride;
  final UnifiedAsrService? _asrServiceOverride;
  final VisionService? _visionServiceOverride;
  UnifiedTtsService? _ttsServiceCache;
  UnifiedAsrService? _asrServiceCache;
  VisionService? _visionServiceCache;

  AgentServiceFacade({
    DemoAIService? demoService,
    UnifiedTtsService? ttsService,
    UnifiedAsrService? asrService,
    VisionService? visionService,
  }) : _demoService = demoService ?? DemoAIService(),
       _ttsServiceOverride = ttsService,
       _asrServiceOverride = asrService,
       _visionServiceOverride = visionService;

  UnifiedTtsService get _ttsService =>
      _ttsServiceOverride ?? (_ttsServiceCache ??= UnifiedTtsService());

  UnifiedAsrService get _asrService =>
      _asrServiceOverride ?? (_asrServiceCache ??= UnifiedAsrService());

  VisionService get _visionService =>
      _visionServiceOverride ?? (_visionServiceCache ??= VisionService());

  // ────────────────────────── 統一輸入處理 ──────────────────────────

  /// 統一處理用戶輸入（文字 / 語音 / 圖片）
  ///
  /// [text] 用戶輸入文本或語音轉寫
  /// [imagePath] 可選的圖片路徑
  /// [inputType] 輸入類型標識：text | voice | image | mixed
  Future<AgentResult> processInput({
    String? text,
    String? imagePath,
    String inputType = 'text',
  }) async {
    final input = text?.trim() ?? '';
    try {
      final safetyRoute = await _tryLocalSafetyRoute(
        input,
        imagePath: imagePath,
      );
      if (safetyRoute != null) {
        return safetyRoute;
      }

      if (!FeatureFlags.enableRealAI) {
        return _processDemoInput(input, imagePath: imagePath);
      }

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        return _processImageInput(input, imagePath.trim());
      }

      // 優先調用真實大模型（智譜 GLM-4-flash）
      final llmResult = await _chatWithLLM(input);
      if (llmResult != null) {
        return llmResult;
      }
      // 大模型不可用時降級到 Demo
      final result = await _demoService.process(input, imagePath: imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('processInput 失敗: $e');
    }
  }

  /// SOS、顯式轉人工與高風險協助必須先走本地確定規則。
  ///
  /// 真實大模型可以回答普通問題，但不能吞掉緊急分流和志願者兜底。
  Future<AgentResult?> _tryLocalSafetyRoute(
    String input, {
    String? imagePath,
  }) async {
    if (input.trim().isEmpty) {
      return null;
    }

    final intent = _demoService.resolveIntent(input, imagePath: imagePath);
    const localFirstIntents = {
      DemoAiIntent.emergency,
      DemoAiIntent.needHuman,
      DemoAiIntent.navigation,
      DemoAiIntent.environmentDescription,
      DemoAiIntent.medicationCheck,
    };
    if (!localFirstIntents.contains(intent)) {
      return null;
    }

    final result = await _demoService.process(input, imagePath: imagePath);
    final mapped = _mapAIResultToAgentResult(result);
    if (mapped.nextAction == 'trigger_sos' ||
        mapped.nextAction == 'match_volunteer') {
      AppLogger.info('[AgentFacade] 本地安全分流: ${mapped.nextAction}');
      return mapped;
    }

    return null;
  }

  Future<AgentResult> _processDemoInput(
    String input, {
    String? imagePath,
  }) async {
    final prompt = input.isEmpty && imagePath != null ? '這是什麼？' : input;
    final result = await _demoService.process(prompt, imagePath: imagePath);
    return _mapAIResultToAgentResult(result);
  }

  /// 智譜 GLM-4 系統提示詞
  static const _systemPrompt =
      '你是 LinkAble 共感助手，一個專爲視障、聽障、老年等有障礙需求的用戶設計的 AI 互助助手。'
      '你的職責是用簡潔、溫暖、可被讀屏軟件朗讀的中文回答用戶問題。'
      '回答要求：'
      '1. 直接回答，不廢話，不超過 100 字 '
      '2. 如果是醫療、法律等專業問題，提醒用戶諮詢專業人員 '
      '3. 如果你不確定，建議用戶轉接真人志願者確認 '
      '4. 語氣溫暖友善，像一個有耐心的朋友 '
      '5. 不要使用 Markdown 格式，純文本即可';

  /// 調用智譜 GLM-4-flash 進行真實對話
  /// 返回 null 表示調用失敗，應降級到 Demo
  Future<AgentResult?> _chatWithLLM(String userMessage) async {
    if (!FeatureFlags.enableRealAI) return null;
    if (!APIConfig.isZhipuConfigured) return null;
    if (userMessage.trim().isEmpty) return null;

    try {
      final url = Uri.parse('${APIConfig.zhipuBaseUrl}/chat/completions');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${APIConfig.zhipuApiKey}',
            },
            body: jsonEncode({
              'model': 'glm-4-flash',
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.7,
              'max_tokens': 500,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        AppLogger.warning('[AgentFacade] GLM-4 調用失敗: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;

      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) return null;
      final message = firstChoice['message'];
      if (message is! Map<String, dynamic>) return null;
      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) return null;

      AppLogger.info('[AgentFacade] GLM-4 回覆成功');

      return AgentResult.success(
        intent: 'general_chat',
        urgency: 'normal',
        confidence: 0.9,
        canResolveByAi: true,
        answerText: content.trim(),
        spokenText: content.trim(),
        nextAction: 'answer',
        uiCopy: {
          'title': 'AI 助手',
          'body': content.trim(),
          'primaryAction': '繼續',
          'secondaryAction': '轉人工協助',
        },
      );
    } catch (_) {
      AppLogger.warning('[AgentFacade] GLM-4 調用異常，降級到 Demo');
      return null;
    }
  }

  /// 圖片輸入：直接調用智譜 GLM-4-vision 多模態理解
  /// 不再做關鍵詞路由，讓大模型自己判斷圖片內容
  Future<AgentResult> _processImageInput(String text, String imagePath) async {
    if (!kIsWeb) {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return AgentResult.error('圖片文件不存在', intent: 'unknown');
      }
    }

    // 優先嚐試真實多模態 API
    if (FeatureFlags.enableRealAI && APIConfig.isZhipuConfigured) {
      try {
        return await _visionWithLLM(text, imagePath);
      } catch (e) {
        AppLogger.warning('[AgentFacade] 多模態視覺調用失敗，降級到關鍵詞路由: $e');
      }
    }

    // 降級到原有關鍵詞路由（Demo/百度OCR）
    final normalized = text.toLowerCase();
    if (_containsAny(normalized, const ['藥', 'medicine', '用法', '劑量', '說明書'])) {
      return checkMedicine(imagePath);
    }
    if (_containsAny(normalized, const ['顏色', '色', 'color'])) {
      return recognizeColor(imagePath);
    }
    if (_containsAny(normalized, const ['錢', '鈔', '面額', '紙幣', 'money'])) {
      return recognizeMoney(imagePath);
    }
    if (_containsAny(normalized, const ['文字', '讀', 'ocr', '路牌', '通知', '票據'])) {
      return recognizeText(imagePath);
    }
    if (_containsAny(normalized, const [
      '產品',
      '商品',
      '包裝',
      '物體',
      '東西',
      'object',
    ])) {
      return identifyObject(imagePath);
    }
    return describeScene(imagePath);
  }

  /// 調用智譜 GLM-4-vision 進行多模態圖片理解
  Future<AgentResult> _visionWithLLM(String userText, String imagePath) async {
    List<int> bytes;
    if (kIsWeb) {
      final response = await http.get(Uri.parse(imagePath));
      bytes = response.bodyBytes;
    } else {
      bytes = await File(imagePath).readAsBytes();
    }
    if (bytes.length > 10 * 1024 * 1024) {
      return AgentResult.error('圖片過大，請壓縮後重試', intent: 'unknown');
    }

    final base64Image = base64Encode(bytes);
    final mimeType = imagePath.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    final prompt = userText.trim().isEmpty || userText.trim() == '這是什麼？'
        ? '請識別這張圖片的內容，用簡潔的中文描述。如果是藥品，讀出藥品名稱、用法用量、有效期。如果是鈔票，說出面額。如果是路牌/文字，讀出內容。'
        : '用戶問：$userText\n請根據圖片內容回答。';

    final url = Uri.parse('${APIConfig.zhipuBaseUrl}/chat/completions');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${APIConfig.zhipuApiKey}',
          },
          body: jsonEncode({
            'model': 'glm-4v-flash',
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
                  },
                ],
              },
            ],
            'temperature': 0.7,
            'max_tokens': 500,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('GLM-4-vision 調用失敗: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) throw Exception('GLM-4-vision 無返回');

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw Exception('GLM-4-vision 返回結構無效');
    }
    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw Exception('GLM-4-vision 消息結構無效');
    }
    final content = message['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('GLM-4-vision 返回爲空');
    }

    AppLogger.info('[AgentFacade] GLM-4-vision 識別成功');

    return AgentResult.success(
      intent: 'scene_describe',
      urgency: 'normal',
      confidence: 0.9,
      canResolveByAi: true,
      answerText: content.trim(),
      spokenText: content.trim(),
      nextAction: 'answer',
      uiCopy: {
        'title': 'AI 已識別圖片',
        'body': content.trim(),
        'primaryAction': '繼續',
        'secondaryAction': '轉人工協助',
      },
    );
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  // ────────────────────────── 意圖識別 ──────────────────────────

  /// 意圖識別
  ///
  /// 返回標準化意圖標籤，供上層路由決策。
  Future<AgentResult> detectIntent(String text) async {
    try {
      final result = await _demoService.detectIntent(text);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('detectIntent 失敗: $e', intent: 'unknown');
    }
  }

  // ────────────────────────── 視覺能力 ──────────────────────────

  /// OCR 文字識別
  Future<AgentResult> recognizeText(String imagePath) async {
    // 1. 檢查是否配置了百度OCR
    if (FeatureFlags.enableRealAI && APIConfig.isBaiduOcrConfigured) {
      try {
        final ocrService = BaiduOCRService();
        final isAvailable = await ocrService.isAvailable();
        if (isAvailable) {
          final result = await ocrService.recognizeText(File(imagePath));
          if (result.isSuccess) {
            return AgentResult.success(
              intent: 'ocr_text',
              urgency: 'normal',
              confidence: result.data!.confidence,
              canResolveByAi: true,
              answerText: result.data!.text.isEmpty
                  ? '未能識別到文字，請重新拍攝'
                  : '識別結果：\n${result.data!.text}',
              spokenText: result.data!.text.isEmpty
                  ? '未能識別到文字，請重新拍攝'
                  : '已識別到文字：${result.data!.text}',
              nextAction: 'answer',
              recommendedVolunteerTags: const ['視障協助'],
            );
          }
        }
      } catch (e) {
        // 真實OCR失敗，降級到Demo
        AppLogger.warning('真實OCR失敗，降級到Demo: $e');
      }
    }

    // 2. fallback到Demo OCR
    try {
      final result = await _demoService.recognizeText(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('recognizeText 失敗: $e', intent: 'ocr_text');
    }
  }

  /// 場景描述
  Future<AgentResult> describeScene(String imagePath) async {
    // 1. 優先使用智譜AI
    if (FeatureFlags.enableRealAI && _visionService.hasRealService) {
      final result = await _visionService.describeScene(imagePath);
      if (result.success) {
        return AgentResult.success(
          intent: 'scene_describe',
          urgency: 'normal',
          confidence: result.confidence,
          canResolveByAi: true,
          answerText: result.text,
          spokenText: result.text,
          nextAction: 'answer',
          recommendedVolunteerTags: const ['視障協助', '老人陪同'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.describeScene(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error(
        'describeScene 失敗: $e',
        intent: 'scene_describe',
      );
    }
  }

  /// 顏色識別
  Future<AgentResult> recognizeColor(String imagePath) async {
    // 1. 優先使用智譜AI
    if (FeatureFlags.enableRealAI && _visionService.hasRealService) {
      final result = await _visionService.recognizeColor(imagePath);
      if (result.success) {
        return AgentResult.success(
          intent: 'color_identify',
          urgency: 'normal',
          confidence: result.confidence,
          canResolveByAi: true,
          answerText: result.text,
          spokenText: result.text,
          nextAction: 'answer',
          recommendedVolunteerTags: const ['視障協助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.recognizeColor(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error(
        'recognizeColor 失敗: $e',
        intent: 'color_identify',
      );
    }
  }

  /// 藥品確認
  Future<AgentResult> checkMedicine(String imagePath) async {
    // 1. 優先使用智譜AI
    if (FeatureFlags.enableRealAI && _visionService.hasRealService) {
      final result = await _visionService.checkMedicine(imagePath);
      if (result.success) {
        return AgentResult.success(
          intent: 'medicine_check',
          urgency: 'normal',
          confidence: result.confidence,
          canResolveByAi: true,
          answerText: result.text,
          spokenText: result.text,
          nextAction: 'answer',
          recommendedVolunteerTags: const ['藥品說明協助', '視障協助'],
          safetyFlags: const ['not_medical_diagnosis'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process(
        '幫我看看這個藥品',
        imagePath: imagePath,
      );
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'medicine_check',
      );
    } catch (e) {
      return AgentResult.error(
        'checkMedicine 失敗: $e',
        intent: 'medicine_check',
      );
    }
  }

  /// 鈔票識別
  Future<AgentResult> recognizeMoney(String imagePath) async {
    // 1. 優先使用智譜AI
    if (FeatureFlags.enableRealAI && _visionService.hasRealService) {
      final result = await _visionService.recognizeMoney(imagePath);
      if (result.success) {
        return AgentResult.success(
          intent: 'money_identify',
          urgency: 'normal',
          confidence: result.confidence,
          canResolveByAi: true,
          answerText: result.text,
          spokenText: result.text,
          nextAction: 'answer',
          recommendedVolunteerTags: const ['視障協助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process('這是多少錢', imagePath: imagePath);
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'money_identify',
      );
    } catch (e) {
      return AgentResult.error(
        'recognizeMoney 失敗: $e',
        intent: 'money_identify',
      );
    }
  }

  /// 物體識別
  Future<AgentResult> identifyObject(String imagePath) async {
    // 1. 優先使用智譜AI
    if (FeatureFlags.enableRealAI && _visionService.hasRealService) {
      final result = await _visionService.identifyObject(imagePath);
      if (result.success) {
        return AgentResult.success(
          intent: 'object_identify',
          urgency: 'normal',
          confidence: result.confidence,
          canResolveByAi: true,
          answerText: result.text,
          spokenText: result.text,
          nextAction: 'answer',
          recommendedVolunteerTags: const ['視障協助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process('這是什麼東西', imagePath: imagePath);
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'object_identify',
      );
    } catch (e) {
      return AgentResult.error(
        'identifyObject 失敗: $e',
        intent: 'object_identify',
      );
    }
  }

  // ────────────────────────── 安全檢測 ──────────────────────────

  /// 緊急意圖檢測
  Future<AgentResult> detectEmergency(String text) async {
    try {
      final result = await _demoService.detectEmergency(text);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('detectEmergency 失敗: $e', intent: 'emergency');
    }
  }

  // ────────────────────────── 內部映射 ──────────────────────────

  /// 將 DemoAIService 的 AIResult 映射爲標準 AgentResult
  AgentResult _mapAIResultToAgentResult(
    AIResult result, {
    String? overrideIntent,
  }) {
    if (!result.success) {
      return AgentResult.error(
        result.error ?? '未知錯誤',
        intent: overrideIntent ?? 'unknown',
      );
    }

    final data = result.data ?? {};
    final intent = overrideIntent ?? (data['intent'] as String? ?? 'unknown');
    final demoIntent = DemoAiIntent.fromWireName(data['demoIntent'] as String?);

    final isEmergency =
        data['isEmergency'] == true ||
        intent == 'emergency' ||
        demoIntent == DemoAiIntent.emergency;

    final requiresHumanFallback =
        data['requiresHumanFallback'] == true ||
        data['nextStatus'] == 'matching' ||
        demoIntent == DemoAiIntent.needHuman;

    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.85;

    String nextAction;
    if (isEmergency) {
      nextAction = 'trigger_sos';
    } else if (requiresHumanFallback) {
      nextAction = 'match_volunteer';
    } else if (confidence < 0.65) {
      nextAction = 'ask_followup';
    } else {
      nextAction = 'answer';
    }

    String urgency = 'normal';
    if (isEmergency) {
      urgency = 'emergency';
    } else if (confidence < 0.65) {
      urgency = 'elevated';
    }

    final canResolveByAi = !requiresHumanFallback && !isEmergency;

    // 推薦志願者標籤
    final List<String> tags = _inferVolunteerTags(demoIntent, data);

    // safetyFlags
    final List<String> safetyFlags = [];
    if (demoIntent == DemoAiIntent.medicationCheck) {
      safetyFlags.add('not_medical_diagnosis');
    }
    if (data['riskLevel'] == 'high') {
      safetyFlags.add('high_risk_scene');
    }

    // uiCopy
    final uiCopy = <String, dynamic>{
      'title': _uiTitle(demoIntent, isEmergency),
      'body': result.text,
      'primaryAction': isEmergency
          ? '確認並繼續'
          : (canResolveByAi ? '繼續' : '轉人工協助'),
      'secondaryAction': isEmergency ? '撤銷（10秒內）' : '重新描述',
    };

    return AgentResult.success(
      intent: intent,
      urgency: urgency,
      confidence: confidence,
      canResolveByAi: canResolveByAi,
      answerText: result.text,
      spokenText: result.text,
      nextAction: nextAction,
      handoffReason: requiresHumanFallback
          ? (demoIntent == DemoAiIntent.fallback ? 'AI 低信心，無法判斷' : '需要真人確認或協助')
          : null,
      recommendedVolunteerTags: tags,
      safetyFlags: safetyFlags,
      uiCopy: uiCopy,
    );
  }

  List<String> _inferVolunteerTags(
    DemoAiIntent intent,
    Map<String, dynamic> data,
  ) {
    switch (intent) {
      case DemoAiIntent.medicationCheck:
      case DemoAiIntent.ocrText:
        return const ['藥品說明協助', '視障協助'];
      case DemoAiIntent.navigation:
      case DemoAiIntent.environmentDescription:
        return const ['視障協助', '普通問路'];
      case DemoAiIntent.translation:
      case DemoAiIntent.moneyRecognition:
        return const ['手語 / 聽障溝通', '視障協助'];
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
        return const ['視障協助', '老人陪同'];
      case DemoAiIntent.colorRecognition:
        return const ['視障協助'];
      case DemoAiIntent.emergency:
        return const ['緊急陪伴'];
      case DemoAiIntent.needHuman:
        final context = data['contextIntent'] as String?;
        if (context == 'medication_check') {
          return const ['藥品說明協助'];
        }
        return const ['視障協助', '普通問路'];
      case DemoAiIntent.fallback:
        return const ['視障協助', '普通問路', '老人陪同'];
    }
  }

  String _uiTitle(DemoAiIntent intent, bool isEmergency) {
    if (isEmergency) return '檢測到緊急情況';
    switch (intent) {
      case DemoAiIntent.ocrText:
        return 'AI 已識別文字';
      case DemoAiIntent.sceneDescription:
        return '場景描述';
      case DemoAiIntent.objectIdentify:
        return '物體識別';
      case DemoAiIntent.colorRecognition:
        return '顏色識別';
      case DemoAiIntent.moneyRecognition:
        return '鈔票識別';
      case DemoAiIntent.translation:
        return '轉譯協助';
      case DemoAiIntent.environmentDescription:
        return '環境描述';
      case DemoAiIntent.navigation:
        return '導航協助';
      case DemoAiIntent.medicationCheck:
        return '藥品確認';
      case DemoAiIntent.emergency:
        return '緊急求助';
      case DemoAiIntent.needHuman:
        return '需要真人協助';
      case DemoAiIntent.fallback:
        return 'AI 不確定';
    }
  }

  // ────────────────────────── TTS 語音朗讀 ──────────────────────────

  /// 朗讀文本
  ///
  /// 使用統一 TTS 服務（優先 MiniMax，fallback 到本地 TTS）。
  /// [text] 要朗讀的文本
  /// [voiceId] MiniMax 音色 ID（可選）
  Future<void> speakText(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    try {
      await _ttsService.speak(text, voiceId: voiceId);
      AppLogger.info('AgentServiceFacade 朗讀文本: $text');
    } catch (e) {
      AppLogger.error('AgentServiceFacade 朗讀失敗', e);
      rethrow;
    }
  }

  /// 停止朗讀
  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      AppLogger.error('停止朗讀失敗', e);
    }
  }

  /// 是否正在朗讀
  bool get isSpeaking => _ttsService.isSpeaking;

  // ────────────────────────── ASR 語音輸入 ──────────────────────────

  /// 是否正在錄音/識別
  bool get isListening => _asrService.isListening;

  /// 開始語音輸入（錄音 + 識別）
  ///
  /// 返回識別到的文本。調用後進入錄音狀態，
  /// 需要調用 [stopVoiceInput] 來停止錄音並獲取最終結果。
  Future<String> startVoiceInput() async {
    try {
      AppLogger.info('AgentServiceFacade 開始語音輸入');
      return await _asrService.startListening();
    } catch (e) {
      AppLogger.error('語音輸入啓動失敗', e);
      rethrow;
    }
  }

  /// 停止語音輸入
  Future<void> stopVoiceInput() async {
    try {
      AppLogger.info('AgentServiceFacade 停止語音輸入');
      await _asrService.stopListening();
    } catch (e) {
      AppLogger.error('停止語音輸入失敗', e);
    }
  }
}
