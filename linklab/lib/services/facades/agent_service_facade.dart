import 'dart:io';

import '../../config/api_config.dart';
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
/// AGENTS.md §12.2 统一入口：AI 相关能力的唯一 facade。
/// 包装 DemoAIService，对外屏蔽 demo/real 实现差异。
/// UI 层只允许通过本 facade 调用 AI 能力。
class AgentServiceFacade {
  final DemoAIService _demoService;
  final UnifiedTtsService _ttsService;
  final UnifiedAsrService _asrService;
  final VisionService _visionService;

  AgentServiceFacade({
    DemoAIService? demoService,
    UnifiedTtsService? ttsService,
    UnifiedAsrService? asrService,
    VisionService? visionService,
  }) : _demoService = demoService ?? DemoAIService(),
       _ttsService = ttsService ?? UnifiedTtsService(),
       _asrService = asrService ?? UnifiedAsrService(),
       _visionService = visionService ?? VisionService();

  // ────────────────────────── 统一输入处理 ──────────────────────────

  /// 统一处理用户输入（文字 / 语音 / 图片）
  ///
  /// [text] 用户输入文本或语音转写
  /// [imagePath] 可选的图片路径
  /// [inputType] 输入类型标识：text | voice | image | mixed
  Future<AgentResult> processInput({
    String? text,
    String? imagePath,
    String inputType = 'text',
  }) async {
    final input = text ?? '';
    try {
      final result = await _demoService.process(
        input,
        imagePath: imagePath,
      );
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('processInput 失败: $e');
    }
  }

  // ────────────────────────── 意图识别 ──────────────────────────

  /// 意图识别
  ///
  /// 返回标准化意图标签，供上层路由决策。
  Future<AgentResult> detectIntent(String text) async {
    try {
      final result = await _demoService.detectIntent(text);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('detectIntent 失败: $e', intent: 'unknown');
    }
  }

  // ────────────────────────── 视觉能力 ──────────────────────────

  /// OCR 文字识别
  Future<AgentResult> recognizeText(String imagePath) async {
    // 1. 检查是否配置了百度OCR
    if (APIConfig.isBaiduOcrConfigured) {
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
                  ? '未能识别到文字，请重新拍摄'
                  : '识别结果：\n${result.data!.text}',
              spokenText: result.data!.text.isEmpty
                  ? '未能识别到文字，请重新拍摄'
                  : '已识别到文字：${result.data!.text}',
              nextAction: 'answer',
              recommendedVolunteerTags: const ['视障协助'],
            );
          }
        }
      } catch (e) {
        // 真实OCR失败，降级到Demo
        AppLogger.warning('真实OCR失败，降级到Demo: $e');
      }
    }

    // 2. fallback到Demo OCR
    try {
      final result = await _demoService.recognizeText(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error('recognizeText 失败: $e', intent: 'ocr_text');
    }
  }

  /// 场景描述
  Future<AgentResult> describeScene(String imagePath) async {
    // 1. 优先使用智谱AI
    if (_visionService.hasRealService) {
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
          recommendedVolunteerTags: const ['视障协助', '老人陪同'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.describeScene(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error(
        'describeScene 失败: $e',
        intent: 'scene_describe',
      );
    }
  }

  /// 颜色识别
  Future<AgentResult> recognizeColor(String imagePath) async {
    // 1. 优先使用智谱AI
    if (_visionService.hasRealService) {
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
          recommendedVolunteerTags: const ['视障协助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.recognizeColor(imagePath);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error(
        'recognizeColor 失败: $e',
        intent: 'color_identify',
      );
    }
  }

  /// 药品确认
  Future<AgentResult> checkMedicine(String imagePath) async {
    // 1. 优先使用智谱AI
    if (_visionService.hasRealService) {
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
          recommendedVolunteerTags: const ['药品说明协助', '视障协助'],
          safetyFlags: const ['not_medical_diagnosis'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process(
        '帮我看看这个药品',
        imagePath: imagePath,
      );
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'medicine_check',
      );
    } catch (e) {
      return AgentResult.error(
        'checkMedicine 失败: $e',
        intent: 'medicine_check',
      );
    }
  }

  /// 钞票识别
  Future<AgentResult> recognizeMoney(String imagePath) async {
    // 1. 优先使用智谱AI
    if (_visionService.hasRealService) {
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
          recommendedVolunteerTags: const ['视障协助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process(
        '这是多少钱',
        imagePath: imagePath,
      );
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'money_identify',
      );
    } catch (e) {
      return AgentResult.error(
        'recognizeMoney 失败: $e',
        intent: 'money_identify',
      );
    }
  }

  /// 物体识别
  Future<AgentResult> identifyObject(String imagePath) async {
    // 1. 优先使用智谱AI
    if (_visionService.hasRealService) {
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
          recommendedVolunteerTags: const ['视障协助'],
        );
      }
    }

    // 2. fallback到Demo
    try {
      final result = await _demoService.process(
        '这是什么东西',
        imagePath: imagePath,
      );
      return _mapAIResultToAgentResult(
        result,
        overrideIntent: 'object_identify',
      );
    } catch (e) {
      return AgentResult.error(
        'identifyObject 失败: $e',
        intent: 'object_identify',
      );
    }
  }

  // ────────────────────────── 安全检测 ──────────────────────────

  /// 紧急意图检测
  Future<AgentResult> detectEmergency(String text) async {
    try {
      final result = await _demoService.detectEmergency(text);
      return _mapAIResultToAgentResult(result);
    } catch (e) {
      return AgentResult.error(
        'detectEmergency 失败: $e',
        intent: 'emergency',
      );
    }
  }

  // ────────────────────────── 内部映射 ──────────────────────────

  /// 将 DemoAIService 的 AIResult 映射为标准 AgentResult
  AgentResult _mapAIResultToAgentResult(
    AIResult result, {
    String? overrideIntent,
  }) {
    if (!result.success) {
      return AgentResult.error(
        result.error ?? '未知错误',
        intent: overrideIntent ?? 'unknown',
      );
    }

    final data = result.data ?? {};
    final intent = overrideIntent ??
        (data['intent'] as String? ?? 'unknown');
    final demoIntent = DemoAiIntent.fromWireName(
      data['demoIntent'] as String?,
    );

    final isEmergency = data['isEmergency'] == true ||
        intent == 'emergency' ||
        demoIntent == DemoAiIntent.emergency;

    final requiresHumanFallback =
        data['requiresHumanFallback'] == true ||
            data['nextStatus'] == 'matching' ||
            demoIntent == DemoAiIntent.needHuman ||
            demoIntent == DemoAiIntent.fallback;

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

    // 推荐志愿者标签
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
          ? '确认并继续'
          : (canResolveByAi ? '继续' : '转人工协助'),
      'secondaryAction': isEmergency ? '撤销（10秒内）' : '重新描述',
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
          ? (demoIntent == DemoAiIntent.fallback
              ? 'AI 低信心，无法判断'
              : '需要真人确认或协助')
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
        return const ['药品说明协助', '视障协助'];
      case DemoAiIntent.navigation:
      case DemoAiIntent.environmentDescription:
        return const ['视障协助', '普通问路'];
      case DemoAiIntent.translation:
      case DemoAiIntent.moneyRecognition:
        return const ['手语 / 听障沟通', '视障协助'];
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
        return const ['视障协助', '老人陪同'];
      case DemoAiIntent.colorRecognition:
        return const ['视障协助'];
      case DemoAiIntent.emergency:
        return const ['紧急陪伴'];
      case DemoAiIntent.needHuman:
        final context = data['contextIntent'] as String?;
        if (context == 'medication_check') {
          return const ['药品说明协助'];
        }
        return const ['视障协助', '普通问路'];
      case DemoAiIntent.fallback:
        return const ['视障协助', '普通问路', '老人陪同'];
    }
  }

  String _uiTitle(DemoAiIntent intent, bool isEmergency) {
    if (isEmergency) return '检测到紧急情况';
    switch (intent) {
      case DemoAiIntent.ocrText:
        return 'AI 已识别文字';
      case DemoAiIntent.sceneDescription:
        return '场景描述';
      case DemoAiIntent.objectIdentify:
        return '物体识别';
      case DemoAiIntent.colorRecognition:
        return '颜色识别';
      case DemoAiIntent.moneyRecognition:
        return '钞票识别';
      case DemoAiIntent.translation:
        return '转译协助';
      case DemoAiIntent.environmentDescription:
        return '环境描述';
      case DemoAiIntent.navigation:
        return '导航协助';
      case DemoAiIntent.medicationCheck:
        return '药品确认';
      case DemoAiIntent.emergency:
        return '紧急求助';
      case DemoAiIntent.needHuman:
        return '需要真人协助';
      case DemoAiIntent.fallback:
        return 'AI 不确定';
    }
  }

  // ────────────────────────── TTS 语音朗读 ──────────────────────────

  /// 朗读文本
  ///
  /// 使用统一 TTS 服务（优先 MiniMax，fallback 到本地 TTS）。
  /// [text] 要朗读的文本
  /// [voiceId] MiniMax 音色 ID（可选）
  Future<void> speakText(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    try {
      await _ttsService.speak(text, voiceId: voiceId);
      AppLogger.info('AgentServiceFacade 朗读文本: $text');
    } catch (e) {
      AppLogger.error('AgentServiceFacade 朗读失败', e);
      rethrow;
    }
  }

  /// 停止朗读
  Future<void> stopSpeaking() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      AppLogger.error('停止朗读失败', e);
    }
  }

  /// 是否正在朗读
  bool get isSpeaking => _ttsService.isSpeaking;

  // ────────────────────────── ASR 语音输入 ──────────────────────────

  /// 是否正在录音/识别
  bool get isListening => _asrService.isListening;

  /// 开始语音输入（录音 + 识别）
  ///
  /// 返回识别到的文本。调用后进入录音状态，
  /// 需要调用 [stopVoiceInput] 来停止录音并获取最终结果。
  Future<String> startVoiceInput() async {
    try {
      AppLogger.info('AgentServiceFacade 开始语音输入');
      return await _asrService.startListening();
    } catch (e) {
      AppLogger.error('语音输入启动失败', e);
      rethrow;
    }
  }

  /// 停止语音输入
  Future<void> stopVoiceInput() async {
    try {
      AppLogger.info('AgentServiceFacade 停止语音输入');
      await _asrService.stopListening();
    } catch (e) {
      AppLogger.error('停止语音输入失败', e);
    }
  }
}
