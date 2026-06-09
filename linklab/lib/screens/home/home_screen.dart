import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_config.dart';
import '../../providers/real_database_provider.dart';
import '../../services/real_database_repository.dart';
import '../../providers/demo_flow_navigator.dart';
import '../../screens/real/real_help_request_screen.dart';
import '../../screens/real/real_volunteer_profile_screen.dart';
import '../../widgets/demo/demo_routes.dart';
import 'pending_help_screen.dart';

/// 登錄後的首頁。
///
/// 競賽 Demo 默認只保留兩個首屏選擇：求助者進入 AI 第一響應，
/// 志願者進入待響應求助演示列表。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onSeekerSelected,
    this.onVolunteerSelected,
  });

  final VoidCallback? onSeekerSelected;
  final VoidCallback? onVolunteerSelected;

  static const _backgroundGradient = LinearGradient(
    colors: [Color(0xFFD8FF00), Color(0xFF68FF4F), Color(0xFF4DEED4)],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realDatabaseEnabled = FeatureFlags.enableDatabaseSync;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF54EFD2),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF68FF4F),
        body: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: 'LinkAble 首頁，選擇求助者或志願者入口',
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: _backgroundGradient),
              ),
              const CustomPaint(
                painter: _GridPainter(
                  color: Color(0x18000000),
                  step: 12,
                  strokeWidth: 0.55,
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final isLargeText = textScale > 1.35;
                    final isCompactHeight = constraints.maxHeight < 780;
                    final horizontalPadding = math.max(
                      20.0,
                      math.min(32.0, constraints.maxWidth * 0.06),
                    );
                    final logoSize = math.min(
                      constraints.maxWidth * (isLargeText ? 0.64 : 0.88),
                      isCompactHeight || isLargeText ? 302.0 : 390.0,
                    );

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompactHeight ? 16 : 22,
                        horizontalPadding,
                        30,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - (isCompactHeight ? 46 : 52),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: _BrandPill()),
                              SizedBox(height: isCompactHeight ? 26 : 38),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: const Text(
                                    '讓幫助真實發生\n連接每一次需要',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Color(0xFF050A03),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      height: 1.22,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompactHeight ? 24 : 34),
                              Center(child: _HandMark(size: logoSize)),
                              SizedBox(height: isCompactHeight ? 18 : 28),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _RoleLabel(label: '求助者'),
                                    _RoleLabel(label: '志願者'),
                                  ],
                                ),
                              ),
                              if (realDatabaseEnabled) ...[
                                SizedBox(height: isCompactHeight ? 14 : 18),
                                const _RealHomeSummaryCard(),
                              ],
                              if (isLargeText)
                                SizedBox(height: isCompactHeight ? 28 : 38)
                              else
                                const Spacer(),
                              _LandingActionButton(
                                title: '我需要出行幫助',
                                subtitle: '呼叫企業或志願者',
                                semanticLabel: realDatabaseEnabled
                                    ? '我需要出行幫助，創建真實求助記錄'
                                    : '我需要出行幫助，進入 AI 求助主線',
                                hint: realDatabaseEnabled
                                    ? '雙擊後寫入當前賬號自己的 help_requests 記錄'
                                    : '雙擊後由 AI 先判斷需求，必要時轉接志願者',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  if (onSeekerSelected != null) {
                                    onSeekerSelected!();
                                    return;
                                  }
                                  if (realDatabaseEnabled) {
                                    pushDemoStageRoute(
                                      context,
                                      page: const RealHelpRequestScreen(),
                                    );
                                    return;
                                  }
                                  DemoFlowNavigator.onHomeBigButtonPressed(
                                    ref,
                                    context,
                                  );
                                },
                                onLongPress: () {
                                  HapticFeedback.heavyImpact();
                                  DemoFlowNavigator.onSOSButtonPressed(
                                    ref,
                                    context,
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              _LandingActionButton(
                                title: '我想成爲志願者',
                                subtitle: '分享我的成就',
                                semanticLabel: realDatabaseEnabled
                                    ? '我想成爲志願者，創建真實志願者資料'
                                    : '我想成爲志願者，查看待幫助列表',
                                hint: realDatabaseEnabled
                                    ? '雙擊後寫入當前賬號自己的 volunteer_profiles 記錄'
                                    : '雙擊進入志願者待響應求助演示',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  if (onVolunteerSelected != null) {
                                    onVolunteerSelected!();
                                    return;
                                  }
                                  if (realDatabaseEnabled) {
                                    pushDemoStageRoute(
                                      context,
                                      page: const RealVolunteerProfileScreen(),
                                    );
                                    return;
                                  }
                                  pushDemoStageRoute(
                                    context,
                                    page: const PendingHelpScreen(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RealHomeSummaryCard extends ConsumerWidget {
  const _RealHomeSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(realHomeSummaryProvider);
    return summary.when(
      data: (data) => _RealHomeSummaryDataCard(summary: data),
      loading: () => const _RealHomeCardShell(
        semanticLabel: '正在讀取 Supabase 當前用戶數據',
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('正在讀取真實數據')),
          ],
        ),
      ),
      error: (_, _) => const _RealHomeCardShell(
        semanticLabel: '真實數據讀取失敗',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFC82432)),
            SizedBox(width: 10),
            Expanded(child: Text('真實數據讀取失敗，請確認 Phase-3 SQL 已執行')),
          ],
        ),
      ),
    );
  }
}

class _RealHomeSummaryDataCard extends StatelessWidget {
  const _RealHomeSummaryDataCard({required this.summary});

  final RealHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final profileName = summary.profile?.effectiveDisplayName ?? '未創建資料';
    final volunteerStatus = summary.hasVolunteerProfile ? '已創建' : '未創建';

    return _RealHomeCardShell(
      semanticLabel:
          '已讀取 Supabase 當前用戶數據，資料 $profileName，求助記錄 ${summary.helpRequestCount} 條，志願者資料 $volunteerStatus',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RealMode 數據',
            style: TextStyle(
              color: Color(0xFF050A03),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '資料：$profileName\n求助記錄：${summary.helpRequestCount} 條\n志願者資料：$volunteerStatus',
            style: const TextStyle(
              color: Color(0xFF050A03),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RealHomeCardShell extends StatelessWidget {
  const _RealHomeCardShell({required this.semanticLabel, required this.child});

  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Color(0xFF050A03),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LinkAble 品牌標識',
      image: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'LinkAble',
          style: TextStyle(
            color: Color(0xFF151515),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HandMark extends StatelessWidget {
  const _HandMark({required this.size});

  static const _assetPath = 'assets/brand/link_hand.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'LinkAble 白色手形標誌，象徵連接每一次需要',
      child: SvgPicture.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF050A03),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF050A03),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingActionButton extends StatelessWidget {
  const _LandingActionButton({
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.hint,
    required this.onTap,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String semanticLabel;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(56);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semanticLabel,
      hint: onLongPress == null ? hint : '$hint；長按可進入緊急求助',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA56BFF), Color(0xFF9144F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5E16C9).withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: CustomPaint(
                foregroundPainter: const _GridPainter(
                  color: Color(0x18FFFFFF),
                  step: 10,
                  strokeWidth: 0.5,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 108),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.color,
    required this.step,
    required this.strokeWidth,
  });

  final Color color;
  final double step;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.step != step ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
