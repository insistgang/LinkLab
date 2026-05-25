import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo_flow/demo_matching_flow.dart';
import '../screens/ai_chat/demo_ai_chat_screen.dart';
import '../screens/call/demo_exports.dart';
import '../widgets/demo/demo_routes.dart';

enum DemoFlowStep {
  home,
  aiChat,
  matching,
  call,
  rating,
  sos,
}

@immutable
class DemoFlowState {
  const DemoFlowState({
    this.currentStep = DemoFlowStep.home,
    this.isNavigating = false,
  });

  final DemoFlowStep currentStep;
  final bool isNavigating;

  DemoFlowState copyWith({
    DemoFlowStep? currentStep,
    bool? isNavigating,
  }) {
    return DemoFlowState(
      currentStep: currentStep ?? this.currentStep,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}

final demoFlowProvider =
    NotifierProvider<DemoFlowNotifier, DemoFlowState>(DemoFlowNotifier.new);

class DemoFlowNotifier extends Notifier<DemoFlowState> {
  @override
  DemoFlowState build() => const DemoFlowState();

  void startAIChatFlow(BuildContext context) {
    state = state.copyWith(
      currentStep: DemoFlowStep.aiChat,
      isNavigating: true,
    );
    pushDemoStageRoute<void>(context, page: const DemoAIChatScreen());
    state = state.copyWith(isNavigating: false);
  }

  void startMatchingFlow(BuildContext context) {
    state = state.copyWith(
      currentStep: DemoFlowStep.matching,
      isNavigating: true,
    );
    DemoMatchingFlow.startMatching(context);
    state = state.copyWith(isNavigating: false);
  }

  void startSOSFlow(
    BuildContext context, {
    bool autoStartUndoWindow = false,
    bool autoActivateEmergency = false,
  }) {
    state = state.copyWith(
      currentStep: DemoFlowStep.sos,
      isNavigating: true,
    );
    pushDemoStageRoute<void>(
      context,
      page: DemoSOSScreen(
        autoStartUndoWindow: autoStartUndoWindow,
        autoActivateEmergency: autoActivateEmergency,
      ),
    );
    state = state.copyWith(isNavigating: false);
  }

  void resetFlow(BuildContext context) {
    state = const DemoFlowState();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
