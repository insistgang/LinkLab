// 通话服务工厂
// 统一管理演示版和真实版通话服务

import 'package:flutter/material.dart';

import '../models/call_models.dart';
import 'webrtc/webrtc_call_manager.dart';

/// 通话模式
enum CallMode {
  demo,   // 演示模式（模拟通话）
  real,   // 真实模式（WebRTC P2P）
}

/// 通话服务接口
abstract class ICallService {
  /// 当前通话模式
  CallMode get mode;

  /// 是否正在通话中
  bool get isInCall;

  /// 通话状态
  CallState get callState;

  /// 通话时长
  Duration get callDuration;

  /// 发起通话（求助者）
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  });

  /// 接听通话（志愿者）
  Future<void> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  });

  /// 结束通话
  Future<void> endCall(CallEndReason reason);

  /// 静音/取消静音
  Future<bool> toggleMute();

  /// 切换扬声器
  Future<bool> toggleSpeaker();

  /// 开始录音
  Future<void> startRecording();

  /// 停止录音
  Future<void> stopRecording();

  /// 释放资源
  Future<void> dispose();
}

/// 通话服务工厂
class CallServiceFactory {
  static final CallServiceFactory _instance = CallServiceFactory._internal();
  factory CallServiceFactory() => _instance;
  CallServiceFactory._internal();

  CallMode _currentMode = CallMode.demo;

  /// 当前通话模式
  CallMode get currentMode => _currentMode;

  /// 设置通话模式
  void setMode(CallMode mode) {
    _currentMode = mode;
  }

  /// 切换到演示模式
  void useDemoMode() {
    _currentMode = CallMode.demo;
  }

  /// 切换到真实模式
  void useRealMode() {
    _currentMode = CallMode.real;
  }

  /// 获取通话服务
  ICallService getService() {
    switch (_currentMode) {
      case CallMode.demo:
        return DemoCallServiceAdapter();
      case CallMode.real:
        return RealCallServiceAdapter();
    }
  }
}

/// 真实通话服务适配器
class RealCallServiceAdapter implements ICallService {
  final WebRTCCallManager _manager = WebRTCCallManager();

  @override
  CallMode get mode => CallMode.real;

  @override
  bool get isInCall => _manager.isInCall;

  @override
  CallState get callState => _manager.currentCall?.state ?? CallState.idle;

  @override
  Duration get callDuration => _manager.callDuration;

  @override
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    await _manager.startCallAsSeeker(
      seekerId: seekerId,
      helpRequestId: helpRequestId,
      volunteerId: volunteerId,
      enableRecording: enableRecording,
    );
  }

  @override
  Future<void> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    await _manager.acceptCallAsVolunteer(
      volunteerId: volunteerId,
      seekerId: seekerId,
      helpRequestId: helpRequestId,
      roomId: roomId,
      enableRecording: enableRecording,
    );
  }

  @override
  Future<void> endCall(CallEndReason reason) async {
    await _manager.endCall(reason);
  }

  @override
  Future<bool> toggleMute() async {
    return await _manager.toggleMute();
  }

  @override
  Future<bool> toggleSpeaker() async {
    return await _manager.toggleSpeaker();
  }

  @override
  Future<void> startRecording() async {
    await _manager.startRecording();
  }

  @override
  Future<void> stopRecording() async {
    await _manager.stopRecording();
  }

  @override
  Future<void> dispose() async {
    await _manager.dispose();
  }
}

/// 演示通话服务适配器（简化版）
class DemoCallServiceAdapter implements ICallService {
  @override
  CallMode get mode => CallMode.demo;

  @override
  bool get isInCall => false;

  @override
  CallState get callState => CallState.idle;

  @override
  Duration get callDuration => Duration.zero;

  @override
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    // 演示模式：仅模拟，不建立真实连接
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    // 演示模式：仅模拟，不建立真实连接
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> endCall(CallEndReason reason) async {
    // 演示模式：无操作
  }

  @override
  Future<bool> toggleMute() async {
    return false;
  }

  @override
  Future<bool> toggleSpeaker() async {
    return true;
  }

  @override
  Future<void> startRecording() async {
    // 演示模式：无操作
  }

  @override
  Future<void> stopRecording() async {
    // 演示模式：无操作
  }

  @override
  Future<void> dispose() async {
    // 演示模式：无操作
  }
}

/// 全局通话服务访问点
ICallService get callService => CallServiceFactory().getService();

/// 初始化通话服务
Future<void> initializeCallService({CallMode mode = CallMode.demo}) async {
  CallServiceFactory().setMode(mode);

  if (mode == CallMode.real) {
    await WebRTCCallManager().initialize();
  }
}
