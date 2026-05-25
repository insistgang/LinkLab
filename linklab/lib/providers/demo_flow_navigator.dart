import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_flow_provider.dart';

class DemoFlowNavigator {
  const DemoFlowNavigator._();

  static void onHomeBigButtonPressed(WidgetRef ref, BuildContext context) {
    ref.read(demoFlowProvider.notifier).startAIChatFlow(context);
  }

  static void onSOSButtonPressed(
    WidgetRef ref,
    BuildContext context, {
    bool autoStartUndoWindow = false,
    bool autoActivateEmergency = false,
  }) {
    ref
        .read(demoFlowProvider.notifier)
        .startSOSFlow(
          context,
          autoStartUndoWindow: autoStartUndoWindow,
          autoActivateEmergency: autoActivateEmergency,
        );
  }

  static void onAIRequestMatching(WidgetRef ref, BuildContext context) {
    ref.read(demoFlowProvider.notifier).startMatchingFlow(context);
  }

  static void onCallEnded(WidgetRef ref, BuildContext context) {
    ref.read(demoFlowProvider.notifier).resetFlow(context);
  }
}
