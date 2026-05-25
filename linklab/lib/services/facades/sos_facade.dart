import 'dart:async';

import '../../models/sos_result_model.dart';
import '../demo_call_service.dart';
import '../security/emergency_contact_service.dart';

/// SosFacade
///
/// AGENTS.md §12.2 统一入口：SOS 紧急呼救能力的唯一 facade。
/// 包装 DemoSOSService / EmergencyContactService，对外屏蔽 demo/real 实现差异。
/// UI 层只允许通过本 facade 调用 SOS 能力。
class SosFacade {
  final DemoSOSService _demoSOS;
  final EmergencyContactService _emergencyContacts;

  SosFacade({
    DemoSOSService? demoSOS,
    EmergencyContactService? emergencyContacts,
  })  : _demoSOS = demoSOS ?? DemoSOSService(),
        _emergencyContacts = emergencyContacts ?? EmergencyContactService();

  // ────────────────────────── SOS 流程 ──────────────────────────

  /// 触发 SOS
  ///
  /// 进入 10 秒误触撤销窗口，然后开始广播。
  Future<SOSResultModel> triggerSOS() async {
    try {
      // 开始误触撤销窗口
      final undoResult = await startUndoWindow();
      if (!undoResult.success) return undoResult;

      // 等待 10 秒撤销窗口
      await Future.delayed(const Duration(seconds: 10));

      // 广播附近志愿者
      final broadcastResult = await broadcastToNearby();

      // 通知紧急联系人
      final notifyResult = await notifyEmergencyContacts();

      return SOSResultModel.active(
        responderCount: broadcastResult.responderCount,
        notifiedContactCount: notifyResult.notifiedContactCount,
      );
    } catch (e) {
      return SOSResultModel.error('triggerSOS 失败: $e');
    }
  }

  /// 取消 SOS
  Future<SOSResultModel> cancelSOS() async {
    try {
      _demoSOS.cancelSOS();
      return SOSResultModel.cancelled();
    } catch (e) {
      return SOSResultModel.error('cancelSOS 失败: $e');
    }
  }

  /// 开始误触撤销窗口
  ///
  /// 10 秒内可撤销，超时后自动进入广播流程。
  Future<SOSResultModel> startUndoWindow() async {
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      return SOSResultModel.undoWindow(deadline: deadline);
    } catch (e) {
      return SOSResultModel.error('startUndoWindow 失败: $e');
    }
  }

  /// 广播附近志愿者
  Future<SOSResultModel> broadcastToNearby() async {
    try {
      await _demoSOS.triggerSOS();
      return SOSResultModel.broadcasting(responderCount: _demoSOS.responderCount);
    } catch (e) {
      return SOSResultModel.error('broadcastToNearby 失败: $e');
    }
  }

  /// 通知紧急联系人
  Future<SOSResultModel> notifyEmergencyContacts() async {
    try {
      final userId = 'current_user'; // Demo 使用固定用户
      final contacts = await _emergencyContacts.getContacts(userId);

      if (contacts.isEmpty) {
        return SOSResultModel.active(
          responderCount: _demoSOS.responderCount,
          notifiedContactCount: 0,
        );
      }

      // 模拟通知（Demo 模式下不真实发送）
      await _emergencyContacts.notifyEmergencyContacts(
        userId: userId,
        latitude: 31.23,
        longitude: 121.47,
        address: '演示地址',
        message: '【共感LinkAble紧急求助】用户触发了 SOS 紧急求助。',
      );

      return SOSResultModel.active(
        responderCount: _demoSOS.responderCount,
        notifiedContactCount: contacts.length,
      );
    } catch (e) {
      return SOSResultModel.error('notifyEmergencyContacts 失败: $e');
    }
  }

  /// 获取 SOS 状态
  SOSResultModel getSOSStatus() {
    final isActive = _demoSOS.isActive;
    final responderCount = _demoSOS.responderCount;

    if (!isActive) {
      return SOSResultModel.idle();
    }

    return SOSResultModel.broadcasting(responderCount: responderCount);
  }
}
