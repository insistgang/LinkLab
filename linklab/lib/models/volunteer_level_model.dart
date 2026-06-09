import 'package:freezed_annotation/freezed_annotation.dart';

part 'volunteer_level_model.freezed.dart';
part 'volunteer_level_model.g.dart';

/// 志願者等級信息模型
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

  /// 當前等級定義
  LevelDefinition get currentLevelDef =>
      LevelDefinitions.getByLevel(currentLevel);

  /// 是否已達到最高等級
  bool get isMaxLevel => currentLevel >= 7;

  /// 等級進度文本
  String get progressText => '$currentPoints / ${currentLevelDef.maxPoints}';
}

/// 等級定義
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

/// 7級志願者等級體系
/// 青苗→嫩芽→新葉→綠蔭→暖陽→星辰→燈塔
class LevelDefinitions {
  static const List<LevelDefinition> all = [
    LevelDefinition(
      level: 1,
      name: '青苗',
      emoji: '🌱',
      minPoints: 0,
      maxPoints: 99,
      privileges: ['基礎幫助功能'],
      description: '剛剛萌芽的志願之心',
    ),
    LevelDefinition(
      level: 2,
      name: '嫩芽',
      emoji: '🌿',
      minPoints: 100,
      maxPoints: 299,
      privileges: ['基礎幫助功能', '異步任務領取'],
      description: '正在成長的志願力量',
    ),
    LevelDefinition(
      level: 3,
      name: '新葉',
      emoji: '🍀',
      minPoints: 300,
      maxPoints: 799,
      privileges: ['基礎幫助功能', '異步任務領取', '技能標籤展示'],
      description: '開始展現專業技能的志願者',
    ),
    LevelDefinition(
      level: 4,
      name: '綠蔭',
      emoji: '🌳',
      minPoints: 800,
      maxPoints: 1999,
      privileges: ['基礎幫助功能', '異步任務領取', '技能標籤展示', '專屬客服', '優先匹配'],
      description: '能夠爲更多人遮風擋雨的資深志願者',
    ),
    LevelDefinition(
      level: 5,
      name: '暖陽',
      emoji: '☀️',
      minPoints: 2000,
      maxPoints: 4999,
      privileges: ['基礎幫助功能', '異步任務領取', '技能標籤展示', '專屬客服', '優先匹配', '線下活動邀請'],
      description: '溫暖他人的優秀志願者',
    ),
    LevelDefinition(
      level: 6,
      name: '星辰',
      emoji: '⭐',
      minPoints: 5000,
      maxPoints: 9999,
      privileges: ['基礎幫助功能', '異步任務領取', '技能標籤展示', '專屬客服', '優先匹配', '線下活動邀請', '公益時數證書', '積分商城'],
      description: '閃耀在志願星空的傑出志願者',
    ),
    LevelDefinition(
      level: 7,
      name: '燈塔',
      emoji: '🏠',
      minPoints: 10000,
      maxPoints: 99999,
      privileges: ['基礎幫助功能', '異步任務領取', '技能標籤展示', '專屬客服', '優先匹配', '線下活動邀請', '公益時數證書', '積分商城', '平臺認證', '簡歷背書', '年度善意報告'],
      description: '指引方向的志願領袖',
    ),
  ];

  /// 根據等級獲取定義
  static LevelDefinition getByLevel(int level) {
    return all.firstWhere(
      (l) => l.level == level,
      orElse: () => all.first,
    );
  }

  /// 根據積分計算等級
  static int calculateLevel(int points) {
    for (int i = all.length - 1; i >= 0; i--) {
      if (points >= all[i].minPoints) {
        return all[i].level;
      }
    }
    return 1;
  }

  /// 獲取下一級所需積分
  static int getPointsToNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= 7) return 0;

    final nextLevelDef = getByLevel(currentLevel + 1);
    return nextLevelDef.minPoints - currentPoints;
  }

  /// 獲取等級進度百分比
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
