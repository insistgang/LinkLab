// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_volunteer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FavoriteVolunteerModel _$FavoriteVolunteerModelFromJson(
  Map<String, dynamic> json,
) {
  return _FavoriteVolunteerModel.fromJson(json);
}

/// @nodoc
mixin _$FavoriteVolunteerModel {
  String get id => throw _privateConstructorUsedError;
  String get seekerId => throw _privateConstructorUsedError;
  String get volunteerId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  int get cooperationCount => throw _privateConstructorUsedError;
  double? get averageRating => throw _privateConstructorUsedError;
  DateTime? get lastCooperationAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FavoriteVolunteerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FavoriteVolunteerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FavoriteVolunteerModelCopyWith<FavoriteVolunteerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteVolunteerModelCopyWith<$Res> {
  factory $FavoriteVolunteerModelCopyWith(
    FavoriteVolunteerModel value,
    $Res Function(FavoriteVolunteerModel) then,
  ) = _$FavoriteVolunteerModelCopyWithImpl<$Res, FavoriteVolunteerModel>;
  @useResult
  $Res call({
    String id,
    String seekerId,
    String volunteerId,
    String? name,
    String? avatarUrl,
    int cooperationCount,
    double? averageRating,
    DateTime? lastCooperationAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$FavoriteVolunteerModelCopyWithImpl<
  $Res,
  $Val extends FavoriteVolunteerModel
>
    implements $FavoriteVolunteerModelCopyWith<$Res> {
  _$FavoriteVolunteerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FavoriteVolunteerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seekerId = null,
    Object? volunteerId = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? cooperationCount = null,
    Object? averageRating = freezed,
    Object? lastCooperationAt = freezed,
    Object? createdAt = freezed,
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
            volunteerId: null == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            cooperationCount: null == cooperationCount
                ? _value.cooperationCount
                : cooperationCount // ignore: cast_nullable_to_non_nullable
                      as int,
            averageRating: freezed == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double?,
            lastCooperationAt: freezed == lastCooperationAt
                ? _value.lastCooperationAt
                : lastCooperationAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FavoriteVolunteerModelImplCopyWith<$Res>
    implements $FavoriteVolunteerModelCopyWith<$Res> {
  factory _$$FavoriteVolunteerModelImplCopyWith(
    _$FavoriteVolunteerModelImpl value,
    $Res Function(_$FavoriteVolunteerModelImpl) then,
  ) = __$$FavoriteVolunteerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String seekerId,
    String volunteerId,
    String? name,
    String? avatarUrl,
    int cooperationCount,
    double? averageRating,
    DateTime? lastCooperationAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$FavoriteVolunteerModelImplCopyWithImpl<$Res>
    extends
        _$FavoriteVolunteerModelCopyWithImpl<$Res, _$FavoriteVolunteerModelImpl>
    implements _$$FavoriteVolunteerModelImplCopyWith<$Res> {
  __$$FavoriteVolunteerModelImplCopyWithImpl(
    _$FavoriteVolunteerModelImpl _value,
    $Res Function(_$FavoriteVolunteerModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FavoriteVolunteerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seekerId = null,
    Object? volunteerId = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? cooperationCount = null,
    Object? averageRating = freezed,
    Object? lastCooperationAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$FavoriteVolunteerModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        seekerId: null == seekerId
            ? _value.seekerId
            : seekerId // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteerId: null == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        cooperationCount: null == cooperationCount
            ? _value.cooperationCount
            : cooperationCount // ignore: cast_nullable_to_non_nullable
                  as int,
        averageRating: freezed == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double?,
        lastCooperationAt: freezed == lastCooperationAt
            ? _value.lastCooperationAt
            : lastCooperationAt // ignore: cast_nullable_to_non_nullable
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
class _$FavoriteVolunteerModelImpl extends _FavoriteVolunteerModel {
  const _$FavoriteVolunteerModelImpl({
    required this.id,
    required this.seekerId,
    required this.volunteerId,
    this.name,
    this.avatarUrl,
    this.cooperationCount = 1,
    this.averageRating,
    this.lastCooperationAt,
    this.createdAt,
  }) : super._();

  factory _$FavoriteVolunteerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavoriteVolunteerModelImplFromJson(json);

  @override
  final String id;
  @override
  final String seekerId;
  @override
  final String volunteerId;
  @override
  final String? name;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final int cooperationCount;
  @override
  final double? averageRating;
  @override
  final DateTime? lastCooperationAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'FavoriteVolunteerModel(id: $id, seekerId: $seekerId, volunteerId: $volunteerId, name: $name, avatarUrl: $avatarUrl, cooperationCount: $cooperationCount, averageRating: $averageRating, lastCooperationAt: $lastCooperationAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteVolunteerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seekerId, seekerId) ||
                other.seekerId == seekerId) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.cooperationCount, cooperationCount) ||
                other.cooperationCount == cooperationCount) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.lastCooperationAt, lastCooperationAt) ||
                other.lastCooperationAt == lastCooperationAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    seekerId,
    volunteerId,
    name,
    avatarUrl,
    cooperationCount,
    averageRating,
    lastCooperationAt,
    createdAt,
  );

  /// Create a copy of FavoriteVolunteerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteVolunteerModelImplCopyWith<_$FavoriteVolunteerModelImpl>
  get copyWith =>
      __$$FavoriteVolunteerModelImplCopyWithImpl<_$FavoriteVolunteerModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FavoriteVolunteerModelImplToJson(this);
  }
}

abstract class _FavoriteVolunteerModel extends FavoriteVolunteerModel {
  const factory _FavoriteVolunteerModel({
    required final String id,
    required final String seekerId,
    required final String volunteerId,
    final String? name,
    final String? avatarUrl,
    final int cooperationCount,
    final double? averageRating,
    final DateTime? lastCooperationAt,
    final DateTime? createdAt,
  }) = _$FavoriteVolunteerModelImpl;
  const _FavoriteVolunteerModel._() : super._();

  factory _FavoriteVolunteerModel.fromJson(Map<String, dynamic> json) =
      _$FavoriteVolunteerModelImpl.fromJson;

  @override
  String get id;
  @override
  String get seekerId;
  @override
  String get volunteerId;
  @override
  String? get name;
  @override
  String? get avatarUrl;
  @override
  int get cooperationCount;
  @override
  double? get averageRating;
  @override
  DateTime? get lastCooperationAt;
  @override
  DateTime? get createdAt;

  /// Create a copy of FavoriteVolunteerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FavoriteVolunteerModelImplCopyWith<_$FavoriteVolunteerModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

FavoriteVolunteerStats _$FavoriteVolunteerStatsFromJson(
  Map<String, dynamic> json,
) {
  return _FavoriteVolunteerStats.fromJson(json);
}

/// @nodoc
mixin _$FavoriteVolunteerStats {
  int get totalFavorites => throw _privateConstructorUsedError;
  int get totalCooperations => throw _privateConstructorUsedError;
  String? get mostFrequentVolunteerId => throw _privateConstructorUsedError;
  String? get mostFrequentVolunteerName => throw _privateConstructorUsedError;

  /// Serializes this FavoriteVolunteerStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FavoriteVolunteerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FavoriteVolunteerStatsCopyWith<FavoriteVolunteerStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteVolunteerStatsCopyWith<$Res> {
  factory $FavoriteVolunteerStatsCopyWith(
    FavoriteVolunteerStats value,
    $Res Function(FavoriteVolunteerStats) then,
  ) = _$FavoriteVolunteerStatsCopyWithImpl<$Res, FavoriteVolunteerStats>;
  @useResult
  $Res call({
    int totalFavorites,
    int totalCooperations,
    String? mostFrequentVolunteerId,
    String? mostFrequentVolunteerName,
  });
}

/// @nodoc
class _$FavoriteVolunteerStatsCopyWithImpl<
  $Res,
  $Val extends FavoriteVolunteerStats
>
    implements $FavoriteVolunteerStatsCopyWith<$Res> {
  _$FavoriteVolunteerStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FavoriteVolunteerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalFavorites = null,
    Object? totalCooperations = null,
    Object? mostFrequentVolunteerId = freezed,
    Object? mostFrequentVolunteerName = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalFavorites: null == totalFavorites
                ? _value.totalFavorites
                : totalFavorites // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCooperations: null == totalCooperations
                ? _value.totalCooperations
                : totalCooperations // ignore: cast_nullable_to_non_nullable
                      as int,
            mostFrequentVolunteerId: freezed == mostFrequentVolunteerId
                ? _value.mostFrequentVolunteerId
                : mostFrequentVolunteerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mostFrequentVolunteerName: freezed == mostFrequentVolunteerName
                ? _value.mostFrequentVolunteerName
                : mostFrequentVolunteerName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FavoriteVolunteerStatsImplCopyWith<$Res>
    implements $FavoriteVolunteerStatsCopyWith<$Res> {
  factory _$$FavoriteVolunteerStatsImplCopyWith(
    _$FavoriteVolunteerStatsImpl value,
    $Res Function(_$FavoriteVolunteerStatsImpl) then,
  ) = __$$FavoriteVolunteerStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalFavorites,
    int totalCooperations,
    String? mostFrequentVolunteerId,
    String? mostFrequentVolunteerName,
  });
}

/// @nodoc
class __$$FavoriteVolunteerStatsImplCopyWithImpl<$Res>
    extends
        _$FavoriteVolunteerStatsCopyWithImpl<$Res, _$FavoriteVolunteerStatsImpl>
    implements _$$FavoriteVolunteerStatsImplCopyWith<$Res> {
  __$$FavoriteVolunteerStatsImplCopyWithImpl(
    _$FavoriteVolunteerStatsImpl _value,
    $Res Function(_$FavoriteVolunteerStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FavoriteVolunteerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalFavorites = null,
    Object? totalCooperations = null,
    Object? mostFrequentVolunteerId = freezed,
    Object? mostFrequentVolunteerName = freezed,
  }) {
    return _then(
      _$FavoriteVolunteerStatsImpl(
        totalFavorites: null == totalFavorites
            ? _value.totalFavorites
            : totalFavorites // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCooperations: null == totalCooperations
            ? _value.totalCooperations
            : totalCooperations // ignore: cast_nullable_to_non_nullable
                  as int,
        mostFrequentVolunteerId: freezed == mostFrequentVolunteerId
            ? _value.mostFrequentVolunteerId
            : mostFrequentVolunteerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mostFrequentVolunteerName: freezed == mostFrequentVolunteerName
            ? _value.mostFrequentVolunteerName
            : mostFrequentVolunteerName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FavoriteVolunteerStatsImpl implements _FavoriteVolunteerStats {
  const _$FavoriteVolunteerStatsImpl({
    this.totalFavorites = 0,
    this.totalCooperations = 0,
    this.mostFrequentVolunteerId,
    this.mostFrequentVolunteerName,
  });

  factory _$FavoriteVolunteerStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavoriteVolunteerStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalFavorites;
  @override
  @JsonKey()
  final int totalCooperations;
  @override
  final String? mostFrequentVolunteerId;
  @override
  final String? mostFrequentVolunteerName;

  @override
  String toString() {
    return 'FavoriteVolunteerStats(totalFavorites: $totalFavorites, totalCooperations: $totalCooperations, mostFrequentVolunteerId: $mostFrequentVolunteerId, mostFrequentVolunteerName: $mostFrequentVolunteerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteVolunteerStatsImpl &&
            (identical(other.totalFavorites, totalFavorites) ||
                other.totalFavorites == totalFavorites) &&
            (identical(other.totalCooperations, totalCooperations) ||
                other.totalCooperations == totalCooperations) &&
            (identical(
                  other.mostFrequentVolunteerId,
                  mostFrequentVolunteerId,
                ) ||
                other.mostFrequentVolunteerId == mostFrequentVolunteerId) &&
            (identical(
                  other.mostFrequentVolunteerName,
                  mostFrequentVolunteerName,
                ) ||
                other.mostFrequentVolunteerName == mostFrequentVolunteerName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalFavorites,
    totalCooperations,
    mostFrequentVolunteerId,
    mostFrequentVolunteerName,
  );

  /// Create a copy of FavoriteVolunteerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteVolunteerStatsImplCopyWith<_$FavoriteVolunteerStatsImpl>
  get copyWith =>
      __$$FavoriteVolunteerStatsImplCopyWithImpl<_$FavoriteVolunteerStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FavoriteVolunteerStatsImplToJson(this);
  }
}

abstract class _FavoriteVolunteerStats implements FavoriteVolunteerStats {
  const factory _FavoriteVolunteerStats({
    final int totalFavorites,
    final int totalCooperations,
    final String? mostFrequentVolunteerId,
    final String? mostFrequentVolunteerName,
  }) = _$FavoriteVolunteerStatsImpl;

  factory _FavoriteVolunteerStats.fromJson(Map<String, dynamic> json) =
      _$FavoriteVolunteerStatsImpl.fromJson;

  @override
  int get totalFavorites;
  @override
  int get totalCooperations;
  @override
  String? get mostFrequentVolunteerId;
  @override
  String? get mostFrequentVolunteerName;

  /// Create a copy of FavoriteVolunteerStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FavoriteVolunteerStatsImplCopyWith<_$FavoriteVolunteerStatsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
