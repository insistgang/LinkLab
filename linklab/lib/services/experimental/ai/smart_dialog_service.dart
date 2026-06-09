import 'dart:async';
import 'ai_service.dart';
import 'intent_classifier.dart';
import 'urgency_detector.dart';
import 'dialog_manager.dart';

/// 智能對話服務
/// F1 智能對話的核心實現
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
    // 智能對話服務總是可用（有本地降級方案）
    return true;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    try {
      // 1. 獲取或創建會話上下文
      final session = context ?? _dialogManager.createSession();

      // 2. 添加用戶消息到歷史
      _dialogManager.addUserMessage(
        session.sessionId,
        input,
        imageUrl: imageUrl,
      );

      // 3. 意圖識別
      final intentResult = _intentClassifier.classify(input, imageUrl: imageUrl);

      // 4. 緊急度檢測
      final urgencyResult = _urgencyDetector.detect(
        input,
        intent: intentResult.intent,
      );

      // 5. 判斷是否需要轉人工
      final needsHuman = IntentClassifier.needsHumanHandoff(
        intentResult.intent,
        intentResult.confidence,
      );

      // 6. 生成響應
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

      // 7. 添加助手響應到歷史
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
      return AIResponse.error('智能對話服務異常: $e');
    }
  }

  /// 生成轉人工響應
  String _generateHandoffResponse(IntentType intent) {
    switch (intent) {
      case IntentType.medicalConsultation:
        return '您諮詢的是醫療相關問題，爲了您的健康安全，我將爲您轉接專業醫療志願者，請稍候。';
      case IntentType.medicineConfirmation:
        return '藥品使用需要謹慎確認，我將爲您轉接志願者協助覈對藥品信息，請稍候。';
      case IntentType.emotionalSupport:
        return '我理解您可能需要情感支持，讓我爲您轉接心理支持志願者，他們會更好地陪伴您。';
      case IntentType.emergency:
        return '檢測到緊急情況，正在爲您啓動緊急求助流程，請保持冷靜。';
      default:
        return '這個問題可能需要人工協助，正在爲您轉接志願者，請稍候。';
    }
  }

  /// 生成AI響應
  String _generateAIResponse(
    String input,
    IntentType intent,
    String sessionId,
  ) {
    // 獲取對話歷史用於上下文理解
    final history = _dialogManager.getFormattedHistory(sessionId, maxMessages: 5);

    // 根據意圖類型生成不同響應
    switch (intent) {
      case IntentType.generalChat:
        return _generateGeneralResponse(input, history);
      case IntentType.textRecognition:
        return '我來幫您識別圖片中的文字，請稍候。';
      case IntentType.objectRecognition:
        return '我來幫您識別這個物體，請稍候。';
      case IntentType.colorRecognition:
        return '我來幫您識別顏色，請稍候。';
      case IntentType.currencyRecognition:
        return '我來幫您識別鈔票面額，請稍候。';
      case IntentType.translation:
        return '我來幫您翻譯這段文字，請稍候。';
      case IntentType.navigation:
        return '我來幫您查詢路線，請稍候。';
      case IntentType.sceneDescription:
        return '我來幫您描述周圍環境，請稍候。';
      default:
        return '我明白了，讓我來幫您處理。';
    }
  }

  /// 生成通用對話響應
  String _generateGeneralResponse(
    String input,
    List<Map<String, String>> history,
  ) {
    // 簡單的規則響應（實際項目中可接入大模型API）
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('你好') || lowerInput.contains('您好') || lowerInput.contains('hello')) {
      return '您好！我是LinkAble智能助手，有什麼可以幫助您的嗎？您可以問我關於文字識別、物體識別、顏色識別、導航等問題。';
    }

    if (lowerInput.contains('謝謝') || lowerInput.contains('感謝')) {
      return '不客氣！很高興能幫到您。如果還有其他問題，隨時告訴我。';
    }

    if (lowerInput.contains('再見') || lowerInput.contains('拜拜')) {
      return '再見！祝您有美好的一天，有需要隨時找我。';
    }

    if (lowerInput.contains('能做什麼') || lowerInput.contains('功能') || lowerInput.contains('幫助')) {
      return '我可以幫您：1. 識別圖片中的文字並朗讀；2. 識別物體和場景；3. 識別顏色；4. 識別鈔票面額；5. 翻譯外文；6. 提供導航指引；7. 描述周圍環境。請告訴我您需要什麼幫助？';
    }

    // 默認響應
    return '我理解您的意思。您可以拍照或詳細描述一下，我會盡力幫助您。';
  }

  /// 獲取對話上下文
  DialogContext? getDialogContext(String sessionId) {
    // 從DialogManager獲取會話（需要添加此方法）
    return null;
  }

  /// 結束對話會話
  Future<void> endSession(String sessionId) async {
    await _dialogManager.endSession(sessionId);
  }

  /// 獲取對話統計
  DialogStatistics getStatistics(String sessionId) {
    return _dialogManager.getStatistics(sessionId);
  }
}
