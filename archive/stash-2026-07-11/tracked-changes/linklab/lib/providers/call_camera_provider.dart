import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/logger.dart';

enum CallCameraStatus { off, initializing, live, unavailable, denied, error }

@immutable
class CallCameraSession {
  const CallCameraSession({
    required this.isRealCamera,
    this.controller,
    this.cameraName = '本机摄像头',
  });

  final bool isRealCamera;
  final CameraController? controller;
  final String cameraName;
}

@immutable
class CallCameraState {
  const CallCameraState({
    required this.status,
    required this.message,
    this.session,
  });

  factory CallCameraState.off() {
    return const CallCameraState(
      status: CallCameraStatus.off,
      message: '摄像头未开启',
    );
  }

  final CallCameraStatus status;
  final String message;
  final CallCameraSession? session;

  bool get isStarting => status == CallCameraStatus.initializing;
  bool get isLive => status == CallCameraStatus.live;
  bool get hasRealPreview =>
      isLive &&
      session?.isRealCamera == true &&
      session?.controller != null &&
      session!.controller!.value.isInitialized;
}

abstract class CallCameraAdapter {
  Future<CallCameraSession> start();

  Future<void> stop(CallCameraSession? session);
}

class RealCallCameraAdapter implements CallCameraAdapter {
  const RealCallCameraAdapter();

  @override
  Future<CallCameraSession> start() async {
    final permission = await _ensureCameraPermission();
    if (!permission) {
      throw const CallCameraPermissionDeniedException();
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw const CallCameraUnavailableException();
    }

    final camera = cameras.firstWhere(
      (candidate) => candidate.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();

    return CallCameraSession(
      isRealCamera: true,
      controller: controller,
      cameraName: camera.name.isEmpty ? '本机摄像头' : camera.name,
    );
  }

  @override
  Future<void> stop(CallCameraSession? session) async {
    await session?.controller?.dispose();
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }

    status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }
}

class CallCameraPermissionDeniedException implements Exception {
  const CallCameraPermissionDeniedException();
}

class CallCameraUnavailableException implements Exception {
  const CallCameraUnavailableException();
}

final callCameraAdapterProvider = Provider<CallCameraAdapter>(
  (ref) => const RealCallCameraAdapter(),
);

final callCameraProvider =
    AutoDisposeNotifierProvider<CallCameraController, CallCameraState>(
      CallCameraController.new,
    );

class CallCameraController extends AutoDisposeNotifier<CallCameraState> {
  @override
  CallCameraState build() {
    ref.onDispose(() {
      unawaited(_disposeCurrentSession());
    });
    return CallCameraState.off();
  }

  Future<CallCameraState> startPreview() async {
    if (state.status == CallCameraStatus.initializing || state.isLive) {
      return state;
    }

    state = const CallCameraState(
      status: CallCameraStatus.initializing,
      message: '正在打开本机摄像头',
    );

    try {
      final session = await ref.read(callCameraAdapterProvider).start();
      state = CallCameraState(
        status: CallCameraStatus.live,
        message: '真实摄像头已开启，仅在本机预览，不上传画面。',
        session: session,
      );
    } on CallCameraPermissionDeniedException {
      state = const CallCameraState(
        status: CallCameraStatus.denied,
        message: '摄像头权限未开启，请在系统设置中允许 LinkAble 使用摄像头。',
      );
    } on CallCameraUnavailableException {
      state = const CallCameraState(
        status: CallCameraStatus.unavailable,
        message: '没有检测到可用摄像头，已保留语音通话和 Demo 说明。',
      );
    } on CameraException catch (error, stackTrace) {
      AppLogger.warning(
        'Call camera failed with CameraException: ${error.code}',
      );
      if (_isPermissionError(error)) {
        state = const CallCameraState(
          status: CallCameraStatus.denied,
          message: '摄像头权限未开启，请在系统设置中允许 LinkAble 使用摄像头。',
        );
      } else {
        AppLogger.error(
          'Call camera initialization failed.',
          error,
          stackTrace,
        );
        state = CallCameraState(
          status: CallCameraStatus.error,
          message: '摄像头打开失败：${error.description ?? error.code}',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('Call camera initialization failed.', error, stackTrace);
      state = const CallCameraState(
        status: CallCameraStatus.error,
        message: '摄像头打开失败，已保留语音通话和 Demo 说明。',
      );
    }

    return state;
  }

  Future<void> stopPreview() async {
    await _disposeCurrentSession();
    state = CallCameraState.off();
  }

  Future<void> _disposeCurrentSession() async {
    final session = state.session;
    if (session == null) {
      return;
    }
    try {
      await ref.read(callCameraAdapterProvider).stop(session);
    } catch (error, stackTrace) {
      AppLogger.error('Call camera dispose failed.', error, stackTrace);
    }
  }

  bool _isPermissionError(CameraException error) {
    final code = error.code.toLowerCase();
    return code.contains('access') ||
        code.contains('denied') ||
        code.contains('permission');
  }
}
