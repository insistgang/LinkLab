// 应用常量
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

  // 应用信息
  static const String appName = 'LinkLab 运营后台';
  static const String appVersion = '1.0.0';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isDemoMode => demoModeOverride || !hasSupabaseConfig;

  // 分页配置
  static const int defaultPageSize = 20;
  static const List<int> pageSizeOptions = [10, 20, 50, 100];

  // 日期格式
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // 菜单项
  static const List<Map<String, dynamic>> menuItems = [
    {'icon': 'dashboard', 'title': '数据看板', 'route': '/dashboard'},
    {'icon': 'people', 'title': '用户管理', 'route': '/users'},
    {'icon': 'content', 'title': '内容管理', 'route': '/content'},
    {'icon': 'report', 'title': '举报处理', 'route': '/reports'},
    {'icon': 'analytics', 'title': '数据统计', 'route': '/statistics'},
    {'icon': 'settings', 'title': '系统设置', 'route': '/settings'},
  ];
}

// 用户角色
enum UserRole {
  superAdmin,
  admin,
  operator,
}

// 用户状态
enum UserStatus {
  active,
  banned,
  pending,
}

// 认证状态
enum VerificationStatus {
  pending,
  approved,
  rejected,
}

// 举报状态
enum ReportStatus {
  pending,
  processing,
  resolved,
  dismissed,
}

// 举报类型
enum ReportType {
  spam,
  harassment,
  inappropriate,
  fraud,
  other,
}

// 内容状态
enum ContentStatus {
  draft,
  published,
  archived,
}
