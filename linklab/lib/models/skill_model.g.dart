// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkillModelImpl _$$SkillModelImplFromJson(Map<String, dynamic> json) =>
    _$SkillModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      requiresVerification: json['requiresVerification'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      certificateUrl: json['certificateUrl'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
    );

Map<String, dynamic> _$$SkillModelImplToJson(_$SkillModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'requiresVerification': instance.requiresVerification,
      'isVerified': instance.isVerified,
      'certificateUrl': instance.certificateUrl,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
    };

_$SkillVerificationRequestImpl _$$SkillVerificationRequestImplFromJson(
  Map<String, dynamic> json,
) => _$SkillVerificationRequestImpl(
  id: json['id'] as String,
  volunteerId: json['volunteerId'] as String,
  skillId: json['skillId'] as String,
  skillName: json['skillName'] as String?,
  certificateUrl: json['certificateUrl'] as String?,
  description: json['description'] as String?,
  status: json['status'] as String? ?? 'pending',
  reviewerNote: json['reviewerNote'] as String?,
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
);

Map<String, dynamic> _$$SkillVerificationRequestImplToJson(
  _$SkillVerificationRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'volunteerId': instance.volunteerId,
  'skillId': instance.skillId,
  'skillName': instance.skillName,
  'certificateUrl': instance.certificateUrl,
  'description': instance.description,
  'status': instance.status,
  'reviewerNote': instance.reviewerNote,
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
};
