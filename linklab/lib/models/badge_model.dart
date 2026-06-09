import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge_model.freezed.dart';
part 'badge_model.g.dart';

/// 徽章模型
@freezed
class BadgeModel with _$BadgeModel {
  const factory BadgeModel({
    required String id,
    required String userId,
    required BadgeType type,
    required String name,
    String? iconUrl,
    String? description,
    DateTime? earnedAt,
    @Default(false) bool isNew,
  }) = _BadgeModel;

  factory BadgeModel.fromJson(Map<String, dynamic> json) =>
      _$BadgeModelFromJson(json);

  const BadgeModel._();

  /// 徽章圖標（emoji形式）
  String get iconEmoji {
    switch (type) {
      case BadgeType.translator:
        return '🌐';
      case BadgeType.helper100:
        return '💯';
      case BadgeType.helper500:
        return '🏆';
      case BadgeType.helper1000:
        return '👑';
      case BadgeType.newYear:
        return '🎆';
      case BadgeType.springFestival:
        return '🧧';
      case BadgeType.lighthouse:
        return '🏠';
      case BadgeType.continuous7:
        return '🔥';
      case BadgeType.continuous30:
        return '⭐';
      case BadgeType.skillMaster:
        return '🎯';
      case BadgeType.risingStar:
        return '🌟';
      case BadgeType.kindHeart:
        return '❤️';
      case BadgeType.other:
        return '🏅';
    }
  }
}

/// 徽章類型
enum BadgeType {
  /// 翻譯達人 - 完成50次翻譯類求助
  translator,
  /// 百次幫助 - 累計完成100次幫助
  helper100,
  /// 五百次幫助 - 累計完成500次幫助
  helper500,
  /// 千次幫助 - 累計完成1000次幫助
  helper1000,
  /// 跨年守夜人 - 元旦當天完成幫助
  newYear,
  /// 除夕守夜人 - 除夕當天完成幫助
  springFestival,
  /// 燈塔守護者 - 達到Lv7
  lighthouse,
  /// 連續7天幫助
  continuous7,
  /// 連續30天幫助
  continuous30,
  /// 技能大師 - 獲得3個認證技能
  skillMaster,
  /// 新星志願者 - 註冊後完成首次幫助
  risingStar,
  /// 愛心大使 - 獲得100個好評
  kindHeart,
  /// 其他
  other,
}

/// 徽章定義
class BadgeDefinition {
  final BadgeType type;
  final String name;
  final String description;
  final int? requiredCount;
  final int? requiredLevel;

  const BadgeDefinition({
    required this.type,
    required this.name,
    required this.description,
    this.requiredCount,
    this.requiredLevel,
  });
}

/// 預定義徽章列表
class BadgeDefinitions {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      type: BadgeType.risingStar,
      name: '新星志願者',
      description: '完成首次幫助，開啓志願之旅',
    ),
    BadgeDefinition(
      type: BadgeType.translator,
      name: '翻譯達人',
      description: '完成50次翻譯類求助',
      requiredCount: 50,
    ),
    BadgeDefinition(
      type: BadgeType.helper100,
      name: '百次幫助',
      description: '累計完成100次幫助',
      requiredCount: 100,
    ),
    BadgeDefinition(
      type: BadgeType.helper500,
      name: '五百次幫助',
      description: '累計完成500次幫助',
      requiredCount: 500,
    ),
    BadgeDefinition(
      type: BadgeType.helper1000,
      name: '千次幫助',
      description: '累計完成1000次幫助',
      requiredCount: 1000,
    ),
    BadgeDefinition(
      type: BadgeType.continuous7,
      name: '堅持不懈',
      description: '連續7天提供幫助',
    ),
    BadgeDefinition(
      type: BadgeType.continuous30,
      name: '月度之星',
      description: '連續30天提供幫助',
    ),
    BadgeDefinition(
      type: BadgeType.kindHeart,
      name: '愛心大使',
      description: '獲得100個好評',
      requiredCount: 100,
    ),
    BadgeDefinition(
      type: BadgeType.skillMaster,
      name: '技能大師',
      description: '獲得3個認證技能標籤',
    ),
    BadgeDefinition(
      type: BadgeType.lighthouse,
      name: '燈塔守護者',
      description: '達到最高等級Lv7',
      requiredLevel: 7,
    ),
    BadgeDefinition(
      type: BadgeType.newYear,
      name: '跨年守夜人',
      description: '元旦當天完成幫助',
    ),
    BadgeDefinition(
      type: BadgeType.springFestival,
      name: '除夕守夜人',
      description: '除夕當天完成幫助',
    ),
  ];

  /// 根據類型獲取徽章定義
  static BadgeDefinition? getByType(BadgeType type) {
    try {
      return all.firstWhere((b) => b.type == type);
    } catch (e) {
      return null;
    }
  }
}
