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
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../security/location_sharing_screen.dart';
import 'demo_call_screen.dart';

const _sosPurpleBackground = LinearGradient(
  colors: [Color(0xFFF5E9FF), Color(0xFFE2C7FF), Color(0xFFC69AFF)],
  stops: [0.0, 0.48, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _sosPurplePanel = Color(0xF7F7EEFF);
const _sosPurplePanelStrong = Color(0xFAF1E4FF);
const _sosPurpleBorder = Color(0x668B42F6);

/// 演示版SOS緊急求助頁面
/// 簡化版：模擬SOS流程，固定5秒匹配成功
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

    // Facade 優先：調用 SosFacade.startUndoWindow
    try {
      final facade = ref.read(sosFacadeProvider);
      final result = await facade.startUndoWindow();
      if (result.success) {
        // Facade 成功，繼續走 demo 流程驅動 UI
      }
    } catch (_) {
      // Facade 異常，降級到舊流程
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

    // Facade 優先：調用 SosFacade.broadcastToNearby 和 notifyEmergencyContacts
    try {
      final facade = ref.read(sosFacadeProvider);
      final broadcastResult = await facade.broadcastToNearby();
      if (broadcastResult.success) {
        // Facade 廣播成功
      }
      await facade.notifyEmergencyContacts();
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    if (!mounted) return;

    // Fallback：原有聯繫人通知邏輯
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

    if (!mounted) return;

    // Fallback：原有 demo flow
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(intent: 'SOS緊急求助', type: 'sos', urgency: 'emergency');

    if (!mounted) return;

    await _sosService.triggerSOS();
  }

  Future<void> _cancelPendingSOS() async {
    _undoWindowTimer?.cancel();
    setState(() {
      _isUndoWindowActive = false;
      _undoCountdownSeconds = _undoWindowSeconds;
    });

    // Facade 優先：調用 SosFacade.cancelSOS
    try {
      final facade = ref.read(sosFacadeProvider);
      await facade.cancelSOS();
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    // Fallback：原有 demo flow
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .markCancelled(reason: 'SOS 誤觸撤銷');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosService,
      builder: (context, child) {
        final isActive = _sosService.isActive;
        final isEmergencyFlowActive = isActive || _isUndoWindowActive;

        return _SosPageShell(
          title: isEmergencyFlowActive ? 'SOS 緊急求助進行中' : 'SOS 緊急求助',
          subtitle: isEmergencyFlowActive
              ? '誤觸撤銷窗口與 Mock 廣播進度均可見'
              : '保留 10 秒誤觸撤銷窗口，支持本地可復現演示',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            children: [
              if (isEmergencyFlowActive)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.stageAccent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const _SolidSosBadge(size: 28),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: AccessibleText(
                          'SOS緊急求助進行中',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AccessibleText(
                        _isUndoWindowActive
                            ? '撤銷 ${_undoCountdownSeconds}s'
                            : '${(_sosService.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_sosService.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                        label: '10 秒撤銷窗口',
                        color: AppTheme.stageAccent,
                      ),
                      DemoPill(
                        icon: Icons.campaign_outlined,
                        label: 'Mock 廣播演示',
                        color: AppTheme.stageAccent,
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
                            color: isEmergencyFlowActive
                                ? AppTheme.stageAccent
                                : null,
                            gradient: isEmergencyFlowActive
                                ? null
                                : AppTheme.stageAccentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.stageAccent.withValues(
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
                                    backgroundColor: AppTheme.stageAccent
                                        .withValues(alpha: 0.22),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.stageTextPrimary,
                                    ),
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEmergencyFlowActive)
                                    const Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    )
                                  else
                                    const _SolidSosBadge(
                                      size: 64,
                                      semanticLabel: 'SOS緊急求助',
                                    ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    isEmergencyFlowActive ? '求助中' : 'SOS',
                                    style: TextStyle(
                                      color: isEmergencyFlowActive
                                          ? Colors.white
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
                    ? '已進入 10 秒誤觸撤銷窗口，倒計時結束後纔會廣播給志願者和聯繫人。'
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
                    ? '評審可以直接看到廣播中、聯繫人通知和撤銷窗口的狀態切換。'
                    : '長按按鈕 3 秒即可進入緊急求助流程。',
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
                    label: '誤觸撤銷剩餘 $_undoCountdownSeconds 秒',
                    icon: Icons.timer_outlined,
                    color: AppTheme.stageAccent,
                  ),
                ),
              ] else if (isActive) ...[
                const SizedBox(height: AppTheme.spacingL),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: [
                    DemoPill(
                      icon: Icons.campaign_outlined,
                      label: '5km 範圍內廣播',
                      color: AppTheme.stageAccent,
                    ),
                    DemoPill(
                      icon: Icons.schedule_outlined,
                      label: '已等待: ${_sosService.elapsedSeconds}秒',
                      color: AppTheme.stageAccent,
                      backgroundColor: AppTheme.stageAccent.withValues(
                        alpha: 0.14,
                      ),
                    ),
                  ],
                ),
                if (_sosService.responderCount > 0) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  Center(
                    child: DemoPill(
                      label: '${_sosService.responderCount}位志願者正在趕來',
                      icon: Icons.favorite_rounded,
                      color: AppTheme.stageAccent,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppTheme.spacingXL),
              if (!isEmergencyFlowActive)
                DemoSurfaceCard(
                  color: _sosPurplePanelStrong,
                  borderColor: _sosPurpleBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '觸發前準備',
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
                                        ? '精確'
                                        : '大致')
                                  : '關閉',
                              color: _safetySettings.autoShareLocation
                                  ? AppTheme.stageAccent
                                  : AppTheme.stageAccent,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _ReadinessMetric(
                              label: '聯繫人',
                              value: '${_emergencyContacts.length} 位',
                              color: _emergencyContacts.isEmpty
                                  ? AppTheme.stageAccent
                                  : AppTheme.stageAccent,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _ReadinessMetric(
                              label: '觸發',
                              value: '長按 3 秒',
                              color: AppTheme.stageAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    semanticLabel: '完善位置共享設置',
                  ),
                  label: Text(
                    '完善位置共享設置',
                    style: TextStyle(color: AppTheme.stageAccent),
                  ),
                ),
              ],
              if (!isEmergencyFlowActive) ...[
                const SizedBox(height: AppTheme.spacingL),
                DemoSurfaceCard(
                  color: _sosPurplePanel,
                  borderColor: _sosPurpleBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '其他觸發方式',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTriggerHint('連按電源鍵3次', '3秒內快速按3次'),
                      if (_safetySettings.enableVoiceTrigger)
                        _buildTriggerHint('語音觸發', '說出“緊急求助”等關鍵詞'),
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
    const actionTextStyle = TextStyle(
      fontSize: AppTheme.fontSizeNormal,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );

    if (_isUndoWindowActive) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelPendingSOS,
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.cancel,
                size: 24,
                semanticLabel: '撤銷誤觸',
              ),
              label: const Text('撤銷誤觸'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.stageTextPrimary,
                side: BorderSide(
                  color: AppTheme.stageTextPrimary.withValues(alpha: 0.18),
                ),
                minimumSize: const Size(0, 58),
                textStyle: actionTextStyle,
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
                semanticLabel: '立即發送',
              ),
              label: const Text('立即發送'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                minimumSize: const Size(0, 58),
                textStyle: actionTextStyle,
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
                // Facade 優先：調用 SosFacade.cancelSOS（安全了 = 結束 SOS）
                try {
                  final facade = ref.read(sosFacadeProvider);
                  await facade.cancelSOS();
                } catch (_) {
                  // Facade 異常，降級到舊流程
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
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                minimumSize: const Size(0, 58),
                textStyle: actionTextStyle,
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
                // Facade 優先：調用 SosFacade.cancelSOS
                try {
                  final facade = ref.read(sosFacadeProvider);
                  await facade.cancelSOS();
                } catch (_) {
                  // Facade 異常，降級到舊流程
                }
                _sosService.cancelSOS();
                await ref
                    .read(demoHelpRequestFlowProvider.notifier)
                    .markCancelled(reason: '用戶取消SOS');
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
                textStyle: actionTextStyle,
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
        ? '未自動共享位置'
        : (_safetySettings.usePreciseLocation ? '精確位置' : '大致位置');

    return DemoSurfaceCard(
      color: isActive
          ? AppTheme.stageAccent.withValues(alpha: 0.14)
          : _sosPurplePanelStrong,
      borderColor: isActive
          ? AppTheme.stageAccent.withValues(alpha: 0.26)
          : _sosPurpleBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            shouldNotifyContacts
                ? '安全通知已就緒'
                : (hasContacts ? '聯繫人通知已關閉' : '尚未設置緊急聯繫人'),
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontSizeNormal,
            ),
          ),
          const SizedBox(height: 6),
          AccessibleText(
            shouldNotifyContacts
                ? '本次 SOS 會以$locationLabel同步通知 ${_emergencyContacts.length} 位聯繫人：$names'
                : _safetySettings.shareWithEmergencyContacts
                ? '當前仍會演示志願者廣播流程，但聯繫人通知需要先在“我的 > 緊急聯繫人”中完成設置。位置狀態：$locationLabel。'
                : '本次 SOS 僅展示志願者廣播流程。位置狀態：$locationLabel。',
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
                  ? '可在“我的 > 緊急聯繫人”中添加，最多 3 位。'
                  : '可在“位置共享”中重新開啓聯繫人同步。',
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
      color: _sosPurplePanel,
      borderColor: _sosPurpleBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            isActive ? 'SOS 當前進度' : 'SOS 將執行的步驟',
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
        AppTheme.stageAccent,
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
            ? '同步${_safetySettings.usePreciseLocation ? '精確' : '大致'}位置'
            : '跳過自動位置共享',
        description: _safetySettings.autoShareLocation
            ? '演示位置摘要會進入 SOS 鏈路。'
            : '本次流程只展示基礎求助，不附帶位置。',
        state: _safetySettings.autoShareLocation
            ? (isActive ? _SafetyStepState.completed : _SafetyStepState.pending)
            : _SafetyStepState.skipped,
      ),
      _SafetyStep(
        title: shouldNotifyContacts ? '通知緊急聯繫人' : '跳過聯繫人通知',
        description: shouldNotifyContacts
            ? '將同步通知 ${_emergencyContacts.length} 位聯繫人。'
            : _safetySettings.shareWithEmergencyContacts
            ? '當前沒有可通知的聯繫人。'
            : '你已在設置中關閉聯繫人同步。',
        state: shouldNotifyContacts
            ? (isActive ? _SafetyStepState.completed : _SafetyStepState.pending)
            : _SafetyStepState.skipped,
      ),
      _SafetyStep(
        title: '向附近志願者廣播',
        description: hasResponse
            ? '已有 ${_sosService.responderCount} 位志願者響應。'
            : '演示版默認在 5km 範圍內廣播。',
        state: !isActive
            ? _SafetyStepState.pending
            : (hasResponse
                  ? _SafetyStepState.completed
                  : _SafetyStepState.active),
      ),
      _SafetyStep(
        title: '建立演示響應',
        description: hasResponse ? '即將進入通話演示。' : '正在等待志願者接入。',
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
      return '用戶未開啓自動位置共享';
    }

    return _safetySettings.usePreciseLocation ? '演示位置：上海市靜安區' : '演示位置：上海市靜安區附近';
  }

  String _buildEmergencyNotificationMessage() {
    final location = _buildLocationSummary();
    return '【LinkLab緊急求助】用戶已觸發 SOS，$location，請儘快聯繫確認安全。';
  }

  Widget _buildTriggerHint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const LinkableSvgIcon(
            icon: LinkableIconName.emergencyDetect,
            size: 18,
            semanticLabel: '緊急檢測提示',
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

class _SosPageShell extends StatelessWidget {
  const _SosPageShell({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bottomBar,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compactPhone = mediaQuery.size.width < 360;
    final horizontalPadding = compactPhone
        ? AppTheme.spacingM
        : AppTheme.spacingL;
    final bottomPadding = compactPhone ? AppTheme.spacingM : AppTheme.spacingL;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9FF),
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _sosPurpleBackground),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppTheme.spacingS,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Column(
                  children: [
                    _SosHeader(title: title, subtitle: subtitle),
                    const SizedBox(height: AppTheme.spacingM),
                    Expanded(child: ClipRect(child: body)),
                    if (bottomBar is! SizedBox) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      bottomBar,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SosHeader extends StatelessWidget {
  const _SosHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: canPop ? '返回' : '返回不可用',
          hint: canPop ? '雙擊返回上一頁' : '當前已經是第一頁',
          child: InkWell(
            onTap: canPop ? () => Navigator.of(context).pop() : null,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: AppTheme.minTouchTarget + 8,
              height: AppTheme.minTouchTarget + 8,
              decoration: BoxDecoration(
                gradient: canPop ? AppTheme.stageAccentGradient : null,
                color: canPop
                    ? null
                    : AppTheme.stageAccent.withValues(alpha: 0.24),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.stageBackground.withValues(alpha: 0.56),
                ),
              ),
              child: const LinkableSvgIcon(
                icon: LinkableIconName.back,
                size: 44,
                semanticLabel: '返回',
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  isHeader: true,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                AccessibleText(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _SafetyStepState { pending, active, completed, skipped }

class _SolidSosBadge extends StatelessWidget {
  const _SolidSosBadge({required this.size, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel ?? 'SOS緊急求助',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.stageAccent,
            shape: BoxShape.circle,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SOS',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        color: _sosPurplePanel,
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
