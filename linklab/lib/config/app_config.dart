// 应用配置
// 控制演示模式和真实模式的切换

/// 应用运行模式
enum AppMode {
  demo,     // 演示模式：使用模拟数据，不依赖网络
  real,     // 真实模式：调用真实API和WebRTC
}

/// 应用配置类
class AppConfig {
  // 当前运行模式
  static AppMode _mode = AppMode.demo;

  /// 获取当前模式
  static AppMode get mode => _mode;

  /// 是否为演示模式
  static bool get isDemoMode => _mode == AppMode.demo;

  /// 是否为真实模式
  static bool get isRealMode => _mode == AppMode.real;

  /// 切换到演示模式
  static void setDemoMode() {
    _mode = AppMode.demo;
    print('[AppConfig] 切换到演示模式');
  }

  /// 切换到真实模式
  static void setRealMode() {
    _mode = AppMode.real;
    print('[AppConfig] 切换到真实模式');
  }

  /// 切换模式
  static void toggleMode() {
    if (_mode == AppMode.demo) {
      setRealMode();
    } else {
      setDemoMode();
    }
  }
}

/// 功能开关配置
class FeatureFlags {
  /// WebRTC通话
  static bool get enableWebRTC => AppConfig.isRealMode;

  /// 真实匹配引擎
  static bool get enableRealMatching => AppConfig.isRealMode;

  /// 推送通知
  static bool get enablePushNotification => AppConfig.isRealMode;

  /// 真实AI API调用
  static bool get enableRealAI => AppConfig.isRealMode;

  /// 数据库同步
  static bool get enableDatabaseSync => AppConfig.isRealMode;

  /// 位置服务
  static bool get enableLocationService => AppConfig.isRealMode;

  /// SOS真实短信
  static bool get enableRealSMS => AppConfig.isRealMode;
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
