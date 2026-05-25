import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

/// 管理员认证服务
class AdminAuthService extends ChangeNotifier {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  AdminUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 检查是否有指定权限
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'super_admin') return true;
    return _currentUser!.permissions?.contains(permission) ?? false;
  }

  /// 检查是否拥有任一权限
  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'super_admin') return true;
    return permissions.any((p) => _currentUser!.permissions?.contains(p) ?? false);
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));

      // DEMO ONLY: 以下账号仅用于竞赛演示，生产环境必须替换为真实认证服务
      // 参考 AGENTS.md: admin_dashboard 不属于竞赛 MVP 主交付
      if (username == 'admin' && password == 'admin123') {
        _currentUser = const AdminUser(
          id: '1',
          username: 'admin',
          email: 'admin@linklab.com',
          role: 'super_admin',
          isActive: true,
          permissions: [
            'users.view', 'users.edit', 'users.ban',
            'content.view', 'content.edit', 'content.delete',
            'reports.view', 'reports.handle',
            'stats.view', 'stats.export',
            'settings.view', 'settings.edit',
          ],
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 操作员账号
      if (username == 'operator' && password == 'operator123') {
        _currentUser = const AdminUser(
          id: '2',
          username: 'operator',
          email: 'operator@linklab.com',
          role: 'operator',
          isActive: true,
          permissions: [
            'users.view',
            'content.view', 'content.edit',
            'reports.view', 'reports.handle',
            'stats.view',
          ],
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = '用户名或密码错误';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '登录失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
