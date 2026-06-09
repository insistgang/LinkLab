import 'dart:async';

import '../../config/app_config.dart';
import '../../models/call_status_model.dart';
import '../demo_call_service.dart';

/// CallSessionFacade
///
/// AGENTS.md §12.2 統一入口：通話能力的唯一 facade。
/// 包裝 DemoCallService，對外屏蔽 demo/real 實現差異。
/// UI 層只允許通過本 facade 調用通話能力。
class CallSessionFacade {
  final DemoCallService _demoCall;

  CallSessionFacade({DemoCallService? demoCall})
    : _demoCall = demoCall ?? DemoCallService();

  // ────────────────────────── 通話流程 ──────────────────────────

  /// 開始通話
  ///
  /// [volunteerId] 志願者 ID
  Future<CallStatusModel> startCall(String volunteerId) async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.connected(
        volunteerId: volunteerId,
        volunteerName: '演示志願者',
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
      return CallStatusModel.error('startCall 失敗: $e');
    }
  }

  /// 結束通話
  Future<CallStatusModel> endCall() async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.ended();
    }

    try {
      await _demoCall.hangUp();
      return CallStatusModel.ended(callDuration: _demoCall.callDuration);
    } catch (e) {
      return CallStatusModel.error('endCall 失敗: $e');
    }
  }

  /// 切換靜音
  CallStatusModel toggleMute() {
    _demoCall.toggleMute();
    return _getCurrentStatus();
  }

  /// 切換揚聲器
  CallStatusModel toggleSpeaker() {
    _demoCall.toggleSpeaker();
    return _getCurrentStatus();
  }

  /// 獲取通話狀態
  CallStatusModel getCallStatus() {
    return _getCurrentStatus();
  }

  /// 模擬斷線（Demo 專用）
  Future<CallStatusModel> simulateDisconnect() async {
    if (AppConfig.demoMode || !FeatureFlags.enableWebRTC) {
      return CallStatusModel.disconnected();
    }

    try {
      // 模擬斷線：先掛斷，然後返回 disconnected 狀態
      await _demoCall.hangUp();
      return CallStatusModel.disconnected();
    } catch (e) {
      return CallStatusModel.error('simulateDisconnect 失敗: $e');
    }
  }

  // ────────────────────────── 內部輔助 ──────────────────────────

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
