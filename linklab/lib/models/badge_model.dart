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

  /// 徽章图标（emoji形式）
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

/// 徽章类型
enum BadgeType {
  /// 翻译达人 - 完成50次翻译类求助
  translator,
  /// 百次帮助 - 累计完成100次帮助
  helper100,
  /// 五百次帮助 - 累计完成500次帮助
  helper500,
  /// 千次帮助 - 累计完成1000次帮助
  helper1000,
  /// 跨年守夜人 - 元旦当天完成帮助
  newYear,
  /// 除夕守夜人 - 除夕当天完成帮助
  springFestival,
  /// 灯塔守护者 - 达到Lv7
  lighthouse,
  /// 连续7天帮助
  continuous7,
  /// 连续30天帮助
  continuous30,
  /// 技能大师 - 获得3个认证技能
  skillMaster,
  /// 新星志愿者 - 注册后完成首次帮助
  risingStar,
  /// 爱心大使 - 获得100个好评
  kindHeart,
  /// 其他
  other,
}

/// 徽章定义
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

/// 预定义徽章列表
class BadgeDefinitions {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      type: BadgeType.risingStar,
      name: '新星志愿者',
      description: '完成首次帮助，开启志愿之旅',
    ),
    BadgeDefinition(
      type: BadgeType.translator,
      name: '翻译达人',
      description: '完成50次翻译类求助',
      requiredCount: 50,
    ),
    BadgeDefinition(
      type: BadgeType.helper100,
      name: '百次帮助',
      description: '累计完成100次帮助',
      requiredCount: 100,
    ),
    BadgeDefinition(
      type: BadgeType.helper500,
      name: '五百次帮助',
      description: '累计完成500次帮助',
      requiredCount: 500,
    ),
    BadgeDefinition(
      type: BadgeType.helper1000,
      name: '千次帮助',
      description: '累计完成1000次帮助',
      requiredCount: 1000,
    ),
    BadgeDefinition(
      type: BadgeType.continuous7,
      name: '坚持不懈',
      description: '连续7天提供帮助',
    ),
    BadgeDefinition(
      type: BadgeType.continuous30,
      name: '月度之星',
      description: '连续30天提供帮助',
    ),
    BadgeDefinition(
      type: BadgeType.kindHeart,
      name: '爱心大使',
      description: '获得100个好评',
      requiredCount: 100,
    ),
    BadgeDefinition(
      type: BadgeType.skillMaster,
      name: '技能大师',
      description: '获得3个认证技能标签',
    ),
    BadgeDefinition(
      type: BadgeType.lighthouse,
      name: '灯塔守护者',
      description: '达到最高等级Lv7',
      requiredLevel: 7,
    ),
    BadgeDefinition(
      type: BadgeType.newYear,
      name: '跨年守夜人',
      description: '元旦当天完成帮助',
    ),
    BadgeDefinition(
      type: BadgeType.springFestival,
      name: '除夕守夜人',
      description: '除夕当天完成帮助',
    ),
  ];

  /// 根据类型获取徽章定义
  static BadgeDefinition? getByType(BadgeType type) {
    try {
      return all.firstWhere((b) => b.type == type);
    } catch (e) {
      return null;
    }
  }
}
