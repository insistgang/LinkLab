/// API配置示例文件
/// 复制此文件为 api_config.dart 并填入您的真实API密钥
///
/// 注意：api_config.dart 不应提交到版本控制，已添加到 .gitignore
///
/// === 获取API密钥的地址 ===
///
/// 百度OCR API：
/// - 官网：https://ai.baidu.com/tech/ocr
/// - 注册百度AI开放平台账号，创建应用获取API Key和Secret Key
///
/// 通义千问VL API：
/// - 官网：https://dashscope.aliyun.com/
/// - 注册阿里云账号，开通DashScope服务获取API Key
///
/// 科大讯飞语音API：
/// - 官网：https://www.xfyun.cn/
/// - 注册讯飞开放平台账号，创建应用获取AppID、API Key和API Secret
///
/// ============================================

class APIConfig {
  // ==================== 百度OCR API配置 ====================
  /// 百度OCR API Key
  static String baiduOcrApiKey = 'YOUR_BAIDU_OCR_API_KEY';

  /// 百度OCR Secret Key
  static String baiduOcrSecretKey = 'YOUR_BAIDU_OCR_SECRET_KEY';

  /// 百度OCR Access Token（自动获取，无需手动设置）
  static String? _baiduOcrAccessToken;
  static DateTime? _baiduTokenExpireTime;

  /// 获取百度OCR Access Token
  static String? get baiduOcrAccessToken => _baiduOcrAccessToken;

  /// 设置百度OCR Access Token
  static void setBaiduOcrAccessToken(String token, int expiresIn) {
    _baiduOcrAccessToken = token;
    // 提前1小时过期
    _baiduTokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600));
  }

  /// 检查百度OCR Token是否有效
  static bool get isBaiduOcrTokenValid {
    if (_baiduOcrAccessToken == null || _baiduTokenExpireTime == null) {
      return false;
    }
    return DateTime.now().isBefore(_baiduTokenExpireTime!);
  }

  /// 百度OCR服务端点
  static const String baiduOcrBaseUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1';

  /// 百度OCR Token获取地址
  static const String baiduOcrTokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';

  // ==================== 通义千问VL API配置 ====================
  /// 通义千问API Key
  static String qwenApiKey = 'YOUR_QWEN_API_KEY';

  /// 通义千问VL服务端点
  static const String qwenBaseUrl = 'https://dashscope.aliyuncs.com/api/v1';

  /// 通义千问VL模型名称
  static const String qwenModel = 'qwen-vl-plus';

  /// 通义千问VL最大token数
  static const int qwenMaxTokens = 800;

  /// 通义千问VL温度参数（0-1，越低越确定）
  static const double qwenTemperature = 0.3;

  // ==================== 科大讯飞语音API配置 ====================
  /// 科大讯飞APP ID
  static String xfyunAppId = 'YOUR_XFYUN_APP_ID';

  /// 科大讯飞API Key
  static String xfyunApiKey = 'YOUR_XFYUN_API_KEY';

  /// 科大讯飞API Secret
  static String xfyunApiSecret = 'YOUR_XFYUN_API_SECRET';

  /// 科大讯飞语音听写（ASR）WebSocket地址
  static const String xfyunAsrWsUrl = 'wss://iat-api.xfyun.cn/v2/iat';

  /// 科大讯飞语音合成（TTS）WebSocket地址
  static const String xfyunTtsWsUrl = 'wss://tts-api.xfyun.cn/v2/tts';

  /// 科大讯飞语音听写HTTP地址（备选）
  static const String xfyunAsrHttpUrl = 'http://api.xfyun.cn/v1/service/v1/iat';

  /// 科大讯飞语音合成HTTP地址（备选）
  static const String xfyunTtsHttpUrl = 'http://api.xfyun.cn/v1/service/v1/tts';

  // ==================== 通用配置 ====================
  /// 请求超时时间（秒）
  static const int requestTimeoutSeconds = 30;

  /// 连接超时时间（秒）
  static const int connectionTimeoutSeconds = 10;

  /// 最大重试次数
  static const int maxRetries = 3;

  /// 重试间隔（毫秒）
  static const int retryDelayMs = 1000;

  /// 是否启用日志
  static const bool enableLogging = true;

  // ==================== 配置验证方法 ====================

  /// 验证百度OCR配置是否完整
  static bool get isBaiduOcrConfigured {
    return baiduOcrApiKey.isNotEmpty &&
        baiduOcrSecretKey.isNotEmpty &&
        baiduOcrApiKey != 'YOUR_BAIDU_OCR_API_KEY';
  }

  /// 验证通义千问配置是否完整
  static bool get isQwenConfigured {
    return qwenApiKey.isNotEmpty && qwenApiKey != 'YOUR_QWEN_API_KEY';
  }

  /// 验证科大讯飞配置是否完整
  static bool get isXfyunConfigured {
    return xfyunAppId.isNotEmpty &&
        xfyunApiKey.isNotEmpty &&
        xfyunApiSecret.isNotEmpty &&
        xfyunAppId != 'YOUR_XFYUN_APP_ID';
  }

  /// 获取配置状态摘要
  static Map<String, bool> getConfigStatus() {
    return {
      'baiduOcr': isBaiduOcrConfigured,
      'qwenVL': isQwenConfigured,
      'xfyun': isXfyunConfigured,
    };
  }

  /// 检查是否有任何AI服务已配置
  static bool get hasAnyServiceConfigured {
    return isBaiduOcrConfigured || isQwenConfigured || isXfyunConfigured;
  }

  // ==================== 配置初始化方法 ====================

  /// 从环境变量或配置文件初始化
  /// 实际项目中可以从安全存储中读取
  static void initialize({
    String? baiduOcrKey,
    String? baiduOcrSecret,
    String? qwenKey,
    String? xfyunApp,
    String? xfyunKey,
    String? xfyunSecret,
  }) {
    if (baiduOcrKey != null) baiduOcrApiKey = baiduOcrKey;
    if (baiduOcrSecret != null) baiduOcrSecretKey = baiduOcrSecret;
    if (qwenKey != null) qwenApiKey = qwenKey;
    if (xfyunApp != null) xfyunAppId = xfyunApp;
    if (xfyunKey != null) xfyunApiKey = xfyunKey;
    if (xfyunSecret != null) xfyunApiSecret = xfyunSecret;
  }

  /// 重置所有配置（用于测试）
  static void reset() {
    baiduOcrApiKey = '';
    baiduOcrSecretKey = '';
    _baiduOcrAccessToken = null;
    _baiduTokenExpireTime = null;
    qwenApiKey = '';
    xfyunAppId = '';
    xfyunApiKey = '';
    xfyunApiSecret = '';
  }
}

/// API错误类型
enum APIErrorType {
  /// 网络错误
  networkError,

  /// 认证失败
  authenticationError,

  /// 请求参数错误
  invalidParameter,

  /// 服务不可用
  serviceUnavailable,

  /// 配额不足
  quotaExceeded,

  /// 超时
  timeout,

  /// 未知错误
  unknown,
}

/// API错误信息
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

  /// 创建网络错误
  factory APIError.network(String? original) {
    return APIError(
      type: APIErrorType.networkError,
      message: '网络连接失败，请检查网络设置',
      originalError: original,
    );
  }

  /// 创建认证错误
  factory APIError.authentication(String? original) {
    return APIError(
      type: APIErrorType.authenticationError,
      message: 'API认证失败，请检查API密钥配置',
      originalError: original,
    );
  }

  /// 创建超时错误
  factory APIError.timeout(String? original) {
    return APIError(
      type: APIErrorType.timeout,
      message: '请求超时，请稍后重试',
      originalError: original,
    );
  }

  /// 创建服务不可用错误
  factory APIError.serviceUnavailable(String? original, int? code) {
    return APIError(
      type: APIErrorType.serviceUnavailable,
      message: 'AI服务暂时不可用，请稍后重试',
      originalError: original,
      statusCode: code,
    );
  }

  /// 创建配额不足错误
  factory APIError.quotaExceeded(String? original) {
    return APIError(
      type: APIErrorType.quotaExceeded,
      message: 'API调用配额已用完，请联系管理员',
      originalError: original,
    );
  }

  @override
  String toString() => 'APIError[$type]: $message';
}

/// API响应包装类
class APIResponse<T> {
  final bool isSuccess;
  final T? data;
  final APIError? error;

  const APIResponse._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  /// 创建成功响应
  factory APIResponse.success(T data) {
    return APIResponse._(isSuccess: true, data: data);
  }

  /// 创建失败响应
  factory APIResponse.failure(APIError error) {
    return APIResponse._(isSuccess: false, error: error);
  }

  /// 是否失败
  bool get isFailure => !isSuccess;

  /// 获取数据或抛出异常
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error?.message ?? 'Unknown error');
  }
}
