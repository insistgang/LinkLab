// 演示用志愿者数据
// 用于演示版的志愿者匹配功能

class DemoVolunteer {
  final String id;
  final String name;
  final String level;
  final String levelBadge;
  final String distance;
  final String avatar;
  final List<String> skills;
  final double rating;
  final int helpCount;
  final bool isOnline;

  const DemoVolunteer({
    required this.id,
    required this.name,
    required this.level,
    required this.levelBadge,
    required this.distance,
    required this.avatar,
    required this.skills,
    required this.rating,
    required this.helpCount,
    this.isOnline = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'levelBadge': levelBadge,
        'distance': distance,
        'avatar': avatar,
        'skills': skills,
        'rating': rating,
        'helpCount': helpCount,
        'isOnline': isOnline,
      };

  factory DemoVolunteer.fromJson(Map<String, dynamic> json) => DemoVolunteer(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        level: (json['level'] as String?) ?? '',
        levelBadge: (json['levelBadge'] as String?) ?? '',
        distance: (json['distance'] as String?) ?? '',
        avatar: (json['avatar'] as String?) ?? '',
        skills: List<String>.from((json['skills'] as List<dynamic>?) ?? []),
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        helpCount: (json['helpCount'] as int?) ?? 0,
        isOnline: (json['isOnline'] as bool?) ?? true,
      );
}

/// 演示志愿者列表
final List<DemoVolunteer> demoVolunteers = [
  const DemoVolunteer(
    id: 'vol_001',
    name: '小李',
    level: '灯塔',
    levelBadge: '🏠',
    distance: '1.2km',
    avatar: '',
    skills: ['导盲', '日常协助'],
    rating: 4.9,
    helpCount: 128,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_002',
    name: '张医生',
    level: '星辰',
    levelBadge: '⭐',
    distance: '2.5km',
    avatar: '',
    skills: ['医疗咨询', '紧急救助'],
    rating: 4.8,
    helpCount: 86,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_003',
    name: '王阿姨',
    level: '暖阳',
    levelBadge: '☀️',
    distance: '0.8km',
    avatar: '',
    skills: ['生活协助', '陪聊'],
    rating: 5.0,
    helpCount: 256,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_004',
    name: '陈同学',
    level: '微光',
    levelBadge: '✨',
    distance: '3.1km',
    avatar: '',
    skills: ['技术支持', '读屏'],
    rating: 4.7,
    helpCount: 32,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_005',
    name: '刘老师',
    level: '烛光',
    levelBadge: '🕯️',
    distance: '1.8km',
    avatar: '',
    skills: ['教育辅导', '心理支持'],
    rating: 4.9,
    helpCount: 168,
    isOnline: false,
  ),
];

/// 默认匹配的志愿者（演示用）
final DemoVolunteer defaultMatchedVolunteer = demoVolunteers[0];

/// 根据ID获取志愿者
DemoVolunteer? getVolunteerById(String id) {
  try {
    return demoVolunteers.firstWhere((v) => v.id == id);
  } catch (e) {
    return null;
  }
}

/// 获取在线志愿者列表
List<DemoVolunteer> getOnlineVolunteers() {
  return demoVolunteers.where((v) => v.isOnline).toList();
}

/// 模拟匹配志愿者
/// 演示版固定返回第一个在线志愿者
Future<DemoVolunteer> mockMatchVolunteer({int delayMs = 2000}) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return defaultMatchedVolunteer;
}

/// 等级说明
const Map<String, String> volunteerLevelDescriptions = {
  '灯塔': '资深志愿者，帮助超过100次',
  '星辰': '专业志愿者，具备专业技能',
  '暖阳': '热心志愿者，深受用户好评',
  '微光': '新晋志愿者，充满热情',
  '烛光': '稳定志愿者，长期服务',
};
