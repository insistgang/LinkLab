// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_level_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAuthStatusImpl _$$UserAuthStatusImplFromJson(Map<String, dynamic> json) =>
    _$UserAuthStatusImpl(
      userId: json['userId'] as String,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      realNameVerified: json['realNameVerified'] as bool? ?? false,
      disabledCertVerified: json['disabledCertVerified'] as bool? ?? false,
      skillCerts:
          (json['skillCerts'] as List<dynamic>?)
              ?.map(
                (e) => SkillCertification.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      realName: json['realName'] as String?,
      idCardNumber: json['idCardNumber'] as String?,
      disabledCertImageUrl: json['disabledCertImageUrl'] as String?,
      phoneVerifiedAt: json['phoneVerifiedAt'] == null
          ? null
          : DateTime.parse(json['phoneVerifiedAt'] as String),
      realNameVerifiedAt: json['realNameVerifiedAt'] == null
          ? null
          : DateTime.parse(json['realNameVerifiedAt'] as String),
      disabledCertVerifiedAt: json['disabledCertVerifiedAt'] == null
          ? null
          : DateTime.parse(json['disabledCertVerifiedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserAuthStatusImplToJson(
  _$UserAuthStatusImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'phoneVerified': instance.phoneVerified,
  'realNameVerified': instance.realNameVerified,
  'disabledCertVerified': instance.disabledCertVerified,
  'skillCerts': instance.skillCerts,
  'realName': instance.realName,
  'idCardNumber': instance.idCardNumber,
  'disabledCertImageUrl': instance.disabledCertImageUrl,
  'phoneVerifiedAt': instance.phoneVerifiedAt?.toIso8601String(),
  'realNameVerifiedAt': instance.realNameVerifiedAt?.toIso8601String(),
  'disabledCertVerifiedAt': instance.disabledCertVerifiedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$SkillCertificationImpl _$$SkillCertificationImplFromJson(
  Map<String, dynamic> json,
) => _$SkillCertificationImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  skillName: json['skillName'] as String,
  skillCode: json['skillCode'] as String?,
  certificateImageUrl: json['certificateImageUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  rejectReason: json['rejectReason'] as String?,
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  verifiedAt: json['verifiedAt'] == null
      ? null
      : DateTime.parse(json['verifiedAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$$SkillCertificationImplToJson(
  _$SkillCertificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'skillName': instance.skillName,
  'skillCode': instance.skillCode,
  'certificateImageUrl': instance.certificateImageUrl,
  'isVerified': instance.isVerified,
  'rejectReason': instance.rejectReason,
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'verifiedAt': instance.verifiedAt?.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
};

_$CertificationApplicationImpl _$$CertificationApplicationImplFromJson(
  Map<String, dynamic> json,
) => _$CertificationApplicationImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  authLevel: $enumDecode(_$AuthLevelEnumMap, json['authLevel']),
  status: $enumDecode(_$CertificationStatusEnumMap, json['status']),
  skillName: json['skillName'] as String?,
  certificateImageUrl: json['certificateImageUrl'] as String?,
  idCardNumber: json['idCardNumber'] as String?,
  realName: json['realName'] as String?,
  rejectReason: json['rejectReason'] as String?,
  reviewerId: json['reviewerId'] as String?,
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$CertificationApplicationImplToJson(
  _$CertificationApplicationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'authLevel': _$AuthLevelEnumMap[instance.authLevel]!,
  'status': _$CertificationStatusEnumMap[instance.status]!,
  'skillName': instance.skillName,
  'certificateImageUrl': instance.certificateImageUrl,
  'idCardNumber': instance.idCardNumber,
  'realName': instance.realName,
  'rejectReason': instance.rejectReason,
  'reviewerId': instance.reviewerId,
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$AuthLevelEnumMap = {
  AuthLevel.phone: 'phone',
  AuthLevel.realName: 'realName',
  AuthLevel.disabledCert: 'disabledCert',
  AuthLevel.skillCert: 'skillCert',
};

const _$CertificationStatusEnumMap = {
  CertificationStatus.pending: 'pending',
  CertificationStatus.approved: 'approved',
  CertificationStatus.rejected: 'rejected',
  CertificationStatus.expired: 'expired',
};
