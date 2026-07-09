// AGENTS.md §4.2：竞赛版已冻结 Demo 主线。
// 该工厂保留为历史页面兼容层，默认且强制只返回 Demo 通话实现。

import '../core/utils/logger.dart';
import '../models/call_models.dart';

/// 通话模式
enum CallMode {
  demo,
  real,
}

/// 通话服务接口
abstract class ICallService {
  CallMode get mode;
  bool get isInCall;
  CallState get callState;
  Duration get callDuration;

  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  });

  Future<void> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  });

  Future<void> endCall(CallEndReason reason);
  Future<bool> toggleMute();
  Future<bool> toggleSpeaker();
  Future<void> startRecording();
  Future<void> stopRecording();
  Future<void> dispose();
}

class CallServiceFactory {
  static final CallServiceFactory _instance = CallServiceFactory._internal();
  factory CallServiceFactory() => _instance;
  CallServiceFactory._internal();

  CallMode _currentMode = CallMode.demo;

  CallMode get currentMode => _currentMode;

  void setMode(CallMode mode) {
    if (mode == CallMode.real) {
      AppLogger.warning(
        'AGENTS.md §4.2：竞赛版已冻结 Demo 主线，忽略切换到真实通话模式的请求',
      );
      _currentMode = CallMode.demo;
      return;
    }
    _currentMode = CallMode.demo;
  }

  void useDemoMode() {
    _currentMode = CallMode.demo;
  }

  void useRealMode() {
    AppLogger.warning(
      'AGENTS.md §4.2：竞赛版已冻结 Demo 主线，CallServiceFactory.useRealMode() 已被忽略',
    );
    _currentMode = CallMode.demo;
  }

  ICallService getService() {
    return DemoCallServiceAdapter();
  }
}

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
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> endCall(CallEndReason reason) async {}

  @override
  Future<bool> toggleMute() async => false;

  @override
  Future<bool> toggleSpeaker() async => true;

  @override
  Future<void> startRecording() async {}

  @override
  Future<void> stopRecording() async {}

  @override
  Future<void> dispose() async {}
}

ICallService get callService => CallServiceFactory().getService();

Future<void> initializeCallService({CallMode mode = CallMode.demo}) async {
  CallServiceFactory().setMode(mode);
}
