import 'ai_result_model.dart';
import 'demo_ai_intent.dart';

/// UI 文案子類
/// 符合 AGENTS.md §5.4 要求
class UiCopy {
  final String title;
  final String body;
  final String primaryAction;
  final String secondaryAction;

  const UiCopy({
    required this.title,
    required this.body,
    required this.primaryAction,
    required this.secondaryAction,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'primary_action': primaryAction,
        'secondary_action': secondaryAction,
      };

  factory UiCopy.fromJson(Map<String, dynamic> json) {
    return UiCopy(
      title: json['title'] as String,
      body: json['body'] as String,
      primaryAction: json['primary_action'] as String,
      secondaryAction: json['secondary_action'] as String,
    );
  }
}

/// Agent 標準化響應模型
/// 符合 AGENTS.md §5.4 要求
class AgentResponse {
  final String requestId;
  final String intent;
  final String urgency;
  final double confidence;
  final bool canResolveByAi;
  final String answerText;
  final String spokenText;
  final String nextAction;
  final String? handoffReason;
  final List<String> recommendedVolunteerTags;
  final List<String> safetyFlags;
  final UiCopy uiCopy;

  const AgentResponse({
    required this.requestId,
    required this.intent,
    required this.urgency,
    required this.confidence,
    required this.canResolveByAi,
    required this.answerText,
    required this.spokenText,
    required this.nextAction,
    this.handoffReason,
    this.recommendedVolunteerTags = const [],
    this.safetyFlags = const [],
    required this.uiCopy,
  });

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'intent': intent,
        'urgency': urgency,
        'confidence': confidence,
        'can_resolve_by_ai': canResolveByAi,
        'answer_text': answerText,
        'spoken_text': spokenText,
        'next_action': nextAction,
        'handoff_reason': handoffReason,
        'recommended_volunteer_tags': recommendedVolunteerTags,
        'safety_flags': safetyFlags,
        'ui_copy': uiCopy.toJson(),
      };

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      requestId: json['request_id'] as String,
      intent: json['intent'] as String,
      urgency: json['urgency'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      canResolveByAi: json['can_resolve_by_ai'] as bool,
      answerText: json['answer_text'] as String,
      spokenText: json['spoken_text'] as String,
      nextAction: json['next_action'] as String,
      handoffReason: json['handoff_reason'] as String?,
      recommendedVolunteerTags:
          List<String>.from(json['recommended_volunteer_tags'] as List),
      safetyFlags: List<String>.from(json['safety_flags'] as List),
      uiCopy: UiCopy.fromJson(json['ui_copy'] as Map<String, dynamic>),
    );
  }

  /// 從舊的 AIResult 快捷轉換爲標準 AgentResponse（遷移用）
  factory AgentResponse.fromAIResult(AIResult result, {String? requestId}) {
    final data = result.data;
    final intentName = data?['intent'] as String? ?? 'fallback';
    final intent = DemoAiIntent.fromWireName(intentName);
    final extra = <String, dynamic>{...?data};
    return AgentResponse.fromDemoResult(
      requestId: requestId ?? 'migrated-${DateTime.now().millisecondsSinceEpoch}',
      demoIntent: intent,
      answerText: result.text,
      extra: extra,
    );
  }

  /// 從舊的 AIResult 轉換爲標準 AgentResponse
  factory AgentResponse.fromDemoResult({
    required String requestId,
    required DemoAiIntent demoIntent,
    required String answerText,
    Map<String, dynamic>? extra,
  }) {
    final intent = demoIntent.wireName;
    final confidence = _extractConfidence(extra) ?? _defaultConfidence(demoIntent);
    final urgency = _extractUrgency(extra, demoIntent);
    final canResolve = _canResolveByAi(demoIntent);
    final nextAction = _resolveNextAction(demoIntent, canResolve);
    final handoffReason = canResolve ? null : _handoffReason(demoIntent);
    final tags = _volunteerTags(demoIntent);
    final flags = _safetyFlags(demoIntent);
    final uiCopy = _defaultUiCopy(demoIntent);

    return AgentResponse(
      requestId: requestId,
      intent: intent,
      urgency: urgency,
      confidence: confidence,
      canResolveByAi: canResolve,
      answerText: answerText,
      spokenText: answerText,
      nextAction: nextAction,
      handoffReason: handoffReason,
      recommendedVolunteerTags: tags,
      safetyFlags: flags,
      uiCopy: uiCopy,
    );
  }

  static double? _extractConfidence(Map<String, dynamic>? extra) {
    if (extra == null) return null;
    final value = extra['confidence'];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return null;
  }

  static double _defaultConfidence(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.ocrText:
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
      case DemoAiIntent.colorRecognition:
      case DemoAiIntent.moneyRecognition:
        return 0.95;
      case DemoAiIntent.translation:
      case DemoAiIntent.environmentDescription:
      case DemoAiIntent.navigation:
      case DemoAiIntent.medicationCheck:
        return 0.90;
      case DemoAiIntent.emergency:
        return 0.98;
      case DemoAiIntent.needHuman:
        return 0.85;
      case DemoAiIntent.fallback:
        return 0.45;
    }
  }

  static String _extractUrgency(
      Map<String, dynamic>? extra, DemoAiIntent intent) {
    if (intent == DemoAiIntent.emergency) return 'emergency';
    if (extra == null) return 'normal';
    final level = extra['urgencyLevel'] as String?;
    if (level == 'high') return 'elevated';
    if (level == 'normal') return 'normal';
    return 'normal';
  }

  static bool _canResolveByAi(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.ocrText:
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
      case DemoAiIntent.colorRecognition:
      case DemoAiIntent.moneyRecognition:
      case DemoAiIntent.translation:
        return true;
      case DemoAiIntent.environmentDescription:
      case DemoAiIntent.navigation:
      case DemoAiIntent.medicationCheck:
        return false;
      case DemoAiIntent.emergency:
      case DemoAiIntent.needHuman:
      case DemoAiIntent.fallback:
        return false;
    }
  }

  static String _resolveNextAction(DemoAiIntent intent, bool canResolve) {
    if (intent == DemoAiIntent.emergency) return 'trigger_sos';
    if (intent == DemoAiIntent.needHuman) return 'match_volunteer';
    if (!canResolve) return 'match_volunteer';
    return 'answer';
  }

  static String? _handoffReason(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.environmentDescription:
        return '環境描述涉及安全風險，建議志願者陪同確認';
      case DemoAiIntent.navigation:
        return '導航路線需要實時確認，建議志願者協助';
      case DemoAiIntent.medicationCheck:
        return '藥品確認涉及健康安全，建議志願者或藥師複覈';
      case DemoAiIntent.emergency:
        return '檢測到緊急情況，需要立即啓動 SOS';
      case DemoAiIntent.needHuman:
        return '用戶主動要求轉人工';
      case DemoAiIntent.fallback:
        return 'AI 無法識別意圖，建議轉人工';
      default:
        return null;
    }
  }

  static List<String> _volunteerTags(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.ocrText:
        return ['視障協助', '閱讀輔助'];
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
        return ['視障協助', '出行陪同'];
      case DemoAiIntent.colorRecognition:
        return ['視障協助', '日常生活'];
      case DemoAiIntent.moneyRecognition:
        return ['視障協助', '財務輔助'];
      case DemoAiIntent.translation:
        return ['聽障轉譯', '溝通協助'];
      case DemoAiIntent.environmentDescription:
        return ['視障協助', '出行陪同'];
      case DemoAiIntent.navigation:
        return ['醫院導診', '出行陪同'];
      case DemoAiIntent.medicationCheck:
        return ['視障協助', '醫院導診'];
      case DemoAiIntent.emergency:
        return ['緊急救援', '醫療協助'];
      case DemoAiIntent.needHuman:
        return ['綜合協助'];
      case DemoAiIntent.fallback:
        return ['綜合協助'];
    }
  }

  static List<String> _safetyFlags(DemoAiIntent intent) {
    if (intent == DemoAiIntent.emergency) {
      return ['sos_triggered'];
    }
    if (intent == DemoAiIntent.medicationCheck) {
      return ['not_medical_diagnosis'];
    }
    return [];
  }

  static UiCopy _defaultUiCopy(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.ocrText:
        return const UiCopy(
          title: 'AI 已識別文字內容',
          body: '我已讀出圖片中的文字，請複覈關鍵信息。',
          primaryAction: '繼續識別',
          secondaryAction: '轉人工確認',
        );
      case DemoAiIntent.sceneDescription:
        return const UiCopy(
          title: 'AI 場景描述完成',
          body: '我已描述當前畫面，前方環境基本安全，請慢速前進。',
          primaryAction: '繼續描述',
          secondaryAction: '轉人工陪同',
        );
      case DemoAiIntent.objectIdentify:
        return const UiCopy(
          title: 'AI 物體識別完成',
          body: '我已識別畫面中的主要物體，請確認是否正確。',
          primaryAction: '繼續識別',
          secondaryAction: '轉人工確認',
        );
      case DemoAiIntent.colorRecognition:
        return const UiCopy(
          title: 'AI 顏色識別完成',
          body: '我已識別主體顏色，光線可能影響判斷，請複覈。',
          primaryAction: '重新識別',
          secondaryAction: '轉人工確認',
        );
      case DemoAiIntent.moneyRecognition:
        return const UiCopy(
          title: 'AI 面額識別完成',
          body: '我已識別鈔票面額，請用觸摸特徵或設備複覈。',
          primaryAction: '繼續識別',
          secondaryAction: '轉人工確認',
        );
      case DemoAiIntent.translation:
        return const UiCopy(
          title: 'AI 轉譯完成',
          body: '我已整理成短句，可轉人工協助溝通。',
          primaryAction: '繼續轉譯',
          secondaryAction: '轉人工協助',
        );
      case DemoAiIntent.environmentDescription:
        return const UiCopy(
          title: 'AI 環境提示',
          body: '前方通道基本可走，建議轉志願者陪同確認。',
          primaryAction: '找志願者',
          secondaryAction: '稍後處理',
        );
      case DemoAiIntent.navigation:
        return const UiCopy(
          title: 'AI 導航提示',
          body: '複雜動線建議轉人工陪同，我可以馬上爲你找志願者。',
          primaryAction: '找志願者',
          secondaryAction: '稍後處理',
        );
      case DemoAiIntent.medicationCheck:
        return const UiCopy(
          title: 'AI 藥品識別',
          body: '我已讀取藥品信息，不做醫療診斷，建議轉人工或藥師確認。',
          primaryAction: '找志願者確認',
          secondaryAction: '稍後處理',
        );
      case DemoAiIntent.emergency:
        return const UiCopy(
          title: '緊急模式已啓動',
          body: '請在 10 秒內撤銷，否則將廣播附近志願者並通知緊急聯繫人。',
          primaryAction: '立即撤銷',
          secondaryAction: '確認緊急',
        );
      case DemoAiIntent.needHuman:
        return const UiCopy(
          title: '正在轉接志願者',
          body: '已收到轉人工請求，正在爲你匹配附近合適的志願者。',
          primaryAction: '等待匹配',
          secondaryAction: '取消求助',
        );
      case DemoAiIntent.fallback:
        return const UiCopy(
          title: 'AI 無法判斷',
          body: '這個問題我還不能穩定判斷，建議轉人工或換個說法再試。',
          primaryAction: '轉人工',
          secondaryAction: '重新描述',
        );
    }
  }
}
