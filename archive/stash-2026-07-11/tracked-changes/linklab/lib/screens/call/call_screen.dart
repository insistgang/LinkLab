import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../models/call_models.dart';
import '../../services/webrtc_service.dart';
import 'call_rating_screen.dart';

/// 语音通话页面
/// 显示通话状态、大按钮挂断/静音
class CallScreen extends StatefulWidget {
  final CallInfo callInfo;

  const CallScreen({
    super.key,
    required this.callInfo,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRTCService _webRTCService = WebRTCService();

  CallState _callState = CallState.connecting;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  void _initCall() {
    // 监听通话状态
    _webRTCService.callStateStream.listen((state) {
      setState(() => _callState = state);

      if (state == CallState.connected) {
        _startDurationTimer();
      } else if (state == CallState.ended || state == CallState.failed) {
        _endCall();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  String get _statusText {
    switch (_callState) {
      case CallState.connecting:
        return '正在连接...';
      case CallState.ringing:
        return '等待接听...';
      case CallState.connected:
        return '通话中 ${_formatDuration(_callDuration)}';
      case CallState.reconnecting:
        return '重新连接...';
      case CallState.failed:
        return '连接失败';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleMute() async {
    await _webRTCService.toggleMute();
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    await _webRTCService.toggleSpeaker();
    setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  Future<void> _hangUp() async {
    await _webRTCService.endCall(CallEndReason.userHangup);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // 头像区域
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
                border: Border.all(
                  color: _callState == CallState.connected
                      ? Colors.green
                      : Colors.orange,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // 角色标签
            Text(
              widget.callInfo.myRole == CallRole.seeker ? '志愿者' : '求助者',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 状态文字
            Text(
              _statusText,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // 控制按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 静音按钮
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? '静音中' : '静音',
                    color: _isMuted ? Colors.orange : Colors.grey[700]!,
                    onPressed: _toggleMute,
                  ),
                  // 挂断按钮（大）
                  _buildHangUpButton(),
                  // 扬声器按钮
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: _isSpeakerOn ? '扬声器' : '听筒',
                    color: _isSpeakerOn ? Colors.green : Colors.grey[700]!,
                    onPressed: _toggleSpeaker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 28),
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
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: IconButton(
            onPressed: _hangUp,
            icon: const Icon(Icons.call_end, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '挂断',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
