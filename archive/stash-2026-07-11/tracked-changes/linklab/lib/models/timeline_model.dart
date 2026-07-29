import 'package:freezed_annotation/freezed_annotation.dart';

part 'timeline_model.freezed.dart';
part 'timeline_model.g.dart';

/// 善意时间线数据模型
@freezed
class TimelineModel with _$TimelineModel {
  const factory TimelineModel({
    required String volunteerId,
    required int year,
    @Default([]) List<TimelineDay> days,
    @Default(0) int totalHelps,
    @Default(0) int totalMinutes,
    @Default(0) int streakDays,
    TimelineStats? stats,
  }) = _TimelineModel;

  factory TimelineModel.fromJson(Map<String, dynamic> json) =>
      _$TimelineModelFromJson(json);
}

/// 时间线单日数据
@freezed
class TimelineDay with _$TimelineDay {
  const factory TimelineDay({
    required String date,
    @Default(0) int helpCount,
    @Default(0) int minutes,
    @Default([]) List<TimelineEvent> events,
  }) = _TimelineDay;

  factory TimelineDay.fromJson(Map<String, dynamic> json) =>
      _$TimelineDayFromJson(json);

  const TimelineDay._();

  /// 活跃度级别（用于热力图颜色）
  int get activityLevel {
    if (helpCount == 0) return 0;
    if (helpCount == 1) return 1;
    if (helpCount <= 3) return 2;
    if (helpCount <= 5) return 3;
    return 4;
  }
}

/// 时间线事件
@freezed
class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    required String id,
    required String type,
    String? seekerName,
    int? durationMinutes,
    int? rating,
    String? thankYouNote,
    DateTime? createdAt,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
}

/// 时间线统计
@freezed
class TimelineStats with _$TimelineStats {
  const factory TimelineStats({
    @Default(0) int realtimeHelpCount,
    @Default(0) int asyncHelpCount,
    @Default(0) double averageRating,
    @Default(0) int fiveStarCount,
    String? mostHelpedSeekerId,
    String? mostHelpedSeekerName,
    @Default(0) int mostHelpedCount,
    @Default([]) List<String> topSkills,
  }) = _TimelineStats;

  factory TimelineStats.fromJson(Map<String, dynamic> json) =>
      _$TimelineStatsFromJson(json);
}

/// 年度报告模型
@freezed
class AnnualReport with _$AnnualReport {
  const factory AnnualReport({
    required String volunteerId,
    required int year,
    required String title,
    @Default([]) List<ReportSection> sections,
    DateTime? generatedAt,
  }) = _AnnualReport;

  factory AnnualReport.fromJson(Map<String, dynamic> json) =>
      _$AnnualReportFromJson(json);
}

/// 报告章节
@freezed
class ReportSection with _$ReportSection {
  const factory ReportSection({
    required String type,
    required String title,
    String? subtitle,
    Map<String, dynamic>? data,
  }) = _ReportSection;

  factory ReportSection.fromJson(Map<String, dynamic> json) =>
      _$ReportSectionFromJson(json);
}

/// 年度报告生成器
class AnnualReportGenerator {
  static AnnualReport generate(String volunteerId, int year, TimelineModel timeline) {
    final sections = <ReportSection>[
      ReportSection(
        type: 'summary',
        title: '年度总结',
        subtitle: '这一年，你帮助了${timeline.totalHelps}位求助者',
        data: {
          'totalHelps': timeline.totalHelps,
          'totalMinutes': timeline.totalMinutes,
          'streakDays': timeline.streakDays,
        },
      ),
      ReportSection(
        type: 'heatmap',
        title: '帮助热力图',
        subtitle: '每一天的善意都被记录',
      ),
      ReportSection(
        type: 'highlights',
        title: '高光时刻',
        subtitle: '你的最佳表现',
        data: {
          'mostActiveDay': _findMostActiveDay(timeline),
          'averageRating': timeline.stats?.averageRating ?? 0,
          'fiveStarCount': timeline.stats?.fiveStarCount ?? 0,
        },
      ),
      ReportSection(
        type: 'skills',
        title: '技能分布',
        subtitle: '你最擅长的领域',
        data: {
          'topSkills': timeline.stats?.topSkills ?? [],
        },
      ),
      ReportSection(
        type: 'quote',
        title: '年度寄语',
        subtitle: _generateQuote(timeline),
      ),
    ];

    return AnnualReport(
      volunteerId: volunteerId,
      year: year,
      title: '$year年度善意报告',
      sections: sections,
      generatedAt: DateTime.now(),
    );
  }

  static String _findMostActiveDay(TimelineModel timeline) {
    TimelineDay? mostActive;
    for (final day in timeline.days) {
      if (mostActive == null || day.helpCount > mostActive.helpCount) {
        mostActive = day;
      }
    }
    return mostActive?.date ?? '';
  }

  static String _generateQuote(TimelineModel timeline) {
    if (timeline.totalHelps >= 100) {
      return '你是真正的志愿之星，用善意点亮了100+个生命';
    } else if (timeline.totalHelps >= 50) {
      return '你的坚持让这个世界变得更美好';
    } else if (timeline.totalHelps >= 10) {
      return '每一次帮助都是一颗种子，终将开花结果';
    } else {
      return '志愿之路才刚刚开始，未来可期';
    }
  }
}
