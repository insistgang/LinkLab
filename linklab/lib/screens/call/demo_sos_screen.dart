import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../demo_flow/demo_help_request_tracker.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/app_session_service.dart';
import '../../services/demo_call_service.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import 'demo_call_screen.dart';
import '../security/location_sharing_screen.dart';

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
  final EmergencyContactService _contactService = EmergencyContactService();
  final SafetySettingsService _safetySettingsService = SafetySettingsService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 长按检测
  bool _isLongPressing = false;
  double _longPressProgress = 0;
  Timer? _longPressTimer;
  Timer? _undoWindowTimer;
  static const int _longPressDurationMs = 3000;
  static const int _undoWindowSeconds = 10;
  List<EmergencyContactModel> _emergencyContacts = const [];
  SafetySettings _safetySettings = const SafetySettings();
  bool _isLoadingReadiness = true;
  bool _isUndoWindowActive = false;
  int _undoCountdownSeconds = _undoWindowSeconds;

  String get _currentUserId =>
      AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _sosService.addListener(_onSOSStateChanged);
    _loadSafetyContext();
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
            MaterialPageRoute(builder: (_) => const DemoCallScreen()),
          );
        }
      });
    }
  }

  void _onLongPressStart() {
    if (_sosService.isActive || _isUndoWindowActive) return;

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

  Future<void> _loadSafetyContext() async {
    final results = await Future.wait<dynamic>([
      _contactService.getContacts(_currentUserId),
      _safetySettingsService.getSettings(_currentUserId),
    ]);

    if (!mounted) return;
    setState(() {
      _emergencyContacts = results[0] as List<EmergencyContactModel>;
      _safetySettings = results[1] as SafetySettings;
      _isLoadingReadiness = false;
    });
  }

  Future<void> _openSafetySettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationSharingScreen(userId: _currentUserId),
      ),
    );
    await _loadSafetyContext();
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0;
      _isUndoWindowActive = true;
      _undoCountdownSeconds = _undoWindowSeconds;
    });
    await DemoHelpRequestTracker.startSOSUndoWindow();
    _startUndoWindow();
  }

  void _startUndoWindow() {
    _undoWindowTimer?.cancel();
    _undoWindowTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_undoCountdownSeconds <= 1) {
        timer.cancel();
        _activateSOSFlow();
        return;
      }

      setState(() {
        _undoCountdownSeconds--;
      });
    });
  }

  Future<void> _activateSOSFlow() async {
    if (!_isUndoWindowActive) {
      return;
    }

    setState(() {
      _isUndoWindowActive = false;
      _undoCountdownSeconds = _undoWindowSeconds;
    });

    if (_safetySettings.shareWithEmergencyContacts &&
        _emergencyContacts.isNotEmpty) {
      unawaited(
        _contactService.notifyEmergencyContacts(
          userId: _currentUserId,
          latitude: _safetySettings.autoShareLocation ? 31.2304 : 0,
          longitude: _safetySettings.autoShareLocation ? 121.4737 : 0,
          address: _buildLocationSummary(),
          message: _buildEmergencyNotificationMessage(),
        ),
      );
    }

    await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: 'SOS紧急求助',
      type: 'sos',
      urgency: 'emergency',
    );
    await _sosService.triggerSOS();
  }

  Future<void> _cancelPendingSOS() async {
    _undoWindowTimer?.cancel();
    setState(() {
      _isUndoWindowActive = false;
      _undoCountdownSeconds = _undoWindowSeconds;
    });
    await DemoHelpRequestTracker.markCancelled(reason: 'SOS 误触撤销');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosService,
      builder: (context, child) {
        final isActive = _sosService.isActive;
        final isEmergencyFlowActive = isActive || _isUndoWindowActive;

        return Scaffold(
          backgroundColor: isEmergencyFlowActive ? Colors.red : Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // 顶部状态栏
                if (isEmergencyFlowActive) ...[
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
                          _isUndoWindowActive
                              ? '撤销 ${_undoCountdownSeconds}s'
                              : '${(_sosService.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_sosService.elapsedSeconds % 60).toString().padLeft(2, '0')}',
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
                                width:
                                    200 *
                                    (isEmergencyFlowActive
                                        ? _pulseAnimation.value
                                        : 1.0),
                                height:
                                    200 *
                                    (isEmergencyFlowActive
                                        ? _pulseAnimation.value
                                        : 1.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isEmergencyFlowActive
                                      ? Colors.white
                                      : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
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
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    // 图标和文字
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEmergencyFlowActive
                                              ? Icons.sos
                                              : Icons.emergency,
                                          size: 60,
                                          color: isEmergencyFlowActive
                                              ? Colors.red
                                              : Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isEmergencyFlowActive ? '求助中' : 'SOS',
                                          style: TextStyle(
                                            color: isEmergencyFlowActive
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
                          _isUndoWindowActive
                              ? '已进入 10 秒误触撤销窗口，倒计时结束后才会广播给志愿者和联系人。'
                              : _sosService.statusText,
                          style: TextStyle(
                            color: isEmergencyFlowActive
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (_isUndoWindowActive) ...[
                          const SizedBox(height: 16),
                          Text(
                            '误触撤销剩余 $_undoCountdownSeconds 秒',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEmergencyContactBanner(isActive: true),
                          const SizedBox(height: 16),
                          _buildSafetyTimelineCard(isActive: false),
                        ] else if (isActive) ...[
                          const SizedBox(height: 16),
                          Text(
                            '5km范围内广播',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '已等待: ${_sosService.elapsedSeconds}秒',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEmergencyContactBanner(isActive: true),
                          const SizedBox(height: 16),
                          _buildSafetyTimelineCard(isActive: true),
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
                          _buildEmergencyContactBanner(isActive: false),
                          const SizedBox(height: 16),
                          if (_isLoadingReadiness)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            )
                          else ...[
                            _buildSafetyTimelineCard(isActive: false),
                            if (_needsMoreSafetySetup()) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _openSafetySettings,
                                icon: const Icon(Icons.tune),
                                label: const Text('完善位置共享设置'),
                              ),
                            ],
                          ],
                          const SizedBox(height: 20),
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
                                _buildTriggerHint('连按电源键3次', '3秒内快速按3次'),
                                if (_safetySettings.enableVoiceTrigger)
                                  _buildTriggerHint('语音触发', '说出"紧急求助"等关键词'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 底部按钮
                if (_isUndoWindowActive) ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cancelPendingSOS,
                            icon: const Icon(Icons.undo),
                            label: const Text('撤销误触'),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _activateSOSFlow,
                            icon: const Icon(Icons.campaign),
                            label: const Text('立即发送'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
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
                ] else if (isActive) ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              _sosService.resolveSOS();
                              await DemoHelpRequestTracker.markCompleted();
                              if (!context.mounted) return;
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
                            onPressed: () async {
                              _sosService.cancelSOS();
                              await DemoHelpRequestTracker.markCancelled(
                                reason: '用户取消SOS',
                              );
                              if (!context.mounted) return;
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

  Widget _buildEmergencyContactBanner({required bool isActive}) {
    final hasContacts = _emergencyContacts.isNotEmpty;
    final names = _emergencyContacts.map((contact) => contact.name).join('、');
    final shouldNotifyContacts =
        _safetySettings.shareWithEmergencyContacts && hasContacts;
    final locationLabel = !_safetySettings.autoShareLocation
        ? '未自动共享位置'
        : (_safetySettings.usePreciseLocation ? '精确位置' : '大致位置');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.red.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shouldNotifyContacts
                ? '安全通知已就绪'
                : (hasContacts ? '联系人通知已关闭' : '尚未设置紧急联系人'),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            shouldNotifyContacts
                ? '本次 SOS 会以$locationLabel同步通知 ${_emergencyContacts.length} 位联系人：$names'
                : _safetySettings.shareWithEmergencyContacts
                ? '当前仍会演示志愿者广播流程，但联系人通知需要先在“我的 > 紧急联系人”中完成设置。位置状态：$locationLabel。'
                : '本次 SOS 仅展示志愿者广播流程。位置状态：$locationLabel。',
            style: TextStyle(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.88)
                  : Colors.black87,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (!shouldNotifyContacts) ...[
            const SizedBox(height: 8),
            Text(
              _safetySettings.shareWithEmergencyContacts
                  ? '可在“我的 > 紧急联系人”中添加，最多 3 位。'
                  : '可在“位置共享”中重新开启联系人同步。',
              style: TextStyle(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.72)
                    : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTimelineCard({required bool isActive}) {
    final steps = _buildSafetySteps(isActive: isActive);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isActive ? 'SOS 当前进度' : 'SOS 将执行的步骤',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSafetyStepRow(step: step, isActive: isActive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyStepRow({
    required _SafetyStep step,
    required bool isActive,
  }) {
    final (icon, color) = switch (step.state) {
      _SafetyStepState.completed => (Icons.check_circle, Colors.greenAccent),
      _SafetyStepState.active => (
        Icons.radio_button_checked,
        Colors.amberAccent,
      ),
      _SafetyStepState.skipped => (Icons.remove_circle_outline, Colors.white70),
      _SafetyStepState.pending => (
        Icons.radio_button_unchecked,
        isActive ? Colors.white70 : Colors.black45,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.description,
                style: TextStyle(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.82)
                      : Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_SafetyStep> _buildSafetySteps({required bool isActive}) {
    final hasResponse = _sosService.responderCount > 0;
    final shouldNotifyContacts =
        _safetySettings.shareWithEmergencyContacts &&
        _emergencyContacts.isNotEmpty;

    return [
      _SafetyStep(
        title: _safetySettings.autoShareLocation
            ? '同步${_safetySettings.usePreciseLocation ? '精确' : '大致'}位置'
            : '跳过自动位置共享',
        description: _safetySettings.autoShareLocation
            ? '演示位置摘要会进入 SOS 链路。'
            : '本次流程只展示基础求助，不附带位置。',
        state: _safetySettings.autoShareLocation
            ? (isActive ? _SafetyStepState.completed : _SafetyStepState.pending)
            : _SafetyStepState.skipped,
      ),
      _SafetyStep(
        title: shouldNotifyContacts ? '通知紧急联系人' : '跳过联系人通知',
        description: shouldNotifyContacts
            ? '将同步通知 ${_emergencyContacts.length} 位联系人。'
            : _safetySettings.shareWithEmergencyContacts
            ? '当前没有可通知的联系人。'
            : '你已在设置中关闭联系人同步。',
        state: shouldNotifyContacts
            ? (isActive ? _SafetyStepState.completed : _SafetyStepState.pending)
            : _SafetyStepState.skipped,
      ),
      _SafetyStep(
        title: '向附近志愿者广播',
        description: hasResponse
            ? '已有 ${_sosService.responderCount} 位志愿者响应。'
            : '演示版默认在 5km 范围内广播。',
        state: !isActive
            ? _SafetyStepState.pending
            : (hasResponse
                  ? _SafetyStepState.completed
                  : _SafetyStepState.active),
      ),
      _SafetyStep(
        title: '建立演示响应',
        description: hasResponse ? '即将进入通话演示。' : '正在等待志愿者接入。',
        state: !isActive
            ? _SafetyStepState.pending
            : (hasResponse
                  ? _SafetyStepState.completed
                  : _SafetyStepState.active),
      ),
    ];
  }

  bool _needsMoreSafetySetup() {
    return !_safetySettings.autoShareLocation ||
        (_safetySettings.shareWithEmergencyContacts &&
            _emergencyContacts.isEmpty);
  }

  String _buildLocationSummary() {
    if (!_safetySettings.autoShareLocation) {
      return '用户未开启自动位置共享';
    }

    return _safetySettings.usePreciseLocation ? '演示位置：上海市静安区' : '演示位置：上海市静安区附近';
  }

  String _buildEmergencyNotificationMessage() {
    final location = _buildLocationSummary();
    return '【LinkLab紧急求助】用户已触发 SOS，$location，请尽快联系确认安全。';
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
    _undoWindowTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}

enum _SafetyStepState { pending, active, completed, skipped }

class _SafetyStep {
  const _SafetyStep({
    required this.title,
    required this.description,
    required this.state,
  });

  final String title;
  final String description;
  final _SafetyStepState state;
}
