import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/demo_call_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../home/main_screen.dart';

/// 演示版通话评价页面
class DemoCallRatingScreen extends StatefulWidget {
  const DemoCallRatingScreen({
    super.key,
    required this.volunteer,
    required this.duration,
  });

  final DemoVolunteer volunteer;
  final Duration duration;

  @override
  State<DemoCallRatingScreen> createState() => _DemoCallRatingScreenState();
}

class _DemoCallRatingScreenState extends State<DemoCallRatingScreen> {
  final DemoCallService _callService = DemoCallService();
  final TextEditingController _feedbackController = TextEditingController();

  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _positiveTags = ['耐心细致', '专业高效', '态度友好', '解决问题', '沟通顺畅'];
  final List<String> _negativeTags = ['沟通困难', '未能解决', '态度冷淡', '网络卡顿', '声音不清'];

  Future<void> _submitRating() async {
    if (_rating == 0) {
      showDemoStageSnackBar(
        context,
        message: '请给出评分',
        icon: Icons.star_outline,
        accentColor: AppTheme.stageWarning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _callService.submitSeekerRating(
      rating: _rating,
      tags: _selectedTags,
      feedback: _feedbackController.text.trim(),
    );

    if (mounted) {
      showDemoStageSnackBar(
        context,
        message: _rating >= 4 ? '感谢您的评价，已同步到帮助档案和常用志愿者。' : '感谢您的评价，已同步到帮助档案。',
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
          title: '评价本次帮助',
          subtitle: '评分会回写帮助档案，并影响常用志愿者列表',
          onBackPressed: _skipRating,
          actions: [
            TextButton(
              onPressed: _skipRating,
              child: Text(
                '跳过',
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
                '通话时长: ${_formatDuration(widget.duration)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Center(
                child: DemoPill(
                  label: '4 星及以上会加入“常用志愿者”',
                  icon: Icons.workspace_premium_outlined,
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
                        '为这次帮助评分',
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
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: index < _rating
                                  ? AppTheme.stageAccent
                                  : AppTheme.stageTextHint,
                              size: 42,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      AccessibleText(
                        _rating > 0 ? _getRatingText(_rating) : '点击星星评分',
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
                        '选择标签（可多选）',
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
                    hintText: '写下您的具体反馈（可选）',
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
                      : Text(
                          '提交评价',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
        return '非常不满意';
      case 2:
        return '不满意';
      case 3:
        return '一般';
      case 4:
        return '满意';
      case 5:
        return '非常满意';
      default:
        return '';
    }
  }

  void _returnToMain() {
    _callService.reset();
    pushAndRemoveUntilDemoStageRoute(
      context,
      page: const MainScreen(),
      predicate: (route) => false,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
