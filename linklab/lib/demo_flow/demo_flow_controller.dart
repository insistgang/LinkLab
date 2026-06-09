// 演示版核心流程控制器
// [DEPRECATED] 使用 providers/demo_flow_provider.dart 和 providers/demo_flow_navigator.dart 替代
// 保留此文件僅作向後兼容，新代碼請使用 Riverpod provider

import 'package:flutter/material.dart';

import '../screens/ai_chat/demo_ai_chat_screen.dart';
import '../screens/call/demo_exports.dart';
import '../widgets/demo/demo_routes.dart';
import 'demo_matching_flow.dart';

/// 演示流程步驟
@Deprecated('使用 providers/demo_flow_provider.dart 中的 DemoFlowStep 替代')
enum DemoFlowStep {
  home,
  aiChat,
  matching,
  call,
  rating,
  sos,
}

/// 演示流程控制器
@Deprecated('使用 providers/demo_flow_provider.dart 中的 DemoFlowNotifier 替代')
class DemoFlowController extends ChangeNotifier {
  static final DemoFlowController _instance = DemoFlowController._internal();
  factory DemoFlowController() => _instance;
  DemoFlowController._internal();

  DemoFlowStep _currentStep = DemoFlowStep.home;
  DemoFlowStep get currentStep => _currentStep;

  BuildContext? _context;
  void setContext(BuildContext context) => _context = context;

  void startAIChatFlow() {
    _currentStep = DemoFlowStep.aiChat;
    notifyListeners();
    if (_context != null) {
      pushDemoStageRoute(_context!, page: const DemoAIChatScreen());
    }
  }

  void startMatchingFlow() {
    _currentStep = DemoFlowStep.matching;
    notifyListeners();
    if (_context != null) {
      DemoMatchingFlow.startMatching(_context!);
    }
  }

  void startSOSFlow({
    bool autoStartUndoWindow = false,
    bool autoActivateEmergency = false,
  }) {
    _currentStep = DemoFlowStep.sos;
    notifyListeners();
    if (_context != null) {
      pushDemoStageRoute(
        _context!,
        page: DemoSOSScreen(
          autoStartUndoWindow: autoStartUndoWindow,
          autoActivateEmergency: autoActivateEmergency,
        ),
      );
    }
  }

  void resetFlow() {
    _currentStep = DemoFlowStep.home;
    notifyListeners();
    if (_context != null) {
      Navigator.of(_context!).popUntil((route) => route.isFirst);
    }
  }

  void goBack() {
    if (_context != null && Navigator.of(_context!).canPop()) {
      Navigator.of(_context!).pop();
    }
  }
}

/// 演示流程導航器
@Deprecated('使用 providers/demo_flow_navigator.dart 中的 DemoFlowNavigator 替代')
class DemoFlowNavigatorLegacy {
  static void onHomeBigButtonPressed(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().startAIChatFlow();
  }

  static void onSOSButtonPressed(
    BuildContext context, {
    bool autoStartUndoWindow = false,
    bool autoActivateEmergency = false,
  }) {
    DemoFlowController().setContext(context);
    DemoFlowController().startSOSFlow(
      autoStartUndoWindow: autoStartUndoWindow,
      autoActivateEmergency: autoActivateEmergency,
    );
  }

  static void onAIRequestMatching(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().startMatchingFlow();
  }

  static void onCallEnded(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().resetFlow();
  }
}

/// 演示流程配置
class DemoFlowConfig {
  /// AI思考延遲（秒）
  static const int aiThinkingDelay = 2;

  /// 匹配等待時間（秒）
  static const int matchingDelay = 4;

  /// 通話自動結束時間（秒）
  static const int callAutoEndDuration = 30;

  /// SOS響應時間（秒）
  static const int sosResponseDelay = 5;

  /// 是否啓用自動流程（演示模式）
  static const bool autoFlowEnabled = true;
}
