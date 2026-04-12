// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_statistics_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HelpStatistics _$HelpStatisticsFromJson(Map<String, dynamic> json) {
  return _HelpStatistics.fromJson(json);
}

/// @nodoc
mixin _$HelpStatistics {
  int get totalRequests => throw _privateConstructorUsedError;
  int get aiResolvedCount => throw _privateConstructorUsedError;
  int get volunteerHelpCount => throw _privateConstructorUsedError;
  int get sosCount => throw _privateConstructorUsedError;
  double get aiResolutionRate => throw _privateConstructorUsedError;
  int get totalDurationMinutes => throw _privateConstructorUsedError;
  double get averageRating => throw _privateConstructorUsedError;
  List<HelpTypeStat> get typeStats => throw _privateConstructorUsedError;
  List<MonthlyStat> get monthlyStats => throw _privateConstructorUsedError;
  DateTime? get lastUpdatedAt => throw _privateConstructorUsedError;

  /// Serializes this HelpStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HelpStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HelpStatisticsCopyWith<HelpStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HelpStatisticsCopyWith<$Res> {
  factory $HelpStatisticsCopyWith(
    HelpStatistics value,
    $Res Function(HelpStatistics) then,
  ) = _$HelpStatisticsCopyWithImpl<$Res, HelpStatistics>;
  @useResult
  $Res call({
    int totalRequests,
    int aiResolvedCount,
    int volunteerHelpCount,
    int sosCount,
    double aiResolutionRate,
    int totalDurationMinutes,
    double averageRating,
    List<HelpTypeStat> typeStats,
    List<MonthlyStat> monthlyStats,
    DateTime? lastUpdatedAt,
  });
}

/// @nodoc
class _$HelpStatisticsCopyWithImpl<$Res, $Val extends HelpStatistics>
    implements $HelpStatisticsCopyWith<$Res> {
  _$HelpStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HelpStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalRequests = null,
    Object? aiResolvedCount = null,
    Object? volunteerHelpCount = null,
    Object? sosCount = null,
    Object? aiResolutionRate = null,
    Object? totalDurationMinutes = null,
    Object? averageRating = null,
    Object? typeStats = null,
    Object? monthlyStats = null,
    Object? lastUpdatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalRequests: null == totalRequests
                ? _value.totalRequests
                : totalRequests // ignore: cast_nullable_to_non_nullable
                      as int,
            aiResolvedCount: null == aiResolvedCount
                ? _value.aiResolvedCount
                : aiResolvedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            volunteerHelpCount: null == volunteerHelpCount
                ? _value.volunteerHelpCount
                : volunteerHelpCount // ignore: cast_nullable_to_non_nullable
                      as int,
            sosCount: null == sosCount
                ? _value.sosCount
                : sosCount // ignore: cast_nullable_to_non_nullable
                      as int,
            aiResolutionRate: null == aiResolutionRate
                ? _value.aiResolutionRate
                : aiResolutionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            totalDurationMinutes: null == totalDurationMinutes
                ? _value.totalDurationMinutes
                : totalDurationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            averageRating: null == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double,
            typeStats: null == typeStats
                ? _value.typeStats
                : typeStats // ignore: cast_nullable_to_non_nullable
                      as List<HelpTypeStat>,
            monthlyStats: null == monthlyStats
                ? _value.monthlyStats
                : monthlyStats // ignore: cast_nullable_to_non_nullable
                      as List<MonthlyStat>,
            lastUpdatedAt: freezed == lastUpdatedAt
                ? _value.lastUpdatedAt
                : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HelpStatisticsImplCopyWith<$Res>
    implements $HelpStatisticsCopyWith<$Res> {
  factory _$$HelpStatisticsImplCopyWith(
    _$HelpStatisticsImpl value,
    $Res Function(_$HelpStatisticsImpl) then,
  ) = __$$HelpStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalRequests,
    int aiResolvedCount,
    int volunteerHelpCount,
    int sosCount,
    double aiResolutionRate,
    int totalDurationMinutes,
    double averageRating,
    List<HelpTypeStat> typeStats,
    List<MonthlyStat> monthlyStats,
    DateTime? lastUpdatedAt,
  });
}

/// @nodoc
class __$$HelpStatisticsImplCopyWithImpl<$Res>
    extends _$HelpStatisticsCopyWithImpl<$Res, _$HelpStatisticsImpl>
    implements _$$HelpStatisticsImplCopyWith<$Res> {
  __$$HelpStatisticsImplCopyWithImpl(
    _$HelpStatisticsImpl _value,
    $Res Function(_$HelpStatisticsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalRequests = null,
    Object? aiResolvedCount = null,
    Object? volunteerHelpCount = null,
    Object? sosCount = null,
    Object? aiResolutionRate = null,
    Object? totalDurationMinutes = null,
    Object? averageRating = null,
    Object? typeStats = null,
    Object? monthlyStats = null,
    Object? lastUpdatedAt = freezed,
  }) {
    return _then(
      _$HelpStatisticsImpl(
        totalRequests: null == totalRequests
            ? _value.totalRequests
            : totalRequests // ignore: cast_nullable_to_non_nullable
                  as int,
        aiResolvedCount: null == aiResolvedCount
            ? _value.aiResolvedCount
            : aiResolvedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        volunteerHelpCount: null == volunteerHelpCount
            ? _value.volunteerHelpCount
            : volunteerHelpCount // ignore: cast_nullable_to_non_nullable
                  as int,
        sosCount: null == sosCount
            ? _value.sosCount
            : sosCount // ignore: cast_nullable_to_non_nullable
                  as int,
        aiResolutionRate: null == aiResolutionRate
            ? _value.aiResolutionRate
            : aiResolutionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        totalDurationMinutes: null == totalDurationMinutes
            ? _value.totalDurationMinutes
            : totalDurationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        averageRating: null == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double,
        typeStats: null == typeStats
            ? _value._typeStats
            : typeStats // ignore: cast_nullable_to_non_nullable
                  as List<HelpTypeStat>,
        monthlyStats: null == monthlyStats
            ? _value._monthlyStats
            : monthlyStats // ignore: cast_nullable_to_non_nullable
                  as List<MonthlyStat>,
        lastUpdatedAt: freezed == lastUpdatedAt
            ? _value.lastUpdatedAt
            : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HelpStatisticsImpl extends _HelpStatistics {
  const _$HelpStatisticsImpl({
    this.totalRequests = 0,
    this.aiResolvedCount = 0,
    this.volunteerHelpCount = 0,
    this.sosCount = 0,
    this.aiResolutionRate = 0.0,
    this.totalDurationMinutes = 0,
    this.averageRating = 0.0,
    final List<HelpTypeStat> typeStats = const [],
    final List<MonthlyStat> monthlyStats = const [],
    this.lastUpdatedAt,
  }) : _typeStats = typeStats,
       _monthlyStats = monthlyStats,
       super._();

  factory _$HelpStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$HelpStatisticsImplFromJson(json);

  @override
  @JsonKey()
  final int totalRequests;
  @override
  @JsonKey()
  final int aiResolvedCount;
  @override
  @JsonKey()
  final int volunteerHelpCount;
  @override
  @JsonKey()
  final int sosCount;
  @override
  @JsonKey()
  final double aiResolutionRate;
  @override
  @JsonKey()
  final int totalDurationMinutes;
  @override
  @JsonKey()
  final double averageRating;
  final List<HelpTypeStat> _typeStats;
  @override
  @JsonKey()
  List<HelpTypeStat> get typeStats {
    if (_typeStats is EqualUnmodifiableListView) return _typeStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_typeStats);
  }

  final List<MonthlyStat> _monthlyStats;
  @override
  @JsonKey()
  List<MonthlyStat> get monthlyStats {
    if (_monthlyStats is EqualUnmodifiableListView) return _monthlyStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_monthlyStats);
  }

  @override
  final DateTime? lastUpdatedAt;

  @override
  String toString() {
    return 'HelpStatistics(totalRequests: $totalRequests, aiResolvedCount: $aiResolvedCount, volunteerHelpCount: $volunteerHelpCount, sosCount: $sosCount, aiResolutionRate: $aiResolutionRate, totalDurationMinutes: $totalDurationMinutes, averageRating: $averageRating, typeStats: $typeStats, monthlyStats: $monthlyStats, lastUpdatedAt: $lastUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HelpStatisticsImpl &&
            (identical(other.totalRequests, totalRequests) ||
                other.totalRequests == totalRequests) &&
            (identical(other.aiResolvedCount, aiResolvedCount) ||
                other.aiResolvedCount == aiResolvedCount) &&
            (identical(other.volunteerHelpCount, volunteerHelpCount) ||
                other.volunteerHelpCount == volunteerHelpCount) &&
            (identical(other.sosCount, sosCount) ||
                other.sosCount == sosCount) &&
            (identical(other.aiResolutionRate, aiResolutionRate) ||
                other.aiResolutionRate == aiResolutionRate) &&
            (identical(other.totalDurationMinutes, totalDurationMinutes) ||
                other.totalDurationMinutes == totalDurationMinutes) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            const DeepCollectionEquality().equals(
              other._typeStats,
              _typeStats,
            ) &&
            const DeepCollectionEquality().equals(
              other._monthlyStats,
              _monthlyStats,
            ) &&
            (identical(other.lastUpdatedAt, lastUpdatedAt) ||
                other.lastUpdatedAt == lastUpdatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalRequests,
    aiResolvedCount,
    volunteerHelpCount,
    sosCount,
    aiResolutionRate,
    totalDurationMinutes,
    averageRating,
    const DeepCollectionEquality().hash(_typeStats),
    const DeepCollectionEquality().hash(_monthlyStats),
    lastUpdatedAt,
  );

  /// Create a copy of HelpStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HelpStatisticsImplCopyWith<_$HelpStatisticsImpl> get copyWith =>
      __$$HelpStatisticsImplCopyWithImpl<_$HelpStatisticsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HelpStatisticsImplToJson(this);
  }
}

abstract class _HelpStatistics extends HelpStatistics {
  const factory _HelpStatistics({
    final int totalRequests,
    final int aiResolvedCount,
    final int volunteerHelpCount,
    final int sosCount,
    final double aiResolutionRate,
    final int totalDurationMinutes,
    final double averageRating,
    final List<HelpTypeStat> typeStats,
    final List<MonthlyStat> monthlyStats,
    final DateTime? lastUpdatedAt,
  }) = _$HelpStatisticsImpl;
  const _HelpStatistics._() : super._();

  factory _HelpStatistics.fromJson(Map<String, dynamic> json) =
      _$HelpStatisticsImpl.fromJson;

  @override
  int get totalRequests;
  @override
  int get aiResolvedCount;
  @override
  int get volunteerHelpCount;
  @override
  int get sosCount;
  @override
  double get aiResolutionRate;
  @override
  int get totalDurationMinutes;
  @override
  double get averageRating;
  @override
  List<HelpTypeStat> get typeStats;
  @override
  List<MonthlyStat> get monthlyStats;
  @override
  DateTime? get lastUpdatedAt;

  /// Create a copy of HelpStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HelpStatisticsImplCopyWith<_$HelpStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HelpTypeStat _$HelpTypeStatFromJson(Map<String, dynamic> json) {
  return _HelpTypeStat.fromJson(json);
}

/// @nodoc
mixin _$HelpTypeStat {
  String get type => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String? get typeLabel => throw _privateConstructorUsedError;

  /// Serializes this HelpTypeStat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HelpTypeStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HelpTypeStatCopyWith<HelpTypeStat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HelpTypeStatCopyWith<$Res> {
  factory $HelpTypeStatCopyWith(
    HelpTypeStat value,
    $Res Function(HelpTypeStat) then,
  ) = _$HelpTypeStatCopyWithImpl<$Res, HelpTypeStat>;
  @useResult
  $Res call({String type, int count, String? typeLabel});
}

/// @nodoc
class _$HelpTypeStatCopyWithImpl<$Res, $Val extends HelpTypeStat>
    implements $HelpTypeStatCopyWith<$Res> {
  _$HelpTypeStatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HelpTypeStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? count = null,
    Object? typeLabel = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            typeLabel: freezed == typeLabel
                ? _value.typeLabel
                : typeLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HelpTypeStatImplCopyWith<$Res>
    implements $HelpTypeStatCopyWith<$Res> {
  factory _$$HelpTypeStatImplCopyWith(
    _$HelpTypeStatImpl value,
    $Res Function(_$HelpTypeStatImpl) then,
  ) = __$$HelpTypeStatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, int count, String? typeLabel});
}

/// @nodoc
class __$$HelpTypeStatImplCopyWithImpl<$Res>
    extends _$HelpTypeStatCopyWithImpl<$Res, _$HelpTypeStatImpl>
    implements _$$HelpTypeStatImplCopyWith<$Res> {
  __$$HelpTypeStatImplCopyWithImpl(
    _$HelpTypeStatImpl _value,
    $Res Function(_$HelpTypeStatImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpTypeStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? count = null,
    Object? typeLabel = freezed,
  }) {
    return _then(
      _$HelpTypeStatImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        typeLabel: freezed == typeLabel
            ? _value.typeLabel
            : typeLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HelpTypeStatImpl implements _HelpTypeStat {
  const _$HelpTypeStatImpl({
    required this.type,
    required this.count,
    this.typeLabel,
  });

  factory _$HelpTypeStatImpl.fromJson(Map<String, dynamic> json) =>
      _$$HelpTypeStatImplFromJson(json);

  @override
  final String type;
  @override
  final int count;
  @override
  final String? typeLabel;

  @override
  String toString() {
    return 'HelpTypeStat(type: $type, count: $count, typeLabel: $typeLabel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HelpTypeStatImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.typeLabel, typeLabel) ||
                other.typeLabel == typeLabel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, count, typeLabel);

  /// Create a copy of HelpTypeStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HelpTypeStatImplCopyWith<_$HelpTypeStatImpl> get copyWith =>
      __$$HelpTypeStatImplCopyWithImpl<_$HelpTypeStatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HelpTypeStatImplToJson(this);
  }
}

abstract class _HelpTypeStat implements HelpTypeStat {
  const factory _HelpTypeStat({
    required final String type,
    required final int count,
    final String? typeLabel,
  }) = _$HelpTypeStatImpl;

  factory _HelpTypeStat.fromJson(Map<String, dynamic> json) =
      _$HelpTypeStatImpl.fromJson;

  @override
  String get type;
  @override
  int get count;
  @override
  String? get typeLabel;

  /// Create a copy of HelpTypeStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HelpTypeStatImplCopyWith<_$HelpTypeStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonthlyStat _$MonthlyStatFromJson(Map<String, dynamic> json) {
  return _MonthlyStat.fromJson(json);
}

/// @nodoc
mixin _$MonthlyStat {
  String get month => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  int get aiCount => throw _privateConstructorUsedError;
  int get volunteerCount => throw _privateConstructorUsedError;

  /// Serializes this MonthlyStat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlyStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlyStatCopyWith<MonthlyStat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlyStatCopyWith<$Res> {
  factory $MonthlyStatCopyWith(
    MonthlyStat value,
    $Res Function(MonthlyStat) then,
  ) = _$MonthlyStatCopyWithImpl<$Res, MonthlyStat>;
  @useResult
  $Res call({String month, int count, int aiCount, int volunteerCount});
}

/// @nodoc
class _$MonthlyStatCopyWithImpl<$Res, $Val extends MonthlyStat>
    implements $MonthlyStatCopyWith<$Res> {
  _$MonthlyStatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlyStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? count = null,
    Object? aiCount = null,
    Object? volunteerCount = null,
  }) {
    return _then(
      _value.copyWith(
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            aiCount: null == aiCount
                ? _value.aiCount
                : aiCount // ignore: cast_nullable_to_non_nullable
                      as int,
            volunteerCount: null == volunteerCount
                ? _value.volunteerCount
                : volunteerCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonthlyStatImplCopyWith<$Res>
    implements $MonthlyStatCopyWith<$Res> {
  factory _$$MonthlyStatImplCopyWith(
    _$MonthlyStatImpl value,
    $Res Function(_$MonthlyStatImpl) then,
  ) = __$$MonthlyStatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String month, int count, int aiCount, int volunteerCount});
}

/// @nodoc
class __$$MonthlyStatImplCopyWithImpl<$Res>
    extends _$MonthlyStatCopyWithImpl<$Res, _$MonthlyStatImpl>
    implements _$$MonthlyStatImplCopyWith<$Res> {
  __$$MonthlyStatImplCopyWithImpl(
    _$MonthlyStatImpl _value,
    $Res Function(_$MonthlyStatImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonthlyStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? count = null,
    Object? aiCount = null,
    Object? volunteerCount = null,
  }) {
    return _then(
      _$MonthlyStatImpl(
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        aiCount: null == aiCount
            ? _value.aiCount
            : aiCount // ignore: cast_nullable_to_non_nullable
                  as int,
        volunteerCount: null == volunteerCount
            ? _value.volunteerCount
            : volunteerCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlyStatImpl implements _MonthlyStat {
  const _$MonthlyStatImpl({
    required this.month,
    required this.count,
    this.aiCount = 0,
    this.volunteerCount = 0,
  });

  factory _$MonthlyStatImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlyStatImplFromJson(json);

  @override
  final String month;
  @override
  final int count;
  @override
  @JsonKey()
  final int aiCount;
  @override
  @JsonKey()
  final int volunteerCount;

  @override
  String toString() {
    return 'MonthlyStat(month: $month, count: $count, aiCount: $aiCount, volunteerCount: $volunteerCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyStatImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.aiCount, aiCount) || other.aiCount == aiCount) &&
            (identical(other.volunteerCount, volunteerCount) ||
                other.volunteerCount == volunteerCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, month, count, aiCount, volunteerCount);

  /// Create a copy of MonthlyStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyStatImplCopyWith<_$MonthlyStatImpl> get copyWith =>
      __$$MonthlyStatImplCopyWithImpl<_$MonthlyStatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlyStatImplToJson(this);
  }
}

abstract class _MonthlyStat implements MonthlyStat {
  const factory _MonthlyStat({
    required final String month,
    required final int count,
    final int aiCount,
    final int volunteerCount,
  }) = _$MonthlyStatImpl;

  factory _MonthlyStat.fromJson(Map<String, dynamic> json) =
      _$MonthlyStatImpl.fromJson;

  @override
  String get month;
  @override
  int get count;
  @override
  int get aiCount;
  @override
  int get volunteerCount;

  /// Create a copy of MonthlyStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyStatImplCopyWith<_$MonthlyStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
