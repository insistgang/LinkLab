/// VolunteerMatchingFacade 統一輸出模型
///
/// AGENTS.md §7.1：志願者匹配標準化結果。
class MatchingResultModel {
  final bool success;
  final String? error;
  final String? helpRequestId;
  final List<VolunteerCandidate> volunteers;
  final String status; // searching | matched | expired | cancelled
  final DateTime? timeoutAt;

  const MatchingResultModel({
    required this.success,
    this.error,
    this.helpRequestId,
    this.volunteers = const [],
    this.status = 'idle',
    this.timeoutAt,
  });

  factory MatchingResultModel.success({
    required String helpRequestId,
    required List<VolunteerCandidate> volunteers,
    DateTime? timeoutAt,
  }) {
    return MatchingResultModel(
      success: true,
      helpRequestId: helpRequestId,
      volunteers: volunteers,
      status: 'matched',
      timeoutAt: timeoutAt,
    );
  }

  factory MatchingResultModel.searching() {
    return const MatchingResultModel(
      success: true,
      status: 'searching',
    );
  }

  factory MatchingResultModel.expired() {
    return const MatchingResultModel(
      success: false,
      status: 'expired',
      error: '60秒內無人接單，匹配已過期。',
    );
  }

  factory MatchingResultModel.cancelled() {
    return const MatchingResultModel(
      success: false,
      status: 'cancelled',
      error: '匹配已取消。',
    );
  }

  factory MatchingResultModel.error(String errorMessage) {
    return MatchingResultModel(
      success: false,
      status: 'error',
      error: errorMessage,
    );
  }

  bool get isMatched => status == 'matched';
  bool get isSearching => status == 'searching';
}

/// 志願者候選
class VolunteerCandidate {
  final String id;
  final String name;
  final double score;
  final double distance;
  final List<String> skills;
  final double rating;
  final int helpCount;

  const VolunteerCandidate({
    required this.id,
    required this.name,
    required this.score,
    required this.distance,
    required this.skills,
    this.rating = 0.0,
    this.helpCount = 0,
  });
}
