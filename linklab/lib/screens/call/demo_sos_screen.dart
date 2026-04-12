import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/demo_call_service.dart';
import 'demo_call_screen.dart';

/// 演示版SOS紧急求助页面
/// 简化版：模拟SOS流程，固定5秒匹配成功
class DemoSOSScreen extends StatefulWidget {
  const DemoSOSScreen({super.key});

  @override
  State<DemoSOSScreen> createState() => _DemoSOSScreenState();
}

class _DemoSOSScreenState extends State<DemoSOSScreen>
    with TickerProviderStateMixin {
  final DemoSOSService _sosService = DemoSOSService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 长按检测
  bool _isLongPressing = false;
  double _longPressProgress = 0;
  Timer? _longPressTimer;
  static const int _longPressDurationMs = 3000;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _sosService.addListener(_onSOSStateChanged);
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onSOSStateChanged() {
    if (_sosService.isActive) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    // SOS匹配成功，进入通话
    if (_sosService.isActive && _sosService.responderCount > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DemoCallScreen(),
            ),
          );
        }
      });
    }
  }

  void _onLongPressStart() {
    if (_sosService.isActive) return;

    setState(() {
      _isLongPressing = true;
      _longPressProgress = 0;
    });

    HapticFeedback.lightImpact();

    final startTime = DateTime.now();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / _longPressDurationMs).clamp(0.0, 1.0);

      setState(() => _longPressProgress = progress);

      if (progress >= 1.0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _onLongPressEnd() {
    _longPressTimer?.cancel();
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0;
    });
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0;
    });
    await _sosService.triggerSOS();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosService,
      builder: (context, child) {
        final isActive = _sosService.isActive;

        return Scaffold(
          backgroundColor: isActive ? Colors.red : Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // 顶部状态栏
                if (isActive) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red[800],
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'SOS紧急求助进行中',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${(_sosService.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_sosService.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SOS按钮
                        GestureDetector(
                          onLongPressStart: (_) => _onLongPressStart(),
                          onLongPressEnd: (_) => _onLongPressEnd(),
                          onLongPressCancel: _onLongPressEnd,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 200 *
                                    (isActive
                                        ? _pulseAnimation.value
                                        : 1.0),
                                height: 200 *
                                    (isActive
                                        ? _pulseAnimation.value
                                        : 1.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? Colors.white : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 长按进度环
                                    if (_isLongPressing)
                                      CircularProgressIndicator(
                                        value: _longPressProgress,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.red[200],
                                        valueColor:
                                            const AlwaysStoppedAnimation<
                                                Color>(Colors.white),
                                      ),
                                    // 图标和文字
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.sos
                                              : Icons.emergency,
                                          size: 60,
                                          color: isActive
                                              ? Colors.red
                                              : Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isActive ? '求助中' : 'SOS',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.red
                                                : Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 状态文字
                        Text(
                          _sosService.statusText,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (isActive) ...[
                          const SizedBox(height: 16),
                          Text(
                            '5km范围内广播',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '已等待: ${_sosService.elapsedSeconds}秒',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          // 响应者数量
                          if (_sosService.responderCount > 0) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                '${_sosService.responderCount}位志愿者正在赶来',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 60),

                        // 其他触发方式提示
                        if (!isActive) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '其他触发方式:',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildTriggerHint(
                                    '连按电源键3次', '3秒内快速按3次'),
                                _buildTriggerHint(
                                    '语音触发', '说出"紧急求助"等关键词'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 底部按钮
                if (isActive) ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _sosService.resolveSOS();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('安全了'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _sosService.cancelSOS();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('取消求助'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTriggerHint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sosService.removeListener(_onSOSStateChanged);
    _longPressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
