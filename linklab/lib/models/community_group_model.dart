import '../widgets/demo/linkable_icon.dart';

/// 社区小组分类
class CommunityGroupCategory {
  static const String visualImpairment = 'visual_impairment';
  static const String hearingImpairment = 'hearing_impairment';
  static const String mobilityImpairment = 'mobility_impairment';
  static const String elderlyCare = 'elderly_care';
  static const String medicineConsult = 'medicine_consult';
  static const String hospitalGuide = 'hospital_guide';

  static const Map<String, String> labels = {
    visualImpairment: '视障互助',
    hearingImpairment: '听障交流',
    mobilityImpairment: '轮椅出行',
    elderlyCare: '老年关爱',
    medicineConsult: '药品咨询',
    hospitalGuide: '导诊互助',
  };

  static const Map<String, LinkableIconName> icons = {
    visualImpairment: LinkableIconName.visualImpairment,
    hearingImpairment: LinkableIconName.hearingImpairment,
    mobilityImpairment: LinkableIconName.mobilityImpairment,
    elderlyCare: LinkableIconName.elderly,
    medicineConsult: LinkableIconName.medicineCheck,
    hospitalGuide: LinkableIconName.navigationGuide,
  };

  static String getLabel(String category) {
    return labels[category] ?? '其他';
  }

  static LinkableIconName getIcon(String category) {
    return icons[category] ?? LinkableIconName.group;
  }
}

/// 社区小组模型
class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.memberCount,
    required this.category,
    this.lastActiveTime,
  });

  final String id;
  final String name;
  final String description;
  final LinkableIconName icon;
  final int memberCount;
  final String category;
  final DateTime? lastActiveTime;

  /// 获取格式化的成员数
  String get formattedMemberCount {
    if (memberCount >= 10000) {
      return '${(memberCount / 10000).toStringAsFixed(1)}万';
    } else if (memberCount >= 1000) {
      return '${(memberCount / 1000).toStringAsFixed(1)}k';
    }
    return '$memberCount';
  }

  /// 获取最后活跃时间描述
  String get lastActiveDescription {
    if (lastActiveTime == null) return '暂无动态';

    final now = DateTime.now();
    final difference = now.difference(lastActiveTime!);

    if (difference.inMinutes < 1) {
      return '刚刚活跃';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '一周前';
    }
  }

  /// 获取分类标签
  String get categoryLabel {
    return CommunityGroupCategory.getLabel(category);
  }
}

/// 小组讨论消息模型
class GroupDiscussion {
  const GroupDiscussion({
    required this.id,
    required this.groupId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.userAvatar,
    this.likeCount = 0,
    this.isLiked = false,
    this.replyCount = 0,
  });

  final String id;
  final String groupId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final String? userAvatar;
  final int likeCount;
  final bool isLiked;
  final int replyCount;

  /// 获取格式化的时间
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}