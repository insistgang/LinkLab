// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  List<String> get role => throw _privateConstructorUsedError;
  List<String> get disabilityType => throw _privateConstructorUsedError;
  AccessibilityPreferences? get preferences =>
      throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    String id,
    String phone,
    String? name,
    String? avatarUrl,
    List<String> role,
    List<String> disabilityType,
    AccessibilityPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  });

  $AccessibilityPreferencesCopyWith<$Res>? get preferences;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? disabilityType = null,
    Object? preferences = freezed,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            disabilityType: null == disabilityType
                ? _value.disabilityType
                : disabilityType // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            preferences: freezed == preferences
                ? _value.preferences
                : preferences // ignore: cast_nullable_to_non_nullable
                      as AccessibilityPreferences?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastLoginAt: freezed == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccessibilityPreferencesCopyWith<$Res>? get preferences {
    if (_value.preferences == null) {
      return null;
    }

    return $AccessibilityPreferencesCopyWith<$Res>(_value.preferences!, (
      value,
    ) {
      return _then(_value.copyWith(preferences: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String phone,
    String? name,
    String? avatarUrl,
    List<String> role,
    List<String> disabilityType,
    AccessibilityPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  });

  @override
  $AccessibilityPreferencesCopyWith<$Res>? get preferences;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? disabilityType = null,
    Object? preferences = freezed,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value._role
            : role // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        disabilityType: null == disabilityType
            ? _value._disabilityType
            : disabilityType // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        preferences: freezed == preferences
            ? _value.preferences
            : preferences // ignore: cast_nullable_to_non_nullable
                  as AccessibilityPreferences?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastLoginAt: freezed == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
    final List<String> role = const ['seeker'],
    final List<String> disabilityType = const [],
    this.preferences,
    this.createdAt,
    this.lastLoginAt,
  }) : _role = role,
       _disabilityType = disabilityType,
       super._();

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String phone;
  @override
  final String? name;
  @override
  final String? avatarUrl;
  final List<String> _role;
  @override
  @JsonKey()
  List<String> get role {
    if (_role is EqualUnmodifiableListView) return _role;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_role);
  }

  final List<String> _disabilityType;
  @override
  @JsonKey()
  List<String> get disabilityType {
    if (_disabilityType is EqualUnmodifiableListView) return _disabilityType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disabilityType);
  }

  @override
  final AccessibilityPreferences? preferences;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? lastLoginAt;

  @override
  String toString() {
    return 'UserModel(id: $id, phone: $phone, name: $name, avatarUrl: $avatarUrl, role: $role, disabilityType: $disabilityType, preferences: $preferences, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            const DeepCollectionEquality().equals(other._role, _role) &&
            const DeepCollectionEquality().equals(
              other._disabilityType,
              _disabilityType,
            ) &&
            (identical(other.preferences, preferences) ||
                other.preferences == preferences) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    phone,
    name,
    avatarUrl,
    const DeepCollectionEquality().hash(_role),
    const DeepCollectionEquality().hash(_disabilityType),
    preferences,
    createdAt,
    lastLoginAt,
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel extends UserModel {
  const factory _UserModel({
    required final String id,
    required final String phone,
    final String? name,
    final String? avatarUrl,
    final List<String> role,
    final List<String> disabilityType,
    final AccessibilityPreferences? preferences,
    final DateTime? createdAt,
    final DateTime? lastLoginAt,
  }) = _$UserModelImpl;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get phone;
  @override
  String? get name;
  @override
  String? get avatarUrl;
  @override
  List<String> get role;
  @override
  List<String> get disabilityType;
  @override
  AccessibilityPreferences? get preferences;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get lastLoginAt;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccessibilityPreferences _$AccessibilityPreferencesFromJson(
  Map<String, dynamic> json,
) {
  return _AccessibilityPreferences.fromJson(json);
}

/// @nodoc
mixin _$AccessibilityPreferences {
  bool get highContrastMode => throw _privateConstructorUsedError;
  double get fontScale => throw _privateConstructorUsedError;
  double get voiceSpeed => throw _privateConstructorUsedError;
  bool get hapticFeedback => throw _privateConstructorUsedError;
  bool get voiceGuidance => throw _privateConstructorUsedError;
  bool get autoReadResults => throw _privateConstructorUsedError;
  String get voiceGender => throw _privateConstructorUsedError;
  String get voiceAccent => throw _privateConstructorUsedError;

  /// Serializes this AccessibilityPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccessibilityPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccessibilityPreferencesCopyWith<AccessibilityPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccessibilityPreferencesCopyWith<$Res> {
  factory $AccessibilityPreferencesCopyWith(
    AccessibilityPreferences value,
    $Res Function(AccessibilityPreferences) then,
  ) = _$AccessibilityPreferencesCopyWithImpl<$Res, AccessibilityPreferences>;
  @useResult
  $Res call({
    bool highContrastMode,
    double fontScale,
    double voiceSpeed,
    bool hapticFeedback,
    bool voiceGuidance,
    bool autoReadResults,
    String voiceGender,
    String voiceAccent,
  });
}

/// @nodoc
class _$AccessibilityPreferencesCopyWithImpl<
  $Res,
  $Val extends AccessibilityPreferences
>
    implements $AccessibilityPreferencesCopyWith<$Res> {
  _$AccessibilityPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccessibilityPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? highContrastMode = null,
    Object? fontScale = null,
    Object? voiceSpeed = null,
    Object? hapticFeedback = null,
    Object? voiceGuidance = null,
    Object? autoReadResults = null,
    Object? voiceGender = null,
    Object? voiceAccent = null,
  }) {
    return _then(
      _value.copyWith(
            highContrastMode: null == highContrastMode
                ? _value.highContrastMode
                : highContrastMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            fontScale: null == fontScale
                ? _value.fontScale
                : fontScale // ignore: cast_nullable_to_non_nullable
                      as double,
            voiceSpeed: null == voiceSpeed
                ? _value.voiceSpeed
                : voiceSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
            hapticFeedback: null == hapticFeedback
                ? _value.hapticFeedback
                : hapticFeedback // ignore: cast_nullable_to_non_nullable
                      as bool,
            voiceGuidance: null == voiceGuidance
                ? _value.voiceGuidance
                : voiceGuidance // ignore: cast_nullable_to_non_nullable
                      as bool,
            autoReadResults: null == autoReadResults
                ? _value.autoReadResults
                : autoReadResults // ignore: cast_nullable_to_non_nullable
                      as bool,
            voiceGender: null == voiceGender
                ? _value.voiceGender
                : voiceGender // ignore: cast_nullable_to_non_nullable
                      as String,
            voiceAccent: null == voiceAccent
                ? _value.voiceAccent
                : voiceAccent // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccessibilityPreferencesImplCopyWith<$Res>
    implements $AccessibilityPreferencesCopyWith<$Res> {
  factory _$$AccessibilityPreferencesImplCopyWith(
    _$AccessibilityPreferencesImpl value,
    $Res Function(_$AccessibilityPreferencesImpl) then,
  ) = __$$AccessibilityPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool highContrastMode,
    double fontScale,
    double voiceSpeed,
    bool hapticFeedback,
    bool voiceGuidance,
    bool autoReadResults,
    String voiceGender,
    String voiceAccent,
  });
}

/// @nodoc
class __$$AccessibilityPreferencesImplCopyWithImpl<$Res>
    extends
        _$AccessibilityPreferencesCopyWithImpl<
          $Res,
          _$AccessibilityPreferencesImpl
        >
    implements _$$AccessibilityPreferencesImplCopyWith<$Res> {
  __$$AccessibilityPreferencesImplCopyWithImpl(
    _$AccessibilityPreferencesImpl _value,
    $Res Function(_$AccessibilityPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccessibilityPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? highContrastMode = null,
    Object? fontScale = null,
    Object? voiceSpeed = null,
    Object? hapticFeedback = null,
    Object? voiceGuidance = null,
    Object? autoReadResults = null,
    Object? voiceGender = null,
    Object? voiceAccent = null,
  }) {
    return _then(
      _$AccessibilityPreferencesImpl(
        highContrastMode: null == highContrastMode
            ? _value.highContrastMode
            : highContrastMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        fontScale: null == fontScale
            ? _value.fontScale
            : fontScale // ignore: cast_nullable_to_non_nullable
                  as double,
        voiceSpeed: null == voiceSpeed
            ? _value.voiceSpeed
            : voiceSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
        hapticFeedback: null == hapticFeedback
            ? _value.hapticFeedback
            : hapticFeedback // ignore: cast_nullable_to_non_nullable
                  as bool,
        voiceGuidance: null == voiceGuidance
            ? _value.voiceGuidance
            : voiceGuidance // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoReadResults: null == autoReadResults
            ? _value.autoReadResults
            : autoReadResults // ignore: cast_nullable_to_non_nullable
                  as bool,
        voiceGender: null == voiceGender
            ? _value.voiceGender
            : voiceGender // ignore: cast_nullable_to_non_nullable
                  as String,
        voiceAccent: null == voiceAccent
            ? _value.voiceAccent
            : voiceAccent // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccessibilityPreferencesImpl implements _AccessibilityPreferences {
  const _$AccessibilityPreferencesImpl({
    this.highContrastMode = false,
    this.fontScale = 1.0,
    this.voiceSpeed = 1.0,
    this.hapticFeedback = true,
    this.voiceGuidance = true,
    this.autoReadResults = true,
    this.voiceGender = 'female',
    this.voiceAccent = 'standard',
  });

  factory _$AccessibilityPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccessibilityPreferencesImplFromJson(json);

  @override
  @JsonKey()
  final bool highContrastMode;
  @override
  @JsonKey()
  final double fontScale;
  @override
  @JsonKey()
  final double voiceSpeed;
  @override
  @JsonKey()
  final bool hapticFeedback;
  @override
  @JsonKey()
  final bool voiceGuidance;
  @override
  @JsonKey()
  final bool autoReadResults;
  @override
  @JsonKey()
  final String voiceGender;
  @override
  @JsonKey()
  final String voiceAccent;

  @override
  String toString() {
    return 'AccessibilityPreferences(highContrastMode: $highContrastMode, fontScale: $fontScale, voiceSpeed: $voiceSpeed, hapticFeedback: $hapticFeedback, voiceGuidance: $voiceGuidance, autoReadResults: $autoReadResults, voiceGender: $voiceGender, voiceAccent: $voiceAccent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccessibilityPreferencesImpl &&
            (identical(other.highContrastMode, highContrastMode) ||
                other.highContrastMode == highContrastMode) &&
            (identical(other.fontScale, fontScale) ||
                other.fontScale == fontScale) &&
            (identical(other.voiceSpeed, voiceSpeed) ||
                other.voiceSpeed == voiceSpeed) &&
            (identical(other.hapticFeedback, hapticFeedback) ||
                other.hapticFeedback == hapticFeedback) &&
            (identical(other.voiceGuidance, voiceGuidance) ||
                other.voiceGuidance == voiceGuidance) &&
            (identical(other.autoReadResults, autoReadResults) ||
                other.autoReadResults == autoReadResults) &&
            (identical(other.voiceGender, voiceGender) ||
                other.voiceGender == voiceGender) &&
            (identical(other.voiceAccent, voiceAccent) ||
                other.voiceAccent == voiceAccent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    highContrastMode,
    fontScale,
    voiceSpeed,
    hapticFeedback,
    voiceGuidance,
    autoReadResults,
    voiceGender,
    voiceAccent,
  );

  /// Create a copy of AccessibilityPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccessibilityPreferencesImplCopyWith<_$AccessibilityPreferencesImpl>
  get copyWith =>
      __$$AccessibilityPreferencesImplCopyWithImpl<
        _$AccessibilityPreferencesImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccessibilityPreferencesImplToJson(this);
  }
}

abstract class _AccessibilityPreferences implements AccessibilityPreferences {
  const factory _AccessibilityPreferences({
    final bool highContrastMode,
    final double fontScale,
    final double voiceSpeed,
    final bool hapticFeedback,
    final bool voiceGuidance,
    final bool autoReadResults,
    final String voiceGender,
    final String voiceAccent,
  }) = _$AccessibilityPreferencesImpl;

  factory _AccessibilityPreferences.fromJson(Map<String, dynamic> json) =
      _$AccessibilityPreferencesImpl.fromJson;

  @override
  bool get highContrastMode;
  @override
  double get fontScale;
  @override
  double get voiceSpeed;
  @override
  bool get hapticFeedback;
  @override
  bool get voiceGuidance;
  @override
  bool get autoReadResults;
  @override
  String get voiceGender;
  @override
  String get voiceAccent;

  /// Create a copy of AccessibilityPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccessibilityPreferencesImplCopyWith<_$AccessibilityPreferencesImpl>
  get copyWith => throw _privateConstructorUsedError;
}

VolunteerProfile _$VolunteerProfileFromJson(Map<String, dynamic> json) {
  return _VolunteerProfile.fromJson(json);
}

/// @nodoc
mixin _$VolunteerProfile {
  String get userId => throw _privateConstructorUsedError;
  List<String> get skills => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  double get creditScore => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastHeartbeatAt => throw _privateConstructorUsedError;
  int? get totalHelpCount => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;

  /// Serializes this VolunteerProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolunteerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolunteerProfileCopyWith<VolunteerProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolunteerProfileCopyWith<$Res> {
  factory $VolunteerProfileCopyWith(
    VolunteerProfile value,
    $Res Function(VolunteerProfile) then,
  ) = _$VolunteerProfileCopyWithImpl<$Res, VolunteerProfile>;
  @useResult
  $Res call({
    String userId,
    List<String> skills,
    int level,
    int points,
    double creditScore,
    bool isVerified,
    bool isOnline,
    DateTime? lastHeartbeatAt,
    int? totalHelpCount,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class _$VolunteerProfileCopyWithImpl<$Res, $Val extends VolunteerProfile>
    implements $VolunteerProfileCopyWith<$Res> {
  _$VolunteerProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolunteerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? skills = null,
    Object? level = null,
    Object? points = null,
    Object? creditScore = null,
    Object? isVerified = null,
    Object? isOnline = null,
    Object? lastHeartbeatAt = freezed,
    Object? totalHelpCount = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            skills: null == skills
                ? _value.skills
                : skills // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            creditScore: null == creditScore
                ? _value.creditScore
                : creditScore // ignore: cast_nullable_to_non_nullable
                      as double,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            isOnline: null == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastHeartbeatAt: freezed == lastHeartbeatAt
                ? _value.lastHeartbeatAt
                : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalHelpCount: freezed == totalHelpCount
                ? _value.totalHelpCount
                : totalHelpCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VolunteerProfileImplCopyWith<$Res>
    implements $VolunteerProfileCopyWith<$Res> {
  factory _$$VolunteerProfileImplCopyWith(
    _$VolunteerProfileImpl value,
    $Res Function(_$VolunteerProfileImpl) then,
  ) = __$$VolunteerProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    List<String> skills,
    int level,
    int points,
    double creditScore,
    bool isVerified,
    bool isOnline,
    DateTime? lastHeartbeatAt,
    int? totalHelpCount,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class __$$VolunteerProfileImplCopyWithImpl<$Res>
    extends _$VolunteerProfileCopyWithImpl<$Res, _$VolunteerProfileImpl>
    implements _$$VolunteerProfileImplCopyWith<$Res> {
  __$$VolunteerProfileImplCopyWithImpl(
    _$VolunteerProfileImpl _value,
    $Res Function(_$VolunteerProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VolunteerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? skills = null,
    Object? level = null,
    Object? points = null,
    Object? creditScore = null,
    Object? isVerified = null,
    Object? isOnline = null,
    Object? lastHeartbeatAt = freezed,
    Object? totalHelpCount = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _$VolunteerProfileImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        skills: null == skills
            ? _value._skills
            : skills // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        creditScore: null == creditScore
            ? _value.creditScore
            : creditScore // ignore: cast_nullable_to_non_nullable
                  as double,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        isOnline: null == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastHeartbeatAt: freezed == lastHeartbeatAt
            ? _value.lastHeartbeatAt
            : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalHelpCount: freezed == totalHelpCount
            ? _value.totalHelpCount
            : totalHelpCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VolunteerProfileImpl extends _VolunteerProfile {
  const _$VolunteerProfileImpl({
    required this.userId,
    final List<String> skills = const [],
    this.level = 1,
    this.points = 0,
    this.creditScore = 5.0,
    this.isVerified = false,
    this.isOnline = false,
    this.lastHeartbeatAt,
    this.totalHelpCount,
    this.latitude,
    this.longitude,
  }) : _skills = skills,
       super._();

  factory _$VolunteerProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolunteerProfileImplFromJson(json);

  @override
  final String userId;
  final List<String> _skills;
  @override
  @JsonKey()
  List<String> get skills {
    if (_skills is EqualUnmodifiableListView) return _skills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skills);
  }

  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final double creditScore;
  @override
  @JsonKey()
  final bool isVerified;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  final DateTime? lastHeartbeatAt;
  @override
  final int? totalHelpCount;
  @override
  final double? latitude;
  @override
  final double? longitude;

  @override
  String toString() {
    return 'VolunteerProfile(userId: $userId, skills: $skills, level: $level, points: $points, creditScore: $creditScore, isVerified: $isVerified, isOnline: $isOnline, lastHeartbeatAt: $lastHeartbeatAt, totalHelpCount: $totalHelpCount, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolunteerProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._skills, _skills) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.creditScore, creditScore) ||
                other.creditScore == creditScore) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastHeartbeatAt, lastHeartbeatAt) ||
                other.lastHeartbeatAt == lastHeartbeatAt) &&
            (identical(other.totalHelpCount, totalHelpCount) ||
                other.totalHelpCount == totalHelpCount) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    const DeepCollectionEquality().hash(_skills),
    level,
    points,
    creditScore,
    isVerified,
    isOnline,
    lastHeartbeatAt,
    totalHelpCount,
    latitude,
    longitude,
  );

  /// Create a copy of VolunteerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolunteerProfileImplCopyWith<_$VolunteerProfileImpl> get copyWith =>
      __$$VolunteerProfileImplCopyWithImpl<_$VolunteerProfileImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VolunteerProfileImplToJson(this);
  }
}

abstract class _VolunteerProfile extends VolunteerProfile {
  const factory _VolunteerProfile({
    required final String userId,
    final List<String> skills,
    final int level,
    final int points,
    final double creditScore,
    final bool isVerified,
    final bool isOnline,
    final DateTime? lastHeartbeatAt,
    final int? totalHelpCount,
    final double? latitude,
    final double? longitude,
  }) = _$VolunteerProfileImpl;
  const _VolunteerProfile._() : super._();

  factory _VolunteerProfile.fromJson(Map<String, dynamic> json) =
      _$VolunteerProfileImpl.fromJson;

  @override
  String get userId;
  @override
  List<String> get skills;
  @override
  int get level;
  @override
  int get points;
  @override
  double get creditScore;
  @override
  bool get isVerified;
  @override
  bool get isOnline;
  @override
  DateTime? get lastHeartbeatAt;
  @override
  int? get totalHelpCount;
  @override
  double? get latitude;
  @override
  double? get longitude;

  /// Create a copy of VolunteerProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolunteerProfileImplCopyWith<_$VolunteerProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
