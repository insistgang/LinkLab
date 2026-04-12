// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InterestGroup _$InterestGroupFromJson(Map<String, dynamic> json) {
  return _InterestGroup.fromJson(json);
}

/// @nodoc
mixin _$InterestGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  int get postCount => throw _privateConstructorUsedError;
  bool get isJoined => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this InterestGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InterestGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterestGroupCopyWith<InterestGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterestGroupCopyWith<$Res> {
  factory $InterestGroupCopyWith(
    InterestGroup value,
    $Res Function(InterestGroup) then,
  ) = _$InterestGroupCopyWithImpl<$Res, InterestGroup>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String category,
    String? iconUrl,
    int memberCount,
    int postCount,
    bool isJoined,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$InterestGroupCopyWithImpl<$Res, $Val extends InterestGroup>
    implements $InterestGroupCopyWith<$Res> {
  _$InterestGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InterestGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? iconUrl = freezed,
    Object? memberCount = null,
    Object? postCount = null,
    Object? isJoined = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            iconUrl: freezed == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberCount: null == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int,
            postCount: null == postCount
                ? _value.postCount
                : postCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isJoined: null == isJoined
                ? _value.isJoined
                : isJoined // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$InterestGroupImplCopyWith<$Res>
    implements $InterestGroupCopyWith<$Res> {
  factory _$$InterestGroupImplCopyWith(
    _$InterestGroupImpl value,
    $Res Function(_$InterestGroupImpl) then,
  ) = __$$InterestGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String category,
    String? iconUrl,
    int memberCount,
    int postCount,
    bool isJoined,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$InterestGroupImplCopyWithImpl<$Res>
    extends _$InterestGroupCopyWithImpl<$Res, _$InterestGroupImpl>
    implements _$$InterestGroupImplCopyWith<$Res> {
  __$$InterestGroupImplCopyWithImpl(
    _$InterestGroupImpl _value,
    $Res Function(_$InterestGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InterestGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? category = null,
    Object? iconUrl = freezed,
    Object? memberCount = null,
    Object? postCount = null,
    Object? isJoined = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$InterestGroupImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        iconUrl: freezed == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberCount: null == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int,
        postCount: null == postCount
            ? _value.postCount
            : postCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isJoined: null == isJoined
            ? _value.isJoined
            : isJoined // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$InterestGroupImpl implements _InterestGroup {
  const _$InterestGroupImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconUrl,
    this.memberCount = 0,
    this.postCount = 0,
    this.isJoined = false,
    this.createdAt,
    this.updatedAt,
  });

  factory _$InterestGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$InterestGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String category;
  @override
  final String? iconUrl;
  @override
  @JsonKey()
  final int memberCount;
  @override
  @JsonKey()
  final int postCount;
  @override
  @JsonKey()
  final bool isJoined;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'InterestGroup(id: $id, name: $name, description: $description, category: $category, iconUrl: $iconUrl, memberCount: $memberCount, postCount: $postCount, isJoined: $isJoined, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterestGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.postCount, postCount) ||
                other.postCount == postCount) &&
            (identical(other.isJoined, isJoined) ||
                other.isJoined == isJoined) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    category,
    iconUrl,
    memberCount,
    postCount,
    isJoined,
    createdAt,
    updatedAt,
  );

  /// Create a copy of InterestGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterestGroupImplCopyWith<_$InterestGroupImpl> get copyWith =>
      __$$InterestGroupImplCopyWithImpl<_$InterestGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InterestGroupImplToJson(this);
  }
}

abstract class _InterestGroup implements InterestGroup {
  const factory _InterestGroup({
    required final String id,
    required final String name,
    required final String description,
    required final String category,
    final String? iconUrl,
    final int memberCount,
    final int postCount,
    final bool isJoined,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$InterestGroupImpl;

  factory _InterestGroup.fromJson(Map<String, dynamic> json) =
      _$InterestGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get category;
  @override
  String? get iconUrl;
  @override
  int get memberCount;
  @override
  int get postCount;
  @override
  bool get isJoined;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of InterestGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterestGroupImplCopyWith<_$InterestGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupMessage _$GroupMessageFromJson(Map<String, dynamic> json) {
  return _GroupMessage.fromJson(json);
}

/// @nodoc
mixin _$GroupMessage {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  String? get userAvatar => throw _privateConstructorUsedError;
  List<String> get attachments => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this GroupMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupMessageCopyWith<GroupMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMessageCopyWith<$Res> {
  factory $GroupMessageCopyWith(
    GroupMessage value,
    $Res Function(GroupMessage) then,
  ) = _$GroupMessageCopyWithImpl<$Res, GroupMessage>;
  @useResult
  $Res call({
    String id,
    String groupId,
    String userId,
    String content,
    String? userName,
    String? userAvatar,
    List<String> attachments,
    int likeCount,
    bool isLiked,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$GroupMessageCopyWithImpl<$Res, $Val extends GroupMessage>
    implements $GroupMessageCopyWith<$Res> {
  _$GroupMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? content = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
    Object? attachments = null,
    Object? likeCount = null,
    Object? isLiked = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            userAvatar: freezed == userAvatar
                ? _value.userAvatar
                : userAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachments: null == attachments
                ? _value.attachments
                : attachments // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isLiked: null == isLiked
                ? _value.isLiked
                : isLiked // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$GroupMessageImplCopyWith<$Res>
    implements $GroupMessageCopyWith<$Res> {
  factory _$$GroupMessageImplCopyWith(
    _$GroupMessageImpl value,
    $Res Function(_$GroupMessageImpl) then,
  ) = __$$GroupMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String groupId,
    String userId,
    String content,
    String? userName,
    String? userAvatar,
    List<String> attachments,
    int likeCount,
    bool isLiked,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$GroupMessageImplCopyWithImpl<$Res>
    extends _$GroupMessageCopyWithImpl<$Res, _$GroupMessageImpl>
    implements _$$GroupMessageImplCopyWith<$Res> {
  __$$GroupMessageImplCopyWithImpl(
    _$GroupMessageImpl _value,
    $Res Function(_$GroupMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? userId = null,
    Object? content = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
    Object? attachments = null,
    Object? likeCount = null,
    Object? isLiked = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$GroupMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        userAvatar: freezed == userAvatar
            ? _value.userAvatar
            : userAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachments: null == attachments
            ? _value._attachments
            : attachments // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isLiked: null == isLiked
            ? _value.isLiked
            : isLiked // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$GroupMessageImpl implements _GroupMessage {
  const _$GroupMessageImpl({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.content,
    this.userName,
    this.userAvatar,
    final List<String> attachments = const [],
    this.likeCount = 0,
    this.isLiked = false,
    this.createdAt,
  }) : _attachments = attachments;

  factory _$GroupMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String userId;
  @override
  final String content;
  @override
  final String? userName;
  @override
  final String? userAvatar;
  final List<String> _attachments;
  @override
  @JsonKey()
  List<String> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'GroupMessage(id: $id, groupId: $groupId, userId: $userId, content: $content, userName: $userName, userAvatar: $userAvatar, attachments: $attachments, likeCount: $likeCount, isLiked: $isLiked, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar) &&
            const DeepCollectionEquality().equals(
              other._attachments,
              _attachments,
            ) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    groupId,
    userId,
    content,
    userName,
    userAvatar,
    const DeepCollectionEquality().hash(_attachments),
    likeCount,
    isLiked,
    createdAt,
  );

  /// Create a copy of GroupMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMessageImplCopyWith<_$GroupMessageImpl> get copyWith =>
      __$$GroupMessageImplCopyWithImpl<_$GroupMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMessageImplToJson(this);
  }
}

abstract class _GroupMessage implements GroupMessage {
  const factory _GroupMessage({
    required final String id,
    required final String groupId,
    required final String userId,
    required final String content,
    final String? userName,
    final String? userAvatar,
    final List<String> attachments,
    final int likeCount,
    final bool isLiked,
    final DateTime? createdAt,
  }) = _$GroupMessageImpl;

  factory _GroupMessage.fromJson(Map<String, dynamic> json) =
      _$GroupMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get userId;
  @override
  String get content;
  @override
  String? get userName;
  @override
  String? get userAvatar;
  @override
  List<String> get attachments;
  @override
  int get likeCount;
  @override
  bool get isLiked;
  @override
  DateTime? get createdAt;

  /// Create a copy of GroupMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupMessageImplCopyWith<_$GroupMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegionalCommunity _$RegionalCommunityFromJson(Map<String, dynamic> json) {
  return _RegionalCommunity.fromJson(json);
}

/// @nodoc
mixin _$RegionalCommunity {
  String get id => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get province => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  int get eventCount => throw _privateConstructorUsedError;
  bool get isJoined => throw _privateConstructorUsedError;
  String? get coverImage => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RegionalCommunity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegionalCommunity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegionalCommunityCopyWith<RegionalCommunity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionalCommunityCopyWith<$Res> {
  factory $RegionalCommunityCopyWith(
    RegionalCommunity value,
    $Res Function(RegionalCommunity) then,
  ) = _$RegionalCommunityCopyWithImpl<$Res, RegionalCommunity>;
  @useResult
  $Res call({
    String id,
    String city,
    String province,
    String? description,
    double? latitude,
    double? longitude,
    int memberCount,
    int eventCount,
    bool isJoined,
    String? coverImage,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$RegionalCommunityCopyWithImpl<$Res, $Val extends RegionalCommunity>
    implements $RegionalCommunityCopyWith<$Res> {
  _$RegionalCommunityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegionalCommunity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? city = null,
    Object? province = null,
    Object? description = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? memberCount = null,
    Object? eventCount = null,
    Object? isJoined = null,
    Object? coverImage = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            province: null == province
                ? _value.province
                : province // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            memberCount: null == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int,
            eventCount: null == eventCount
                ? _value.eventCount
                : eventCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isJoined: null == isJoined
                ? _value.isJoined
                : isJoined // ignore: cast_nullable_to_non_nullable
                      as bool,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
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
abstract class _$$RegionalCommunityImplCopyWith<$Res>
    implements $RegionalCommunityCopyWith<$Res> {
  factory _$$RegionalCommunityImplCopyWith(
    _$RegionalCommunityImpl value,
    $Res Function(_$RegionalCommunityImpl) then,
  ) = __$$RegionalCommunityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String city,
    String province,
    String? description,
    double? latitude,
    double? longitude,
    int memberCount,
    int eventCount,
    bool isJoined,
    String? coverImage,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$RegionalCommunityImplCopyWithImpl<$Res>
    extends _$RegionalCommunityCopyWithImpl<$Res, _$RegionalCommunityImpl>
    implements _$$RegionalCommunityImplCopyWith<$Res> {
  __$$RegionalCommunityImplCopyWithImpl(
    _$RegionalCommunityImpl _value,
    $Res Function(_$RegionalCommunityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegionalCommunity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? city = null,
    Object? province = null,
    Object? description = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? memberCount = null,
    Object? eventCount = null,
    Object? isJoined = null,
    Object? coverImage = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$RegionalCommunityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        province: null == province
            ? _value.province
            : province // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        memberCount: null == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int,
        eventCount: null == eventCount
            ? _value.eventCount
            : eventCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isJoined: null == isJoined
            ? _value.isJoined
            : isJoined // ignore: cast_nullable_to_non_nullable
                  as bool,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
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
class _$RegionalCommunityImpl implements _RegionalCommunity {
  const _$RegionalCommunityImpl({
    required this.id,
    required this.city,
    required this.province,
    this.description,
    this.latitude,
    this.longitude,
    this.memberCount = 0,
    this.eventCount = 0,
    this.isJoined = false,
    this.coverImage,
    this.createdAt,
  });

  factory _$RegionalCommunityImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionalCommunityImplFromJson(json);

  @override
  final String id;
  @override
  final String city;
  @override
  final String province;
  @override
  final String? description;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final int memberCount;
  @override
  @JsonKey()
  final int eventCount;
  @override
  @JsonKey()
  final bool isJoined;
  @override
  final String? coverImage;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RegionalCommunity(id: $id, city: $city, province: $province, description: $description, latitude: $latitude, longitude: $longitude, memberCount: $memberCount, eventCount: $eventCount, isJoined: $isJoined, coverImage: $coverImage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionalCommunityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.province, province) ||
                other.province == province) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.eventCount, eventCount) ||
                other.eventCount == eventCount) &&
            (identical(other.isJoined, isJoined) ||
                other.isJoined == isJoined) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    city,
    province,
    description,
    latitude,
    longitude,
    memberCount,
    eventCount,
    isJoined,
    coverImage,
    createdAt,
  );

  /// Create a copy of RegionalCommunity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionalCommunityImplCopyWith<_$RegionalCommunityImpl> get copyWith =>
      __$$RegionalCommunityImplCopyWithImpl<_$RegionalCommunityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionalCommunityImplToJson(this);
  }
}

abstract class _RegionalCommunity implements RegionalCommunity {
  const factory _RegionalCommunity({
    required final String id,
    required final String city,
    required final String province,
    final String? description,
    final double? latitude,
    final double? longitude,
    final int memberCount,
    final int eventCount,
    final bool isJoined,
    final String? coverImage,
    final DateTime? createdAt,
  }) = _$RegionalCommunityImpl;

  factory _RegionalCommunity.fromJson(Map<String, dynamic> json) =
      _$RegionalCommunityImpl.fromJson;

  @override
  String get id;
  @override
  String get city;
  @override
  String get province;
  @override
  String? get description;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int get memberCount;
  @override
  int get eventCount;
  @override
  bool get isJoined;
  @override
  String? get coverImage;
  @override
  DateTime? get createdAt;

  /// Create a copy of RegionalCommunity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegionalCommunityImplCopyWith<_$RegionalCommunityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommunityEvent _$CommunityEventFromJson(Map<String, dynamic> json) {
  return _CommunityEvent.fromJson(json);
}

/// @nodoc
mixin _$CommunityEvent {
  String get id => throw _privateConstructorUsedError;
  String get communityId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int get participantCount => throw _privateConstructorUsedError;
  int get maxParticipants => throw _privateConstructorUsedError;
  String? get coverImage => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CommunityEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommunityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityEventCopyWith<CommunityEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityEventCopyWith<$Res> {
  factory $CommunityEventCopyWith(
    CommunityEvent value,
    $Res Function(CommunityEvent) then,
  ) = _$CommunityEventCopyWithImpl<$Res, CommunityEvent>;
  @useResult
  $Res call({
    String id,
    String communityId,
    String title,
    String? description,
    DateTime startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    int participantCount,
    int maxParticipants,
    String? coverImage,
    String status,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$CommunityEventCopyWithImpl<$Res, $Val extends CommunityEvent>
    implements $CommunityEventCopyWith<$Res> {
  _$CommunityEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? communityId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? location = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? participantCount = null,
    Object? maxParticipants = null,
    Object? coverImage = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            communityId: null == communityId
                ? _value.communityId
                : communityId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            participantCount: null == participantCount
                ? _value.participantCount
                : participantCount // ignore: cast_nullable_to_non_nullable
                      as int,
            maxParticipants: null == maxParticipants
                ? _value.maxParticipants
                : maxParticipants // ignore: cast_nullable_to_non_nullable
                      as int,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$CommunityEventImplCopyWith<$Res>
    implements $CommunityEventCopyWith<$Res> {
  factory _$$CommunityEventImplCopyWith(
    _$CommunityEventImpl value,
    $Res Function(_$CommunityEventImpl) then,
  ) = __$$CommunityEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String communityId,
    String title,
    String? description,
    DateTime startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    int participantCount,
    int maxParticipants,
    String? coverImage,
    String status,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$CommunityEventImplCopyWithImpl<$Res>
    extends _$CommunityEventCopyWithImpl<$Res, _$CommunityEventImpl>
    implements _$$CommunityEventImplCopyWith<$Res> {
  __$$CommunityEventImplCopyWithImpl(
    _$CommunityEventImpl _value,
    $Res Function(_$CommunityEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? communityId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? location = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? participantCount = null,
    Object? maxParticipants = null,
    Object? coverImage = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CommunityEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        communityId: null == communityId
            ? _value.communityId
            : communityId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        participantCount: null == participantCount
            ? _value.participantCount
            : participantCount // ignore: cast_nullable_to_non_nullable
                  as int,
        maxParticipants: null == maxParticipants
            ? _value.maxParticipants
            : maxParticipants // ignore: cast_nullable_to_non_nullable
                  as int,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$CommunityEventImpl implements _CommunityEvent {
  const _$CommunityEventImpl({
    required this.id,
    required this.communityId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.participantCount = 0,
    this.maxParticipants = 0,
    this.coverImage,
    this.status = 'upcoming',
    this.createdAt,
  });

  factory _$CommunityEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommunityEventImplFromJson(json);

  @override
  final String id;
  @override
  final String communityId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  @override
  final String? location;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final int participantCount;
  @override
  @JsonKey()
  final int maxParticipants;
  @override
  final String? coverImage;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CommunityEvent(id: $id, communityId: $communityId, title: $title, description: $description, startTime: $startTime, endTime: $endTime, location: $location, latitude: $latitude, longitude: $longitude, participantCount: $participantCount, maxParticipants: $maxParticipants, coverImage: $coverImage, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunityEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.communityId, communityId) ||
                other.communityId == communityId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.participantCount, participantCount) ||
                other.participantCount == participantCount) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    communityId,
    title,
    description,
    startTime,
    endTime,
    location,
    latitude,
    longitude,
    participantCount,
    maxParticipants,
    coverImage,
    status,
    createdAt,
  );

  /// Create a copy of CommunityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunityEventImplCopyWith<_$CommunityEventImpl> get copyWith =>
      __$$CommunityEventImplCopyWithImpl<_$CommunityEventImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommunityEventImplToJson(this);
  }
}

abstract class _CommunityEvent implements CommunityEvent {
  const factory _CommunityEvent({
    required final String id,
    required final String communityId,
    required final String title,
    final String? description,
    required final DateTime startTime,
    final DateTime? endTime,
    final String? location,
    final double? latitude,
    final double? longitude,
    final int participantCount,
    final int maxParticipants,
    final String? coverImage,
    final String status,
    final DateTime? createdAt,
  }) = _$CommunityEventImpl;

  factory _CommunityEvent.fromJson(Map<String, dynamic> json) =
      _$CommunityEventImpl.fromJson;

  @override
  String get id;
  @override
  String get communityId;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  String? get location;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int get participantCount;
  @override
  int get maxParticipants;
  @override
  String? get coverImage;
  @override
  String get status;
  @override
  DateTime? get createdAt;

  /// Create a copy of CommunityEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunityEventImplCopyWith<_$CommunityEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeaturedStory _$FeaturedStoryFromJson(Map<String, dynamic> json) {
  return _FeaturedStory.fromJson(json);
}

/// @nodoc
mixin _$FeaturedStory {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  String? get coverImage => throw _privateConstructorUsedError;
  String get authorType => throw _privateConstructorUsedError;
  String? get authorName => throw _privateConstructorUsedError;
  String? get authorAvatar => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get readCount => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get featuredDate => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FeaturedStory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeaturedStory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeaturedStoryCopyWith<FeaturedStory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeaturedStoryCopyWith<$Res> {
  factory $FeaturedStoryCopyWith(
    FeaturedStory value,
    $Res Function(FeaturedStory) then,
  ) = _$FeaturedStoryCopyWithImpl<$Res, FeaturedStory>;
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    String? summary,
    String? coverImage,
    String authorType,
    String? authorName,
    String? authorAvatar,
    int likeCount,
    int readCount,
    bool isLiked,
    String status,
    DateTime? featuredDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$FeaturedStoryCopyWithImpl<$Res, $Val extends FeaturedStory>
    implements $FeaturedStoryCopyWith<$Res> {
  _$FeaturedStoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeaturedStory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? summary = freezed,
    Object? coverImage = freezed,
    Object? authorType = null,
    Object? authorName = freezed,
    Object? authorAvatar = freezed,
    Object? likeCount = null,
    Object? readCount = null,
    Object? isLiked = null,
    Object? status = null,
    Object? featuredDate = freezed,
    Object? createdAt = freezed,
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
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorType: null == authorType
                ? _value.authorType
                : authorType // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: freezed == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorAvatar: freezed == authorAvatar
                ? _value.authorAvatar
                : authorAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            readCount: null == readCount
                ? _value.readCount
                : readCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isLiked: null == isLiked
                ? _value.isLiked
                : isLiked // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            featuredDate: freezed == featuredDate
                ? _value.featuredDate
                : featuredDate // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FeaturedStoryImplCopyWith<$Res>
    implements $FeaturedStoryCopyWith<$Res> {
  factory _$$FeaturedStoryImplCopyWith(
    _$FeaturedStoryImpl value,
    $Res Function(_$FeaturedStoryImpl) then,
  ) = __$$FeaturedStoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String content,
    String? summary,
    String? coverImage,
    String authorType,
    String? authorName,
    String? authorAvatar,
    int likeCount,
    int readCount,
    bool isLiked,
    String status,
    DateTime? featuredDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$FeaturedStoryImplCopyWithImpl<$Res>
    extends _$FeaturedStoryCopyWithImpl<$Res, _$FeaturedStoryImpl>
    implements _$$FeaturedStoryImplCopyWith<$Res> {
  __$$FeaturedStoryImplCopyWithImpl(
    _$FeaturedStoryImpl _value,
    $Res Function(_$FeaturedStoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeaturedStory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? summary = freezed,
    Object? coverImage = freezed,
    Object? authorType = null,
    Object? authorName = freezed,
    Object? authorAvatar = freezed,
    Object? likeCount = null,
    Object? readCount = null,
    Object? isLiked = null,
    Object? status = null,
    Object? featuredDate = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$FeaturedStoryImpl(
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
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorType: null == authorType
            ? _value.authorType
            : authorType // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: freezed == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorAvatar: freezed == authorAvatar
            ? _value.authorAvatar
            : authorAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        readCount: null == readCount
            ? _value.readCount
            : readCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isLiked: null == isLiked
            ? _value.isLiked
            : isLiked // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        featuredDate: freezed == featuredDate
            ? _value.featuredDate
            : featuredDate // ignore: cast_nullable_to_non_nullable
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
class _$FeaturedStoryImpl implements _FeaturedStory {
  const _$FeaturedStoryImpl({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    this.coverImage,
    this.authorType = 'anonymous',
    this.authorName,
    this.authorAvatar,
    this.likeCount = 0,
    this.readCount = 0,
    this.isLiked = false,
    this.status = 'pending',
    this.featuredDate,
    this.createdAt,
    this.updatedAt,
  });

  factory _$FeaturedStoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeaturedStoryImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final String? summary;
  @override
  final String? coverImage;
  @override
  @JsonKey()
  final String authorType;
  @override
  final String? authorName;
  @override
  final String? authorAvatar;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final int readCount;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? featuredDate;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FeaturedStory(id: $id, title: $title, content: $content, summary: $summary, coverImage: $coverImage, authorType: $authorType, authorName: $authorName, authorAvatar: $authorAvatar, likeCount: $likeCount, readCount: $readCount, isLiked: $isLiked, status: $status, featuredDate: $featuredDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeaturedStoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.authorType, authorType) ||
                other.authorType == authorType) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorAvatar, authorAvatar) ||
                other.authorAvatar == authorAvatar) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.readCount, readCount) ||
                other.readCount == readCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.featuredDate, featuredDate) ||
                other.featuredDate == featuredDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
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
    summary,
    coverImage,
    authorType,
    authorName,
    authorAvatar,
    likeCount,
    readCount,
    isLiked,
    status,
    featuredDate,
    createdAt,
    updatedAt,
  );

  /// Create a copy of FeaturedStory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeaturedStoryImplCopyWith<_$FeaturedStoryImpl> get copyWith =>
      __$$FeaturedStoryImplCopyWithImpl<_$FeaturedStoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeaturedStoryImplToJson(this);
  }
}

abstract class _FeaturedStory implements FeaturedStory {
  const factory _FeaturedStory({
    required final String id,
    required final String title,
    required final String content,
    final String? summary,
    final String? coverImage,
    final String authorType,
    final String? authorName,
    final String? authorAvatar,
    final int likeCount,
    final int readCount,
    final bool isLiked,
    final String status,
    final DateTime? featuredDate,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$FeaturedStoryImpl;

  factory _FeaturedStory.fromJson(Map<String, dynamic> json) =
      _$FeaturedStoryImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  String? get summary;
  @override
  String? get coverImage;
  @override
  String get authorType;
  @override
  String? get authorName;
  @override
  String? get authorAvatar;
  @override
  int get likeCount;
  @override
  int get readCount;
  @override
  bool get isLiked;
  @override
  String get status;
  @override
  DateTime? get featuredDate;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of FeaturedStory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeaturedStoryImplCopyWith<_$FeaturedStoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NewbieTraining _$NewbieTrainingFromJson(Map<String, dynamic> json) {
  return _NewbieTraining.fromJson(json);
}

/// @nodoc
mixin _$NewbieTraining {
  String get id => throw _privateConstructorUsedError;
  String get volunteerId => throw _privateConstructorUsedError;
  int get completedScenarios => throw _privateConstructorUsedError;
  int get totalScenarios => throw _privateConstructorUsedError;
  bool get isGraduated => throw _privateConstructorUsedError;
  String? get mentorId => throw _privateConstructorUsedError;
  String? get mentorName => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get graduatedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this NewbieTraining to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NewbieTraining
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NewbieTrainingCopyWith<NewbieTraining> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewbieTrainingCopyWith<$Res> {
  factory $NewbieTrainingCopyWith(
    NewbieTraining value,
    $Res Function(NewbieTraining) then,
  ) = _$NewbieTrainingCopyWithImpl<$Res, NewbieTraining>;
  @useResult
  $Res call({
    String id,
    String volunteerId,
    int completedScenarios,
    int totalScenarios,
    bool isGraduated,
    String? mentorId,
    String? mentorName,
    DateTime? startedAt,
    DateTime? graduatedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$NewbieTrainingCopyWithImpl<$Res, $Val extends NewbieTraining>
    implements $NewbieTrainingCopyWith<$Res> {
  _$NewbieTrainingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NewbieTraining
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? volunteerId = null,
    Object? completedScenarios = null,
    Object? totalScenarios = null,
    Object? isGraduated = null,
    Object? mentorId = freezed,
    Object? mentorName = freezed,
    Object? startedAt = freezed,
    Object? graduatedAt = freezed,
    Object? updatedAt = freezed,
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
            completedScenarios: null == completedScenarios
                ? _value.completedScenarios
                : completedScenarios // ignore: cast_nullable_to_non_nullable
                      as int,
            totalScenarios: null == totalScenarios
                ? _value.totalScenarios
                : totalScenarios // ignore: cast_nullable_to_non_nullable
                      as int,
            isGraduated: null == isGraduated
                ? _value.isGraduated
                : isGraduated // ignore: cast_nullable_to_non_nullable
                      as bool,
            mentorId: freezed == mentorId
                ? _value.mentorId
                : mentorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mentorName: freezed == mentorName
                ? _value.mentorName
                : mentorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            graduatedAt: freezed == graduatedAt
                ? _value.graduatedAt
                : graduatedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$NewbieTrainingImplCopyWith<$Res>
    implements $NewbieTrainingCopyWith<$Res> {
  factory _$$NewbieTrainingImplCopyWith(
    _$NewbieTrainingImpl value,
    $Res Function(_$NewbieTrainingImpl) then,
  ) = __$$NewbieTrainingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String volunteerId,
    int completedScenarios,
    int totalScenarios,
    bool isGraduated,
    String? mentorId,
    String? mentorName,
    DateTime? startedAt,
    DateTime? graduatedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$NewbieTrainingImplCopyWithImpl<$Res>
    extends _$NewbieTrainingCopyWithImpl<$Res, _$NewbieTrainingImpl>
    implements _$$NewbieTrainingImplCopyWith<$Res> {
  __$$NewbieTrainingImplCopyWithImpl(
    _$NewbieTrainingImpl _value,
    $Res Function(_$NewbieTrainingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NewbieTraining
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? volunteerId = null,
    Object? completedScenarios = null,
    Object? totalScenarios = null,
    Object? isGraduated = null,
    Object? mentorId = freezed,
    Object? mentorName = freezed,
    Object? startedAt = freezed,
    Object? graduatedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$NewbieTrainingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteerId: null == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String,
        completedScenarios: null == completedScenarios
            ? _value.completedScenarios
            : completedScenarios // ignore: cast_nullable_to_non_nullable
                  as int,
        totalScenarios: null == totalScenarios
            ? _value.totalScenarios
            : totalScenarios // ignore: cast_nullable_to_non_nullable
                  as int,
        isGraduated: null == isGraduated
            ? _value.isGraduated
            : isGraduated // ignore: cast_nullable_to_non_nullable
                  as bool,
        mentorId: freezed == mentorId
            ? _value.mentorId
            : mentorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mentorName: freezed == mentorName
            ? _value.mentorName
            : mentorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        graduatedAt: freezed == graduatedAt
            ? _value.graduatedAt
            : graduatedAt // ignore: cast_nullable_to_non_nullable
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
class _$NewbieTrainingImpl implements _NewbieTraining {
  const _$NewbieTrainingImpl({
    required this.id,
    required this.volunteerId,
    this.completedScenarios = 0,
    this.totalScenarios = 3,
    this.isGraduated = false,
    this.mentorId,
    this.mentorName,
    this.startedAt,
    this.graduatedAt,
    this.updatedAt,
  });

  factory _$NewbieTrainingImpl.fromJson(Map<String, dynamic> json) =>
      _$$NewbieTrainingImplFromJson(json);

  @override
  final String id;
  @override
  final String volunteerId;
  @override
  @JsonKey()
  final int completedScenarios;
  @override
  @JsonKey()
  final int totalScenarios;
  @override
  @JsonKey()
  final bool isGraduated;
  @override
  final String? mentorId;
  @override
  final String? mentorName;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? graduatedAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'NewbieTraining(id: $id, volunteerId: $volunteerId, completedScenarios: $completedScenarios, totalScenarios: $totalScenarios, isGraduated: $isGraduated, mentorId: $mentorId, mentorName: $mentorName, startedAt: $startedAt, graduatedAt: $graduatedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewbieTrainingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.completedScenarios, completedScenarios) ||
                other.completedScenarios == completedScenarios) &&
            (identical(other.totalScenarios, totalScenarios) ||
                other.totalScenarios == totalScenarios) &&
            (identical(other.isGraduated, isGraduated) ||
                other.isGraduated == isGraduated) &&
            (identical(other.mentorId, mentorId) ||
                other.mentorId == mentorId) &&
            (identical(other.mentorName, mentorName) ||
                other.mentorName == mentorName) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.graduatedAt, graduatedAt) ||
                other.graduatedAt == graduatedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    volunteerId,
    completedScenarios,
    totalScenarios,
    isGraduated,
    mentorId,
    mentorName,
    startedAt,
    graduatedAt,
    updatedAt,
  );

  /// Create a copy of NewbieTraining
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewbieTrainingImplCopyWith<_$NewbieTrainingImpl> get copyWith =>
      __$$NewbieTrainingImplCopyWithImpl<_$NewbieTrainingImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NewbieTrainingImplToJson(this);
  }
}

abstract class _NewbieTraining implements NewbieTraining {
  const factory _NewbieTraining({
    required final String id,
    required final String volunteerId,
    final int completedScenarios,
    final int totalScenarios,
    final bool isGraduated,
    final String? mentorId,
    final String? mentorName,
    final DateTime? startedAt,
    final DateTime? graduatedAt,
    final DateTime? updatedAt,
  }) = _$NewbieTrainingImpl;

  factory _NewbieTraining.fromJson(Map<String, dynamic> json) =
      _$NewbieTrainingImpl.fromJson;

  @override
  String get id;
  @override
  String get volunteerId;
  @override
  int get completedScenarios;
  @override
  int get totalScenarios;
  @override
  bool get isGraduated;
  @override
  String? get mentorId;
  @override
  String? get mentorName;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get graduatedAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of NewbieTraining
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewbieTrainingImplCopyWith<_$NewbieTrainingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainingScenario _$TrainingScenarioFromJson(Map<String, dynamic> json) {
  return _TrainingScenario.fromJson(json);
}

/// @nodoc
mixin _$TrainingScenario {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  List<String> get hints => throw _privateConstructorUsedError;
  List<String> get expectedActions => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this TrainingScenario to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainingScenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainingScenarioCopyWith<TrainingScenario> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingScenarioCopyWith<$Res> {
  factory $TrainingScenarioCopyWith(
    TrainingScenario value,
    $Res Function(TrainingScenario) then,
  ) = _$TrainingScenarioCopyWithImpl<$Res, TrainingScenario>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String type,
    String? imageUrl,
    String? audioUrl,
    List<String> hints,
    List<String> expectedActions,
    bool isCompleted,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$TrainingScenarioCopyWithImpl<$Res, $Val extends TrainingScenario>
    implements $TrainingScenarioCopyWith<$Res> {
  _$TrainingScenarioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainingScenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? hints = null,
    Object? expectedActions = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
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
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            audioUrl: freezed == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            hints: null == hints
                ? _value.hints
                : hints // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            expectedActions: null == expectedActions
                ? _value.expectedActions
                : expectedActions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$TrainingScenarioImplCopyWith<$Res>
    implements $TrainingScenarioCopyWith<$Res> {
  factory _$$TrainingScenarioImplCopyWith(
    _$TrainingScenarioImpl value,
    $Res Function(_$TrainingScenarioImpl) then,
  ) = __$$TrainingScenarioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String type,
    String? imageUrl,
    String? audioUrl,
    List<String> hints,
    List<String> expectedActions,
    bool isCompleted,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$$TrainingScenarioImplCopyWithImpl<$Res>
    extends _$TrainingScenarioCopyWithImpl<$Res, _$TrainingScenarioImpl>
    implements _$$TrainingScenarioImplCopyWith<$Res> {
  __$$TrainingScenarioImplCopyWithImpl(
    _$TrainingScenarioImpl _value,
    $Res Function(_$TrainingScenarioImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrainingScenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? imageUrl = freezed,
    Object? audioUrl = freezed,
    Object? hints = null,
    Object? expectedActions = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$TrainingScenarioImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioUrl: freezed == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        hints: null == hints
            ? _value._hints
            : hints // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        expectedActions: null == expectedActions
            ? _value._expectedActions
            : expectedActions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$TrainingScenarioImpl implements _TrainingScenario {
  const _$TrainingScenarioImpl({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.audioUrl,
    final List<String> hints = const [],
    final List<String> expectedActions = const [],
    this.isCompleted = false,
    this.completedAt,
  }) : _hints = hints,
       _expectedActions = expectedActions;

  factory _$TrainingScenarioImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingScenarioImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String type;
  @override
  final String? imageUrl;
  @override
  final String? audioUrl;
  final List<String> _hints;
  @override
  @JsonKey()
  List<String> get hints {
    if (_hints is EqualUnmodifiableListView) return _hints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hints);
  }

  final List<String> _expectedActions;
  @override
  @JsonKey()
  List<String> get expectedActions {
    if (_expectedActions is EqualUnmodifiableListView) return _expectedActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_expectedActions);
  }

  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'TrainingScenario(id: $id, title: $title, description: $description, type: $type, imageUrl: $imageUrl, audioUrl: $audioUrl, hints: $hints, expectedActions: $expectedActions, isCompleted: $isCompleted, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingScenarioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            const DeepCollectionEquality().equals(other._hints, _hints) &&
            const DeepCollectionEquality().equals(
              other._expectedActions,
              _expectedActions,
            ) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    type,
    imageUrl,
    audioUrl,
    const DeepCollectionEquality().hash(_hints),
    const DeepCollectionEquality().hash(_expectedActions),
    isCompleted,
    completedAt,
  );

  /// Create a copy of TrainingScenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingScenarioImplCopyWith<_$TrainingScenarioImpl> get copyWith =>
      __$$TrainingScenarioImplCopyWithImpl<_$TrainingScenarioImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingScenarioImplToJson(this);
  }
}

abstract class _TrainingScenario implements TrainingScenario {
  const factory _TrainingScenario({
    required final String id,
    required final String title,
    required final String description,
    required final String type,
    final String? imageUrl,
    final String? audioUrl,
    final List<String> hints,
    final List<String> expectedActions,
    final bool isCompleted,
    final DateTime? completedAt,
  }) = _$TrainingScenarioImpl;

  factory _TrainingScenario.fromJson(Map<String, dynamic> json) =
      _$TrainingScenarioImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get type;
  @override
  String? get imageUrl;
  @override
  String? get audioUrl;
  @override
  List<String> get hints;
  @override
  List<String> get expectedActions;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedAt;

  /// Create a copy of TrainingScenario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainingScenarioImplCopyWith<_$TrainingScenarioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModerationResult _$ModerationResultFromJson(Map<String, dynamic> json) {
  return _ModerationResult.fromJson(json);
}

/// @nodoc
mixin _$ModerationResult {
  bool get isApproved => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  List<String> get flaggedKeywords => throw _privateConstructorUsedError;

  /// Serializes this ModerationResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModerationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModerationResultCopyWith<ModerationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModerationResultCopyWith<$Res> {
  factory $ModerationResultCopyWith(
    ModerationResult value,
    $Res Function(ModerationResult) then,
  ) = _$ModerationResultCopyWithImpl<$Res, ModerationResult>;
  @useResult
  $Res call({
    bool isApproved,
    double confidence,
    String? category,
    String? reason,
    List<String> flaggedKeywords,
  });
}

/// @nodoc
class _$ModerationResultCopyWithImpl<$Res, $Val extends ModerationResult>
    implements $ModerationResultCopyWith<$Res> {
  _$ModerationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModerationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isApproved = null,
    Object? confidence = null,
    Object? category = freezed,
    Object? reason = freezed,
    Object? flaggedKeywords = null,
  }) {
    return _then(
      _value.copyWith(
            isApproved: null == isApproved
                ? _value.isApproved
                : isApproved // ignore: cast_nullable_to_non_nullable
                      as bool,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            flaggedKeywords: null == flaggedKeywords
                ? _value.flaggedKeywords
                : flaggedKeywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModerationResultImplCopyWith<$Res>
    implements $ModerationResultCopyWith<$Res> {
  factory _$$ModerationResultImplCopyWith(
    _$ModerationResultImpl value,
    $Res Function(_$ModerationResultImpl) then,
  ) = __$$ModerationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isApproved,
    double confidence,
    String? category,
    String? reason,
    List<String> flaggedKeywords,
  });
}

/// @nodoc
class __$$ModerationResultImplCopyWithImpl<$Res>
    extends _$ModerationResultCopyWithImpl<$Res, _$ModerationResultImpl>
    implements _$$ModerationResultImplCopyWith<$Res> {
  __$$ModerationResultImplCopyWithImpl(
    _$ModerationResultImpl _value,
    $Res Function(_$ModerationResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModerationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isApproved = null,
    Object? confidence = null,
    Object? category = freezed,
    Object? reason = freezed,
    Object? flaggedKeywords = null,
  }) {
    return _then(
      _$ModerationResultImpl(
        isApproved: null == isApproved
            ? _value.isApproved
            : isApproved // ignore: cast_nullable_to_non_nullable
                  as bool,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        flaggedKeywords: null == flaggedKeywords
            ? _value._flaggedKeywords
            : flaggedKeywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModerationResultImpl implements _ModerationResult {
  const _$ModerationResultImpl({
    required this.isApproved,
    required this.confidence,
    this.category,
    this.reason,
    final List<String> flaggedKeywords = const [],
  }) : _flaggedKeywords = flaggedKeywords;

  factory _$ModerationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModerationResultImplFromJson(json);

  @override
  final bool isApproved;
  @override
  final double confidence;
  @override
  final String? category;
  @override
  final String? reason;
  final List<String> _flaggedKeywords;
  @override
  @JsonKey()
  List<String> get flaggedKeywords {
    if (_flaggedKeywords is EqualUnmodifiableListView) return _flaggedKeywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_flaggedKeywords);
  }

  @override
  String toString() {
    return 'ModerationResult(isApproved: $isApproved, confidence: $confidence, category: $category, reason: $reason, flaggedKeywords: $flaggedKeywords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModerationResultImpl &&
            (identical(other.isApproved, isApproved) ||
                other.isApproved == isApproved) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            const DeepCollectionEquality().equals(
              other._flaggedKeywords,
              _flaggedKeywords,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isApproved,
    confidence,
    category,
    reason,
    const DeepCollectionEquality().hash(_flaggedKeywords),
  );

  /// Create a copy of ModerationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModerationResultImplCopyWith<_$ModerationResultImpl> get copyWith =>
      __$$ModerationResultImplCopyWithImpl<_$ModerationResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ModerationResultImplToJson(this);
  }
}

abstract class _ModerationResult implements ModerationResult {
  const factory _ModerationResult({
    required final bool isApproved,
    required final double confidence,
    final String? category,
    final String? reason,
    final List<String> flaggedKeywords,
  }) = _$ModerationResultImpl;

  factory _ModerationResult.fromJson(Map<String, dynamic> json) =
      _$ModerationResultImpl.fromJson;

  @override
  bool get isApproved;
  @override
  double get confidence;
  @override
  String? get category;
  @override
  String? get reason;
  @override
  List<String> get flaggedKeywords;

  /// Create a copy of ModerationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModerationResultImplCopyWith<_$ModerationResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
