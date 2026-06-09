import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

/// 管理員認證服務
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

  /// 檢查是否有指定權限
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'super_admin') return true;
    return _currentUser!.permissions?.contains(permission) ?? false;
  }

  /// 檢查是否擁有任一權限
  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'super_admin') return true;
    return permissions.any((p) => _currentUser!.permissions?.contains(p) ?? false);
  }

  /// 登錄
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 模擬API調用
      await Future.delayed(const Duration(seconds: 1));

      // DEMO ONLY: 以下賬號僅用於競賽演示，生產環境必須替換爲真實認證服務
      // 參考 AGENTS.md: admin_dashboard 不屬於競賽 MVP 主交付
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

      // 操作員賬號
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

      _error = '用戶名或密碼錯誤';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '登錄失敗: $e';
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

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
