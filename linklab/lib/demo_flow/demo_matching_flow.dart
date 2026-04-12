// 演示版匹配流程
// 控制从AI对话到通话完成的整个流程

import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/call/demo_exports.dart';
import '../services/demo_call_service.dart';
import 'demo_flow_controller.dart';

/// 演示版匹配流程控制器
class DemoMatchingFlow {
  /// 开始匹配流程
  static Future<void> startMatching(BuildContext context) async {
    // 1. 进入匹配等待页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DemoMatchingScreen(),
      ),
    );

    // 2. 等待匹配完成（由DemoMatchingService控制）
    // 匹配成功后自动导航到通话页面
  }

  /// 快速匹配（用于演示快捷入口）
  static Future<void> quickMatch(BuildContext context) async {
    final matchingService = DemoMatchingService();

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在快速匹配志愿者...'),
          ],
        ),
      ),
    );

    // 模拟匹配
    await matchingService.startMatching();

    // 关闭对话框
    if (context.mounted) {
      Navigator.of(context).pop();

      // 直接进入通话
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DemoCallScreen(),
        ),
      );
    }
  }

  /// SOS匹配流程
  static Future<void> sosMatch(BuildContext context) async {
    final sosService = DemoSOSService();

    // 触发SOS
    await sosService.triggerSOS();

    // 等待响应后进入通话
    // 由DemoSOSService控制流程
  }
}

/// 演示版通话流程控制器
class DemoCallFlow {
  static Timer? _autoEndTimer;

  /// 开始通话
  static Future<void> startCall(BuildContext context) async {
    final callService = DemoCallService();

    // 开始通话
    await callService.startCall();

    // 设置自动结束（演示模式）
    _autoEndTimer?.cancel();
    _autoEndTimer = Timer(
      Duration(seconds: DemoFlowConfig.callAutoEndDuration),
      () => endCall(context),
    );
  }

  /// 结束通话
  static Future<void> endCall(BuildContext context) async {
    _autoEndTimer?.cancel();

    final callService = DemoCallService();
    final volunteer = callService.currentVolunteer;
    final duration = callService.callDuration;

    await callService.hangUp();

    if (context.mounted && volunteer != null) {
      // 进入评价页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DemoCallRatingScreen(
            volunteer: volunteer,
            duration: duration,
          ),
        ),
      );
    }
  }

  /// 跳过通话直接评价（演示用）
  static void skipToRating(BuildContext context) {
    _autoEndTimer?.cancel();

    final callService = DemoCallService();
    final volunteer = callService.currentVolunteer ?? demoVolunteers.first;
    final duration = const Duration(seconds: 10); // 模拟10秒通话

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DemoCallRatingScreen(
          volunteer: volunteer,
          duration: duration,
        ),
      ),
    );
  }
}

/// 演示流程状态管理
class DemoFlowState extends ChangeNotifier {
  static final DemoFlowState _instance = DemoFlowState._internal();
  factory DemoFlowState() => _instance;
  DemoFlowState._internal();

  // 当前流程状态
  bool _isInDemoFlow = false;
  String _currentStep = 'idle';
  String? _currentVolunteerName;

  // Getters
  bool get isInDemoFlow => _isInDemoFlow;
  String get currentStep => _currentStep;
  String? get currentVolunteerName => _currentVolunteerName;

  /// 开始演示流程
  void startFlow() {
    _isInDemoFlow = true;
    _currentStep = 'ai_chat';
    notifyListeners();
  }

  /// 进入匹配
  void enterMatching() {
    _currentStep = 'matching';
    notifyListeners();
  }

  /// 匹配成功
  void onMatched(String volunteerName) {
    _currentStep = 'matched';
    _currentVolunteerName = volunteerName;
    notifyListeners();
  }

  /// 进入通话
  void enterCall() {
    _currentStep = 'call';
    notifyListeners();
  }

  /// 通话结束
  void endCall() {
    _currentStep = 'rating';
    notifyListeners();
  }

  /// 流程完成
  void completeFlow() {
    _isInDemoFlow = false;
    _currentStep = 'idle';
    _currentVolunteerName = null;
    notifyListeners();
  }

  /// 重置流程
  void reset() {
    _isInDemoFlow = false;
    _currentStep = 'idle';
    _currentVolunteerName = null;
    notifyListeners();
  }
}

/// 演示快捷入口
class DemoQuickActions {
  /// 一键演示完整流程
  static Future<void> runFullDemo(BuildContext context) async {
    final flowState = DemoFlowState();
    flowState.startFlow();

    // 1. AI对话
    await Future.delayed(const Duration(seconds: 2));

    // 2. 触发匹配
    flowState.enterMatching();
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DemoMatchingScreen()),
      );
    }
  }

  /// 直接演示匹配成功
  static void showMatchedDemo(BuildContext context) {
    DemoMatchingFlow.quickMatch(context);
  }

  /// 直接演示通话中
  static void showCallDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DemoCallScreen()),
    );
  }

  /// 直接演示SOS
  static void showSOSDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DemoSOSScreen()),
    );
  }
}
