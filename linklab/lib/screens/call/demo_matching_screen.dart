import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/demo_call_service.dart';
import 'demo_call_screen.dart';

/// 演示版匹配等待页面
/// 简化版：模拟匹配过程，固定4秒匹配成功
class DemoMatchingScreen extends StatefulWidget {
  const DemoMatchingScreen({super.key});

  @override
  State<DemoMatchingScreen> createState() => _DemoMatchingScreenState();
}

class _DemoMatchingScreenState extends State<DemoMatchingScreen>
    with TickerProviderStateMixin {
  final DemoMatchingService _matchingService = DemoMatchingService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startMatching();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startMatching() async {
    await _matchingService.startMatching();

    if (mounted) {
      // 匹配成功，进入通话页面
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DemoCallScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _matchingService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.deepPurple,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // 脉冲动画
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 120 * _pulseAnimation.value,
                      height: 120 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // 状态文字
                Text(
                  _matchingService.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 已等待时间
                Text(
                  '已等待: ${_matchingService.elapsedSeconds}秒',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                // 志愿者列表预览
                if (_matchingService.matchedCount > 0) ...[
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '找到以下志愿者',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _matchingService.matchedCount,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.3),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // 取消按钮
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _matchingService.cancelMatching();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('取消匹配'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
