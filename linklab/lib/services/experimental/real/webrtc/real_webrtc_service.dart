import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/utils/logger.dart';
import '../../../../models/call_models.dart';
import '../../../webrtc/webrtc_config.dart';

/// 真實WebRTC服務
/// 管理PeerConnection、媒體流和通話狀態
/// AGENTS.md §4.2：競賽版僅走 Demo 主線，當前文件只保留爲實驗性真實鏈路實現。
class RealWebRTCService {
  static final RealWebRTCService _instance = RealWebRTCService._internal();
  factory RealWebRTCService() => _instance;
  RealWebRTCService._internal();

  // ==================== 核心組件 ====================

  /// PeerConnection實例
  RTCPeerConnection? _peerConnection;

  /// 本地媒體流
  MediaStream? _localStream;

  /// 遠程媒體流
  MediaStream? _remoteStream;

  /// 當前通話信息
  CallInfo? _currentCall;

  // ==================== 狀態流控制器 ====================

  /// 通話狀態流
  final _callStateController = StreamController<CallState>.broadcast();

  /// 遠程媒體流流
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();

  /// WebRTC事件流
  final _eventController = StreamController<WebRTCEvent>.broadcast();

  /// 網絡質量流
  final _networkQualityController =
      StreamController<NetworkQuality>.broadcast();

  /// 通話統計信息流
  final _statsController = StreamController<CallStats>.broadcast();

  // ==================== 計時器和任務 ====================

  /// 通話時長計時器
  Timer? _durationTimer;

  /// 統計信息收集計時器
  Timer? _statsTimer;

  /// ICE收集超時計時器
  Timer? _iceGatheringTimer;

  /// 連接超時計時器
  Timer? _connectionTimeoutTimer;

  /// 重連嘗試次數
  int _reconnectAttempts = 0;

  /// 通話開始時間
  DateTime? _callStartTime;

  // ==================== 狀態標誌 ====================

  /// 是否正在初始化
  bool _isInitializing = false;

  /// 是否已連接
  bool _isConnected = false;

  /// 是否已斷開
  bool _isDisposed = false;

  // ==================== 信令回調 ====================

  /// 發送Offer的回調
  Function(String sdp, String type)? onOfferCreated;

  /// 發送Answer的回調
  Function(String sdp, String type)? onAnswerCreated;

  /// 發送ICE候選的回調
  Function(String candidate, String? sdpMid, int? sdpMLineIndex)?
  onIceCandidate;

  /// 通話結束回調
  Function(CallEndReason reason)? onCallEnded;

  // ==================== Getters ====================

  /// 通話狀態流
  Stream<CallState> get callStateStream => _callStateController.stream;

  /// 遠程媒體流流
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;

  /// WebRTC事件流
  Stream<WebRTCEvent> get eventStream => _eventController.stream;

  /// 網絡質量流
  Stream<NetworkQuality> get networkQualityStream =>
      _networkQualityController.stream;

  /// 通話統計信息流
  Stream<CallStats> get statsStream => _statsController.stream;

  /// 當前通話信息
  CallInfo? get currentCall => _currentCall;

  /// 本地媒體流
  MediaStream? get localStream => _localStream;

  /// 遠程媒體流
  MediaStream? get remoteStream => _remoteStream;

  /// 是否正在通話中
  bool get isInCall => _currentCall != null && _isConnected;

  /// 是否已連接
  bool get isConnected => _isConnected;

  /// 通話時長
  Duration get callDuration {
    if (_callStartTime == null) return Duration.zero;
    return DateTime.now().difference(_callStartTime!);
  }

  // ==================== 初始化方法 ====================

  /// 檢查並請求權限
  Future<bool> checkPermissions() async {
    try {
      // 檢查麥克風權限
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      // 檢查錄音權限（Android）
      if (await Permission.storage.isRestricted == false) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }

      return microphoneStatus.isGranted;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 權限檢查失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '權限檢查失敗: $error');
      return false;
    }
  }

  /// 初始化通話（作爲求助者）
  Future<CallInfo> initializeCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
  }) async {
    if (_isInitializing) {
      throw Exception('正在初始化通話，請稍候');
    }

    _isInitializing = true;

    try {
      // 檢查權限
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('需要麥克風權限才能進行通話');
      }

      // 生成房間ID
      final roomId = _generateRoomId();

      // 創建通話信息
      _currentCall = CallInfo(
        callId: helpRequestId,
        roomId: roomId,
        seekerId: seekerId,
        volunteerId: volunteerId,
        myRole: CallRole.seeker,
        state: CallState.connecting,
      );

      // 保持屏幕常亮
      await WakelockPlus.enable();

      // 初始化媒體
      await _initializeMedia();

      // 創建PeerConnection
      await _createPeerConnection();

      _updateCallState(CallState.connecting);
      _emitEvent(WebRTCEventType.connecting);

      return _currentCall!;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化求助者通話失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '初始化通話失敗: $error');
      await _cleanup();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 初始化通話（作爲志願者）
  Future<CallInfo> initializeCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
  }) async {
    if (_isInitializing) {
      throw Exception('正在初始化通話，請稍候');
    }

    _isInitializing = true;

    try {
      // 檢查權限
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('需要麥克風權限才能進行通話');
      }

      // 創建通話信息
      _currentCall = CallInfo(
        callId: helpRequestId,
        roomId: roomId,
        seekerId: seekerId,
        volunteerId: volunteerId,
        myRole: CallRole.volunteer,
        state: CallState.connecting,
      );

      // 保持屏幕常亮
      await WakelockPlus.enable();

      // 初始化媒體
      await _initializeMedia();

      // 創建PeerConnection
      await _createPeerConnection();

      _updateCallState(CallState.connecting);
      _emitEvent(WebRTCEventType.connecting);

      return _currentCall!;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化志願者通話失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '初始化通話失敗: $error');
      await _cleanup();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 初始化本地媒體流
  Future<void> _initializeMedia() async {
    try {
      _emitEvent(WebRTCEventType.localStreamAdded);

      // 獲取用戶媒體
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRTCConfig.audioConstraints,
      );

      // 配置音頻軌道
      for (final track in _localStream!.getAudioTracks()) {
        // 啓用回聲消除和噪聲抑制
        await track.applyConstraints({
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化媒體流失敗', error, stackTrace);
      if (error.toString().contains('NotAllowedError')) {
        _emitEvent(WebRTCEventType.permissionDenied, error: '用戶拒絕了麥克風權限');
        throw Exception('需要麥克風權限才能進行通話');
      } else if (error.toString().contains('NotFoundError')) {
        _emitEvent(WebRTCEventType.deviceNotFound, error: '未找到麥克風設備');
        throw Exception('未找到麥克風設備');
      }
      throw Exception('無法獲取麥克風: $error');
    }
  }

  /// 創建PeerConnection
  Future<void> _createPeerConnection() async {
    try {
      // 創建PeerConnection
      _peerConnection = await createPeerConnection(
        WebRTCConfig.rtcConfiguration,
        WebRTCConfig.sdpConstraints,
      );

      // 添加本地流到PeerConnection
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localStream!);
        }
      }

      // 監聽遠程流
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream);
          _emitEvent(WebRTCEventType.remoteStreamAdded, data: _remoteStream);
        }
      };

      // 監聽連接狀態變化
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        _handleConnectionStateChange(state);
      };

      // 監聽ICE連接狀態
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        AppLogger.verbose('[WebRTC] ICE Connection State: $state');
      };

      // 監聽ICE收集狀態
      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        AppLogger.verbose('[WebRTC] ICE Gathering State: $state');
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          _emitEvent(WebRTCEventType.iceGatheringComplete);
          _iceGatheringTimer?.cancel();
        }
      };

      // 監聽ICE候選
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _emitEvent(WebRTCEventType.iceCandidateGenerated, data: candidate);
          onIceCandidate?.call(
            candidate.candidate!,
            candidate.sdpMid,
            candidate.sdpMLineIndex,
          );
        }
      };

      // 監聽數據通道（用於傳輸元數據）
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        AppLogger.verbose('[WebRTC] Data channel received: ${channel.label}');
      };
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 創建 PeerConnection 失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '創建PeerConnection失敗: $error');
      throw Exception('創建PeerConnection失敗: $error');
    }
  }

  // ==================== 信令處理方法 ====================

  /// 創建併發送Offer
  Future<void> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      // 創建Offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      // 設置本地描述
      await _peerConnection!.setLocalDescription(offer);

      _emitEvent(WebRTCEventType.offerCreated, data: offer);

      // 調用回調發送Offer
      if (offer.sdp != null && offer.type != null) {
        onOfferCreated?.call(offer.sdp!, offer.type!);
      }

      // 啓動ICE收集超時計時器
      _startIceGatheringTimer();

      // 啓動連接超時計時器
      _startConnectionTimeoutTimer();

      _updateCallState(CallState.ringing);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 創建 Offer 失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '創建Offer失敗: $error');
      throw Exception('創建Offer失敗: $error');
    }
  }

  /// 處理收到的Offer
  Future<void> handleOffer(String sdp, String type) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      // 設置遠程描述（Offer）
      final offer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(offer);

      // 創建Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      // 設置本地描述
      await _peerConnection!.setLocalDescription(answer);

      _emitEvent(WebRTCEventType.answerCreated, data: answer);

      // 調用回調發送Answer
      if (answer.sdp != null && answer.type != null) {
        onAnswerCreated?.call(answer.sdp!, answer.type!);
      }

      // 啓動ICE收集超時計時器
      _startIceGatheringTimer();

      _updateCallState(CallState.ringing);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 處理 Offer 失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '處理Offer失敗: $error');
      throw Exception('處理Offer失敗: $error');
    }
  }

  /// 處理收到的Answer
  Future<void> handleAnswer(String sdp, String type) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      final answer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(answer);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 處理 Answer 失敗', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '處理Answer失敗: $error');
      throw Exception('處理Answer失敗: $error');
    }
  }

  /// 添加ICE候選
  Future<void> addIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
      await _peerConnection!.addCandidate(iceCandidate);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 添加ICE候選失敗', error, stackTrace);
      // ICE候選添加失敗通常不會導致通話失敗，可以繼續嘗試其他候選
    }
  }

  // ==================== 狀態處理方法 ====================

  /// 處理連接狀態變化
  void _handleConnectionStateChange(RTCPeerConnectionState state) {
    AppLogger.info('[WebRTC] Connection State: $state');

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        _updateCallState(CallState.connecting);
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _isConnected = true;
        _reconnectAttempts = 0;
        _callStartTime = DateTime.now();
        _updateCallState(CallState.connected);
        _emitEvent(WebRTCEventType.connected);
        _startDurationTimer();
        _startStatsTimer();
        _connectionTimeoutTimer?.cancel();
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _isConnected = false;
        _updateCallState(CallState.reconnecting);
        _emitEvent(WebRTCEventType.disconnected);
        _attemptReconnect();
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _isConnected = false;
        _updateCallState(CallState.failed);
        _emitEvent(WebRTCEventType.failed);
        _handleConnectionFailed();
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _isConnected = false;
        _updateCallState(CallState.ended);
        _emitEvent(WebRTCEventType.closed);
        break;

      default:
        break;
    }
  }

  /// 處理連接失敗
  void _handleConnectionFailed() {
    _stopDurationTimer();
    _stopStatsTimer();

    // 通知上層連接失敗
    onCallEnded?.call(CallEndReason.networkError);
  }

  /// 嘗試重連
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= WebRTCConfig.maxReconnectAttempts) {
      _emitEvent(WebRTCEventType.error, error: '重連次數已達上限');
      await endCall(CallEndReason.networkError);
      return;
    }

    _reconnectAttempts++;
    AppLogger.warning(
      '[WebRTC] 嘗試重連 ($_reconnectAttempts/${WebRTCConfig.maxReconnectAttempts})',
    );

    await Future.delayed(
      Duration(milliseconds: WebRTCConfig.reconnectInterval),
    );

    // 這裏可以實現重連邏輯
    // 例如：重新創建PeerConnection或重新發送Offer
  }

  // ==================== 通話控制方法 ====================

  /// 開始通話（建立連接後調用）
  Future<void> startCall(String roomId) async {
    // 此方法用於信令層通知可以開始通話
    // 實際連接在PeerConnection狀態變爲connected時自動處理
    AppLogger.info('[WebRTC] 通話開始: roomId=$roomId');
  }

  /// 靜音/取消靜音
  Future<bool> toggleMute() async {
    if (_localStream == null) return false;

    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      _currentCall?.isMuted = !audioTrack.enabled;
      return !audioTrack.enabled;
    }
    return false;
  }

  /// 設置靜音狀態
  Future<void> setMute(bool muted) async {
    if (_localStream == null) return;

    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !muted;
      _currentCall?.isMuted = muted;
    }
  }

  /// 切換揚聲器
  Future<bool> toggleSpeaker() async {
    _currentCall?.isSpeakerOn = !(_currentCall?.isSpeakerOn ?? true);
    // 實際切換揚聲器需要平臺特定實現
    // 可以使用 flutter_audio_manager 或類似插件
    return _currentCall?.isSpeakerOn ?? true;
  }

  /// 設置揚聲器狀態
  Future<void> setSpeaker(bool enabled) async {
    _currentCall?.isSpeakerOn = enabled;
    // 實際切換揚聲器需要平臺特定實現
  }

  /// 結束通話
  Future<void> endCall(CallEndReason reason) async {
    AppLogger.info('[WebRTC] 結束通話: reason=$reason');

    // 通知上層通話結束
    onCallEnded?.call(reason);

    await _cleanup();
    _updateCallState(CallState.ended);
  }

  /// 清理資源
  Future<void> _cleanup() async {
    _isConnected = false;

    // 停止計時器
    _stopDurationTimer();
    _stopStatsTimer();
    _iceGatheringTimer?.cancel();
    _connectionTimeoutTimer?.cancel();

    // 停止本地流
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    // 停止遠程流
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.dispose();
    _remoteStream = null;

    // 關閉PeerConnection
    await _peerConnection?.close();
    _peerConnection = null;

    // 釋放屏幕常亮
    await WakelockPlus.disable();

    // 清空當前通話
    _currentCall = null;
    _callStartTime = null;
    _reconnectAttempts = 0;

    _remoteStreamController.add(null);
  }

  /// 釋放所有資源
  void dispose() {
    _cleanup();
    _isDisposed = true;
    _callStateController.close();
    _remoteStreamController.close();
    _eventController.close();
    _networkQualityController.close();
    _statsController.close();
  }

  // ==================== 計時器方法 ====================

  /// 啓動通話時長計時器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 計時器觸發時，UI層可以通過callDuration獲取當前時長
    });
  }

  /// 停止通話時長計時器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 啓動ICE收集超時計時器
  void _startIceGatheringTimer() {
    _iceGatheringTimer?.cancel();
    _iceGatheringTimer = Timer(
      Duration(milliseconds: WebRTCConfig.iceGatheringTimeout),
      () {
        AppLogger.warning('[WebRTC] ICE收集超時');
        // ICE收集超時，但通常可以繼續嘗試連接
      },
    );
  }

  /// 啓動連接超時計時器
  void _startConnectionTimeoutTimer() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(
      Duration(milliseconds: WebRTCConfig.connectionTimeout),
      () {
        if (!_isConnected) {
          AppLogger.warning('[WebRTC] 連接超時');
          _emitEvent(WebRTCEventType.error, error: '連接超時');
          endCall(CallEndReason.timeout);
        }
      },
    );
  }

  /// 啓動統計信息收集計時器
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectStats();
    });
  }

  /// 停止統計信息收集計時器
  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  // ==================== 統計信息方法 ====================

  /// 收集通話統計信息
  Future<void> _collectStats() async {
    if (_peerConnection == null || !_isConnected) return;

    try {
      final stats = await _peerConnection!.getStats();

      int bytesReceived = 0;
      int bytesSent = 0;
      int packetsLost = 0;
      int packetsReceived = 0;
      double? jitter;
      int? rtt;

      for (final report in stats) {
        final values = report.values;

        // 收包統計
        if (values['bytesReceived'] != null) {
          bytesReceived += (values['bytesReceived'] as num).toInt();
        }

        // 發包統計
        if (values['bytesSent'] != null) {
          bytesSent += (values['bytesSent'] as num).toInt();
        }

        // 丟包統計
        if (values['packetsLost'] != null) {
          packetsLost += (values['packetsLost'] as num).toInt();
        }

        // 接收包數
        if (values['packetsReceived'] != null) {
          packetsReceived += (values['packetsReceived'] as num).toInt();
        }

        // 抖動
        if (values['jitter'] != null) {
          jitter = (values['jitter'] as num).toDouble();
        }

        // 往返時間
        if (values['currentRoundTripTime'] != null) {
          rtt = ((values['currentRoundTripTime'] as num) * 1000).toInt();
        }
      }

      // 計算丟包率
      final totalPackets = packetsReceived + packetsLost;
      final packetLossRate = totalPackets > 0
          ? packetsLost / totalPackets
          : 0.0;

      // 計算比特率（簡化計算）
      final duration = callDuration.inSeconds;
      final averageBitrate = duration > 0
          ? ((bytesReceived + bytesSent) * 8 / duration / 1000).toDouble()
          : 0.0;

      // 評估網絡質量
      final quality = NetworkQualityEvaluator.evaluateByRTT(rtt);
      _networkQualityController.add(quality);

      // 發送統計信息
      final callStats = CallStats(
        duration: callDuration,
        bytesReceived: bytesReceived,
        bytesSent: bytesSent,
        averageBitrate: averageBitrate,
        packetLoss: (packetLossRate * 100).toInt(),
      );

      _statsController.add(callStats);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 收集統計信息失敗', error, stackTrace);
    }
  }

  /// 獲取當前統計信息
  Future<CallStats?> getCurrentStats() async {
    if (_peerConnection == null) return null;

    try {
      final stats = await _peerConnection!.getStats();

      int bytesReceived = 0;
      int bytesSent = 0;

      for (final report in stats) {
        final values = report.values;
        if (values['bytesReceived'] != null) {
          bytesReceived += (values['bytesReceived'] as num).toInt();
        }
        if (values['bytesSent'] != null) {
          bytesSent += (values['bytesSent'] as num).toInt();
        }
      }

      return CallStats(
        duration: callDuration,
        bytesReceived: bytesReceived,
        bytesSent: bytesSent,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 獲取當前統計信息失敗', error, stackTrace);
      return null;
    }
  }

  // ==================== 輔助方法 ====================

  /// 更新通話狀態
  void _updateCallState(CallState state) {
    _currentCall?.state = state;
    _callStateController.add(state);
  }

  /// 發送事件
  void _emitEvent(WebRTCEventType type, {dynamic data, String? error}) {
    if (!_isDisposed) {
      _eventController.add(WebRTCEvent(type: type, data: data, error: error));
    }
  }

  /// 生成房間ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 獲取格式化的通話時長
  String getFormattedDuration() {
    final duration = callDuration;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
