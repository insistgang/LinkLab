import 'dart:async';

import '../../models/sos_result_model.dart';
import '../demo_call_service.dart';
import '../security/emergency_contact_service.dart';

/// SosFacade
///
/// AGENTS.md §12.2 統一入口：SOS 緊急呼救能力的唯一 facade。
/// 包裝 DemoSOSService / EmergencyContactService，對外屏蔽 demo/real 實現差異。
/// UI 層只允許通過本 facade 調用 SOS 能力。
class SosFacade {
  final DemoSOSService _demoSOS;
  final EmergencyContactService _emergencyContacts;

  SosFacade({
    DemoSOSService? demoSOS,
    EmergencyContactService? emergencyContacts,
  })  : _demoSOS = demoSOS ?? DemoSOSService(),
        _emergencyContacts = emergencyContacts ?? EmergencyContactService();

  // ────────────────────────── SOS 流程 ──────────────────────────

  /// 觸發 SOS
  ///
  /// 進入 10 秒誤觸撤銷窗口，然後開始廣播。
  Future<SOSResultModel> triggerSOS() async {
    try {
      // 開始誤觸撤銷窗口
      final undoResult = await startUndoWindow();
      if (!undoResult.success) return undoResult;

      // 等待 10 秒撤銷窗口
      await Future.delayed(const Duration(seconds: 10));

      // 廣播附近志願者
      final broadcastResult = await broadcastToNearby();

      // 通知緊急聯繫人
      final notifyResult = await notifyEmergencyContacts();

      return SOSResultModel.active(
        responderCount: broadcastResult.responderCount,
        notifiedContactCount: notifyResult.notifiedContactCount,
      );
    } catch (e) {
      return SOSResultModel.error('triggerSOS 失敗: $e');
    }
  }

  /// 取消 SOS
  Future<SOSResultModel> cancelSOS() async {
    try {
      _demoSOS.cancelSOS();
      return SOSResultModel.cancelled();
    } catch (e) {
      return SOSResultModel.error('cancelSOS 失敗: $e');
    }
  }

  /// 開始誤觸撤銷窗口
  ///
  /// 10 秒內可撤銷，超時後自動進入廣播流程。
  Future<SOSResultModel> startUndoWindow() async {
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      return SOSResultModel.undoWindow(deadline: deadline);
    } catch (e) {
      return SOSResultModel.error('startUndoWindow 失敗: $e');
    }
  }

  /// 廣播附近志願者
  Future<SOSResultModel> broadcastToNearby() async {
    try {
      await _demoSOS.triggerSOS();
      return SOSResultModel.broadcasting(responderCount: _demoSOS.responderCount);
    } catch (e) {
      return SOSResultModel.error('broadcastToNearby 失敗: $e');
    }
  }

  /// 通知緊急聯繫人
  Future<SOSResultModel> notifyEmergencyContacts() async {
    try {
      final userId = 'current_user'; // Demo 使用固定用戶
      final contacts = await _emergencyContacts.getContacts(userId);

      if (contacts.isEmpty) {
        return SOSResultModel.active(
          responderCount: _demoSOS.responderCount,
          notifiedContactCount: 0,
        );
      }

      // 模擬通知（Demo 模式下不真實發送）
      await _emergencyContacts.notifyEmergencyContacts(
        userId: userId,
        latitude: 31.23,
        longitude: 121.47,
        address: '演示地址',
        message: '【共感LinkAble緊急求助】用戶觸發了 SOS 緊急求助。',
      );

      return SOSResultModel.active(
        responderCount: _demoSOS.responderCount,
        notifiedContactCount: contacts.length,
      );
    } catch (e) {
      return SOSResultModel.error('notifyEmergencyContacts 失敗: $e');
    }
  }

  /// 獲取 SOS 狀態
  SOSResultModel getSOSStatus() {
    final isActive = _demoSOS.isActive;
    final responderCount = _demoSOS.responderCount;

    if (!isActive) {
      return SOSResultModel.idle();
    }

    return SOSResultModel.broadcasting(responderCount: responderCount);
  }
}
