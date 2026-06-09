import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/call_models.dart';
import '../../services/matching_service.dart';
import '../../services/webrtc_service.dart';
import 'async_help_request_screen.dart';
import 'call_screen.dart';

/// 匹配等待頁面
/// 顯示匹配動畫、預估時間和匹配狀態
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

    // 監聽匹配狀態
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
      // 志願者已匹配，準備進入通話
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
          SnackBar(content: Text('匹配失敗: $e')),
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
        title: const Text('當前志願者繁忙'),
        content: const Text('是否轉爲異步留言？志願者將在空閒時回覆您。'),
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
                        '當前實時匹配暫無響應，我想先留言等待志願者稍後回覆。',
                    replaceWithSeekerCenterOnSubmit: true,
                  ),
                ),
              );
            },
            child: const Text('轉爲留言'),
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
        title: const Text('暫無可用志願者'),
        content: const Text('當前附近沒有在線志願者，是否轉爲異步留言？'),
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
                        '當前附近暫無在線志願者，請幫我轉成異步留言。',
                    replaceWithSeekerCenterOnSubmit: true,
                  ),
                ),
              );
            },
            child: const Text('轉爲留言'),
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
        return '正在搜索志願者...';
      case MatchingState.waitingResponse:
        return '已推送至 $_matchedVolunteerCount 位志願者';
      case MatchingState.expandingRange:
        return '擴大搜索範圍...';
      case MatchingState.convertingToAsync:
        return '轉爲異步留言...';
      default:
        return '正在匹配...';
    }
  }

  String get _estimatedTime {
    if (_elapsedSeconds < 10) return '預計等待時間: 10-20秒';
    if (_elapsedSeconds < 30) return '預計等待時間: 5-15秒';
    return '正在擴大搜索範圍...';
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
            // 脈衝動畫
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
            // 狀態文字
            Text(
              _statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 預計時間
            Text(
              _estimatedTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            // 已等待時間
            Text(
              '已等待: ${_elapsedSeconds}秒',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // 取消按鈕
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
