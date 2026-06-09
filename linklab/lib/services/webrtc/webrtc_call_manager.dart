// AGENTS.md §4.2：該管理器屬於歷史實驗性真實鏈路。
// 默認競賽版不進入此實現，真實 WebRTC 已隔離到 services/experimental/real/。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/utils/logger.dart';
import '../../models/call_models.dart';
import 'call_recording_service.dart';
import '../experimental/real/webrtc/real_webrtc_service.dart';
import 'signaling_service.dart';
import 'webrtc_config.dart';

/// 通話事件類型
enum CallManagerEventType {
  // 通話生命週期
  callInitialized,
  callConnecting,
  callConnected,
  callDisconnected,
  callEnded,
  callFailed,

  // 信令事件
  signalingConnected,
  signalingDisconnected,
  signalingError,

  // 媒體事件
  localStreamReady,
  remoteStreamReady,
  remoteStreamRemoved,

  // 錄音事件
  recordingStarted,
  recordingStopped,
  recordingError,

  // 錯誤事件
  error,
  permissionDenied,
}

/// 通話管理器事件
class CallManagerEvent {
  final CallManagerEventType type;
  final dynamic data;
  final String? error;
  final DateTime timestamp;

  CallManagerEvent({
    required this.type,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// WebRTC 通話管理器
/// 負責協調WebRTC服務、信令服務和錄音服務
class WebRTCCallManager {
  static final WebRTCCallManager _instance = WebRTCCallManager._internal();
  factory WebRTCCallManager() => _instance;
  WebRTCCallManager._internal();

  // ==================== 核心服務 ====================

  /// WebRTC服務
  final RealWebRTCService _webrtcService = RealWebRTCService();

  /// 信令服務
  final SignalingService _signalingService = SignalingService();

  /// 錄音服務
  final CallRecordingService _recordingService = CallRecordingService();

  // ==================== 狀態流控制器 ====================

  /// 通話管理器事件流
  final _eventController = StreamController<CallManagerEvent>.broadcast();

  /// 合併的通話狀態流
  final _callStateController = StreamController<CallState>.broadcast();

  // ==================== 訂閱管理 ====================

  /// WebRTC事件訂閱
  StreamSubscription<WebRTCEvent>? _webrtcEventSubscription;

  /// WebRTC狀態訂閱
  StreamSubscription<CallState>? _webrtcStateSubscription;

  /// 信令消息訂閱
  StreamSubscription<SignalingMessage>? _signalingMessageSubscription;

  /// 信令房間狀態訂閱
  StreamSubscription<RoomState>? _roomStateSubscription;

  /// 錄音狀態訂閱
  StreamSubscription<RecordingState>? _recordingStateSubscription;

  // ==================== 狀態 ====================

  /// 當前通話信息
  CallInfo? _currentCall;

  /// 是否正在通話中
  bool get isInCall => _currentCall != null;

  /// 當前通話信息
  CallInfo? get currentCall => _currentCall;

  /// 是否已連接
  bool get isConnected => _webrtcService.isConnected;

  /// 通話時長
  Duration get callDuration => _webrtcService.callDuration;

  /// 本地媒體流
  MediaStream? get localStream => _webrtcService.localStream;

  /// 遠程媒體流
  MediaStream? get remoteStream => _webrtcService.remoteStream;

  /// 是否正在錄音
  bool get isRecording => _recordingService.isRecording;

  // ==================== Getters ====================

  /// 通話管理器事件流
  Stream<CallManagerEvent> get eventStream => _eventController.stream;

  /// 通話狀態流
  Stream<CallState> get callStateStream => _callStateController.stream;

  /// WebRTC事件流
  Stream<WebRTCEvent> get webrtcEventStream => _webrtcService.eventStream;

  /// 遠程媒體流流
  Stream<MediaStream?> get remoteStreamStream => _webrtcService.remoteStreamStream;

  /// 網絡質量流
  Stream<NetworkQuality> get networkQualityStream => _webrtcService.networkQualityStream;

  /// 通話統計信息流
  Stream<CallStats> get statsStream => _webrtcService.statsStream;

  /// 錄音狀態流
  Stream<RecordingState> get recordingStateStream => _recordingService.stateStream;

  /// 錄音時長流
  Stream<Duration> get recordingDurationStream => _recordingService.durationStream;

  /// 錄音電平流
  Stream<double> get recordingLevelStream => _recordingService.levelStream;

  /// 信令消息流
  Stream<SignalingMessage> get signalingMessageStream => _signalingService.signalingMessageStream;

  /// 房間參與者流
  Stream<List<RoomParticipant>> get participantsStream => _signalingService.participantsStream;

  // ==================== 初始化方法 ====================

  /// 初始化通話管理器
  Future<void> initialize() async {
    // 初始化錄音服務
    await _recordingService.initialize();

    // 設置WebRTC回調
    _setupWebRTCCallbacks();

    // 訂閱WebRTC事件
    _webrtcEventSubscription = _webrtcService.eventStream.listen(_handleWebRTCEvent);

    // 訂閱WebRTC狀態
    _webrtcStateSubscription = _webrtcService.callStateStream.listen(_handleCallStateChange);

    // 訂閱信令消息
    _signalingMessageSubscription = _signalingService.signalingMessageStream.listen(_handleSignalingMessage);

    // 訂閱房間狀態
    _roomStateSubscription = _signalingService.roomStateStream.listen(_handleRoomStateChange);

    // 訂閱錄音狀態
    _recordingStateSubscription = _recordingService.stateStream.listen(_handleRecordingStateChange);

    AppLogger.info('[CallManager] 通話管理器已初始化');
  }

  /// 設置WebRTC回調
  void _setupWebRTCCallbacks() {
    // Offer創建回調
    _webrtcService.onOfferCreated = (sdp, type) async {
      if (_currentCall != null) {
        await _signalingService.sendOffer(_currentCall!.roomId, sdp, type);
      }
    };

    // Answer創建回調
    _webrtcService.onAnswerCreated = (sdp, type) async {
      if (_currentCall != null) {
        await _signalingService.sendAnswer(_currentCall!.roomId, sdp, type);
      }
    };

    // ICE候選回調
    _webrtcService.onIceCandidate = (candidate, sdpMid, sdpMLineIndex) async {
      if (_currentCall != null) {
        await _signalingService.sendIceCandidate(
          _currentCall!.roomId,
          candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
      }
    };

    // 通話結束回調
    _webrtcService.onCallEnded = (reason) async {
      await _handleCallEnded(reason);
    };
  }

  // ==================== 通話控制方法 ====================

  /// 作爲求助者發起通話
  Future<CallInfo> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    if (_currentCall != null) {
      throw Exception('已有進行中的通話');
    }

    try {
      _emitEvent(CallManagerEventType.callInitialized);

      // 初始化WebRTC通話
      final callInfo = await _webrtcService.initializeCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteerId,
      );

      _currentCall = callInfo;

      // 加入信令房間
      await _signalingService.joinRoom(callInfo.roomId, role: CallRole.seeker);

      // 更新房間狀態
      await _signalingService.updateRoomStatus(callInfo.roomId, 'connecting');

      // 創建併發送Offer（作爲發起方）
      await _webrtcService.createOffer();

      // 如果啓用錄音，開始錄音
      if (enableRecording) {
        await startRecording();
      }

      _emitEvent(CallManagerEventType.callConnecting, data: callInfo);

      return callInfo;
    } catch (error, stackTrace) {
      AppLogger.error('[CallManager] 發起通話失敗', error, stackTrace);
      _emitEvent(CallManagerEventType.error, error: '發起通話失敗: $error');
      await _cleanup();
      rethrow;
    }
  }

  /// 作爲志願者接聽通話
  Future<CallInfo> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    if (_currentCall != null) {
      throw Exception('已有進行中的通話');
    }

    try {
      _emitEvent(CallManagerEventType.callInitialized);

      // 初始化WebRTC通話
      final callInfo = await _webrtcService.initializeCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
      );

      _currentCall = callInfo;

      // 加入信令房間
      await _signalingService.joinRoom(roomId, role: CallRole.volunteer);

      // 更新房間狀態
      await _signalingService.updateRoomStatus(roomId, 'connected');

      // 如果啓用錄音，開始錄音
      if (enableRecording) {
        await startRecording();
      }

      _emitEvent(CallManagerEventType.callConnecting, data: callInfo);

      return callInfo;
    } catch (error, stackTrace) {
      AppLogger.error('[CallManager] 接聽通話失敗', error, stackTrace);
      _emitEvent(CallManagerEventType.error, error: '接聽通話失敗: $error');
      await _cleanup();
      rethrow;
    }
  }

  /// 結束通話
  Future<void> endCall(CallEndReason reason) async {
    if (_currentCall == null) return;

    try {
      // 發送掛斷信令
      await _signalingService.sendBye(_currentCall!.roomId, reason: reason);

      // 停止錄音
      if (_recordingService.isRecording) {
        await stopRecording();
      }

      // 結束WebRTC通話
      await _webrtcService.endCall(reason);

      // 離開信令房間
      await _signalingService.leaveRoom();

      // 更新房間狀態
      await _signalingService.updateRoomStatus(
        _currentCall!.roomId,
        reason == CallEndReason.userHangup ? 'ended' : 'failed',
      );

      await _cleanup();

      _emitEvent(CallManagerEventType.callEnded, data: reason);
    } catch (error, stackTrace) {
      AppLogger.error('[CallManager] 結束通話失敗', error, stackTrace);
      _emitEvent(CallManagerEventType.error, error: '結束通話失敗: $error');
    }
  }

  /// 靜音/取消靜音
  Future<bool> toggleMute() async {
    return await _webrtcService.toggleMute();
  }

  /// 設置靜音狀態
  Future<void> setMute(bool muted) async {
    await _webrtcService.setMute(muted);
  }

  /// 切換揚聲器
  Future<bool> toggleSpeaker() async {
    return await _webrtcService.toggleSpeaker();
  }

  /// 設置揚聲器狀態
  Future<void> setSpeaker(bool enabled) async {
    await _webrtcService.setSpeaker(enabled);
  }

  // ==================== 錄音控制方法 ====================

  /// 開始錄音
  Future<RecordingInfo?> startRecording() async {
    try {
      final info = await _recordingService.startRecording();
      if (info != null) {
        _emitEvent(CallManagerEventType.recordingStarted, data: info);
      }
      return info;
    } catch (error, stackTrace) {
      AppLogger.error('[CallManager] 開始錄音失敗', error, stackTrace);
      _emitEvent(CallManagerEventType.recordingError, error: '開始錄音失敗: $error');
      return null;
    }
  }

  /// 停止錄音
  Future<RecordingInfo?> stopRecording() async {
    try {
      final info = await _recordingService.stopRecording();
      if (info != null) {
        _emitEvent(CallManagerEventType.recordingStopped, data: info);
      }
      return info;
    } catch (error, stackTrace) {
      AppLogger.error('[CallManager] 停止錄音失敗', error, stackTrace);
      _emitEvent(CallManagerEventType.recordingError, error: '停止錄音失敗: $error');
      return null;
    }
  }

  /// 暫停錄音
  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
  }

  /// 恢復錄音
  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
  }

  // ==================== 事件處理方法 ====================

  /// 處理WebRTC事件
  void _handleWebRTCEvent(WebRTCEvent event) {
    switch (event.type) {
      case WebRTCEventType.connected:
        _emitEvent(CallManagerEventType.callConnected);
        break;
      case WebRTCEventType.disconnected:
        _emitEvent(CallManagerEventType.callDisconnected);
        break;
      case WebRTCEventType.failed:
        _emitEvent(CallManagerEventType.callFailed, error: event.error);
        break;
      case WebRTCEventType.localStreamAdded:
        _emitEvent(CallManagerEventType.localStreamReady, data: event.data);
        break;
      case WebRTCEventType.remoteStreamAdded:
        _emitEvent(CallManagerEventType.remoteStreamReady, data: event.data);
        break;
      case WebRTCEventType.permissionDenied:
        _emitEvent(CallManagerEventType.permissionDenied, error: event.error);
        break;
      case WebRTCEventType.error:
        _emitEvent(CallManagerEventType.error, error: event.error);
        break;
      default:
        break;
    }
  }

  /// 處理通話狀態變化
  void _handleCallStateChange(CallState state) {
    _currentCall?.state = state;
    _callStateController.add(state);

    switch (state) {
      case CallState.connected:
        _emitEvent(CallManagerEventType.callConnected);
        break;
      case CallState.reconnecting:
        _emitEvent(CallManagerEventType.callDisconnected);
        break;
      case CallState.failed:
        _emitEvent(CallManagerEventType.callFailed);
        break;
      case CallState.ended:
        _emitEvent(CallManagerEventType.callEnded);
        break;
      default:
        break;
    }
  }

  /// 處理信令消息
  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    switch (message.type) {
      case SignalingType.offer:
        // 收到Offer，處理並創建Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          await _webrtcService.handleOffer(sdp, type);
        }
        break;

      case SignalingType.answer:
        // 收到Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          await _webrtcService.handleAnswer(sdp, type);
        }
        break;

      case SignalingType.iceCandidate:
        // 收到ICE候選
        final candidate = message.data['candidate'] as String?;
        final sdpMid = message.data['sdp_mid'] as String?;
        final sdpMLineIndex = message.data['sdp_mline_index'] as int?;
        if (candidate != null) {
          await _webrtcService.addIceCandidate(candidate, sdpMid, sdpMLineIndex);
        }
        break;

      case SignalingType.bye:
        // 對方掛斷
        final reasonStr = message.data['reason'] as String?;
        final reason = CallEndReason.values.firstWhere(
          (r) => r.name == reasonStr,
          orElse: () => CallEndReason.remoteHangup,
        );
        await _handleRemoteHangup(reason);
        break;

      default:
        break;
    }
  }

  /// 處理房間狀態變化
  void _handleRoomStateChange(RoomState state) {
    switch (state) {
      case RoomState.joined:
        _emitEvent(CallManagerEventType.signalingConnected);
        break;
      case RoomState.left:
        _emitEvent(CallManagerEventType.signalingDisconnected);
        break;
      case RoomState.error:
        _emitEvent(CallManagerEventType.signalingError);
        break;
      default:
        break;
    }
  }

  /// 處理錄音狀態變化
  void _handleRecordingStateChange(RecordingState state) {
    // 可以在這裏添加錄音狀態變化的處理邏輯
    AppLogger.verbose('[CallManager] 錄音狀態: $state');
  }

  /// 處理通話結束
  Future<void> _handleCallEnded(CallEndReason reason) async {
    // 停止錄音
    if (_recordingService.isRecording) {
      await stopRecording();
    }

    // 離開信令房間
    await _signalingService.leaveRoom();

    await _cleanup();

    _emitEvent(CallManagerEventType.callEnded, data: reason);
  }

  /// 處理對方掛斷
  Future<void> _handleRemoteHangup(CallEndReason reason) async {
    // 停止錄音
    if (_recordingService.isRecording) {
      await stopRecording();
    }

    // 結束WebRTC通話
    await _webrtcService.endCall(reason);

    // 離開信令房間
    await _signalingService.leaveRoom();

    await _cleanup();

    _emitEvent(CallManagerEventType.callEnded, data: reason);
  }

  // ==================== 輔助方法 ====================

  /// 清理資源
  Future<void> _cleanup() async {
    _currentCall = null;
  }

  /// 發送事件
  void _emitEvent(CallManagerEventType type, {dynamic data, String? error}) {
    if (!_eventController.isClosed) {
      _eventController.add(CallManagerEvent(
        type: type,
        data: data,
        error: error,
      ));
    }
  }

  /// 獲取格式化的通話時長
  String getFormattedDuration() {
    return _webrtcService.getFormattedDuration();
  }

  /// 獲取當前統計信息
  Future<CallStats?> getCurrentStats() async {
    return await _webrtcService.getCurrentStats();
  }

  /// 釋放所有資源
  Future<void> dispose() async {
    // 取消訂閱
    await _webrtcEventSubscription?.cancel();
    await _webrtcStateSubscription?.cancel();
    await _signalingMessageSubscription?.cancel();
    await _roomStateSubscription?.cancel();
    await _recordingStateSubscription?.cancel();

    // 結束當前通話
    if (_currentCall != null) {
      await endCall(CallEndReason.userHangup);
    }

    // 釋放服務
    _webrtcService.dispose();
    _signalingService.dispose();
    await _recordingService.dispose();

    // 關閉流控制器
    await _eventController.close();
    await _callStateController.close();
  }
}
