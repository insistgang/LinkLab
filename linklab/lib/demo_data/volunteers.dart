// 演示用志願者數據
// 用於演示版的志願者匹配功能

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

/// 演示志願者列表
final List<DemoVolunteer> demoVolunteers = [
  const DemoVolunteer(
    id: 'vol_001',
    name: '小李',
    level: '燈塔',
    levelBadge: '🏠',
    distance: '1.2km',
    avatar: '',
    skills: ['導盲', '日常協助'],
    rating: 4.9,
    helpCount: 128,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_002',
    name: '張醫生',
    level: '星辰',
    levelBadge: '⭐',
    distance: '2.5km',
    avatar: '',
    skills: ['醫療諮詢', '緊急救助'],
    rating: 4.8,
    helpCount: 86,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_003',
    name: '王阿姨',
    level: '暖陽',
    levelBadge: '☀️',
    distance: '0.8km',
    avatar: '',
    skills: ['生活協助', '陪聊'],
    rating: 5.0,
    helpCount: 256,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_004',
    name: '陳同學',
    level: '微光',
    levelBadge: '✨',
    distance: '3.1km',
    avatar: '',
    skills: ['技術支持', '讀屏'],
    rating: 4.7,
    helpCount: 32,
    isOnline: true,
  ),
  const DemoVolunteer(
    id: 'vol_005',
    name: '劉老師',
    level: '燭光',
    levelBadge: '🕯️',
    distance: '1.8km',
    avatar: '',
    skills: ['教育輔導', '心理支持'],
    rating: 4.9,
    helpCount: 168,
    isOnline: false,
  ),
];

/// 默認匹配的志願者（演示用）
final DemoVolunteer defaultMatchedVolunteer = demoVolunteers[0];

/// 根據ID獲取志願者
DemoVolunteer? getVolunteerById(String id) {
  try {
    return demoVolunteers.firstWhere((v) => v.id == id);
  } catch (e) {
    return null;
  }
}

/// 獲取在線志願者列表
List<DemoVolunteer> getOnlineVolunteers() {
  return demoVolunteers.where((v) => v.isOnline).toList();
}

/// 模擬匹配志願者
/// 演示版固定返回第一個在線志願者
Future<DemoVolunteer> mockMatchVolunteer({int delayMs = 2000}) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return defaultMatchedVolunteer;
}

/// 等級說明
const Map<String, String> volunteerLevelDescriptions = {
  '燈塔': '資深志願者，幫助超過100次',
  '星辰': '專業志願者，具備專業技能',
  '暖陽': '熱心志願者，深受用戶好評',
  '微光': '新晉志願者，充滿熱情',
  '燭光': '穩定志願者，長期服務',
};
