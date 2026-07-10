import 'dart:async';

import '../../config/app_config.dart';
import '../../models/call_status_model.dart';
import '../demo_call_service.dart';

/// CallSessionFacade
///
/// AGENTS.md §12.2 统一入口：通话能力的唯一 facade。
/// 包装 DemoCallService，对外屏蔽 demo/real 实现差异。
/// UI 层只允许通过本 facade 调用通话能力。
class CallSessionFacade {
  final DemoCallService _demoCall;

  CallSessionFacade({DemoCallService? demoCall})
    : _demoCall = demoCall ?? DemoCallService();

  // ────────────────────────── 通话流程 ──────────────────────────

  /// 开始通话
  ///
  /// [volunteerId] 志愿者 ID
  Future<CallStatusModel> startCall(String volunteerId) async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.connected(
        volunteerId: volunteerId,
        volunteerName: '演示志愿者',
      );
    }

    try {
      await _demoCall.startCall();

      final volunteer = _demoCall.currentVolunteer;
      return CallStatusModel.connected(
        volunteerId: volunteer?.id ?? volunteerId,
        volunteerName: volunteer?.name,
        callDuration: _demoCall.callDuration,
      );
    } catch (e) {
      return CallStatusModel.error('startCall 失败: $e');
    }
  }

  /// 结束通话
  Future<CallStatusModel> endCall() async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.ended();
    }

    try {
      await _demoCall.hangUp();
      return CallStatusModel.ended(callDuration: _demoCall.callDuration);
    } catch (e) {
      return CallStatusModel.error('endCall 失败: $e');
    }
  }

  /// 切换静音
  CallStatusModel toggleMute() {
    _demoCall.toggleMute();
    return _getCurrentStatus();
  }

  /// 切换扬声器
  CallStatusModel toggleSpeaker() {
    _demoCall.toggleSpeaker();
    return _getCurrentStatus();
  }

  /// 获取通话状态
  CallStatusModel getCallStatus() {
    return _getCurrentStatus();
  }

  /// 模拟断线（Demo 专用）
  Future<CallStatusModel> simulateDisconnect() async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.disconnected();
    }

    try {
      // 模拟断线：先挂断，然后返回 disconnected 状态
      await _demoCall.hangUp();
      return CallStatusModel.disconnected();
    } catch (e) {
      return CallStatusModel.error('simulateDisconnect 失败: $e');
    }
  }

  // ────────────────────────── 内部辅助 ──────────────────────────

  CallStatusModel _getCurrentStatus() {
    final state = _demoCall.state;
    final volunteer = _demoCall.currentVolunteer;

    switch (state) {
      case DemoCallState.idle:
        return CallStatusModel.idle();
      case DemoCallState.connecting:
        return CallStatusModel.connecting(
          volunteerId: volunteer?.id ?? '',
          volunteerName: volunteer?.name,
        );
      case DemoCallState.ringing:
        return CallStatusModel.connecting(
          volunteerId: volunteer?.id ?? '',
          volunteerName: volunteer?.name,
        );
      case DemoCallState.connected:
        return CallStatusModel.connected(
          volunteerId: volunteer?.id ?? '',
          volunteerName: volunteer?.name,
          callDuration: _demoCall.callDuration,
        );
      case DemoCallState.ended:
        return CallStatusModel.ended(callDuration: _demoCall.callDuration);
    }
  }
}
