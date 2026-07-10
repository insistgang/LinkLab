import 'package:freezed_annotation/freezed_annotation.dart';

part 'help_statistics_model.freezed.dart';
part 'help_statistics_model.g.dart';

/// 帮助统计数据模型（用于求助者中心）
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

  /// AI解决率百分比文本
  String get aiResolutionRateText => '${(aiResolutionRate * 100).toStringAsFixed(1)}%';

  /// 最常用的求助类型
  String? get mostUsedType {
    if (typeStats.isEmpty) return null;
    final sorted = [...typeStats]..sort((a, b) => b.count.compareTo(a.count));
    return sorted.first.type;
  }
}

/// 求助类型统计
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

/// 月度统计
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

/// 帮助记录筛选条件
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

  /// 转换为查询参数
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
