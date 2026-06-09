/// AI服務統一接口
/// 定義所有AI能力的基礎契約
abstract class AIService {
  /// 處理用戶輸入，返回AI響應
  /// [input] - 用戶輸入文本
  /// [imageUrl] - 可選的圖片URL（用於多模態輸入）
  /// [context] - 可選的對話上下文
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  });

  /// 檢查服務是否可用
  Future<bool> isAvailable();

  /// 獲取服務名稱
  String get serviceName;
}

/// AI響應數據模型
class AIResponse {
  /// 響應文本內容
  final String text;

  /// 識別到的意圖類型
  final IntentType intent;

  /// 緊急度級別
  final UrgencyLevel urgency;

  /// 是否需要轉人工
  final bool needsHuman;

  /// 置信度 (0.0 - 1.0)
  final double confidence;

  /// 附加數據
  final Map<String, dynamic>? extraData;

  /// 錯誤信息（如有）
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

  /// 創建錯誤響應
  factory AIResponse.error(String message) {
    return AIResponse(
      text: '服務暫時不可用，請稍後重試',
      intent: IntentType.unknown,
      urgency: UrgencyLevel.normal,
      needsHuman: true,
      isSuccess: false,
      errorMessage: message,
    );
  }

  /// 創建需要轉人工的響應
  factory AIResponse.handoff(String text, {IntentType intent = IntentType.unknown}) {
    return AIResponse(
      text: text,
      intent: intent,
      needsHuman: true,
      confidence: 1.0,
    );
  }
}

/// 意圖類型枚舉
enum IntentType {
  /// 文字識別
  textRecognition,

  /// 物體識別
  objectRecognition,

  /// 顏色識別
  colorRecognition,

  /// 鈔票識別
  currencyRecognition,

  /// 翻譯
  translation,

  /// 導航
  navigation,

  /// 環境描述
  sceneDescription,

  /// 藥品確認
  medicineConfirmation,

  /// 醫療問診
  medicalConsultation,

  /// 情感陪伴
  emotionalSupport,

  /// 緊急求助
  emergency,

  /// 通用對話
  generalChat,

  /// 未知意圖
  unknown,
}

/// 緊急度級別枚舉
enum UrgencyLevel {
  /// 普通
  normal,

  /// 重要
  important,

  /// 緊急
  urgent,

  /// 危急
  emergency,
}

/// 對話上下文
class DialogContext {
  /// 會話ID
  final String sessionId;

  /// 歷史消息列表
  final List<DialogMessage> history;

  /// 當前輪數
  final int turnCount;

  /// 用戶ID
  final String? userId;

  /// 創建時間
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

  /// 獲取最近N條消息
  List<DialogMessage> getRecentMessages(int count) {
    if (history.length <= count) return history;
    return history.sublist(history.length - count);
  }

  /// 創建新會話
  factory DialogContext.create({String? userId}) {
    return DialogContext(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: DateTime.now(),
    );
  }
}

/// 對話消息
class DialogMessage {
  /// 消息角色
  final MessageRole role;

  /// 消息內容
  final String content;

  /// 消息時間
  final DateTime timestamp;

  /// 關聯圖片URL
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

/// AI服務配置
class AIServiceConfig {
  /// 百度OCR API Key
  final String? baiduOcrApiKey;

  /// 百度OCR Secret Key
  final String? baiduOcrSecretKey;

  /// 通義千問API Key
  final String? qwenApiKey;

  /// 科大訊飛APP ID
  final String? xfyunAppId;

  /// 科大訊飛API Key
  final String? xfyunApiKey;

  /// 請求超時時間（秒）
  final int timeoutSeconds;

  /// 是否啓用離線模式
  final bool enableOfflineMode;

  /// 最大重試次數
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
