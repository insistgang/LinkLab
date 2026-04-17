import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/help_request_model.dart';
import '../models/user_model.dart';
import 'local_storage.dart';

class AppSessionService extends ChangeNotifier {
  AppSessionService._internal();

  static final AppSessionService instance = AppSessionService._internal();

  final LocalStorage _storage = LocalStorage();

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isFirstLaunch = true;
  UserModel? _userProfile;
  AccessibilityPreferences _preferences =
      const AccessibilityPreferences();

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isFirstLaunch => _isFirstLaunch;
  UserModel? get currentUser => _userProfile;
  UserModel? get userProfile => _userProfile;
  AccessibilityPreferences get preferences => _preferences;

  Future<void> initialize() async {
    if (_initialized) return;

    await _storage.initialize();
    _restoreState();

    if (_storage.getHelpHistory().isEmpty) {
      await _seedDemoHelpHistory();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> loginExistingUser(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final current = _userProfile;

    if (current == null) {
      return;
    }

    final updated = current.copyWith(
      phone: normalizedPhone,
      lastLoginAt: DateTime.now(),
    );

    _userProfile = updated;
    _isLoggedIn = true;
    _isFirstLaunch = false;

    await _storage.saveUserProfile(updated.toJson());
    await _storage.setLoggedIn(true);
    await _storage.setFirstLaunch(false);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String phone,
    required String role,
    required List<String> disabilityTypes,
    required AccessibilityPreferences preferences,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final roles = switch (role) {
      'volunteer' => const ['volunteer'],
      'both' => const ['seeker', 'volunteer'],
      _ => const ['seeker'],
    };

    final user = UserModel(
      id: 'demo-${normalizedPhone.substring(normalizedPhone.length - 4)}',
      phone: normalizedPhone,
      name: _buildDisplayName(normalizedPhone, roles),
      role: roles,
      disabilityType: disabilityTypes,
      preferences: preferences,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    _userProfile = user;
    _preferences = preferences;
    _isLoggedIn = true;
    _isFirstLaunch = false;

    await _storage.saveUserProfile(user.toJson());
    await _storage.saveAccessibilityPrefs(preferences.toJson());
    await _storage.setLoggedIn(true);
    await _storage.setFirstLaunch(false);

    if (_storage.getHelpHistory().isEmpty) {
      await _seedDemoHelpHistory(seekerId: user.id);
    }

    notifyListeners();
  }

  Future<void> updatePreferences(
    AccessibilityPreferences preferences,
  ) async {
    _preferences = preferences;
    _userProfile = _userProfile?.copyWith(preferences: preferences);

    await _storage.saveAccessibilityPrefs(preferences.toJson());
    if (_userProfile != null) {
      await _storage.saveUserProfile(_userProfile!.toJson());
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    await _storage.setLoggedIn(false);
    await _storage.clearAuthToken();
    notifyListeners();
  }

  List<HelpRequestModel> getRecentHelpHistory({int limit = 3}) {
    final history = _storage.getHelpHistory();
    return history
        .map((item) => HelpRequestModel.fromJson(item))
        .take(limit)
        .toList();
  }

  Future<void> addHelpRecord(Map<String, dynamic> record) async {
    await _storage.addHelpRecord(record);
    notifyListeners();
  }

  String get greetingName {
    final name = _userProfile?.displayName;
    if (name == null || name.isEmpty) {
      return '朋友';
    }
    return name;
  }

  void _restoreState() {
    _isLoggedIn = _storage.isLoggedIn();
    _isFirstLaunch = _storage.isFirstLaunch();

    final storedProfile = _storage.getUserProfile();
    if (storedProfile != null) {
      try {
        _userProfile = UserModel.fromJson(
          Map<String, dynamic>.from(storedProfile),
        );
      } catch (_) {
        _userProfile = null;
      }
    }

    try {
      _preferences = AccessibilityPreferences.fromJson(
        Map<String, dynamic>.from(_storage.getAccessibilityPrefs()),
      );
    } catch (_) {
      _preferences = const AccessibilityPreferences();
    }
  }

  Future<void> _seedDemoHelpHistory({String? seekerId}) async {
    final userId = seekerId ?? _userProfile?.id ?? 'demo-seeker';
    final now = DateTime.now();

    final records = [
      {
        'id': 'help-demo-1',
        'seekerId': userId,
        'type': 'ai_auto',
        'intent': '识别药品说明书',
        'urgency': 'important',
        'status': 'ai_resolved',
        'aiResponse': {
          'summary': '已识别药品名称与用法，并建议人工复核关键剂量信息。'
        },
        'durationSeconds': 92,
        'seekerRating': 5,
        'createdAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'completedAt':
            now.subtract(const Duration(hours: 3, minutes: 58)).toIso8601String(),
      },
      {
        'id': 'help-demo-2',
        'seekerId': userId,
        'type': 'realtime_voice',
        'intent': '协助查看快递面单',
        'urgency': 'normal',
        'status': 'completed',
        'volunteerId': 'demo-volunteer-1',
        'durationSeconds': 386,
        'seekerRating': 5,
        'createdAt': now.subtract(const Duration(days: 1, hours: 2))
            .toIso8601String(),
        'matchedAt': now.subtract(const Duration(days: 1, hours: 2, minutes: -1))
            .toIso8601String(),
        'completedAt':
            now.subtract(const Duration(days: 1, hours: 1, minutes: 54))
                .toIso8601String(),
      },
      {
        'id': 'help-demo-3',
        'seekerId': userId,
        'type': 'sos',
        'intent': '夜间迷路，触发紧急协助',
        'urgency': 'emergency',
        'status': 'completed',
        'volunteerId': 'demo-volunteer-2',
        'durationSeconds': 512,
        'seekerRating': 4,
        'createdAt': now.subtract(const Duration(days: 3, hours: 6))
            .toIso8601String(),
        'matchedAt': now.subtract(const Duration(days: 3, hours: 5, minutes: 58))
            .toIso8601String(),
        'completedAt':
            now.subtract(const Duration(days: 3, hours: 5, minutes: 49))
                .toIso8601String(),
      },
    ];

    await _storage.setString(StorageKeys.helpHistory, jsonEncode(records));
  }

  String _normalizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.isEmpty ? phone : digitsOnly;
  }

  String _buildDisplayName(String phone, List<String> roles) {
    final suffix = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    if (roles.contains('volunteer') && roles.contains('seeker')) {
      return '互助用户$suffix';
    }
    if (roles.contains('volunteer')) {
      return '志愿者$suffix';
    }
    return '用户$suffix';
  }
}
