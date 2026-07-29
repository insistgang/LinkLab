import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/demo_match_request.dart';
import '../../models/demo_match_result.dart';
import '../../models/demo_volunteer.dart';
import 'demo_data_loader.dart';

const demoSkillHospitalGuide = '医院导诊';
const demoSkillVisualAssistance = '视障协助';
const demoSkillHearingCommunication = '手语 / 听障沟通';
const demoSkillElderlyCompanion = '老人陪同';
const demoSkillGeneralDirections = '普通问路';
const demoSkillMedicationHelp = '药品说明协助';
const demoSkillDeliveryCommunication = '外卖 / 快递沟通';
const demoSkillEmergencyCompanion = '紧急陪伴';

class DemoMatchActionResult {
  const DemoMatchActionResult({
    required this.success,
    required this.message,
    this.activeVolunteerId,
  });

  final bool success;
  final String message;
  final String? activeVolunteerId;
}

/// F9-A 本地 Top 5 志愿者匹配引擎。
///
/// 仅服务竞赛 Demo，不接真实定位、Supabase、Realtime、推送或 WebRTC。
class DemoMatchingEngineService {
  final Set<String> _rejectedOrTimedOutVolunteerIds = <String>{};
  String? _activeVolunteerId;
  bool _expired = false;
  bool _cancelled = false;

  String? get activeVolunteerId => _activeVolunteerId;
  bool get isExpired => _expired;
  bool get isCancelled => _cancelled;

  Future<List<DemoVolunteer>> loadVolunteers() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoMatchingEngineService.loadVolunteers',
    )) {
      return _fallbackVolunteers;
    }

    var rawVolunteers = DemoDataLoader.getMatchingDemoVolunteers();
    if (rawVolunteers.isEmpty) {
      await DemoDataLoader.initialize();
      rawVolunteers = DemoDataLoader.getMatchingDemoVolunteers();
    }

    if (rawVolunteers.isEmpty) {
      AppLogger.warning('F9 demo 志愿者数据为空，使用内置匹配降级数据');
      return _fallbackVolunteers;
    }

    final volunteers = <DemoVolunteer>[];
    for (final item in rawVolunteers) {
      try {
        volunteers.add(DemoVolunteer.fromJson(item));
      } catch (error, stackTrace) {
        AppLogger.warning('单条 F9 demo 志愿者数据解析失败，已跳过', error, stackTrace);
      }
    }

    if (volunteers.isEmpty) {
      AppLogger.warning('F9 demo 志愿者解析结果为空，使用内置匹配降级数据');
      return _fallbackVolunteers;
    }

    return List<DemoVolunteer>.unmodifiable(volunteers);
  }

  Future<DemoMatchResponse> matchTopVolunteers(
    DemoMatchRequest request, {
    List<DemoVolunteer>? volunteerPool,
  }) async {
    if (request.isSos) {
      AppLogger.info(
        'F9 matching skipped: SOS is handled by F13 broadcast flow',
      );
      return DemoMatchResponse.sos();
    }

    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoMatchingEngineService.matchTopVolunteers',
    )) {
      return DemoMatchResponse.empty('竞赛 Demo 匹配当前未启用，无法进入真实匹配。');
    }

    final volunteers = volunteerPool ?? await loadVolunteers();
    final onlineVolunteers = volunteers
        .where((volunteer) => volunteer.isOnline)
        .toList(growable: false);

    if (onlineVolunteers.isEmpty) {
      AppLogger.warning('F9 demo 匹配没有在线志愿者');
      return DemoMatchResponse.empty('当前没有在线 demo 志愿者，请稍后重试或重新发起求助。');
    }

    final preferredSkills = inferPreferredSkills(request);
    final ranked = onlineVolunteers
        .map(
          (volunteer) => _scoreVolunteer(
            volunteer: volunteer,
            request: request,
            preferredSkills: preferredSkills,
          ),
        )
        .toList();

    ranked.sort(_compareMatchResults);

    final topFive = ranked
        .take(5)
        .toList(growable: false)
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(rank: entry.key + 1))
        .toList(growable: false);

    AppLogger.info(
      'F9 demo Top 5 matching completed: ${topFive.length} result(s)',
    );
    return DemoMatchResponse.topFive(topFive);
  }

  List<String> inferPreferredSkills(DemoMatchRequest request) {
    if (request.preferredSkills.isNotEmpty) {
      return List<String>.unmodifiable(request.preferredSkills);
    }

    final text = _normalize('${request.requestType} ${request.queryText}');

    if (_matchesAny(text, _medicationKeywords)) {
      return const [demoSkillMedicationHelp, demoSkillHospitalGuide];
    }

    if (_matchesAny(text, _hospitalKeywords)) {
      return const [demoSkillHospitalGuide, demoSkillMedicationHelp];
    }

    if (_matchesAny(text, _hearingKeywords)) {
      return const [
        demoSkillHearingCommunication,
        demoSkillDeliveryCommunication,
      ];
    }

    if (_matchesAny(text, _visualKeywords)) {
      return const [demoSkillVisualAssistance, demoSkillGeneralDirections];
    }

    if (_matchesAny(text, _elderlyKeywords)) {
      return const [demoSkillElderlyCompanion, demoSkillGeneralDirections];
    }

    return const [demoSkillGeneralDirections, demoSkillVisualAssistance];
  }

  DemoMatchActionResult tryAccept(String volunteerId) {
    if (_cancelled) {
      return const DemoMatchActionResult(
        success: false,
        message: '用户已取消本次匹配，不能继续接单。',
      );
    }

    if (_expired) {
      return const DemoMatchActionResult(
        success: false,
        message: '本次匹配已过期，不能继续接单。',
      );
    }

    if (_rejectedOrTimedOutVolunteerIds.contains(volunteerId)) {
      return DemoMatchActionResult(
        success: false,
        message: '志愿者 $volunteerId 已拒接或超时，不能再次接单。',
        activeVolunteerId: _activeVolunteerId,
      );
    }

    final activeVolunteerId = _activeVolunteerId;
    if (activeVolunteerId != null) {
      return DemoMatchActionResult(
        success: false,
        message: '已有志愿者 $activeVolunteerId 成功接单，本次竞争已结束。',
        activeVolunteerId: activeVolunteerId,
      );
    }

    _activeVolunteerId = volunteerId;
    AppLogger.info('F9 demo volunteer accepted request');
    return DemoMatchActionResult(
      success: true,
      message: '志愿者已接单。',
      activeVolunteerId: volunteerId,
    );
  }

  DemoMatchActionResult rejectOrTimeout(String volunteerId) {
    if (_activeVolunteerId == volunteerId) {
      return DemoMatchActionResult(
        success: false,
        message: '志愿者 $volunteerId 已经接单，不能再标记为拒接或超时。',
        activeVolunteerId: _activeVolunteerId,
      );
    }

    _rejectedOrTimedOutVolunteerIds.add(volunteerId);
    AppLogger.info('F9 demo volunteer rejected or timed out');
    return DemoMatchActionResult(
      success: true,
      message: '已记录拒接或超时，可继续尝试下一位候选人。',
      activeVolunteerId: _activeVolunteerId,
    );
  }

  DemoMatchActionResult expire() {
    if (_activeVolunteerId != null) {
      return DemoMatchActionResult(
        success: false,
        message: '已有志愿者接单，不能将本次匹配标记为过期。',
        activeVolunteerId: _activeVolunteerId,
      );
    }

    _expired = true;
    AppLogger.info('F9 demo matching expired');
    return const DemoMatchActionResult(success: true, message: '无人接单，本次匹配已过期。');
  }

  DemoMatchActionResult cancel() {
    if (_activeVolunteerId != null) {
      return DemoMatchActionResult(
        success: false,
        message: '已接通志愿者，不能取消匹配阶段。',
        activeVolunteerId: _activeVolunteerId,
      );
    }

    _cancelled = true;
    AppLogger.info('F9 demo matching cancelled');
    return const DemoMatchActionResult(success: true, message: '用户已取消本次匹配。');
  }

  void resetCompetition() {
    _activeVolunteerId = null;
    _expired = false;
    _cancelled = false;
    _rejectedOrTimedOutVolunteerIds.clear();
  }

  DemoMatchResult _scoreVolunteer({
    required DemoVolunteer volunteer,
    required DemoMatchRequest request,
    required List<String> preferredSkills,
  }) {
    final matchedSkills = volunteer.skills
        .where(preferredSkills.contains)
        .toList(growable: false);

    // AGENTS.md §7.1 权重：availability 0.30, distance 0.25, skill 0.20, trust 0.15, reputation 0.10
    final availabilityScore = _availabilityScore(volunteer);
    final distanceScore = _distanceScore(volunteer.distanceMeters);
    final skillScore = _skillScore(matchedSkills, preferredSkills);
    final trustHistoryScore = _trustHistoryScore(volunteer.helpCount);
    final reputationScore = _reputationScore(volunteer.reputationScore);

    final score = _roundScore(
      availabilityScore * 0.30 +
          distanceScore * 0.25 +
          skillScore * 0.20 +
          trustHistoryScore * 0.15 +
          reputationScore * 0.10,
    );

    return DemoMatchResult(
      volunteer: volunteer,
      score: score,
      matchedSkills: List<String>.unmodifiable(matchedSkills),
      reason: _buildReason(volunteer, matchedSkills),
      rank: 0,
    );
  }

  int _compareMatchResults(DemoMatchResult a, DemoMatchResult b) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;

    final distanceComparison = a.volunteer.distanceMeters.compareTo(
      b.volunteer.distanceMeters,
    );
    if (distanceComparison != 0) return distanceComparison;

    final reputationComparison = b.volunteer.reputationScore.compareTo(
      a.volunteer.reputationScore,
    );
    if (reputationComparison != 0) return reputationComparison;

    final responseComparison = a.volunteer.estimatedResponseSeconds.compareTo(
      b.volunteer.estimatedResponseSeconds,
    );
    if (responseComparison != 0) return responseComparison;

    return a.volunteer.id.compareTo(b.volunteer.id);
  }

  double _skillScore(List<String> matchedSkills, List<String> preferredSkills) {
    if (preferredSkills.isEmpty) return 0.35;
    return _clampScore(matchedSkills.length / preferredSkills.length);
  }

  double _availabilityScore(DemoVolunteer volunteer) {
    // AGENTS.md §7.1: 是否在线、是否愿意接单、是否正在服务中
    if (!volunteer.isOnline) return 0.0;
    // 在线志愿者基础分 0.7，帮助次数越多说明越活跃
    final activityBoost = (volunteer.helpCount / 100).clamp(0.0, 0.3);
    return _clampScore(0.7 + activityBoost);
  }

  double _trustHistoryScore(int helpCount) {
    // AGENTS.md §7.1: 优先连接曾经成功协助过的志愿者
    // 帮助次数越多，历史信任分越高
    return _clampScore(helpCount / 100);
  }

  double _distanceScore(int distanceMeters) {
    final normalizedDistance = distanceMeters.clamp(0, 5000) / 5000;
    return _clampScore(1 - normalizedDistance);
  }

  double _reputationScore(double reputationScore) {
    final normalized = reputationScore > 1
        ? reputationScore / 5
        : reputationScore;
    return _clampScore(normalized);
  }

  double _clampScore(num value) {
    return value.clamp(0, 1).toDouble();
  }

  double _roundScore(double value) {
    return double.parse(value.toStringAsFixed(4));
  }

  String _buildReason(DemoVolunteer volunteer, List<String> matchedSkills) {
    final skillText = matchedSkills.isEmpty
        ? '在线且可提供基础协助'
        : '匹配 ${matchedSkills.join('、')}';
    final distanceText = volunteer.distanceMeters < 1000
        ? '${volunteer.distanceMeters} 米'
        : '${(volunteer.distanceMeters / 1000).toStringAsFixed(1)} 公里';
    final reputationText = (volunteer.reputationScore * 100).round();

    return '$skillText；距离约 $distanceText，信誉 $reputationText 分，预计 ${volunteer.estimatedResponseSeconds} 秒响应。';
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(_normalize(keyword)));
  }
}

const _hospitalKeywords = [
  'hospital',
  '医院',
  '科室',
  '挂号',
  '取药',
  '门诊',
  '急诊',
  '缴费',
];

const _medicationKeywords = [
  'medication',
  'medicine',
  '药品',
  '药盒',
  '药品盒',
  '说明书',
  '怎么吃',
  '一次几片',
  '剂量',
  '用法',
  '禁忌',
  '药名',
];

const _hearingKeywords = [
  'hearing',
  '听障',
  '听不清',
  '电话',
  '外卖',
  '快递',
  '帮我说',
  '转译',
  '手语',
];

const _visualKeywords = [
  'visual',
  '视障',
  '看不见',
  '看不清',
  '路况',
  '障碍物',
  '过路口',
  '前面有什么',
];

const _elderlyKeywords = ['elderly', '老人', '陪同', '慢慢走', '腿脚', '扶一下'];

const _fallbackVolunteers = [
  DemoVolunteer(
    id: 'fallback_volunteer_001',
    nickname: '演示导诊员',
    avatarLabel: '导',
    distanceMeters: 400,
    skills: [demoSkillHospitalGuide, demoSkillMedicationHelp],
    reputationScore: 0.95,
    isOnline: true,
    helpCount: 80,
    estimatedResponseSeconds: 10,
    preferredScenarios: ['医院', '药品说明'],
    languageTags: ['普通话'],
  ),
  DemoVolunteer(
    id: 'fallback_volunteer_002',
    nickname: '演示问路员',
    avatarLabel: '路',
    distanceMeters: 500,
    skills: [demoSkillVisualAssistance, demoSkillGeneralDirections],
    reputationScore: 0.92,
    isOnline: true,
    helpCount: 70,
    estimatedResponseSeconds: 9,
    preferredScenarios: ['路况', '障碍物'],
    languageTags: ['普通话'],
  ),
  DemoVolunteer(
    id: 'fallback_volunteer_003',
    nickname: '演示转译员',
    avatarLabel: '译',
    distanceMeters: 900,
    skills: [demoSkillHearingCommunication, demoSkillDeliveryCommunication],
    reputationScore: 0.9,
    isOnline: true,
    helpCount: 55,
    estimatedResponseSeconds: 12,
    preferredScenarios: ['听障沟通', '外卖电话'],
    languageTags: ['普通话', '手语'],
  ),
  DemoVolunteer(
    id: 'fallback_volunteer_004',
    nickname: '演示陪同员',
    avatarLabel: '陪',
    distanceMeters: 650,
    skills: [demoSkillElderlyCompanion, demoSkillGeneralDirections],
    reputationScore: 0.88,
    isOnline: true,
    helpCount: 60,
    estimatedResponseSeconds: 13,
    preferredScenarios: ['老人陪同'],
    languageTags: ['普通话'],
  ),
  DemoVolunteer(
    id: 'fallback_volunteer_005',
    nickname: '演示紧急陪伴员',
    avatarLabel: '急',
    distanceMeters: 1200,
    skills: [demoSkillEmergencyCompanion, demoSkillVisualAssistance],
    reputationScore: 0.93,
    isOnline: true,
    helpCount: 90,
    estimatedResponseSeconds: 8,
    preferredScenarios: ['紧急陪伴'],
    languageTags: ['普通话'],
  ),
];
