// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HelpRequestModel _$HelpRequestModelFromJson(Map<String, dynamic> json) {
  return _HelpRequestModel.fromJson(json);
}

/// @nodoc
mixin _$HelpRequestModel {
  String get id => throw _privateConstructorUsedError;
  String get seekerId => throw _privateConstructorUsedError;
  String? get type =>
      throw _privateConstructorUsedError; // 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
  String? get intent => throw _privateConstructorUsedError;
  String? get urgency =>
      throw _privateConstructorUsedError; // 'normal', 'important', 'urgent', 'emergency'
  String? get status =>
      throw _privateConstructorUsedError; // 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  Map<String, dynamic>? get aiResponse => throw _privateConstructorUsedError;
  String? get volunteerId => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;
  int? get seekerRating => throw _privateConstructorUsedError;
  int? get volunteerRating => throw _privateConstructorUsedError;
  String? get cancelReason => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get matchedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this HelpRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HelpRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HelpRequestModelCopyWith<HelpRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HelpRequestModelCopyWith<$Res> {
  factory $HelpRequestModelCopyWith(
    HelpRequestModel value,
    $Res Function(HelpRequestModel) then,
  ) = _$HelpRequestModelCopyWithImpl<$Res, HelpRequestModel>;
  @useResult
  $Res call({
    String id,
    String seekerId,
    String? type,
    String? intent,
    String? urgency,
    String? status,
    Map<String, dynamic>? aiResponse,
    String? volunteerId,
    double? latitude,
    double? longitude,
    int? durationSeconds,
    int? seekerRating,
    int? volunteerRating,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? matchedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$HelpRequestModelCopyWithImpl<$Res, $Val extends HelpRequestModel>
    implements $HelpRequestModelCopyWith<$Res> {
  _$HelpRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HelpRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seekerId = null,
    Object? type = freezed,
    Object? intent = freezed,
    Object? urgency = freezed,
    Object? status = freezed,
    Object? aiResponse = freezed,
    Object? volunteerId = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? durationSeconds = freezed,
    Object? seekerRating = freezed,
    Object? volunteerRating = freezed,
    Object? cancelReason = freezed,
    Object? createdAt = freezed,
    Object? matchedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            seekerId: null == seekerId
                ? _value.seekerId
                : seekerId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            intent: freezed == intent
                ? _value.intent
                : intent // ignore: cast_nullable_to_non_nullable
                      as String?,
            urgency: freezed == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            aiResponse: freezed == aiResponse
                ? _value.aiResponse
                : aiResponse // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            volunteerId: freezed == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            seekerRating: freezed == seekerRating
                ? _value.seekerRating
                : seekerRating // ignore: cast_nullable_to_non_nullable
                      as int?,
            volunteerRating: freezed == volunteerRating
                ? _value.volunteerRating
                : volunteerRating // ignore: cast_nullable_to_non_nullable
                      as int?,
            cancelReason: freezed == cancelReason
                ? _value.cancelReason
                : cancelReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            matchedAt: freezed == matchedAt
                ? _value.matchedAt
                : matchedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HelpRequestModelImplCopyWith<$Res>
    implements $HelpRequestModelCopyWith<$Res> {
  factory _$$HelpRequestModelImplCopyWith(
    _$HelpRequestModelImpl value,
    $Res Function(_$HelpRequestModelImpl) then,
  ) = __$$HelpRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String seekerId,
    String? type,
    String? intent,
    String? urgency,
    String? status,
    Map<String, dynamic>? aiResponse,
    String? volunteerId,
    double? latitude,
    double? longitude,
    int? durationSeconds,
    int? seekerRating,
    int? volunteerRating,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? matchedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$$HelpRequestModelImplCopyWithImpl<$Res>
    extends _$HelpRequestModelCopyWithImpl<$Res, _$HelpRequestModelImpl>
    implements _$$HelpRequestModelImplCopyWith<$Res> {
  __$$HelpRequestModelImplCopyWithImpl(
    _$HelpRequestModelImpl _value,
    $Res Function(_$HelpRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seekerId = null,
    Object? type = freezed,
    Object? intent = freezed,
    Object? urgency = freezed,
    Object? status = freezed,
    Object? aiResponse = freezed,
    Object? volunteerId = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? durationSeconds = freezed,
    Object? seekerRating = freezed,
    Object? volunteerRating = freezed,
    Object? cancelReason = freezed,
    Object? createdAt = freezed,
    Object? matchedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$HelpRequestModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        seekerId: null == seekerId
            ? _value.seekerId
            : seekerId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        intent: freezed == intent
            ? _value.intent
            : intent // ignore: cast_nullable_to_non_nullable
                  as String?,
        urgency: freezed == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        aiResponse: freezed == aiResponse
            ? _value._aiResponse
            : aiResponse // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        volunteerId: freezed == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        seekerRating: freezed == seekerRating
            ? _value.seekerRating
            : seekerRating // ignore: cast_nullable_to_non_nullable
                  as int?,
        volunteerRating: freezed == volunteerRating
            ? _value.volunteerRating
            : volunteerRating // ignore: cast_nullable_to_non_nullable
                  as int?,
        cancelReason: freezed == cancelReason
            ? _value.cancelReason
            : cancelReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        matchedAt: freezed == matchedAt
            ? _value.matchedAt
            : matchedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HelpRequestModelImpl extends _HelpRequestModel {
  const _$HelpRequestModelImpl({
    required this.id,
    required this.seekerId,
    this.type,
    this.intent,
    this.urgency,
    this.status,
    final Map<String, dynamic>? aiResponse,
    this.volunteerId,
    this.latitude,
    this.longitude,
    this.durationSeconds,
    this.seekerRating,
    this.volunteerRating,
    this.cancelReason,
    this.createdAt,
    this.matchedAt,
    this.completedAt,
  }) : _aiResponse = aiResponse,
       super._();

  factory _$HelpRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$HelpRequestModelImplFromJson(json);

  @override
  final String id;
  @override
  final String seekerId;
  @override
  final String? type;
  // 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
  @override
  final String? intent;
  @override
  final String? urgency;
  // 'normal', 'important', 'urgent', 'emergency'
  @override
  final String? status;
  // 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  final Map<String, dynamic>? _aiResponse;
  // 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  @override
  Map<String, dynamic>? get aiResponse {
    final value = _aiResponse;
    if (value == null) return null;
    if (_aiResponse is EqualUnmodifiableMapView) return _aiResponse;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? volunteerId;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final int? durationSeconds;
  @override
  final int? seekerRating;
  @override
  final int? volunteerRating;
  @override
  final String? cancelReason;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? matchedAt;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'HelpRequestModel(id: $id, seekerId: $seekerId, type: $type, intent: $intent, urgency: $urgency, status: $status, aiResponse: $aiResponse, volunteerId: $volunteerId, latitude: $latitude, longitude: $longitude, durationSeconds: $durationSeconds, seekerRating: $seekerRating, volunteerRating: $volunteerRating, cancelReason: $cancelReason, createdAt: $createdAt, matchedAt: $matchedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HelpRequestModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seekerId, seekerId) ||
                other.seekerId == seekerId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.intent, intent) || other.intent == intent) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._aiResponse,
              _aiResponse,
            ) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.seekerRating, seekerRating) ||
                other.seekerRating == seekerRating) &&
            (identical(other.volunteerRating, volunteerRating) ||
                other.volunteerRating == volunteerRating) &&
            (identical(other.cancelReason, cancelReason) ||
                other.cancelReason == cancelReason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.matchedAt, matchedAt) ||
                other.matchedAt == matchedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    seekerId,
    type,
    intent,
    urgency,
    status,
    const DeepCollectionEquality().hash(_aiResponse),
    volunteerId,
    latitude,
    longitude,
    durationSeconds,
    seekerRating,
    volunteerRating,
    cancelReason,
    createdAt,
    matchedAt,
    completedAt,
  );

  /// Create a copy of HelpRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HelpRequestModelImplCopyWith<_$HelpRequestModelImpl> get copyWith =>
      __$$HelpRequestModelImplCopyWithImpl<_$HelpRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HelpRequestModelImplToJson(this);
  }
}

abstract class _HelpRequestModel extends HelpRequestModel {
  const factory _HelpRequestModel({
    required final String id,
    required final String seekerId,
    final String? type,
    final String? intent,
    final String? urgency,
    final String? status,
    final Map<String, dynamic>? aiResponse,
    final String? volunteerId,
    final double? latitude,
    final double? longitude,
    final int? durationSeconds,
    final int? seekerRating,
    final int? volunteerRating,
    final String? cancelReason,
    final DateTime? createdAt,
    final DateTime? matchedAt,
    final DateTime? completedAt,
  }) = _$HelpRequestModelImpl;
  const _HelpRequestModel._() : super._();

  factory _HelpRequestModel.fromJson(Map<String, dynamic> json) =
      _$HelpRequestModelImpl.fromJson;

  @override
  String get id;
  @override
  String get seekerId;
  @override
  String? get type; // 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
  @override
  String? get intent;
  @override
  String? get urgency; // 'normal', 'important', 'urgent', 'emergency'
  @override
  String? get status; // 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  @override
  Map<String, dynamic>? get aiResponse;
  @override
  String? get volunteerId;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int? get durationSeconds;
  @override
  int? get seekerRating;
  @override
  int? get volunteerRating;
  @override
  String? get cancelReason;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get matchedAt;
  @override
  DateTime? get completedAt;

  /// Create a copy of HelpRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HelpRequestModelImplCopyWith<_$HelpRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AsyncTaskModel _$AsyncTaskModelFromJson(Map<String, dynamic> json) {
  return _AsyncTaskModel.fromJson(json);
}

/// @nodoc
mixin _$AsyncTaskModel {
  String get id => throw _privateConstructorUsedError;
  String get helpRequestId => throw _privateConstructorUsedError;
  String get seekerId => throw _privateConstructorUsedError;
  String? get volunteerId => throw _privateConstructorUsedError;
  String get taskType => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get status =>
      throw _privateConstructorUsedError; // 'pending', 'assigned', 'processing', 'completed', 'cancelled'
  String? get result => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get assignedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this AsyncTaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AsyncTaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AsyncTaskModelCopyWith<AsyncTaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AsyncTaskModelCopyWith<$Res> {
  factory $AsyncTaskModelCopyWith(
    AsyncTaskModel value,
    $Res Function(AsyncTaskModel) then,
  ) = _$AsyncTaskModelCopyWithImpl<$Res, AsyncTaskModel>;
  @useResult
  $Res call({
    String id,
    String helpRequestId,
    String seekerId,
    String? volunteerId,
    String taskType,
    String description,
    String? imageUrl,
    String? status,
    String? result,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$AsyncTaskModelCopyWithImpl<$Res, $Val extends AsyncTaskModel>
    implements $AsyncTaskModelCopyWith<$Res> {
  _$AsyncTaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AsyncTaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? helpRequestId = null,
    Object? seekerId = null,
    Object? volunteerId = freezed,
    Object? taskType = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? status = freezed,
    Object? result = freezed,
    Object? createdAt = freezed,
    Object? assignedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            helpRequestId: null == helpRequestId
                ? _value.helpRequestId
                : helpRequestId // ignore: cast_nullable_to_non_nullable
                      as String,
            seekerId: null == seekerId
                ? _value.seekerId
                : seekerId // ignore: cast_nullable_to_non_nullable
                      as String,
            volunteerId: freezed == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            taskType: null == taskType
                ? _value.taskType
                : taskType // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            result: freezed == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            assignedAt: freezed == assignedAt
                ? _value.assignedAt
                : assignedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AsyncTaskModelImplCopyWith<$Res>
    implements $AsyncTaskModelCopyWith<$Res> {
  factory _$$AsyncTaskModelImplCopyWith(
    _$AsyncTaskModelImpl value,
    $Res Function(_$AsyncTaskModelImpl) then,
  ) = __$$AsyncTaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String helpRequestId,
    String seekerId,
    String? volunteerId,
    String taskType,
    String description,
    String? imageUrl,
    String? status,
    String? result,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$$AsyncTaskModelImplCopyWithImpl<$Res>
    extends _$AsyncTaskModelCopyWithImpl<$Res, _$AsyncTaskModelImpl>
    implements _$$AsyncTaskModelImplCopyWith<$Res> {
  __$$AsyncTaskModelImplCopyWithImpl(
    _$AsyncTaskModelImpl _value,
    $Res Function(_$AsyncTaskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AsyncTaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? helpRequestId = null,
    Object? seekerId = null,
    Object? volunteerId = freezed,
    Object? taskType = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? status = freezed,
    Object? result = freezed,
    Object? createdAt = freezed,
    Object? assignedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$AsyncTaskModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        helpRequestId: null == helpRequestId
            ? _value.helpRequestId
            : helpRequestId // ignore: cast_nullable_to_non_nullable
                  as String,
        seekerId: null == seekerId
            ? _value.seekerId
            : seekerId // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteerId: freezed == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        taskType: null == taskType
            ? _value.taskType
            : taskType // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        result: freezed == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        assignedAt: freezed == assignedAt
            ? _value.assignedAt
            : assignedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AsyncTaskModelImpl extends _AsyncTaskModel {
  const _$AsyncTaskModelImpl({
    required this.id,
    required this.helpRequestId,
    required this.seekerId,
    this.volunteerId,
    required this.taskType,
    required this.description,
    this.imageUrl,
    this.status,
    this.result,
    this.createdAt,
    this.assignedAt,
    this.completedAt,
  }) : super._();

  factory _$AsyncTaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AsyncTaskModelImplFromJson(json);

  @override
  final String id;
  @override
  final String helpRequestId;
  @override
  final String seekerId;
  @override
  final String? volunteerId;
  @override
  final String taskType;
  @override
  final String description;
  @override
  final String? imageUrl;
  @override
  final String? status;
  // 'pending', 'assigned', 'processing', 'completed', 'cancelled'
  @override
  final String? result;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? assignedAt;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'AsyncTaskModel(id: $id, helpRequestId: $helpRequestId, seekerId: $seekerId, volunteerId: $volunteerId, taskType: $taskType, description: $description, imageUrl: $imageUrl, status: $status, result: $result, createdAt: $createdAt, assignedAt: $assignedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AsyncTaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.helpRequestId, helpRequestId) ||
                other.helpRequestId == helpRequestId) &&
            (identical(other.seekerId, seekerId) ||
                other.seekerId == seekerId) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.taskType, taskType) ||
                other.taskType == taskType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    helpRequestId,
    seekerId,
    volunteerId,
    taskType,
    description,
    imageUrl,
    status,
    result,
    createdAt,
    assignedAt,
    completedAt,
  );

  /// Create a copy of AsyncTaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AsyncTaskModelImplCopyWith<_$AsyncTaskModelImpl> get copyWith =>
      __$$AsyncTaskModelImplCopyWithImpl<_$AsyncTaskModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AsyncTaskModelImplToJson(this);
  }
}

abstract class _AsyncTaskModel extends AsyncTaskModel {
  const factory _AsyncTaskModel({
    required final String id,
    required final String helpRequestId,
    required final String seekerId,
    final String? volunteerId,
    required final String taskType,
    required final String description,
    final String? imageUrl,
    final String? status,
    final String? result,
    final DateTime? createdAt,
    final DateTime? assignedAt,
    final DateTime? completedAt,
  }) = _$AsyncTaskModelImpl;
  const _AsyncTaskModel._() : super._();

  factory _AsyncTaskModel.fromJson(Map<String, dynamic> json) =
      _$AsyncTaskModelImpl.fromJson;

  @override
  String get id;
  @override
  String get helpRequestId;
  @override
  String get seekerId;
  @override
  String? get volunteerId;
  @override
  String get taskType;
  @override
  String get description;
  @override
  String? get imageUrl;
  @override
  String? get status; // 'pending', 'assigned', 'processing', 'completed', 'cancelled'
  @override
  String? get result;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get assignedAt;
  @override
  DateTime? get completedAt;

  /// Create a copy of AsyncTaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AsyncTaskModelImplCopyWith<_$AsyncTaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
