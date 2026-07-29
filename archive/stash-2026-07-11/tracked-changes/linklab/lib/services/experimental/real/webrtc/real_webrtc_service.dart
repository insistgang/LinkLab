import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/utils/logger.dart';
import '../../../../models/call_models.dart';
import '../../../webrtc/webrtc_config.dart';

/// 真实WebRTC服务
/// 管理PeerConnection、媒体流和通话状态
/// AGENTS.md §4.2：竞赛版仅走 Demo 主线，当前文件只保留为实验性真实链路实现。
class RealWebRTCService {
  static final RealWebRTCService _instance = RealWebRTCService._internal();
  factory RealWebRTCService() => _instance;
  RealWebRTCService._internal();

  // ==================== 核心组件 ====================

  /// PeerConnection实例
  RTCPeerConnection? _peerConnection;

  /// 本地媒体流
  MediaStream? _localStream;

  /// 远程媒体流
  MediaStream? _remoteStream;

  /// 当前通话信息
  CallInfo? _currentCall;

  // ==================== 状态流控制器 ====================

  /// 通话状态流
  final _callStateController = StreamController<CallState>.broadcast();

  /// 远程媒体流流
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();

  /// WebRTC事件流
  final _eventController = StreamController<WebRTCEvent>.broadcast();

  /// 网络质量流
  final _networkQualityController =
      StreamController<NetworkQuality>.broadcast();

  /// 通话统计信息流
  final _statsController = StreamController<CallStats>.broadcast();

  // ==================== 计时器和任务 ====================

  /// 通话时长计时器
  Timer? _durationTimer;

  /// 统计信息收集计时器
  Timer? _statsTimer;

  /// ICE收集超时计时器
  Timer? _iceGatheringTimer;

  /// 连接超时计时器
  Timer? _connectionTimeoutTimer;

  /// 重连尝试次数
  int _reconnectAttempts = 0;

  /// 通话开始时间
  DateTime? _callStartTime;

  // ==================== 状态标志 ====================

  /// 是否正在初始化
  bool _isInitializing = false;

  /// 是否已连接
  bool _isConnected = false;

  /// 是否已断开
  bool _isDisposed = false;

  // ==================== 信令回调 ====================

  /// 发送Offer的回调
  Function(String sdp, String type)? onOfferCreated;

  /// 发送Answer的回调
  Function(String sdp, String type)? onAnswerCreated;

  /// 发送ICE候选的回调
  Function(String candidate, String? sdpMid, int? sdpMLineIndex)?
  onIceCandidate;

  /// 通话结束回调
  Function(CallEndReason reason)? onCallEnded;

  // ==================== Getters ====================

  /// 通话状态流
  Stream<CallState> get callStateStream => _callStateController.stream;

  /// 远程媒体流流
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;

  /// WebRTC事件流
  Stream<WebRTCEvent> get eventStream => _eventController.stream;

  /// 网络质量流
  Stream<NetworkQuality> get networkQualityStream =>
      _networkQualityController.stream;

  /// 通话统计信息流
  Stream<CallStats> get statsStream => _statsController.stream;

  /// 当前通话信息
  CallInfo? get currentCall => _currentCall;

  /// 本地媒体流
  MediaStream? get localStream => _localStream;

  /// 远程媒体流
  MediaStream? get remoteStream => _remoteStream;

  /// 是否正在通话中
  bool get isInCall => _currentCall != null && _isConnected;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 通话时长
  Duration get callDuration {
    if (_callStartTime == null) return Duration.zero;
    return DateTime.now().difference(_callStartTime!);
  }

  // ==================== 初始化方法 ====================

  /// 检查并请求权限
  Future<bool> checkPermissions() async {
    try {
      // 检查麦克风权限
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      // 检查录音权限（Android）
      if (await Permission.storage.isRestricted == false) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }

      return microphoneStatus.isGranted;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 权限检查失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '权限检查失败: $error');
      return false;
    }
  }

  /// 初始化通话（作为求助者）
  Future<CallInfo> initializeCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
  }) async {
    if (_isInitializing) {
      throw Exception('正在初始化通话，请稍候');
    }

    _isInitializing = true;

    try {
      // 检查权限
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('需要麦克风权限才能进行通话');
      }

      // 生成房间ID
      final roomId = _generateRoomId();

      // 创建通话信息
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

      // 初始化媒体
      await _initializeMedia();

      // 创建PeerConnection
      await _createPeerConnection();

      _updateCallState(CallState.connecting);
      _emitEvent(WebRTCEventType.connecting);

      return _currentCall!;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化求助者通话失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '初始化通话失败: $error');
      await _cleanup();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 初始化通话（作为志愿者）
  Future<CallInfo> initializeCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
  }) async {
    if (_isInitializing) {
      throw Exception('正在初始化通话，请稍候');
    }

    _isInitializing = true;

    try {
      // 检查权限
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('需要麦克风权限才能进行通话');
      }

      // 创建通话信息
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

      // 初始化媒体
      await _initializeMedia();

      // 创建PeerConnection
      await _createPeerConnection();

      _updateCallState(CallState.connecting);
      _emitEvent(WebRTCEventType.connecting);

      return _currentCall!;
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化志愿者通话失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '初始化通话失败: $error');
      await _cleanup();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 初始化本地媒体流
  Future<void> _initializeMedia() async {
    try {
      _emitEvent(WebRTCEventType.localStreamAdded);

      // 获取用户媒体
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRTCConfig.audioConstraints,
      );

      // 配置音频轨道
      for (final track in _localStream!.getAudioTracks()) {
        // 启用回声消除和噪声抑制
        await track.applyConstraints({
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 初始化媒体流失败', error, stackTrace);
      if (error.toString().contains('NotAllowedError')) {
        _emitEvent(WebRTCEventType.permissionDenied, error: '用户拒绝了麦克风权限');
        throw Exception('需要麦克风权限才能进行通话');
      } else if (error.toString().contains('NotFoundError')) {
        _emitEvent(WebRTCEventType.deviceNotFound, error: '未找到麦克风设备');
        throw Exception('未找到麦克风设备');
      }
      throw Exception('无法获取麦克风: $error');
    }
  }

  /// 创建PeerConnection
  Future<void> _createPeerConnection() async {
    try {
      // 创建PeerConnection
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

      // 监听远程流
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream);
          _emitEvent(WebRTCEventType.remoteStreamAdded, data: _remoteStream);
        }
      };

      // 监听连接状态变化
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        _handleConnectionStateChange(state);
      };

      // 监听ICE连接状态
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        AppLogger.verbose('[WebRTC] ICE Connection State: $state');
      };

      // 监听ICE收集状态
      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        AppLogger.verbose('[WebRTC] ICE Gathering State: $state');
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          _emitEvent(WebRTCEventType.iceGatheringComplete);
          _iceGatheringTimer?.cancel();
        }
      };

      // 监听ICE候选
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

      // 监听数据通道（用于传输元数据）
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        AppLogger.verbose('[WebRTC] Data channel received: ${channel.label}');
      };
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 创建 PeerConnection 失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '创建PeerConnection失败: $error');
      throw Exception('创建PeerConnection失败: $error');
    }
  }

  // ==================== 信令处理方法 ====================

  /// 创建并发送Offer
  Future<void> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      // 创建Offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      // 设置本地描述
      await _peerConnection!.setLocalDescription(offer);

      _emitEvent(WebRTCEventType.offerCreated, data: offer);

      // 调用回调发送Offer
      if (offer.sdp != null && offer.type != null) {
        onOfferCreated?.call(offer.sdp!, offer.type!);
      }

      // 启动ICE收集超时计时器
      _startIceGatheringTimer();

      // 启动连接超时计时器
      _startConnectionTimeoutTimer();

      _updateCallState(CallState.ringing);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 创建 Offer 失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '创建Offer失败: $error');
      throw Exception('创建Offer失败: $error');
    }
  }

  /// 处理收到的Offer
  Future<void> handleOffer(String sdp, String type) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      // 设置远程描述（Offer）
      final offer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(offer);

      // 创建Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });

      // 设置本地描述
      await _peerConnection!.setLocalDescription(answer);

      _emitEvent(WebRTCEventType.answerCreated, data: answer);

      // 调用回调发送Answer
      if (answer.sdp != null && answer.type != null) {
        onAnswerCreated?.call(answer.sdp!, answer.type!);
      }

      // 启动ICE收集超时计时器
      _startIceGatheringTimer();

      _updateCallState(CallState.ringing);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 处理 Offer 失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '处理Offer失败: $error');
      throw Exception('处理Offer失败: $error');
    }
  }

  /// 处理收到的Answer
  Future<void> handleAnswer(String sdp, String type) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection未初始化');
    }

    try {
      final answer = RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(answer);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 处理 Answer 失败', error, stackTrace);
      _emitEvent(WebRTCEventType.error, error: '处理Answer失败: $error');
      throw Exception('处理Answer失败: $error');
    }
  }

  /// 添加ICE候选
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
      AppLogger.error('[WebRTC] 添加ICE候选失败', error, stackTrace);
      // ICE候选添加失败通常不会导致通话失败，可以继续尝试其他候选
    }
  }

  // ==================== 状态处理方法 ====================

  /// 处理连接状态变化
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

  /// 处理连接失败
  void _handleConnectionFailed() {
    _stopDurationTimer();
    _stopStatsTimer();

    // 通知上层连接失败
    onCallEnded?.call(CallEndReason.networkError);
  }

  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= WebRTCConfig.maxReconnectAttempts) {
      _emitEvent(WebRTCEventType.error, error: '重连次数已达上限');
      await endCall(CallEndReason.networkError);
      return;
    }

    _reconnectAttempts++;
    AppLogger.warning(
      '[WebRTC] 尝试重连 ($_reconnectAttempts/${WebRTCConfig.maxReconnectAttempts})',
    );

    await Future.delayed(
      Duration(milliseconds: WebRTCConfig.reconnectInterval),
    );

    // 这里可以实现重连逻辑
    // 例如：重新创建PeerConnection或重新发送Offer
  }

  // ==================== 通话控制方法 ====================

  /// 开始通话（建立连接后调用）
  Future<void> startCall(String roomId) async {
    // 此方法用于信令层通知可以开始通话
    // 实际连接在PeerConnection状态变为connected时自动处理
    AppLogger.info('[WebRTC] 通话开始: roomId=$roomId');
  }

  /// 静音/取消静音
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

  /// 设置静音状态
  Future<void> setMute(bool muted) async {
    if (_localStream == null) return;

    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !muted;
      _currentCall?.isMuted = muted;
    }
  }

  /// 切换扬声器
  Future<bool> toggleSpeaker() async {
    _currentCall?.isSpeakerOn = !(_currentCall?.isSpeakerOn ?? true);
    // 实际切换扬声器需要平台特定实现
    // 可以使用 flutter_audio_manager 或类似插件
    return _currentCall?.isSpeakerOn ?? true;
  }

  /// 设置扬声器状态
  Future<void> setSpeaker(bool enabled) async {
    _currentCall?.isSpeakerOn = enabled;
    // 实际切换扬声器需要平台特定实现
  }

  /// 结束通话
  Future<void> endCall(CallEndReason reason) async {
    AppLogger.info('[WebRTC] 结束通话: reason=$reason');

    // 通知上层通话结束
    onCallEnded?.call(reason);

    await _cleanup();
    _updateCallState(CallState.ended);
  }

  /// 清理资源
  Future<void> _cleanup() async {
    _isConnected = false;

    // 停止计时器
    _stopDurationTimer();
    _stopStatsTimer();
    _iceGatheringTimer?.cancel();
    _connectionTimeoutTimer?.cancel();

    // 停止本地流
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    // 停止远程流
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.dispose();
    _remoteStream = null;

    // 关闭PeerConnection
    await _peerConnection?.close();
    _peerConnection = null;

    // 释放屏幕常亮
    await WakelockPlus.disable();

    // 清空当前通话
    _currentCall = null;
    _callStartTime = null;
    _reconnectAttempts = 0;

    _remoteStreamController.add(null);
  }

  /// 释放所有资源
  void dispose() {
    _cleanup();
    _isDisposed = true;
    _callStateController.close();
    _remoteStreamController.close();
    _eventController.close();
    _networkQualityController.close();
    _statsController.close();
  }

  // ==================== 计时器方法 ====================

  /// 启动通话时长计时器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 计时器触发时，UI层可以通过callDuration获取当前时长
    });
  }

  /// 停止通话时长计时器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 启动ICE收集超时计时器
  void _startIceGatheringTimer() {
    _iceGatheringTimer?.cancel();
    _iceGatheringTimer = Timer(
      Duration(milliseconds: WebRTCConfig.iceGatheringTimeout),
      () {
        AppLogger.warning('[WebRTC] ICE收集超时');
        // ICE收集超时，但通常可以继续尝试连接
      },
    );
  }

  /// 启动连接超时计时器
  void _startConnectionTimeoutTimer() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(
      Duration(milliseconds: WebRTCConfig.connectionTimeout),
      () {
        if (!_isConnected) {
          AppLogger.warning('[WebRTC] 连接超时');
          _emitEvent(WebRTCEventType.error, error: '连接超时');
          endCall(CallEndReason.timeout);
        }
      },
    );
  }

  /// 启动统计信息收集计时器
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectStats();
    });
  }

  /// 停止统计信息收集计时器
  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  // ==================== 统计信息方法 ====================

  /// 收集通话统计信息
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

        // 收包统计
        if (values['bytesReceived'] != null) {
          bytesReceived += (values['bytesReceived'] as num).toInt();
        }

        // 发包统计
        if (values['bytesSent'] != null) {
          bytesSent += (values['bytesSent'] as num).toInt();
        }

        // 丢包统计
        if (values['packetsLost'] != null) {
          packetsLost += (values['packetsLost'] as num).toInt();
        }

        // 接收包数
        if (values['packetsReceived'] != null) {
          packetsReceived += (values['packetsReceived'] as num).toInt();
        }

        // 抖动
        if (values['jitter'] != null) {
          jitter = (values['jitter'] as num).toDouble();
        }

        // 往返时间
        if (values['currentRoundTripTime'] != null) {
          rtt = ((values['currentRoundTripTime'] as num) * 1000).toInt();
        }
      }

      // 计算丢包率
      final totalPackets = packetsReceived + packetsLost;
      final packetLossRate = totalPackets > 0
          ? packetsLost / totalPackets
          : 0.0;

      // 计算比特率（简化计算）
      final duration = callDuration.inSeconds;
      final averageBitrate = duration > 0
          ? ((bytesReceived + bytesSent) * 8 / duration / 1000).toDouble()
          : 0.0;

      // 评估网络质量
      final quality = NetworkQualityEvaluator.evaluateByRTT(rtt);
      _networkQualityController.add(quality);

      // 发送统计信息
      final callStats = CallStats(
        duration: callDuration,
        bytesReceived: bytesReceived,
        bytesSent: bytesSent,
        averageBitrate: averageBitrate,
        packetLoss: (packetLossRate * 100).toInt(),
      );

      _statsController.add(callStats);
    } catch (error, stackTrace) {
      AppLogger.error('[WebRTC] 收集统计信息失败', error, stackTrace);
    }
  }

  /// 获取当前统计信息
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
      AppLogger.error('[WebRTC] 获取当前统计信息失败', error, stackTrace);
      return null;
    }
  }

  // ==================== 辅助方法 ====================

  /// 更新通话状态
  void _updateCallState(CallState state) {
    _currentCall?.state = state;
    _callStateController.add(state);
  }

  /// 发送事件
  void _emitEvent(WebRTCEventType type, {dynamic data, String? error}) {
    if (!_isDisposed) {
      _eventController.add(WebRTCEvent(type: type, data: data, error: error));
    }
  }

  /// 生成房间ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 获取格式化的通话时长
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
