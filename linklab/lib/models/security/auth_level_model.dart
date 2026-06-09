import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_level_model.freezed.dart';
part 'auth_level_model.g.dart';

/// 認證等級枚舉
enum AuthLevel {
  phone,        // 手機號認證
  realName,     // 實名認證
  disabledCert, // 殘障證明（求助者）
  skillCert,    // 技能認證（志願者）
}

/// 認證等級擴展
extension AuthLevelExtension on AuthLevel {
  String get label {
    switch (this) {
      case AuthLevel.phone:
        return '手機認證';
      case AuthLevel.realName:
        return '實名認證';
      case AuthLevel.disabledCert:
        return '殘障證明';
      case AuthLevel.skillCert:
        return '技能認證';
    }
  }

  String get description {
    switch (this) {
      case AuthLevel.phone:
        return '已完成手機號驗證';
      case AuthLevel.realName:
        return '已完成實名認證';
      case AuthLevel.disabledCert:
        return '已上傳殘障證明，獲得優先匹配權';
      case AuthLevel.skillCert:
        return '已完成專業技能認證';
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

/// 用戶認證狀態模型
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

  /// 獲取當前最高認證等級
  AuthLevel get currentLevel {
    if (disabledCertVerified) return AuthLevel.disabledCert;
    if (skillCerts.any((cert) => cert.isVerified)) return AuthLevel.skillCert;
    if (realNameVerified) return AuthLevel.realName;
    if (phoneVerified) return AuthLevel.phone;
    return AuthLevel.phone;
  }

  /// 是否已完成基礎認證（手機+實名）
  bool get isBasicVerified => phoneVerified && realNameVerified;

  /// 是否擁有優先認證（殘障證明）
  bool get hasPriority => disabledCertVerified;

  /// 已認證的技能列表
  List<SkillCertification> get verifiedSkills =>
      skillCerts.where((cert) => cert.isVerified).toList();
}

/// 技能認證模型
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

/// 認證申請狀態
enum CertificationStatus {
  pending,   // 待審覈
  approved,  // 已通過
  rejected,  // 已拒絕
  expired,   // 已過期
}

/// 認證申請記錄
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
