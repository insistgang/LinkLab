import 'dart:async';

import '../../config/app_config.dart';
import '../../models/matching_result_model.dart';
import '../demo_call_service.dart';
import '../matching_service.dart';

/// VolunteerMatchingFacade
///
/// AGENTS.md §12.2 統一入口：志願者匹配能力的唯一 facade。
/// 包裝 MatchingService / DemoMatchingService，對外屏蔽 demo/real 實現差異。
/// UI 層只允許通過本 facade 調用匹配能力。
class VolunteerMatchingFacade {
  final DemoMatchingService _demoMatching;
  final MatchingService _legacyMatching;

  VolunteerMatchingFacade({
    DemoMatchingService? demoMatching,
    MatchingService? legacyMatching,
  }) : _demoMatching = demoMatching ?? DemoMatchingService(),
       _legacyMatching = legacyMatching ?? MatchingService();

  // ────────────────────────── 匹配流程 ──────────────────────────

  /// 發起志願者匹配
  ///
  /// [intent] 求主意圖標籤
  /// [urgency] 緊急程度：normal | elevated | emergency
  /// [tags] 推薦志願者技能標籤
  Future<MatchingResultModel> findVolunteers({
    required String intent,
    required String urgency,
    List<String> tags = const [],
  }) async {
    if (AppConfig.demoMode || !FeatureFlags.enableRealMatching) {
      return MatchingResultModel.success(
        helpRequestId: 'demo_facade_${DateTime.now().millisecondsSinceEpoch}',
        volunteers: _demoVolunteerCandidates(tags),
        timeoutAt: DateTime.now().add(const Duration(seconds: 60)),
      );
    }

    try {
      // 使用 legacy MatchingService 發起匹配
      final result = await _legacyMatching.startMatching(
        seekerId: 'current_user',
        urgency: urgency,
        location: {'lat': 31.23, 'lng': 121.47}, // Demo 使用固定位置
        skills: tags,
        helpType: intent,
      );

      if (result == null) {
        return MatchingResultModel.error('匹配服務返回空結果');
      }

      final candidates = result.volunteers
          .map(
            (v) => VolunteerCandidate(
              id: v.id,
              name: _getVolunteerName(v.id),
              score: v.score,
              distance: v.distance,
              skills: v.skills,
              rating: _getVolunteerRating(v.id),
              helpCount: _getVolunteerHelpCount(v.id),
            ),
          )
          .toList();

      return MatchingResultModel.success(
        helpRequestId: result.helpRequestId,
        volunteers: candidates,
        timeoutAt: result.timeoutAt,
      );
    } catch (e) {
      return MatchingResultModel.error('findVolunteers 失敗: $e');
    }
  }

  /// 接受匹配
  Future<bool> acceptVolunteer(String volunteerId) async {
    if (AppConfig.demoMode || !FeatureFlags.enableRealMatching) {
      return true;
    }

    try {
      final helpRequestId = _legacyMatching.currentHelpRequestId;
      if (helpRequestId == null) return false;
      return await _legacyMatching.acceptMatch(helpRequestId);
    } catch (e) {
      return false;
    }
  }

  /// 拒絕匹配
  Future<void> rejectVolunteer(String volunteerId) async {
    if (AppConfig.demoMode || !FeatureFlags.enableRealMatching) {
      return;
    }

    try {
      final helpRequestId = _legacyMatching.currentHelpRequestId;
      if (helpRequestId != null) {
        await _legacyMatching.rejectMatch(helpRequestId);
      }
    } catch (_) {
      // ignore
    }
  }

  /// 取消匹配
  Future<void> cancelMatching() async {
    if (AppConfig.demoMode || !FeatureFlags.enableRealMatching) {
      _demoMatching.cancelMatching();
      return;
    }

    try {
      await _legacyMatching.cancelMatching();
      _demoMatching.cancelMatching();
    } catch (_) {
      // ignore
    }
  }

  /// 獲取當前匹配狀態
  MatchingResultModel getMatchingStatus() {
    final isSearching = _demoMatching.isSearching;
    final matchedCount = _demoMatching.matchedCount;

    if (!isSearching && matchedCount == 0) {
      return MatchingResultModel.cancelled();
    }

    if (isSearching) {
      return MatchingResultModel.searching();
    }

    return MatchingResultModel.success(
      helpRequestId: _legacyMatching.currentHelpRequestId ?? 'unknown',
      volunteers: [],
    );
  }

  List<VolunteerCandidate> _demoVolunteerCandidates(List<String> tags) {
    return [
      for (var index = 0; index < demoVolunteers.length; index++)
        VolunteerCandidate(
          id: demoVolunteers[index].id,
          name: demoVolunteers[index].name,
          score: 0.95 - index * 0.04,
          distance: 0.4 + index * 0.3,
          skills: demoVolunteers[index].skills,
          rating: demoVolunteers[index].rating,
          helpCount: demoVolunteers[index].helpCount,
        ),
    ];
  }

  // ────────────────────────── 內部輔助 ──────────────────────────

  String _getVolunteerName(String volunteerId) {
    try {
      final volunteer = demoVolunteers.firstWhere((v) => v.id == volunteerId);
      return volunteer.name;
    } catch (_) {
      return '志願者';
    }
  }

  double _getVolunteerRating(String volunteerId) {
    try {
      final volunteer = demoVolunteers.firstWhere((v) => v.id == volunteerId);
      return volunteer.rating;
    } catch (_) {
      return 4.5;
    }
  }

  int _getVolunteerHelpCount(String volunteerId) {
    try {
      final volunteer = demoVolunteers.firstWhere((v) => v.id == volunteerId);
      return volunteer.helpCount;
    } catch (_) {
      return 0;
    }
  }
}
