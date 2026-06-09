import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/utils/logger.dart';
import '../../../models/call_models.dart';
import '../../webrtc/call_recording_service.dart';
import '../../webrtc/signaling_service.dart';
import '../../webrtc/webrtc_config.dart';
import 'webrtc/real_webrtc_service.dart';

/// 真實通話服務
/// 集成WebRTC、信令和錄音功能的完整通話服務
/// AGENTS.md §4.2：競賽版僅走 Demo 主線，當前文件只保留爲實驗性真實鏈路實現。
class RealCallService extends ChangeNotifier {
  static final RealCallService _instance = RealCallService._internal();
  factory RealCallService() => _instance;
  RealCallService._internal() {
    _setupWebRTCCallbacks();
    _setupSignalingCallbacks();
  }

  // ==================== 核心服務 ====================

  /// WebRTC服務
  final RealWebRTCService _webRTCService = RealWebRTCService();

  /// 信令服務
  final SignalingService _signalingService = SignalingService();

  /// 錄音服務
  final CallRecordingService _recordingService = CallRecordingService();

  // ==================== 狀態 ====================

  /// 通話狀態
  CallState _callState = CallState.idle;

  /// 當前通話信息
  CallInfo? _currentCall;

  /// 當前志願者信息
  VolunteerInfo? _currentVolunteer;

  /// 通話時長
  Duration _callDuration = Duration.zero;

  /// 網絡質量
  NetworkQuality _networkQuality = NetworkQuality.unknown;

  /// 是否正在錄音
  bool _isRecording = false;

  /// 錯誤信息
  String? _errorMessage;

  /// 遠程媒體流
  MediaStream? _remoteStream;

  /// 訂閱列表
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ==================== Getters ====================

  /// 通話狀態
  CallState get callState => _callState;

  /// 當前通話信息
  CallInfo? get currentCall => _currentCall;

  /// 當前志願者信息
  VolunteerInfo? get currentVolunteer => _currentVolunteer;

  /// 通話時長
  Duration get callDuration => _callDuration;

  /// 格式化的通話時長
  String get formattedDuration {
    final minutes = _callDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 網絡質量
  NetworkQuality get networkQuality => _networkQuality;

  /// 網絡質量描述
  String get networkQualityText =>
      NetworkQualityEvaluator.getQualityDescription(_networkQuality);

  /// 是否正在通話中
  bool get isInCall => _callState == CallState.connected;

  /// 是否正在連接中
  bool get isConnecting =>
      _callState == CallState.connecting || _callState == CallState.ringing;

  /// 是否正在錄音
  bool get isRecording => _isRecording;

  /// 是否靜音
  bool get isMuted => _currentCall?.isMuted ?? false;

  /// 是否使用揚聲器
  bool get isSpeakerOn => _currentCall?.isSpeakerOn ?? true;

  /// 錯誤信息
  String? get errorMessage => _errorMessage;

  /// 遠程媒體流
  MediaStream? get remoteStream => _remoteStream;

  /// 通話狀態流
  Stream<CallState> get callStateStream => _webRTCService.callStateStream;

  /// 通話統計信息流
  Stream<CallStats> get statsStream => _webRTCService.statsStream;

  /// 網絡質量流
  Stream<NetworkQuality> get networkQualityStream =>
      _webRTCService.networkQualityStream;

  // ==================== 回調設置 ====================

  /// 設置WebRTC回調
  void _setupWebRTCCallbacks() {
    _webRTCService.onOfferCreated = (sdp, type) {
      if (_currentCall != null) {
        _signalingService.sendOffer(_currentCall!.roomId, sdp, type);
      }
    };

    _webRTCService.onAnswerCreated = (sdp, type) {
      if (_currentCall != null) {
        _signalingService.sendAnswer(_currentCall!.roomId, sdp, type);
      }
    };

    _webRTCService.onIceCandidate = (candidate, sdpMid, sdpMLineIndex) {
      if (_currentCall != null) {
        _signalingService.sendIceCandidate(
          _currentCall!.roomId,
          candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
      }
    };

    _webRTCService.onCallEnded = (reason) {
      _handleCallEnded(reason);
    };
  }

  /// 設置信令回調
  void _setupSignalingCallbacks() {
    // 監聽信令消息
    _subscriptions.add(
      _signalingService.signalingMessageStream.listen(_handleSignalingMessage),
    );

    // 監聽房間狀態
    _subscriptions.add(
      _signalingService.roomStateStream.listen(_handleRoomStateChange),
    );

    // 監聽WebRTC狀態
    _subscriptions.add(
      _webRTCService.callStateStream.listen(_handleCallStateChange),
    );

    // 監聽遠程流
    _subscriptions.add(
      _webRTCService.remoteStreamStream.listen((stream) {
        _remoteStream = stream;
        notifyListeners();
      }),
    );

    // 監聽網絡質量
    _subscriptions.add(
      _webRTCService.networkQualityStream.listen((quality) {
        _networkQuality = quality;
        notifyListeners();
      }),
    );

    // 監聽通話時長
    _subscriptions.add(
      Stream.periodic(const Duration(seconds: 1)).listen((_) {
        if (_callState == CallState.connected) {
          _callDuration = _webRTCService.callDuration;
          notifyListeners();
        }
      }),
    );
  }

  // ==================== 通話控制方法 ====================

  /// 初始化服務
  Future<void> initialize() async {
    await _recordingService.initialize();
  }

  /// 作爲求助者發起通話
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    required VolunteerInfo volunteer,
  }) async {
    try {
      _resetState();
      _currentVolunteer = volunteer;
      _callState = CallState.connecting;
      notifyListeners();

      // 初始化WebRTC
      _currentCall = await _webRTCService.initializeCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteer.id,
      );

      // 加入信令房間
      await _signalingService.joinRoom(
        _currentCall!.roomId,
        role: CallRole.seeker,
      );

      // 等待對方加入後創建Offer
      // 實際在收到對方join消息後創建Offer
    } catch (error, stackTrace) {
      AppLogger.error('真實通話發起失敗', error, stackTrace);
      _errorMessage = '發起通話失敗: $error';
      _callState = CallState.failed;
      notifyListeners();
    }
  }

  /// 作爲志願者接聽通話
  Future<void> answerCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    required VolunteerInfo volunteer,
  }) async {
    try {
      _resetState();
      _currentVolunteer = volunteer;
      _callState = CallState.connecting;
      notifyListeners();

      // 初始化WebRTC
      _currentCall = await _webRTCService.initializeCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
      );

      // 加入信令房間
      await _signalingService.joinRoom(roomId, role: CallRole.volunteer);

      // 志願者加入後，等待求助者的Offer
    } catch (error, stackTrace) {
      AppLogger.error('真實通話接聽失敗', error, stackTrace);
      _errorMessage = '接聽通話失敗: $error';
      _callState = CallState.failed;
      notifyListeners();
    }
  }

  /// 靜音/取消靜音
  Future<void> toggleMute() async {
    await _webRTCService.toggleMute();
    notifyListeners();
  }

  /// 切換揚聲器
  Future<void> toggleSpeaker() async {
    await _webRTCService.toggleSpeaker();
    notifyListeners();
  }

  /// 開始錄音
  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      final info = await _recordingService.startRecording();
      if (info != null) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      AppLogger.error('真實通話開始錄音失敗', error, stackTrace);
      _errorMessage = '開始錄音失敗: $error';
      notifyListeners();
    }
  }

  /// 停止錄音
  Future<RecordingInfo?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final info = await _recordingService.stopRecording();
      _isRecording = false;
      notifyListeners();
      return info;
    } catch (error, stackTrace) {
      AppLogger.error('真實通話停止錄音失敗', error, stackTrace);
      _errorMessage = '停止錄音失敗: $error';
      notifyListeners();
      return null;
    }
  }

  /// 結束通話
  Future<void> endCall() async {
    if (_currentCall == null) return;

    // 停止錄音
    if (_isRecording) {
      await stopRecording();
    }

    // 發送掛斷信號
    await _signalingService.sendBye(
      _currentCall!.roomId,
      reason: CallEndReason.userHangup,
    );

    // 結束WebRTC通話
    await _webRTCService.endCall(CallEndReason.userHangup);

    // 離開信令房間
    await _signalingService.leaveRoom();

    _callState = CallState.ended;
    notifyListeners();
  }

  // ==================== 事件處理方法 ====================

  /// 處理信令消息
  void _handleSignalingMessage(SignalingMessage message) {
    switch (message.type) {
      case SignalingType.offer:
        // 收到Offer，創建Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          _webRTCService.handleOffer(sdp, type);
        }
        break;

      case SignalingType.answer:
        // 收到Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          _webRTCService.handleAnswer(sdp, type);
        }
        break;

      case SignalingType.iceCandidate:
        // 收到ICE候選
        final candidate = message.data['candidate'] as String?;
        final sdpMid = message.data['sdp_mid'] as String?;
        final sdpMLineIndex = message.data['sdp_mline_index'] as int?;
        if (candidate != null) {
          _webRTCService.addIceCandidate(candidate, sdpMid, sdpMLineIndex);
        }
        break;

      case SignalingType.join:
        // 對方加入，如果是求助者則創建Offer
        if (_currentCall?.myRole == CallRole.seeker) {
          _webRTCService.createOffer();
        }
        break;

      case SignalingType.bye:
        // 對方掛斷
        final reasonStr = message.data['reason'] as String?;
        final reason = CallEndReason.values.firstWhere(
          (r) => r.name == reasonStr,
          orElse: () => CallEndReason.remoteHangup,
        );
        _handleCallEnded(reason);
        break;

      default:
        break;
    }
  }

  /// 處理房間狀態變化
  void _handleRoomStateChange(RoomState state) {
    switch (state) {
      case RoomState.peerJoined:
        // 對方已加入
        break;
      case RoomState.peerLeft:
        // 對方已離開
        if (_callState == CallState.connected) {
          _handleCallEnded(CallEndReason.remoteHangup);
        }
        break;
      case RoomState.callEnded:
        // 通話結束
        _handleCallEnded(CallEndReason.remoteHangup);
        break;
      default:
        break;
    }
  }

  /// 處理通話狀態變化
  void _handleCallStateChange(CallState state) {
    _callState = state;
    notifyListeners();

    if (state == CallState.connected) {
      // 通話連接成功，可以開始錄音（如果需要）
    } else if (state == CallState.ended || state == CallState.failed) {
      // 通話結束
      _handleCallEnded(
        state == CallState.failed
            ? CallEndReason.networkError
            : CallEndReason.userHangup,
      );
    }
  }

  /// 處理通話結束
  void _handleCallEnded(CallEndReason reason) {
    // 停止錄音
    if (_isRecording) {
      stopRecording();
    }

    // 離開信令房間
    _signalingService.leaveRoom();

    _callState = CallState.ended;
    notifyListeners();
  }

  /// 重置狀態
  void _resetState() {
    _callState = CallState.idle;
    _currentCall = null;
    _callDuration = Duration.zero;
    _networkQuality = NetworkQuality.unknown;
    _isRecording = false;
    _errorMessage = null;
    _remoteStream = null;
  }

  // ==================== 資源釋放 ====================

  @override
  void dispose() {
    // 取消訂閱
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 釋放服務
    _webRTCService.dispose();
    _signalingService.dispose();
    _recordingService.dispose();

    super.dispose();
  }
}

/// 志願者信息
class VolunteerInfo {
  final String id;
  final String name;
  final String? avatar;
  final double rating;
  final int helpCount;
  final List<String> skills;

  VolunteerInfo({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
    required this.helpCount,
    required this.skills,
  });
}
