import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/app.dart';
import 'package:linklab/config/app_config.dart';
import 'package:linklab/core/theme/app_theme.dart';
import 'package:linklab/demo_flow/demo_help_request_tracker.dart';
import 'package:linklab/models/help_request_model.dart';
import 'package:linklab/models/user_model.dart';
import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/demo_call_service.dart';
import 'package:linklab/services/local_storage.dart';

Future<void> prepareEmptyDemoEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  AppConfig.demoMode = true;
  AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
  await DemoDataLoader.initialize();

  final storage = LocalStorage();
  await storage.initialize();
  await storage.clearAll();

  final session = AppSessionService.instance;
  if (!session.isInitialized) {
    await session.initialize();
  }
  await session.setStageMode(DemoStageMode.day);

  DemoCallService().reset();
  DemoMatchingService().cancelMatching();
  DemoSOSService().cancelSOS();
  await DemoHelpRequestTracker.clearCurrentRequest();
}

Future<void> prepareSignedInDemoEnvironment({
  bool clearHelpHistory = false,
  AccessibilityPreferences preferences = const AccessibilityPreferences(),
}) async {
  await prepareEmptyDemoEnvironment();

  final session = AppSessionService.instance;
  await session.completeOnboarding(
    phone: '13800138000',
    role: 'seeker',
    disabilityTypes: const ['visual'],
    preferences: preferences,
  );

  final storage = LocalStorage();
  if (clearHelpHistory) {
    await storage.clearHelpHistory();
  }
}

Future<void> pumpDemoShell(WidgetTester tester, {required Widget home}) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: home)));
  await tester.pumpAndSettle();
}

Future<void> pumpLinkLabDemoApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const ProviderScope(child: LinkLabApp()));
  await tester.pumpAndSettle();
}

List<HelpRequestModel> readLocalHelpHistoryModels() {
  return LocalStorage()
      .getHelpHistory()
      .map(HelpRequestModel.fromJson)
      .toList();
}
