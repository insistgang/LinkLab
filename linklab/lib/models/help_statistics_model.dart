import 'package:freezed_annotation/freezed_annotation.dart';

part 'help_statistics_model.freezed.dart';
part 'help_statistics_model.g.dart';

/// 幫助統計數據模型（用於求助者中心）
@freezed
class HelpStatistics with _$HelpStatistics {
  const factory HelpStatistics({
    @Default(0) int totalRequests,
    @Default(0) int aiResolvedCount,
    @Default(0) int volunteerHelpCount,
    @Default(0) int sosCount,
    @Default(0.0) double aiResolutionRate,
    @Default(0) int totalDurationMinutes,
    @Default(0.0) double averageRating,
    @Default([]) List<HelpTypeStat> typeStats,
    @Default([]) List<MonthlyStat> monthlyStats,
    DateTime? lastUpdatedAt,
  }) = _HelpStatistics;

  factory HelpStatistics.fromJson(Map<String, dynamic> json) =>
      _$HelpStatisticsFromJson(json);

  const HelpStatistics._();

  /// AI解決率百分比文本
  String get aiResolutionRateText => '${(aiResolutionRate * 100).toStringAsFixed(1)}%';

  /// 最常用的求助類型
  String? get mostUsedType {
    if (typeStats.isEmpty) return null;
    final sorted = [...typeStats]..sort((a, b) => b.count.compareTo(a.count));
    return sorted.first.type;
  }
}

/// 求助類型統計
@freezed
class HelpTypeStat with _$HelpTypeStat {
  const factory HelpTypeStat({
    required String type,
    required int count,
    String? typeLabel,
  }) = _HelpTypeStat;

  factory HelpTypeStat.fromJson(Map<String, dynamic> json) =>
      _$HelpTypeStatFromJson(json);
}

/// 月度統計
@freezed
class MonthlyStat with _$MonthlyStat {
  const factory MonthlyStat({
    required String month,
    required int count,
    @Default(0) int aiCount,
    @Default(0) int volunteerCount,
  }) = _MonthlyStat;

  factory MonthlyStat.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatFromJson(json);
}

/// 幫助記錄篩選條件
class HelpRecordFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;
  final String? status;
  final bool? hasRating;

  const HelpRecordFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.status,
    this.hasRating,
  });

  /// 轉換爲查詢參數
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (hasRating != null) params['has_rating'] = hasRating;
    return params;
  }
}
