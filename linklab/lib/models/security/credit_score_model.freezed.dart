// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_score_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreditScore _$CreditScoreFromJson(Map<String, dynamic> json) {
  return _CreditScore.fromJson(json);
}

/// @nodoc
mixin _$CreditScore {
  String get userId => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  int get totalRatings => throw _privateConstructorUsedError;
  int get positiveRatings => throw _privateConstructorUsedError;
  int get negativeRatings => throw _privateConstructorUsedError;
  int get consecutiveGoodRatings => throw _privateConstructorUsedError;
  DateTime? get lastRatingAt => throw _privateConstructorUsedError;
  DateTime? get lastViolationAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CreditScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreditScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreditScoreCopyWith<CreditScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreditScoreCopyWith<$Res> {
  factory $CreditScoreCopyWith(
    CreditScore value,
    $Res Function(CreditScore) then,
  ) = _$CreditScoreCopyWithImpl<$Res, CreditScore>;
  @useResult
  $Res call({
    String userId,
    double score,
    int totalRatings,
    int positiveRatings,
    int negativeRatings,
    int consecutiveGoodRatings,
    DateTime? lastRatingAt,
    DateTime? lastViolationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$CreditScoreCopyWithImpl<$Res, $Val extends CreditScore>
    implements $CreditScoreCopyWith<$Res> {
  _$CreditScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreditScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? score = null,
    Object? totalRatings = null,
    Object? positiveRatings = null,
    Object? negativeRatings = null,
    Object? consecutiveGoodRatings = null,
    Object? lastRatingAt = freezed,
    Object? lastViolationAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
            totalRatings: null == totalRatings
                ? _value.totalRatings
                : totalRatings // ignore: cast_nullable_to_non_nullable
                      as int,
            positiveRatings: null == positiveRatings
                ? _value.positiveRatings
                : positiveRatings // ignore: cast_nullable_to_non_nullable
                      as int,
            negativeRatings: null == negativeRatings
                ? _value.negativeRatings
                : negativeRatings // ignore: cast_nullable_to_non_nullable
                      as int,
            consecutiveGoodRatings: null == consecutiveGoodRatings
                ? _value.consecutiveGoodRatings
                : consecutiveGoodRatings // ignore: cast_nullable_to_non_nullable
                      as int,
            lastRatingAt: freezed == lastRatingAt
                ? _value.lastRatingAt
                : lastRatingAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastViolationAt: freezed == lastViolationAt
                ? _value.lastViolationAt
                : lastViolationAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CreditScoreImplCopyWith<$Res>
    implements $CreditScoreCopyWith<$Res> {
  factory _$$CreditScoreImplCopyWith(
    _$CreditScoreImpl value,
    $Res Function(_$CreditScoreImpl) then,
  ) = __$$CreditScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    double score,
    int totalRatings,
    int positiveRatings,
    int negativeRatings,
    int consecutiveGoodRatings,
    DateTime? lastRatingAt,
    DateTime? lastViolationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CreditScoreImplCopyWithImpl<$Res>
    extends _$CreditScoreCopyWithImpl<$Res, _$CreditScoreImpl>
    implements _$$CreditScoreImplCopyWith<$Res> {
  __$$CreditScoreImplCopyWithImpl(
    _$CreditScoreImpl _value,
    $Res Function(_$CreditScoreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreditScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? score = null,
    Object? totalRatings = null,
    Object? positiveRatings = null,
    Object? negativeRatings = null,
    Object? consecutiveGoodRatings = null,
    Object? lastRatingAt = freezed,
    Object? lastViolationAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CreditScoreImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
        totalRatings: null == totalRatings
            ? _value.totalRatings
            : totalRatings // ignore: cast_nullable_to_non_nullable
                  as int,
        positiveRatings: null == positiveRatings
            ? _value.positiveRatings
            : positiveRatings // ignore: cast_nullable_to_non_nullable
                  as int,
        negativeRatings: null == negativeRatings
            ? _value.negativeRatings
            : negativeRatings // ignore: cast_nullable_to_non_nullable
                  as int,
        consecutiveGoodRatings: null == consecutiveGoodRatings
            ? _value.consecutiveGoodRatings
            : consecutiveGoodRatings // ignore: cast_nullable_to_non_nullable
                  as int,
        lastRatingAt: freezed == lastRatingAt
            ? _value.lastRatingAt
            : lastRatingAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastViolationAt: freezed == lastViolationAt
            ? _value.lastViolationAt
            : lastViolationAt // ignore: cast_nullable_to_non_nullable
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
class _$CreditScoreImpl extends _CreditScore {
  const _$CreditScoreImpl({
    required this.userId,
    this.score = 5.0,
    this.totalRatings = 0,
    this.positiveRatings = 0,
    this.negativeRatings = 0,
    this.consecutiveGoodRatings = 0,
    this.lastRatingAt,
    this.lastViolationAt,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$CreditScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreditScoreImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final double score;
  @override
  @JsonKey()
  final int totalRatings;
  @override
  @JsonKey()
  final int positiveRatings;
  @override
  @JsonKey()
  final int negativeRatings;
  @override
  @JsonKey()
  final int consecutiveGoodRatings;
  @override
  final DateTime? lastRatingAt;
  @override
  final DateTime? lastViolationAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CreditScore(userId: $userId, score: $score, totalRatings: $totalRatings, positiveRatings: $positiveRatings, negativeRatings: $negativeRatings, consecutiveGoodRatings: $consecutiveGoodRatings, lastRatingAt: $lastRatingAt, lastViolationAt: $lastViolationAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreditScoreImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.totalRatings, totalRatings) ||
                other.totalRatings == totalRatings) &&
            (identical(other.positiveRatings, positiveRatings) ||
                other.positiveRatings == positiveRatings) &&
            (identical(other.negativeRatings, negativeRatings) ||
                other.negativeRatings == negativeRatings) &&
            (identical(other.consecutiveGoodRatings, consecutiveGoodRatings) ||
                other.consecutiveGoodRatings == consecutiveGoodRatings) &&
            (identical(other.lastRatingAt, lastRatingAt) ||
                other.lastRatingAt == lastRatingAt) &&
            (identical(other.lastViolationAt, lastViolationAt) ||
                other.lastViolationAt == lastViolationAt) &&
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
    score,
    totalRatings,
    positiveRatings,
    negativeRatings,
    consecutiveGoodRatings,
    lastRatingAt,
    lastViolationAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CreditScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreditScoreImplCopyWith<_$CreditScoreImpl> get copyWith =>
      __$$CreditScoreImplCopyWithImpl<_$CreditScoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreditScoreImplToJson(this);
  }
}

abstract class _CreditScore extends CreditScore {
  const factory _CreditScore({
    required final String userId,
    final double score,
    final int totalRatings,
    final int positiveRatings,
    final int negativeRatings,
    final int consecutiveGoodRatings,
    final DateTime? lastRatingAt,
    final DateTime? lastViolationAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$CreditScoreImpl;
  const _CreditScore._() : super._();

  factory _CreditScore.fromJson(Map<String, dynamic> json) =
      _$CreditScoreImpl.fromJson;

  @override
  String get userId;
  @override
  double get score;
  @override
  int get totalRatings;
  @override
  int get positiveRatings;
  @override
  int get negativeRatings;
  @override
  int get consecutiveGoodRatings;
  @override
  DateTime? get lastRatingAt;
  @override
  DateTime? get lastViolationAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CreditScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreditScoreImplCopyWith<_$CreditScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RatingRecord _$RatingRecordFromJson(Map<String, dynamic> json) {
  return _RatingRecord.fromJson(json);
}

/// @nodoc
mixin _$RatingRecord {
  String get id => throw _privateConstructorUsedError;
  String get callId => throw _privateConstructorUsedError;
  String get helpRequestId => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError; // 1-5星
  String? get comment => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  bool get isSeekerToVolunteer => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RatingRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RatingRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatingRecordCopyWith<RatingRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatingRecordCopyWith<$Res> {
  factory $RatingRecordCopyWith(
    RatingRecord value,
    $Res Function(RatingRecord) then,
  ) = _$RatingRecordCopyWithImpl<$Res, RatingRecord>;
  @useResult
  $Res call({
    String id,
    String callId,
    String helpRequestId,
    String fromUserId,
    String toUserId,
    int rating,
    String? comment,
    List<String> tags,
    bool isSeekerToVolunteer,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$RatingRecordCopyWithImpl<$Res, $Val extends RatingRecord>
    implements $RatingRecordCopyWith<$Res> {
  _$RatingRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RatingRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? callId = null,
    Object? helpRequestId = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? tags = null,
    Object? isSeekerToVolunteer = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            callId: null == callId
                ? _value.callId
                : callId // ignore: cast_nullable_to_non_nullable
                      as String,
            helpRequestId: null == helpRequestId
                ? _value.helpRequestId
                : helpRequestId // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as int,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isSeekerToVolunteer: null == isSeekerToVolunteer
                ? _value.isSeekerToVolunteer
                : isSeekerToVolunteer // ignore: cast_nullable_to_non_nullable
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
abstract class _$$RatingRecordImplCopyWith<$Res>
    implements $RatingRecordCopyWith<$Res> {
  factory _$$RatingRecordImplCopyWith(
    _$RatingRecordImpl value,
    $Res Function(_$RatingRecordImpl) then,
  ) = __$$RatingRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String callId,
    String helpRequestId,
    String fromUserId,
    String toUserId,
    int rating,
    String? comment,
    List<String> tags,
    bool isSeekerToVolunteer,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$RatingRecordImplCopyWithImpl<$Res>
    extends _$RatingRecordCopyWithImpl<$Res, _$RatingRecordImpl>
    implements _$$RatingRecordImplCopyWith<$Res> {
  __$$RatingRecordImplCopyWithImpl(
    _$RatingRecordImpl _value,
    $Res Function(_$RatingRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RatingRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? callId = null,
    Object? helpRequestId = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? tags = null,
    Object? isSeekerToVolunteer = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$RatingRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        callId: null == callId
            ? _value.callId
            : callId // ignore: cast_nullable_to_non_nullable
                  as String,
        helpRequestId: null == helpRequestId
            ? _value.helpRequestId
            : helpRequestId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as int,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isSeekerToVolunteer: null == isSeekerToVolunteer
            ? _value.isSeekerToVolunteer
            : isSeekerToVolunteer // ignore: cast_nullable_to_non_nullable
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
class _$RatingRecordImpl extends _RatingRecord {
  const _$RatingRecordImpl({
    required this.id,
    required this.callId,
    required this.helpRequestId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    final List<String> tags = const [],
    this.isSeekerToVolunteer = false,
    this.createdAt,
  }) : _tags = tags,
       super._();

  factory _$RatingRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatingRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String callId;
  @override
  final String helpRequestId;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  final int rating;
  // 1-5星
  @override
  final String? comment;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool isSeekerToVolunteer;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RatingRecord(id: $id, callId: $callId, helpRequestId: $helpRequestId, fromUserId: $fromUserId, toUserId: $toUserId, rating: $rating, comment: $comment, tags: $tags, isSeekerToVolunteer: $isSeekerToVolunteer, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatingRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.callId, callId) || other.callId == callId) &&
            (identical(other.helpRequestId, helpRequestId) ||
                other.helpRequestId == helpRequestId) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isSeekerToVolunteer, isSeekerToVolunteer) ||
                other.isSeekerToVolunteer == isSeekerToVolunteer) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    callId,
    helpRequestId,
    fromUserId,
    toUserId,
    rating,
    comment,
    const DeepCollectionEquality().hash(_tags),
    isSeekerToVolunteer,
    createdAt,
  );

  /// Create a copy of RatingRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatingRecordImplCopyWith<_$RatingRecordImpl> get copyWith =>
      __$$RatingRecordImplCopyWithImpl<_$RatingRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatingRecordImplToJson(this);
  }
}

abstract class _RatingRecord extends RatingRecord {
  const factory _RatingRecord({
    required final String id,
    required final String callId,
    required final String helpRequestId,
    required final String fromUserId,
    required final String toUserId,
    required final int rating,
    final String? comment,
    final List<String> tags,
    final bool isSeekerToVolunteer,
    final DateTime? createdAt,
  }) = _$RatingRecordImpl;
  const _RatingRecord._() : super._();

  factory _RatingRecord.fromJson(Map<String, dynamic> json) =
      _$RatingRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get callId;
  @override
  String get helpRequestId;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  int get rating; // 1-5星
  @override
  String? get comment;
  @override
  List<String> get tags;
  @override
  bool get isSeekerToVolunteer;
  @override
  DateTime? get createdAt;

  /// Create a copy of RatingRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatingRecordImplCopyWith<_$RatingRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreditScoreChange _$CreditScoreChangeFromJson(Map<String, dynamic> json) {
  return _CreditScoreChange.fromJson(json);
}

/// @nodoc
mixin _$CreditScoreChange {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get change => throw _privateConstructorUsedError;
  double get scoreBefore => throw _privateConstructorUsedError;
  double get scoreAfter => throw _privateConstructorUsedError;
  CreditChangeReason get reason => throw _privateConstructorUsedError;
  String? get relatedId => throw _privateConstructorUsedError; // 关联的评价ID或举报ID
  String? get description => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CreditScoreChange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreditScoreChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreditScoreChangeCopyWith<CreditScoreChange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreditScoreChangeCopyWith<$Res> {
  factory $CreditScoreChangeCopyWith(
    CreditScoreChange value,
    $Res Function(CreditScoreChange) then,
  ) = _$CreditScoreChangeCopyWithImpl<$Res, CreditScoreChange>;
  @useResult
  $Res call({
    String id,
    String userId,
    double change,
    double scoreBefore,
    double scoreAfter,
    CreditChangeReason reason,
    String? relatedId,
    String? description,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$CreditScoreChangeCopyWithImpl<$Res, $Val extends CreditScoreChange>
    implements $CreditScoreChangeCopyWith<$Res> {
  _$CreditScoreChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreditScoreChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? change = null,
    Object? scoreBefore = null,
    Object? scoreAfter = null,
    Object? reason = null,
    Object? relatedId = freezed,
    Object? description = freezed,
    Object? createdAt = freezed,
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
            change: null == change
                ? _value.change
                : change // ignore: cast_nullable_to_non_nullable
                      as double,
            scoreBefore: null == scoreBefore
                ? _value.scoreBefore
                : scoreBefore // ignore: cast_nullable_to_non_nullable
                      as double,
            scoreAfter: null == scoreAfter
                ? _value.scoreAfter
                : scoreAfter // ignore: cast_nullable_to_non_nullable
                      as double,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as CreditChangeReason,
            relatedId: freezed == relatedId
                ? _value.relatedId
                : relatedId // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CreditScoreChangeImplCopyWith<$Res>
    implements $CreditScoreChangeCopyWith<$Res> {
  factory _$$CreditScoreChangeImplCopyWith(
    _$CreditScoreChangeImpl value,
    $Res Function(_$CreditScoreChangeImpl) then,
  ) = __$$CreditScoreChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    double change,
    double scoreBefore,
    double scoreAfter,
    CreditChangeReason reason,
    String? relatedId,
    String? description,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$CreditScoreChangeImplCopyWithImpl<$Res>
    extends _$CreditScoreChangeCopyWithImpl<$Res, _$CreditScoreChangeImpl>
    implements _$$CreditScoreChangeImplCopyWith<$Res> {
  __$$CreditScoreChangeImplCopyWithImpl(
    _$CreditScoreChangeImpl _value,
    $Res Function(_$CreditScoreChangeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreditScoreChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? change = null,
    Object? scoreBefore = null,
    Object? scoreAfter = null,
    Object? reason = null,
    Object? relatedId = freezed,
    Object? description = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CreditScoreChangeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        change: null == change
            ? _value.change
            : change // ignore: cast_nullable_to_non_nullable
                  as double,
        scoreBefore: null == scoreBefore
            ? _value.scoreBefore
            : scoreBefore // ignore: cast_nullable_to_non_nullable
                  as double,
        scoreAfter: null == scoreAfter
            ? _value.scoreAfter
            : scoreAfter // ignore: cast_nullable_to_non_nullable
                  as double,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as CreditChangeReason,
        relatedId: freezed == relatedId
            ? _value.relatedId
            : relatedId // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
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
class _$CreditScoreChangeImpl implements _CreditScoreChange {
  const _$CreditScoreChangeImpl({
    required this.id,
    required this.userId,
    required this.change,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.reason,
    this.relatedId,
    this.description,
    this.createdAt,
  });

  factory _$CreditScoreChangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreditScoreChangeImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final double change;
  @override
  final double scoreBefore;
  @override
  final double scoreAfter;
  @override
  final CreditChangeReason reason;
  @override
  final String? relatedId;
  // 关联的评价ID或举报ID
  @override
  final String? description;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CreditScoreChange(id: $id, userId: $userId, change: $change, scoreBefore: $scoreBefore, scoreAfter: $scoreAfter, reason: $reason, relatedId: $relatedId, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreditScoreChangeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.scoreBefore, scoreBefore) ||
                other.scoreBefore == scoreBefore) &&
            (identical(other.scoreAfter, scoreAfter) ||
                other.scoreAfter == scoreAfter) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.relatedId, relatedId) ||
                other.relatedId == relatedId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    change,
    scoreBefore,
    scoreAfter,
    reason,
    relatedId,
    description,
    createdAt,
  );

  /// Create a copy of CreditScoreChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreditScoreChangeImplCopyWith<_$CreditScoreChangeImpl> get copyWith =>
      __$$CreditScoreChangeImplCopyWithImpl<_$CreditScoreChangeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreditScoreChangeImplToJson(this);
  }
}

abstract class _CreditScoreChange implements CreditScoreChange {
  const factory _CreditScoreChange({
    required final String id,
    required final String userId,
    required final double change,
    required final double scoreBefore,
    required final double scoreAfter,
    required final CreditChangeReason reason,
    final String? relatedId,
    final String? description,
    final DateTime? createdAt,
  }) = _$CreditScoreChangeImpl;

  factory _CreditScoreChange.fromJson(Map<String, dynamic> json) =
      _$CreditScoreChangeImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  double get change;
  @override
  double get scoreBefore;
  @override
  double get scoreAfter;
  @override
  CreditChangeReason get reason;
  @override
  String? get relatedId; // 关联的评价ID或举报ID
  @override
  String? get description;
  @override
  DateTime? get createdAt;

  /// Create a copy of CreditScoreChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreditScoreChangeImplCopyWith<_$CreditScoreChangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
