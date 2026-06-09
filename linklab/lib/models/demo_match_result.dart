import 'demo_volunteer.dart';

class DemoMatchResult {
  const DemoMatchResult({
    required this.volunteer,
    required this.score,
    required this.matchedSkills,
    required this.reason,
    required this.rank,
  });

  final DemoVolunteer volunteer;
  final double score;
  final List<String> matchedSkills;
  final String reason;
  final int rank;

  DemoMatchResult copyWith({int? rank}) {
    return DemoMatchResult(
      volunteer: volunteer,
      score: score,
      matchedSkills: matchedSkills,
      reason: reason,
      rank: rank ?? this.rank,
    );
  }
}

class DemoMatchResponse {
  const DemoMatchResponse({
    required this.results,
    required this.message,
    required this.usesTopFive,
  });

  final List<DemoMatchResult> results;
  final String message;
  final bool usesTopFive;

  factory DemoMatchResponse.topFive(
    List<DemoMatchResult> results, {
    String message = '已按本地 demo 匹配公式生成 Top 5 志願者。',
  }) {
    return DemoMatchResponse(
      results: results,
      message: message,
      usesTopFive: true,
    );
  }

  factory DemoMatchResponse.sos() {
    return const DemoMatchResponse(
      results: [],
      message: 'SOS 由 F13 廣播型流程處理，不使用普通 Top 5 匹配。',
      usesTopFive: false,
    );
  }

  factory DemoMatchResponse.empty(String message) {
    return DemoMatchResponse(
      results: const [],
      message: message,
      usesTopFive: true,
    );
  }
}
