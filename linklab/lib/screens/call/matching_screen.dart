import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/call_models.dart';
import '../../services/matching_service.dart';
import '../../services/webrtc_service.dart';
import 'async_help_request_screen.dart';
import 'call_screen.dart';

/// 匹配等待页面
/// 显示匹配动画、预估时间和匹配状态
class MatchingScreen extends StatefulWidget {
  final String seekerId;
  final String urgency;
  final Map<String, double> location;
  final List<String>? skills;
  final String? helpType;

  const MatchingScreen({
    super.key,
    required this.seekerId,
    required this.urgency,
    required this.location,
    this.skills,
    this.helpType,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  final MatchingService _matchingService = MatchingService();
  final WebRTCService _webRTCService = WebRTCService();

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  MatchingState _currentState = MatchingState.idle;
  int _elapsedSeconds = 0;
  int _matchedVolunteerCount = 0;
  Timer? _timer;

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

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 监听匹配状态
    _matchingService.matchingStateStream.listen(_onMatchingStateChanged);
    _matchingService.matchedVolunteerStream.listen(_onVolunteerMatched);
  }

  void _onMatchingStateChanged(MatchingState state) {
    setState(() => _currentState = state);

    switch (state) {
      case MatchingState.matched:
        _navigateToCall();
        break;
      case MatchingState.asyncPending:
        _showAsyncDialog();
        break;
      case MatchingState.noVolunteers:
        _showNoVolunteersDialog();
        break;
      case MatchingState.cancelled:
        Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  void _onVolunteerMatched(MatchedVolunteer? volunteer) {
    if (volunteer != null && mounted) {
      // 志愿者已匹配，准备进入通话
    }
  }

  Future<void> _startMatching() async {
    _startTimer();

    try {
      final result = await _matchingService.startMatching(
        seekerId: widget.seekerId,
        urgency: widget.urgency,
        location: widget.location,
        skills: widget.skills,
        helpType: widget.helpType,
      );

      if (result != null) {
        setState(() => _matchedVolunteerCount = result.volunteers.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匹配失败: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _navigateToCall() async {
    _timer?.cancel();

    // 初始化WebRTC
    final callInfo = await _webRTCService.initializeCallAsSeeker(
      seekerId: widget.seekerId,
      helpRequestId: _matchingService.currentHelpRequestId ?? '',
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(callInfo: callInfo),
        ),
      );
    }
  }

  void _showAsyncDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('当前志愿者繁忙'),
        content: const Text('是否转为异步留言？志愿者将在空闲时回覆您。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AsyncHelpRequestScreen(
                    initialTaskType: widget.helpType,
                    initialDescription:
                        '当前实时匹配暂无响应，我想先留言等待志愿者稍后回覆。',
                    replaceWithSeekerCenterOnSubmit: true,
                  ),
                ),
              );
            },
            child: const Text('转为留言'),
          ),
        ],
      ),
    );
  }

  void _showNoVolunteersDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('暂无可用志愿者'),
        content: const Text('当前附近没有在线志愿者，是否转为异步留言？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AsyncHelpRequestScreen(
                    initialTaskType: widget.helpType,
                    initialDescription:
                        '当前附近暂无在线志愿者，请帮我转成异步留言。',
                    replaceWithSeekerCenterOnSubmit: true,
                  ),
                ),
              );
            },
            child: const Text('转为留言'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelMatching() async {
    await _matchingService.cancelMatching();
  }

  String get _statusText {
    switch (_currentState) {
      case MatchingState.searching:
        return '正在搜索志愿者...';
      case MatchingState.waitingResponse:
        return '已推送至 $_matchedVolunteerCount 位志愿者';
      case MatchingState.expandingRange:
        return '扩大搜索范围...';
      case MatchingState.convertingToAsync:
        return '转为异步留言...';
      default:
        return '正在匹配...';
    }
  }

  String get _estimatedTime {
    if (_elapsedSeconds < 10) return '预计等待时间: 10-20秒';
    if (_elapsedSeconds < 30) return '预计等待时间: 5-15秒';
    return '正在扩大搜索范围...';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _matchingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 预计时间
            Text(
              _estimatedTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            // 已等待时间
            Text(
              '已等待: ${_elapsedSeconds}秒',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // 取消按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: _cancelMatching,
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
  }
}
