import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_transaction_model.freezed.dart';
part 'point_transaction_model.g.dart';

/// 積分交易記錄模型
/// 用於記錄用戶積分的增減流水
@freezed
class PointTransactionModel with _$PointTransactionModel {
  const factory PointTransactionModel({
    required String id,
    required String userId,
    required int points,
    required PointTransactionType type,
    String? description,
    String? relatedId,
    @Default(false) bool isPositive,
    DateTime? createdAt,
  }) = _PointTransactionModel;

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$PointTransactionModelFromJson(json);
}

/// 積分交易類型
enum PointTransactionType {
  /// 每日簽到
  dailyCheckIn,
  /// 連續7天簽到獎勵
  weeklyBonus,
  /// 連續30天簽到獎勵
  monthlyBonus,
  /// 完成實時幫助
  realtimeHelp,
  /// 完成異步幫助
  asyncHelp,
  /// 獲得五星好評
  fiveStarRating,
  /// 連續7天幫助獎勵
  continuousHelpBonus,
  /// 每日任務
  dailyTask,
  /// 被舉報扣除
  penalty,
  /// 其他
  other,
}

/// 積分規則常量
class PointRules {
  /// 連續使用1天
  static const int dailyCheckIn = 1;
  /// 連續使用7天獎勵
  static const int weeklyBonus = 10;
  /// 連續使用30天獎勵
  static const int monthlyBonus = 50;
  /// 完成實時幫助
  static const int realtimeHelp = 10;
  /// 完成異步幫助
  static const int asyncHelp = 5;
  /// 獲得五星好評
  static const int fiveStarRating = 3;
  /// 連續7天幫助獎勵
  static const int continuousHelpBonus = 20;
  /// 每日任務
  static const int dailyTask = 2;
  /// 被舉報扣除
  static const int penalty = -50;

  /// 獲取類型描述
  static String getTypeDescription(PointTransactionType type) {
    switch (type) {
      case PointTransactionType.dailyCheckIn:
        return '每日簽到';
      case PointTransactionType.weeklyBonus:
        return '連續7天簽到獎勵';
      case PointTransactionType.monthlyBonus:
        return '連續30天簽到獎勵';
      case PointTransactionType.realtimeHelp:
        return '完成實時幫助';
      case PointTransactionType.asyncHelp:
        return '完成異步幫助';
      case PointTransactionType.fiveStarRating:
        return '獲得五星好評';
      case PointTransactionType.continuousHelpBonus:
        return '連續7天幫助獎勵';
      case PointTransactionType.dailyTask:
        return '完成每日任務';
      case PointTransactionType.penalty:
        return '違規扣除';
      case PointTransactionType.other:
        return '其他';
    }
  }
}
