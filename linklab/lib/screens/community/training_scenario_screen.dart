import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../services/app_session_service.dart';
import '../../services/community/newbie_village_service.dart';
import '../../widgets/accessible/index.dart';

/// 训练场景页面
class TrainingScenarioScreen extends StatefulWidget {
  const TrainingScenarioScreen({
    super.key,
    required this.scenario,
  });

  final TrainingScenario scenario;

  @override
  State<TrainingScenarioScreen> createState() => _TrainingScenarioScreenState();
}

class _TrainingScenarioScreenState extends State<TrainingScenarioScreen> {
  final _newbieService = NewbieVillageService();
  int _currentStep = 0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: widget.scenario.title,
      body: _isCompleted ? _buildCompletionView() : _buildScenarioView(),
    );
  }

  Widget _buildScenarioView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 场景类型标签
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: _getTypeColor(widget.scenario.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: AccessibleText(
              ScenarioType.getLabel(widget.scenario.type),
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: _getTypeColor(widget.scenario.type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          // 场景图片
          AccessibleImage.asset(
            assetPath: widget.scenario.imageUrl,
            semanticLabel: '${widget.scenario.title}示意图',
            hint: '用于辅助理解当前训练场景的示意图片',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            fallbackIcon: _getTypeIcon(widget.scenario.type),
            fallbackText: '${ScenarioType.getLabel(widget.scenario.type)}场景暂无示意图',
          ),
          const SizedBox(height: AppTheme.spacingL),
          // 场景描述
          const AccessibleText(
            '场景描述',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            widget.scenario.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          // 提示
          if (widget.scenario.hints.isNotEmpty) ...[
            const AccessibleText(
              '操作提示',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...widget.scenario.hints.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AccessibleText(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: AccessibleText(
                          entry.value,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppTheme.spacingXL),
          ],
          // 预期操作
          if (widget.scenario.expectedActions.isNotEmpty) ...[
            const AccessibleText(
              '预期操作',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.secondaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Column(
                children: widget.scenario.expectedActions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: AccessibleText(
                              action,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeNormal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
          ],
          // 操作按钮
          AccessibleButton(
            onPressed: _completeScenario,
            label: '完成训练',
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleButton(
            onPressed: () => Navigator.pop(context),
            label: '稍后再做',
            
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            const AccessibleText(
              '场景完成！',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const AccessibleText(
              '恭喜您完成了这个训练场景',
              style: TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            AccessibleButton(
              onPressed: () => Navigator.pop(context, true),
              label: '继续下一个',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeScenario() async {
    try {
      final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

      await _newbieService.completeScenario(
        userId,
        widget.scenario.id,
        score: 100,
      );

      setState(() => _isCompleted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成失败: $e')),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case ScenarioType.ocr:
        return Colors.blue;
      case ScenarioType.sceneDescription:
        return Colors.green;
      case ScenarioType.navigation:
        return Colors.orange;
      case ScenarioType.emergency:
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case ScenarioType.ocr:
        return Icons.document_scanner;
      case ScenarioType.sceneDescription:
        return Icons.visibility;
      case ScenarioType.navigation:
        return Icons.navigation;
      case ScenarioType.emergency:
        return Icons.emergency;
      default:
        return Icons.school;
    }
  }
}
