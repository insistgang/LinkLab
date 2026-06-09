import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
// ignore: deprecated_member_use_from_same_package
import '../../services/app_session_service.dart';
import '../../services/community/newbie_village_service.dart';
import '../../widgets/accessible/index.dart';
import 'training_scenario_screen.dart';

/// 新手村頁面
class NewbieVillageScreen extends StatefulWidget {
  const NewbieVillageScreen({super.key});

  @override
  State<NewbieVillageScreen> createState() => _NewbieVillageScreenState();
}

class _NewbieVillageScreenState extends State<NewbieVillageScreen> {
  final _newbieService = NewbieVillageService();
  Map<String, dynamic> _stats = {};
  List<TrainingScenario> _scenarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

    final stats = await _newbieService.getTrainingStats(userId);
    final scenarios = await _newbieService.getAllScenarios();

    setState(() {
      _stats = stats;
      _scenarios = scenarios;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (_stats['progressPercentage'] ?? 0) as int;
    final isGraduated = (_stats['isGraduated'] ?? false) as bool;

    return AccessibleScaffold(
      title: '新手村',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 歡迎卡片
                  _buildWelcomeCard(isGraduated),
                  const SizedBox(height: AppTheme.spacingXL),
                  // 進度卡片
                  _buildProgressCard(progressPercentage),
                  const SizedBox(height: AppTheme.spacingXL),
                  // 導師信息
                  if (_stats['mentorName'] != null) ...[
                    _buildMentorCard(_stats['mentorName'] as String),
                    const SizedBox(height: AppTheme.spacingXL),
                  ],
                  // 訓練場景
                  const AccessibleText(
                    '訓練場景',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ..._scenarios.map((scenario) => _ScenarioCard(
                        scenario: scenario,
                        onTap: () => _startScenario(scenario),
                      )),
                  const SizedBox(height: AppTheme.spacingXL),
                  // 畢業按鈕
                  if (isGraduated)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.secondaryColor,
                            AppTheme.secondaryLight,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          const AccessibleText(
                            '恭喜畢業！',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          const AccessibleText(
                            '您已完成所有訓練，可以正式成爲志願者了',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeNormal,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(bool isGraduated) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      isGraduated ? '歡迎回來！' : '歡迎來到新手村！',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    const AccessibleText(
                      '完成訓練即可成爲正式志願者',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int progressPercentage) {
    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccessibleText(
            '訓練進度',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: LinearProgressIndicator(
              value: progressPercentage / 100,
              minHeight: 12,
              backgroundColor: AppTheme.backgroundGrey,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AccessibleText(
                '已完成 ${_stats['completedScenarios'] ?? 0}/${_stats['totalScenarios'] ?? 3} 個場景',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondary,
                ),
              ),
              AccessibleText(
                '$progressPercentage%',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(String mentorName) {
    return AccessibleCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AccessibleText(
                  '您的導師',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  mentorName,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          AccessibleButton(
            onPressed: () {
              // TODO: 聯繫導師
            },
            label: '聯繫',
            
          ),
        ],
      ),
    );
  }

  void _startScenario(TrainingScenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingScenarioScreen(scenario: scenario),
      ),
    ).then((_) => _loadData());
  }
}

/// 場景卡片
class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.onTap,
  });

  final TrainingScenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getTypeColor(scenario.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(
              _getTypeIcon(scenario.type),
              size: 36,
              color: _getTypeColor(scenario.type),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AccessibleText(
                        scenario.title,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (scenario.isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  scenario.description,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(scenario.type).withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: AccessibleText(
                    ScenarioType.getLabel(scenario.type),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: _getTypeColor(scenario.type),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.textHint,
          ),
        ],
      ),
    );
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
