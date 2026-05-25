import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/emergency_contact_model.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/demo_help_request_flow_provider.dart';
import '../../providers/demo_services_provider.dart';
import '../../providers/facade_providers.dart';
import '../../services/demo_call_service.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../security/location_sharing_screen.dart';
import 'demo_call_screen.dart';

/// 演示版SOS紧急求助页面
/// 简化版：模拟SOS流程，固定5秒匹配成功
class DemoSOSScreen extends ConsumerStatefulWidget {
  const DemoSOSScreen({
    super.key,
    this.autoStartUndoWindow = false,
    this.autoActivateEmergency = false,
  });

  final bool autoStartUndoWindow;
  final bool autoActivateEmergency;

  @override
  ConsumerState<DemoSOSScreen> createState() => _DemoSOSScreenState();
}

class _DemoSOSScreenState extends ConsumerState<DemoSOSScreen>
    with TickerProviderStateMixin {
  late final DemoSOSService _sosService;
  final EmergencyContactService _contactService = EmergencyContactService();
  final SafetySettingsService _safetySettingsService = SafetySettingsService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
      ref.read(appSessionProvider).userProfile?.id ?? 'demo-user-id';

  @override
  void initState() {
    super.initState();
    _sosService = ref.read(demoSOSServiceProvider);
    _initAnimations();
    _sosService.addListener(_onSOSStateChanged);
    _loadSafetyContext();
    if (widget.autoActivateEmergency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_activateSOSFlow());
      });
    } else if (widget.autoStartUndoWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerSOS();
      });
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onSOSStateChanged() {
    if (_sosService.isActive) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    if (_sosService.isActive && _sosService.responderCount > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          replaceWithDemoStageRoute(context, page: const DemoCallScreen());
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
    await pushDemoStageRoute(
      context,
      page: LocationSharingScreen(userId: _currentUserId),
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

    // Facade 优先：调用 SosFacade.startUndoWindow
    try {
      final facade = ref.read(sosFacadeProvider);
      final result = await facade.startUndoWindow();
      if (result.success) {
        // Facade 成功，继续走 demo 流程驱动 UI
      }
    } catch (_) {
      // Facade 异常，降级到旧流程
    }

    // Fallback：原有 demo flow
    await ref.read(demoHelpRequestFlowProvider.notifier).startSOSUndoWindow();
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
    if (!_isUndoWindowActive && !widget.autoActivateEmergency) {
      return;
    }

    setState(() {
      _isUndoWindowActive = false;
      _undoCountdownSeconds = _undoWindowSeconds;
    });

    // Facade 优先：调用 SosFacade.broadcastToNearby 和 notifyEmergencyContacts
    try {
      final facade = ref.read(sosFacadeProvider);
      final broadcastResult = await facade.broadcastToNearby();
      if (broadcastResult.success) {
        // Facade 广播成功
      }
      await facade.notifyEmergencyContacts();
    } catch (_) {
      // Facade 异常，降级到旧流程
    }

    // Fallback：原有联系人通知逻辑
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

    // Fallback：原有 demo flow
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(intent: 'SOS紧急求助', type: 'sos', urgency: 'emergency');
    await _sosService.triggerSOS();
  }

  Future<void> _cancelPendingSOS() async {
    _undoWindowTimer?.cancel();
    setState(() {
      _isUndoWindowActive = false;
      _undoCountdownSeconds = _undoWindowSeconds;
    });

    // Facade 优先：调用 SosFacade.cancelSOS
    try {
      final facade = ref.read(sosFacadeProvider);
      await facade.cancelSOS();
    } catch (_) {
      // Facade 异常，降级到旧流程
    }

    // Fallback：原有 demo flow
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .markCancelled(reason: 'SOS 误触撤销');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosService,
      builder: (context, child) {
        final isActive = _sosService.isActive;
        final isEmergencyFlowActive = isActive || _isUndoWindowActive;

        return DemoStageScaffold(
          title: isEmergencyFlowActive ? 'SOS 紧急求助进行中' : 'SOS 紧急求助',
          subtitle: isEmergencyFlowActive
              ? '误触撤销窗口与 Mock 广播进度均可见'
              : '保留 10 秒误触撤销窗口，支持本地可复现演示',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            children: [
              if (isEmergencyFlowActive)
                DemoReveal(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.stageDanger.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.stageDanger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const LinkableSvgIcon(
                          icon: LinkableIconName.emergency,
                          size: 28,
                          semanticLabel: 'SOS紧急求助',
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: AccessibleText(
                            'SOS紧急求助进行中',
                            style: TextStyle(
                              color: AppTheme.stageTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AccessibleText(
                          _isUndoWindowActive
                              ? '撤销 ${_undoCountdownSeconds}s'
                              : '${(_sosService.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_sosService.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isEmergencyFlowActive) ...[
                Center(
                  child: Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    alignment: WrapAlignment.center,
                    children: [
                      DemoPill(
                        icon: Icons.timer_outlined,
                        label: '10 秒撤销窗口',
                        color: AppTheme.stageWarning,
                      ),
                      DemoPill(
                        icon: Icons.campaign_outlined,
                        label: 'Mock 广播演示',
                        color: AppTheme.stageDanger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],
              const SizedBox(height: AppTheme.spacingXL),
              Center(
                child: GestureDetector(
                  onLongPressStart: (_) => _onLongPressStart(),
                  onLongPressEnd: (_) => _onLongPressEnd(),
                  onLongPressCancel: _onLongPressEnd,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final scale = isEmergencyFlowActive
                          ? _pulseAnimation.value
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isEmergencyFlowActive
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE5E5),
                                      Color(0xFFFFF3F0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppTheme.stageDanger,
                                      const Color(0xFFFF8A5B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.stageDanger.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 28,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isLongPressing)
                                SizedBox(
                                  width: 196,
                                  height: 196,
                                  child: CircularProgressIndicator(
                                    value: _longPressProgress,
                                    strokeWidth: 9,
                                    backgroundColor: AppTheme.stageDanger
                                        .withValues(alpha: 0.22),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.stageTextPrimary,
                                    ),
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LinkableSvgIcon(
                                    icon: LinkableIconName.emergency,
                                    size: 64,
                                    semanticLabel: isEmergencyFlowActive
                                        ? 'SOS进行中'
                                        : 'SOS紧急求助',
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    isEmergencyFlowActive ? '求助中' : 'SOS',
                                    style: TextStyle(
                                      color: isEmergencyFlowActive
                                          ? AppTheme.stageDanger
                                          : AppTheme.stageTextPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AccessibleText(
                _isUndoWindowActive
                    ? '已进入 10 秒误触撤销窗口，倒计时结束后才会广播给志愿者和联系人。'
                    : _sosService.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEmergencyFlowActive
                      ? AppTheme.stageTextPrimary
                      : AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              AccessibleText(
                isEmergencyFlowActive
                    ? '评审可以直接看到广播中、联系人通知和撤销窗口的状态切换。'
                    : '长按按钮 3 秒即可进入紧急求助流程。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeNormal,
                ),
              ),
              if (_isUndoWindowActive) ...[
                const SizedBox(height: AppTheme.spacingL),
                Center(
                  child: DemoPill(
                    label: '误触撤销剩余 $_undoCountdownSeconds 秒',
                    icon: Icons.timer_outlined,
                    color: AppTheme.stageWarning,
                  ),
                ),
              ] else if (isActive) ...[
                const SizedBox(height: AppTheme.spacingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DemoPill(
                      icon: Icons.campaign_outlined,
                      label: '5km 范围内广播',
                      color: AppTheme.stageDanger,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    DemoPill(
                      icon: Icons.schedule_outlined,
                      label: '已等待: ${_sosService.elapsedSeconds}秒',
                      color: AppTheme.stageTextPrimary,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                if (_sosService.responderCount > 0) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  Center(
                    child: DemoPill(
                      label: '${_sosService.responderCount}位志愿者正在赶来',
                      icon: Icons.favorite_rounded,
                      color: AppTheme.stageSuccess,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppTheme.spacingXL),
              if (!isEmergencyFlowActive)
                DemoReveal(
                  delay: const Duration(milliseconds: 90),
                  child: DemoSurfaceCard(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessibleText(
                          '触发前准备',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontSize: AppTheme.fontSizeNormal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: _ReadinessMetric(
                                label: '位置',
                                value: _safetySettings.autoShareLocation
                                    ? (_safetySettings.usePreciseLocation
                                          ? '精确'
                                          : '大致')
                                    : '关闭',
                                color: _safetySettings.autoShareLocation
                                    ? AppTheme.stageSuccess
                                    : AppTheme.stageWarning,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: _ReadinessMetric(
                                label: '联系人',
                                value: '${_emergencyContacts.length} 位',
                                color: _emergencyContacts.isEmpty
                                    ? AppTheme.stageWarning
                                    : AppTheme.stageInfo,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: _ReadinessMetric(
                                label: '触发',
                                value: '长按 3 秒',
                                color: AppTheme.stageDanger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isEmergencyFlowActive)
                const SizedBox(height: AppTheme.spacingL),
              _buildEmergencyContactBanner(isActive: isEmergencyFlowActive),
              const SizedBox(height: AppTheme.spacingL),
              if (_isLoadingReadiness)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.stageAccent,
                    ),
                  ),
                )
              else
                _buildSafetyTimelineCard(isActive: isEmergencyFlowActive),
              if (!isEmergencyFlowActive && _needsMoreSafetySetup()) ...[
                const SizedBox(height: AppTheme.spacingM),
                TextButton.icon(
                  onPressed: _openSafetySettings,
                  icon: const LinkableSvgIcon(
                    icon: LinkableIconName.screenReader,
                    size: 24,
                    semanticLabel: '完善位置共享设置',
                  ),
                  label: Text(
                    '完善位置共享设置',
                    style: TextStyle(color: AppTheme.stageAccent),
                  ),
                ),
              ],
              if (!isEmergencyFlowActive) ...[
                const SizedBox(height: AppTheme.spacingL),
                DemoSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '其他触发方式',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTriggerHint('连按电源键3次', '3秒内快速按3次'),
                      if (_safetySettings.enableVoiceTrigger)
                        _buildTriggerHint('语音触发', '说出“紧急求助”等关键词'),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomBar: _buildBottomBar(isActive: isActive),
        );
      },
    );
  }

  Widget _buildBottomBar({required bool isActive}) {
    if (_isUndoWindowActive) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelPendingSOS,
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.cancel,
                size: 24,
                semanticLabel: '撤销误触',
              ),
              label: const Text('撤销误触'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.stageTextPrimary,
                side: BorderSide(
                  color: AppTheme.stageTextPrimary.withValues(alpha: 0.18),
                ),
                minimumSize: const Size(0, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _activateSOSFlow,
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.broadcast,
                size: 24,
                semanticLabel: '立即发送',
              ),
              label: const Text('立即发送'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageWarning,
                foregroundColor: AppTheme.stageBackground,
                minimumSize: const Size(0, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (isActive) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Facade 优先：调用 SosFacade.cancelSOS（安全了 = 结束 SOS）
                try {
                  final facade = ref.read(sosFacadeProvider);
                  await facade.cancelSOS();
                } catch (_) {
                  // Facade 异常，降级到旧流程
                }
                _sosService.resolveSOS();
                await ref
                    .read(demoHelpRequestFlowProvider.notifier)
                    .markCompleted();
                if (!mounted) return;
                Navigator.pop(context);
              },
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.completed,
                size: 24,
                semanticLabel: '安全了',
              ),
              label: const Text('安全了'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageSuccess,
                foregroundColor: AppTheme.stageBackground,
                minimumSize: const Size(0, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                // Facade 优先：调用 SosFacade.cancelSOS
                try {
                  final facade = ref.read(sosFacadeProvider);
                  await facade.cancelSOS();
                } catch (_) {
                  // Facade 异常，降级到旧流程
                }
                _sosService.cancelSOS();
                await ref
                    .read(demoHelpRequestFlowProvider.notifier)
                    .markCancelled(reason: '用户取消SOS');
                if (!mounted) return;
                Navigator.pop(context);
              },
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.cancel,
                size: 24,
                semanticLabel: '取消求助',
              ),
              label: const Text('取消求助'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.stageTextPrimary,
                side: BorderSide(
                  color: AppTheme.stageTextPrimary.withValues(alpha: 0.18),
                ),
                minimumSize: const Size(0, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmergencyContactBanner({required bool isActive}) {
    final hasContacts = _emergencyContacts.isNotEmpty;
    final names = _emergencyContacts.map((contact) => contact.name).join('、');
    final shouldNotifyContacts =
        _safetySettings.shareWithEmergencyContacts && hasContacts;
    final locationLabel = !_safetySettings.autoShareLocation
        ? '未自动共享位置'
        : (_safetySettings.usePreciseLocation ? '精确位置' : '大致位置');

    return DemoSurfaceCard(
      color: isActive
          ? AppTheme.stageDanger.withValues(alpha: 0.12)
          : AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      borderColor: isActive
          ? AppTheme.stageDanger.withValues(alpha: 0.22)
          : AppTheme.stageBorder.withValues(alpha: 0.82),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            shouldNotifyContacts
                ? '安全通知已就绪'
                : (hasContacts ? '联系人通知已关闭' : '尚未设置紧急联系人'),
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontSizeNormal,
            ),
          ),
          const SizedBox(height: 6),
          AccessibleText(
            shouldNotifyContacts
                ? '本次 SOS 会以$locationLabel同步通知 ${_emergencyContacts.length} 位联系人：$names'
                : _safetySettings.shareWithEmergencyContacts
                ? '当前仍会演示志愿者广播流程，但联系人通知需要先在“我的 > 紧急联系人”中完成设置。位置状态：$locationLabel。'
                : '本次 SOS 仅展示志愿者广播流程。位置状态：$locationLabel。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          if (!shouldNotifyContacts) ...[
            const SizedBox(height: 8),
            AccessibleText(
              _safetySettings.shareWithEmergencyContacts
                  ? '可在“我的 > 紧急联系人”中添加，最多 3 位。'
                  : '可在“位置共享”中重新开启联系人同步。',
              style: TextStyle(color: AppTheme.stageTextHint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTimelineCard({required bool isActive}) {
    final steps = _buildSafetySteps(isActive: isActive);

    return DemoSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            isActive ? 'SOS 当前进度' : 'SOS 将执行的步骤',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontSizeNormal,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSafetyStepRow(step: step),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyStepRow({required _SafetyStep step}) {
    final (icon, color) = switch (step.state) {
      _SafetyStepState.completed => (
        LinkableIconName.completed,
        AppTheme.stageSuccess,
      ),
      _SafetyStepState.active => (
        LinkableIconName.processing,
        AppTheme.stageAccent,
      ),
      _SafetyStepState.skipped => (
        LinkableIconName.cancel,
        AppTheme.stageTextHint,
      ),
      _SafetyStepState.pending => (
        LinkableIconName.unknown,
        AppTheme.stageTextHint,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinkableSvgIcon(icon: icon, size: 22, semanticLabel: step.title),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                step.title,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              AccessibleText(
                step.description,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
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
          const LinkableSvgIcon(
            icon: LinkableIconName.emergencyDetect,
            size: 18,
            semanticLabel: '紧急检测提示',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$title：',
                    style: TextStyle(
                      color: AppTheme.stageTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ReadinessMetric extends StatelessWidget {
  const _ReadinessMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.stageSurface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            value,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
