import 'dart:math';
import '../../models/user_model.dart';
import '../../models/call_models.dart';
import 'demo_data_loader.dart';

/// 演示版志愿者服务
/// 用于替代真实的Supabase匹配服务
class DemoVolunteerService {
  static final DemoVolunteerService _instance = DemoVolunteerService._internal();
  factory DemoVolunteerService() => _instance;
  DemoVolunteerService._internal();

  final _random = Random();

  /// 获取所有演示志愿者
  List<VolunteerProfile> getAllVolunteers() {
    final volunteersData = DemoDataLoader.getDemoVolunteers();
    return volunteersData.map((data) => _parseVolunteer(data)).toList();
  }

  /// 获取在线志愿者
  List<VolunteerProfile> getOnlineVolunteers() {
    return getAllVolunteers().where((v) => v.isOnline).toList();
  }

  /// 模拟匹配志愿者
  /// [delayMs] 模拟匹配延迟（毫秒）
  Future<MatchingResult> matchVolunteer({
    required String seekerId,
    int delayMs = 3000,
  }) async {
    // 模拟匹配延迟
    await Future.delayed(Duration(milliseconds: delayMs));

    // 获取默认匹配的志愿者（演示用）
    final defaultVolunteerData = DemoDataLoader.getDefaultMatchedVolunteer();
    if (defaultVolunteerData == null) {
      throw Exception('演示数据未加载');
    }

    final volunteer = _parseVolunteer(defaultVolunteerData);

    // 构建匹配结果
    final matchedVolunteer = MatchedVolunteer(
      id: 'match_${_random.nextInt(10000)}',
      userId: volunteer.userId,
      score: 0.95,
      distance: volunteer.distance ?? 1.2,
      skills: volunteer.skills,
    );

    return MatchingResult(
      helpRequestId: 'help_${_random.nextInt(100000)}',
      volunteers: [matchedVolunteer],
      timeoutAt: DateTime.now().add(const Duration(seconds: 30)),
    );
  }

  /// 模拟匹配多个志愿者（用于展示列表）
  Future<List<MatchedVolunteer>> matchMultipleVolunteers({
    int count = 3,
    int delayMs = 2000,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMs));

    final volunteers = getOnlineVolunteers();
    final matched = <MatchedVolunteer>[];

    for (int i = 0; i < min(count, volunteers.length); i++) {
      final volunteer = volunteers[i];
      matched.add(MatchedVolunteer(
        id: 'match_${_random.nextInt(10000)}_$i',
        userId: volunteer.userId,
        score: 0.9 - (i * 0.05),
        distance: volunteer.distance ?? (1.0 + i * 1.5),
        skills: volunteer.skills,
      ));
    }

    return matched;
  }

  /// 获取志愿者详情
  VolunteerProfile? getVolunteerById(String userId) {
    final volunteers = getAllVolunteers();
    try {
      return volunteers.firstWhere((v) => v.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// 解析志愿者数据
  VolunteerProfile _parseVolunteer(Map<String, dynamic> data) {
    return VolunteerProfile(
      userId: data['userId'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      level: data['level'] ?? 1,
      points: data['points'] ?? 0,
      creditScore: (data['creditScore'] ?? 5.0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      isOnline: data['isOnline'] ?? false,
      totalHelpCount: data['totalHelpCount'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  /// 模拟获取志愿者用户信息
  UserModel? getVolunteerUser(String userId) {
    final volunteerData = DemoDataLoader.getDemoVolunteers().firstWhere(
      (v) => v['userId'] == userId,
      orElse: () => {},
    );

    if (volunteerData.isEmpty) return null;

    return UserModel(
      id: volunteerData['userId'] ?? '',
      phone: volunteerData['phone'] ?? '',
      name: volunteerData['name'],
      avatarUrl: volunteerData['avatarUrl'],
      role: List<String>.from(volunteerData['role'] ?? ['volunteer']),
    );
  }
}
