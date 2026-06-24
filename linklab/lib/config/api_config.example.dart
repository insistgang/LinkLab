/// 本地 API 配置文件。
/// AGENTS.md §4.2 / §4.6：競賽版默認走 Demo 主線，此文件只允許保存本地實驗配置，
/// 不得提交到版本控制；請以 `api_config.example.dart` 爲模板複製生成。
class APIConfig {
  // ==================== 百度OCR API配置 ====================
  /// 百度OCR API Key
  /// 獲取地址：https://ai.baidu.com/tech/ocr
  static String baiduOcrApiKey = '';

  /// 百度OCR Secret Key
  static String baiduOcrSecretKey = '';

  /// 百度OCR Access Token（自動獲取，無需手動設置）
  static String? _baiduOcrAccessToken;
  static DateTime? _baiduTokenExpireTime;

  /// 獲取百度OCR Access Token
  static String? get baiduOcrAccessToken => _baiduOcrAccessToken;

  /// 設置百度OCR Access Token
  static void setBaiduOcrAccessToken(String token, int expiresIn) {
    _baiduOcrAccessToken = token;
    // 提前1小時過期
    _baiduTokenExpireTime = DateTime.now().add(
      Duration(seconds: expiresIn - 3600),
    );
  }

  /// 檢查百度OCR Token是否有效
  static bool get isBaiduOcrTokenValid {
    if (_baiduOcrAccessToken == null || _baiduTokenExpireTime == null) {
      return false;
    }
    return DateTime.now().isBefore(_baiduTokenExpireTime!);
  }

  /// 百度OCR服務端點
  static const String baiduOcrBaseUrl =
      'https://aip.baidubce.com/rest/2.0/ocr/v1';

  /// 百度OCR Token獲取地址
  static const String baiduOcrTokenUrl =
      'https://aip.baidubce.com/oauth/2.0/token';

  // ==================== 通義千問VL API配置 ====================
  /// 通義千問API Key
  /// 獲取地址：https://dashscope.aliyun.com/
  static String qwenApiKey = '';

  /// 通義千問VL服務端點
  static const String qwenBaseUrl = 'https://dashscope.aliyuncs.com/api/v1';

  /// 通義千問VL模型名稱
  static const String qwenModel = 'qwen-vl-plus';

  /// 通義千問VL最大token數
  static const int qwenMaxTokens = 800;

  /// 通義千問VL溫度參數（0-1，越低越確定）
  static const double qwenTemperature = 0.3;

  // ==================== 科大訊飛語音API配置 ====================
  /// 科大訊飛APP ID
  /// 獲取地址：https://www.xfyun.cn/
  static String xfyunAppId = '';

  /// 科大訊飛API Key
  static String xfyunApiKey = '';

  /// 科大訊飛API Secret
  static String xfyunApiSecret = '';

  /// 科大訊飛語音聽寫（ASR）WebSocket地址
  static const String xfyunAsrWsUrl = 'wss://iat-api.xfyun.cn/v2/iat';

  /// 科大訊飛語音合成（TTS）WebSocket地址
  static const String xfyunTtsWsUrl = 'wss://tts-api.xfyun.cn/v2/tts';

  /// 科大訊飛語音聽寫HTTP地址（備選）
  static const String xfyunAsrHttpUrl = 'http://api.xfyun.cn/v1/service/v1/iat';

  /// 科大訊飛語音合成HTTP地址（備選）
  static const String xfyunTtsHttpUrl = 'http://api.xfyun.cn/v1/service/v1/tts';

  // ==================== MiniMax TTS API配置 ====================
  /// MiniMax API Key
  /// 獲取地址：https://platform.minimaxi.com/
  static String minimaxApiKey = '';

  /// MiniMax API 服務端點
  static const String minimaxApiHost = 'https://api.minimaxi.com';

  /// MiniMax TTS API地址
  static const String minimaxTtsEndpoint = '$minimaxApiHost/v1/t2a_v2';

  /// MiniMax TTS 模型名稱
  static const String minimaxTtsModel = 'speech-2.8-hd';

  // ==================== 百度翻譯API配置（可選） ====================
  /// 百度翻譯APP ID
  static String baiduTranslateAppId = '';

  /// 百度翻譯密鑰
  static String baiduTranslateSecret = '';

  /// 百度翻譯API地址
  static const String baiduTranslateUrl =
      'https://fanyi-api.baidu.com/api/trans/vip/translate';

  // ==================== 智譜AI視覺API配置 ====================
  /// 智譜AI API Key
  /// 獲取地址：https://open.bigmodel.cn/
  static String zhipuApiKey = '';

  /// 智譜AI服務端點
  static const String zhipuBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';

  /// 智譜AI視覺模型名稱
  static const String zhipuVlModel = 'glm-4v-flash';

  // ==================== 通用配置 ====================
  /// 請求超時時間（秒）
  static const int requestTimeoutSeconds = 30;

  /// 連接超時時間（秒）
  static const int connectionTimeoutSeconds = 10;

  /// 最大重試次數
  static const int maxRetries = 3;

  /// 重試間隔（毫秒）
  static const int retryDelayMs = 1000;

  /// 是否啓用日誌
  static const bool enableLogging = true;

  // ==================== 配置驗證方法 ====================

  /// 驗證百度OCR配置是否完整
  static bool get isBaiduOcrConfigured {
    return baiduOcrApiKey.isNotEmpty && baiduOcrSecretKey.isNotEmpty;
  }

  /// 驗證通義千問配置是否完整
  static bool get isQwenConfigured {
    return qwenApiKey.isNotEmpty;
  }

  /// 驗證科大訊飛配置是否完整
  static bool get isXfyunConfigured {
    return xfyunAppId.isNotEmpty &&
        xfyunApiKey.isNotEmpty &&
        xfyunApiSecret.isNotEmpty;
  }

  /// 驗證百度翻譯配置是否完整
  static bool get isBaiduTranslateConfigured {
    return baiduTranslateAppId.isNotEmpty && baiduTranslateSecret.isNotEmpty;
  }

  /// 驗證MiniMax TTS配置是否完整
  static bool get isMinimaxTtsConfigured {
    return minimaxApiKey.isNotEmpty;
  }

  /// 驗證智譜AI配置是否完整
  static bool get isZhipuConfigured {
    return zhipuApiKey.isNotEmpty;
  }

  /// 獲取配置狀態摘要
  static Map<String, bool> getConfigStatus() {
    return {
      'baiduOcr': isBaiduOcrConfigured,
      'qwenVL': isQwenConfigured,
      'xfyun': isXfyunConfigured,
      'baiduTranslate': isBaiduTranslateConfigured,
      'minimaxTts': isMinimaxTtsConfigured,
      'zhipuVl': isZhipuConfigured,
    };
  }

  /// 檢查是否有任何AI服務已配置
  static bool get hasAnyServiceConfigured {
    return isBaiduOcrConfigured ||
        isQwenConfigured ||
        isXfyunConfigured ||
        isMinimaxTtsConfigured ||
        isZhipuConfigured;
  }

  // ==================== 配置初始化方法 ====================

  /// 從環境變量或配置文件初始化
  /// 實際項目中可以從安全存儲中讀取
  static void initialize({
    String? baiduOcrKey,
    String? baiduOcrSecret,
    String? qwenKey,
    String? xfyunApp,
    String? xfyunKey,
    String? xfyunSecret,
    String? translateAppId,
    String? translateSecret,
    String? zhipuKey,
    String? minimaxKey,
  }) {
    if (baiduOcrKey != null) baiduOcrApiKey = baiduOcrKey;
    if (baiduOcrSecret != null) baiduOcrSecretKey = baiduOcrSecret;
    if (qwenKey != null) qwenApiKey = qwenKey;
    if (xfyunApp != null) xfyunAppId = xfyunApp;
    if (xfyunKey != null) xfyunApiKey = xfyunKey;
    if (xfyunSecret != null) xfyunApiSecret = xfyunSecret;
    if (translateAppId != null) baiduTranslateAppId = translateAppId;
    if (translateSecret != null) baiduTranslateSecret = translateSecret;
    if (zhipuKey != null) zhipuApiKey = zhipuKey;
    if (minimaxKey != null) minimaxApiKey = minimaxKey;
  }

  /// 重置所有配置（用於測試）
  static void reset() {
    baiduOcrApiKey = '';
    baiduOcrSecretKey = '';
    _baiduOcrAccessToken = null;
    _baiduTokenExpireTime = null;
    qwenApiKey = '';
    xfyunAppId = '';
    xfyunApiKey = '';
    xfyunApiSecret = '';
    minimaxApiKey = '';
    baiduTranslateAppId = '';
    baiduTranslateSecret = '';
    zhipuApiKey = '';
  }
}

/// API錯誤類型
enum APIErrorType {
  /// 網絡錯誤
  networkError,

  /// 認證失敗
  authenticationError,

  /// 請求參數錯誤
  invalidParameter,

  /// 服務不可用
  serviceUnavailable,

  /// 配額不足
  quotaExceeded,

  /// 超時
  timeout,

  /// 未知錯誤
  unknown,
}

/// API錯誤信息
class APIError {
  final APIErrorType type;
  final String message;
  final String? originalError;
  final int? statusCode;

  const APIError({
    required this.type,
    required this.message,
    this.originalError,
    this.statusCode,
  });

  /// 創建網絡錯誤
  factory APIError.network(String? original) {
    return APIError(
      type: APIErrorType.networkError,
      message: '網絡連接失敗，請檢查網絡設置',
      originalError: original,
    );
  }

  /// 創建認證錯誤
  factory APIError.authentication(String? original) {
    return APIError(
      type: APIErrorType.authenticationError,
      message: 'API認證失敗，請檢查API密鑰配置',
      originalError: original,
    );
  }

  /// 創建超時錯誤
  factory APIError.timeout(String? original) {
    return APIError(
      type: APIErrorType.timeout,
      message: '請求超時，請稍後重試',
      originalError: original,
    );
  }

  /// 創建服務不可用錯誤
  factory APIError.serviceUnavailable(String? original, int? code) {
    return APIError(
      type: APIErrorType.serviceUnavailable,
      message: 'AI服務暫時不可用，請稍後重試',
      originalError: original,
      statusCode: code,
    );
  }

  /// 創建配額不足錯誤
  factory APIError.quotaExceeded(String? original) {
    return APIError(
      type: APIErrorType.quotaExceeded,
      message: 'API調用配額已用完，請聯繫管理員',
      originalError: original,
    );
  }

  @override
  String toString() => 'APIError[$type]: $message';
}

/// API響應包裝類
class APIResponse<T> {
  final bool isSuccess;
  final T? data;
  final APIError? error;

  const APIResponse._({required this.isSuccess, this.data, this.error});

  /// 創建成功響應
  factory APIResponse.success(T data) {
    return APIResponse._(isSuccess: true, data: data);
  }

  /// 創建失敗響應
  factory APIResponse.failure(APIError error) {
    return APIResponse._(isSuccess: false, error: error);
  }

  /// 是否失敗
  bool get isFailure => !isSuccess;

  /// 獲取數據或拋出異常
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error?.message ?? 'Unknown error');
  }
}
