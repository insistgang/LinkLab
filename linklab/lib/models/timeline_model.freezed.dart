// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timeline_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TimelineModel _$TimelineModelFromJson(Map<String, dynamic> json) {
  return _TimelineModel.fromJson(json);
}

/// @nodoc
mixin _$TimelineModel {
  String get volunteerId => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  List<TimelineDay> get days => throw _privateConstructorUsedError;
  int get totalHelps => throw _privateConstructorUsedError;
  int get totalMinutes => throw _privateConstructorUsedError;
  int get streakDays => throw _privateConstructorUsedError;
  TimelineStats? get stats => throw _privateConstructorUsedError;

  /// Serializes this TimelineModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineModelCopyWith<TimelineModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineModelCopyWith<$Res> {
  factory $TimelineModelCopyWith(
    TimelineModel value,
    $Res Function(TimelineModel) then,
  ) = _$TimelineModelCopyWithImpl<$Res, TimelineModel>;
  @useResult
  $Res call({
    String volunteerId,
    int year,
    List<TimelineDay> days,
    int totalHelps,
    int totalMinutes,
    int streakDays,
    TimelineStats? stats,
  });

  $TimelineStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class _$TimelineModelCopyWithImpl<$Res, $Val extends TimelineModel>
    implements $TimelineModelCopyWith<$Res> {
  _$TimelineModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volunteerId = null,
    Object? year = null,
    Object? days = null,
    Object? totalHelps = null,
    Object? totalMinutes = null,
    Object? streakDays = null,
    Object? stats = freezed,
  }) {
    return _then(
      _value.copyWith(
            volunteerId: null == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String,
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            days: null == days
                ? _value.days
                : days // ignore: cast_nullable_to_non_nullable
                      as List<TimelineDay>,
            totalHelps: null == totalHelps
                ? _value.totalHelps
                : totalHelps // ignore: cast_nullable_to_non_nullable
                      as int,
            totalMinutes: null == totalMinutes
                ? _value.totalMinutes
                : totalMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            streakDays: null == streakDays
                ? _value.streakDays
                : streakDays // ignore: cast_nullable_to_non_nullable
                      as int,
            stats: freezed == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as TimelineStats?,
          )
          as $Val,
    );
  }

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TimelineStatsCopyWith<$Res>? get stats {
    if (_value.stats == null) {
      return null;
    }

    return $TimelineStatsCopyWith<$Res>(_value.stats!, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TimelineModelImplCopyWith<$Res>
    implements $TimelineModelCopyWith<$Res> {
  factory _$$TimelineModelImplCopyWith(
    _$TimelineModelImpl value,
    $Res Function(_$TimelineModelImpl) then,
  ) = __$$TimelineModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String volunteerId,
    int year,
    List<TimelineDay> days,
    int totalHelps,
    int totalMinutes,
    int streakDays,
    TimelineStats? stats,
  });

  @override
  $TimelineStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class __$$TimelineModelImplCopyWithImpl<$Res>
    extends _$TimelineModelCopyWithImpl<$Res, _$TimelineModelImpl>
    implements _$$TimelineModelImplCopyWith<$Res> {
  __$$TimelineModelImplCopyWithImpl(
    _$TimelineModelImpl _value,
    $Res Function(_$TimelineModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volunteerId = null,
    Object? year = null,
    Object? days = null,
    Object? totalHelps = null,
    Object? totalMinutes = null,
    Object? streakDays = null,
    Object? stats = freezed,
  }) {
    return _then(
      _$TimelineModelImpl(
        volunteerId: null == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        days: null == days
            ? _value._days
            : days // ignore: cast_nullable_to_non_nullable
                  as List<TimelineDay>,
        totalHelps: null == totalHelps
            ? _value.totalHelps
            : totalHelps // ignore: cast_nullable_to_non_nullable
                  as int,
        totalMinutes: null == totalMinutes
            ? _value.totalMinutes
            : totalMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        streakDays: null == streakDays
            ? _value.streakDays
            : streakDays // ignore: cast_nullable_to_non_nullable
                  as int,
        stats: freezed == stats
            ? _value.stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as TimelineStats?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineModelImpl implements _TimelineModel {
  const _$TimelineModelImpl({
    required this.volunteerId,
    required this.year,
    final List<TimelineDay> days = const [],
    this.totalHelps = 0,
    this.totalMinutes = 0,
    this.streakDays = 0,
    this.stats,
  }) : _days = days;

  factory _$TimelineModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineModelImplFromJson(json);

  @override
  final String volunteerId;
  @override
  final int year;
  final List<TimelineDay> _days;
  @override
  @JsonKey()
  List<TimelineDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  @JsonKey()
  final int totalHelps;
  @override
  @JsonKey()
  final int totalMinutes;
  @override
  @JsonKey()
  final int streakDays;
  @override
  final TimelineStats? stats;

  @override
  String toString() {
    return 'TimelineModel(volunteerId: $volunteerId, year: $year, days: $days, totalHelps: $totalHelps, totalMinutes: $totalMinutes, streakDays: $streakDays, stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineModelImpl &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.year, year) || other.year == year) &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            (identical(other.totalHelps, totalHelps) ||
                other.totalHelps == totalHelps) &&
            (identical(other.totalMinutes, totalMinutes) ||
                other.totalMinutes == totalMinutes) &&
            (identical(other.streakDays, streakDays) ||
                other.streakDays == streakDays) &&
            (identical(other.stats, stats) || other.stats == stats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    volunteerId,
    year,
    const DeepCollectionEquality().hash(_days),
    totalHelps,
    totalMinutes,
    streakDays,
    stats,
  );

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineModelImplCopyWith<_$TimelineModelImpl> get copyWith =>
      __$$TimelineModelImplCopyWithImpl<_$TimelineModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineModelImplToJson(this);
  }
}

abstract class _TimelineModel implements TimelineModel {
  const factory _TimelineModel({
    required final String volunteerId,
    required final int year,
    final List<TimelineDay> days,
    final int totalHelps,
    final int totalMinutes,
    final int streakDays,
    final TimelineStats? stats,
  }) = _$TimelineModelImpl;

  factory _TimelineModel.fromJson(Map<String, dynamic> json) =
      _$TimelineModelImpl.fromJson;

  @override
  String get volunteerId;
  @override
  int get year;
  @override
  List<TimelineDay> get days;
  @override
  int get totalHelps;
  @override
  int get totalMinutes;
  @override
  int get streakDays;
  @override
  TimelineStats? get stats;

  /// Create a copy of TimelineModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineModelImplCopyWith<_$TimelineModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimelineDay _$TimelineDayFromJson(Map<String, dynamic> json) {
  return _TimelineDay.fromJson(json);
}

/// @nodoc
mixin _$TimelineDay {
  String get date => throw _privateConstructorUsedError;
  int get helpCount => throw _privateConstructorUsedError;
  int get minutes => throw _privateConstructorUsedError;
  List<TimelineEvent> get events => throw _privateConstructorUsedError;

  /// Serializes this TimelineDay to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineDayCopyWith<TimelineDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineDayCopyWith<$Res> {
  factory $TimelineDayCopyWith(
    TimelineDay value,
    $Res Function(TimelineDay) then,
  ) = _$TimelineDayCopyWithImpl<$Res, TimelineDay>;
  @useResult
  $Res call({
    String date,
    int helpCount,
    int minutes,
    List<TimelineEvent> events,
  });
}

/// @nodoc
class _$TimelineDayCopyWithImpl<$Res, $Val extends TimelineDay>
    implements $TimelineDayCopyWith<$Res> {
  _$TimelineDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? helpCount = null,
    Object? minutes = null,
    Object? events = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            helpCount: null == helpCount
                ? _value.helpCount
                : helpCount // ignore: cast_nullable_to_non_nullable
                      as int,
            minutes: null == minutes
                ? _value.minutes
                : minutes // ignore: cast_nullable_to_non_nullable
                      as int,
            events: null == events
                ? _value.events
                : events // ignore: cast_nullable_to_non_nullable
                      as List<TimelineEvent>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimelineDayImplCopyWith<$Res>
    implements $TimelineDayCopyWith<$Res> {
  factory _$$TimelineDayImplCopyWith(
    _$TimelineDayImpl value,
    $Res Function(_$TimelineDayImpl) then,
  ) = __$$TimelineDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String date,
    int helpCount,
    int minutes,
    List<TimelineEvent> events,
  });
}

/// @nodoc
class __$$TimelineDayImplCopyWithImpl<$Res>
    extends _$TimelineDayCopyWithImpl<$Res, _$TimelineDayImpl>
    implements _$$TimelineDayImplCopyWith<$Res> {
  __$$TimelineDayImplCopyWithImpl(
    _$TimelineDayImpl _value,
    $Res Function(_$TimelineDayImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimelineDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? helpCount = null,
    Object? minutes = null,
    Object? events = null,
  }) {
    return _then(
      _$TimelineDayImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        helpCount: null == helpCount
            ? _value.helpCount
            : helpCount // ignore: cast_nullable_to_non_nullable
                  as int,
        minutes: null == minutes
            ? _value.minutes
            : minutes // ignore: cast_nullable_to_non_nullable
                  as int,
        events: null == events
            ? _value._events
            : events // ignore: cast_nullable_to_non_nullable
                  as List<TimelineEvent>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineDayImpl extends _TimelineDay {
  const _$TimelineDayImpl({
    required this.date,
    this.helpCount = 0,
    this.minutes = 0,
    final List<TimelineEvent> events = const [],
  }) : _events = events,
       super._();

  factory _$TimelineDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineDayImplFromJson(json);

  @override
  final String date;
  @override
  @JsonKey()
  final int helpCount;
  @override
  @JsonKey()
  final int minutes;
  final List<TimelineEvent> _events;
  @override
  @JsonKey()
  List<TimelineEvent> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  String toString() {
    return 'TimelineDay(date: $date, helpCount: $helpCount, minutes: $minutes, events: $events)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineDayImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.helpCount, helpCount) ||
                other.helpCount == helpCount) &&
            (identical(other.minutes, minutes) || other.minutes == minutes) &&
            const DeepCollectionEquality().equals(other._events, _events));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    helpCount,
    minutes,
    const DeepCollectionEquality().hash(_events),
  );

  /// Create a copy of TimelineDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineDayImplCopyWith<_$TimelineDayImpl> get copyWith =>
      __$$TimelineDayImplCopyWithImpl<_$TimelineDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineDayImplToJson(this);
  }
}

abstract class _TimelineDay extends TimelineDay {
  const factory _TimelineDay({
    required final String date,
    final int helpCount,
    final int minutes,
    final List<TimelineEvent> events,
  }) = _$TimelineDayImpl;
  const _TimelineDay._() : super._();

  factory _TimelineDay.fromJson(Map<String, dynamic> json) =
      _$TimelineDayImpl.fromJson;

  @override
  String get date;
  @override
  int get helpCount;
  @override
  int get minutes;
  @override
  List<TimelineEvent> get events;

  /// Create a copy of TimelineDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineDayImplCopyWith<_$TimelineDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimelineEvent _$TimelineEventFromJson(Map<String, dynamic> json) {
  return _TimelineEvent.fromJson(json);
}

/// @nodoc
mixin _$TimelineEvent {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get seekerName => throw _privateConstructorUsedError;
  int? get durationMinutes => throw _privateConstructorUsedError;
  int? get rating => throw _privateConstructorUsedError;
  String? get thankYouNote => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TimelineEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineEventCopyWith<TimelineEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineEventCopyWith<$Res> {
  factory $TimelineEventCopyWith(
    TimelineEvent value,
    $Res Function(TimelineEvent) then,
  ) = _$TimelineEventCopyWithImpl<$Res, TimelineEvent>;
  @useResult
  $Res call({
    String id,
    String type,
    String? seekerName,
    int? durationMinutes,
    int? rating,
    String? thankYouNote,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$TimelineEventCopyWithImpl<$Res, $Val extends TimelineEvent>
    implements $TimelineEventCopyWith<$Res> {
  _$TimelineEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? seekerName = freezed,
    Object? durationMinutes = freezed,
    Object? rating = freezed,
    Object? thankYouNote = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            seekerName: freezed == seekerName
                ? _value.seekerName
                : seekerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            durationMinutes: freezed == durationMinutes
                ? _value.durationMinutes
                : durationMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as int?,
            thankYouNote: freezed == thankYouNote
                ? _value.thankYouNote
                : thankYouNote // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$TimelineEventImplCopyWith<$Res>
    implements $TimelineEventCopyWith<$Res> {
  factory _$$TimelineEventImplCopyWith(
    _$TimelineEventImpl value,
    $Res Function(_$TimelineEventImpl) then,
  ) = __$$TimelineEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String? seekerName,
    int? durationMinutes,
    int? rating,
    String? thankYouNote,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$TimelineEventImplCopyWithImpl<$Res>
    extends _$TimelineEventCopyWithImpl<$Res, _$TimelineEventImpl>
    implements _$$TimelineEventImplCopyWith<$Res> {
  __$$TimelineEventImplCopyWithImpl(
    _$TimelineEventImpl _value,
    $Res Function(_$TimelineEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimelineEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? seekerName = freezed,
    Object? durationMinutes = freezed,
    Object? rating = freezed,
    Object? thankYouNote = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$TimelineEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        seekerName: freezed == seekerName
            ? _value.seekerName
            : seekerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        durationMinutes: freezed == durationMinutes
            ? _value.durationMinutes
            : durationMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as int?,
        thankYouNote: freezed == thankYouNote
            ? _value.thankYouNote
            : thankYouNote // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$TimelineEventImpl implements _TimelineEvent {
  const _$TimelineEventImpl({
    required this.id,
    required this.type,
    this.seekerName,
    this.durationMinutes,
    this.rating,
    this.thankYouNote,
    this.createdAt,
  });

  factory _$TimelineEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineEventImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String? seekerName;
  @override
  final int? durationMinutes;
  @override
  final int? rating;
  @override
  final String? thankYouNote;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'TimelineEvent(id: $id, type: $type, seekerName: $seekerName, durationMinutes: $durationMinutes, rating: $rating, thankYouNote: $thankYouNote, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.seekerName, seekerName) ||
                other.seekerName == seekerName) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.thankYouNote, thankYouNote) ||
                other.thankYouNote == thankYouNote) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    seekerName,
    durationMinutes,
    rating,
    thankYouNote,
    createdAt,
  );

  /// Create a copy of TimelineEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineEventImplCopyWith<_$TimelineEventImpl> get copyWith =>
      __$$TimelineEventImplCopyWithImpl<_$TimelineEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineEventImplToJson(this);
  }
}

abstract class _TimelineEvent implements TimelineEvent {
  const factory _TimelineEvent({
    required final String id,
    required final String type,
    final String? seekerName,
    final int? durationMinutes,
    final int? rating,
    final String? thankYouNote,
    final DateTime? createdAt,
  }) = _$TimelineEventImpl;

  factory _TimelineEvent.fromJson(Map<String, dynamic> json) =
      _$TimelineEventImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String? get seekerName;
  @override
  int? get durationMinutes;
  @override
  int? get rating;
  @override
  String? get thankYouNote;
  @override
  DateTime? get createdAt;

  /// Create a copy of TimelineEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineEventImplCopyWith<_$TimelineEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimelineStats _$TimelineStatsFromJson(Map<String, dynamic> json) {
  return _TimelineStats.fromJson(json);
}

/// @nodoc
mixin _$TimelineStats {
  int get realtimeHelpCount => throw _privateConstructorUsedError;
  int get asyncHelpCount => throw _privateConstructorUsedError;
  double get averageRating => throw _privateConstructorUsedError;
  int get fiveStarCount => throw _privateConstructorUsedError;
  String? get mostHelpedSeekerId => throw _privateConstructorUsedError;
  String? get mostHelpedSeekerName => throw _privateConstructorUsedError;
  int get mostHelpedCount => throw _privateConstructorUsedError;
  List<String> get topSkills => throw _privateConstructorUsedError;

  /// Serializes this TimelineStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineStatsCopyWith<TimelineStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineStatsCopyWith<$Res> {
  factory $TimelineStatsCopyWith(
    TimelineStats value,
    $Res Function(TimelineStats) then,
  ) = _$TimelineStatsCopyWithImpl<$Res, TimelineStats>;
  @useResult
  $Res call({
    int realtimeHelpCount,
    int asyncHelpCount,
    double averageRating,
    int fiveStarCount,
    String? mostHelpedSeekerId,
    String? mostHelpedSeekerName,
    int mostHelpedCount,
    List<String> topSkills,
  });
}

/// @nodoc
class _$TimelineStatsCopyWithImpl<$Res, $Val extends TimelineStats>
    implements $TimelineStatsCopyWith<$Res> {
  _$TimelineStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? realtimeHelpCount = null,
    Object? asyncHelpCount = null,
    Object? averageRating = null,
    Object? fiveStarCount = null,
    Object? mostHelpedSeekerId = freezed,
    Object? mostHelpedSeekerName = freezed,
    Object? mostHelpedCount = null,
    Object? topSkills = null,
  }) {
    return _then(
      _value.copyWith(
            realtimeHelpCount: null == realtimeHelpCount
                ? _value.realtimeHelpCount
                : realtimeHelpCount // ignore: cast_nullable_to_non_nullable
                      as int,
            asyncHelpCount: null == asyncHelpCount
                ? _value.asyncHelpCount
                : asyncHelpCount // ignore: cast_nullable_to_non_nullable
                      as int,
            averageRating: null == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double,
            fiveStarCount: null == fiveStarCount
                ? _value.fiveStarCount
                : fiveStarCount // ignore: cast_nullable_to_non_nullable
                      as int,
            mostHelpedSeekerId: freezed == mostHelpedSeekerId
                ? _value.mostHelpedSeekerId
                : mostHelpedSeekerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mostHelpedSeekerName: freezed == mostHelpedSeekerName
                ? _value.mostHelpedSeekerName
                : mostHelpedSeekerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            mostHelpedCount: null == mostHelpedCount
                ? _value.mostHelpedCount
                : mostHelpedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            topSkills: null == topSkills
                ? _value.topSkills
                : topSkills // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimelineStatsImplCopyWith<$Res>
    implements $TimelineStatsCopyWith<$Res> {
  factory _$$TimelineStatsImplCopyWith(
    _$TimelineStatsImpl value,
    $Res Function(_$TimelineStatsImpl) then,
  ) = __$$TimelineStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int realtimeHelpCount,
    int asyncHelpCount,
    double averageRating,
    int fiveStarCount,
    String? mostHelpedSeekerId,
    String? mostHelpedSeekerName,
    int mostHelpedCount,
    List<String> topSkills,
  });
}

/// @nodoc
class __$$TimelineStatsImplCopyWithImpl<$Res>
    extends _$TimelineStatsCopyWithImpl<$Res, _$TimelineStatsImpl>
    implements _$$TimelineStatsImplCopyWith<$Res> {
  __$$TimelineStatsImplCopyWithImpl(
    _$TimelineStatsImpl _value,
    $Res Function(_$TimelineStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimelineStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? realtimeHelpCount = null,
    Object? asyncHelpCount = null,
    Object? averageRating = null,
    Object? fiveStarCount = null,
    Object? mostHelpedSeekerId = freezed,
    Object? mostHelpedSeekerName = freezed,
    Object? mostHelpedCount = null,
    Object? topSkills = null,
  }) {
    return _then(
      _$TimelineStatsImpl(
        realtimeHelpCount: null == realtimeHelpCount
            ? _value.realtimeHelpCount
            : realtimeHelpCount // ignore: cast_nullable_to_non_nullable
                  as int,
        asyncHelpCount: null == asyncHelpCount
            ? _value.asyncHelpCount
            : asyncHelpCount // ignore: cast_nullable_to_non_nullable
                  as int,
        averageRating: null == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double,
        fiveStarCount: null == fiveStarCount
            ? _value.fiveStarCount
            : fiveStarCount // ignore: cast_nullable_to_non_nullable
                  as int,
        mostHelpedSeekerId: freezed == mostHelpedSeekerId
            ? _value.mostHelpedSeekerId
            : mostHelpedSeekerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mostHelpedSeekerName: freezed == mostHelpedSeekerName
            ? _value.mostHelpedSeekerName
            : mostHelpedSeekerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        mostHelpedCount: null == mostHelpedCount
            ? _value.mostHelpedCount
            : mostHelpedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        topSkills: null == topSkills
            ? _value._topSkills
            : topSkills // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineStatsImpl implements _TimelineStats {
  const _$TimelineStatsImpl({
    this.realtimeHelpCount = 0,
    this.asyncHelpCount = 0,
    this.averageRating = 0,
    this.fiveStarCount = 0,
    this.mostHelpedSeekerId,
    this.mostHelpedSeekerName,
    this.mostHelpedCount = 0,
    final List<String> topSkills = const [],
  }) : _topSkills = topSkills;

  factory _$TimelineStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineStatsImplFromJson(json);

  @override
  @JsonKey()
  final int realtimeHelpCount;
  @override
  @JsonKey()
  final int asyncHelpCount;
  @override
  @JsonKey()
  final double averageRating;
  @override
  @JsonKey()
  final int fiveStarCount;
  @override
  final String? mostHelpedSeekerId;
  @override
  final String? mostHelpedSeekerName;
  @override
  @JsonKey()
  final int mostHelpedCount;
  final List<String> _topSkills;
  @override
  @JsonKey()
  List<String> get topSkills {
    if (_topSkills is EqualUnmodifiableListView) return _topSkills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSkills);
  }

  @override
  String toString() {
    return 'TimelineStats(realtimeHelpCount: $realtimeHelpCount, asyncHelpCount: $asyncHelpCount, averageRating: $averageRating, fiveStarCount: $fiveStarCount, mostHelpedSeekerId: $mostHelpedSeekerId, mostHelpedSeekerName: $mostHelpedSeekerName, mostHelpedCount: $mostHelpedCount, topSkills: $topSkills)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineStatsImpl &&
            (identical(other.realtimeHelpCount, realtimeHelpCount) ||
                other.realtimeHelpCount == realtimeHelpCount) &&
            (identical(other.asyncHelpCount, asyncHelpCount) ||
                other.asyncHelpCount == asyncHelpCount) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.fiveStarCount, fiveStarCount) ||
                other.fiveStarCount == fiveStarCount) &&
            (identical(other.mostHelpedSeekerId, mostHelpedSeekerId) ||
                other.mostHelpedSeekerId == mostHelpedSeekerId) &&
            (identical(other.mostHelpedSeekerName, mostHelpedSeekerName) ||
                other.mostHelpedSeekerName == mostHelpedSeekerName) &&
            (identical(other.mostHelpedCount, mostHelpedCount) ||
                other.mostHelpedCount == mostHelpedCount) &&
            const DeepCollectionEquality().equals(
              other._topSkills,
              _topSkills,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    realtimeHelpCount,
    asyncHelpCount,
    averageRating,
    fiveStarCount,
    mostHelpedSeekerId,
    mostHelpedSeekerName,
    mostHelpedCount,
    const DeepCollectionEquality().hash(_topSkills),
  );

  /// Create a copy of TimelineStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineStatsImplCopyWith<_$TimelineStatsImpl> get copyWith =>
      __$$TimelineStatsImplCopyWithImpl<_$TimelineStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineStatsImplToJson(this);
  }
}

abstract class _TimelineStats implements TimelineStats {
  const factory _TimelineStats({
    final int realtimeHelpCount,
    final int asyncHelpCount,
    final double averageRating,
    final int fiveStarCount,
    final String? mostHelpedSeekerId,
    final String? mostHelpedSeekerName,
    final int mostHelpedCount,
    final List<String> topSkills,
  }) = _$TimelineStatsImpl;

  factory _TimelineStats.fromJson(Map<String, dynamic> json) =
      _$TimelineStatsImpl.fromJson;

  @override
  int get realtimeHelpCount;
  @override
  int get asyncHelpCount;
  @override
  double get averageRating;
  @override
  int get fiveStarCount;
  @override
  String? get mostHelpedSeekerId;
  @override
  String? get mostHelpedSeekerName;
  @override
  int get mostHelpedCount;
  @override
  List<String> get topSkills;

  /// Create a copy of TimelineStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineStatsImplCopyWith<_$TimelineStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnnualReport _$AnnualReportFromJson(Map<String, dynamic> json) {
  return _AnnualReport.fromJson(json);
}

/// @nodoc
mixin _$AnnualReport {
  String get volunteerId => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<ReportSection> get sections => throw _privateConstructorUsedError;
  DateTime? get generatedAt => throw _privateConstructorUsedError;

  /// Serializes this AnnualReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnnualReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnnualReportCopyWith<AnnualReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnnualReportCopyWith<$Res> {
  factory $AnnualReportCopyWith(
    AnnualReport value,
    $Res Function(AnnualReport) then,
  ) = _$AnnualReportCopyWithImpl<$Res, AnnualReport>;
  @useResult
  $Res call({
    String volunteerId,
    int year,
    String title,
    List<ReportSection> sections,
    DateTime? generatedAt,
  });
}

/// @nodoc
class _$AnnualReportCopyWithImpl<$Res, $Val extends AnnualReport>
    implements $AnnualReportCopyWith<$Res> {
  _$AnnualReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnnualReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volunteerId = null,
    Object? year = null,
    Object? title = null,
    Object? sections = null,
    Object? generatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            volunteerId: null == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String,
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            sections: null == sections
                ? _value.sections
                : sections // ignore: cast_nullable_to_non_nullable
                      as List<ReportSection>,
            generatedAt: freezed == generatedAt
                ? _value.generatedAt
                : generatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnnualReportImplCopyWith<$Res>
    implements $AnnualReportCopyWith<$Res> {
  factory _$$AnnualReportImplCopyWith(
    _$AnnualReportImpl value,
    $Res Function(_$AnnualReportImpl) then,
  ) = __$$AnnualReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String volunteerId,
    int year,
    String title,
    List<ReportSection> sections,
    DateTime? generatedAt,
  });
}

/// @nodoc
class __$$AnnualReportImplCopyWithImpl<$Res>
    extends _$AnnualReportCopyWithImpl<$Res, _$AnnualReportImpl>
    implements _$$AnnualReportImplCopyWith<$Res> {
  __$$AnnualReportImplCopyWithImpl(
    _$AnnualReportImpl _value,
    $Res Function(_$AnnualReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnnualReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volunteerId = null,
    Object? year = null,
    Object? title = null,
    Object? sections = null,
    Object? generatedAt = freezed,
  }) {
    return _then(
      _$AnnualReportImpl(
        volunteerId: null == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        sections: null == sections
            ? _value._sections
            : sections // ignore: cast_nullable_to_non_nullable
                  as List<ReportSection>,
        generatedAt: freezed == generatedAt
            ? _value.generatedAt
            : generatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnnualReportImpl implements _AnnualReport {
  const _$AnnualReportImpl({
    required this.volunteerId,
    required this.year,
    required this.title,
    final List<ReportSection> sections = const [],
    this.generatedAt,
  }) : _sections = sections;

  factory _$AnnualReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnnualReportImplFromJson(json);

  @override
  final String volunteerId;
  @override
  final int year;
  @override
  final String title;
  final List<ReportSection> _sections;
  @override
  @JsonKey()
  List<ReportSection> get sections {
    if (_sections is EqualUnmodifiableListView) return _sections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sections);
  }

  @override
  final DateTime? generatedAt;

  @override
  String toString() {
    return 'AnnualReport(volunteerId: $volunteerId, year: $year, title: $title, sections: $sections, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnnualReportImpl &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._sections, _sections) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    volunteerId,
    year,
    title,
    const DeepCollectionEquality().hash(_sections),
    generatedAt,
  );

  /// Create a copy of AnnualReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnnualReportImplCopyWith<_$AnnualReportImpl> get copyWith =>
      __$$AnnualReportImplCopyWithImpl<_$AnnualReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnnualReportImplToJson(this);
  }
}

abstract class _AnnualReport implements AnnualReport {
  const factory _AnnualReport({
    required final String volunteerId,
    required final int year,
    required final String title,
    final List<ReportSection> sections,
    final DateTime? generatedAt,
  }) = _$AnnualReportImpl;

  factory _AnnualReport.fromJson(Map<String, dynamic> json) =
      _$AnnualReportImpl.fromJson;

  @override
  String get volunteerId;
  @override
  int get year;
  @override
  String get title;
  @override
  List<ReportSection> get sections;
  @override
  DateTime? get generatedAt;

  /// Create a copy of AnnualReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnnualReportImplCopyWith<_$AnnualReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReportSection _$ReportSectionFromJson(Map<String, dynamic> json) {
  return _ReportSection.fromJson(json);
}

/// @nodoc
mixin _$ReportSection {
  String get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  /// Serializes this ReportSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportSectionCopyWith<ReportSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportSectionCopyWith<$Res> {
  factory $ReportSectionCopyWith(
    ReportSection value,
    $Res Function(ReportSection) then,
  ) = _$ReportSectionCopyWithImpl<$Res, ReportSection>;
  @useResult
  $Res call({
    String type,
    String title,
    String? subtitle,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class _$ReportSectionCopyWithImpl<$Res, $Val extends ReportSection>
    implements $ReportSectionCopyWith<$Res> {
  _$ReportSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportSectionImplCopyWith<$Res>
    implements $ReportSectionCopyWith<$Res> {
  factory _$$ReportSectionImplCopyWith(
    _$ReportSectionImpl value,
    $Res Function(_$ReportSectionImpl) then,
  ) = __$$ReportSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    String title,
    String? subtitle,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class __$$ReportSectionImplCopyWithImpl<$Res>
    extends _$ReportSectionCopyWithImpl<$Res, _$ReportSectionImpl>
    implements _$$ReportSectionImplCopyWith<$Res> {
  __$$ReportSectionImplCopyWithImpl(
    _$ReportSectionImpl _value,
    $Res Function(_$ReportSectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? data = freezed,
  }) {
    return _then(
      _$ReportSectionImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: freezed == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportSectionImpl implements _ReportSection {
  const _$ReportSectionImpl({
    required this.type,
    required this.title,
    this.subtitle,
    final Map<String, dynamic>? data,
  }) : _data = data;

  factory _$ReportSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportSectionImplFromJson(json);

  @override
  final String type;
  @override
  final String title;
  @override
  final String? subtitle;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ReportSection(type: $type, title: $title, subtitle: $subtitle, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportSectionImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    title,
    subtitle,
    const DeepCollectionEquality().hash(_data),
  );

  /// Create a copy of ReportSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportSectionImplCopyWith<_$ReportSectionImpl> get copyWith =>
      __$$ReportSectionImplCopyWithImpl<_$ReportSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportSectionImplToJson(this);
  }
}

abstract class _ReportSection implements ReportSection {
  const factory _ReportSection({
    required final String type,
    required final String title,
    final String? subtitle,
    final Map<String, dynamic>? data,
  }) = _$ReportSectionImpl;

  factory _ReportSection.fromJson(Map<String, dynamic> json) =
      _$ReportSectionImpl.fromJson;

  @override
  String get type;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  Map<String, dynamic>? get data;

  /// Create a copy of ReportSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportSectionImplCopyWith<_$ReportSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
