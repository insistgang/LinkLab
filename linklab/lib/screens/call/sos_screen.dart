import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/sos_service.dart';
import '../../services/webrtc_service.dart';
import 'call_screen.dart';

/// SOS 緊急求助頁面
/// 大按鈕觸發SOS，顯示SOS狀態和倒計時
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  final SOSService _sosService = SOSService();
  final WebRTCService _webRTCService = WebRTCService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  SOSState _currentState = SOSState.idle;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // 長按檢測
  bool _isLongPressing = false;
  double _longPressProgress = 0;
  Timer? _longPressTimer;
  static const int _longPressDurationMs = 3000;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _subscribeToSOSState();
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

  void _subscribeToSOSState() {
    _sosService.sosStateStream.listen((state) {
      setState(() => _currentState = state);

      switch (state) {
        case SOSState.broadcasting:
          _startTimer();
          _pulseController.repeat(reverse: true);
          break;
        case SOSState.waitingResponse:
          // 保持動畫
          break;
        case SOSState.responded:
        case SOSState.connected:
          _navigateToCall();
          break;
        case SOSState.cancelled:
        case SOSState.resolved:
          _resetState();
          break;
        default:
          break;
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _resetState() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _elapsedSeconds = 0;
      _currentState = SOSState.idle;
    });
  }

  Future<void> _navigateToCall() async {
    _timer?.cancel();
    _pulseController.stop();

    // 獲取當前通話信息
    final callInfo = _webRTCService.currentCall;
    if (callInfo != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(callInfo: callInfo),
        ),
      );
    }
  }

  void _onLongPressStart() {
    if (_currentState != SOSState.idle) return;

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
        _triggerSOS(SOSTriggerMethod.longPress);
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

  Future<void> _triggerSOS(SOSTriggerMethod method) async {
    HapticFeedback.heavyImpact();
    await _sosService.triggerSOS(method);
  }

  Future<void> _cancelSOS() async {
    await _sosService.cancelSOS();
  }

  Future<void> _resolveSOS() async {
    await _sosService.resolveSOS();
  }

  String get _statusText {
    switch (_currentState) {
      case SOSState.triggering:
        return '正在觸發SOS...';
      case SOSState.gettingLocation:
        return '正在獲取位置...';
      case SOSState.broadcasting:
        return '正在廣播求助信號...';
      case SOSState.waitingResponse:
        return '等待志願者響應...';
      case SOSState.escalating:
        return '擴大搜索範圍...';
      case SOSState.responded:
        return '志願者已響應';
      case SOSState.connected:
        return '正在建立連接...';
      case SOSState.manualIntervention:
        return '平臺已介入處理';
      default:
        return '長按3秒發送緊急求助';
    }
  }

  String get _escalationText {
    if (_elapsedSeconds < 300) {
      return '5km範圍內廣播';
    } else if (_elapsedSeconds < 600) {
      return '已擴大至全城廣播';
    } else {
      return '已通知所有緊急聯繫人';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentState == SOSState.idle ? Colors.white : Colors.red,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部狀態欄
            if (_currentState != SOSState.idle) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red[800],
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SOS緊急求助進行中',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
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
                    // SOS按鈕
                    GestureDetector(
                      onLongPressStart: (_) => _onLongPressStart(),
                      onLongPressEnd: (_) => _onLongPressEnd(),
                      onLongPressCancel: _onLongPressEnd,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200 * (_currentState == SOSState.idle ? 1.0 : _pulseAnimation.value),
                            height: 200 * (_currentState == SOSState.idle ? 1.0 : _pulseAnimation.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentState == SOSState.idle ? Colors.red : Colors.white,
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
                                // 長按進度環
                                if (_isLongPressing)
                                  CircularProgressIndicator(
                                    value: _longPressProgress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.red[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                // 圖標和文字
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _currentState == SOSState.idle ? Icons.emergency : Icons.sos,
                                      size: 60,
                                      color: _currentState == SOSState.idle ? Colors.white : Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _currentState == SOSState.idle ? 'SOS' : '求助中',
                                      style: TextStyle(
                                        color: _currentState == SOSState.idle ? Colors.white : Colors.red,
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

                    // 狀態文字
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _currentState == SOSState.idle ? Colors.black87 : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (_currentState != SOSState.idle) ...[
                      const SizedBox(height: 16),
                      Text(
                        _escalationText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已等待: $_elapsedSeconds秒',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 60),

                    // 其他觸發方式提示
                    if (_currentState == SOSState.idle) ...[
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
                              '其他觸發方式:',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTriggerHint('連按電源鍵3次', '3秒內快速按3次'),
                            _buildTriggerHint('語音觸發', '說出"緊急求助"等關鍵詞'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 底部按鈕
            if (_currentState != SOSState.idle) ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resolveSOS,
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
                        onPressed: _cancelSOS,
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
    _timer?.cancel();
    _longPressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
