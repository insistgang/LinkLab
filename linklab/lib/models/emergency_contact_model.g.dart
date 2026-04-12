// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmergencyContactModelImpl _$$EmergencyContactModelImplFromJson(
  Map<String, dynamic> json,
) => _$EmergencyContactModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  relationship: json['relationship'] as String?,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$EmergencyContactModelImplToJson(
  _$EmergencyContactModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'phone': instance.phone,
  'relationship': instance.relationship,
  'priority': instance.priority,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt?.toIso8601String(),
};
