import 'dart:async';
import 'ai_service.dart';
import 'intent_classifier.dart';
import 'urgency_detector.dart';
import 'dialog_manager.dart';

/// 智能对话服务
/// F1 智能对话的核心实现
class SmartDialogService implements AIService {
  final AIServiceConfig _config;
  final IntentClassifier _intentClassifier;
  final UrgencyDetector _urgencyDetector;
  final DialogContextManager _dialogManager;

  SmartDialogService({
    required AIServiceConfig config,
    IntentClassifier? intentClassifier,
    UrgencyDetector? urgencyDetector,
    DialogContextManager? dialogManager,
  })  : _config = config,
        _intentClassifier = intentClassifier ?? IntentClassifier(),
        _urgencyDetector = urgencyDetector ?? UrgencyDetector(),
        _dialogManager = dialogManager ?? DialogContextManager();

  @override
  String get serviceName => 'SmartDialogService';

  @override
  Future<bool> isAvailable() async {
    // 智能对话服务总是可用（有本地降级方案）
    return true;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    try {
      // 1. 获取或创建会话上下文
      final session = context ?? _dialogManager.createSession();

      // 2. 添加用户消息到历史
      _dialogManager.addUserMessage(
        session.sessionId,
        input,
        imageUrl: imageUrl,
      );

      // 3. 意图识别
      final intentResult = _intentClassifier.classify(input, imageUrl: imageUrl);

      // 4. 紧急度检测
      final urgencyResult = _urgencyDetector.detect(
        input,
        intent: intentResult.intent,
      );

      // 5. 判断是否需要转人工
      final needsHuman = IntentClassifier.needsHumanHandoff(
        intentResult.intent,
        intentResult.confidence,
      );

      // 6. 生成响应
      String responseText;
      if (needsHuman) {
        responseText = _generateHandoffResponse(intentResult.intent);
      } else {
        responseText = _generateAIResponse(
          input,
          intentResult.intent,
          session.sessionId,
        );
      }

      // 7. 添加助手响应到历史
      _dialogManager.addAssistantMessage(
        session.sessionId,
        responseText,
      );

      return AIResponse(
        text: responseText,
        intent: intentResult.intent,
        urgency: urgencyResult.level,
        needsHuman: needsHuman,
        confidence: intentResult.confidence,
        extraData: {
          'sessionId': session.sessionId,
          'urgencyReason': urgencyResult.reason,
          'urgencyConfidence': urgencyResult.confidence,
        },
      );
    } catch (e) {
      return AIResponse.error('智能对话服务异常: $e');
    }
  }

  /// 生成转人工响应
  String _generateHandoffResponse(IntentType intent) {
    switch (intent) {
      case IntentType.medicalConsultation:
        return '您咨询的是医疗相关问题，为了您的健康安全，我将为您转接专业医疗志愿者，请稍候。';
      case IntentType.medicineConfirmation:
        return '药品使用需要谨慎确认，我将为您转接志愿者协助核对药品信息，请稍候。';
      case IntentType.emotionalSupport:
        return '我理解您可能需要情感支持，让我为您转接心理支持志愿者，他们会更好地陪伴您。';
      case IntentType.emergency:
        return '检测到紧急情况，正在为您启动紧急求助流程，请保持冷静。';
      default:
        return '这个问题可能需要人工协助，正在为您转接志愿者，请稍候。';
    }
  }

  /// 生成AI响应
  String _generateAIResponse(
    String input,
    IntentType intent,
    String sessionId,
  ) {
    // 获取对话历史用于上下文理解
    final history = _dialogManager.getFormattedHistory(sessionId, maxMessages: 5);

    // 根据意图类型生成不同响应
    switch (intent) {
      case IntentType.generalChat:
        return _generateGeneralResponse(input, history);
      case IntentType.textRecognition:
        return '我来帮您识别图片中的文字，请稍候。';
      case IntentType.objectRecognition:
        return '我来帮您识别这个物体，请稍候。';
      case IntentType.colorRecognition:
        return '我来帮您识别颜色，请稍候。';
      case IntentType.currencyRecognition:
        return '我来帮您识别钞票面额，请稍候。';
      case IntentType.translation:
        return '我来帮您翻译这段文字，请稍候。';
      case IntentType.navigation:
        return '我来帮您查询路线，请稍候。';
      case IntentType.sceneDescription:
        return '我来帮您描述周围环境，请稍候。';
      default:
        return '我明白了，让我来帮您处理。';
    }
  }

  /// 生成通用对话响应
  String _generateGeneralResponse(
    String input,
    List<Map<String, String>> history,
  ) {
    // 简单的规则响应（实际项目中可接入大模型API）
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('你好') || lowerInput.contains('您好') || lowerInput.contains('hello')) {
      return '您好！我是LinkAble智能助手，有什么可以帮助您的吗？您可以问我关于文字识别、物体识别、颜色识别、导航等问题。';
    }

    if (lowerInput.contains('谢谢') || lowerInput.contains('感谢')) {
      return '不客气！很高兴能帮到您。如果还有其他问题，随时告诉我。';
    }

    if (lowerInput.contains('再见') || lowerInput.contains('拜拜')) {
      return '再见！祝您有美好的一天，有需要随时找我。';
    }

    if (lowerInput.contains('能做什么') || lowerInput.contains('功能') || lowerInput.contains('帮助')) {
      return '我可以帮您：1. 识别图片中的文字并朗读；2. 识别物体和场景；3. 识别颜色；4. 识别钞票面额；5. 翻译外文；6. 提供导航指引；7. 描述周围环境。请告诉我您需要什么帮助？';
    }

    // 默认响应
    return '我理解您的意思。您可以拍照或详细描述一下，我会尽力帮助您。';
  }

  /// 获取对话上下文
  DialogContext? getDialogContext(String sessionId) {
    // 从DialogManager获取会话（需要添加此方法）
    return null;
  }

  /// 结束对话会话
  Future<void> endSession(String sessionId) async {
    await _dialogManager.endSession(sessionId);
  }

  /// 获取对话统计
  DialogStatistics getStatistics(String sessionId) {
    return _dialogManager.getStatistics(sessionId);
  }
}
