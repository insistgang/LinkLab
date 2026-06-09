import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_score_model.freezed.dart';
part 'credit_score_model.g.dart';

/// 信用分模型
@freezed
class CreditScore with _$CreditScore {
  const factory CreditScore({
    required String userId,
    @Default(5.0) double score,
    @Default(0) int totalRatings,
    @Default(0) int positiveRatings,
    @Default(0) int negativeRatings,
    @Default(0) int consecutiveGoodRatings,
    DateTime? lastRatingAt,
    DateTime? lastViolationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CreditScore;

  factory CreditScore.fromJson(Map<String, dynamic> json) =>
      _$CreditScoreFromJson(json);

  const CreditScore._();

  /// 信用等級
  CreditLevel get creditLevel {
    if (score >= 4.5) return CreditLevel.excellent;
    if (score >= 4.0) return CreditLevel.good;
    if (score >= 3.5) return CreditLevel.fair;
    return CreditLevel.poor;
  }

  /// 匹配權重係數
  double get matchingWeight {
    if (score >= 4.5) return 1.0;
    if (score >= 4.0) return 0.8;
    if (score >= 3.5) return 0.5;
    return 0.0;
  }

  /// 是否可以匹配
  bool get canMatch => score >= 3.5;

  /// 好評率
  double get positiveRate =>
      totalRatings > 0 ? positiveRatings / totalRatings : 1.0;
}

/// 信用等級
enum CreditLevel {
  excellent, // 優秀 (4.5-5.0)
  good,      // 良好 (4.0-4.5)
  fair,      // 一般 (3.5-4.0)
  poor,      // 較差 (<3.5)
}

extension CreditLevelExtension on CreditLevel {
  String get label {
    switch (this) {
      case CreditLevel.excellent:
        return '信用優秀';
      case CreditLevel.good:
        return '信用良好';
      case CreditLevel.fair:
        return '信用一般';
      case CreditLevel.poor:
        return '信用較差';
    }
  }

  String get description {
    switch (this) {
      case CreditLevel.excellent:
        return '正常匹配權重';
      case CreditLevel.good:
        return '匹配權重×0.8';
      case CreditLevel.fair:
        return '匹配權重×0.5，限制匹配頻率';
      case CreditLevel.poor:
        return '暫停匹配，需人工審覈';
    }
  }

  String get color {
    switch (this) {
      case CreditLevel.excellent:
        return '#4CAF50';
      case CreditLevel.good:
        return '#8BC34A';
      case CreditLevel.fair:
        return '#FFC107';
      case CreditLevel.poor:
        return '#F44336';
    }
  }
}

/// 評價記錄模型
@freezed
class RatingRecord with _$RatingRecord {
  const factory RatingRecord({
    required String id,
    required String callId,
    required String helpRequestId,
    required String fromUserId,
    required String toUserId,
    required int rating, // 1-5星
    String? comment,
    @Default([]) List<String> tags,
    @Default(false) bool isSeekerToVolunteer,
    DateTime? createdAt,
  }) = _RatingRecord;

  factory RatingRecord.fromJson(Map<String, dynamic> json) =>
      _$RatingRecordFromJson(json);

  const RatingRecord._();

  /// 是否爲好評
  bool get isPositive => rating >= 4;

  /// 是否爲差評
  bool get isNegative => rating <= 3;
}

/// 信用分變動記錄
@freezed
class CreditScoreChange with _$CreditScoreChange {
  const factory CreditScoreChange({
    required String id,
    required String userId,
    required double change,
    required double scoreBefore,
    required double scoreAfter,
    required CreditChangeReason reason,
    String? relatedId, // 關聯的評價ID或舉報ID
    String? description,
    DateTime? createdAt,
  }) = _CreditScoreChange;

  factory CreditScoreChange.fromJson(Map<String, dynamic> json) =>
      _$CreditScoreChangeFromJson(json);
}

/// 信用分變動原因
enum CreditChangeReason {
  rating5Star,           // 獲得5星評價
  rating4Star,           // 獲得4星評價
  rating3StarOrBelow,    // 獲得3星及以下評價
  validReport,           // 被有效舉報
  consecutiveGoodBonus,  // 連續好評獎勵
  monthlyNoViolation,    // 月度無違規獎勵
  manualAdjustment,      // 人工調整
}

extension CreditChangeReasonExtension on CreditChangeReason {
  String get label {
    switch (this) {
      case CreditChangeReason.rating5Star:
        return '獲得5星評價';
      case CreditChangeReason.rating4Star:
        return '獲得4星評價';
      case CreditChangeReason.rating3StarOrBelow:
        return '獲得差評';
      case CreditChangeReason.validReport:
        return '被有效舉報';
      case CreditChangeReason.consecutiveGoodBonus:
        return '連續好評獎勵';
      case CreditChangeReason.monthlyNoViolation:
        return '月度無違規獎勵';
      case CreditChangeReason.manualAdjustment:
        return '人工調整';
    }
  }

  double get defaultChange {
    switch (this) {
      case CreditChangeReason.rating5Star:
        return 0.1;
      case CreditChangeReason.rating4Star:
        return 0.05;
      case CreditChangeReason.rating3StarOrBelow:
        return -0.2;
      case CreditChangeReason.validReport:
        return -1.0;
      case CreditChangeReason.consecutiveGoodBonus:
        return 0.3;
      case CreditChangeReason.monthlyNoViolation:
        return 0.1;
      case CreditChangeReason.manualAdjustment:
        return 0.0;
    }
  }
}

/// 信用分計算結果
class CreditScoreCalculation {
  final double newScore;
  final List<CreditScoreChange> changes;
  final String summary;

  CreditScoreCalculation({
    required this.newScore,
    required this.changes,
    required this.summary,
  });
}
