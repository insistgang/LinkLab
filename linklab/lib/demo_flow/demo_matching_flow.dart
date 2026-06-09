// 演示版匹配流程
// 控制從AI對話到通話完成的整個流程

import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/call/demo_exports.dart';
import '../services/demo_call_service.dart';
import '../widgets/demo/demo_routes.dart';
import 'demo_flow_controller.dart';

/// 演示版匹配流程控制器
class DemoMatchingFlow {
  /// 開始匹配流程
  static Future<void> startMatching(BuildContext context) async {
    // 1. 進入匹配等待頁面
    await pushDemoStageRoute(context, page: const DemoMatchingScreen());

    // 2. 等待匹配完成（由DemoMatchingService控制）
    // 匹配成功後自動導航到通話頁面
  }

  /// 快速匹配（用於演示快捷入口）
  static Future<void> quickMatch(BuildContext context) async {
    final matchingService = DemoMatchingService();

    // 顯示加載對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在快速匹配志願者...'),
          ],
        ),
      ),
    );

    // 模擬匹配
    await matchingService.startMatching();

    // 關閉對話框
    if (context.mounted) {
      Navigator.of(context).pop();

      // 直接進入通話
      pushDemoStageRoute(context, page: const DemoCallScreen());
    }
  }

  /// SOS匹配流程
  static Future<void> sosMatch(BuildContext context) async {
    final sosService = DemoSOSService();

    // 觸發SOS
    await sosService.triggerSOS();

    // 等待響應後進入通話
    // 由DemoSOSService控制流程
  }
}

/// 演示版通話流程控制器
class DemoCallFlow {
  static Timer? _autoEndTimer;

  /// 開始通話
  static Future<void> startCall(BuildContext context) async {
    final callService = DemoCallService();

    // 開始通話
    await callService.startCall();

    // 設置自動結束（演示模式）
    _autoEndTimer?.cancel();
    _autoEndTimer = Timer(
      const Duration(seconds: DemoFlowConfig.callAutoEndDuration),
      () => endCall(context),
    );
  }

  /// 結束通話
  static Future<void> endCall(BuildContext context) async {
    _autoEndTimer?.cancel();

    final callService = DemoCallService();
    final volunteer = callService.currentVolunteer;
    final duration = callService.callDuration;

    await callService.hangUp();

    if (context.mounted && volunteer != null) {
      // 進入評價頁面
      Navigator.of(context).pushReplacement(
        buildDemoStageRoute(
          page: DemoCallRatingScreen(volunteer: volunteer, duration: duration),
        ),
      );
    }
  }

  /// 跳過通話直接評價（演示用）
  static void skipToRating(BuildContext context) {
    _autoEndTimer?.cancel();

    final callService = DemoCallService();
    final volunteer = callService.currentVolunteer ?? demoVolunteers.first;
    final duration = const Duration(seconds: 10); // 模擬10秒通話

    Navigator.of(context).pushReplacement(
      buildDemoStageRoute(
        page: DemoCallRatingScreen(volunteer: volunteer, duration: duration),
      ),
    );
  }
}

/// 演示流程狀態管理（舊版 ChangeNotifier，已被 Riverpod 版本替代）
@Deprecated('使用 providers/demo_flow_provider.dart 中的 Riverpod DemoFlowState 替代')
class _LegacyDemoFlowState extends ChangeNotifier {
  static final _LegacyDemoFlowState _instance = _LegacyDemoFlowState._internal();
  factory _LegacyDemoFlowState() => _instance;
  _LegacyDemoFlowState._internal();

  // 當前流程狀態
  bool _isInDemoFlow = false;
  String _currentStep = 'idle';
  String? _currentVolunteerName;

  // Getters
  bool get isInDemoFlow => _isInDemoFlow;
  String get currentStep => _currentStep;
  String? get currentVolunteerName => _currentVolunteerName;

  /// 開始演示流程
  void startFlow() {
    _isInDemoFlow = true;
    _currentStep = 'ai_chat';
    notifyListeners();
  }

  /// 進入匹配
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

  /// 進入通話
  void enterCall() {
    _currentStep = 'call';
    notifyListeners();
  }

  /// 通話結束
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
  /// 一鍵演示完整流程
  static Future<void> runFullDemo(BuildContext context) async {
    final flowState = _LegacyDemoFlowState();
    flowState.startFlow();

    // 1. AI對話
    await Future.delayed(const Duration(seconds: 2));

    // 2. 觸發匹配
    flowState.enterMatching();
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      pushDemoStageRoute(context, page: const DemoMatchingScreen());
    }
  }

  /// 直接演示匹配成功
  static void showMatchedDemo(BuildContext context) {
    DemoMatchingFlow.quickMatch(context);
  }

  /// 直接演示通話中
  static void showCallDemo(BuildContext context) {
    pushDemoStageRoute(context, page: const DemoCallScreen());
  }

  /// 直接演示SOS
  static void showSOSDemo(BuildContext context) {
    pushDemoStageRoute(context, page: const DemoSOSScreen());
  }
}
