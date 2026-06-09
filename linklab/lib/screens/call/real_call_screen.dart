import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/call_models.dart';
import '../../services/experimental/real/real_call_service.dart';
import '../../services/unified_call_service.dart';
import '../../services/webrtc/webrtc_config.dart';
import 'call_rating_screen.dart';

/// 真實WebRTC通話頁面
/// 支持通話狀態顯示、靜音/揚聲器切換、通話時長計時、網絡狀態指示、錄音功能
/// AGENTS.md §4.2：該頁面屬於實驗性真實鏈路，不進入競賽版默認導航和演示腳本。
class RealCallScreen extends ConsumerStatefulWidget {
  final CallInfo callInfo;
  final VolunteerInfo? volunteer;

  const RealCallScreen({
    super.key,
    required this.callInfo,
    this.volunteer,
  });

  @override
  ConsumerState<RealCallScreen> createState() => _RealCallScreenState();
}

class _RealCallScreenState extends ConsumerState<RealCallScreen> {
  final UnifiedCallService _callService = UnifiedCallService();

  // 狀態
  CallState _callState = CallState.connecting;
  Duration _callDuration = Duration.zero;
  NetworkQuality _networkQuality = NetworkQuality.unknown;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isRecording = false;
  String? _errorMessage;

  // 訂閱
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<NetworkQuality>? _networkQualitySubscription;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  void _initCall() {
    // 監聽通話狀態
    _callStateSubscription = _callService.realCallService.callStateStream.listen((state) {
      setState(() => _callState = state);

      if (state == CallState.connected) {
        _startDurationTimer();
      } else if (state == CallState.ended || state == CallState.failed) {
        _endCall();
      }
    });

    // 監聽網絡質量
    _networkQualitySubscription = _callService.realCallService.networkQualityStream.listen((quality) {
      setState(() => _networkQuality = quality);
    });

    // 監聽錯誤
    _callService.realCallService.addListener(() {
      if (mounted) {
        setState(() {
          _isMuted = _callService.realCallService.isMuted;
          _isSpeakerOn = _callService.realCallService.isSpeakerOn;
          _isRecording = _callService.realCallService.isRecording;
          _errorMessage = _callService.realCallService.errorMessage;
        });
      }
    });
  }

  // 計時器
  Timer? _durationTimer;

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  String get _statusText {
    switch (_callState) {
      case CallState.connecting:
        return '正在連接...';
      case CallState.ringing:
        return '等待接聽...';
      case CallState.connected:
        return '通話中 ${_formatDuration(_callDuration)}';
      case CallState.reconnecting:
        return '重新連接...';
      case CallState.failed:
        return '連接失敗${_errorMessage != null ? ': $_errorMessage' : ''}';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _toggleMute() async {
    await _callService.toggleMute();
  }

  Future<void> _toggleSpeaker() async {
    await _callService.toggleSpeaker();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _callService.stopRecording();
      _showRecordingSavedSnackBar();
    } else {
      await _callService.startRecording();
    }
  }

  void _showRecordingSavedSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('錄音已保存'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _hangUp() async {
    await _callService.endCall();
    _endCall();
  }

  void _endCall() {
    _durationTimer?.cancel();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallRatingScreen(
            callId: widget.callInfo.callId,
            role: widget.callInfo.myRole,
            duration: _callDuration,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callStateSubscription?.cancel();
    _networkQualitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 網絡狀態指示器
            _buildNetworkIndicator(),
            const SizedBox(height: 20),
            // 頭像區域
            _buildAvatarArea(),
            const SizedBox(height: 24),
            // 角色標籤
            Text(
              widget.callInfo.myRole == CallRole.seeker ? '志願者' : '求助者',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 志願者信息
            if (widget.volunteer != null)
              Text(
                widget.volunteer!.name,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 12),
            // 狀態文字
            Text(
              _statusText,
              style: TextStyle(
                color: _callState == CallState.failed ? Colors.red : Colors.grey[400],
                fontSize: 16,
              ),
            ),
            // 錄音指示器
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildRecordingIndicator(),
              ),
            const Spacer(),
            // 控制按鈕
            _buildControlButtons(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// 網絡狀態指示器
  Widget _buildNetworkIndicator() {
    if (_callState != CallState.connected) {
      return const SizedBox.shrink();
    }

    Color indicatorColor;
    IconData icon;

    switch (_networkQuality) {
      case NetworkQuality.excellent:
        indicatorColor = Colors.green;
        icon = Icons.signal_cellular_alt;
        break;
      case NetworkQuality.good:
        indicatorColor = Colors.lightGreen;
        icon = Icons.signal_cellular_alt;
        break;
      case NetworkQuality.fair:
        indicatorColor = Colors.yellow;
        icon = Icons.signal_cellular_alt_2_bar;
        break;
      case NetworkQuality.poor:
        indicatorColor = Colors.orange;
        icon = Icons.signal_cellular_alt_1_bar;
        break;
      case NetworkQuality.bad:
        indicatorColor = Colors.red;
        icon = Icons.signal_cellular_off;
        break;
      case NetworkQuality.unknown:
        indicatorColor = Colors.grey;
        icon = Icons.signal_cellular_null;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: indicatorColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            NetworkQualityEvaluator.getQualityDescription(_networkQuality),
            style: TextStyle(
              color: indicatorColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 頭像區域
  Widget _buildAvatarArea() {
    Color borderColor;
    switch (_callState) {
      case CallState.connected:
        borderColor = Colors.green;
        break;
      case CallState.connecting:
      case CallState.ringing:
        borderColor = Colors.orange;
        break;
      case CallState.failed:
        borderColor = Colors.red;
        break;
      default:
        borderColor = Colors.grey;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
      ),
      child: widget.volunteer?.avatar != null
          ? ClipOval(
              child: Image.network(
                widget.volunteer!.avatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            )
          : const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
    );
  }

  /// 錄音指示器
  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '正在錄音',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 控制按鈕區域
  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // 第一行：靜音、揚聲器、錄音
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 靜音按鈕
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: _isMuted ? '靜音中' : '靜音',
                color: _isMuted ? Colors.orange : Colors.grey[700]!,
                onPressed: _toggleMute,
              ),
              // 揚聲器按鈕
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                label: _isSpeakerOn ? '揚聲器' : '聽筒',
                color: _isSpeakerOn ? Colors.green : Colors.grey[700]!,
                onPressed: _toggleSpeaker,
              ),
              // 錄音按鈕
              _buildControlButton(
                icon: _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                label: _isRecording ? '停止錄音' : '錄音',
                color: _isRecording ? Colors.red : Colors.grey[700]!,
                onPressed: _toggleRecording,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 掛斷按鈕
          _buildHangUpButton(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHangUpButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: IconButton(
            onPressed: _hangUp,
            icon: const Icon(Icons.call_end, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '掛斷',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
