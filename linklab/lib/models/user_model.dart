import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// 用户模型
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String phone,
    String? name,
    String? avatarUrl,
    @Default(['seeker']) List<String> role,
    @Default([]) List<String> disabilityType,
    AccessibilityPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  const UserModel._();

  /// 是否拥有求助者角色
  bool get isSeeker => role.contains('seeker');

  /// 是否拥有志愿者角色
  bool get isVolunteer => role.contains('volunteer');

  /// 是否为视障用户
  bool get isVisualImpaired => disabilityType.contains('visual');

  /// 显示名称
  String get displayName => name ?? phone;
}

/// 无障碍偏好设置
@freezed
class AccessibilityPreferences with _$AccessibilityPreferences {
  const factory AccessibilityPreferences({
    @Default(false) bool highContrastMode,
    @Default(1.0) double fontScale,
    @Default(1.0) double voiceSpeed,
    @Default(true) bool hapticFeedback,
    @Default(true) bool voiceGuidance,
    @Default(true) bool autoReadResults,
    @Default('female') String voiceGender,
    @Default('standard') String voiceAccent,
  }) = _AccessibilityPreferences;

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) =>
      _$AccessibilityPreferencesFromJson(json);
}

/// 志愿者档案模型
@freezed
class VolunteerProfile with _$VolunteerProfile {
  const factory VolunteerProfile({
    required String userId,
    @Default([]) List<String> skills,
    @Default(1) int level,
    @Default(0) int points,
    @Default(5.0) double creditScore,
    @Default(false) bool isVerified,
    @Default(false) bool isOnline,
    DateTime? lastHeartbeatAt,
    int? totalHelpCount,
    double? latitude,
    double? longitude,
  }) = _VolunteerProfile;

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) =>
      _$VolunteerProfileFromJson(json);

  const VolunteerProfile._();

  /// 等级名称
  String get levelName {
    switch (level) {
      case 1:
        return '初心者';
      case 2:
        return '见习志愿者';
      case 3:
        return '正式志愿者';
      case 4:
        return '资深志愿者';
      case 5:
        return '专家志愿者';
      case 6:
        return '大师志愿者';
      case 7:
        return '传奇志愿者';
      default:
        return '初心者';
    }
  }
}
