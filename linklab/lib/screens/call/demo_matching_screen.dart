import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_help_request_tracker.dart';
import '../../services/demo_call_service.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'demo_call_screen.dart';

/// 演示版匹配等待页面
/// 视觉收口为参考图风格，但仍保持 Demo 主线 4 秒内进入通话。
class DemoMatchingScreen extends StatefulWidget {
  const DemoMatchingScreen({super.key});

  @override
  State<DemoMatchingScreen> createState() => _DemoMatchingScreenState();
}

class _DemoMatchingScreenState extends State<DemoMatchingScreen>
    with TickerProviderStateMixin {
  static Color get _matchBackground => AppTheme.stageBackground;
  static Color get _matchSurface => AppTheme.stageSurface;
  static Color get _matchSurfaceStrong => AppTheme.stageSurfaceStrong;
  static Color get _matchBorder => AppTheme.stageBorder;
  static Color get _matchGlow => AppTheme.stageAccent;
  static Color get _matchGlowSoft => AppTheme.stageAccentLight;
  static Color get _matchTextPrimary => AppTheme.stageTextPrimary;
  static Color get _matchTextSecondary => AppTheme.stageTextSecondary;

  final DemoMatchingService _matchingService = DemoMatchingService();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.985, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
    _startMatching();
  }

  Future<void> _startMatching() async {
    await DemoHelpRequestTracker.ensureMatchingRequest(intent: '连接真人志愿者获取帮助');
    await _matchingService.startMatching();

    if (mounted) {
      replaceWithDemoStageRoute(context, page: const DemoCallScreen());
    }
  }

  Future<void> _cancelMatching() async {
    _matchingService.cancelMatching();
    await DemoHelpRequestTracker.markCancelled(reason: '用户取消匹配');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  List<_MatchCandidate> _buildCandidates() {
    final volunteers = demoVolunteers;
    return [
      _MatchCandidate(
        volunteer: volunteers[0],
        title: '距离：2.3公里',
        subtitle: 'WGG AAA',
        badge: _matchingService.elapsedSeconds >= 1 ? '优先推荐' : '检索中',
        isHighlighted: true,
        indicatorIcon: Icons.keyboard_arrow_up_rounded,
      ),
      _MatchCandidate(
        volunteer: volunteers[1],
        title: '技能标签：${volunteers[1].skills.join(' / ')}',
        subtitle: '预计到达时间：15分钟',
        badge: '技能匹配',
        showPulseDot: true,
      ),
      _MatchCandidate(
        volunteer: volunteers[2],
        title: '预计到达时间：15分钟',
        subtitle: 'WGG AAA',
        badge: '医疗支持',
        indicatorIcon: Icons.keyboard_arrow_down_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([_matchingService, session]),
      builder: (context, _) {
        final progress = (_matchingService.elapsedSeconds / 4).clamp(0.08, 1.0);
        final candidates = _buildCandidates();

        return Scaffold(
          backgroundColor: _matchBackground,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.stageBackgroundSoft,
                  _matchBackground,
                  AppTheme.stageBackgroundSoft.withValues(alpha: 0.82),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    child: Column(
                      children: [
                        _MatchingHeader(onBack: _cancelMatching),
                        const SizedBox(height: 14),
                        _NeoProgressBar(progress: progress),
                        const SizedBox(height: 18),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              DemoReveal(
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: _CountdownDial(
                                    progress: progress,
                                    statusText: _matchingService.statusText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...List.generate(candidates.length, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DemoReveal(
                                    delay: Duration(
                                      milliseconds: 80 + (index * 45),
                                    ),
                                    child: _MatchCandidateCard(
                                      candidate: candidates[index],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          button: true,
                          label: '取消匹配',
                          hint: '双击取消当前志愿者匹配流程',
                          child: InkWell(
                            onTap: _cancelMatching,
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                              width: double.infinity,
                              height: 66,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _matchGlow,
                                    AppTheme.stageAccentLight,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: _matchGlow.withValues(alpha: 0.22),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '取消匹配',
                                  style: TextStyle(
                                    color: AppTheme.isDayStageMode
                                        ? AppTheme.stageBackground
                                        : const Color(0xFF182008),
                                    fontSize: AppTheme.fontSizeLarge,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _matchingService.cancelMatching();
    _pulseController.dispose();
    super.dispose();
  }
}

class _MatchingHeader extends StatelessWidget {
  const _MatchingHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: '返回',
          hint: '双击取消匹配并返回上一页',
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: AppTheme.minTouchTarget,
              height: AppTheme.minTouchTarget,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _DemoMatchingScreenState._matchTextPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AccessibleText(
            '正在为你匹配最合适的志愿者...',
            style: TextStyle(
              color: _DemoMatchingScreenState._matchTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: AppTheme.isDayStageMode ? '切换到深夜模式' : '切换到日间模式',
          hint: '双击切换当前界面配色模式',
          child: InkWell(
            onTap: () {
              AppSessionService.instance.toggleStageMode();
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: AppTheme.minTouchTarget,
              height: AppTheme.minTouchTarget,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                AppTheme.isDayStageMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode,
                color: _DemoMatchingScreenState._matchGlow,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeoProgressBar extends StatelessWidget {
  const _NeoProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _DemoMatchingScreenState._matchGlow,
                  _DemoMatchingScreenState._matchGlowSoft,
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _DemoMatchingScreenState._matchGlow.withValues(
                    alpha: 0.34,
                  ),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownDial extends StatelessWidget {
  const _CountdownDial({required this.progress, required this.statusText});

  final double progress;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '匹配进度仪表盘，当前状态：$statusText',
      child: Column(
        children: [
          SizedBox(
            width: 248,
            height: 248,
            child: CustomPaint(
              painter: _MatchDialPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '30',
                      style: TextStyle(
                        color: _DemoMatchingScreenState._matchTextPrimary,
                        fontSize: 58,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '秒',
                      style: TextStyle(
                        color: _DemoMatchingScreenState._matchTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AccessibleText(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _DemoMatchingScreenState._matchTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchDialPainter extends CustomPainter {
  const _MatchDialPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 22;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi * 0.82;
    const totalSweep = math.pi * 1.66;
    final activeSweep = totalSweep * (0.72 + (progress * 0.24));
    final knobAngle = startAngle + activeSweep;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          _DemoMatchingScreenState._matchGlow,
          _DemoMatchingScreenState._matchGlowSoft,
          _DemoMatchingScreenState._matchGlow,
        ],
      ).createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          _DemoMatchingScreenState._matchGlow,
          _DemoMatchingScreenState._matchGlowSoft,
          _DemoMatchingScreenState._matchGlowSoft.withValues(alpha: 0.82),
        ],
      ).createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(ringRect, startAngle, totalSweep, false, trackPaint);
    canvas.drawArc(ringRect, startAngle, activeSweep, false, glowPaint);
    canvas.drawArc(ringRect, startAngle, activeSweep, false, ringPaint);

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 28; i++) {
      final angle = startAngle + (totalSweep * (i / 27));
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 18),
        center.dy + math.sin(angle) * (radius - 18),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 30),
        center.dy + math.sin(angle) * (radius - 30),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final knobCenter = Offset(
      center.dx + math.cos(knobAngle) * radius,
      center.dy + math.sin(knobAngle) * radius,
    );

    final knobGlow = Paint()
      ..color = _DemoMatchingScreenState._matchGlow.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(knobCenter, 10, knobGlow);

    final knobPaint = Paint()..color = _DemoMatchingScreenState._matchGlow;
    final knobInner = Paint()..color = const Color(0xFF435800);
    canvas.drawCircle(knobCenter, 8, knobPaint);
    canvas.drawCircle(knobCenter, 4, knobInner);
  }

  @override
  bool shouldRepaint(covariant _MatchDialPainter oldDelegate) {
    return true;
  }
}

class _MatchCandidate {
  const _MatchCandidate({
    required this.volunteer,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.isHighlighted = false,
    this.showPulseDot = false,
    this.indicatorIcon,
  });

  final DemoVolunteer volunteer;
  final String title;
  final String subtitle;
  final String badge;
  final bool isHighlighted;
  final bool showPulseDot;
  final IconData? indicatorIcon;
}

class _MatchCandidateCard extends StatelessWidget {
  const _MatchCandidateCard({required this.candidate});

  final _MatchCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '候选志愿者 ${candidate.volunteer.name}，${candidate.title}，${candidate.subtitle}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DemoMatchingScreenState._matchSurfaceStrong.withValues(
            alpha: 0.9,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: candidate.isHighlighted
                ? _DemoMatchingScreenState._matchGlow.withValues(alpha: 0.28)
                : _DemoMatchingScreenState._matchBorder.withValues(alpha: 0.82),
          ),
          boxShadow: [
            if (candidate.isHighlighted)
              BoxShadow(
                color: _DemoMatchingScreenState._matchGlow.withValues(
                  alpha: 0.12,
                ),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _DemoMatchingScreenState._matchGlow,
                      width: 2.4,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _DemoMatchingScreenState._matchBorder,
                        _DemoMatchingScreenState._matchSurface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      candidate.volunteer.name.characters.first,
                      style: TextStyle(
                        color: _DemoMatchingScreenState._matchTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (candidate.showPulseDot)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _DemoMatchingScreenState._matchGlow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _DemoMatchingScreenState._matchGlow
                                .withValues(alpha: 0.32),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    candidate.title,
                    style: TextStyle(
                      color: _DemoMatchingScreenState._matchTextPrimary,
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AccessibleText(
                    candidate.subtitle,
                    style: TextStyle(
                      color: _DemoMatchingScreenState._matchTextSecondary,
                      fontSize: AppTheme.fontSizeNormal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DemoPill(
                    label: candidate.badge,
                    color: _DemoMatchingScreenState._matchGlow,
                    backgroundColor: _DemoMatchingScreenState._matchGlow
                        .withValues(alpha: 0.12),
                  ),
                ],
              ),
            ),
            if (candidate.indicatorIcon != null) ...[
              const SizedBox(width: 12),
              Icon(
                candidate.indicatorIcon,
                color: _DemoMatchingScreenState._matchGlow,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
