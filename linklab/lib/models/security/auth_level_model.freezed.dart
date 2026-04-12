// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_level_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserAuthStatus _$UserAuthStatusFromJson(Map<String, dynamic> json) {
  return _UserAuthStatus.fromJson(json);
}

/// @nodoc
mixin _$UserAuthStatus {
  String get userId => throw _privateConstructorUsedError;
  bool get phoneVerified => throw _privateConstructorUsedError;
  bool get realNameVerified => throw _privateConstructorUsedError;
  bool get disabledCertVerified => throw _privateConstructorUsedError;
  List<SkillCertification> get skillCerts => throw _privateConstructorUsedError;
  String? get realName => throw _privateConstructorUsedError;
  String? get idCardNumber => throw _privateConstructorUsedError;
  String? get disabledCertImageUrl => throw _privateConstructorUsedError;
  DateTime? get phoneVerifiedAt => throw _privateConstructorUsedError;
  DateTime? get realNameVerifiedAt => throw _privateConstructorUsedError;
  DateTime? get disabledCertVerifiedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserAuthStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserAuthStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAuthStatusCopyWith<UserAuthStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAuthStatusCopyWith<$Res> {
  factory $UserAuthStatusCopyWith(
    UserAuthStatus value,
    $Res Function(UserAuthStatus) then,
  ) = _$UserAuthStatusCopyWithImpl<$Res, UserAuthStatus>;
  @useResult
  $Res call({
    String userId,
    bool phoneVerified,
    bool realNameVerified,
    bool disabledCertVerified,
    List<SkillCertification> skillCerts,
    String? realName,
    String? idCardNumber,
    String? disabledCertImageUrl,
    DateTime? phoneVerifiedAt,
    DateTime? realNameVerifiedAt,
    DateTime? disabledCertVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$UserAuthStatusCopyWithImpl<$Res, $Val extends UserAuthStatus>
    implements $UserAuthStatusCopyWith<$Res> {
  _$UserAuthStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAuthStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? phoneVerified = null,
    Object? realNameVerified = null,
    Object? disabledCertVerified = null,
    Object? skillCerts = null,
    Object? realName = freezed,
    Object? idCardNumber = freezed,
    Object? disabledCertImageUrl = freezed,
    Object? phoneVerifiedAt = freezed,
    Object? realNameVerifiedAt = freezed,
    Object? disabledCertVerifiedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneVerified: null == phoneVerified
                ? _value.phoneVerified
                : phoneVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            realNameVerified: null == realNameVerified
                ? _value.realNameVerified
                : realNameVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            disabledCertVerified: null == disabledCertVerified
                ? _value.disabledCertVerified
                : disabledCertVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            skillCerts: null == skillCerts
                ? _value.skillCerts
                : skillCerts // ignore: cast_nullable_to_non_nullable
                      as List<SkillCertification>,
            realName: freezed == realName
                ? _value.realName
                : realName // ignore: cast_nullable_to_non_nullable
                      as String?,
            idCardNumber: freezed == idCardNumber
                ? _value.idCardNumber
                : idCardNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            disabledCertImageUrl: freezed == disabledCertImageUrl
                ? _value.disabledCertImageUrl
                : disabledCertImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneVerifiedAt: freezed == phoneVerifiedAt
                ? _value.phoneVerifiedAt
                : phoneVerifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            realNameVerifiedAt: freezed == realNameVerifiedAt
                ? _value.realNameVerifiedAt
                : realNameVerifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            disabledCertVerifiedAt: freezed == disabledCertVerifiedAt
                ? _value.disabledCertVerifiedAt
                : disabledCertVerifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserAuthStatusImplCopyWith<$Res>
    implements $UserAuthStatusCopyWith<$Res> {
  factory _$$UserAuthStatusImplCopyWith(
    _$UserAuthStatusImpl value,
    $Res Function(_$UserAuthStatusImpl) then,
  ) = __$$UserAuthStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    bool phoneVerified,
    bool realNameVerified,
    bool disabledCertVerified,
    List<SkillCertification> skillCerts,
    String? realName,
    String? idCardNumber,
    String? disabledCertImageUrl,
    DateTime? phoneVerifiedAt,
    DateTime? realNameVerifiedAt,
    DateTime? disabledCertVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$UserAuthStatusImplCopyWithImpl<$Res>
    extends _$UserAuthStatusCopyWithImpl<$Res, _$UserAuthStatusImpl>
    implements _$$UserAuthStatusImplCopyWith<$Res> {
  __$$UserAuthStatusImplCopyWithImpl(
    _$UserAuthStatusImpl _value,
    $Res Function(_$UserAuthStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserAuthStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? phoneVerified = null,
    Object? realNameVerified = null,
    Object? disabledCertVerified = null,
    Object? skillCerts = null,
    Object? realName = freezed,
    Object? idCardNumber = freezed,
    Object? disabledCertImageUrl = freezed,
    Object? phoneVerifiedAt = freezed,
    Object? realNameVerifiedAt = freezed,
    Object? disabledCertVerifiedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserAuthStatusImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneVerified: null == phoneVerified
            ? _value.phoneVerified
            : phoneVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        realNameVerified: null == realNameVerified
            ? _value.realNameVerified
            : realNameVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        disabledCertVerified: null == disabledCertVerified
            ? _value.disabledCertVerified
            : disabledCertVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        skillCerts: null == skillCerts
            ? _value._skillCerts
            : skillCerts // ignore: cast_nullable_to_non_nullable
                  as List<SkillCertification>,
        realName: freezed == realName
            ? _value.realName
            : realName // ignore: cast_nullable_to_non_nullable
                  as String?,
        idCardNumber: freezed == idCardNumber
            ? _value.idCardNumber
            : idCardNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        disabledCertImageUrl: freezed == disabledCertImageUrl
            ? _value.disabledCertImageUrl
            : disabledCertImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneVerifiedAt: freezed == phoneVerifiedAt
            ? _value.phoneVerifiedAt
            : phoneVerifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        realNameVerifiedAt: freezed == realNameVerifiedAt
            ? _value.realNameVerifiedAt
            : realNameVerifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        disabledCertVerifiedAt: freezed == disabledCertVerifiedAt
            ? _value.disabledCertVerifiedAt
            : disabledCertVerifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAuthStatusImpl extends _UserAuthStatus {
  const _$UserAuthStatusImpl({
    required this.userId,
    this.phoneVerified = false,
    this.realNameVerified = false,
    this.disabledCertVerified = false,
    final List<SkillCertification> skillCerts = const [],
    this.realName,
    this.idCardNumber,
    this.disabledCertImageUrl,
    this.phoneVerifiedAt,
    this.realNameVerifiedAt,
    this.disabledCertVerifiedAt,
    this.createdAt,
    this.updatedAt,
  }) : _skillCerts = skillCerts,
       super._();

  factory _$UserAuthStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAuthStatusImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final bool phoneVerified;
  @override
  @JsonKey()
  final bool realNameVerified;
  @override
  @JsonKey()
  final bool disabledCertVerified;
  final List<SkillCertification> _skillCerts;
  @override
  @JsonKey()
  List<SkillCertification> get skillCerts {
    if (_skillCerts is EqualUnmodifiableListView) return _skillCerts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skillCerts);
  }

  @override
  final String? realName;
  @override
  final String? idCardNumber;
  @override
  final String? disabledCertImageUrl;
  @override
  final DateTime? phoneVerifiedAt;
  @override
  final DateTime? realNameVerifiedAt;
  @override
  final DateTime? disabledCertVerifiedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserAuthStatus(userId: $userId, phoneVerified: $phoneVerified, realNameVerified: $realNameVerified, disabledCertVerified: $disabledCertVerified, skillCerts: $skillCerts, realName: $realName, idCardNumber: $idCardNumber, disabledCertImageUrl: $disabledCertImageUrl, phoneVerifiedAt: $phoneVerifiedAt, realNameVerifiedAt: $realNameVerifiedAt, disabledCertVerifiedAt: $disabledCertVerifiedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAuthStatusImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.phoneVerified, phoneVerified) ||
                other.phoneVerified == phoneVerified) &&
            (identical(other.realNameVerified, realNameVerified) ||
                other.realNameVerified == realNameVerified) &&
            (identical(other.disabledCertVerified, disabledCertVerified) ||
                other.disabledCertVerified == disabledCertVerified) &&
            const DeepCollectionEquality().equals(
              other._skillCerts,
              _skillCerts,
            ) &&
            (identical(other.realName, realName) ||
                other.realName == realName) &&
            (identical(other.idCardNumber, idCardNumber) ||
                other.idCardNumber == idCardNumber) &&
            (identical(other.disabledCertImageUrl, disabledCertImageUrl) ||
                other.disabledCertImageUrl == disabledCertImageUrl) &&
            (identical(other.phoneVerifiedAt, phoneVerifiedAt) ||
                other.phoneVerifiedAt == phoneVerifiedAt) &&
            (identical(other.realNameVerifiedAt, realNameVerifiedAt) ||
                other.realNameVerifiedAt == realNameVerifiedAt) &&
            (identical(other.disabledCertVerifiedAt, disabledCertVerifiedAt) ||
                other.disabledCertVerifiedAt == disabledCertVerifiedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    phoneVerified,
    realNameVerified,
    disabledCertVerified,
    const DeepCollectionEquality().hash(_skillCerts),
    realName,
    idCardNumber,
    disabledCertImageUrl,
    phoneVerifiedAt,
    realNameVerifiedAt,
    disabledCertVerifiedAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of UserAuthStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAuthStatusImplCopyWith<_$UserAuthStatusImpl> get copyWith =>
      __$$UserAuthStatusImplCopyWithImpl<_$UserAuthStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAuthStatusImplToJson(this);
  }
}

abstract class _UserAuthStatus extends UserAuthStatus {
  const factory _UserAuthStatus({
    required final String userId,
    final bool phoneVerified,
    final bool realNameVerified,
    final bool disabledCertVerified,
    final List<SkillCertification> skillCerts,
    final String? realName,
    final String? idCardNumber,
    final String? disabledCertImageUrl,
    final DateTime? phoneVerifiedAt,
    final DateTime? realNameVerifiedAt,
    final DateTime? disabledCertVerifiedAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$UserAuthStatusImpl;
  const _UserAuthStatus._() : super._();

  factory _UserAuthStatus.fromJson(Map<String, dynamic> json) =
      _$UserAuthStatusImpl.fromJson;

  @override
  String get userId;
  @override
  bool get phoneVerified;
  @override
  bool get realNameVerified;
  @override
  bool get disabledCertVerified;
  @override
  List<SkillCertification> get skillCerts;
  @override
  String? get realName;
  @override
  String? get idCardNumber;
  @override
  String? get disabledCertImageUrl;
  @override
  DateTime? get phoneVerifiedAt;
  @override
  DateTime? get realNameVerifiedAt;
  @override
  DateTime? get disabledCertVerifiedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of UserAuthStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAuthStatusImplCopyWith<_$UserAuthStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SkillCertification _$SkillCertificationFromJson(Map<String, dynamic> json) {
  return _SkillCertification.fromJson(json);
}

/// @nodoc
mixin _$SkillCertification {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get skillName => throw _privateConstructorUsedError;
  String? get skillCode => throw _privateConstructorUsedError;
  String? get certificateImageUrl => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  String? get rejectReason => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get verifiedAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this SkillCertification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillCertification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillCertificationCopyWith<SkillCertification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillCertificationCopyWith<$Res> {
  factory $SkillCertificationCopyWith(
    SkillCertification value,
    $Res Function(SkillCertification) then,
  ) = _$SkillCertificationCopyWithImpl<$Res, SkillCertification>;
  @useResult
  $Res call({
    String id,
    String userId,
    String skillName,
    String? skillCode,
    String? certificateImageUrl,
    bool isVerified,
    String? rejectReason,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class _$SkillCertificationCopyWithImpl<$Res, $Val extends SkillCertification>
    implements $SkillCertificationCopyWith<$Res> {
  _$SkillCertificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillCertification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? skillName = null,
    Object? skillCode = freezed,
    Object? certificateImageUrl = freezed,
    Object? isVerified = null,
    Object? rejectReason = freezed,
    Object? submittedAt = freezed,
    Object? verifiedAt = freezed,
    Object? expiresAt = freezed,
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
            skillName: null == skillName
                ? _value.skillName
                : skillName // ignore: cast_nullable_to_non_nullable
                      as String,
            skillCode: freezed == skillCode
                ? _value.skillCode
                : skillCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            certificateImageUrl: freezed == certificateImageUrl
                ? _value.certificateImageUrl
                : certificateImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            rejectReason: freezed == rejectReason
                ? _value.rejectReason
                : rejectReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            verifiedAt: freezed == verifiedAt
                ? _value.verifiedAt
                : verifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillCertificationImplCopyWith<$Res>
    implements $SkillCertificationCopyWith<$Res> {
  factory _$$SkillCertificationImplCopyWith(
    _$SkillCertificationImpl value,
    $Res Function(_$SkillCertificationImpl) then,
  ) = __$$SkillCertificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String skillName,
    String? skillCode,
    String? certificateImageUrl,
    bool isVerified,
    String? rejectReason,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class __$$SkillCertificationImplCopyWithImpl<$Res>
    extends _$SkillCertificationCopyWithImpl<$Res, _$SkillCertificationImpl>
    implements _$$SkillCertificationImplCopyWith<$Res> {
  __$$SkillCertificationImplCopyWithImpl(
    _$SkillCertificationImpl _value,
    $Res Function(_$SkillCertificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillCertification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? skillName = null,
    Object? skillCode = freezed,
    Object? certificateImageUrl = freezed,
    Object? isVerified = null,
    Object? rejectReason = freezed,
    Object? submittedAt = freezed,
    Object? verifiedAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _$SkillCertificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        skillName: null == skillName
            ? _value.skillName
            : skillName // ignore: cast_nullable_to_non_nullable
                  as String,
        skillCode: freezed == skillCode
            ? _value.skillCode
            : skillCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        certificateImageUrl: freezed == certificateImageUrl
            ? _value.certificateImageUrl
            : certificateImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        rejectReason: freezed == rejectReason
            ? _value.rejectReason
            : rejectReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        verifiedAt: freezed == verifiedAt
            ? _value.verifiedAt
            : verifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillCertificationImpl implements _SkillCertification {
  const _$SkillCertificationImpl({
    required this.id,
    required this.userId,
    required this.skillName,
    this.skillCode,
    this.certificateImageUrl,
    this.isVerified = false,
    this.rejectReason,
    this.submittedAt,
    this.verifiedAt,
    this.expiresAt,
  });

  factory _$SkillCertificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillCertificationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String skillName;
  @override
  final String? skillCode;
  @override
  final String? certificateImageUrl;
  @override
  @JsonKey()
  final bool isVerified;
  @override
  final String? rejectReason;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? verifiedAt;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'SkillCertification(id: $id, userId: $userId, skillName: $skillName, skillCode: $skillCode, certificateImageUrl: $certificateImageUrl, isVerified: $isVerified, rejectReason: $rejectReason, submittedAt: $submittedAt, verifiedAt: $verifiedAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillCertificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.skillName, skillName) ||
                other.skillName == skillName) &&
            (identical(other.skillCode, skillCode) ||
                other.skillCode == skillCode) &&
            (identical(other.certificateImageUrl, certificateImageUrl) ||
                other.certificateImageUrl == certificateImageUrl) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.rejectReason, rejectReason) ||
                other.rejectReason == rejectReason) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    skillName,
    skillCode,
    certificateImageUrl,
    isVerified,
    rejectReason,
    submittedAt,
    verifiedAt,
    expiresAt,
  );

  /// Create a copy of SkillCertification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillCertificationImplCopyWith<_$SkillCertificationImpl> get copyWith =>
      __$$SkillCertificationImplCopyWithImpl<_$SkillCertificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillCertificationImplToJson(this);
  }
}

abstract class _SkillCertification implements SkillCertification {
  const factory _SkillCertification({
    required final String id,
    required final String userId,
    required final String skillName,
    final String? skillCode,
    final String? certificateImageUrl,
    final bool isVerified,
    final String? rejectReason,
    final DateTime? submittedAt,
    final DateTime? verifiedAt,
    final DateTime? expiresAt,
  }) = _$SkillCertificationImpl;

  factory _SkillCertification.fromJson(Map<String, dynamic> json) =
      _$SkillCertificationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get skillName;
  @override
  String? get skillCode;
  @override
  String? get certificateImageUrl;
  @override
  bool get isVerified;
  @override
  String? get rejectReason;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get verifiedAt;
  @override
  DateTime? get expiresAt;

  /// Create a copy of SkillCertification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillCertificationImplCopyWith<_$SkillCertificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CertificationApplication _$CertificationApplicationFromJson(
  Map<String, dynamic> json,
) {
  return _CertificationApplication.fromJson(json);
}

/// @nodoc
mixin _$CertificationApplication {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  AuthLevel get authLevel => throw _privateConstructorUsedError;
  CertificationStatus get status => throw _privateConstructorUsedError;
  String? get skillName => throw _privateConstructorUsedError;
  String? get certificateImageUrl => throw _privateConstructorUsedError;
  String? get idCardNumber => throw _privateConstructorUsedError;
  String? get realName => throw _privateConstructorUsedError;
  String? get rejectReason => throw _privateConstructorUsedError;
  String? get reviewerId => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CertificationApplication to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CertificationApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CertificationApplicationCopyWith<CertificationApplication> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CertificationApplicationCopyWith<$Res> {
  factory $CertificationApplicationCopyWith(
    CertificationApplication value,
    $Res Function(CertificationApplication) then,
  ) = _$CertificationApplicationCopyWithImpl<$Res, CertificationApplication>;
  @useResult
  $Res call({
    String id,
    String userId,
    AuthLevel authLevel,
    CertificationStatus status,
    String? skillName,
    String? certificateImageUrl,
    String? idCardNumber,
    String? realName,
    String? rejectReason,
    String? reviewerId,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$CertificationApplicationCopyWithImpl<
  $Res,
  $Val extends CertificationApplication
>
    implements $CertificationApplicationCopyWith<$Res> {
  _$CertificationApplicationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CertificationApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? authLevel = null,
    Object? status = null,
    Object? skillName = freezed,
    Object? certificateImageUrl = freezed,
    Object? idCardNumber = freezed,
    Object? realName = freezed,
    Object? rejectReason = freezed,
    Object? reviewerId = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
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
            authLevel: null == authLevel
                ? _value.authLevel
                : authLevel // ignore: cast_nullable_to_non_nullable
                      as AuthLevel,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as CertificationStatus,
            skillName: freezed == skillName
                ? _value.skillName
                : skillName // ignore: cast_nullable_to_non_nullable
                      as String?,
            certificateImageUrl: freezed == certificateImageUrl
                ? _value.certificateImageUrl
                : certificateImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            idCardNumber: freezed == idCardNumber
                ? _value.idCardNumber
                : idCardNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            realName: freezed == realName
                ? _value.realName
                : realName // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectReason: freezed == rejectReason
                ? _value.rejectReason
                : rejectReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            reviewerId: freezed == reviewerId
                ? _value.reviewerId
                : reviewerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$CertificationApplicationImplCopyWith<$Res>
    implements $CertificationApplicationCopyWith<$Res> {
  factory _$$CertificationApplicationImplCopyWith(
    _$CertificationApplicationImpl value,
    $Res Function(_$CertificationApplicationImpl) then,
  ) = __$$CertificationApplicationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    AuthLevel authLevel,
    CertificationStatus status,
    String? skillName,
    String? certificateImageUrl,
    String? idCardNumber,
    String? realName,
    String? rejectReason,
    String? reviewerId,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$CertificationApplicationImplCopyWithImpl<$Res>
    extends
        _$CertificationApplicationCopyWithImpl<
          $Res,
          _$CertificationApplicationImpl
        >
    implements _$$CertificationApplicationImplCopyWith<$Res> {
  __$$CertificationApplicationImplCopyWithImpl(
    _$CertificationApplicationImpl _value,
    $Res Function(_$CertificationApplicationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CertificationApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? authLevel = null,
    Object? status = null,
    Object? skillName = freezed,
    Object? certificateImageUrl = freezed,
    Object? idCardNumber = freezed,
    Object? realName = freezed,
    Object? rejectReason = freezed,
    Object? reviewerId = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CertificationApplicationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        authLevel: null == authLevel
            ? _value.authLevel
            : authLevel // ignore: cast_nullable_to_non_nullable
                  as AuthLevel,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CertificationStatus,
        skillName: freezed == skillName
            ? _value.skillName
            : skillName // ignore: cast_nullable_to_non_nullable
                  as String?,
        certificateImageUrl: freezed == certificateImageUrl
            ? _value.certificateImageUrl
            : certificateImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        idCardNumber: freezed == idCardNumber
            ? _value.idCardNumber
            : idCardNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        realName: freezed == realName
            ? _value.realName
            : realName // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectReason: freezed == rejectReason
            ? _value.rejectReason
            : rejectReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        reviewerId: freezed == reviewerId
            ? _value.reviewerId
            : reviewerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
class _$CertificationApplicationImpl implements _CertificationApplication {
  const _$CertificationApplicationImpl({
    required this.id,
    required this.userId,
    required this.authLevel,
    required this.status,
    this.skillName,
    this.certificateImageUrl,
    this.idCardNumber,
    this.realName,
    this.rejectReason,
    this.reviewerId,
    this.submittedAt,
    this.reviewedAt,
    this.createdAt,
  });

  factory _$CertificationApplicationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CertificationApplicationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final AuthLevel authLevel;
  @override
  final CertificationStatus status;
  @override
  final String? skillName;
  @override
  final String? certificateImageUrl;
  @override
  final String? idCardNumber;
  @override
  final String? realName;
  @override
  final String? rejectReason;
  @override
  final String? reviewerId;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? reviewedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CertificationApplication(id: $id, userId: $userId, authLevel: $authLevel, status: $status, skillName: $skillName, certificateImageUrl: $certificateImageUrl, idCardNumber: $idCardNumber, realName: $realName, rejectReason: $rejectReason, reviewerId: $reviewerId, submittedAt: $submittedAt, reviewedAt: $reviewedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CertificationApplicationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.authLevel, authLevel) ||
                other.authLevel == authLevel) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.skillName, skillName) ||
                other.skillName == skillName) &&
            (identical(other.certificateImageUrl, certificateImageUrl) ||
                other.certificateImageUrl == certificateImageUrl) &&
            (identical(other.idCardNumber, idCardNumber) ||
                other.idCardNumber == idCardNumber) &&
            (identical(other.realName, realName) ||
                other.realName == realName) &&
            (identical(other.rejectReason, rejectReason) ||
                other.rejectReason == rejectReason) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    authLevel,
    status,
    skillName,
    certificateImageUrl,
    idCardNumber,
    realName,
    rejectReason,
    reviewerId,
    submittedAt,
    reviewedAt,
    createdAt,
  );

  /// Create a copy of CertificationApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CertificationApplicationImplCopyWith<_$CertificationApplicationImpl>
  get copyWith =>
      __$$CertificationApplicationImplCopyWithImpl<
        _$CertificationApplicationImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CertificationApplicationImplToJson(this);
  }
}

abstract class _CertificationApplication implements CertificationApplication {
  const factory _CertificationApplication({
    required final String id,
    required final String userId,
    required final AuthLevel authLevel,
    required final CertificationStatus status,
    final String? skillName,
    final String? certificateImageUrl,
    final String? idCardNumber,
    final String? realName,
    final String? rejectReason,
    final String? reviewerId,
    final DateTime? submittedAt,
    final DateTime? reviewedAt,
    final DateTime? createdAt,
  }) = _$CertificationApplicationImpl;

  factory _CertificationApplication.fromJson(Map<String, dynamic> json) =
      _$CertificationApplicationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  AuthLevel get authLevel;
  @override
  CertificationStatus get status;
  @override
  String? get skillName;
  @override
  String? get certificateImageUrl;
  @override
  String? get idCardNumber;
  @override
  String? get realName;
  @override
  String? get rejectReason;
  @override
  String? get reviewerId;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get reviewedAt;
  @override
  DateTime? get createdAt;

  /// Create a copy of CertificationApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CertificationApplicationImplCopyWith<_$CertificationApplicationImpl>
  get copyWith => throw _privateConstructorUsedError;
}
