/// AI服务统一接口
/// 定义所有AI能力的基础契约
abstract class AIService {
  /// 处理用户输入，返回AI响应
  /// [input] - 用户输入文本
  /// [imageUrl] - 可选的图片URL（用于多模态输入）
  /// [context] - 可选的对话上下文
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  });

  /// 检查服务是否可用
  Future<bool> isAvailable();

  /// 获取服务名称
  String get serviceName;
}

/// AI响应数据模型
class AIResponse {
  /// 响应文本内容
  final String text;

  /// 识别到的意图类型
  final IntentType intent;

  /// 紧急度级别
  final UrgencyLevel urgency;

  /// 是否需要转人工
  final bool needsHuman;

  /// 置信度 (0.0 - 1.0)
  final double confidence;

  /// 附加数据
  final Map<String, dynamic>? extraData;

  /// 错误信息（如有）
  final String? errorMessage;

  /// 是否成功
  final bool isSuccess;

  const AIResponse({
    required this.text,
    this.intent = IntentType.unknown,
    this.urgency = UrgencyLevel.normal,
    this.needsHuman = false,
    this.confidence = 0.0,
    this.extraData,
    this.errorMessage,
    this.isSuccess = true,
  });

  /// 创建错误响应
  factory AIResponse.error(String message) {
    return AIResponse(
      text: '服务暂时不可用，请稍后重试',
      intent: IntentType.unknown,
      urgency: UrgencyLevel.normal,
      needsHuman: true,
      isSuccess: false,
      errorMessage: message,
    );
  }

  /// 创建需要转人工的响应
  factory AIResponse.handoff(String text, {IntentType intent = IntentType.unknown}) {
    return AIResponse(
      text: text,
      intent: intent,
      needsHuman: true,
      confidence: 1.0,
    );
  }
}

/// 意图类型枚举
enum IntentType {
  /// 文字识别
  textRecognition,

  /// 物体识别
  objectRecognition,

  /// 颜色识别
  colorRecognition,

  /// 钞票识别
  currencyRecognition,

  /// 翻译
  translation,

  /// 导航
  navigation,

  /// 环境描述
  sceneDescription,

  /// 药品确认
  medicineConfirmation,

  /// 医疗问诊
  medicalConsultation,

  /// 情感陪伴
  emotionalSupport,

  /// 紧急求助
  emergency,

  /// 通用对话
  generalChat,

  /// 未知意图
  unknown,
}

/// 紧急度级别枚举
enum UrgencyLevel {
  /// 普通
  normal,

  /// 重要
  important,

  /// 紧急
  urgent,

  /// 危急
  emergency,
}

/// 对话上下文
class DialogContext {
  /// 会话ID
  final String sessionId;

  /// 历史消息列表
  final List<DialogMessage> history;

  /// 当前轮数
  final int turnCount;

  /// 用户ID
  final String? userId;

  /// 创建时间
  final DateTime createdAt;

  const DialogContext({
    required this.sessionId,
    this.history = const [],
    this.turnCount = 0,
    this.userId,
    required this.createdAt,
  });

  /// 添加新消息
  DialogContext addMessage(DialogMessage message) {
    return DialogContext(
      sessionId: sessionId,
      history: [...history, message],
      turnCount: turnCount + 1,
      userId: userId,
      createdAt: createdAt,
    );
  }

  /// 获取最近N条消息
  List<DialogMessage> getRecentMessages(int count) {
    if (history.length <= count) return history;
    return history.sublist(history.length - count);
  }

  /// 创建新会话
  factory DialogContext.create({String? userId}) {
    return DialogContext(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: DateTime.now(),
    );
  }
}

/// 对话消息
class DialogMessage {
  /// 消息角色
  final MessageRole role;

  /// 消息内容
  final String content;

  /// 消息时间
  final DateTime timestamp;

  /// 关联图片URL
  final String? imageUrl;

  const DialogMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

/// 消息角色
enum MessageRole {
  user,
  assistant,
  system,
}

/// AI服务配置
class AIServiceConfig {
  /// 百度OCR API Key
  final String? baiduOcrApiKey;

  /// 百度OCR Secret Key
  final String? baiduOcrSecretKey;

  /// 通义千问API Key
  final String? qwenApiKey;

  /// 科大讯飞APP ID
  final String? xfyunAppId;

  /// 科大讯飞API Key
  final String? xfyunApiKey;

  /// 请求超时时间（秒）
  final int timeoutSeconds;

  /// 是否启用离线模式
  final bool enableOfflineMode;

  /// 最大重试次数
  final int maxRetries;

  const AIServiceConfig({
    this.baiduOcrApiKey,
    this.baiduOcrSecretKey,
    this.qwenApiKey,
    this.xfyunAppId,
    this.xfyunApiKey,
    this.timeoutSeconds = 10,
    this.enableOfflineMode = true,
    this.maxRetries = 3,
  });
}
