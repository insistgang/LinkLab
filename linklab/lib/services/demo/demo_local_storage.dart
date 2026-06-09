import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';

/// 本地存儲鍵名
class StorageKeys {
  static const String userProfile = 'user_profile';
  static const String accessibilityPrefs = 'accessibility_preferences';
  static const String helpHistory = 'help_history';
  static const String emergencyContacts = 'emergency_contacts';
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';
  static const String authToken = 'auth_token';
  static const String lastSyncTime = 'last_sync_time';
}

/// 演示版本地存儲服務
/// 用於替代Supabase遠程存儲
class DemoLocalStorage {
  static final DemoLocalStorage _instance = DemoLocalStorage._internal();
  factory DemoLocalStorage() => _instance;
  DemoLocalStorage._internal();

  SharedPreferences? _prefs;

  Map<String, dynamic>? _decodeMap(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  }

  List<Map<String, dynamic>> _decodeMapList(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// 初始化
  Future<void> initialize() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoLocalStorage.initialize',
    )) {
      throw Exception('DemoLocalStorage 僅在 Demo fallback 開啓時可用');
    }

    _prefs = await SharedPreferences.getInstance();
  }

  /// 確保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception('DemoLocalStorage未初始化，請先調用initialize()');
    }
  }

  // ==================== 用戶相關 ====================

  /// 保存用戶資料
  Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    _ensureInitialized();
    return await _prefs!.setString(
      StorageKeys.userProfile,
      jsonEncode(profile),
    );
  }

  /// 獲取用戶資料
  Map<String, dynamic>? getUserProfile() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.userProfile);
    if (jsonString == null) return null;
    try {
      return _decodeMap(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// 清除用戶資料
  Future<bool> clearUserProfile() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.userProfile);
  }

  // ==================== 無障礙偏好 ====================

  /// 保存無障礙偏好
  Future<bool> saveAccessibilityPrefs(Map<String, dynamic> prefs) async {
    _ensureInitialized();
    return await _prefs!.setString(
      StorageKeys.accessibilityPrefs,
      jsonEncode(prefs),
    );
  }

  /// 獲取無障礙偏好
  Map<String, dynamic> getAccessibilityPrefs() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.accessibilityPrefs);
    if (jsonString == null) {
      // 返回默認設置
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
      return _decodeMap(jsonString) ?? {};
    } catch (e) {
      return {};
    }
  }

  // ==================== 求助歷史 ====================

  /// 添加求助記錄
  Future<bool> addHelpRecord(Map<String, dynamic> record) async {
    _ensureInitialized();
    final history = getHelpHistory();
    record['id'] = 'help_${DateTime.now().millisecondsSinceEpoch}';
    record['createdAt'] = DateTime.now().toIso8601String();
    history.insert(0, record);
    // 只保留最近50條
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    return await _prefs!.setString(
      StorageKeys.helpHistory,
      jsonEncode(history),
    );
  }

  /// 獲取求助歷史
  List<Map<String, dynamic>> getHelpHistory() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.helpHistory);
    if (jsonString == null) return [];
    try {
      return _decodeMapList(jsonString);
    } catch (e) {
      return [];
    }
  }

  /// 清除求助歷史
  Future<bool> clearHelpHistory() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.helpHistory);
  }

  // ==================== 緊急聯繫人 ====================

  /// 保存緊急聯繫人
  Future<bool> saveEmergencyContacts(
    List<Map<String, dynamic>> contacts,
  ) async {
    _ensureInitialized();
    return await _prefs!.setString(
      StorageKeys.emergencyContacts,
      jsonEncode(contacts),
    );
  }

  /// 獲取緊急聯繫人
  List<Map<String, dynamic>> getEmergencyContacts() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.emergencyContacts);
    if (jsonString == null) return [];
    try {
      return _decodeMapList(jsonString);
    } catch (e) {
      return [];
    }
  }

  /// 添加緊急聯繫人
  Future<bool> addEmergencyContact(Map<String, dynamic> contact) async {
    _ensureInitialized();
    final contacts = getEmergencyContacts();
    contact['id'] = 'contact_${DateTime.now().millisecondsSinceEpoch}';
    contacts.add(contact);
    return await saveEmergencyContacts(contacts);
  }

  /// 刪除緊急聯繫人
  Future<bool> removeEmergencyContact(String contactId) async {
    _ensureInitialized();
    final contacts = getEmergencyContacts();
    contacts.removeWhere((c) => c['id'] == contactId);
    return await saveEmergencyContacts(contacts);
  }

  // ==================== 應用狀態 ====================

  /// 是否首次啓動
  bool isFirstLaunch() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isFirstLaunch) ?? true;
  }

  /// 設置首次啓動標誌
  Future<bool> setFirstLaunch(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isFirstLaunch, value);
  }

  /// 是否已登錄
  bool isLoggedIn() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  /// 設置登錄狀態
  Future<bool> setLoggedIn(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isLoggedIn, value);
  }

  /// 保存認證令牌
  Future<bool> saveAuthToken(String token) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.authToken, token);
  }

  /// 獲取認證令牌
  String? getAuthToken() {
    _ensureInitialized();
    return _prefs!.getString(StorageKeys.authToken);
  }

  /// 清除認證令牌
  Future<bool> clearAuthToken() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.authToken);
  }

  // ==================== 通用方法 ====================

  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// 獲取字符串
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// 保存布爾值
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  /// 獲取布爾值
  bool getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  /// 保存整數
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  /// 獲取整數
  int getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();
    return _prefs!.getInt(key) ?? defaultValue;
  }

  /// 刪除鍵
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  /// 清除所有數據
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }
}
