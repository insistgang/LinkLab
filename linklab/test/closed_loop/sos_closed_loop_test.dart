@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/demo_flow/demo_help_request_tracker.dart';
import 'package:linklab/screens/call/demo_sos_screen.dart';
import 'package:linklab/services/demo_call_service.dart';

import 'test_harness.dart';

void main() {
  testWidgets('SOS 闭环支持撤销窗口、取消和 Mock 广播状态变化', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(tester, home: const DemoSOSScreen());
    expect(find.text('长按3秒发送紧急求助'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await tester.pumpAndSettle();

    final createdHistory = readLocalHelpHistoryModels();
    expect(createdHistory.first.type, 'sos');
    expect(createdHistory.first.status, 'created');

    await DemoHelpRequestTracker.markCancelled(reason: 'SOS 误触撤销');
    await tester.pumpAndSettle();

    final cancelledHistory = readLocalHelpHistoryModels();
    expect(cancelledHistory.first.status, 'cancelled');

    await DemoHelpRequestTracker.startSOSUndoWindow();
    await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: 'SOS紧急求助',
      type: 'sos',
      urgency: 'emergency',
    );

    final sosService = DemoSOSService();
    final triggerFuture = sosService.triggerSOS();

    await tester.pump(const Duration(seconds: 3));
    expect(sosService.isActive, isTrue);
    expect(sosService.responderCount, 5);
    expect(sosService.statusText, contains('志愿者响应'));

    await tester.pump(const Duration(seconds: 2));
    await triggerFuture;
    sosService.cancelSOS();
    await tester.pump();

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');
  });
}
