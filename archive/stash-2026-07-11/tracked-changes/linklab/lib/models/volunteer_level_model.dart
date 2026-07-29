import 'package:freezed_annotation/freezed_annotation.dart';

part 'volunteer_level_model.freezed.dart';
part 'volunteer_level_model.g.dart';

/// 志愿者等级信息模型
@freezed
class VolunteerLevelInfo with _$VolunteerLevelInfo {
  const factory VolunteerLevelInfo({
    required int currentLevel,
    required int currentPoints,
    required int pointsToNextLevel,
    required double progressPercent,
    LevelDefinition? nextLevel,
    @Default([]) List<LevelDefinition> allLevels,
  }) = _VolunteerLevelInfo;

  factory VolunteerLevelInfo.fromJson(Map<String, dynamic> json) =>
      _$VolunteerLevelInfoFromJson(json);

  const VolunteerLevelInfo._();

  /// 当前等级定义
  LevelDefinition get currentLevelDef =>
      LevelDefinitions.getByLevel(currentLevel);

  /// 是否已达到最高等级
  bool get isMaxLevel => currentLevel >= 7;

  /// 等级进度文本
  String get progressText => '$currentPoints / ${currentLevelDef.maxPoints}';
}

/// 等级定义
@freezed
class LevelDefinition with _$LevelDefinition {
  const factory LevelDefinition({
    required int level,
    required String name,
    required String emoji,
    required int minPoints,
    required int maxPoints,
    @Default([]) List<String> privileges,
    String? description,
  }) = _LevelDefinition;

  factory LevelDefinition.fromJson(Map<String, dynamic> json) =>
      _$LevelDefinitionFromJson(json);
}

/// 7级志愿者等级体系
/// 青苗→嫩芽→新叶→绿荫→暖阳→星辰→灯塔
class LevelDefinitions {
  static const List<LevelDefinition> all = [
    LevelDefinition(
      level: 1,
      name: '青苗',
      emoji: '🌱',
      minPoints: 0,
      maxPoints: 99,
      privileges: ['基础帮助功能'],
      description: '刚刚萌芽的志愿之心',
    ),
    LevelDefinition(
      level: 2,
      name: '嫩芽',
      emoji: '🌿',
      minPoints: 100,
      maxPoints: 299,
      privileges: ['基础帮助功能', '异步任务领取'],
      description: '正在成长的志愿力量',
    ),
    LevelDefinition(
      level: 3,
      name: '新叶',
      emoji: '🍀',
      minPoints: 300,
      maxPoints: 799,
      privileges: ['基础帮助功能', '异步任务领取', '技能标签展示'],
      description: '开始展现专业技能的志愿者',
    ),
    LevelDefinition(
      level: 4,
      name: '绿荫',
      emoji: '🌳',
      minPoints: 800,
      maxPoints: 1999,
      privileges: ['基础帮助功能', '异步任务领取', '技能标签展示', '专属客服', '优先匹配'],
      description: '能够为更多人遮风挡雨的资深志愿者',
    ),
    LevelDefinition(
      level: 5,
      name: '暖阳',
      emoji: '☀️',
      minPoints: 2000,
      maxPoints: 4999,
      privileges: ['基础帮助功能', '异步任务领取', '技能标签展示', '专属客服', '优先匹配', '线下活动邀请'],
      description: '温暖他人的优秀志愿者',
    ),
    LevelDefinition(
      level: 6,
      name: '星辰',
      emoji: '⭐',
      minPoints: 5000,
      maxPoints: 9999,
      privileges: ['基础帮助功能', '异步任务领取', '技能标签展示', '专属客服', '优先匹配', '线下活动邀请', '公益时数证书', '积分商城'],
      description: '闪耀在志愿星空的杰出志愿者',
    ),
    LevelDefinition(
      level: 7,
      name: '灯塔',
      emoji: '🏠',
      minPoints: 10000,
      maxPoints: 99999,
      privileges: ['基础帮助功能', '异步任务领取', '技能标签展示', '专属客服', '优先匹配', '线下活动邀请', '公益时数证书', '积分商城', '平台认证', '简历背书', '年度善意报告'],
      description: '指引方向的志愿领袖',
    ),
  ];

  /// 根据等级获取定义
  static LevelDefinition getByLevel(int level) {
    return all.firstWhere(
      (l) => l.level == level,
      orElse: () => all.first,
    );
  }

  /// 根据积分计算等级
  static int calculateLevel(int points) {
    for (int i = all.length - 1; i >= 0; i--) {
      if (points >= all[i].minPoints) {
        return all[i].level;
      }
    }
    return 1;
  }

  /// 获取下一级所需积分
  static int getPointsToNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= 7) return 0;

    final nextLevelDef = getByLevel(currentLevel + 1);
    return nextLevelDef.minPoints - currentPoints;
  }

  /// 获取等级进度百分比
  static double getProgressPercent(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= 7) return 1.0;

    final currentLevelDef = getByLevel(currentLevel);
    final nextLevelDef = getByLevel(currentLevel + 1);

    final levelRange = nextLevelDef.minPoints - currentLevelDef.minPoints;
    final currentInLevel = currentPoints - currentLevelDef.minPoints;

    return currentInLevel / levelRange;
  }
}
