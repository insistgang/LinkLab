import '../constants/app_constants.dart';

// 用戶模型
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final Map<String, dynamic>? metadata;

  // 殘障用戶額外信息
  final String? disabilityType;
  final String? disabilityDescription;
  final VerificationStatus? verificationStatus;
  final String? disabilityCertificateUrl;

  // 志願者額外信息
  final String? volunteerLevel;
  final int? volunteerPoints;
  final List<String>? skills;
  final double? rating;
  final int? totalCalls;
  final int? totalHelpMinutes;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.avatarUrl,
    this.role = UserRole.operator,
    this.status = UserStatus.active,
    required this.createdAt,
    this.lastSignInAt,
    this.metadata,
    this.disabilityType,
    this.disabilityDescription,
    this.verificationStatus,
    this.disabilityCertificateUrl,
    this.volunteerLevel,
    this.volunteerPoints,
    this.skills,
    this.rating,
    this.totalCalls,
    this.totalHelpMinutes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.operator,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'])
          : null,
      metadata: json['metadata'],
      disabilityType: json['disability_type'],
      disabilityDescription: json['disability_description'],
      verificationStatus: json['verification_status'] != null
          ? VerificationStatus.values.firstWhere(
              (e) => e.name == json['verification_status'],
              orElse: () => VerificationStatus.pending,
            )
          : null,
      disabilityCertificateUrl: json['disability_certificate_url'],
      volunteerLevel: json['volunteer_level'],
      volunteerPoints: json['volunteer_points'],
      skills: json['skills'] != null
          ? List<String>.from(json['skills'])
          : null,
      rating: json['rating']?.toDouble(),
      totalCalls: json['total_calls'],
      totalHelpMinutes: json['total_help_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'metadata': metadata,
      'disability_type': disabilityType,
      'disability_description': disabilityDescription,
      'verification_status': verificationStatus?.name,
      'disability_certificate_url': disabilityCertificateUrl,
      'volunteer_level': volunteerLevel,
      'volunteer_points': volunteerPoints,
      'skills': skills,
      'rating': rating,
      'total_calls': totalCalls,
      'total_help_minutes': totalHelpMinutes,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
    String? disabilityType,
    String? disabilityDescription,
    VerificationStatus? verificationStatus,
    String? disabilityCertificateUrl,
    String? volunteerLevel,
    int? volunteerPoints,
    List<String>? skills,
    double? rating,
    int? totalCalls,
    int? totalHelpMinutes,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      metadata: metadata ?? this.metadata,
      disabilityType: disabilityType ?? this.disabilityType,
      disabilityDescription: disabilityDescription ?? this.disabilityDescription,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      disabilityCertificateUrl:
          disabilityCertificateUrl ?? this.disabilityCertificateUrl,
      volunteerLevel: volunteerLevel ?? this.volunteerLevel,
      volunteerPoints: volunteerPoints ?? this.volunteerPoints,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalCalls: totalCalls ?? this.totalCalls,
      totalHelpMinutes: totalHelpMinutes ?? this.totalHelpMinutes,
    );
  }

  String get statusText {
    switch (status) {
      case UserStatus.active:
        return '正常';
      case UserStatus.banned:
        return '已封禁';
      case UserStatus.pending:
        return '待審覈';
    }
  }

  String get verificationText {
    switch (verificationStatus) {
      case VerificationStatus.pending:
        return '待審覈';
      case VerificationStatus.approved:
        return '已通過';
      case VerificationStatus.rejected:
        return '已拒絕';
      default:
        return '未提交';
    }
  }

  String get roleText {
    switch (role) {
      case UserRole.superAdmin:
        return '超級管理員';
      case UserRole.admin:
        return '管理員';
      case UserRole.operator:
        return '運營人員';
    }
  }
}

// 用戶列表響應
class UserListResponse {
  final List<UserModel> users;
  final int total;
  final int page;
  final int pageSize;

  UserListResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
  });
}
