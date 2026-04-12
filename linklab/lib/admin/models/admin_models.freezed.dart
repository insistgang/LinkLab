// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) {
  return _AdminUser.fromJson(json);
}

/// @nodoc
mixin _$AdminUser {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get role =>
      throw _privateConstructorUsedError; // 'super_admin', 'admin', 'operator', 'viewer'
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  List<String>? get permissions => throw _privateConstructorUsedError;

  /// Serializes this AdminUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminUserCopyWith<AdminUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminUserCopyWith<$Res> {
  factory $AdminUserCopyWith(AdminUser value, $Res Function(AdminUser) then) =
      _$AdminUserCopyWithImpl<$Res, AdminUser>;
  @useResult
  $Res call({
    String id,
    String username,
    String email,
    String role,
    bool isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    List<String>? permissions,
  });
}

/// @nodoc
class _$AdminUserCopyWithImpl<$Res, $Val extends AdminUser>
    implements $AdminUserCopyWith<$Res> {
  _$AdminUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? role = null,
    Object? isActive = null,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
    Object? permissions = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastLoginAt: freezed == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            permissions: freezed == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AdminUserImplCopyWith<$Res>
    implements $AdminUserCopyWith<$Res> {
  factory _$$AdminUserImplCopyWith(
    _$AdminUserImpl value,
    $Res Function(_$AdminUserImpl) then,
  ) = __$$AdminUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String username,
    String email,
    String role,
    bool isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    List<String>? permissions,
  });
}

/// @nodoc
class __$$AdminUserImplCopyWithImpl<$Res>
    extends _$AdminUserCopyWithImpl<$Res, _$AdminUserImpl>
    implements _$$AdminUserImplCopyWith<$Res> {
  __$$AdminUserImplCopyWithImpl(
    _$AdminUserImpl _value,
    $Res Function(_$AdminUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? role = null,
    Object? isActive = null,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
    Object? permissions = freezed,
  }) {
    return _then(
      _$AdminUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastLoginAt: freezed == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        permissions: freezed == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminUserImpl implements _AdminUser {
  const _$AdminUserImpl({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt,
    final List<String>? permissions,
  }) : _permissions = permissions;

  factory _$AdminUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminUserImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  final String email;
  @override
  final String role;
  // 'super_admin', 'admin', 'operator', 'viewer'
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? lastLoginAt;
  @override
  final DateTime? createdAt;
  final List<String>? _permissions;
  @override
  List<String>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, username: $username, email: $email, role: $role, isActive: $isActive, lastLoginAt: $lastLoginAt, createdAt: $createdAt, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    username,
    email,
    role,
    isActive,
    lastLoginAt,
    createdAt,
    const DeepCollectionEquality().hash(_permissions),
  );

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      __$$AdminUserImplCopyWithImpl<_$AdminUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminUserImplToJson(this);
  }
}

abstract class _AdminUser implements AdminUser {
  const factory _AdminUser({
    required final String id,
    required final String username,
    required final String email,
    required final String role,
    final bool isActive,
    final DateTime? lastLoginAt,
    final DateTime? createdAt,
    final List<String>? permissions,
  }) = _$AdminUserImpl;

  factory _AdminUser.fromJson(Map<String, dynamic> json) =
      _$AdminUserImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  String get email;
  @override
  String get role; // 'super_admin', 'admin', 'operator', 'viewer'
  @override
  bool get isActive;
  @override
  DateTime? get lastLoginAt;
  @override
  DateTime? get createdAt;
  @override
  List<String>? get permissions;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserListItem _$UserListItemFromJson(Map<String, dynamic> json) {
  return _UserListItem.fromJson(json);
}

/// @nodoc
mixin _$UserListItem {
  String get id => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  List<String> get disabilityTypes => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'active', 'banned', 'pending_verification'
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;
  int get helpRequestCount => throw _privateConstructorUsedError;
  int get volunteerCount => throw _privateConstructorUsedError;
  bool? get isDisabilityVerified => throw _privateConstructorUsedError;
  bool? get isVolunteerVerified => throw _privateConstructorUsedError;

  /// Serializes this UserListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserListItemCopyWith<UserListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserListItemCopyWith<$Res> {
  factory $UserListItemCopyWith(
    UserListItem value,
    $Res Function(UserListItem) then,
  ) = _$UserListItemCopyWithImpl<$Res, UserListItem>;
  @useResult
  $Res call({
    String id,
    String phone,
    String? name,
    String? avatarUrl,
    List<String> roles,
    List<String> disabilityTypes,
    String status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int helpRequestCount,
    int volunteerCount,
    bool? isDisabilityVerified,
    bool? isVolunteerVerified,
  });
}

/// @nodoc
class _$UserListItemCopyWithImpl<$Res, $Val extends UserListItem>
    implements $UserListItemCopyWith<$Res> {
  _$UserListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? roles = null,
    Object? disabilityTypes = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
    Object? helpRequestCount = null,
    Object? volunteerCount = null,
    Object? isDisabilityVerified = freezed,
    Object? isVolunteerVerified = freezed,
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
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            disabilityTypes: null == disabilityTypes
                ? _value.disabilityTypes
                : disabilityTypes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastLoginAt: freezed == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            helpRequestCount: null == helpRequestCount
                ? _value.helpRequestCount
                : helpRequestCount // ignore: cast_nullable_to_non_nullable
                      as int,
            volunteerCount: null == volunteerCount
                ? _value.volunteerCount
                : volunteerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isDisabilityVerified: freezed == isDisabilityVerified
                ? _value.isDisabilityVerified
                : isDisabilityVerified // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isVolunteerVerified: freezed == isVolunteerVerified
                ? _value.isVolunteerVerified
                : isVolunteerVerified // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserListItemImplCopyWith<$Res>
    implements $UserListItemCopyWith<$Res> {
  factory _$$UserListItemImplCopyWith(
    _$UserListItemImpl value,
    $Res Function(_$UserListItemImpl) then,
  ) = __$$UserListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String phone,
    String? name,
    String? avatarUrl,
    List<String> roles,
    List<String> disabilityTypes,
    String status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int helpRequestCount,
    int volunteerCount,
    bool? isDisabilityVerified,
    bool? isVolunteerVerified,
  });
}

/// @nodoc
class __$$UserListItemImplCopyWithImpl<$Res>
    extends _$UserListItemCopyWithImpl<$Res, _$UserListItemImpl>
    implements _$$UserListItemImplCopyWith<$Res> {
  __$$UserListItemImplCopyWithImpl(
    _$UserListItemImpl _value,
    $Res Function(_$UserListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? name = freezed,
    Object? avatarUrl = freezed,
    Object? roles = null,
    Object? disabilityTypes = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
    Object? helpRequestCount = null,
    Object? volunteerCount = null,
    Object? isDisabilityVerified = freezed,
    Object? isVolunteerVerified = freezed,
  }) {
    return _then(
      _$UserListItemImpl(
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
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        disabilityTypes: null == disabilityTypes
            ? _value._disabilityTypes
            : disabilityTypes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastLoginAt: freezed == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        helpRequestCount: null == helpRequestCount
            ? _value.helpRequestCount
            : helpRequestCount // ignore: cast_nullable_to_non_nullable
                  as int,
        volunteerCount: null == volunteerCount
            ? _value.volunteerCount
            : volunteerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isDisabilityVerified: freezed == isDisabilityVerified
            ? _value.isDisabilityVerified
            : isDisabilityVerified // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isVolunteerVerified: freezed == isVolunteerVerified
            ? _value.isVolunteerVerified
            : isVolunteerVerified // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserListItemImpl implements _UserListItem {
  const _$UserListItemImpl({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
    required final List<String> roles,
    required final List<String> disabilityTypes,
    this.status = 'active',
    this.createdAt,
    this.lastLoginAt,
    this.helpRequestCount = 0,
    this.volunteerCount = 0,
    this.isDisabilityVerified,
    this.isVolunteerVerified,
  }) : _roles = roles,
       _disabilityTypes = disabilityTypes;

  factory _$UserListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserListItemImplFromJson(json);

  @override
  final String id;
  @override
  final String phone;
  @override
  final String? name;
  @override
  final String? avatarUrl;
  final List<String> _roles;
  @override
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  final List<String> _disabilityTypes;
  @override
  List<String> get disabilityTypes {
    if (_disabilityTypes is EqualUnmodifiableListView) return _disabilityTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disabilityTypes);
  }

  @override
  @JsonKey()
  final String status;
  // 'active', 'banned', 'pending_verification'
  @override
  final DateTime? createdAt;
  @override
  final DateTime? lastLoginAt;
  @override
  @JsonKey()
  final int helpRequestCount;
  @override
  @JsonKey()
  final int volunteerCount;
  @override
  final bool? isDisabilityVerified;
  @override
  final bool? isVolunteerVerified;

  @override
  String toString() {
    return 'UserListItem(id: $id, phone: $phone, name: $name, avatarUrl: $avatarUrl, roles: $roles, disabilityTypes: $disabilityTypes, status: $status, createdAt: $createdAt, lastLoginAt: $lastLoginAt, helpRequestCount: $helpRequestCount, volunteerCount: $volunteerCount, isDisabilityVerified: $isDisabilityVerified, isVolunteerVerified: $isVolunteerVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserListItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            const DeepCollectionEquality().equals(
              other._disabilityTypes,
              _disabilityTypes,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.helpRequestCount, helpRequestCount) ||
                other.helpRequestCount == helpRequestCount) &&
            (identical(other.volunteerCount, volunteerCount) ||
                other.volunteerCount == volunteerCount) &&
            (identical(other.isDisabilityVerified, isDisabilityVerified) ||
                other.isDisabilityVerified == isDisabilityVerified) &&
            (identical(other.isVolunteerVerified, isVolunteerVerified) ||
                other.isVolunteerVerified == isVolunteerVerified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    phone,
    name,
    avatarUrl,
    const DeepCollectionEquality().hash(_roles),
    const DeepCollectionEquality().hash(_disabilityTypes),
    status,
    createdAt,
    lastLoginAt,
    helpRequestCount,
    volunteerCount,
    isDisabilityVerified,
    isVolunteerVerified,
  );

  /// Create a copy of UserListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserListItemImplCopyWith<_$UserListItemImpl> get copyWith =>
      __$$UserListItemImplCopyWithImpl<_$UserListItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserListItemImplToJson(this);
  }
}

abstract class _UserListItem implements UserListItem {
  const factory _UserListItem({
    required final String id,
    required final String phone,
    final String? name,
    final String? avatarUrl,
    required final List<String> roles,
    required final List<String> disabilityTypes,
    final String status,
    final DateTime? createdAt,
    final DateTime? lastLoginAt,
    final int helpRequestCount,
    final int volunteerCount,
    final bool? isDisabilityVerified,
    final bool? isVolunteerVerified,
  }) = _$UserListItemImpl;

  factory _UserListItem.fromJson(Map<String, dynamic> json) =
      _$UserListItemImpl.fromJson;

  @override
  String get id;
  @override
  String get phone;
  @override
  String? get name;
  @override
  String? get avatarUrl;
  @override
  List<String> get roles;
  @override
  List<String> get disabilityTypes;
  @override
  String get status; // 'active', 'banned', 'pending_verification'
  @override
  DateTime? get createdAt;
  @override
  DateTime? get lastLoginAt;
  @override
  int get helpRequestCount;
  @override
  int get volunteerCount;
  @override
  bool? get isDisabilityVerified;
  @override
  bool? get isVolunteerVerified;

  /// Create a copy of UserListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserListItemImplCopyWith<_$UserListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VerificationRequest _$VerificationRequestFromJson(Map<String, dynamic> json) {
  return _VerificationRequest.fromJson(json);
}

/// @nodoc
mixin _$VerificationRequest {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'disability', 'volunteer_skill'
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'approved', 'rejected'
  String? get documentUrl => throw _privateConstructorUsedError;
  String? get documentType => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  String? get reviewedBy => throw _privateConstructorUsedError;

  /// Serializes this VerificationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerificationRequestCopyWith<VerificationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationRequestCopyWith<$Res> {
  factory $VerificationRequestCopyWith(
    VerificationRequest value,
    $Res Function(VerificationRequest) then,
  ) = _$VerificationRequestCopyWithImpl<$Res, VerificationRequest>;
  @useResult
  $Res call({
    String id,
    String userId,
    String userName,
    String type,
    String status,
    String? documentUrl,
    String? documentType,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  });
}

/// @nodoc
class _$VerificationRequestCopyWithImpl<$Res, $Val extends VerificationRequest>
    implements $VerificationRequestCopyWith<$Res> {
  _$VerificationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? userName = null,
    Object? type = null,
    Object? status = null,
    Object? documentUrl = freezed,
    Object? documentType = freezed,
    Object? rejectionReason = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
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
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            documentUrl: freezed == documentUrl
                ? _value.documentUrl
                : documentUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            documentType: freezed == documentType
                ? _value.documentType
                : documentType // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedBy: freezed == reviewedBy
                ? _value.reviewedBy
                : reviewedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VerificationRequestImplCopyWith<$Res>
    implements $VerificationRequestCopyWith<$Res> {
  factory _$$VerificationRequestImplCopyWith(
    _$VerificationRequestImpl value,
    $Res Function(_$VerificationRequestImpl) then,
  ) = __$$VerificationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String userName,
    String type,
    String status,
    String? documentUrl,
    String? documentType,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  });
}

/// @nodoc
class __$$VerificationRequestImplCopyWithImpl<$Res>
    extends _$VerificationRequestCopyWithImpl<$Res, _$VerificationRequestImpl>
    implements _$$VerificationRequestImplCopyWith<$Res> {
  __$$VerificationRequestImplCopyWithImpl(
    _$VerificationRequestImpl _value,
    $Res Function(_$VerificationRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? userName = null,
    Object? type = null,
    Object? status = null,
    Object? documentUrl = freezed,
    Object? documentType = freezed,
    Object? rejectionReason = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? reviewedBy = freezed,
  }) {
    return _then(
      _$VerificationRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        documentUrl: freezed == documentUrl
            ? _value.documentUrl
            : documentUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        documentType: freezed == documentType
            ? _value.documentType
            : documentType // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedBy: freezed == reviewedBy
            ? _value.reviewedBy
            : reviewedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VerificationRequestImpl implements _VerificationRequest {
  const _$VerificationRequestImpl({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    this.documentUrl,
    this.documentType,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory _$VerificationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerificationRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String type;
  // 'disability', 'volunteer_skill'
  @override
  final String status;
  // 'pending', 'approved', 'rejected'
  @override
  final String? documentUrl;
  @override
  final String? documentType;
  @override
  final String? rejectionReason;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? reviewedAt;
  @override
  final String? reviewedBy;

  @override
  String toString() {
    return 'VerificationRequest(id: $id, userId: $userId, userName: $userName, type: $type, status: $status, documentUrl: $documentUrl, documentType: $documentType, rejectionReason: $rejectionReason, submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.documentUrl, documentUrl) ||
                other.documentUrl == documentUrl) &&
            (identical(other.documentType, documentType) ||
                other.documentType == documentType) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    userName,
    type,
    status,
    documentUrl,
    documentType,
    rejectionReason,
    submittedAt,
    reviewedAt,
    reviewedBy,
  );

  /// Create a copy of VerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationRequestImplCopyWith<_$VerificationRequestImpl> get copyWith =>
      __$$VerificationRequestImplCopyWithImpl<_$VerificationRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VerificationRequestImplToJson(this);
  }
}

abstract class _VerificationRequest implements VerificationRequest {
  const factory _VerificationRequest({
    required final String id,
    required final String userId,
    required final String userName,
    required final String type,
    required final String status,
    final String? documentUrl,
    final String? documentType,
    final String? rejectionReason,
    final DateTime? submittedAt,
    final DateTime? reviewedAt,
    final String? reviewedBy,
  }) = _$VerificationRequestImpl;

  factory _VerificationRequest.fromJson(Map<String, dynamic> json) =
      _$VerificationRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get userName;
  @override
  String get type; // 'disability', 'volunteer_skill'
  @override
  String get status; // 'pending', 'approved', 'rejected'
  @override
  String? get documentUrl;
  @override
  String? get documentType;
  @override
  String? get rejectionReason;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get reviewedAt;
  @override
  String? get reviewedBy;

  /// Create a copy of VerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerificationRequestImplCopyWith<_$VerificationRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReportRecord _$ReportRecordFromJson(Map<String, dynamic> json) {
  return _ReportRecord.fromJson(json);
}

/// @nodoc
mixin _$ReportRecord {
  String get id => throw _privateConstructorUsedError;
  String get reporterId => throw _privateConstructorUsedError;
  String get reporterName => throw _privateConstructorUsedError;
  String get targetId => throw _privateConstructorUsedError;
  String get targetType =>
      throw _privateConstructorUsedError; // 'user', 'content', 'call'
  String get targetName => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get evidenceUrls => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'processing', 'resolved', 'dismissed'
  String? get resolution => throw _privateConstructorUsedError;
  String? get action =>
      throw _privateConstructorUsedError; // 'warning', 'ban', 'dismiss'
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;

  /// Serializes this ReportRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportRecordCopyWith<ReportRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportRecordCopyWith<$Res> {
  factory $ReportRecordCopyWith(
    ReportRecord value,
    $Res Function(ReportRecord) then,
  ) = _$ReportRecordCopyWithImpl<$Res, ReportRecord>;
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reporterName,
    String targetId,
    String targetType,
    String targetName,
    String reason,
    String? description,
    String? evidenceUrls,
    String status,
    String? resolution,
    String? action,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  });
}

/// @nodoc
class _$ReportRecordCopyWithImpl<$Res, $Val extends ReportRecord>
    implements $ReportRecordCopyWith<$Res> {
  _$ReportRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reporterName = null,
    Object? targetId = null,
    Object? targetType = null,
    Object? targetName = null,
    Object? reason = null,
    Object? description = freezed,
    Object? evidenceUrls = freezed,
    Object? status = null,
    Object? resolution = freezed,
    Object? action = freezed,
    Object? createdAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            reporterId: null == reporterId
                ? _value.reporterId
                : reporterId // ignore: cast_nullable_to_non_nullable
                      as String,
            reporterName: null == reporterName
                ? _value.reporterName
                : reporterName // ignore: cast_nullable_to_non_nullable
                      as String,
            targetId: null == targetId
                ? _value.targetId
                : targetId // ignore: cast_nullable_to_non_nullable
                      as String,
            targetType: null == targetType
                ? _value.targetType
                : targetType // ignore: cast_nullable_to_non_nullable
                      as String,
            targetName: null == targetName
                ? _value.targetName
                : targetName // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            evidenceUrls: freezed == evidenceUrls
                ? _value.evidenceUrls
                : evidenceUrls // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            resolution: freezed == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as String?,
            action: freezed == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportRecordImplCopyWith<$Res>
    implements $ReportRecordCopyWith<$Res> {
  factory _$$ReportRecordImplCopyWith(
    _$ReportRecordImpl value,
    $Res Function(_$ReportRecordImpl) then,
  ) = __$$ReportRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reporterName,
    String targetId,
    String targetType,
    String targetName,
    String reason,
    String? description,
    String? evidenceUrls,
    String status,
    String? resolution,
    String? action,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  });
}

/// @nodoc
class __$$ReportRecordImplCopyWithImpl<$Res>
    extends _$ReportRecordCopyWithImpl<$Res, _$ReportRecordImpl>
    implements _$$ReportRecordImplCopyWith<$Res> {
  __$$ReportRecordImplCopyWithImpl(
    _$ReportRecordImpl _value,
    $Res Function(_$ReportRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reporterName = null,
    Object? targetId = null,
    Object? targetType = null,
    Object? targetName = null,
    Object? reason = null,
    Object? description = freezed,
    Object? evidenceUrls = freezed,
    Object? status = null,
    Object? resolution = freezed,
    Object? action = freezed,
    Object? createdAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _$ReportRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reporterId: null == reporterId
            ? _value.reporterId
            : reporterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reporterName: null == reporterName
            ? _value.reporterName
            : reporterName // ignore: cast_nullable_to_non_nullable
                  as String,
        targetId: null == targetId
            ? _value.targetId
            : targetId // ignore: cast_nullable_to_non_nullable
                  as String,
        targetType: null == targetType
            ? _value.targetType
            : targetType // ignore: cast_nullable_to_non_nullable
                  as String,
        targetName: null == targetName
            ? _value.targetName
            : targetName // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        evidenceUrls: freezed == evidenceUrls
            ? _value.evidenceUrls
            : evidenceUrls // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        resolution: freezed == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as String?,
        action: freezed == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportRecordImpl implements _ReportRecord {
  const _$ReportRecordImpl({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    required this.reason,
    this.description,
    this.evidenceUrls,
    required this.status,
    this.resolution,
    this.action,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory _$ReportRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String reporterId;
  @override
  final String reporterName;
  @override
  final String targetId;
  @override
  final String targetType;
  // 'user', 'content', 'call'
  @override
  final String targetName;
  @override
  final String reason;
  @override
  final String? description;
  @override
  final String? evidenceUrls;
  @override
  final String status;
  // 'pending', 'processing', 'resolved', 'dismissed'
  @override
  final String? resolution;
  @override
  final String? action;
  // 'warning', 'ban', 'dismiss'
  @override
  final DateTime? createdAt;
  @override
  final DateTime? resolvedAt;
  @override
  final String? resolvedBy;

  @override
  String toString() {
    return 'ReportRecord(id: $id, reporterId: $reporterId, reporterName: $reporterName, targetId: $targetId, targetType: $targetType, targetName: $targetName, reason: $reason, description: $description, evidenceUrls: $evidenceUrls, status: $status, resolution: $resolution, action: $action, createdAt: $createdAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reporterId, reporterId) ||
                other.reporterId == reporterId) &&
            (identical(other.reporterName, reporterName) ||
                other.reporterName == reporterName) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.targetName, targetName) ||
                other.targetName == targetName) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.evidenceUrls, evidenceUrls) ||
                other.evidenceUrls == evidenceUrls) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reporterId,
    reporterName,
    targetId,
    targetType,
    targetName,
    reason,
    description,
    evidenceUrls,
    status,
    resolution,
    action,
    createdAt,
    resolvedAt,
    resolvedBy,
  );

  /// Create a copy of ReportRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportRecordImplCopyWith<_$ReportRecordImpl> get copyWith =>
      __$$ReportRecordImplCopyWithImpl<_$ReportRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportRecordImplToJson(this);
  }
}

abstract class _ReportRecord implements ReportRecord {
  const factory _ReportRecord({
    required final String id,
    required final String reporterId,
    required final String reporterName,
    required final String targetId,
    required final String targetType,
    required final String targetName,
    required final String reason,
    final String? description,
    final String? evidenceUrls,
    required final String status,
    final String? resolution,
    final String? action,
    final DateTime? createdAt,
    final DateTime? resolvedAt,
    final String? resolvedBy,
  }) = _$ReportRecordImpl;

  factory _ReportRecord.fromJson(Map<String, dynamic> json) =
      _$ReportRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get reporterId;
  @override
  String get reporterName;
  @override
  String get targetId;
  @override
  String get targetType; // 'user', 'content', 'call'
  @override
  String get targetName;
  @override
  String get reason;
  @override
  String? get description;
  @override
  String? get evidenceUrls;
  @override
  String get status; // 'pending', 'processing', 'resolved', 'dismissed'
  @override
  String? get resolution;
  @override
  String? get action; // 'warning', 'ban', 'dismiss'
  @override
  DateTime? get createdAt;
  @override
  DateTime? get resolvedAt;
  @override
  String? get resolvedBy;

  /// Create a copy of ReportRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportRecordImplCopyWith<_$ReportRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) {
  return _ContentItem.fromJson(json);
}

/// @nodoc
mixin _$ContentItem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'story', 'announcement', 'guide'
  String get authorId => throw _privateConstructorUsedError;
  String get authorName => throw _privateConstructorUsedError;
  String? get coverImageUrl => throw _privateConstructorUsedError;
  int get viewCount => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'draft', 'pending', 'published', 'rejected', 'archived'
  List<String>? get tags => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get publishedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ContentItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentItemCopyWith<ContentItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentItemCopyWith<$Res> {
  factory $ContentItemCopyWith(
    ContentItem value,
    $Res Function(ContentItem) then,
  ) = _$ContentItemCopyWithImpl<$Res, ContentItem>;
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    String type,
    String authorId,
    String authorName,
    String? coverImageUrl,
    int viewCount,
    int likeCount,
    String status,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? publishedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$ContentItemCopyWithImpl<$Res, $Val extends ContentItem>
    implements $ContentItemCopyWith<$Res> {
  _$ContentItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? type = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? coverImageUrl = freezed,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? status = null,
    Object? tags = freezed,
    Object? createdAt = freezed,
    Object? publishedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: null == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String,
            coverImageUrl: freezed == coverImageUrl
                ? _value.coverImageUrl
                : coverImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            viewCount: null == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ContentItemImplCopyWith<$Res>
    implements $ContentItemCopyWith<$Res> {
  factory _$$ContentItemImplCopyWith(
    _$ContentItemImpl value,
    $Res Function(_$ContentItemImpl) then,
  ) = __$$ContentItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    String type,
    String authorId,
    String authorName,
    String? coverImageUrl,
    int viewCount,
    int likeCount,
    String status,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? publishedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ContentItemImplCopyWithImpl<$Res>
    extends _$ContentItemCopyWithImpl<$Res, _$ContentItemImpl>
    implements _$$ContentItemImplCopyWith<$Res> {
  __$$ContentItemImplCopyWithImpl(
    _$ContentItemImpl _value,
    $Res Function(_$ContentItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? type = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? coverImageUrl = freezed,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? status = null,
    Object? tags = freezed,
    Object? createdAt = freezed,
    Object? publishedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ContentItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: null == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String,
        coverImageUrl: freezed == coverImageUrl
            ? _value.coverImageUrl
            : coverImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        viewCount: null == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
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
class _$ContentItemImpl implements _ContentItem {
  const _$ContentItemImpl({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.authorId,
    required this.authorName,
    this.coverImageUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.status = 'draft',
    final List<String>? tags,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  }) : _tags = tags;

  factory _$ContentItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentItemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final String type;
  // 'story', 'announcement', 'guide'
  @override
  final String authorId;
  @override
  final String authorName;
  @override
  final String? coverImageUrl;
  @override
  @JsonKey()
  final int viewCount;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final String status;
  // 'draft', 'pending', 'published', 'rejected', 'archived'
  final List<String>? _tags;
  // 'draft', 'pending', 'published', 'rejected', 'archived'
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? publishedAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ContentItem(id: $id, title: $title, content: $content, type: $type, authorId: $authorId, authorName: $authorName, coverImageUrl: $coverImageUrl, viewCount: $viewCount, likeCount: $likeCount, status: $status, tags: $tags, createdAt: $createdAt, publishedAt: $publishedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    content,
    type,
    authorId,
    authorName,
    coverImageUrl,
    viewCount,
    likeCount,
    status,
    const DeepCollectionEquality().hash(_tags),
    createdAt,
    publishedAt,
    updatedAt,
  );

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentItemImplCopyWith<_$ContentItemImpl> get copyWith =>
      __$$ContentItemImplCopyWithImpl<_$ContentItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentItemImplToJson(this);
  }
}

abstract class _ContentItem implements ContentItem {
  const factory _ContentItem({
    required final String id,
    required final String title,
    required final String content,
    required final String type,
    required final String authorId,
    required final String authorName,
    final String? coverImageUrl,
    final int viewCount,
    final int likeCount,
    final String status,
    final List<String>? tags,
    final DateTime? createdAt,
    final DateTime? publishedAt,
    final DateTime? updatedAt,
  }) = _$ContentItemImpl;

  factory _ContentItem.fromJson(Map<String, dynamic> json) =
      _$ContentItemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  String get type; // 'story', 'announcement', 'guide'
  @override
  String get authorId;
  @override
  String get authorName;
  @override
  String? get coverImageUrl;
  @override
  int get viewCount;
  @override
  int get likeCount;
  @override
  String get status; // 'draft', 'pending', 'published', 'rejected', 'archived'
  @override
  List<String>? get tags;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get publishedAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentItemImplCopyWith<_$ContentItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) {
  return _DashboardStats.fromJson(json);
}

/// @nodoc
mixin _$DashboardStats {
  int get totalUsers => throw _privateConstructorUsedError;
  int get newUsersToday => throw _privateConstructorUsedError;
  int get dau => throw _privateConstructorUsedError;
  int get mau => throw _privateConstructorUsedError;
  double get dauGrowthRate => throw _privateConstructorUsedError;
  double get mauGrowthRate => throw _privateConstructorUsedError;
  int get totalHelpRequests => throw _privateConstructorUsedError;
  int get helpRequestsToday => throw _privateConstructorUsedError;
  double get responseRate => throw _privateConstructorUsedError;
  double get aiResolutionRate => throw _privateConstructorUsedError;
  double get avgCallDuration => throw _privateConstructorUsedError;
  double get satisfactionRate => throw _privateConstructorUsedError;
  double get volunteerRetentionRate => throw _privateConstructorUsedError;
  int get pendingReports => throw _privateConstructorUsedError;
  int get pendingVerifications => throw _privateConstructorUsedError;

  /// Serializes this DashboardStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardStatsCopyWith<DashboardStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStatsCopyWith<$Res> {
  factory $DashboardStatsCopyWith(
    DashboardStats value,
    $Res Function(DashboardStats) then,
  ) = _$DashboardStatsCopyWithImpl<$Res, DashboardStats>;
  @useResult
  $Res call({
    int totalUsers,
    int newUsersToday,
    int dau,
    int mau,
    double dauGrowthRate,
    double mauGrowthRate,
    int totalHelpRequests,
    int helpRequestsToday,
    double responseRate,
    double aiResolutionRate,
    double avgCallDuration,
    double satisfactionRate,
    double volunteerRetentionRate,
    int pendingReports,
    int pendingVerifications,
  });
}

/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res, $Val extends DashboardStats>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalUsers = null,
    Object? newUsersToday = null,
    Object? dau = null,
    Object? mau = null,
    Object? dauGrowthRate = null,
    Object? mauGrowthRate = null,
    Object? totalHelpRequests = null,
    Object? helpRequestsToday = null,
    Object? responseRate = null,
    Object? aiResolutionRate = null,
    Object? avgCallDuration = null,
    Object? satisfactionRate = null,
    Object? volunteerRetentionRate = null,
    Object? pendingReports = null,
    Object? pendingVerifications = null,
  }) {
    return _then(
      _value.copyWith(
            totalUsers: null == totalUsers
                ? _value.totalUsers
                : totalUsers // ignore: cast_nullable_to_non_nullable
                      as int,
            newUsersToday: null == newUsersToday
                ? _value.newUsersToday
                : newUsersToday // ignore: cast_nullable_to_non_nullable
                      as int,
            dau: null == dau
                ? _value.dau
                : dau // ignore: cast_nullable_to_non_nullable
                      as int,
            mau: null == mau
                ? _value.mau
                : mau // ignore: cast_nullable_to_non_nullable
                      as int,
            dauGrowthRate: null == dauGrowthRate
                ? _value.dauGrowthRate
                : dauGrowthRate // ignore: cast_nullable_to_non_nullable
                      as double,
            mauGrowthRate: null == mauGrowthRate
                ? _value.mauGrowthRate
                : mauGrowthRate // ignore: cast_nullable_to_non_nullable
                      as double,
            totalHelpRequests: null == totalHelpRequests
                ? _value.totalHelpRequests
                : totalHelpRequests // ignore: cast_nullable_to_non_nullable
                      as int,
            helpRequestsToday: null == helpRequestsToday
                ? _value.helpRequestsToday
                : helpRequestsToday // ignore: cast_nullable_to_non_nullable
                      as int,
            responseRate: null == responseRate
                ? _value.responseRate
                : responseRate // ignore: cast_nullable_to_non_nullable
                      as double,
            aiResolutionRate: null == aiResolutionRate
                ? _value.aiResolutionRate
                : aiResolutionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            avgCallDuration: null == avgCallDuration
                ? _value.avgCallDuration
                : avgCallDuration // ignore: cast_nullable_to_non_nullable
                      as double,
            satisfactionRate: null == satisfactionRate
                ? _value.satisfactionRate
                : satisfactionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            volunteerRetentionRate: null == volunteerRetentionRate
                ? _value.volunteerRetentionRate
                : volunteerRetentionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            pendingReports: null == pendingReports
                ? _value.pendingReports
                : pendingReports // ignore: cast_nullable_to_non_nullable
                      as int,
            pendingVerifications: null == pendingVerifications
                ? _value.pendingVerifications
                : pendingVerifications // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardStatsImplCopyWith<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  factory _$$DashboardStatsImplCopyWith(
    _$DashboardStatsImpl value,
    $Res Function(_$DashboardStatsImpl) then,
  ) = __$$DashboardStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalUsers,
    int newUsersToday,
    int dau,
    int mau,
    double dauGrowthRate,
    double mauGrowthRate,
    int totalHelpRequests,
    int helpRequestsToday,
    double responseRate,
    double aiResolutionRate,
    double avgCallDuration,
    double satisfactionRate,
    double volunteerRetentionRate,
    int pendingReports,
    int pendingVerifications,
  });
}

/// @nodoc
class __$$DashboardStatsImplCopyWithImpl<$Res>
    extends _$DashboardStatsCopyWithImpl<$Res, _$DashboardStatsImpl>
    implements _$$DashboardStatsImplCopyWith<$Res> {
  __$$DashboardStatsImplCopyWithImpl(
    _$DashboardStatsImpl _value,
    $Res Function(_$DashboardStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalUsers = null,
    Object? newUsersToday = null,
    Object? dau = null,
    Object? mau = null,
    Object? dauGrowthRate = null,
    Object? mauGrowthRate = null,
    Object? totalHelpRequests = null,
    Object? helpRequestsToday = null,
    Object? responseRate = null,
    Object? aiResolutionRate = null,
    Object? avgCallDuration = null,
    Object? satisfactionRate = null,
    Object? volunteerRetentionRate = null,
    Object? pendingReports = null,
    Object? pendingVerifications = null,
  }) {
    return _then(
      _$DashboardStatsImpl(
        totalUsers: null == totalUsers
            ? _value.totalUsers
            : totalUsers // ignore: cast_nullable_to_non_nullable
                  as int,
        newUsersToday: null == newUsersToday
            ? _value.newUsersToday
            : newUsersToday // ignore: cast_nullable_to_non_nullable
                  as int,
        dau: null == dau
            ? _value.dau
            : dau // ignore: cast_nullable_to_non_nullable
                  as int,
        mau: null == mau
            ? _value.mau
            : mau // ignore: cast_nullable_to_non_nullable
                  as int,
        dauGrowthRate: null == dauGrowthRate
            ? _value.dauGrowthRate
            : dauGrowthRate // ignore: cast_nullable_to_non_nullable
                  as double,
        mauGrowthRate: null == mauGrowthRate
            ? _value.mauGrowthRate
            : mauGrowthRate // ignore: cast_nullable_to_non_nullable
                  as double,
        totalHelpRequests: null == totalHelpRequests
            ? _value.totalHelpRequests
            : totalHelpRequests // ignore: cast_nullable_to_non_nullable
                  as int,
        helpRequestsToday: null == helpRequestsToday
            ? _value.helpRequestsToday
            : helpRequestsToday // ignore: cast_nullable_to_non_nullable
                  as int,
        responseRate: null == responseRate
            ? _value.responseRate
            : responseRate // ignore: cast_nullable_to_non_nullable
                  as double,
        aiResolutionRate: null == aiResolutionRate
            ? _value.aiResolutionRate
            : aiResolutionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        avgCallDuration: null == avgCallDuration
            ? _value.avgCallDuration
            : avgCallDuration // ignore: cast_nullable_to_non_nullable
                  as double,
        satisfactionRate: null == satisfactionRate
            ? _value.satisfactionRate
            : satisfactionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        volunteerRetentionRate: null == volunteerRetentionRate
            ? _value.volunteerRetentionRate
            : volunteerRetentionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        pendingReports: null == pendingReports
            ? _value.pendingReports
            : pendingReports // ignore: cast_nullable_to_non_nullable
                  as int,
        pendingVerifications: null == pendingVerifications
            ? _value.pendingVerifications
            : pendingVerifications // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardStatsImpl implements _DashboardStats {
  const _$DashboardStatsImpl({
    required this.totalUsers,
    required this.newUsersToday,
    required this.dau,
    required this.mau,
    this.dauGrowthRate = 0.0,
    this.mauGrowthRate = 0.0,
    required this.totalHelpRequests,
    required this.helpRequestsToday,
    this.responseRate = 0.0,
    this.aiResolutionRate = 0.0,
    this.avgCallDuration = 0.0,
    this.satisfactionRate = 0.0,
    this.volunteerRetentionRate = 0.0,
    required this.pendingReports,
    required this.pendingVerifications,
  });

  factory _$DashboardStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardStatsImplFromJson(json);

  @override
  final int totalUsers;
  @override
  final int newUsersToday;
  @override
  final int dau;
  @override
  final int mau;
  @override
  @JsonKey()
  final double dauGrowthRate;
  @override
  @JsonKey()
  final double mauGrowthRate;
  @override
  final int totalHelpRequests;
  @override
  final int helpRequestsToday;
  @override
  @JsonKey()
  final double responseRate;
  @override
  @JsonKey()
  final double aiResolutionRate;
  @override
  @JsonKey()
  final double avgCallDuration;
  @override
  @JsonKey()
  final double satisfactionRate;
  @override
  @JsonKey()
  final double volunteerRetentionRate;
  @override
  final int pendingReports;
  @override
  final int pendingVerifications;

  @override
  String toString() {
    return 'DashboardStats(totalUsers: $totalUsers, newUsersToday: $newUsersToday, dau: $dau, mau: $mau, dauGrowthRate: $dauGrowthRate, mauGrowthRate: $mauGrowthRate, totalHelpRequests: $totalHelpRequests, helpRequestsToday: $helpRequestsToday, responseRate: $responseRate, aiResolutionRate: $aiResolutionRate, avgCallDuration: $avgCallDuration, satisfactionRate: $satisfactionRate, volunteerRetentionRate: $volunteerRetentionRate, pendingReports: $pendingReports, pendingVerifications: $pendingVerifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardStatsImpl &&
            (identical(other.totalUsers, totalUsers) ||
                other.totalUsers == totalUsers) &&
            (identical(other.newUsersToday, newUsersToday) ||
                other.newUsersToday == newUsersToday) &&
            (identical(other.dau, dau) || other.dau == dau) &&
            (identical(other.mau, mau) || other.mau == mau) &&
            (identical(other.dauGrowthRate, dauGrowthRate) ||
                other.dauGrowthRate == dauGrowthRate) &&
            (identical(other.mauGrowthRate, mauGrowthRate) ||
                other.mauGrowthRate == mauGrowthRate) &&
            (identical(other.totalHelpRequests, totalHelpRequests) ||
                other.totalHelpRequests == totalHelpRequests) &&
            (identical(other.helpRequestsToday, helpRequestsToday) ||
                other.helpRequestsToday == helpRequestsToday) &&
            (identical(other.responseRate, responseRate) ||
                other.responseRate == responseRate) &&
            (identical(other.aiResolutionRate, aiResolutionRate) ||
                other.aiResolutionRate == aiResolutionRate) &&
            (identical(other.avgCallDuration, avgCallDuration) ||
                other.avgCallDuration == avgCallDuration) &&
            (identical(other.satisfactionRate, satisfactionRate) ||
                other.satisfactionRate == satisfactionRate) &&
            (identical(other.volunteerRetentionRate, volunteerRetentionRate) ||
                other.volunteerRetentionRate == volunteerRetentionRate) &&
            (identical(other.pendingReports, pendingReports) ||
                other.pendingReports == pendingReports) &&
            (identical(other.pendingVerifications, pendingVerifications) ||
                other.pendingVerifications == pendingVerifications));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalUsers,
    newUsersToday,
    dau,
    mau,
    dauGrowthRate,
    mauGrowthRate,
    totalHelpRequests,
    helpRequestsToday,
    responseRate,
    aiResolutionRate,
    avgCallDuration,
    satisfactionRate,
    volunteerRetentionRate,
    pendingReports,
    pendingVerifications,
  );

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      __$$DashboardStatsImplCopyWithImpl<_$DashboardStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardStatsImplToJson(this);
  }
}

abstract class _DashboardStats implements DashboardStats {
  const factory _DashboardStats({
    required final int totalUsers,
    required final int newUsersToday,
    required final int dau,
    required final int mau,
    final double dauGrowthRate,
    final double mauGrowthRate,
    required final int totalHelpRequests,
    required final int helpRequestsToday,
    final double responseRate,
    final double aiResolutionRate,
    final double avgCallDuration,
    final double satisfactionRate,
    final double volunteerRetentionRate,
    required final int pendingReports,
    required final int pendingVerifications,
  }) = _$DashboardStatsImpl;

  factory _DashboardStats.fromJson(Map<String, dynamic> json) =
      _$DashboardStatsImpl.fromJson;

  @override
  int get totalUsers;
  @override
  int get newUsersToday;
  @override
  int get dau;
  @override
  int get mau;
  @override
  double get dauGrowthRate;
  @override
  double get mauGrowthRate;
  @override
  int get totalHelpRequests;
  @override
  int get helpRequestsToday;
  @override
  double get responseRate;
  @override
  double get aiResolutionRate;
  @override
  double get avgCallDuration;
  @override
  double get satisfactionRate;
  @override
  double get volunteerRetentionRate;
  @override
  int get pendingReports;
  @override
  int get pendingVerifications;

  /// Create a copy of DashboardStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrendDataPoint _$TrendDataPointFromJson(Map<String, dynamic> json) {
  return _TrendDataPoint.fromJson(json);
}

/// @nodoc
mixin _$TrendDataPoint {
  DateTime get date => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  int? get secondaryValue => throw _privateConstructorUsedError;

  /// Serializes this TrendDataPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrendDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrendDataPointCopyWith<TrendDataPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrendDataPointCopyWith<$Res> {
  factory $TrendDataPointCopyWith(
    TrendDataPoint value,
    $Res Function(TrendDataPoint) then,
  ) = _$TrendDataPointCopyWithImpl<$Res, TrendDataPoint>;
  @useResult
  $Res call({DateTime date, int value, int? secondaryValue});
}

/// @nodoc
class _$TrendDataPointCopyWithImpl<$Res, $Val extends TrendDataPoint>
    implements $TrendDataPointCopyWith<$Res> {
  _$TrendDataPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrendDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
    Object? secondaryValue = freezed,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            secondaryValue: freezed == secondaryValue
                ? _value.secondaryValue
                : secondaryValue // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TrendDataPointImplCopyWith<$Res>
    implements $TrendDataPointCopyWith<$Res> {
  factory _$$TrendDataPointImplCopyWith(
    _$TrendDataPointImpl value,
    $Res Function(_$TrendDataPointImpl) then,
  ) = __$$TrendDataPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, int value, int? secondaryValue});
}

/// @nodoc
class __$$TrendDataPointImplCopyWithImpl<$Res>
    extends _$TrendDataPointCopyWithImpl<$Res, _$TrendDataPointImpl>
    implements _$$TrendDataPointImplCopyWith<$Res> {
  __$$TrendDataPointImplCopyWithImpl(
    _$TrendDataPointImpl _value,
    $Res Function(_$TrendDataPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrendDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
    Object? secondaryValue = freezed,
  }) {
    return _then(
      _$TrendDataPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        secondaryValue: freezed == secondaryValue
            ? _value.secondaryValue
            : secondaryValue // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TrendDataPointImpl implements _TrendDataPoint {
  const _$TrendDataPointImpl({
    required this.date,
    required this.value,
    this.secondaryValue,
  });

  factory _$TrendDataPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrendDataPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final int value;
  @override
  final int? secondaryValue;

  @override
  String toString() {
    return 'TrendDataPoint(date: $date, value: $value, secondaryValue: $secondaryValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrendDataPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.secondaryValue, secondaryValue) ||
                other.secondaryValue == secondaryValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, value, secondaryValue);

  /// Create a copy of TrendDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrendDataPointImplCopyWith<_$TrendDataPointImpl> get copyWith =>
      __$$TrendDataPointImplCopyWithImpl<_$TrendDataPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TrendDataPointImplToJson(this);
  }
}

abstract class _TrendDataPoint implements TrendDataPoint {
  const factory _TrendDataPoint({
    required final DateTime date,
    required final int value,
    final int? secondaryValue,
  }) = _$TrendDataPointImpl;

  factory _TrendDataPoint.fromJson(Map<String, dynamic> json) =
      _$TrendDataPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  int get value;
  @override
  int? get secondaryValue;

  /// Create a copy of TrendDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrendDataPointImplCopyWith<_$TrendDataPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DistributionItem _$DistributionItemFromJson(Map<String, dynamic> json) {
  return _DistributionItem.fromJson(json);
}

/// @nodoc
mixin _$DistributionItem {
  String get label => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;

  /// Serializes this DistributionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DistributionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DistributionItemCopyWith<DistributionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DistributionItemCopyWith<$Res> {
  factory $DistributionItemCopyWith(
    DistributionItem value,
    $Res Function(DistributionItem) then,
  ) = _$DistributionItemCopyWithImpl<$Res, DistributionItem>;
  @useResult
  $Res call({String label, int value, int colorValue});
}

/// @nodoc
class _$DistributionItemCopyWithImpl<$Res, $Val extends DistributionItem>
    implements $DistributionItemCopyWith<$Res> {
  _$DistributionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DistributionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? colorValue = null,
  }) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            colorValue: null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DistributionItemImplCopyWith<$Res>
    implements $DistributionItemCopyWith<$Res> {
  factory _$$DistributionItemImplCopyWith(
    _$DistributionItemImpl value,
    $Res Function(_$DistributionItemImpl) then,
  ) = __$$DistributionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, int value, int colorValue});
}

/// @nodoc
class __$$DistributionItemImplCopyWithImpl<$Res>
    extends _$DistributionItemCopyWithImpl<$Res, _$DistributionItemImpl>
    implements _$$DistributionItemImplCopyWith<$Res> {
  __$$DistributionItemImplCopyWithImpl(
    _$DistributionItemImpl _value,
    $Res Function(_$DistributionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DistributionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? colorValue = null,
  }) {
    return _then(
      _$DistributionItemImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        colorValue: null == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DistributionItemImpl implements _DistributionItem {
  const _$DistributionItemImpl({
    required this.label,
    required this.value,
    required this.colorValue,
  });

  factory _$DistributionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$DistributionItemImplFromJson(json);

  @override
  final String label;
  @override
  final int value;
  @override
  final int colorValue;

  @override
  String toString() {
    return 'DistributionItem(label: $label, value: $value, colorValue: $colorValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistributionItemImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label, value, colorValue);

  /// Create a copy of DistributionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistributionItemImplCopyWith<_$DistributionItemImpl> get copyWith =>
      __$$DistributionItemImplCopyWithImpl<_$DistributionItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DistributionItemImplToJson(this);
  }
}

abstract class _DistributionItem implements DistributionItem {
  const factory _DistributionItem({
    required final String label,
    required final int value,
    required final int colorValue,
  }) = _$DistributionItemImpl;

  factory _DistributionItem.fromJson(Map<String, dynamic> json) =
      _$DistributionItemImpl.fromJson;

  @override
  String get label;
  @override
  int get value;
  @override
  int get colorValue;

  /// Create a copy of DistributionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistributionItemImplCopyWith<_$DistributionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StatisticsReport _$StatisticsReportFromJson(Map<String, dynamic> json) {
  return _StatisticsReport.fromJson(json);
}

/// @nodoc
mixin _$StatisticsReport {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'daily', 'weekly', 'monthly'
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  DateTime? get generatedAt => throw _privateConstructorUsedError;
  String? get generatedBy => throw _privateConstructorUsedError;

  /// Serializes this StatisticsReport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StatisticsReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatisticsReportCopyWith<StatisticsReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatisticsReportCopyWith<$Res> {
  factory $StatisticsReportCopyWith(
    StatisticsReport value,
    $Res Function(StatisticsReport) then,
  ) = _$StatisticsReportCopyWithImpl<$Res, StatisticsReport>;
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> data,
    DateTime? generatedAt,
    String? generatedBy,
  });
}

/// @nodoc
class _$StatisticsReportCopyWithImpl<$Res, $Val extends StatisticsReport>
    implements $StatisticsReportCopyWith<$Res> {
  _$StatisticsReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StatisticsReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? data = null,
    Object? generatedAt = freezed,
    Object? generatedBy = freezed,
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            generatedAt: freezed == generatedAt
                ? _value.generatedAt
                : generatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            generatedBy: freezed == generatedBy
                ? _value.generatedBy
                : generatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StatisticsReportImplCopyWith<$Res>
    implements $StatisticsReportCopyWith<$Res> {
  factory _$$StatisticsReportImplCopyWith(
    _$StatisticsReportImpl value,
    $Res Function(_$StatisticsReportImpl) then,
  ) = __$$StatisticsReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> data,
    DateTime? generatedAt,
    String? generatedBy,
  });
}

/// @nodoc
class __$$StatisticsReportImplCopyWithImpl<$Res>
    extends _$StatisticsReportCopyWithImpl<$Res, _$StatisticsReportImpl>
    implements _$$StatisticsReportImplCopyWith<$Res> {
  __$$StatisticsReportImplCopyWithImpl(
    _$StatisticsReportImpl _value,
    $Res Function(_$StatisticsReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StatisticsReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? data = null,
    Object? generatedAt = freezed,
    Object? generatedBy = freezed,
  }) {
    return _then(
      _$StatisticsReportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        generatedAt: freezed == generatedAt
            ? _value.generatedAt
            : generatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        generatedBy: freezed == generatedBy
            ? _value.generatedBy
            : generatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StatisticsReportImpl implements _StatisticsReport {
  const _$StatisticsReportImpl({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required final Map<String, dynamic> data,
    this.generatedAt,
    this.generatedBy,
  }) : _data = data;

  factory _$StatisticsReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatisticsReportImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
  // 'daily', 'weekly', 'monthly'
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  final DateTime? generatedAt;
  @override
  final String? generatedBy;

  @override
  String toString() {
    return 'StatisticsReport(id: $id, name: $name, type: $type, startDate: $startDate, endDate: $endDate, data: $data, generatedAt: $generatedAt, generatedBy: $generatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatisticsReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.generatedBy, generatedBy) ||
                other.generatedBy == generatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    startDate,
    endDate,
    const DeepCollectionEquality().hash(_data),
    generatedAt,
    generatedBy,
  );

  /// Create a copy of StatisticsReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatisticsReportImplCopyWith<_$StatisticsReportImpl> get copyWith =>
      __$$StatisticsReportImplCopyWithImpl<_$StatisticsReportImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StatisticsReportImplToJson(this);
  }
}

abstract class _StatisticsReport implements StatisticsReport {
  const factory _StatisticsReport({
    required final String id,
    required final String name,
    required final String type,
    required final DateTime startDate,
    required final DateTime endDate,
    required final Map<String, dynamic> data,
    final DateTime? generatedAt,
    final String? generatedBy,
  }) = _$StatisticsReportImpl;

  factory _StatisticsReport.fromJson(Map<String, dynamic> json) =
      _$StatisticsReportImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type; // 'daily', 'weekly', 'monthly'
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  Map<String, dynamic> get data;
  @override
  DateTime? get generatedAt;
  @override
  String? get generatedBy;

  /// Create a copy of StatisticsReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatisticsReportImplCopyWith<_$StatisticsReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OperationLog _$OperationLogFromJson(Map<String, dynamic> json) {
  return _OperationLog.fromJson(json);
}

/// @nodoc
mixin _$OperationLog {
  String get id => throw _privateConstructorUsedError;
  String get adminId => throw _privateConstructorUsedError;
  String get adminName => throw _privateConstructorUsedError;
  String get operation => throw _privateConstructorUsedError;
  String get targetType => throw _privateConstructorUsedError;
  String get targetId => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OperationLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OperationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OperationLogCopyWith<OperationLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OperationLogCopyWith<$Res> {
  factory $OperationLogCopyWith(
    OperationLog value,
    $Res Function(OperationLog) then,
  ) = _$OperationLogCopyWithImpl<$Res, OperationLog>;
  @useResult
  $Res call({
    String id,
    String adminId,
    String adminName,
    String operation,
    String targetType,
    String targetId,
    String? details,
    DateTime createdAt,
  });
}

/// @nodoc
class _$OperationLogCopyWithImpl<$Res, $Val extends OperationLog>
    implements $OperationLogCopyWith<$Res> {
  _$OperationLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OperationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? adminId = null,
    Object? adminName = null,
    Object? operation = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? details = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            adminId: null == adminId
                ? _value.adminId
                : adminId // ignore: cast_nullable_to_non_nullable
                      as String,
            adminName: null == adminName
                ? _value.adminName
                : adminName // ignore: cast_nullable_to_non_nullable
                      as String,
            operation: null == operation
                ? _value.operation
                : operation // ignore: cast_nullable_to_non_nullable
                      as String,
            targetType: null == targetType
                ? _value.targetType
                : targetType // ignore: cast_nullable_to_non_nullable
                      as String,
            targetId: null == targetId
                ? _value.targetId
                : targetId // ignore: cast_nullable_to_non_nullable
                      as String,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OperationLogImplCopyWith<$Res>
    implements $OperationLogCopyWith<$Res> {
  factory _$$OperationLogImplCopyWith(
    _$OperationLogImpl value,
    $Res Function(_$OperationLogImpl) then,
  ) = __$$OperationLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String adminId,
    String adminName,
    String operation,
    String targetType,
    String targetId,
    String? details,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$OperationLogImplCopyWithImpl<$Res>
    extends _$OperationLogCopyWithImpl<$Res, _$OperationLogImpl>
    implements _$$OperationLogImplCopyWith<$Res> {
  __$$OperationLogImplCopyWithImpl(
    _$OperationLogImpl _value,
    $Res Function(_$OperationLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OperationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? adminId = null,
    Object? adminName = null,
    Object? operation = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? details = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$OperationLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        adminId: null == adminId
            ? _value.adminId
            : adminId // ignore: cast_nullable_to_non_nullable
                  as String,
        adminName: null == adminName
            ? _value.adminName
            : adminName // ignore: cast_nullable_to_non_nullable
                  as String,
        operation: null == operation
            ? _value.operation
            : operation // ignore: cast_nullable_to_non_nullable
                  as String,
        targetType: null == targetType
            ? _value.targetType
            : targetType // ignore: cast_nullable_to_non_nullable
                  as String,
        targetId: null == targetId
            ? _value.targetId
            : targetId // ignore: cast_nullable_to_non_nullable
                  as String,
        details: freezed == details
            ? _value.details
            : details // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OperationLogImpl implements _OperationLog {
  const _$OperationLogImpl({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.operation,
    required this.targetType,
    required this.targetId,
    this.details,
    required this.createdAt,
  });

  factory _$OperationLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$OperationLogImplFromJson(json);

  @override
  final String id;
  @override
  final String adminId;
  @override
  final String adminName;
  @override
  final String operation;
  @override
  final String targetType;
  @override
  final String targetId;
  @override
  final String? details;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'OperationLog(id: $id, adminId: $adminId, adminName: $adminName, operation: $operation, targetType: $targetType, targetId: $targetId, details: $details, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.adminId, adminId) || other.adminId == adminId) &&
            (identical(other.adminName, adminName) ||
                other.adminName == adminName) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    adminId,
    adminName,
    operation,
    targetType,
    targetId,
    details,
    createdAt,
  );

  /// Create a copy of OperationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperationLogImplCopyWith<_$OperationLogImpl> get copyWith =>
      __$$OperationLogImplCopyWithImpl<_$OperationLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OperationLogImplToJson(this);
  }
}

abstract class _OperationLog implements OperationLog {
  const factory _OperationLog({
    required final String id,
    required final String adminId,
    required final String adminName,
    required final String operation,
    required final String targetType,
    required final String targetId,
    final String? details,
    required final DateTime createdAt,
  }) = _$OperationLogImpl;

  factory _OperationLog.fromJson(Map<String, dynamic> json) =
      _$OperationLogImpl.fromJson;

  @override
  String get id;
  @override
  String get adminId;
  @override
  String get adminName;
  @override
  String get operation;
  @override
  String get targetType;
  @override
  String get targetId;
  @override
  String? get details;
  @override
  DateTime get createdAt;

  /// Create a copy of OperationLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperationLogImplCopyWith<_$OperationLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
