import 'package:freezed_annotation/freezed_annotation.dart';

part 'emergency_contact_model.freezed.dart';
part 'emergency_contact_model.g.dart';

/// 紧急联系人模型
@freezed
class EmergencyContactModel with _$EmergencyContactModel {
  const factory EmergencyContactModel({
    required String id,
    required String userId,
    required String name,
    required String phone,
    String? relationship,
    @Default(0) int priority, // 优先级，0为最高
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _EmergencyContactModel;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactModelFromJson(json);

  const EmergencyContactModel._();

  /// 关系标签
  String get relationshipLabel {
    switch (relationship) {
      case 'parent':
        return '父母';
      case 'spouse':
        return '配偶';
      case 'child':
        return '子女';
      case 'sibling':
        return '兄弟姐妹';
      case 'friend':
        return '朋友';
      case 'caregiver':
        return '看护人';
      case 'doctor':
        return '医生';
      default:
        return '其他';
    }
  }
}
