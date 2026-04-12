// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SkillModel _$SkillModelFromJson(Map<String, dynamic> json) {
  return _SkillModel.fromJson(json);
}

/// @nodoc
mixin _$SkillModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  bool get requiresVerification => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  String? get certificateUrl => throw _privateConstructorUsedError;
  DateTime? get verifiedAt => throw _privateConstructorUsedError;

  /// Serializes this SkillModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillModelCopyWith<SkillModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillModelCopyWith<$Res> {
  factory $SkillModelCopyWith(
    SkillModel value,
    $Res Function(SkillModel) then,
  ) = _$SkillModelCopyWithImpl<$Res, SkillModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? category,
    String? description,
    String? iconUrl,
    bool requiresVerification,
    bool isVerified,
    String? certificateUrl,
    DateTime? verifiedAt,
  });
}

/// @nodoc
class _$SkillModelCopyWithImpl<$Res, $Val extends SkillModel>
    implements $SkillModelCopyWith<$Res> {
  _$SkillModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = freezed,
    Object? description = freezed,
    Object? iconUrl = freezed,
    Object? requiresVerification = null,
    Object? isVerified = null,
    Object? certificateUrl = freezed,
    Object? verifiedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            iconUrl: freezed == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            requiresVerification: null == requiresVerification
                ? _value.requiresVerification
                : requiresVerification // ignore: cast_nullable_to_non_nullable
                      as bool,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            certificateUrl: freezed == certificateUrl
                ? _value.certificateUrl
                : certificateUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            verifiedAt: freezed == verifiedAt
                ? _value.verifiedAt
                : verifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillModelImplCopyWith<$Res>
    implements $SkillModelCopyWith<$Res> {
  factory _$$SkillModelImplCopyWith(
    _$SkillModelImpl value,
    $Res Function(_$SkillModelImpl) then,
  ) = __$$SkillModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? category,
    String? description,
    String? iconUrl,
    bool requiresVerification,
    bool isVerified,
    String? certificateUrl,
    DateTime? verifiedAt,
  });
}

/// @nodoc
class __$$SkillModelImplCopyWithImpl<$Res>
    extends _$SkillModelCopyWithImpl<$Res, _$SkillModelImpl>
    implements _$$SkillModelImplCopyWith<$Res> {
  __$$SkillModelImplCopyWithImpl(
    _$SkillModelImpl _value,
    $Res Function(_$SkillModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = freezed,
    Object? description = freezed,
    Object? iconUrl = freezed,
    Object? requiresVerification = null,
    Object? isVerified = null,
    Object? certificateUrl = freezed,
    Object? verifiedAt = freezed,
  }) {
    return _then(
      _$SkillModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        iconUrl: freezed == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        requiresVerification: null == requiresVerification
            ? _value.requiresVerification
            : requiresVerification // ignore: cast_nullable_to_non_nullable
                  as bool,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        certificateUrl: freezed == certificateUrl
            ? _value.certificateUrl
            : certificateUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        verifiedAt: freezed == verifiedAt
            ? _value.verifiedAt
            : verifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillModelImpl extends _SkillModel {
  const _$SkillModelImpl({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.iconUrl,
    this.requiresVerification = false,
    this.isVerified = false,
    this.certificateUrl,
    this.verifiedAt,
  }) : super._();

  factory _$SkillModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? category;
  @override
  final String? description;
  @override
  final String? iconUrl;
  @override
  @JsonKey()
  final bool requiresVerification;
  @override
  @JsonKey()
  final bool isVerified;
  @override
  final String? certificateUrl;
  @override
  final DateTime? verifiedAt;

  @override
  String toString() {
    return 'SkillModel(id: $id, name: $name, category: $category, description: $description, iconUrl: $iconUrl, requiresVerification: $requiresVerification, isVerified: $isVerified, certificateUrl: $certificateUrl, verifiedAt: $verifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.requiresVerification, requiresVerification) ||
                other.requiresVerification == requiresVerification) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.certificateUrl, certificateUrl) ||
                other.certificateUrl == certificateUrl) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    category,
    description,
    iconUrl,
    requiresVerification,
    isVerified,
    certificateUrl,
    verifiedAt,
  );

  /// Create a copy of SkillModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillModelImplCopyWith<_$SkillModelImpl> get copyWith =>
      __$$SkillModelImplCopyWithImpl<_$SkillModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillModelImplToJson(this);
  }
}

abstract class _SkillModel extends SkillModel {
  const factory _SkillModel({
    required final String id,
    required final String name,
    final String? category,
    final String? description,
    final String? iconUrl,
    final bool requiresVerification,
    final bool isVerified,
    final String? certificateUrl,
    final DateTime? verifiedAt,
  }) = _$SkillModelImpl;
  const _SkillModel._() : super._();

  factory _SkillModel.fromJson(Map<String, dynamic> json) =
      _$SkillModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get category;
  @override
  String? get description;
  @override
  String? get iconUrl;
  @override
  bool get requiresVerification;
  @override
  bool get isVerified;
  @override
  String? get certificateUrl;
  @override
  DateTime? get verifiedAt;

  /// Create a copy of SkillModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillModelImplCopyWith<_$SkillModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SkillVerificationRequest _$SkillVerificationRequestFromJson(
  Map<String, dynamic> json,
) {
  return _SkillVerificationRequest.fromJson(json);
}

/// @nodoc
mixin _$SkillVerificationRequest {
  String get id => throw _privateConstructorUsedError;
  String get volunteerId => throw _privateConstructorUsedError;
  String get skillId => throw _privateConstructorUsedError;
  String? get skillName => throw _privateConstructorUsedError;
  String? get certificateUrl => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get reviewerNote => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;

  /// Serializes this SkillVerificationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillVerificationRequestCopyWith<SkillVerificationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillVerificationRequestCopyWith<$Res> {
  factory $SkillVerificationRequestCopyWith(
    SkillVerificationRequest value,
    $Res Function(SkillVerificationRequest) then,
  ) = _$SkillVerificationRequestCopyWithImpl<$Res, SkillVerificationRequest>;
  @useResult
  $Res call({
    String id,
    String volunteerId,
    String skillId,
    String? skillName,
    String? certificateUrl,
    String? description,
    String status,
    String? reviewerNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class _$SkillVerificationRequestCopyWithImpl<
  $Res,
  $Val extends SkillVerificationRequest
>
    implements $SkillVerificationRequestCopyWith<$Res> {
  _$SkillVerificationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? volunteerId = null,
    Object? skillId = null,
    Object? skillName = freezed,
    Object? certificateUrl = freezed,
    Object? description = freezed,
    Object? status = null,
    Object? reviewerNote = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            volunteerId: null == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String,
            skillId: null == skillId
                ? _value.skillId
                : skillId // ignore: cast_nullable_to_non_nullable
                      as String,
            skillName: freezed == skillName
                ? _value.skillName
                : skillName // ignore: cast_nullable_to_non_nullable
                      as String?,
            certificateUrl: freezed == certificateUrl
                ? _value.certificateUrl
                : certificateUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            reviewerNote: freezed == reviewerNote
                ? _value.reviewerNote
                : reviewerNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillVerificationRequestImplCopyWith<$Res>
    implements $SkillVerificationRequestCopyWith<$Res> {
  factory _$$SkillVerificationRequestImplCopyWith(
    _$SkillVerificationRequestImpl value,
    $Res Function(_$SkillVerificationRequestImpl) then,
  ) = __$$SkillVerificationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String volunteerId,
    String skillId,
    String? skillName,
    String? certificateUrl,
    String? description,
    String status,
    String? reviewerNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  });
}

/// @nodoc
class __$$SkillVerificationRequestImplCopyWithImpl<$Res>
    extends
        _$SkillVerificationRequestCopyWithImpl<
          $Res,
          _$SkillVerificationRequestImpl
        >
    implements _$$SkillVerificationRequestImplCopyWith<$Res> {
  __$$SkillVerificationRequestImplCopyWithImpl(
    _$SkillVerificationRequestImpl _value,
    $Res Function(_$SkillVerificationRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? volunteerId = null,
    Object? skillId = null,
    Object? skillName = freezed,
    Object? certificateUrl = freezed,
    Object? description = freezed,
    Object? status = null,
    Object? reviewerNote = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
  }) {
    return _then(
      _$SkillVerificationRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteerId: null == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String,
        skillId: null == skillId
            ? _value.skillId
            : skillId // ignore: cast_nullable_to_non_nullable
                  as String,
        skillName: freezed == skillName
            ? _value.skillName
            : skillName // ignore: cast_nullable_to_non_nullable
                  as String?,
        certificateUrl: freezed == certificateUrl
            ? _value.certificateUrl
            : certificateUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        reviewerNote: freezed == reviewerNote
            ? _value.reviewerNote
            : reviewerNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillVerificationRequestImpl implements _SkillVerificationRequest {
  const _$SkillVerificationRequestImpl({
    required this.id,
    required this.volunteerId,
    required this.skillId,
    this.skillName,
    this.certificateUrl,
    this.description,
    this.status = 'pending',
    this.reviewerNote,
    this.submittedAt,
    this.reviewedAt,
  });

  factory _$SkillVerificationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillVerificationRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String volunteerId;
  @override
  final String skillId;
  @override
  final String? skillName;
  @override
  final String? certificateUrl;
  @override
  final String? description;
  @override
  @JsonKey()
  final String status;
  @override
  final String? reviewerNote;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? reviewedAt;

  @override
  String toString() {
    return 'SkillVerificationRequest(id: $id, volunteerId: $volunteerId, skillId: $skillId, skillName: $skillName, certificateUrl: $certificateUrl, description: $description, status: $status, reviewerNote: $reviewerNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillVerificationRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.skillId, skillId) || other.skillId == skillId) &&
            (identical(other.skillName, skillName) ||
                other.skillName == skillName) &&
            (identical(other.certificateUrl, certificateUrl) ||
                other.certificateUrl == certificateUrl) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.reviewerNote, reviewerNote) ||
                other.reviewerNote == reviewerNote) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    volunteerId,
    skillId,
    skillName,
    certificateUrl,
    description,
    status,
    reviewerNote,
    submittedAt,
    reviewedAt,
  );

  /// Create a copy of SkillVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillVerificationRequestImplCopyWith<_$SkillVerificationRequestImpl>
  get copyWith =>
      __$$SkillVerificationRequestImplCopyWithImpl<
        _$SkillVerificationRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillVerificationRequestImplToJson(this);
  }
}

abstract class _SkillVerificationRequest implements SkillVerificationRequest {
  const factory _SkillVerificationRequest({
    required final String id,
    required final String volunteerId,
    required final String skillId,
    final String? skillName,
    final String? certificateUrl,
    final String? description,
    final String status,
    final String? reviewerNote,
    final DateTime? submittedAt,
    final DateTime? reviewedAt,
  }) = _$SkillVerificationRequestImpl;

  factory _SkillVerificationRequest.fromJson(Map<String, dynamic> json) =
      _$SkillVerificationRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get volunteerId;
  @override
  String get skillId;
  @override
  String? get skillName;
  @override
  String? get certificateUrl;
  @override
  String? get description;
  @override
  String get status;
  @override
  String? get reviewerNote;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get reviewedAt;

  /// Create a copy of SkillVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillVerificationRequestImplCopyWith<_$SkillVerificationRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
