/// AgentServiceFacade 統一輸出模型
///
/// AGENTS.md §5.4 要求：所有 AI 能力輸出必須經過歸一化，不得直接展示原始模型響應。
class AgentResult {
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
  final Map<String, dynamic>? uiCopy;
  final bool success;
  final String? error;

  const AgentResult({
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
    this.uiCopy,
    required this.success,
    this.error,
  });

  factory AgentResult.success({
    required String intent,
    String urgency = 'normal',
    required double confidence,
    required bool canResolveByAi,
    required String answerText,
    required String spokenText,
    required String nextAction,
    String? handoffReason,
    List<String> recommendedVolunteerTags = const [],
    List<String> safetyFlags = const [],
    Map<String, dynamic>? uiCopy,
  }) {
    return AgentResult(
      intent: intent,
      urgency: urgency,
      confidence: confidence,
      canResolveByAi: canResolveByAi,
      answerText: answerText,
      spokenText: spokenText,
      nextAction: nextAction,
      handoffReason: handoffReason,
      recommendedVolunteerTags: recommendedVolunteerTags,
      safetyFlags: safetyFlags,
      uiCopy: uiCopy,
      success: true,
    );
  }

  factory AgentResult.error(String errorMessage, {String? intent}) {
    return AgentResult(
      intent: intent ?? 'unknown',
      urgency: 'normal',
      confidence: 0.0,
      canResolveByAi: false,
      answerText: '處理出錯，請稍後重試或轉人工協助。',
      spokenText: '處理出錯，請稍後重試或轉人工協助。',
      nextAction: 'show_fallback',
      success: false,
      error: errorMessage,
      uiCopy: {
        'title': '處理出錯',
        'body': '當前服務暫時不可用，你可以稍後再試或轉人工協助。',
        'primaryAction': '轉人工協助',
        'secondaryAction': '稍後重試',
      },
    );
  }

  /// 緊急意圖快速構造
  factory AgentResult.emergency({
    required String answerText,
    required String spokenText,
    List<String> safetyFlags = const [],
  }) {
    return AgentResult.success(
      intent: 'emergency',
      urgency: 'emergency',
      confidence: 1.0,
      canResolveByAi: false,
      answerText: answerText,
      spokenText: spokenText,
      nextAction: 'trigger_sos',
      safetyFlags: safetyFlags,
      uiCopy: {
        'title': '檢測到緊急情況',
        'body': answerText,
        'primaryAction': '確認並繼續',
        'secondaryAction': '撤銷（10秒內）',
      },
    );
  }

  bool get isEmergency => urgency == 'emergency';

  bool get requiresHumanFallback =>
      !canResolveByAi || nextAction == 'match_volunteer';

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'urgency': urgency,
      'confidence': confidence,
      'canResolveByAi': canResolveByAi,
      'answerText': answerText,
      'spokenText': spokenText,
      'nextAction': nextAction,
      'handoffReason': handoffReason,
      'recommendedVolunteerTags': recommendedVolunteerTags,
      'safetyFlags': safetyFlags,
      'uiCopy': uiCopy,
      'success': success,
      'error': error,
    };
  }
}
