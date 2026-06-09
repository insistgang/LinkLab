// 應用配置
// 競賽 MVP 默認 Demo-first；RealMode 只在顯式開啓時初始化基礎設施。

import '../core/utils/logger.dart';

/// 應用運行模式
enum AppMode {
  demo, // 演示模式：使用模擬數據，不依賴網絡
  real, // 真實模式：允許初始化真實基礎設施
}

/// 應用配置類
class AppConfig {
  AppConfig._();

  static const String _supabaseUrlEnvKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  // 競賽版：默認鎖定 Demo 主線，避免真實配置污染 3 分鐘演示。
  static bool get isCompetitionDemoOnly => demoMode;

  static AppMode _mode = AppMode.demo;
  static bool _presenterMode = false;
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static bool _supabaseInitialized = false;

  /// 獲取當前模式
  static AppMode get mode => _mode;

  /// Supabase URL，僅來自 .env。
  static String get supabaseUrl => _supabaseUrl;

  /// Supabase anon key，僅來自 .env。不要在日誌或 UI 中輸出。
  static String get supabaseAnonKey => _supabaseAnonKey;

  /// 只有 URL 與 anon key 都有效，才允許顯式 RealMode 初始化。
  static bool get hasSupabaseConfig =>
      _isValidSupabaseUrl(_supabaseUrl) &&
      _supabaseAnonKey.isNotEmpty &&
      !_supabaseAnonKey.startsWith('YOUR_');

  /// 是否已經具備初始化 Supabase client 的條件。
  static bool get canInitializeSupabase => hasSupabaseConfig;

  /// 本啓動流程是否已經成功初始化 Supabase client。
  static bool get supabaseInitialized => _supabaseInitialized;

  /// 是否處於演示模式。
  static bool get demoMode => _mode == AppMode.demo;

  static set demoMode(bool value) {
    if (value) {
      setDemoMode();
    } else {
      setRealMode();
    }
  }

  /// 是否爲演示模式
  static bool get isDemoMode => demoMode;

  /// 是否爲真實模式
  static bool get isRealMode => _mode == AppMode.real;

  /// 是否啓用競賽演示員預置會話。
  static bool get presenterMode => _presenterMode;

  /// 從 .env 讀取運行配置。
  ///
  /// 規則：
  /// - 默認 fallback 到 DemoMode，保障競賽主線不依賴外部服務。
  /// - 顯式 `preferRealMode: true` 且配置完整時才進入 RealMode。
  /// - SUPABASE_SERVICE_ROLE_KEY 即使存在也不會讀取或使用。
  static void configureFromEnvironment(
    Map<String, String> env, {
    bool preferRealMode = false,
    bool enablePresenterSessionOnFallback = true,
  }) {
    _supabaseUrl = (env[_supabaseUrlEnvKey] ?? '').trim();
    _supabaseAnonKey = (env[_supabaseAnonKeyEnvKey] ?? '').trim();
    _supabaseInitialized = false;

    if (preferRealMode && hasSupabaseConfig) {
      _applyMode(AppMode.real, logChange: false);
      disablePresenterMode();
      AppLogger.info('RealMode 默認啓動：已從 .env 讀取 Supabase URL 與 anon key');
      return;
    }

    final fallbackReason = hasSupabaseConfig
        ? '競賽 MVP 默認鎖定 Demo 主線'
        : '缺少有效的 SUPABASE_URL 或 SUPABASE_ANON_KEY';
    configureDemoFallback(
      reason: fallbackReason,
      enablePresenterSession: enablePresenterSessionOnFallback,
    );
  }

  /// Phase-1 的真實模式默認配置。
  static void configureRealModeDefaults() {
    if (!hasSupabaseConfig) {
      configureDemoFallback(reason: 'Supabase 配置不完整，無法進入 RealMode');
      return;
    }

    _applyMode(AppMode.real);
    disablePresenterMode();
  }

  /// Demo fallback。用於缺少配置或 Supabase 初始化失敗。
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

  /// 競賽 Demo 默認配置。保留給測試和手動演示入口顯式調用。
  static void configureCompetitionDemoDefaults({
    bool enablePresenterSession = true,
  }) {
    lockCompetitionDemoMode();
    if (enablePresenterSession) {
      enablePresenterMode();
    } else {
      disablePresenterMode();
    }
  }

  static void enablePresenterMode() {
    _presenterMode = true;
    AppLogger.info('演示員預置會話已啓用');
  }

  static void disablePresenterMode() {
    _presenterMode = false;
    AppLogger.info('演示員預置會話已關閉');
  }

  /// 兼容舊命名：現在只代表“顯式切到 DemoMode”，不再阻止 RealMode 默認啓動。
  static void lockCompetitionDemoMode() {
    _applyMode(AppMode.demo, logChange: false);
    AppLogger.info('已切換到 DemoMode');
  }

  /// 切換到演示模式
  static void setDemoMode() {
    _applyMode(AppMode.demo);
  }

  /// 切換到真實模式
  static void setRealMode() {
    if (!hasSupabaseConfig) {
      configureDemoFallback(reason: '缺少 Supabase 配置，拒絕切換到 RealMode');
      return;
    }

    _applyMode(AppMode.real);
    disablePresenterMode();
  }

  /// 切換模式
  static void toggleMode() {
    if (demoMode) {
      setRealMode();
    } else {
      setDemoMode();
    }
  }

  /// Demo fallback 判定。
  ///
  /// Phase-1 只真實初始化 Supabase client，短信/AI/WebRTC/SOS/真實匹配尚未接入，
  /// 因此這些能力仍允許走本地 Demo fallback，避免主鏈路出現死路。
  static bool shouldUseDemoFallback({
    required String feature,
    bool logWhenDisabled = true,
  }) {
    final enabled = demoMode || isRealMode;
    if (!enabled && logWhenDisabled) {
      AppLogger.warning('$feature 請求 Demo fallback，但當前 fallback 不可用');
    }
    return enabled;
  }

  static void _applyMode(AppMode mode, {bool logChange = true}) {
    _mode = mode;
    if (!logChange) {
      return;
    }

    if (mode == AppMode.demo) {
      AppLogger.info('切換到 DemoMode');
    } else {
      AppLogger.warning('切換到 RealMode');
    }
  }

  static bool _isValidSupabaseUrl(String value) {
    if (value.isEmpty || value.startsWith('YOUR_')) {
      return false;
    }

    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }
}

/// 功能開關配置
class FeatureFlags {
  /// Phase-2 只接入 Supabase Auth 登錄態。
  static bool get enableSupabaseAuth =>
      AppConfig.isRealMode && AppConfig.supabaseInitialized;

  /// Phase-1 不接真實 WebRTC。
  static bool get enableWebRTC => false;

  /// Phase-1 不接真實匹配引擎。
  static bool get enableRealMatching => false;

  /// Phase-1 不接真實推送。
  static bool get enablePushNotification => false;

  /// Phase-1 不接真實 AI。
  static bool get enableRealAI => false;

  /// Phase-3 只接最小真實數據庫 CRUD。
  ///
  /// 範圍僅限 profiles / help_requests / volunteer_profiles。匹配、AI、地圖、
  /// WebRTC、SOS 和短信仍保持關閉。
  static bool get enableDatabaseSync =>
      AppConfig.isRealMode && AppConfig.supabaseInitialized;

  /// Phase-1 不啓用真實位置服務。
  static bool get enableLocationService => false;

  /// Phase-1 不接真實短信。
  static bool get enableRealSMS => false;

  /// Phase-1 不開放交互式社區入口。
  static bool get enableCommunity => false;

  /// 首頁精選故事卡片。RealMode Phase-1 不加載社區服務。
  static bool get enableStaticStoryCards => AppConfig.demoMode;

  /// 安心積分
  static bool get enablePoints => false;

  /// 徽章
  static bool get enableBadges => false;

  /// 排班
  static bool get enableSchedule => false;

  /// 後臺入口
  static bool get enableAdminDashboard => false;

  /// 通話錄音
  static bool get enableCallRecording => false;
}

/// 演示模式配置
class DemoConfig {
  /// AI思考延遲（秒）
  static const int aiThinkingDelay = 2;

  /// 匹配等待時間（秒）
  static const int matchingDelay = 4;

  /// 通話自動結束時間（秒）
  static const int callAutoEndDuration = 30;

  /// SOS響應時間（秒）
  static const int sosResponseDelay = 5;

  /// 是否顯示演示水印
  static bool get showDemoWatermark => AppConfig.demoMode;
}

/// 網絡配置
class NetworkConfig {
  /// Supabase URL
  static String get supabaseUrl => AppConfig.supabaseUrl;

  /// Supabase Anon Key
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  /// 連接超時（秒）
  static const int connectionTimeout = 10;

  /// 讀取超時（秒）
  static const int readTimeout = 30;
}
