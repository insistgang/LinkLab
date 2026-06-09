import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存儲鍵名常量
class StorageKeys {
  static const String userProfile = 'user_profile';
  static const String accessibilityPrefs = 'accessibility_preferences';
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';
  static const String isDemoMode = 'is_demo_mode';
  static const String authToken = 'auth_token';
  static const String lastVolunteerId = 'last_volunteer_id';
  static const String helpHistory = 'help_history';
  static const String favoriteVolunteers = 'favorite_volunteers';
  static const String emergencyContacts = 'emergency_contacts';
  static const String asyncTasks = 'async_tasks';
  static const String demoHelpRequests = 'demo_help_requests';
  static const String currentDemoHelpRequestId = 'current_demo_help_request_id';
  static const String stageThemeMode = 'stage_theme_mode';

  static String safetySettings(String userId) => 'safety_settings_$userId';
}

/// 本地存儲服務
/// 用於演示版的數據持久化（替代Supabase）
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 確保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception('LocalStorage未初始化，請先調用initialize()');
    }
  }

  // ==================== 演示模式 ====================

  /// 是否演示模式
  bool isDemoMode() {
    _ensureInitialized();
    return _prefs!.getBool(StorageKeys.isDemoMode) ?? true;
  }

  /// 設置演示模式
  Future<bool> setDemoMode(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(StorageKeys.isDemoMode, value);
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
      return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    } catch (e) {
      return null;
    }
  }

  /// 清除用戶資料
  Future<bool> clearUserProfile() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.userProfile);
  }

  // ==================== 登錄狀態 ====================

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

  // ==================== 首次啓動 ====================

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
      return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    } catch (e) {
      return {};
    }
  }

  // ==================== 演示主題模式 ====================

  String getStageThemeMode() {
    _ensureInitialized();
    return _prefs!.getString(StorageKeys.stageThemeMode) ?? 'day';
  }

  Future<bool> setStageThemeMode(String value) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.stageThemeMode, value);
  }

  // ==================== 求助歷史 ====================

  /// 添加求助記錄
  Future<bool> addHelpRecord(Map<String, dynamic> record) async {
    _ensureInitialized();
    final history = getHelpHistory();
    record['id'] = 'help_${DateTime.now().millisecondsSinceEpoch}';
    record['createdAt'] = DateTime.now().toIso8601String();
    history.insert(0, record);
    // 只保留最近20條
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    return await _prefs!.setString(
      StorageKeys.helpHistory,
      jsonEncode(history),
    );
  }

  /// 保存完整求助歷史
  Future<bool> saveHelpHistory(List<Map<String, dynamic>> history) async {
    _ensureInitialized();
    return await _prefs!.setString(
      StorageKeys.helpHistory,
      jsonEncode(history),
    );
  }

  /// 新增或更新指定求助記錄
  Future<bool> upsertHelpRecord(
    Map<String, dynamic> record, {
    int maxRecords = 50,
  }) async {
    _ensureInitialized();

    final history = getHelpHistory();
    final recordId = record['id']?.toString();

    if (recordId == null || recordId.isEmpty) {
      record['id'] = 'help_${DateTime.now().millisecondsSinceEpoch}';
    }

    record['createdAt'] ??= DateTime.now().toIso8601String();

    final index = history.indexWhere(
      (item) => item['id']?.toString() == record['id']?.toString(),
    );

    if (index >= 0) {
      history[index] = {...history[index], ...record};
    } else {
      history.insert(0, record);
    }

    history.sort((a, b) {
      final aTime =
          DateTime.tryParse('${a['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse('${b['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    if (history.length > maxRecords) {
      history.removeRange(maxRecords, history.length);
    }

    return await saveHelpHistory(history);
  }

  /// 獲取求助歷史
  List<Map<String, dynamic>> getHelpHistory() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.helpHistory);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// 清除求助歷史
  Future<bool> clearHelpHistory() async {
    _ensureInitialized();
    return await _prefs!.remove(StorageKeys.helpHistory);
  }

  // ==================== 常用志願者 ====================

  /// 保存常用志願者列表
  Future<bool> saveFavoriteVolunteers(
    List<Map<String, dynamic>> favorites,
  ) async {
    _ensureInitialized();
    return await _prefs!.setString(
      StorageKeys.favoriteVolunteers,
      jsonEncode(favorites),
    );
  }

  /// 獲取常用志願者列表
  List<Map<String, dynamic>> getFavoriteVolunteers() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.favoriteVolunteers);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ==================== 異步任務 ====================

  /// 保存異步任務
  Future<bool> saveAsyncTasks(List<Map<String, dynamic>> tasks) async {
    _ensureInitialized();
    return await _prefs!.setString(StorageKeys.asyncTasks, jsonEncode(tasks));
  }

  /// 獲取異步任務
  List<Map<String, dynamic>> getAsyncTasks() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(StorageKeys.asyncTasks);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
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
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
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
