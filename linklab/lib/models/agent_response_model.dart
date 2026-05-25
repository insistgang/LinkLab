import 'ai_result_model.dart';
import 'demo_ai_intent.dart';

/// UI 文案子类
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

/// Agent 标准化响应模型
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

  /// 从旧的 AIResult 快捷转换为标准 AgentResponse（迁移用）
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

  /// 从旧的 AIResult 转换为标准 AgentResponse
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
        return '环境描述涉及安全风险，建议志愿者陪同确认';
      case DemoAiIntent.navigation:
        return '导航路线需要实时确认，建议志愿者协助';
      case DemoAiIntent.medicationCheck:
        return '药品确认涉及健康安全，建议志愿者或药师复核';
      case DemoAiIntent.emergency:
        return '检测到紧急情况，需要立即启动 SOS';
      case DemoAiIntent.needHuman:
        return '用户主动要求转人工';
      case DemoAiIntent.fallback:
        return 'AI 无法识别意图，建议转人工';
      default:
        return null;
    }
  }

  static List<String> _volunteerTags(DemoAiIntent intent) {
    switch (intent) {
      case DemoAiIntent.ocrText:
        return ['视障协助', '阅读辅助'];
      case DemoAiIntent.sceneDescription:
      case DemoAiIntent.objectIdentify:
        return ['视障协助', '出行陪同'];
      case DemoAiIntent.colorRecognition:
        return ['视障协助', '日常生活'];
      case DemoAiIntent.moneyRecognition:
        return ['视障协助', '财务辅助'];
      case DemoAiIntent.translation:
        return ['听障转译', '沟通协助'];
      case DemoAiIntent.environmentDescription:
        return ['视障协助', '出行陪同'];
      case DemoAiIntent.navigation:
        return ['医院导诊', '出行陪同'];
      case DemoAiIntent.medicationCheck:
        return ['视障协助', '医院导诊'];
      case DemoAiIntent.emergency:
        return ['紧急救援', '医疗协助'];
      case DemoAiIntent.needHuman:
        return ['综合协助'];
      case DemoAiIntent.fallback:
        return ['综合协助'];
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
          title: 'AI 已识别文字内容',
          body: '我已读出图片中的文字，请复核关键信息。',
          primaryAction: '继续识别',
          secondaryAction: '转人工确认',
        );
      case DemoAiIntent.sceneDescription:
        return const UiCopy(
          title: 'AI 场景描述完成',
          body: '我已描述当前画面，前方环境基本安全，请慢速前进。',
          primaryAction: '继续描述',
          secondaryAction: '转人工陪同',
        );
      case DemoAiIntent.objectIdentify:
        return const UiCopy(
          title: 'AI 物体识别完成',
          body: '我已识别画面中的主要物体，请确认是否正确。',
          primaryAction: '继续识别',
          secondaryAction: '转人工确认',
        );
      case DemoAiIntent.colorRecognition:
        return const UiCopy(
          title: 'AI 颜色识别完成',
          body: '我已识别主体颜色，光线可能影响判断，请复核。',
          primaryAction: '重新识别',
          secondaryAction: '转人工确认',
        );
      case DemoAiIntent.moneyRecognition:
        return const UiCopy(
          title: 'AI 面额识别完成',
          body: '我已识别钞票面额，请用触摸特征或设备复核。',
          primaryAction: '继续识别',
          secondaryAction: '转人工确认',
        );
      case DemoAiIntent.translation:
        return const UiCopy(
          title: 'AI 转译完成',
          body: '我已整理成短句，可转人工协助沟通。',
          primaryAction: '继续转译',
          secondaryAction: '转人工协助',
        );
      case DemoAiIntent.environmentDescription:
        return const UiCopy(
          title: 'AI 环境提示',
          body: '前方通道基本可走，建议转志愿者陪同确认。',
          primaryAction: '找志愿者',
          secondaryAction: '稍后处理',
        );
      case DemoAiIntent.navigation:
        return const UiCopy(
          title: 'AI 导航提示',
          body: '复杂动线建议转人工陪同，我可以马上为你找志愿者。',
          primaryAction: '找志愿者',
          secondaryAction: '稍后处理',
        );
      case DemoAiIntent.medicationCheck:
        return const UiCopy(
          title: 'AI 药品识别',
          body: '我已读取药品信息，不做医疗诊断，建议转人工或药师确认。',
          primaryAction: '找志愿者确认',
          secondaryAction: '稍后处理',
        );
      case DemoAiIntent.emergency:
        return const UiCopy(
          title: '紧急模式已启动',
          body: '请在 10 秒内撤销，否则将广播附近志愿者并通知紧急联系人。',
          primaryAction: '立即撤销',
          secondaryAction: '确认紧急',
        );
      case DemoAiIntent.needHuman:
        return const UiCopy(
          title: '正在转接志愿者',
          body: '已收到转人工请求，正在为你匹配附近合适的志愿者。',
          primaryAction: '等待匹配',
          secondaryAction: '取消求助',
        );
      case DemoAiIntent.fallback:
        return const UiCopy(
          title: 'AI 无法判断',
          body: '这个问题我还不能稳定判断，建议转人工或换个说法再试。',
          primaryAction: '转人工',
          secondaryAction: '重新描述',
        );
    }
  }
}
