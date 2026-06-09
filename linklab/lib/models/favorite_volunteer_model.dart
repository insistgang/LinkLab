import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_volunteer_model.freezed.dart';
part 'favorite_volunteer_model.g.dart';

/// 常用志願者關係模型
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

  /// 獲取合作次數文本
  String get cooperationText {
    if (cooperationCount == 1) return '首次合作';
    if (cooperationCount < 10) return '第$cooperationCount次合作';
    return '已合作$cooperationCount次';
  }

  /// 是否爲親密志願者（合作3次以上）
  bool get isClosePartner => cooperationCount >= 3;

  /// 志願者名稱（兼容字段）
  String? get volunteerName => name;

  /// 志願者頭像（兼容字段）
  String? get volunteerAvatar => avatarUrl;
}

/// 常用志願者統計信息
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
