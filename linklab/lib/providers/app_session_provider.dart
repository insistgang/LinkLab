import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/app_session_service.dart';

final appSessionServiceProvider = Provider<AppSessionService>((ref) {
  return AppSessionService.instance;
});

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

  final bool isInitialized;
  final bool isLoggedIn;
  final bool isFirstLaunch;
  final UserModel? userProfile;
  final DemoStageMode stageMode;
  final AccessibilityPreferences preferences;
}

class AppSessionNotifier extends Notifier<AppSessionState> {
  VoidCallback? _sessionListener;

  @override
  AppSessionState build() {
    final session = ref.read(appSessionServiceProvider);

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
}
