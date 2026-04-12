// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'volunteer_level_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VolunteerLevelInfo _$VolunteerLevelInfoFromJson(Map<String, dynamic> json) {
  return _VolunteerLevelInfo.fromJson(json);
}

/// @nodoc
mixin _$VolunteerLevelInfo {
  int get currentLevel => throw _privateConstructorUsedError;
  int get currentPoints => throw _privateConstructorUsedError;
  int get pointsToNextLevel => throw _privateConstructorUsedError;
  double get progressPercent => throw _privateConstructorUsedError;
  LevelDefinition? get nextLevel => throw _privateConstructorUsedError;
  List<LevelDefinition> get allLevels => throw _privateConstructorUsedError;

  /// Serializes this VolunteerLevelInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolunteerLevelInfoCopyWith<VolunteerLevelInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolunteerLevelInfoCopyWith<$Res> {
  factory $VolunteerLevelInfoCopyWith(
    VolunteerLevelInfo value,
    $Res Function(VolunteerLevelInfo) then,
  ) = _$VolunteerLevelInfoCopyWithImpl<$Res, VolunteerLevelInfo>;
  @useResult
  $Res call({
    int currentLevel,
    int currentPoints,
    int pointsToNextLevel,
    double progressPercent,
    LevelDefinition? nextLevel,
    List<LevelDefinition> allLevels,
  });

  $LevelDefinitionCopyWith<$Res>? get nextLevel;
}

/// @nodoc
class _$VolunteerLevelInfoCopyWithImpl<$Res, $Val extends VolunteerLevelInfo>
    implements $VolunteerLevelInfoCopyWith<$Res> {
  _$VolunteerLevelInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentLevel = null,
    Object? currentPoints = null,
    Object? pointsToNextLevel = null,
    Object? progressPercent = null,
    Object? nextLevel = freezed,
    Object? allLevels = null,
  }) {
    return _then(
      _value.copyWith(
            currentLevel: null == currentLevel
                ? _value.currentLevel
                : currentLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPoints: null == currentPoints
                ? _value.currentPoints
                : currentPoints // ignore: cast_nullable_to_non_nullable
                      as int,
            pointsToNextLevel: null == pointsToNextLevel
                ? _value.pointsToNextLevel
                : pointsToNextLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            progressPercent: null == progressPercent
                ? _value.progressPercent
                : progressPercent // ignore: cast_nullable_to_non_nullable
                      as double,
            nextLevel: freezed == nextLevel
                ? _value.nextLevel
                : nextLevel // ignore: cast_nullable_to_non_nullable
                      as LevelDefinition?,
            allLevels: null == allLevels
                ? _value.allLevels
                : allLevels // ignore: cast_nullable_to_non_nullable
                      as List<LevelDefinition>,
          )
          as $Val,
    );
  }

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LevelDefinitionCopyWith<$Res>? get nextLevel {
    if (_value.nextLevel == null) {
      return null;
    }

    return $LevelDefinitionCopyWith<$Res>(_value.nextLevel!, (value) {
      return _then(_value.copyWith(nextLevel: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VolunteerLevelInfoImplCopyWith<$Res>
    implements $VolunteerLevelInfoCopyWith<$Res> {
  factory _$$VolunteerLevelInfoImplCopyWith(
    _$VolunteerLevelInfoImpl value,
    $Res Function(_$VolunteerLevelInfoImpl) then,
  ) = __$$VolunteerLevelInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int currentLevel,
    int currentPoints,
    int pointsToNextLevel,
    double progressPercent,
    LevelDefinition? nextLevel,
    List<LevelDefinition> allLevels,
  });

  @override
  $LevelDefinitionCopyWith<$Res>? get nextLevel;
}

/// @nodoc
class __$$VolunteerLevelInfoImplCopyWithImpl<$Res>
    extends _$VolunteerLevelInfoCopyWithImpl<$Res, _$VolunteerLevelInfoImpl>
    implements _$$VolunteerLevelInfoImplCopyWith<$Res> {
  __$$VolunteerLevelInfoImplCopyWithImpl(
    _$VolunteerLevelInfoImpl _value,
    $Res Function(_$VolunteerLevelInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentLevel = null,
    Object? currentPoints = null,
    Object? pointsToNextLevel = null,
    Object? progressPercent = null,
    Object? nextLevel = freezed,
    Object? allLevels = null,
  }) {
    return _then(
      _$VolunteerLevelInfoImpl(
        currentLevel: null == currentLevel
            ? _value.currentLevel
            : currentLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPoints: null == currentPoints
            ? _value.currentPoints
            : currentPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        pointsToNextLevel: null == pointsToNextLevel
            ? _value.pointsToNextLevel
            : pointsToNextLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        progressPercent: null == progressPercent
            ? _value.progressPercent
            : progressPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        nextLevel: freezed == nextLevel
            ? _value.nextLevel
            : nextLevel // ignore: cast_nullable_to_non_nullable
                  as LevelDefinition?,
        allLevels: null == allLevels
            ? _value._allLevels
            : allLevels // ignore: cast_nullable_to_non_nullable
                  as List<LevelDefinition>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VolunteerLevelInfoImpl extends _VolunteerLevelInfo {
  const _$VolunteerLevelInfoImpl({
    required this.currentLevel,
    required this.currentPoints,
    required this.pointsToNextLevel,
    required this.progressPercent,
    this.nextLevel,
    final List<LevelDefinition> allLevels = const [],
  }) : _allLevels = allLevels,
       super._();

  factory _$VolunteerLevelInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolunteerLevelInfoImplFromJson(json);

  @override
  final int currentLevel;
  @override
  final int currentPoints;
  @override
  final int pointsToNextLevel;
  @override
  final double progressPercent;
  @override
  final LevelDefinition? nextLevel;
  final List<LevelDefinition> _allLevels;
  @override
  @JsonKey()
  List<LevelDefinition> get allLevels {
    if (_allLevels is EqualUnmodifiableListView) return _allLevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allLevels);
  }

  @override
  String toString() {
    return 'VolunteerLevelInfo(currentLevel: $currentLevel, currentPoints: $currentPoints, pointsToNextLevel: $pointsToNextLevel, progressPercent: $progressPercent, nextLevel: $nextLevel, allLevels: $allLevels)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolunteerLevelInfoImpl &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel) &&
            (identical(other.currentPoints, currentPoints) ||
                other.currentPoints == currentPoints) &&
            (identical(other.pointsToNextLevel, pointsToNextLevel) ||
                other.pointsToNextLevel == pointsToNextLevel) &&
            (identical(other.progressPercent, progressPercent) ||
                other.progressPercent == progressPercent) &&
            (identical(other.nextLevel, nextLevel) ||
                other.nextLevel == nextLevel) &&
            const DeepCollectionEquality().equals(
              other._allLevels,
              _allLevels,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentLevel,
    currentPoints,
    pointsToNextLevel,
    progressPercent,
    nextLevel,
    const DeepCollectionEquality().hash(_allLevels),
  );

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolunteerLevelInfoImplCopyWith<_$VolunteerLevelInfoImpl> get copyWith =>
      __$$VolunteerLevelInfoImplCopyWithImpl<_$VolunteerLevelInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VolunteerLevelInfoImplToJson(this);
  }
}

abstract class _VolunteerLevelInfo extends VolunteerLevelInfo {
  const factory _VolunteerLevelInfo({
    required final int currentLevel,
    required final int currentPoints,
    required final int pointsToNextLevel,
    required final double progressPercent,
    final LevelDefinition? nextLevel,
    final List<LevelDefinition> allLevels,
  }) = _$VolunteerLevelInfoImpl;
  const _VolunteerLevelInfo._() : super._();

  factory _VolunteerLevelInfo.fromJson(Map<String, dynamic> json) =
      _$VolunteerLevelInfoImpl.fromJson;

  @override
  int get currentLevel;
  @override
  int get currentPoints;
  @override
  int get pointsToNextLevel;
  @override
  double get progressPercent;
  @override
  LevelDefinition? get nextLevel;
  @override
  List<LevelDefinition> get allLevels;

  /// Create a copy of VolunteerLevelInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolunteerLevelInfoImplCopyWith<_$VolunteerLevelInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LevelDefinition _$LevelDefinitionFromJson(Map<String, dynamic> json) {
  return _LevelDefinition.fromJson(json);
}

/// @nodoc
mixin _$LevelDefinition {
  int get level => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  int get minPoints => throw _privateConstructorUsedError;
  int get maxPoints => throw _privateConstructorUsedError;
  List<String> get privileges => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this LevelDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LevelDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LevelDefinitionCopyWith<LevelDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelDefinitionCopyWith<$Res> {
  factory $LevelDefinitionCopyWith(
    LevelDefinition value,
    $Res Function(LevelDefinition) then,
  ) = _$LevelDefinitionCopyWithImpl<$Res, LevelDefinition>;
  @useResult
  $Res call({
    int level,
    String name,
    String emoji,
    int minPoints,
    int maxPoints,
    List<String> privileges,
    String? description,
  });
}

/// @nodoc
class _$LevelDefinitionCopyWithImpl<$Res, $Val extends LevelDefinition>
    implements $LevelDefinitionCopyWith<$Res> {
  _$LevelDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LevelDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? name = null,
    Object? emoji = null,
    Object? minPoints = null,
    Object? maxPoints = null,
    Object? privileges = null,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            emoji: null == emoji
                ? _value.emoji
                : emoji // ignore: cast_nullable_to_non_nullable
                      as String,
            minPoints: null == minPoints
                ? _value.minPoints
                : minPoints // ignore: cast_nullable_to_non_nullable
                      as int,
            maxPoints: null == maxPoints
                ? _value.maxPoints
                : maxPoints // ignore: cast_nullable_to_non_nullable
                      as int,
            privileges: null == privileges
                ? _value.privileges
                : privileges // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LevelDefinitionImplCopyWith<$Res>
    implements $LevelDefinitionCopyWith<$Res> {
  factory _$$LevelDefinitionImplCopyWith(
    _$LevelDefinitionImpl value,
    $Res Function(_$LevelDefinitionImpl) then,
  ) = __$$LevelDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int level,
    String name,
    String emoji,
    int minPoints,
    int maxPoints,
    List<String> privileges,
    String? description,
  });
}

/// @nodoc
class __$$LevelDefinitionImplCopyWithImpl<$Res>
    extends _$LevelDefinitionCopyWithImpl<$Res, _$LevelDefinitionImpl>
    implements _$$LevelDefinitionImplCopyWith<$Res> {
  __$$LevelDefinitionImplCopyWithImpl(
    _$LevelDefinitionImpl _value,
    $Res Function(_$LevelDefinitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LevelDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? name = null,
    Object? emoji = null,
    Object? minPoints = null,
    Object? maxPoints = null,
    Object? privileges = null,
    Object? description = freezed,
  }) {
    return _then(
      _$LevelDefinitionImpl(
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        emoji: null == emoji
            ? _value.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        minPoints: null == minPoints
            ? _value.minPoints
            : minPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        maxPoints: null == maxPoints
            ? _value.maxPoints
            : maxPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        privileges: null == privileges
            ? _value._privileges
            : privileges // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelDefinitionImpl implements _LevelDefinition {
  const _$LevelDefinitionImpl({
    required this.level,
    required this.name,
    required this.emoji,
    required this.minPoints,
    required this.maxPoints,
    final List<String> privileges = const [],
    this.description,
  }) : _privileges = privileges;

  factory _$LevelDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelDefinitionImplFromJson(json);

  @override
  final int level;
  @override
  final String name;
  @override
  final String emoji;
  @override
  final int minPoints;
  @override
  final int maxPoints;
  final List<String> _privileges;
  @override
  @JsonKey()
  List<String> get privileges {
    if (_privileges is EqualUnmodifiableListView) return _privileges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_privileges);
  }

  @override
  final String? description;

  @override
  String toString() {
    return 'LevelDefinition(level: $level, name: $name, emoji: $emoji, minPoints: $minPoints, maxPoints: $maxPoints, privileges: $privileges, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelDefinitionImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.minPoints, minPoints) ||
                other.minPoints == minPoints) &&
            (identical(other.maxPoints, maxPoints) ||
                other.maxPoints == maxPoints) &&
            const DeepCollectionEquality().equals(
              other._privileges,
              _privileges,
            ) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    level,
    name,
    emoji,
    minPoints,
    maxPoints,
    const DeepCollectionEquality().hash(_privileges),
    description,
  );

  /// Create a copy of LevelDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelDefinitionImplCopyWith<_$LevelDefinitionImpl> get copyWith =>
      __$$LevelDefinitionImplCopyWithImpl<_$LevelDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelDefinitionImplToJson(this);
  }
}

abstract class _LevelDefinition implements LevelDefinition {
  const factory _LevelDefinition({
    required final int level,
    required final String name,
    required final String emoji,
    required final int minPoints,
    required final int maxPoints,
    final List<String> privileges,
    final String? description,
  }) = _$LevelDefinitionImpl;

  factory _LevelDefinition.fromJson(Map<String, dynamic> json) =
      _$LevelDefinitionImpl.fromJson;

  @override
  int get level;
  @override
  String get name;
  @override
  String get emoji;
  @override
  int get minPoints;
  @override
  int get maxPoints;
  @override
  List<String> get privileges;
  @override
  String? get description;

  /// Create a copy of LevelDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LevelDefinitionImplCopyWith<_$LevelDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
