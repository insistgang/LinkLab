import 'dart:convert';

import '../../core/utils/logger.dart';
import '../../models/badge_model.dart';
import '../../models/point_transaction_model.dart';
import '../../models/schedule_model.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_level_model.dart';
import '../local_storage.dart' as app_storage;

class VolunteerDemoStore {
  VolunteerDemoStore({app_storage.LocalStorage? storage})
      : _storage = storage ?? app_storage.LocalStorage();

  final app_storage.LocalStorage _storage;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _storage.initialize();
    _initialized = true;
  }

  String _profileKey(String volunteerId) => 'volunteer_profile_$volunteerId';
  String _transactionsKey(String volunteerId) =>
      'volunteer_point_transactions_$volunteerId';
  String _skillsKey(String volunteerId) => 'volunteer_skills_$volunteerId';
  String _skillRequestsKey(String volunteerId) =>
      'volunteer_skill_requests_$volunteerId';
  String _badgesKey(String volunteerId) => 'volunteer_badges_$volunteerId';
  String _scheduleKey(String volunteerId) => 'volunteer_schedule_$volunteerId';
  String _activitiesKey(String volunteerId) => 'volunteer_activities_$volunteerId';

  Future<VolunteerProfile> getProfile(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readMap(_profileKey(volunteerId));
    if (stored != null) {
      try {
        return VolunteerProfile.fromJson(stored);
      } catch (e) {
        AppLogger.warning('解析本地志愿者资料失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedProfile(volunteerId);
    await saveProfile(seeded);
    return seeded;
  }

  Future<void> saveProfile(VolunteerProfile profile) async {
    await _ensureInitialized();
    await _storage.setString(_profileKey(profile.userId), jsonEncode(profile.toJson()));
  }

  Future<List<PointTransactionModel>> getTransactions(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readList(_transactionsKey(volunteerId));
    if (stored != null) {
      try {
        return stored
            .map(PointTransactionModel.fromJson)
            .toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
      } catch (e) {
        AppLogger.warning('解析本地志愿者积分流水失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedTransactions(volunteerId);
    await saveTransactions(volunteerId, seeded);
    return seeded;
  }

  Future<void> saveTransactions(
    String volunteerId,
    List<PointTransactionModel> transactions,
  ) async {
    await _ensureInitialized();
    final jsonList = transactions.map((item) => item.toJson()).toList();
    await _storage.setString(_transactionsKey(volunteerId), jsonEncode(jsonList));
  }

  Future<void> appendTransaction(
    String volunteerId,
    PointTransactionModel transaction,
  ) async {
    final transactions = await getTransactions(volunteerId);
    transactions.removeWhere((item) => item.id == transaction.id);
    transactions.insert(0, transaction);
    await saveTransactions(volunteerId, transactions);
  }

  Future<List<SkillModel>> getSkills(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readList(_skillsKey(volunteerId));
    if (stored != null) {
      try {
        return stored.map(SkillModel.fromJson).toList();
      } catch (e) {
        AppLogger.warning('解析本地志愿者技能失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedSkills();
    await saveSkills(volunteerId, seeded);
    return seeded;
  }

  Future<void> saveSkills(String volunteerId, List<SkillModel> skills) async {
    await _ensureInitialized();
    await _storage.setString(
      _skillsKey(volunteerId),
      jsonEncode(skills.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<SkillVerificationRequest>> getSkillRequests(
    String volunteerId,
  ) async {
    await _ensureInitialized();

    final stored = _readList(_skillRequestsKey(volunteerId));
    if (stored != null) {
      try {
        return stored.map(SkillVerificationRequest.fromJson).toList()
          ..sort((a, b) {
            final aTime = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
      } catch (e) {
        AppLogger.warning('解析本地技能申请失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedSkillRequests(volunteerId);
    await saveSkillRequests(volunteerId, seeded);
    return seeded;
  }

  Future<void> saveSkillRequests(
    String volunteerId,
    List<SkillVerificationRequest> requests,
  ) async {
    await _ensureInitialized();
    await _storage.setString(
      _skillRequestsKey(volunteerId),
      jsonEncode(requests.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<BadgeModel>> getBadges(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readList(_badgesKey(volunteerId));
    if (stored == null) {
      return [];
    }

    try {
      return stored.map(BadgeModel.fromJson).toList()
        ..sort((a, b) {
          final aTime = a.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
    } catch (e) {
      AppLogger.warning('解析本地徽章失败，改为空列表: $volunteerId');
      return [];
    }
  }

  Future<void> saveBadges(String volunteerId, List<BadgeModel> badges) async {
    await _ensureInitialized();
    await _storage.setString(
      _badgesKey(volunteerId),
      jsonEncode(badges.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> upsertBadges(String volunteerId, List<BadgeModel> newBadges) async {
    final badges = await getBadges(volunteerId);
    for (final badge in newBadges) {
      final index = badges.indexWhere((item) => item.id == badge.id);
      if (index >= 0) {
        badges[index] = badge;
      } else {
        badges.add(badge);
      }
    }
    await saveBadges(volunteerId, badges);
  }

  Future<ScheduleModel> getSchedule(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readMap(_scheduleKey(volunteerId));
    if (stored != null) {
      try {
        return ScheduleModel.fromJson(stored);
      } catch (e) {
        AppLogger.warning('解析本地排班失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedSchedule(volunteerId);
    await saveSchedule(seeded);
    return seeded;
  }

  Future<void> saveSchedule(ScheduleModel schedule) async {
    await _ensureInitialized();
    await _storage.setString(_scheduleKey(schedule.userId), jsonEncode(schedule.toJson()));
  }

  Future<List<VolunteerActivityRecord>> getActivities(String volunteerId) async {
    await _ensureInitialized();

    final stored = _readList(_activitiesKey(volunteerId));
    if (stored != null) {
      try {
        return stored.map(VolunteerActivityRecord.fromJson).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        AppLogger.warning('解析本地志愿活动失败，改为重建: $volunteerId');
      }
    }

    final seeded = _seedActivities(volunteerId);
    await saveActivities(volunteerId, seeded);
    return seeded;
  }

  Future<void> saveActivities(
    String volunteerId,
    List<VolunteerActivityRecord> activities,
  ) async {
    await _ensureInitialized();
    await _storage.setString(
      _activitiesKey(volunteerId),
      jsonEncode(activities.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> addActivity(
    String volunteerId,
    VolunteerActivityRecord activity,
  ) async {
    final activities = await getActivities(volunteerId);
    activities.removeWhere((item) => item.id == activity.id);
    activities.insert(0, activity);
    await saveActivities(volunteerId, activities);

    final profile = await getProfile(volunteerId);
    await saveProfile(
      profile.copyWith(
        totalHelpCount: activities.length,
      ),
    );
  }

  Map<String, dynamic>? _readMap(String key) {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>>? _readList(String key) {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  VolunteerProfile _seedProfile(String volunteerId) {
    const seededPoints = 386;
    return VolunteerProfile(
      userId: volunteerId,
      skills: const ['lang_english', 'tech_mobile', 'psych_companion'],
      level: LevelDefinitions.calculateLevel(seededPoints),
      points: seededPoints,
      creditScore: 4.9,
      isVerified: true,
      isOnline: false,
      lastHeartbeatAt: DateTime.now().subtract(const Duration(hours: 2)),
      totalHelpCount: 8,
    );
  }

  List<PointTransactionModel> _seedTransactions(String volunteerId) {
    final now = DateTime.now();
    return [
      PointTransactionModel(
        id: 'vtx_${volunteerId}_1',
        userId: volunteerId,
        points: 10,
        type: PointTransactionType.realtimeHelp,
        description: '完成夜间语音陪伴',
        isPositive: true,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      PointTransactionModel(
        id: 'vtx_${volunteerId}_2',
        userId: volunteerId,
        points: 3,
        type: PointTransactionType.fiveStarRating,
        description: '获得五星好评',
        isPositive: true,
        createdAt: now.subtract(const Duration(hours: 9, minutes: 48)),
      ),
      PointTransactionModel(
        id: 'vtx_${volunteerId}_3',
        userId: volunteerId,
        points: 5,
        type: PointTransactionType.asyncHelp,
        description: '完成图片识别异步任务',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      PointTransactionModel(
        id: 'vtx_${volunteerId}_4',
        userId: volunteerId,
        points: 20,
        type: PointTransactionType.continuousHelpBonus,
        description: '连续7天帮助奖励',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PointTransactionModel(
        id: 'vtx_${volunteerId}_5',
        userId: volunteerId,
        points: 120,
        type: PointTransactionType.other,
        description: '完成志愿者训练营',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      PointTransactionModel(
        id: 'vtx_${volunteerId}_6',
        userId: volunteerId,
        points: 228,
        type: PointTransactionType.other,
        description: '春季服务专项成长值',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 24)),
      ),
    ];
  }

  List<SkillModel> _seedSkills() {
    return [
      SkillDefinitions.getById('lang_english')!.copyWith(isVerified: true),
      SkillDefinitions.getById('tech_mobile')!.copyWith(isVerified: true),
      SkillDefinitions.getById('psych_companion')!.copyWith(isVerified: true),
    ];
  }

  List<SkillVerificationRequest> _seedSkillRequests(String volunteerId) {
    return [
      SkillVerificationRequest(
        id: 'skill_request_$volunteerId',
        volunteerId: volunteerId,
        skillId: 'medical_basic',
        skillName: '医疗辅助',
        description: '已上传护理培训结业证明，等待平台审核',
        status: 'pending',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  ScheduleModel _seedSchedule(String volunteerId) {
    return ScheduleModel(
      userId: volunteerId,
      weeklySchedule: {
        'monday': const [TimeSlot(start: '19:00', end: '21:30')],
        'tuesday': const [],
        'wednesday': const [TimeSlot(start: '19:30', end: '22:00')],
        'thursday': const [],
        'friday': const [TimeSlot(start: '20:00', end: '22:30')],
        'saturday': const [TimeSlot(start: '10:00', end: '12:00')],
        'sunday': const [TimeSlot(start: '15:00', end: '18:00')],
      },
      isOnline: false,
      status: OnlineStatus.offline,
      lastStatusUpdateAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  List<VolunteerActivityRecord> _seedActivities(String volunteerId) {
    final now = DateTime.now();
    return [
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_1',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_1',
        seekerName: '李阿姨',
        type: 'realtime_voice',
        durationMinutes: 18,
        rating: 5,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_2',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_2',
        seekerName: '王叔叔',
        type: 'async',
        durationMinutes: 12,
        rating: 4,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_3',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_3',
        seekerName: '陈女士',
        type: 'realtime_video',
        durationMinutes: 23,
        rating: 5,
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_4',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_4',
        seekerName: '赵先生',
        type: 'realtime_voice',
        durationMinutes: 15,
        rating: 5,
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_5',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_5',
        seekerName: '吴阿姨',
        type: 'async',
        durationMinutes: 9,
        rating: 4,
        createdAt: now.subtract(const Duration(days: 4, hours: 1)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_6',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_6',
        seekerName: '何叔叔',
        type: 'realtime_voice',
        durationMinutes: 20,
        rating: 5,
        createdAt: now.subtract(const Duration(days: 5, hours: 2)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_7',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_7',
        seekerName: '周女士',
        type: 'async',
        durationMinutes: 11,
        rating: 5,
        createdAt: now.subtract(const Duration(days: 6, hours: 5)),
      ),
      VolunteerActivityRecord(
        id: 'activity_${volunteerId}_8',
        volunteerId: volunteerId,
        seekerId: 'seeker_demo_8',
        seekerName: '孙阿姨',
        type: 'realtime_voice',
        durationMinutes: 17,
        rating: 4,
        createdAt: now.subtract(const Duration(days: 7, hours: 2)),
      ),
    ];
  }
}

class VolunteerActivityRecord {
  const VolunteerActivityRecord({
    required this.id,
    required this.volunteerId,
    required this.seekerId,
    required this.seekerName,
    required this.type,
    required this.durationMinutes,
    required this.createdAt,
    this.rating,
  });

  final String id;
  final String volunteerId;
  final String seekerId;
  final String seekerName;
  final String type;
  final int durationMinutes;
  final DateTime createdAt;
  final int? rating;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volunteerId': volunteerId,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'type': type,
      'durationMinutes': durationMinutes,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VolunteerActivityRecord.fromJson(Map<String, dynamic> json) {
    return VolunteerActivityRecord(
      id: json['id'] as String,
      volunteerId: json['volunteerId'] as String,
      seekerId: json['seekerId'] as String? ?? 'seeker-demo',
      seekerName: json['seekerName'] as String? ?? '求助者',
      type: json['type'] as String? ?? 'unknown',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
