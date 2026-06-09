// 應用常量
class AppConstants {
  // Supabase 配置
  static const String supabaseUrl =
      String.fromEnvironment('LINKLAB_SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('LINKLAB_SUPABASE_ANON_KEY', defaultValue: '');
  static const bool demoModeOverride =
      bool.fromEnvironment('LINKLAB_ADMIN_DEMO', defaultValue: false);

  static const String demoAdminEmail = 'admin@linklab.com';
  static const String demoAdminPassword = 'admin123';

  // 應用信息
  static const String appName = 'LinkLab 運營後臺';
  static const String appVersion = '1.0.0';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isDemoMode => demoModeOverride || !hasSupabaseConfig;

  // 分頁配置
  static const int defaultPageSize = 20;
  static const List<int> pageSizeOptions = [10, 20, 50, 100];

  // 日期格式
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // 菜單項
  static const List<Map<String, dynamic>> menuItems = [
    {'icon': 'dashboard', 'title': '數據看板', 'route': '/dashboard'},
    {'icon': 'people', 'title': '用戶管理', 'route': '/users'},
    {'icon': 'content', 'title': '內容管理', 'route': '/content'},
    {'icon': 'report', 'title': '舉報處理', 'route': '/reports'},
    {'icon': 'analytics', 'title': '數據統計', 'route': '/statistics'},
    {'icon': 'settings', 'title': '系統設置', 'route': '/settings'},
  ];
}

// 用戶角色
enum UserRole {
  superAdmin,
  admin,
  operator,
}

// 用戶狀態
enum UserStatus {
  active,
  banned,
  pending,
}

// 認證狀態
enum VerificationStatus {
  pending,
  approved,
  rejected,
}

// 舉報狀態
enum ReportStatus {
  pending,
  processing,
  resolved,
  dismissed,
}

// 舉報類型
enum ReportType {
  spam,
  harassment,
  inappropriate,
  fraud,
  other,
}

// 內容狀態
enum ContentStatus {
  draft,
  published,
  archived,
}
