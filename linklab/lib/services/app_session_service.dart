import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logger.dart';
import '../models/help_request_model.dart';
import '../models/user_model.dart';
import '../providers/app_session_provider.dart' show AppSessionState;
import 'auth_service.dart';
import 'local_storage.dart';
import 'real_database_repository.dart';

@Deprecated('使用 Riverpod appSessionProvider 代替。此類保留僅供過渡期非 Consumer 上下文使用。')
class AppSessionService extends ChangeNotifier {
  AppSessionService._internal();

  static final AppSessionService instance = AppSessionService._internal();

  final LocalStorage _storage = LocalStorage();
  final AuthService _authService = AuthService();
  final RealDatabaseRepository _realDatabase = const RealDatabaseRepository();
  StreamSubscription<AuthState>? _authSubscription;

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isFirstLaunch = true;
  UserModel? _userProfile;
  DemoStageMode _stageMode = DemoStageMode.day;
  AccessibilityPreferences _preferences = const AccessibilityPreferences();

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isFirstLaunch => _isFirstLaunch;
  UserModel? get currentUser => _userProfile;
  UserModel? get userProfile => _userProfile;
  DemoStageMode get stageMode => _stageMode;
  bool get isDayStageMode => _stageMode == DemoStageMode.day;
  AccessibilityPreferences get preferences => _preferences;

  Future<void> initialize() async {
    if (_initialized) return;

    await _storage.initialize();
    _restoreState();

    if (FeatureFlags.enableSupabaseAuth) {
      await _restoreSupabaseSession();
      _listenToSupabaseAuthState();
    } else if (AppConfig.isRealMode) {
      // RealMode 沒有可用 Supabase Auth 時不能沿用本地 Demo 登錄態。
      _isLoggedIn = false;
    }

    if (_storage.getHelpHistory().isEmpty) {
      await _seedDemoHelpHistory();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> loginExistingUser(String phone) async {
    if (AppConfig.isRealMode) {
      throw Exception('RealMode 請使用郵箱登錄，手機號短信暫未接入。');
    }

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

  Future<EmailAuthOutcome> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!FeatureFlags.enableSupabaseAuth) {
      return _completeDemoEmailAuth(email: email, message: '已使用本地演示賬號登錄');
    }

    final outcome = await _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (outcome.session != null) {
      await _applySupabaseSession(outcome.session);
    }
    return outcome;
  }

  Future<EmailAuthOutcome> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!FeatureFlags.enableSupabaseAuth) {
      return _completeDemoEmailAuth(email: email, message: '已創建本地演示賬號並登錄');
    }

    final outcome = await _authService.signUpWithEmailPassword(
      email: email,
      password: password,
    );
    if (outcome.session != null) {
      await _applySupabaseSession(outcome.session);
    }
    return outcome;
  }

  Future<void> sendEmailLoginLink(String email) async {
    if (!FeatureFlags.enableSupabaseAuth) {
      AppLogger.info('DemoMode 已模擬發送郵箱登錄郵件');
      return;
    }
    await _authService.sendEmailLoginLink(email);
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

  Future<void> updatePreferences(AccessibilityPreferences preferences) async {
    _preferences = preferences;
    _userProfile = _userProfile?.copyWith(preferences: preferences);

    await _storage.saveAccessibilityPrefs(preferences.toJson());
    if (_userProfile != null) {
      await _storage.saveUserProfile(_userProfile!.toJson());
    }

    notifyListeners();
  }

  Future<void> setStageMode(DemoStageMode mode) async {
    if (_stageMode == mode) return;
    _stageMode = mode;
    AppTheme.setStageMode(mode);
    await _storage.setStageThemeMode(mode.name);
    notifyListeners();
  }

  Future<void> toggleStageMode() async {
    await setStageMode(
      _stageMode == DemoStageMode.day ? DemoStageMode.night : DemoStageMode.day,
    );
  }

  Future<void> logout() async {
    if (FeatureFlags.enableSupabaseAuth) {
      await _authService.signOut();
    }

    _isLoggedIn = false;
    await _storage.setLoggedIn(false);
    await _storage.clearAuthToken();
    notifyListeners();
  }

  Future<void> ensureCompetitionPresenterSession() async {
    if (!AppConfig.presenterMode) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    if (_isLoggedIn) {
      await setStageMode(DemoStageMode.day);
      return;
    }

    final currentProfile = _userProfile;
    if (currentProfile != null) {
      await loginExistingUser(currentProfile.phone);
      await setStageMode(DemoStageMode.day);
      AppLogger.info('已恢復本地演示賬號，直接進入競賽主演示');
      return;
    }

    const presenterPreferences = AccessibilityPreferences(
      fontScale: 1.1,
      autoReadResults: true,
      voiceGuidance: true,
      hapticFeedback: true,
    );

    await completeOnboarding(
      phone: '13800138000',
      role: 'seeker',
      disabilityTypes: const ['visual'],
      preferences: presenterPreferences,
    );
    await setStageMode(DemoStageMode.day);
    AppLogger.info('已注入競賽演示員會話，默認直達 Demo 主線');
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
    _stageMode = _storage.getStageThemeMode() == DemoStageMode.night.name
        ? DemoStageMode.night
        : DemoStageMode.day;
    AppTheme.setStageMode(_stageMode);

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
        'intent': '識別藥品說明書',
        'urgency': 'important',
        'status': 'ai_resolved',
        'aiResponse': {'summary': '已識別藥品名稱與用法，並建議人工複覈關鍵劑量信息。'},
        'durationSeconds': 92,
        'seekerRating': 5,
        'createdAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'completedAt': now
            .subtract(const Duration(hours: 3, minutes: 58))
            .toIso8601String(),
      },
      {
        'id': 'help-demo-2',
        'seekerId': userId,
        'type': 'realtime_voice',
        'intent': '協助查看快遞面單',
        'urgency': 'normal',
        'status': 'completed',
        'volunteerId': 'demo-volunteer-1',
        'durationSeconds': 386,
        'seekerRating': 5,
        'createdAt': now
            .subtract(const Duration(days: 1, hours: 2))
            .toIso8601String(),
        'matchedAt': now
            .subtract(const Duration(days: 1, hours: 2, minutes: -1))
            .toIso8601String(),
        'completedAt': now
            .subtract(const Duration(days: 1, hours: 1, minutes: 54))
            .toIso8601String(),
      },
      {
        'id': 'help-demo-3',
        'seekerId': userId,
        'type': 'sos',
        'intent': '夜間迷路，觸發緊急協助',
        'urgency': 'emergency',
        'status': 'completed',
        'volunteerId': 'demo-volunteer-2',
        'durationSeconds': 512,
        'seekerRating': 4,
        'createdAt': now
            .subtract(const Duration(days: 3, hours: 6))
            .toIso8601String(),
        'matchedAt': now
            .subtract(const Duration(days: 3, hours: 5, minutes: 58))
            .toIso8601String(),
        'completedAt': now
            .subtract(const Duration(days: 3, hours: 5, minutes: 49))
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
    final suffix = phone.length >= 4
        ? phone.substring(phone.length - 4)
        : phone;
    if (roles.contains('volunteer') && roles.contains('seeker')) {
      return '互助用戶$suffix';
    }
    if (roles.contains('volunteer')) {
      return '志願者$suffix';
    }
    return '用戶$suffix';
  }

  Future<EmailAuthOutcome> _completeDemoEmailAuth({
    required String email,
    required String message,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final localPart = normalizedEmail.split('@').first.trim();
    final safeId = normalizedEmail
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    final user = UserModel(
      id: 'demo-email-${safeId.isEmpty ? 'user' : safeId}',
      phone: normalizedEmail,
      name: localPart.isEmpty ? '郵箱用戶' : localPart,
      role: const ['seeker'],
      disabilityType: const [],
      preferences: _preferences,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    _userProfile = user;
    _isLoggedIn = true;
    _isFirstLaunch = false;

    await _storage.saveUserProfile(user.toJson());
    await _storage.setLoggedIn(true);
    await _storage.setFirstLaunch(false);
    await _storage.saveAuthToken('demo-email-session-${user.id}');

    if (_storage.getHelpHistory().isEmpty) {
      await _seedDemoHelpHistory(seekerId: user.id);
    }

    notifyListeners();
    AppLogger.info('DemoMode 郵箱登錄已完成');

    return EmailAuthOutcome(signedIn: true, message: message);
  }

  Future<void> _restoreSupabaseSession() async {
    final session = _authService.currentSession;
    if (session == null) {
      _isLoggedIn = false;
      await _storage.setLoggedIn(false);
      await _storage.clearAuthToken();
      return;
    }

    await _applySupabaseSession(session, notify: false);
  }

  void _listenToSupabaseAuthState() {
    _authSubscription ??= _authService.onAuthStateChange.listen((authState) {
      unawaited(_handleSupabaseAuthState(authState));
    });
  }

  Future<void> _handleSupabaseAuthState(AuthState authState) async {
    switch (authState.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.initialSession:
        await _applySupabaseSession(authState.session);
      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.userDeleted:
        _isLoggedIn = false;
        await _storage.setLoggedIn(false);
        await _storage.clearAuthToken();
        notifyListeners();
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
  }

  Future<void> _applySupabaseSession(
    Session? session, {
    bool notify = true,
  }) async {
    final authUser = session?.user;
    if (session == null || authUser == null) {
      _isLoggedIn = false;
      await _storage.setLoggedIn(false);
      await _storage.clearAuthToken();
      if (notify) notifyListeners();
      return;
    }

    final authUserProfile = _buildUserFromSupabase(authUser);
    final user = await _syncRealProfile(authUserProfile);
    _userProfile = user;
    _isLoggedIn = true;
    _isFirstLaunch = false;

    await _storage.saveUserProfile(user.toJson());
    await _storage.saveAuthToken(session.accessToken);
    await _storage.setLoggedIn(true);
    await _storage.setFirstLaunch(false);

    if (_storage.getHelpHistory().isEmpty) {
      await _seedDemoHelpHistory(seekerId: user.id);
    }

    if (notify) notifyListeners();
  }

  UserModel _buildUserFromSupabase(User authUser) {
    final email = authUser.email?.trim();
    final phone = authUser.phone?.trim();
    final identifier = (email?.isNotEmpty ?? false)
        ? email!
        : (phone?.isNotEmpty ?? false)
        ? phone!
        : authUser.id;
    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final metadataName =
        metadata['full_name']?.toString().trim().isNotEmpty == true
        ? metadata['full_name'].toString().trim()
        : metadata['name']?.toString().trim();
    final fallbackName = email != null && email.contains('@')
        ? email.split('@').first
        : 'LinkAble用戶';

    return UserModel(
      id: authUser.id,
      phone: identifier,
      name: metadataName?.isNotEmpty == true ? metadataName : fallbackName,
      role: const ['seeker'],
      disabilityType: const [],
      preferences: _preferences,
      createdAt: DateTime.tryParse(authUser.createdAt),
      lastLoginAt: DateTime.now(),
    );
  }

  Future<UserModel> _syncRealProfile(UserModel authUserProfile) async {
    if (!FeatureFlags.enableDatabaseSync) {
      return authUserProfile;
    }

    try {
      final profile = await _realDatabase.ensureCurrentProfile(
        fallbackDisplayName: authUserProfile.displayName,
        phone: authUserProfile.phone.contains('@')
            ? null
            : authUserProfile.phone,
      );

      return authUserProfile.copyWith(
        name: profile.effectiveDisplayName,
        phone: profile.phone?.trim().isNotEmpty == true
            ? profile.phone!.trim()
            : authUserProfile.phone,
        role: _rolesFromRealProfile(profile.role),
        createdAt: profile.createdAt,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'RealMode profile 同步失敗，繼續使用 Auth session',
        error,
        stackTrace,
      );
      return authUserProfile;
    }
  }

  List<String> _rolesFromRealProfile(String role) {
    return switch (role) {
      'volunteer' => const ['volunteer'],
      'admin' => const ['admin'],
      _ => const ['seeker'],
    };
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    super.dispose();
  }

  /// 將當前服務狀態轉換爲 Riverpod 狀態對象。
  /// 僅用於過渡期橋接，新代碼應直接使用 [AppSessionState.fromService]。
  AppSessionState toRiverpodState() => AppSessionState.fromService(this);
}
