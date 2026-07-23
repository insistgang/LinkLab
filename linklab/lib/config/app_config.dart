// 应用配置
// 竞赛 MVP 默认 Demo-first；RealMode 只在显式开启时初始化基础设施。

import '../core/utils/logger.dart';

/// 应用运行模式
enum AppMode {
  demo, // 演示模式：使用模拟数据，不依赖网络
  real, // 真实模式：允许初始化真实基础设施
}

/// 应用配置类
class AppConfig {
  AppConfig._();

  static const String _supabaseUrlEnvKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';
  static const String _enableRealAiEnvKey = 'LINKABLE_ENABLE_REAL_AI';

  // 竞赛版：默认锁定 Demo 主线，避免真实配置污染 3 分钟演示。
  static bool get isCompetitionDemoOnly => demoMode;

  static AppMode _mode = AppMode.demo;
  static bool _presenterMode = false;
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static bool _supabaseInitialized = false;
  static bool _realAiEnabled = false;

  /// 获取当前模式
  static AppMode get mode => _mode;

  /// Supabase URL，仅来自 .env。
  static String get supabaseUrl => _supabaseUrl;

  /// Supabase anon key，仅来自 .env。不要在日志或 UI 中输出。
  static String get supabaseAnonKey => _supabaseAnonKey;

  /// 只有 URL 与 anon key 都有效，才允许显式 RealMode 初始化。
  static bool get hasSupabaseConfig =>
      _isValidSupabaseUrl(_supabaseUrl) &&
      _supabaseAnonKey.isNotEmpty &&
      !_supabaseAnonKey.startsWith('YOUR_');

  /// 是否已经具备初始化 Supabase client 的条件。
  static bool get canInitializeSupabase => hasSupabaseConfig;

  /// 本启动流程是否已经成功初始化 Supabase client。
  static bool get supabaseInitialized => _supabaseInitialized;

  /// 是否处于演示模式。
  static bool get demoMode => _mode == AppMode.demo;

  static set demoMode(bool value) {
    if (value) {
      setDemoMode();
    } else {
      setRealMode();
    }
  }

  /// 是否为演示模式
  static bool get isDemoMode => demoMode;

  /// 是否为真实模式
  static bool get isRealMode => _mode == AppMode.real;

  /// 是否启用竞赛演示员预置会话。
  static bool get presenterMode => _presenterMode;

  /// 是否允许 AI facade 调用真实外部 AI / OCR / Vision API。
  ///
  /// 注意：这不是 RealMode 开关。竞赛演示仍可保持 DemoMode，只在此 flag
  /// 显式开启时尝试真实 AI，失败后仍由 facade 自动回落到 Demo fallback。
  static bool get realAiEnabled => _realAiEnabled;

  /// 从 .env 读取运行配置。
  ///
  /// 规则：
  /// - 默认 fallback 到 DemoMode，保障竞赛主线不依赖外部服务。
  /// - 显式 `preferRealMode: true` 且配置完整时才进入 RealMode。
  /// - SUPABASE_SERVICE_ROLE_KEY 即使存在也不会读取或使用。
  static void configureFromEnvironment(
    Map<String, String> env, {
    bool preferRealMode = false,
    bool enablePresenterSessionOnFallback = true,
    bool enableRealAIFromEnvironment = true,
  }) {
    _supabaseUrl = (env[_supabaseUrlEnvKey] ?? '').trim();
    _supabaseAnonKey = (env[_supabaseAnonKeyEnvKey] ?? '').trim();
    _supabaseInitialized = false;
    _realAiEnabled =
        enableRealAIFromEnvironment && _readBool(env[_enableRealAiEnvKey]);

    if (preferRealMode && hasSupabaseConfig) {
      _applyMode(AppMode.real, logChange: false);
      disablePresenterMode();
      AppLogger.info('RealMode 默认启动：已从 .env 读取 Supabase URL 与 anon key');
      return;
    }

    final fallbackReason = hasSupabaseConfig
        ? '竞赛 MVP 默认锁定 Demo 主线'
        : '缺少有效的 SUPABASE_URL 或 SUPABASE_ANON_KEY';
    configureDemoFallback(
      reason: fallbackReason,
      enablePresenterSession: enablePresenterSessionOnFallback,
    );

    if (_realAiEnabled) {
      AppLogger.warning('真实 AI API 已由 .env 显式开启，失败时仍会回落 DemoMode');
    }
  }

  /// Phase-1 的真实模式默认配置。
  static void configureRealModeDefaults() {
    if (!hasSupabaseConfig) {
      configureDemoFallback(reason: 'Supabase 配置不完整，无法进入 RealMode');
      return;
    }

    _applyMode(AppMode.real);
    disablePresenterMode();
  }

  /// Demo fallback。用于缺少配置或 Supabase 初始化失败。
  static void configureDemoFallback({
    required String reason,
    bool enablePresenterSession = true,
  }) {
    _applyMode(AppMode.demo, logChange: false);
    if (enablePresenterSession) {
      enablePresenterMode();
    } else {
      disablePresenterMode();
    }
    AppLogger.warning('已回退 DemoMode：$reason');
  }

  static void markSupabaseInitialized() {
    _supabaseInitialized = true;
  }

  static void markSupabaseUnavailable() {
    _supabaseInitialized = false;
  }

  /// 竞赛 Demo 默认配置。保留给测试和手动演示入口显式调用。
  static void configureCompetitionDemoDefaults({
    bool enablePresenterSession = true,
  }) {
    lockCompetitionDemoMode();
    _realAiEnabled = false;
    if (enablePresenterSession) {
      enablePresenterMode();
    } else {
      disablePresenterMode();
    }
  }

  static void enablePresenterMode() {
    _presenterMode = true;
    AppLogger.info('演示员预置会话已启用');
  }

  static void disablePresenterMode() {
    _presenterMode = false;
    AppLogger.info('演示员预置会话已关闭');
  }

  /// 兼容旧命名：现在只代表“显式切到 DemoMode”，不再阻止 RealMode 默认启动。
  static void lockCompetitionDemoMode() {
    _applyMode(AppMode.demo, logChange: false);
    AppLogger.info('已切换到 DemoMode');
  }

  /// 切换到演示模式
  static void setDemoMode() {
    _applyMode(AppMode.demo);
  }

  /// 切换到真实模式
  static void setRealMode() {
    if (!hasSupabaseConfig) {
      configureDemoFallback(reason: '缺少 Supabase 配置，拒绝切换到 RealMode');
      return;
    }

    _applyMode(AppMode.real);
    disablePresenterMode();
  }

  /// 切换模式
  static void toggleMode() {
    if (demoMode) {
      setRealMode();
    } else {
      setDemoMode();
    }
  }

  /// Demo fallback 判定。
  ///
  /// Phase-1 只真实初始化 Supabase client，短信/AI/WebRTC/SOS/真实匹配尚未接入，
  /// 因此这些能力仍允许走本地 Demo fallback，避免主链路出现死路。
  static bool shouldUseDemoFallback({
    required String feature,
    bool logWhenDisabled = true,
  }) {
    final enabled = demoMode || isRealMode;
    if (!enabled && logWhenDisabled) {
      AppLogger.warning('$feature 请求 Demo fallback，但当前 fallback 不可用');
    }
    return enabled;
  }

  static void _applyMode(AppMode mode, {bool logChange = true}) {
    _mode = mode;
    if (!logChange) {
      return;
    }

    if (mode == AppMode.demo) {
      AppLogger.info('切换到 DemoMode');
    } else {
      AppLogger.warning('切换到 RealMode');
    }
  }

  static bool _isValidSupabaseUrl(String value) {
    if (value.isEmpty || value.startsWith('YOUR_')) {
      return false;
    }

    final uri = Uri.tryParse(value);
    final isLoopbackHost =
        uri?.host == 'localhost' ||
        uri?.host == '127.0.0.1' ||
        uri?.host == '::1';
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || (uri.scheme == 'http' && isLoopbackHost)) &&
        uri.host.isNotEmpty;
  }

  static bool _readBool(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y' ||
        normalized == 'on' ||
        normalized == 'enabled';
  }
}

/// 功能开关配置
class FeatureFlags {
  /// Phase-2 只接入 Supabase Auth 登录态。
  static bool get enableSupabaseAuth =>
      AppConfig.isRealMode && AppConfig.supabaseInitialized;

  /// Phase-1 不接真实 WebRTC。
  static bool get enableWebRTC => false;

  /// Phase-1 不接真实匹配引擎。
  static bool get enableRealMatching => false;

  /// Phase-1 不接真实推送。
  static bool get enablePushNotification => false;

  /// 真实 AI 仅在 .env 显式开启时使用。
  static bool get enableRealAI => AppConfig.realAiEnabled;

  /// Phase-3 只接最小真实数据库 CRUD。
  ///
  /// 范围仅限 profiles / help_requests / volunteer_profiles。匹配、AI、地图、
  /// WebRTC、SOS 和短信仍保持关闭。
  static bool get enableDatabaseSync =>
      AppConfig.isRealMode && AppConfig.supabaseInitialized;

  /// Phase-1 不启用真实位置服务。
  static bool get enableLocationService => false;

  /// Phase-1 不接真实短信。
  static bool get enableRealSMS => false;

  /// Phase-1 不开放交互式社区入口。
  static bool get enableCommunity => false;

  /// 首页精选故事卡片。RealMode Phase-1 不加载社区服务。
  static bool get enableStaticStoryCards => AppConfig.demoMode;

  /// 安心积分
  static bool get enablePoints => false;

  /// 徽章
  static bool get enableBadges => false;

  /// 排班
  static bool get enableSchedule => false;

  /// 后台入口
  static bool get enableAdminDashboard => false;

  /// 通话录音
  static bool get enableCallRecording => false;
}

/// 演示模式配置
class DemoConfig {
  /// AI思考延迟（秒）
  static const int aiThinkingDelay = 2;

  /// 匹配等待时间（秒）
  static const int matchingDelay = 4;

  /// 通话自动结束时间（秒）
  static const int callAutoEndDuration = 30;

  /// SOS响应时间（秒）
  static const int sosResponseDelay = 5;

  /// 是否显示演示水印
  static bool get showDemoWatermark => AppConfig.demoMode;
}

/// 网络配置
class NetworkConfig {
  /// Supabase URL
  static String get supabaseUrl => AppConfig.supabaseUrl;

  /// Supabase Anon Key
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  /// 连接超时（秒）
  static const int connectionTimeout = 10;

  /// 读取超时（秒）
  static const int readTimeout = 30;
}
