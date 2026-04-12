// 演示版核心流程控制器
// 管理整个演示流程的导航和状态

import 'package:flutter/material.dart';

import '../screens/call/demo_exports.dart';
import '../services/demo_call_service.dart';
import 'demo_ai_service.dart';
import 'demo_matching_flow.dart';

/// 演示流程步骤
enum DemoFlowStep {
  home,           // 首页
  aiChat,         // AI对话
  matching,       // 匹配等待
  call,           // 通话中
  rating,         // 评价
  sos,            // SOS紧急
}

/// 演示流程控制器
class DemoFlowController extends ChangeNotifier {
  static final DemoFlowController _instance = DemoFlowController._internal();
  factory DemoFlowController() => _instance;
  DemoFlowController._internal();

  DemoFlowStep _currentStep = DemoFlowStep.home;
  DemoFlowStep get currentStep => _currentStep;

  // 当前上下文（用于导航）
  BuildContext? _context;
  void setContext(BuildContext context) => _context = context;

  /// 从首页开始AI对话流程
  void startAIChatFlow() {
    _currentStep = DemoFlowStep.aiChat;
    notifyListeners();

    if (_context != null) {
      Navigator.of(_context!).pushNamed('/ai_chat');
    }
  }

  /// 从AI对话进入匹配流程
  void startMatchingFlow() {
    _currentStep = DemoFlowStep.matching;
    notifyListeners();

    if (_context != null) {
      DemoMatchingFlow.startMatching(_context!);
    }
  }

  /// 直接开始SOS流程
  void startSOSFlow() {
    _currentStep = DemoFlowStep.sos;
    notifyListeners();

    if (_context != null) {
      Navigator.of(_context!).push(
        MaterialPageRoute(builder: (_) => const DemoSOSScreen()),
      );
    }
  }

  /// 重置流程到首页
  void resetFlow() {
    _currentStep = DemoFlowStep.home;
    notifyListeners();

    if (_context != null) {
      Navigator.of(_context!).popUntil((route) => route.isFirst);
    }
  }

  /// 返回上一步
  void goBack() {
    if (_context != null && Navigator.of(_context!).canPop()) {
      Navigator.of(_context!).pop();
      _updateStepFromNavigator();
    }
  }

  void _updateStepFromNavigator() {
    // 根据当前路由更新步骤
    // 实际项目中可以通过RouteObserver实现
  }
}

/// 演示流程导航器
class DemoFlowNavigator {
  /// 首页大按钮点击 → AI对话
  static void onHomeBigButtonPressed(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().startAIChatFlow();
  }

  /// SOS按钮点击 → SOS页面
  static void onSOSButtonPressed(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().startSOSFlow();
  }

  /// AI对话中触发匹配 → 匹配等待
  static void onAIRequestMatching(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().startMatchingFlow();
  }

  /// 通话结束 → 返回首页
  static void onCallEnded(BuildContext context) {
    DemoFlowController().setContext(context);
    DemoFlowController().resetFlow();
  }
}

/// 演示流程配置
class DemoFlowConfig {
  /// AI思考延迟（秒）
  static const int aiThinkingDelay = 2;

  /// 匹配等待时间（秒）
  static const int matchingDelay = 4;

  /// 通话自动结束时间（秒）
  static const int callAutoEndDuration = 30;

  /// SOS响应时间（秒）
  static const int sosResponseDelay = 5;

  /// 是否启用自动流程（演示模式）
  static const bool autoFlowEnabled = true;
}
