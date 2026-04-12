// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) {
  return _ScheduleModel.fromJson(json);
}

/// @nodoc
mixin _$ScheduleModel {
  String get userId => throw _privateConstructorUsedError;
  Map<String, List<TimeSlot>> get weeklySchedule =>
      throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  OnlineStatus get status => throw _privateConstructorUsedError;
  DateTime? get lastStatusUpdateAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ScheduleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleModelCopyWith<ScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleModelCopyWith<$Res> {
  factory $ScheduleModelCopyWith(
    ScheduleModel value,
    $Res Function(ScheduleModel) then,
  ) = _$ScheduleModelCopyWithImpl<$Res, ScheduleModel>;
  @useResult
  $Res call({
    String userId,
    Map<String, List<TimeSlot>> weeklySchedule,
    bool isOnline,
    OnlineStatus status,
    DateTime? lastStatusUpdateAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$ScheduleModelCopyWithImpl<$Res, $Val extends ScheduleModel>
    implements $ScheduleModelCopyWith<$Res> {
  _$ScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? weeklySchedule = null,
    Object? isOnline = null,
    Object? status = null,
    Object? lastStatusUpdateAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            weeklySchedule: null == weeklySchedule
                ? _value.weeklySchedule
                : weeklySchedule // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<TimeSlot>>,
            isOnline: null == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OnlineStatus,
            lastStatusUpdateAt: freezed == lastStatusUpdateAt
                ? _value.lastStatusUpdateAt
                : lastStatusUpdateAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ScheduleModelImplCopyWith<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  factory _$$ScheduleModelImplCopyWith(
    _$ScheduleModelImpl value,
    $Res Function(_$ScheduleModelImpl) then,
  ) = __$$ScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    Map<String, List<TimeSlot>> weeklySchedule,
    bool isOnline,
    OnlineStatus status,
    DateTime? lastStatusUpdateAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ScheduleModelImplCopyWithImpl<$Res>
    extends _$ScheduleModelCopyWithImpl<$Res, _$ScheduleModelImpl>
    implements _$$ScheduleModelImplCopyWith<$Res> {
  __$$ScheduleModelImplCopyWithImpl(
    _$ScheduleModelImpl _value,
    $Res Function(_$ScheduleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? weeklySchedule = null,
    Object? isOnline = null,
    Object? status = null,
    Object? lastStatusUpdateAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ScheduleModelImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        weeklySchedule: null == weeklySchedule
            ? _value._weeklySchedule
            : weeklySchedule // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<TimeSlot>>,
        isOnline: null == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OnlineStatus,
        lastStatusUpdateAt: freezed == lastStatusUpdateAt
            ? _value.lastStatusUpdateAt
            : lastStatusUpdateAt // ignore: cast_nullable_to_non_nullable
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
class _$ScheduleModelImpl extends _ScheduleModel {
  const _$ScheduleModelImpl({
    required this.userId,
    final Map<String, List<TimeSlot>> weeklySchedule = const {},
    this.isOnline = false,
    this.status = OnlineStatus.offline,
    this.lastStatusUpdateAt,
    this.createdAt,
    this.updatedAt,
  }) : _weeklySchedule = weeklySchedule,
       super._();

  factory _$ScheduleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleModelImplFromJson(json);

  @override
  final String userId;
  final Map<String, List<TimeSlot>> _weeklySchedule;
  @override
  @JsonKey()
  Map<String, List<TimeSlot>> get weeklySchedule {
    if (_weeklySchedule is EqualUnmodifiableMapView) return _weeklySchedule;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_weeklySchedule);
  }

  @override
  @JsonKey()
  final bool isOnline;
  @override
  @JsonKey()
  final OnlineStatus status;
  @override
  final DateTime? lastStatusUpdateAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ScheduleModel(userId: $userId, weeklySchedule: $weeklySchedule, isOnline: $isOnline, status: $status, lastStatusUpdateAt: $lastStatusUpdateAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(
              other._weeklySchedule,
              _weeklySchedule,
            ) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastStatusUpdateAt, lastStatusUpdateAt) ||
                other.lastStatusUpdateAt == lastStatusUpdateAt) &&
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
    const DeepCollectionEquality().hash(_weeklySchedule),
    isOnline,
    status,
    lastStatusUpdateAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      __$$ScheduleModelImplCopyWithImpl<_$ScheduleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleModelImplToJson(this);
  }
}

abstract class _ScheduleModel extends ScheduleModel {
  const factory _ScheduleModel({
    required final String userId,
    final Map<String, List<TimeSlot>> weeklySchedule,
    final bool isOnline,
    final OnlineStatus status,
    final DateTime? lastStatusUpdateAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$ScheduleModelImpl;
  const _ScheduleModel._() : super._();

  factory _ScheduleModel.fromJson(Map<String, dynamic> json) =
      _$ScheduleModelImpl.fromJson;

  @override
  String get userId;
  @override
  Map<String, List<TimeSlot>> get weeklySchedule;
  @override
  bool get isOnline;
  @override
  OnlineStatus get status;
  @override
  DateTime? get lastStatusUpdateAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) {
  return _TimeSlot.fromJson(json);
}

/// @nodoc
mixin _$TimeSlot {
  String get start => throw _privateConstructorUsedError;
  String get end => throw _privateConstructorUsedError;

  /// Serializes this TimeSlot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimeSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimeSlotCopyWith<TimeSlot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeSlotCopyWith<$Res> {
  factory $TimeSlotCopyWith(TimeSlot value, $Res Function(TimeSlot) then) =
      _$TimeSlotCopyWithImpl<$Res, TimeSlot>;
  @useResult
  $Res call({String start, String end});
}

/// @nodoc
class _$TimeSlotCopyWithImpl<$Res, $Val extends TimeSlot>
    implements $TimeSlotCopyWith<$Res> {
  _$TimeSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimeSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null}) {
    return _then(
      _value.copyWith(
            start: null == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                      as String,
            end: null == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeSlotImplCopyWith<$Res>
    implements $TimeSlotCopyWith<$Res> {
  factory _$$TimeSlotImplCopyWith(
    _$TimeSlotImpl value,
    $Res Function(_$TimeSlotImpl) then,
  ) = __$$TimeSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String start, String end});
}

/// @nodoc
class __$$TimeSlotImplCopyWithImpl<$Res>
    extends _$TimeSlotCopyWithImpl<$Res, _$TimeSlotImpl>
    implements _$$TimeSlotImplCopyWith<$Res> {
  __$$TimeSlotImplCopyWithImpl(
    _$TimeSlotImpl _value,
    $Res Function(_$TimeSlotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimeSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null}) {
    return _then(
      _$TimeSlotImpl(
        start: null == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as String,
        end: null == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TimeSlotImpl extends _TimeSlot {
  const _$TimeSlotImpl({required this.start, required this.end}) : super._();

  factory _$TimeSlotImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimeSlotImplFromJson(json);

  @override
  final String start;
  @override
  final String end;

  @override
  String toString() {
    return 'TimeSlot(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeSlotImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  /// Create a copy of TimeSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeSlotImplCopyWith<_$TimeSlotImpl> get copyWith =>
      __$$TimeSlotImplCopyWithImpl<_$TimeSlotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimeSlotImplToJson(this);
  }
}

abstract class _TimeSlot extends TimeSlot {
  const factory _TimeSlot({
    required final String start,
    required final String end,
  }) = _$TimeSlotImpl;
  const _TimeSlot._() : super._();

  factory _TimeSlot.fromJson(Map<String, dynamic> json) =
      _$TimeSlotImpl.fromJson;

  @override
  String get start;
  @override
  String get end;

  /// Create a copy of TimeSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimeSlotImplCopyWith<_$TimeSlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
