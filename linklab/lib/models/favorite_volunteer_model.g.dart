// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_volunteer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FavoriteVolunteerModelImpl _$$FavoriteVolunteerModelImplFromJson(
  Map<String, dynamic> json,
) => _$FavoriteVolunteerModelImpl(
  id: json['id'] as String,
  seekerId: json['seekerId'] as String,
  volunteerId: json['volunteerId'] as String,
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  cooperationCount: (json['cooperationCount'] as num?)?.toInt() ?? 1,
  averageRating: (json['averageRating'] as num?)?.toDouble(),
  lastCooperationAt: json['lastCooperationAt'] == null
      ? null
      : DateTime.parse(json['lastCooperationAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$FavoriteVolunteerModelImplToJson(
  _$FavoriteVolunteerModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'seekerId': instance.seekerId,
  'volunteerId': instance.volunteerId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'cooperationCount': instance.cooperationCount,
  'averageRating': instance.averageRating,
  'lastCooperationAt': instance.lastCooperationAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};

_$FavoriteVolunteerStatsImpl _$$FavoriteVolunteerStatsImplFromJson(
  Map<String, dynamic> json,
) => _$FavoriteVolunteerStatsImpl(
  totalFavorites: (json['totalFavorites'] as num?)?.toInt() ?? 0,
  totalCooperations: (json['totalCooperations'] as num?)?.toInt() ?? 0,
  mostFrequentVolunteerId: json['mostFrequentVolunteerId'] as String?,
  mostFrequentVolunteerName: json['mostFrequentVolunteerName'] as String?,
);

Map<String, dynamic> _$$FavoriteVolunteerStatsImplToJson(
  _$FavoriteVolunteerStatsImpl instance,
) => <String, dynamic>{
  'totalFavorites': instance.totalFavorites,
  'totalCooperations': instance.totalCooperations,
  'mostFrequentVolunteerId': instance.mostFrequentVolunteerId,
  'mostFrequentVolunteerName': instance.mostFrequentVolunteerName,
};
