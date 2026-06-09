import '../widgets/demo/linkable_icon.dart';

/// 社區小組分類
class CommunityGroupCategory {
  static const String visualImpairment = 'visual_impairment';
  static const String hearingImpairment = 'hearing_impairment';
  static const String mobilityImpairment = 'mobility_impairment';
  static const String elderlyCare = 'elderly_care';
  static const String medicineConsult = 'medicine_consult';
  static const String hospitalGuide = 'hospital_guide';

  static const Map<String, String> labels = {
    visualImpairment: '視障互助',
    hearingImpairment: '聽障交流',
    mobilityImpairment: '輪椅出行',
    elderlyCare: '老年關愛',
    medicineConsult: '藥品諮詢',
    hospitalGuide: '導診互助',
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

/// 社區小組模型
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

  /// 獲取格式化的成員數
  String get formattedMemberCount {
    if (memberCount >= 10000) {
      return '${(memberCount / 10000).toStringAsFixed(1)}萬';
    } else if (memberCount >= 1000) {
      return '${(memberCount / 1000).toStringAsFixed(1)}k';
    }
    return '$memberCount';
  }

  /// 獲取最後活躍時間描述
  String get lastActiveDescription {
    if (lastActiveTime == null) return '暫無動態';

    final now = DateTime.now();
    final difference = now.difference(lastActiveTime!);

    if (difference.inMinutes < 1) {
      return '剛剛活躍';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '一週前';
    }
  }

  /// 獲取分類標籤
  String get categoryLabel {
    return CommunityGroupCategory.getLabel(category);
  }
}

/// 小組討論消息模型
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

  /// 獲取格式化的時間
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小時前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}