import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/demo_call_service.dart';
import 'demo_call_rating_screen.dart';

/// 演示版通话页面
/// 模拟通话界面，不建立真实WebRTC连接
class DemoCallScreen extends StatefulWidget {
  const DemoCallScreen({super.key});

  @override
  State<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends State<DemoCallScreen> {
  final DemoCallService _callService = DemoCallService();

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    await _callService.startCall();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _hangUp() async {
    await _callService.hangUp();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DemoCallRatingScreen(
            volunteer: _callService.currentVolunteer!,
            duration: _callService.callDuration,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _callService,
      builder: (context, child) {
        final volunteer = _callService.currentVolunteer;
        final isConnecting = _callService.isConnecting;
        final isConnected = _callService.isInCall;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // 志愿者头像
                if (volunteer != null) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                      border: Border.all(
                        color: isConnected ? Colors.green : Colors.orange,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        volunteer.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 志愿者姓名
                  Text(
                    volunteer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 评分和帮助次数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${volunteer.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '已帮助 ${volunteer.helpCount} 次',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 技能标签
                  Wrap(
                    spacing: 8,
                    children: volunteer.skills
                        .map((skill) => Chip(
                              label: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.deepPurple.withOpacity(0.5),
                              padding: EdgeInsets.zero,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                // 状态文字
                if (isConnecting)
                  const Text(
                    '正在连接...',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  )
                else if (isConnected)
                  Text(
                    '通话中 ${_formatDuration(_callService.callDuration)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                const Spacer(),
                // 通话提示
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '演示模式：这是模拟通话界面',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '真实版本将建立WebRTC语音连接',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 控制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 静音按钮（演示）
                      _buildControlButton(
                        icon: Icons.mic,
                        label: '静音',
                        color: Colors.grey[700]!,
                        onPressed: () {
                          // 演示：无实际操作
                        },
                      ),
                      // 挂断按钮（大）
                      _buildHangUpButton(),
                      // 扬声器按钮（演示）
                      _buildControlButton(
                        icon: Icons.volume_up,
                        label: '扬声器',
                        color: Colors.green,
                        onPressed: () {
                          // 演示：无实际操作
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
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
