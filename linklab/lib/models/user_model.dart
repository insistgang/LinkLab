import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// 用戶模型
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

  /// 是否擁有求助者角色
  bool get isSeeker => role.contains('seeker');

  /// 是否擁有志願者角色
  bool get isVolunteer => role.contains('volunteer');

  /// 是否爲視障用戶
  bool get isVisualImpaired => disabilityType.contains('visual');

  /// 顯示名稱
  String get displayName => name ?? phone;
}

/// 無障礙偏好設置
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

/// 志願者檔案模型
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

  /// 等級名稱
  String get levelName {
    switch (level) {
      case 1:
        return '初心者';
      case 2:
        return '見習志願者';
      case 3:
        return '正式志願者';
      case 4:
        return '資深志願者';
      case 5:
        return '專家志願者';
      case 6:
        return '大師志願者';
      case 7:
        return '傳奇志願者';
      default:
        return '初心者';
    }
  }
}
