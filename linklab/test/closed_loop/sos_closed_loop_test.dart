@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/demo_flow/demo_help_request_tracker.dart';
import 'package:linklab/screens/call/demo_sos_screen.dart';
import 'package:linklab/services/demo_call_service.dart';

import 'test_harness.dart';

void main() {
  testWidgets('SOS 緊急態首屏顯示正文，並支持撤銷取消和 Mock 廣播', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    tester.view.physicalSize = const Size(500, 934);
    tester.view.devicePixelRatio = 1.0;
    final sosService = DemoSOSService()..cancelSOS();
    addTearDown(() {
      sosService.cancelSOS();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final triggerFuture = sosService.triggerSOS();
    await tester.pump(const Duration(seconds: 5));
    await triggerFuture;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DemoSOSScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('SOS 緊急求助進行中'), findsOneWidget);
    expect(find.text('SOS緊急求助進行中'), findsOneWidget);
    expect(find.text('求助中'), findsOneWidget);
    expect(find.text('安全了'), findsOneWidget);
    expect(find.text('取消求助'), findsOneWidget);
    expect(tester.takeException(), isNull);

    sosService.cancelSOS();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(DemoSOSService().statusText, '長按3秒發送緊急求助');

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await tester.pump();

    final createdHistory = readLocalHelpHistoryModels();
    expect(createdHistory.first.type, 'sos');
    expect(createdHistory.first.status, 'created');

    await DemoHelpRequestTracker.markCancelled(reason: 'SOS 誤觸撤銷');
    await tester.pump();

    final cancelledHistory = readLocalHelpHistoryModels();
    expect(cancelledHistory.first.status, 'cancelled');

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: 'SOS緊急求助',
      type: 'sos',
      urgency: 'emergency',
    );

    final secondTriggerFuture = sosService.triggerSOS();

    await tester.pump(const Duration(seconds: 3));
    expect(sosService.isActive, isTrue);
    expect(sosService.responderCount, 5);
    expect(sosService.statusText, contains('志願者響應'));

    await tester.pump(const Duration(seconds: 2));
    await secondTriggerFuture;
    sosService.cancelSOS();
    await tester.pump();

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');
  });
}
