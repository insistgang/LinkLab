// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emergency_contact_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EmergencyContactModel _$EmergencyContactModelFromJson(
  Map<String, dynamic> json,
) {
  return _EmergencyContactModel.fromJson(json);
}

/// @nodoc
mixin _$EmergencyContactModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get relationship => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError; // 优先级，0为最高
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this EmergencyContactModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmergencyContactModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmergencyContactModelCopyWith<EmergencyContactModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmergencyContactModelCopyWith<$Res> {
  factory $EmergencyContactModelCopyWith(
    EmergencyContactModel value,
    $Res Function(EmergencyContactModel) then,
  ) = _$EmergencyContactModelCopyWithImpl<$Res, EmergencyContactModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String phone,
    String? relationship,
    int priority,
    bool isActive,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$EmergencyContactModelCopyWithImpl<
  $Res,
  $Val extends EmergencyContactModel
>
    implements $EmergencyContactModelCopyWith<$Res> {
  _$EmergencyContactModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmergencyContactModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phone = null,
    Object? relationship = freezed,
    Object? priority = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            relationship: freezed == relationship
                ? _value.relationship
                : relationship // ignore: cast_nullable_to_non_nullable
                      as String?,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmergencyContactModelImplCopyWith<$Res>
    implements $EmergencyContactModelCopyWith<$Res> {
  factory _$$EmergencyContactModelImplCopyWith(
    _$EmergencyContactModelImpl value,
    $Res Function(_$EmergencyContactModelImpl) then,
  ) = __$$EmergencyContactModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String phone,
    String? relationship,
    int priority,
    bool isActive,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$EmergencyContactModelImplCopyWithImpl<$Res>
    extends
        _$EmergencyContactModelCopyWithImpl<$Res, _$EmergencyContactModelImpl>
    implements _$$EmergencyContactModelImplCopyWith<$Res> {
  __$$EmergencyContactModelImplCopyWithImpl(
    _$EmergencyContactModelImpl _value,
    $Res Function(_$EmergencyContactModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmergencyContactModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phone = null,
    Object? relationship = freezed,
    Object? priority = null,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$EmergencyContactModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        relationship: freezed == relationship
            ? _value.relationship
            : relationship // ignore: cast_nullable_to_non_nullable
                  as String?,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EmergencyContactModelImpl extends _EmergencyContactModel {
  const _$EmergencyContactModelImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relationship,
    this.priority = 0,
    this.isActive = true,
    this.createdAt,
  }) : super._();

  factory _$EmergencyContactModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmergencyContactModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String? relationship;
  @override
  @JsonKey()
  final int priority;
  // 优先级，0为最高
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'EmergencyContactModel(id: $id, userId: $userId, name: $name, phone: $phone, relationship: $relationship, priority: $priority, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmergencyContactModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.relationship, relationship) ||
                other.relationship == relationship) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    phone,
    relationship,
    priority,
    isActive,
    createdAt,
  );

  /// Create a copy of EmergencyContactModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmergencyContactModelImplCopyWith<_$EmergencyContactModelImpl>
  get copyWith =>
      __$$EmergencyContactModelImplCopyWithImpl<_$EmergencyContactModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EmergencyContactModelImplToJson(this);
  }
}

abstract class _EmergencyContactModel extends EmergencyContactModel {
  const factory _EmergencyContactModel({
    required final String id,
    required final String userId,
    required final String name,
    required final String phone,
    final String? relationship,
    final int priority,
    final bool isActive,
    final DateTime? createdAt,
  }) = _$EmergencyContactModelImpl;
  const _EmergencyContactModel._() : super._();

  factory _EmergencyContactModel.fromJson(Map<String, dynamic> json) =
      _$EmergencyContactModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get phone;
  @override
  String? get relationship;
  @override
  int get priority; // 优先级，0为最高
  @override
  bool get isActive;
  @override
  DateTime? get createdAt;

  /// Create a copy of EmergencyContactModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmergencyContactModelImplCopyWith<_$EmergencyContactModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
