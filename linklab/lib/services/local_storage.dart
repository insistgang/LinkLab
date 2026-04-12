import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储键名常量
class StorageKeys {
  static const String userProfile = 'user_profile';
  static const String accessibilityPrefs = 'accessibility_preferences';
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';
  static const String isDemoMode = 'is_demo_mode';
  static const String authToken = 'auth_token';
  static const String lastVolunteerId = 'last_volunteer_id';
  static const String helpHistory = 'help_history';
  static const String emergencyContacts = 'emergency_contacts';
}

/// 本地存储服务
/// 用于演示版的数据持久化（替代Supabase）
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception('LocalStorage未初始化，请先调用initialize()');
    }
  }

  // ==================== 演示模式 ====================

  /// 是否演示模式
  bool isDemoMode() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isDemoMode) ?? true;
  }

  /// 设置演示模式
  Future<bool> setDemoMode(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isDemoMode, value);
  }

  // ==================== 用户相关 ====================

  /// 保存用户资料
  Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.userProfile, jsonEncode(profile));
  }

  /// 获取用户资料
  Map<String, dynamic>? getUserProfile() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.userProfile);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// 清除用户资料
  Future<bool> clearUserProfile() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.userProfile);
  }

  // ==================== 登录状态 ====================

  /// 是否已登录
  bool isLoggedIn() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  /// 设置登录状态
  Future<bool> setLoggedIn(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isLoggedIn, value);
  }

  /// 保存认证令牌
  Future<bool> saveAuthToken(String token) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.authToken, token);
  }

  /// 获取认证令牌
  String? getAuthToken() {
    _ensureInitialized();
    return _prefs!.getString(StorageKeys.authToken);
  }

  /// 清除认证令牌
  Future<bool> clearAuthToken() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.authToken);
  }

  // ==================== 首次启动 ====================

  /// 是否首次启动
  bool isFirstLaunch() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isFirstLaunch) ?? true;
  }

  /// 设置首次启动标志
  Future<bool> setFirstLaunch(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isFirstLaunch, value);
  }

  // ==================== 无障碍偏好 ====================

  /// 保存无障碍偏好
  Future<bool> saveAccessibilityPrefs(Map<String, dynamic> prefs) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.accessibilityPrefs, jsonEncode(prefs));
  }

  /// 获取无障碍偏好
  Map<String, dynamic> getAccessibilityPrefs() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.accessibilityPrefs);
    if (jsonString == null) {
      // 返回默认设置
      return {
        'highContrastMode': false,
        'fontScale': 1.0,
        'voiceSpeed': 1.0,
        'hapticFeedback': true,
        'voiceGuidance': true,
        'autoReadResults': true,
        'voiceGender': 'female',
        'voiceAccent': 'standard',
      };
    }
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return {};
    }
  }

  // ==================== 求助历史 ====================

  /// 添加求助记录
  Future<bool> addHelpRecord(Map<String, dynamic> record) async {
    _ensureInitialized();
    final history = getHelpHistory();
    record['id'] = 'help_${DateTime.now().millisecondsSinceEpoch}';
    record['createdAt'] = DateTime.now().toIso8601String();
    history.insert(0, record);
    // 只保留最近20条
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    return await _prefs!.setString(StorageKeys.helpHistory, jsonEncode(history));
  }

  /// 获取求助历史
  List<Map<String, dynamic>> getHelpHistory() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.helpHistory);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// 清除求助历史
  Future<bool> clearHelpHistory() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.helpHistory);
  }

  // ==================== 紧急联系人 ====================

  /// 保存紧急联系人
  Future<bool> saveEmergencyContacts(List<Map<String, dynamic>> contacts) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.emergencyContacts, jsonEncode(contacts));
  }

  /// 获取紧急联系人
  List<Map<String, dynamic>> getEmergencyContacts() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.emergencyContacts);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// 添加紧急联系人
  Future<bool> addEmergencyContact(Map<String, dynamic> contact) async {
    _ensureInitialized();
    final contacts = getEmergencyContacts();
    contact['id'] = 'contact_${DateTime.now().millisecondsSinceEpoch}';
    contacts.add(contact);
    return await saveEmergencyContacts(contacts);
  }

  /// 删除紧急联系人
  Future<bool> removeEmergencyContact(String contactId) async {
    _ensureInitialized();
    final contacts = getEmergencyContacts();
    contacts.removeWhere((c) => c['id'] == contactId);
    return await saveEmergencyContacts(contacts);
  }

  // ==================== 通用方法 ====================

  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// 获取字符串
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  /// 获取布尔值
  bool getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  /// 获取整数
  int getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();
    return _prefs!.getInt(key) ?? defaultValue;
  }

  /// 删除键
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  /// 清除所有数据
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }
}
