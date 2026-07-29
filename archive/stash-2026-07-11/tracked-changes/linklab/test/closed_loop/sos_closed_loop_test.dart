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
  testWidgets('SOS 紧急态首屏显示正文，并支持撤销取消和 Mock 广播', (tester) async {
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

    expect(find.text('SOS 紧急求助进行中'), findsOneWidget);
    expect(find.text('SOS紧急求助进行中'), findsOneWidget);
    expect(find.text('求助中'), findsOneWidget);
    expect(find.text('安全了'), findsOneWidget);
    expect(find.text('取消求助'), findsOneWidget);
    expect(tester.takeException(), isNull);

    sosService.cancelSOS();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(DemoSOSService().statusText, '长按3秒发送紧急求助');

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await tester.pump();

    final createdHistory = readLocalHelpHistoryModels();
    expect(createdHistory.first.type, 'sos');
    expect(createdHistory.first.status, 'created');

    await DemoHelpRequestTracker.markCancelled(reason: 'SOS 误触撤销');
    await tester.pump();

    final cancelledHistory = readLocalHelpHistoryModels();
    expect(cancelledHistory.first.status, 'cancelled');

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: 'SOS紧急求助',
      type: 'sos',
      urgency: 'emergency',
    );

    final secondTriggerFuture = sosService.triggerSOS();

    await tester.pump(const Duration(seconds: 3));
    expect(sosService.isActive, isTrue);
    expect(sosService.responderCount, 5);
    expect(sosService.statusText, contains('志愿者响应'));

    await tester.pump(const Duration(seconds: 2));
    await secondTriggerFuture;
    sosService.cancelSOS();
    await tester.pump();

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');
  });
}
