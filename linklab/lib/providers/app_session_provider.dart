import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/help_request_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/app_session_service.dart';

// ---------------------------------------------------------------------------
// Legacy service provider – 只做过渡期桥接，新代码不应直接依赖
// ---------------------------------------------------------------------------
final appSessionServiceProvider = Provider<AppSessionService>((ref) {
  return AppSessionService.instance;
});

// ---------------------------------------------------------------------------
// Riverpod 状态 & Notifier
// ---------------------------------------------------------------------------
final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionState>(
      AppSessionNotifier.new,
    );

class AppSessionState {
  const AppSessionState({
    required this.isInitialized,
    required this.isLoggedIn,
    required this.isFirstLaunch,
    required this.userProfile,
    required this.stageMode,
    required this.preferences,
  });

  factory AppSessionState.fromService(AppSessionService session) {
    return AppSessionState(
      isInitialized: session.isInitialized,
      isLoggedIn: session.isLoggedIn,
      isFirstLaunch: session.isFirstLaunch,
      userProfile: session.userProfile,
      stageMode: session.stageMode,
      preferences: session.preferences,
    );
  }

  factory AppSessionState.initial() {
    return const AppSessionState(
      isInitialized: false,
      isLoggedIn: false,
      isFirstLaunch: true,
      userProfile: null,
      stageMode: DemoStageMode.day,
      preferences: AccessibilityPreferences(),
    );
  }

  final bool isInitialized;
  final bool isLoggedIn;
  final bool isFirstLaunch;
  final UserModel? userProfile;
  final DemoStageMode stageMode;
  final AccessibilityPreferences preferences;

  bool get isDayStageMode => stageMode == DemoStageMode.day;

  String get greetingName {
    final name = userProfile?.displayName;
    if (name == null || name.isEmpty) return '朋友';
    return name;
  }

  AppSessionState copyWith({
    bool? isInitialized,
    bool? isLoggedIn,
    bool? isFirstLaunch,
    UserModel? userProfile,
    DemoStageMode? stageMode,
    AccessibilityPreferences? preferences,
  }) {
    return AppSessionState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      userProfile: userProfile ?? this.userProfile,
      stageMode: stageMode ?? this.stageMode,
      preferences: preferences ?? this.preferences,
    );
  }

  /// 委托给底层 service 获取帮助历史。
  /// 注意：这是同步调用本地存储，仅适用于 Demo 模式。
  List<HelpRequestModel> getRecentHelpHistory({int limit = 3}) {
    // 通过全局 service 实例读取本地存储（过渡期方案）
    // ignore: deprecated_member_use_from_same_package
    return AppSessionService.instance.getRecentHelpHistory(limit: limit);
  }
}

class AppSessionNotifier extends Notifier<AppSessionState> {
  AppSessionService get _session => ref.read(appSessionServiceProvider);

  VoidCallback? _sessionListener;

  @override
  AppSessionState build() {
    final session = _session;

    if (_sessionListener == null) {
      _sessionListener = () {
        state = AppSessionState.fromService(session);
      };
      session.addListener(_sessionListener!);
      ref.onDispose(() {
        session.removeListener(_sessionListener!);
      });
    }

    return AppSessionState.fromService(session);
  }

  // -----------------------------------------------------------------------
  // 公开方法 – UI 层只通过这些方法修改会话状态
  // -----------------------------------------------------------------------

  Future<void> initialize() async {
    await _session.initialize();
    // build() 中的 listener 会自动同步 state，此处无需手动赋值
  }

  Future<void> login(String phone, String code) async {
    await _session.loginExistingUser(phone);
  }

  Future<EmailAuthOutcome> loginWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _session.loginWithEmailPassword(email: email, password: password);
  }

  Future<EmailAuthOutcome> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _session.signUpWithEmailPassword(email: email, password: password);
  }

  Future<void> sendEmailLoginLink(String email) {
    return _session.sendEmailLoginLink(email);
  }

  Future<void> loginExistingUser(String phone) async {
    await _session.loginExistingUser(phone);
  }

  Future<void> completeOnboarding({
    required String phone,
    required String role,
    required List<String> disabilityTypes,
    required AccessibilityPreferences preferences,
  }) async {
    await _session.completeOnboarding(
      phone: phone,
      role: role,
      disabilityTypes: disabilityTypes,
      preferences: preferences,
    );
  }

  Future<void> updatePreferences(AccessibilityPreferences prefs) async {
    await _session.updatePreferences(prefs);
  }

  Future<void> setStageMode(DemoStageMode mode) async {
    await _session.setStageMode(mode);
  }

  Future<void> toggleStageMode() async {
    await _session.toggleStageMode();
  }

  Future<void> logout() async {
    await _session.logout();
  }

  Future<void> ensureCompetitionPresenterSession() async {
    await _session.ensureCompetitionPresenterSession();
  }

  List<HelpRequestModel> getRecentHelpHistory({int limit = 3}) {
    return _session.getRecentHelpHistory(limit: limit);
  }

  Future<void> addHelpRecord(Map<String, dynamic> record) async {
    await _session.addHelpRecord(record);
  }
}
