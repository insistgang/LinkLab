import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_volunteer_model.freezed.dart';
part 'favorite_volunteer_model.g.dart';

/// 常用志愿者关系模型
@freezed
class FavoriteVolunteerModel with _$FavoriteVolunteerModel {
  const factory FavoriteVolunteerModel({
    required String id,
    required String seekerId,
    required String volunteerId,
    String? name,
    String? avatarUrl,
    @Default(1) int cooperationCount,
    double? averageRating,
    DateTime? lastCooperationAt,
    DateTime? createdAt,
  }) = _FavoriteVolunteerModel;

  factory FavoriteVolunteerModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteVolunteerModelFromJson(json);

  const FavoriteVolunteerModel._();

  /// 获取合作次数文本
  String get cooperationText {
    if (cooperationCount == 1) return '首次合作';
    if (cooperationCount < 10) return '第$cooperationCount次合作';
    return '已合作$cooperationCount次';
  }

  /// 是否为亲密志愿者（合作3次以上）
  bool get isClosePartner => cooperationCount >= 3;

  /// 志愿者名称（兼容字段）
  String? get volunteerName => name;

  /// 志愿者头像（兼容字段）
  String? get volunteerAvatar => avatarUrl;
}

/// 常用志愿者统计信息
@freezed
class FavoriteVolunteerStats with _$FavoriteVolunteerStats {
  const factory FavoriteVolunteerStats({
    @Default(0) int totalFavorites,
    @Default(0) int totalCooperations,
    String? mostFrequentVolunteerId,
    String? mostFrequentVolunteerName,
  }) = _FavoriteVolunteerStats;

  factory FavoriteVolunteerStats.fromJson(Map<String, dynamic> json) =>
      _$FavoriteVolunteerStatsFromJson(json);
}
