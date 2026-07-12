import '../../config/app_config.dart';

/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = '共感LinkAble';
  static const String appTagline = 'AI驱动的视障人士智能互助平台';
  static const String appVersion = '1.0.1';

  // Supabase配置：Phase-1 只允许从 .env 读取。
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 超时配置
  static const int connectionTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒
  static const int aiResponseTimeout = 10000; // 10秒

  // 匹配配置
  static const int matchingTimeoutSeconds = 30;
  static const int maxMatchingRadiusKm = 50;
  static const int sosBroadcastRadiusKm = 5;

  // WebRTC配置
  static const List<Map<String, String>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  // 紧急检测关键词
  static const List<String> emergencyKeywords = [
    '救命',
    'help',
    '紧急',
    '危险',
    '受伤',
    '摔倒',
    '火灾',
    '地震',
    'sos',
    '报警',
    '医生',
    '救护车',
  ];

  // AI意图类型
  static const String intentOcr = 'ocr';
  static const String intentSceneDescription = 'scene_description';
  static const String intentColorRecognition = 'color_recognition';
  static const String intentObjectRecognition = 'object_recognition';
  static const String intentNavigation = 'navigation';
  static const String intentTranslation = 'translation';
  static const String intentGeneral = 'general';
  static const String intentEmergency = 'emergency';

  // 用户角色
  static const String roleSeeker = 'seeker';
  static const String roleVolunteer = 'volunteer';
  static const String roleBoth = 'both';

  // 障碍类型
  static const String disabilityVisual = 'visual';
  static const String disabilityHearing = 'hearing';
  static const String disabilityPhysical = 'physical';
  static const String disabilityElderly = 'elderly';
  static const String disabilityTemporary = 'temporary';

  // 志愿者等级
  static const int volunteerLevelMin = 1;
  static const int volunteerLevelMax = 7;

  // 帮助请求状态
  static const String statusCreated = 'created';
  static const String statusAiProcessing = 'ai_processing';
  static const String statusAiResolved = 'ai_resolved';
  static const String statusMatching = 'matching';
  static const String statusConnected = 'connected';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  // 紧急程度
  static const String urgencyNormal = 'normal';
  static const String urgencyImportant = 'important';
  static const String urgencyUrgent = 'urgent';
  static const String urgencyEmergency = 'emergency';

  // 存储键名
  static const String keyUserId = 'user_id';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';
  static const String keyDisabilityType = 'disability_type';
  static const String keyAccessibilityPrefs = 'accessibility_prefs';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyHighContrastMode = 'high_contrast_mode';
  static const String keyFontScale = 'font_scale';
  static const String keyVoiceSpeed = 'voice_speed';
  static const String keyHapticFeedback = 'haptic_feedback';

  // 默认无障碍偏好
  static const double defaultFontScale = 1.0;
  static const double defaultVoiceSpeed = 1.0;
  static const bool defaultHapticFeedback = true;
  static const bool defaultHighContrastMode = false;

  // 图片压缩配置
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;

  // 录音配置
  static const String audioFormat = 'aac';
  static const int maxRecordingDurationSeconds = 300; // 5分钟

  // 评分配置
  static const int minRating = 1;
  static const int maxRating = 5;

  // 缓存配置
  static const int cacheMaxAgeHours = 24;
  static const int maxCacheSizeMB = 100;

  // 重试配置
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000;

  // 心跳配置
  static const int heartbeatIntervalSeconds = 30;
  static const int heartbeatTimeoutSeconds = 90;
}
