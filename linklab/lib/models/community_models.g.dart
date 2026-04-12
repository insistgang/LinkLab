// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InterestGroupImpl _$$InterestGroupImplFromJson(Map<String, dynamic> json) =>
    _$InterestGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      iconUrl: json['iconUrl'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      isJoined: json['isJoined'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$InterestGroupImplToJson(_$InterestGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'iconUrl': instance.iconUrl,
      'memberCount': instance.memberCount,
      'postCount': instance.postCount,
      'isJoined': instance.isJoined,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$GroupMessageImpl _$$GroupMessageImplFromJson(Map<String, dynamic> json) =>
    _$GroupMessageImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$GroupMessageImplToJson(_$GroupMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'content': instance.content,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
      'attachments': instance.attachments,
      'likeCount': instance.likeCount,
      'isLiked': instance.isLiked,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$RegionalCommunityImpl _$$RegionalCommunityImplFromJson(
  Map<String, dynamic> json,
) => _$RegionalCommunityImpl(
  id: json['id'] as String,
  city: json['city'] as String,
  province: json['province'] as String,
  description: json['description'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
  eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
  isJoined: json['isJoined'] as bool? ?? false,
  coverImage: json['coverImage'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$RegionalCommunityImplToJson(
  _$RegionalCommunityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'city': instance.city,
  'province': instance.province,
  'description': instance.description,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'memberCount': instance.memberCount,
  'eventCount': instance.eventCount,
  'isJoined': instance.isJoined,
  'coverImage': instance.coverImage,
  'createdAt': instance.createdAt?.toIso8601String(),
};

_$CommunityEventImpl _$$CommunityEventImplFromJson(Map<String, dynamic> json) =>
    _$CommunityEventImpl(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
      coverImage: json['coverImage'] as String?,
      status: json['status'] as String? ?? 'upcoming',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CommunityEventImplToJson(
  _$CommunityEventImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'communityId': instance.communityId,
  'title': instance.title,
  'description': instance.description,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'location': instance.location,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'participantCount': instance.participantCount,
  'maxParticipants': instance.maxParticipants,
  'coverImage': instance.coverImage,
  'status': instance.status,
  'createdAt': instance.createdAt?.toIso8601String(),
};

_$FeaturedStoryImpl _$$FeaturedStoryImplFromJson(Map<String, dynamic> json) =>
    _$FeaturedStoryImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      coverImage: json['coverImage'] as String?,
      authorType: json['authorType'] as String? ?? 'anonymous',
      authorName: json['authorName'] as String?,
      authorAvatar: json['authorAvatar'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      featuredDate: json['featuredDate'] == null
          ? null
          : DateTime.parse(json['featuredDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FeaturedStoryImplToJson(_$FeaturedStoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'summary': instance.summary,
      'coverImage': instance.coverImage,
      'authorType': instance.authorType,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'likeCount': instance.likeCount,
      'readCount': instance.readCount,
      'isLiked': instance.isLiked,
      'status': instance.status,
      'featuredDate': instance.featuredDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$NewbieTrainingImpl _$$NewbieTrainingImplFromJson(Map<String, dynamic> json) =>
    _$NewbieTrainingImpl(
      id: json['id'] as String,
      volunteerId: json['volunteerId'] as String,
      completedScenarios: (json['completedScenarios'] as num?)?.toInt() ?? 0,
      totalScenarios: (json['totalScenarios'] as num?)?.toInt() ?? 3,
      isGraduated: json['isGraduated'] as bool? ?? false,
      mentorId: json['mentorId'] as String?,
      mentorName: json['mentorName'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      graduatedAt: json['graduatedAt'] == null
          ? null
          : DateTime.parse(json['graduatedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$NewbieTrainingImplToJson(
  _$NewbieTrainingImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'volunteerId': instance.volunteerId,
  'completedScenarios': instance.completedScenarios,
  'totalScenarios': instance.totalScenarios,
  'isGraduated': instance.isGraduated,
  'mentorId': instance.mentorId,
  'mentorName': instance.mentorName,
  'startedAt': instance.startedAt?.toIso8601String(),
  'graduatedAt': instance.graduatedAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$TrainingScenarioImpl _$$TrainingScenarioImplFromJson(
  Map<String, dynamic> json,
) => _$TrainingScenarioImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  type: json['type'] as String,
  imageUrl: json['imageUrl'] as String?,
  audioUrl: json['audioUrl'] as String?,
  hints:
      (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  expectedActions:
      (json['expectedActions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isCompleted: json['isCompleted'] as bool? ?? false,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$$TrainingScenarioImplToJson(
  _$TrainingScenarioImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'type': instance.type,
  'imageUrl': instance.imageUrl,
  'audioUrl': instance.audioUrl,
  'hints': instance.hints,
  'expectedActions': instance.expectedActions,
  'isCompleted': instance.isCompleted,
  'completedAt': instance.completedAt?.toIso8601String(),
};

_$ModerationResultImpl _$$ModerationResultImplFromJson(
  Map<String, dynamic> json,
) => _$ModerationResultImpl(
  isApproved: json['isApproved'] as bool,
  confidence: (json['confidence'] as num).toDouble(),
  category: json['category'] as String?,
  reason: json['reason'] as String?,
  flaggedKeywords:
      (json['flaggedKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$ModerationResultImplToJson(
  _$ModerationResultImpl instance,
) => <String, dynamic>{
  'isApproved': instance.isApproved,
  'confidence': instance.confidence,
  'category': instance.category,
  'reason': instance.reason,
  'flaggedKeywords': instance.flaggedKeywords,
};
