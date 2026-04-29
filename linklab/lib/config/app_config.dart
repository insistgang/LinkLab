// 应用配置
// 控制演示模式和真实模式的切换

import '../core/utils/logger.dart';

/// 应用运行模式
enum AppMode {
  demo, // 演示模式：使用模拟数据，不依赖网络
  real, // 真实模式：调用真实API和WebRTC
}

/// 应用配置类
class AppConfig {
  // AGENTS.md 要求竞赛版默认且强制只走 Demo 主线。
  // 真实模式保留为未来开发骨架，但当前构建不允许切换过去。
  // AGENTS.md §4.4：一旦启用真实 Supabase，只能对齐根目录 supabase/ migrations / functions；
  // linklab/supabase 仅允许以 legacy 形式保留，不再参与事实来源判定。
  static const bool isCompetitionDemoOnly = true;

  // 当前运行模式
  static AppMode _mode = AppMode.demo;
  static bool _presenterMode = false;

  /// 获取当前模式
  static AppMode get mode => _mode;

  /// 是否强制走 Demo 主线。
  /// 竞赛版启动时必须显式执行 `AppConfig.demoMode = true;`，
  /// 再由 `lockCompetitionDemoMode()` 锁死默认行为。
  static bool get demoMode => _mode == AppMode.demo;

  static set demoMode(bool value) {
    _applyMode(value, logChange: false);
  }

  /// 是否为演示模式
  static bool get isDemoMode => demoMode;

  /// 是否为真实模式
  static bool get isRealMode => !demoMode;

  /// 是否启用竞赛演示员预置会话。
  /// 默认关闭，仅由竞赛入口显式开启，避免污染测试和开发流。
  static bool get presenterMode => _presenterMode;

  /// 竞赛 Demo 默认配置。
  /// 主入口与需要演示员直达首页的测试应调用此方法，避免散落的入口遗漏
  /// demo mode / presenter mode 任一开关。
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
    AppLogger.info('竞赛演示员预置会话已启用');
  }

  static void disablePresenterMode() {
    _presenterMode = false;
    AppLogger.info('竞赛演示员预置会话已关闭');
  }

  /// 竞赛版启动入口
  static void lockCompetitionDemoMode() {
    _applyMode(true, logChange: false);
    AppLogger.info('竞赛版已锁定为 Demo 模式');
  }

  /// 切换到演示模式
  static void setDemoMode() {
    _applyMode(true);
  }

  /// 切换到真实模式
  static void setRealMode() {
    _applyMode(false);
  }

  /// 切换模式
  static void toggleMode() {
    if (isCompetitionDemoOnly) {
      AppLogger.warning('竞赛版不允许切换模式，保持 Demo 主线');
      return;
    }

    if (demoMode) {
      setRealMode();
    } else {
      setDemoMode();
    }
  }

  /// Demo fallback 判定。
  /// 所有 demo_* 服务都应通过这个开关判断自己是否应该承担竞赛版回退职责。
  static bool shouldUseDemoFallback({
    required String feature,
    bool logWhenDisabled = true,
  }) {
    final enabled = demoMode;
    if (!enabled && logWhenDisabled) {
      AppLogger.warning('$feature 请求 Demo fallback，但当前 demoMode=false');
    }
    return enabled;
  }

  static void _applyMode(bool useDemo, {bool logChange = true}) {
    if (isCompetitionDemoOnly && !useDemo) {
      _mode = AppMode.demo;
      AppLogger.warning('竞赛版已锁定 Demo 主线，忽略切换到真实模式的请求');
      return;
    }

    _mode = useDemo ? AppMode.demo : AppMode.real;
    if (!logChange) {
      return;
    }

    if (useDemo) {
      AppLogger.info('切换到演示模式');
    } else {
      AppLogger.warning('切换到真实模式');
    }
  }
}

/// 功能开关配置
class FeatureFlags {
  /// WebRTC通话
  static bool get enableWebRTC =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 真实匹配引擎
  static bool get enableRealMatching =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 推送通知
  static bool get enablePushNotification =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 真实AI API调用
  static bool get enableRealAI =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 数据库同步
  static bool get enableDatabaseSync =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 位置服务
  static bool get enableLocationService =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// SOS真实短信
  static bool get enableRealSMS =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 交互式社群 / 社区入口
  static bool get enableCommunity =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 首页精选故事卡片。AGENTS.md 允许静态故事作为降级展示，
  /// 但当前竞赛默认首页只服务 6 项 MVP，所以默认不加载社区故事服务。
  static bool get enableStaticStoryCards =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.demoMode;

  /// 安心积分
  static bool get enablePoints =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 徽章
  static bool get enableBadges =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 排班
  static bool get enableSchedule =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 后台入口
  static bool get enableAdminDashboard =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;

  /// 通话录音
  static bool get enableCallRecording =>
      !AppConfig.isCompetitionDemoOnly && AppConfig.isRealMode;
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
  static const bool showDemoWatermark = true;
}

/// 网络配置
class NetworkConfig {
  /// Supabase URL
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';

  /// Supabase Anon Key
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// 连接超时（秒）
  static const int connectionTimeout = 10;

  /// 读取超时（秒）
  static const int readTimeout = 30;
}
