import 'dart:math';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../models/call_models.dart';
import 'demo_data_loader.dart';

/// 演示版志願者服務
/// 用於替代真實的Supabase匹配服務
class DemoVolunteerService {
  static final DemoVolunteerService _instance =
      DemoVolunteerService._internal();
  factory DemoVolunteerService() => _instance;
  DemoVolunteerService._internal();

  final _random = Random();

  List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }

  /// 獲取所有演示志願者
  List<VolunteerProfile> getAllVolunteers() {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoVolunteerService.getAllVolunteers',
    )) {
      return const [];
    }

    final volunteersData = DemoDataLoader.getDemoVolunteers();
    return volunteersData.map((data) => _parseVolunteer(data)).toList();
  }

  /// 獲取在線志願者
  List<VolunteerProfile> getOnlineVolunteers() {
    return getAllVolunteers().where((v) => v.isOnline).toList();
  }

  /// 模擬匹配志願者
  /// [delayMs] 模擬匹配延遲（毫秒）
  Future<MatchingResult> matchVolunteer({
    required String seekerId,
    int delayMs = 3000,
  }) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoVolunteerService.matchVolunteer',
    )) {
      throw StateError(
        'DemoVolunteerService.matchVolunteer 僅在 Demo fallback 開啓時可用',
      );
    }

    // 模擬匹配延遲
    await Future.delayed(Duration(milliseconds: delayMs));

    // 獲取默認匹配的志願者（演示用）
    final defaultVolunteerData = DemoDataLoader.getDefaultMatchedVolunteer();
    if (defaultVolunteerData == null) {
      throw Exception('演示數據未加載');
    }

    final volunteer = _parseVolunteer(defaultVolunteerData);

    // 構建匹配結果
    final matchedVolunteer = MatchedVolunteer(
      id: 'match_${_random.nextInt(10000)}',
      userId: volunteer.userId,
      score: 0.95,
      distance: 1.2,
      skills: volunteer.skills,
    );

    return MatchingResult(
      helpRequestId: 'help_${_random.nextInt(100000)}',
      volunteers: [matchedVolunteer],
      timeoutAt: DateTime.now().add(const Duration(seconds: 30)),
    );
  }

  /// 模擬匹配多個志願者（用於展示列表）
  Future<List<MatchedVolunteer>> matchMultipleVolunteers({
    int count = 3,
    int delayMs = 2000,
  }) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoVolunteerService.matchMultipleVolunteers',
    )) {
      return const [];
    }

    await Future.delayed(Duration(milliseconds: delayMs));

    final volunteers = getOnlineVolunteers();
    final matched = <MatchedVolunteer>[];

    for (int i = 0; i < min(count, volunteers.length); i++) {
      final volunteer = volunteers[i];
      matched.add(
        MatchedVolunteer(
          id: 'match_${_random.nextInt(10000)}_$i',
          userId: volunteer.userId,
          score: 0.9 - (i * 0.05),
          distance: 1.0 + i * 1.5,
          skills: volunteer.skills,
        ),
      );
    }

    return matched;
  }

  /// 獲取志願者詳情
  VolunteerProfile? getVolunteerById(String userId) {
    final volunteers = getAllVolunteers();
    try {
      return volunteers.firstWhere((v) => v.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// 解析志願者數據
  VolunteerProfile _parseVolunteer(Map<String, dynamic> data) {
    final creditScore = (data['creditScore'] as num?)?.toDouble() ?? 5.0;
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();

    return VolunteerProfile(
      userId: data['userId'] as String? ?? '',
      skills: _stringList(data['skills']),
      level: data['level'] as int? ?? 1,
      points: data['points'] as int? ?? 0,
      creditScore: creditScore,
      isVerified: data['isVerified'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      totalHelpCount: data['totalHelpCount'] as int?,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// 模擬獲取志願者用戶信息
  UserModel? getVolunteerUser(String userId) {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoVolunteerService.getVolunteerUser',
    )) {
      return null;
    }

    final volunteerData = DemoDataLoader.getDemoVolunteers().firstWhere(
      (v) => (v['userId'] as String? ?? '') == userId,
      orElse: () => <String, dynamic>{},
    );

    if (volunteerData.isEmpty) return null;

    return UserModel(
      id: volunteerData['userId'] as String? ?? '',
      phone: volunteerData['phone'] as String? ?? '',
      name: volunteerData['name'] as String?,
      avatarUrl: volunteerData['avatarUrl'] as String?,
      role: _stringList(volunteerData['role'] ?? ['volunteer']),
    );
  }
}
