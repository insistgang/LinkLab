import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_level_model.freezed.dart';
part 'auth_level_model.g.dart';

/// 认证等级枚举
enum AuthLevel {
  phone,        // 手机号认证
  realName,     // 实名认证
  disabledCert, // 残障证明（求助者）
  skillCert,    // 技能认证（志愿者）
}

/// 认证等级扩展
extension AuthLevelExtension on AuthLevel {
  String get label {
    switch (this) {
      case AuthLevel.phone:
        return '手机认证';
      case AuthLevel.realName:
        return '实名认证';
      case AuthLevel.disabledCert:
        return '残障证明';
      case AuthLevel.skillCert:
        return '技能认证';
    }
  }

  String get description {
    switch (this) {
      case AuthLevel.phone:
        return '已完成手机号验证';
      case AuthLevel.realName:
        return '已完成实名认证';
      case AuthLevel.disabledCert:
        return '已上传残障证明，获得优先匹配权';
      case AuthLevel.skillCert:
        return '已完成专业技能认证';
    }
  }

  int get priority {
    switch (this) {
      case AuthLevel.phone:
        return 1;
      case AuthLevel.realName:
        return 2;
      case AuthLevel.disabledCert:
        return 3;
      case AuthLevel.skillCert:
        return 3;
    }
  }
}

/// 用户认证状态模型
@freezed
class UserAuthStatus with _$UserAuthStatus {
  const factory UserAuthStatus({
    required String userId,
    @Default(false) bool phoneVerified,
    @Default(false) bool realNameVerified,
    @Default(false) bool disabledCertVerified,
    @Default([]) List<SkillCertification> skillCerts,
    String? realName,
    String? idCardNumber,
    String? disabledCertImageUrl,
    DateTime? phoneVerifiedAt,
    DateTime? realNameVerifiedAt,
    DateTime? disabledCertVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserAuthStatus;

  factory UserAuthStatus.fromJson(Map<String, dynamic> json) =>
      _$UserAuthStatusFromJson(json);

  const UserAuthStatus._();

  /// 获取当前最高认证等级
  AuthLevel get currentLevel {
    if (disabledCertVerified) return AuthLevel.disabledCert;
    if (skillCerts.any((cert) => cert.isVerified)) return AuthLevel.skillCert;
    if (realNameVerified) return AuthLevel.realName;
    if (phoneVerified) return AuthLevel.phone;
    return AuthLevel.phone;
  }

  /// 是否已完成基础认证（手机+实名）
  bool get isBasicVerified => phoneVerified && realNameVerified;

  /// 是否拥有优先认证（残障证明）
  bool get hasPriority => disabledCertVerified;

  /// 已认证的技能列表
  List<SkillCertification> get verifiedSkills =>
      skillCerts.where((cert) => cert.isVerified).toList();
}

/// 技能认证模型
@freezed
class SkillCertification with _$SkillCertification {
  const factory SkillCertification({
    required String id,
    required String userId,
    required String skillName,
    String? skillCode,
    String? certificateImageUrl,
    @Default(false) bool isVerified,
    String? rejectReason,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? expiresAt,
  }) = _SkillCertification;

  factory SkillCertification.fromJson(Map<String, dynamic> json) =>
      _$SkillCertificationFromJson(json);
}

/// 认证申请状态
enum CertificationStatus {
  pending,   // 待审核
  approved,  // 已通过
  rejected,  // 已拒绝
  expired,   // 已过期
}

/// 认证申请记录
@freezed
class CertificationApplication with _$CertificationApplication {
  const factory CertificationApplication({
    required String id,
    required String userId,
    required AuthLevel authLevel,
    required CertificationStatus status,
    String? skillName,
    String? certificateImageUrl,
    String? idCardNumber,
    String? realName,
    String? rejectReason,
    String? reviewerId,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) = _CertificationApplication;

  factory CertificationApplication.fromJson(Map<String, dynamic> json) =>
      _$CertificationApplicationFromJson(json);
}
