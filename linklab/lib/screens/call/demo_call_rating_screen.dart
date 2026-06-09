import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/demo_help_request_flow_provider.dart';
import '../../providers/demo_services_provider.dart';
import '../../services/demo_call_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../home/main_screen.dart';

/// 演示版通話評價頁面
class DemoCallRatingScreen extends ConsumerStatefulWidget {
  const DemoCallRatingScreen({
    super.key,
    required this.volunteer,
    required this.duration,
  });

  final DemoVolunteer volunteer;
  final Duration duration;

  @override
  ConsumerState<DemoCallRatingScreen> createState() =>
      _DemoCallRatingScreenState();
}

class _DemoCallRatingScreenState extends ConsumerState<DemoCallRatingScreen> {
  late final DemoCallService _callService;
  final TextEditingController _feedbackController = TextEditingController();

  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _positiveTags = ['耐心細緻', '專業高效', '態度友好', '解決問題', '溝通順暢'];
  final List<String> _negativeTags = ['溝通困難', '未能解決', '態度冷淡', '網絡卡頓', '聲音不清'];

  @override
  void initState() {
    super.initState();
    _callService = ref.read(demoCallServiceProvider);
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      showDemoStageSnackBar(
        context,
        message: '請給出評分',
        icon: Icons.star_outline,
        accentColor: AppTheme.stageWarning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .markCompleted(
          durationSeconds: widget.duration.inSeconds,
          seekerRating: _rating,
          feedback: _feedbackController.text.trim(),
          ratingTags: List<String>.unmodifiable(_selectedTags),
        );

    if (mounted) {
      showDemoStageSnackBar(
        context,
        message: '感謝您的評價，已寫入本地 Demo 幫助回看。',
        icon: Icons.favorite_border,
        accentColor: AppTheme.stageSuccess,
      );
      _returnToMain();
    }
  }

  void _skipRating() {
    _returnToMain();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes分$seconds秒';
    }
    return '$seconds秒';
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '幫助已完成',
          subtitle: '當前爲 Demo 記錄，不代表真實積分或真實志願者檔案',
          onBackPressed: _skipRating,
          actions: [
            TextButton(
              onPressed: _skipRating,
              child: Text(
                '跳過',
                style: TextStyle(color: AppTheme.stageTextSecondary),
              ),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            children: [
              DemoReveal(
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppTheme.stageAccentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.volunteer.name[0],
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.stageBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              AccessibleText(
                widget.volunteer.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              AccessibleText(
                '本次幫助類型: ${widget.volunteer.skills.take(2).join(' / ')}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              AccessibleText(
                '通話時長: ${_formatDuration(widget.duration)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleText(
                '感謝你完成本次互助。你可以快速評分後返回首頁，或查看本地結果回看。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeNormal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Center(
                child: DemoPill(
                  label: 'Demo 記錄，不產生真實積分',
                  icon: Icons.info_outline,
                  color: AppTheme.stageAccent,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              DemoReveal(
                delay: const Duration(milliseconds: 100),
                child: DemoSurfaceCard(
                  child: Column(
                    children: [
                      AccessibleText(
                        '爲這次幫助評分',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () =>
                                setState(() => _rating = index + 1),
                            tooltip: '評分${index + 1}星',
                            icon: LinkableMaterialIcon(
                              icon: index < _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: index < _rating
                                  ? AppTheme.stageAccent
                                  : AppTheme.stageTextHint,
                              size: 42,
                              semanticLabel: '評分${index + 1}星',
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      AccessibleText(
                        _rating > 0 ? _getRatingText(_rating) : '點擊星星評分',
                        style: TextStyle(
                          color: _rating > 0
                              ? AppTheme.stageAccent
                              : AppTheme.stageTextHint,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: AppTheme.spacingL),
                DemoSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '選擇標籤（可多選）',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: (_rating >= 4 ? _positiveTags : _negativeTags)
                            .map((tag) => _buildTagChip(tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingL),
              DemoSurfaceCard(
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: TextStyle(color: AppTheme.stageTextPrimary),
                  decoration: InputDecoration(
                    hintText: '寫下您的具體反饋（可選）',
                    hintStyle: TextStyle(color: AppTheme.stageTextHint),
                    filled: true,
                    fillColor: AppTheme.stageSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppTheme.stageAccent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.stageAccent,
                    foregroundColor: AppTheme.stageBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.stageBackground,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '提交評價',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDemoStageSnackBar(
                      context,
                      message: '本地 Demo 已保留幫助完成記錄，可在首頁最近求助中回看。',
                      icon: Icons.history_outlined,
                      accentColor: AppTheme.stageInfo,
                    );
                  },
                  icon: const LinkableMaterialIcon(
                    icon: Icons.history_outlined,
                    semanticLabel: '查看幫助檔案',
                  ),
                  label: const Text('查看幫助檔案 / 結果回看'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.stageTextPrimary,
                    side: BorderSide(color: AppTheme.stageBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: _skipRating,
                  child: const Text('返回首頁'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
      },
      backgroundColor: AppTheme.stageSurface,
      selectedColor: AppTheme.stageAccent.withValues(alpha: 0.22),
      side: BorderSide(
        color: isSelected
            ? AppTheme.stageAccent.withValues(alpha: 0.4)
            : AppTheme.stageBorder.withValues(alpha: 0.82),
      ),
      checkmarkColor: AppTheme.stageAccent,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.stageTextPrimary
            : AppTheme.stageTextSecondary,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '非常不滿意';
      case 2:
        return '不滿意';
      case 3:
        return '一般';
      case 4:
        return '滿意';
      case 5:
        return '非常滿意';
      default:
        return '';
    }
  }

  void _returnToMain() {
    _callService.reset();
    pushAndRemoveUntilDemoStageRoute(
      context,
      page: const MainScreen(startInSeekerArea: true),
      predicate: (route) => false,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
