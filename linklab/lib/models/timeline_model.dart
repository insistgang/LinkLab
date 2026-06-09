import 'package:freezed_annotation/freezed_annotation.dart';

part 'timeline_model.freezed.dart';
part 'timeline_model.g.dart';

/// 善意時間線數據模型
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

/// 時間線單日數據
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

  /// 活躍度級別（用於熱力圖顏色）
  int get activityLevel {
    if (helpCount == 0) return 0;
    if (helpCount == 1) return 1;
    if (helpCount <= 3) return 2;
    if (helpCount <= 5) return 3;
    return 4;
  }
}

/// 時間線事件
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

/// 時間線統計
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

/// 年度報告模型
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

/// 報告章節
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

/// 年度報告生成器
class AnnualReportGenerator {
  static AnnualReport generate(String volunteerId, int year, TimelineModel timeline) {
    final sections = <ReportSection>[
      ReportSection(
        type: 'summary',
        title: '年度總結',
        subtitle: '這一年，你幫助了${timeline.totalHelps}位求助者',
        data: {
          'totalHelps': timeline.totalHelps,
          'totalMinutes': timeline.totalMinutes,
          'streakDays': timeline.streakDays,
        },
      ),
      ReportSection(
        type: 'heatmap',
        title: '幫助熱力圖',
        subtitle: '每一天的善意都被記錄',
      ),
      ReportSection(
        type: 'highlights',
        title: '高光時刻',
        subtitle: '你的最佳表現',
        data: {
          'mostActiveDay': _findMostActiveDay(timeline),
          'averageRating': timeline.stats?.averageRating ?? 0,
          'fiveStarCount': timeline.stats?.fiveStarCount ?? 0,
        },
      ),
      ReportSection(
        type: 'skills',
        title: '技能分佈',
        subtitle: '你最擅長的領域',
        data: {
          'topSkills': timeline.stats?.topSkills ?? [],
        },
      ),
      ReportSection(
        type: 'quote',
        title: '年度寄語',
        subtitle: _generateQuote(timeline),
      ),
    ];

    return AnnualReport(
      volunteerId: volunteerId,
      year: year,
      title: '$year年度善意報告',
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
      return '你是真正的志願之星，用善意點亮了100+個生命';
    } else if (timeline.totalHelps >= 50) {
      return '你的堅持讓這個世界變得更美好';
    } else if (timeline.totalHelps >= 10) {
      return '每一次幫助都是一顆種子，終將開花結果';
    } else {
      return '志願之路纔剛剛開始，未來可期';
    }
  }
}
