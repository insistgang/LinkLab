import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_transaction_model.freezed.dart';
part 'point_transaction_model.g.dart';

/// 积分交易记录模型
/// 用于记录用户积分的增减流水
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

/// 积分交易类型
enum PointTransactionType {
  /// 每日签到
  dailyCheckIn,
  /// 连续7天签到奖励
  weeklyBonus,
  /// 连续30天签到奖励
  monthlyBonus,
  /// 完成实时帮助
  realtimeHelp,
  /// 完成异步帮助
  asyncHelp,
  /// 获得五星好评
  fiveStarRating,
  /// 连续7天帮助奖励
  continuousHelpBonus,
  /// 每日任务
  dailyTask,
  /// 被举报扣除
  penalty,
  /// 其他
  other,
}

/// 积分规则常量
class PointRules {
  /// 连续使用1天
  static const int dailyCheckIn = 1;
  /// 连续使用7天奖励
  static const int weeklyBonus = 10;
  /// 连续使用30天奖励
  static const int monthlyBonus = 50;
  /// 完成实时帮助
  static const int realtimeHelp = 10;
  /// 完成异步帮助
  static const int asyncHelp = 5;
  /// 获得五星好评
  static const int fiveStarRating = 3;
  /// 连续7天帮助奖励
  static const int continuousHelpBonus = 20;
  /// 每日任务
  static const int dailyTask = 2;
  /// 被举报扣除
  static const int penalty = -50;

  /// 获取类型描述
  static String getTypeDescription(PointTransactionType type) {
    switch (type) {
      case PointTransactionType.dailyCheckIn:
        return '每日签到';
      case PointTransactionType.weeklyBonus:
        return '连续7天签到奖励';
      case PointTransactionType.monthlyBonus:
        return '连续30天签到奖励';
      case PointTransactionType.realtimeHelp:
        return '完成实时帮助';
      case PointTransactionType.asyncHelp:
        return '完成异步帮助';
      case PointTransactionType.fiveStarRating:
        return '获得五星好评';
      case PointTransactionType.continuousHelpBonus:
        return '连续7天帮助奖励';
      case PointTransactionType.dailyTask:
        return '完成每日任务';
      case PointTransactionType.penalty:
        return '违规扣除';
      case PointTransactionType.other:
        return '其他';
    }
  }
}
