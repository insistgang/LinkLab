// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Report _$ReportFromJson(Map<String, dynamic> json) {
  return _Report.fromJson(json);
}

/// @nodoc
mixin _$Report {
  String get id => throw _privateConstructorUsedError;
  String get reporterId => throw _privateConstructorUsedError;
  String get reportedId => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get evidenceUrls => throw _privateConstructorUsedError;
  String? get callId => throw _privateConstructorUsedError;
  String? get helpRequestId => throw _privateConstructorUsedError;
  ReportStatus get status => throw _privateConstructorUsedError;
  ReportDecision? get decision => throw _privateConstructorUsedError;
  String? get reviewerId => throw _privateConstructorUsedError;
  String? get reviewNote => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Report to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportCopyWith<Report> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportCopyWith<$Res> {
  factory $ReportCopyWith(Report value, $Res Function(Report) then) =
      _$ReportCopyWithImpl<$Res, Report>;
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reportedId,
    String reason,
    String? description,
    List<String> evidenceUrls,
    String? callId,
    String? helpRequestId,
    ReportStatus status,
    ReportDecision? decision,
    String? reviewerId,
    String? reviewNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$ReportCopyWithImpl<$Res, $Val extends Report>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reportedId = null,
    Object? reason = null,
    Object? description = freezed,
    Object? evidenceUrls = null,
    Object? callId = freezed,
    Object? helpRequestId = freezed,
    Object? status = null,
    Object? decision = freezed,
    Object? reviewerId = freezed,
    Object? reviewNote = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? createdAt = freezed,
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
            reportedId: null == reportedId
                ? _value.reportedId
                : reportedId // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            evidenceUrls: null == evidenceUrls
                ? _value.evidenceUrls
                : evidenceUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            callId: freezed == callId
                ? _value.callId
                : callId // ignore: cast_nullable_to_non_nullable
                      as String?,
            helpRequestId: freezed == helpRequestId
                ? _value.helpRequestId
                : helpRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ReportStatus,
            decision: freezed == decision
                ? _value.decision
                : decision // ignore: cast_nullable_to_non_nullable
                      as ReportDecision?,
            reviewerId: freezed == reviewerId
                ? _value.reviewerId
                : reviewerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            reviewNote: freezed == reviewNote
                ? _value.reviewNote
                : reviewNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            submittedAt: freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reviewedAt: freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ReportImplCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$$ReportImplCopyWith(
    _$ReportImpl value,
    $Res Function(_$ReportImpl) then,
  ) = __$$ReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reporterId,
    String reportedId,
    String reason,
    String? description,
    List<String> evidenceUrls,
    String? callId,
    String? helpRequestId,
    ReportStatus status,
    ReportDecision? decision,
    String? reviewerId,
    String? reviewNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$ReportImplCopyWithImpl<$Res>
    extends _$ReportCopyWithImpl<$Res, _$ReportImpl>
    implements _$$ReportImplCopyWith<$Res> {
  __$$ReportImplCopyWithImpl(
    _$ReportImpl _value,
    $Res Function(_$ReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reporterId = null,
    Object? reportedId = null,
    Object? reason = null,
    Object? description = freezed,
    Object? evidenceUrls = null,
    Object? callId = freezed,
    Object? helpRequestId = freezed,
    Object? status = null,
    Object? decision = freezed,
    Object? reviewerId = freezed,
    Object? reviewNote = freezed,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ReportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reporterId: null == reporterId
            ? _value.reporterId
            : reporterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reportedId: null == reportedId
            ? _value.reportedId
            : reportedId // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        evidenceUrls: null == evidenceUrls
            ? _value._evidenceUrls
            : evidenceUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        callId: freezed == callId
            ? _value.callId
            : callId // ignore: cast_nullable_to_non_nullable
                  as String?,
        helpRequestId: freezed == helpRequestId
            ? _value.helpRequestId
            : helpRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ReportStatus,
        decision: freezed == decision
            ? _value.decision
            : decision // ignore: cast_nullable_to_non_nullable
                  as ReportDecision?,
        reviewerId: freezed == reviewerId
            ? _value.reviewerId
            : reviewerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        reviewNote: freezed == reviewNote
            ? _value.reviewNote
            : reviewNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        submittedAt: freezed == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reviewedAt: freezed == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
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
class _$ReportImpl extends _Report {
  const _$ReportImpl({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    this.description,
    final List<String> evidenceUrls = const [],
    this.callId,
    this.helpRequestId,
    this.status = ReportStatus.pending,
    this.decision,
    this.reviewerId,
    this.reviewNote,
    this.submittedAt,
    this.reviewedAt,
    this.createdAt,
  }) : _evidenceUrls = evidenceUrls,
       super._();

  factory _$ReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportImplFromJson(json);

  @override
  final String id;
  @override
  final String reporterId;
  @override
  final String reportedId;
  @override
  final String reason;
  @override
  final String? description;
  final List<String> _evidenceUrls;
  @override
  @JsonKey()
  List<String> get evidenceUrls {
    if (_evidenceUrls is EqualUnmodifiableListView) return _evidenceUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_evidenceUrls);
  }

  @override
  final String? callId;
  @override
  final String? helpRequestId;
  @override
  @JsonKey()
  final ReportStatus status;
  @override
  final ReportDecision? decision;
  @override
  final String? reviewerId;
  @override
  final String? reviewNote;
  @override
  final DateTime? submittedAt;
  @override
  final DateTime? reviewedAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Report(id: $id, reporterId: $reporterId, reportedId: $reportedId, reason: $reason, description: $description, evidenceUrls: $evidenceUrls, callId: $callId, helpRequestId: $helpRequestId, status: $status, decision: $decision, reviewerId: $reviewerId, reviewNote: $reviewNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reporterId, reporterId) ||
                other.reporterId == reporterId) &&
            (identical(other.reportedId, reportedId) ||
                other.reportedId == reportedId) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._evidenceUrls,
              _evidenceUrls,
            ) &&
            (identical(other.callId, callId) || other.callId == callId) &&
            (identical(other.helpRequestId, helpRequestId) ||
                other.helpRequestId == helpRequestId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.decision, decision) ||
                other.decision == decision) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.reviewNote, reviewNote) ||
                other.reviewNote == reviewNote) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reporterId,
    reportedId,
    reason,
    description,
    const DeepCollectionEquality().hash(_evidenceUrls),
    callId,
    helpRequestId,
    status,
    decision,
    reviewerId,
    reviewNote,
    submittedAt,
    reviewedAt,
    createdAt,
  );

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      __$$ReportImplCopyWithImpl<_$ReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportImplToJson(this);
  }
}

abstract class _Report extends Report {
  const factory _Report({
    required final String id,
    required final String reporterId,
    required final String reportedId,
    required final String reason,
    final String? description,
    final List<String> evidenceUrls,
    final String? callId,
    final String? helpRequestId,
    final ReportStatus status,
    final ReportDecision? decision,
    final String? reviewerId,
    final String? reviewNote,
    final DateTime? submittedAt,
    final DateTime? reviewedAt,
    final DateTime? createdAt,
  }) = _$ReportImpl;
  const _Report._() : super._();

  factory _Report.fromJson(Map<String, dynamic> json) = _$ReportImpl.fromJson;

  @override
  String get id;
  @override
  String get reporterId;
  @override
  String get reportedId;
  @override
  String get reason;
  @override
  String? get description;
  @override
  List<String> get evidenceUrls;
  @override
  String? get callId;
  @override
  String? get helpRequestId;
  @override
  ReportStatus get status;
  @override
  ReportDecision? get decision;
  @override
  String? get reviewerId;
  @override
  String? get reviewNote;
  @override
  DateTime? get submittedAt;
  @override
  DateTime? get reviewedAt;
  @override
  DateTime? get createdAt;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BlacklistEntry _$BlacklistEntryFromJson(Map<String, dynamic> json) {
  return _BlacklistEntry.fromJson(json);
}

/// @nodoc
mixin _$BlacklistEntry {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  BlacklistLevel get level => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get evidence => throw _privateConstructorUsedError;
  String? get deviceFingerprint => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BlacklistEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BlacklistEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BlacklistEntryCopyWith<BlacklistEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlacklistEntryCopyWith<$Res> {
  factory $BlacklistEntryCopyWith(
    BlacklistEntry value,
    $Res Function(BlacklistEntry) then,
  ) = _$BlacklistEntryCopyWithImpl<$Res, BlacklistEntry>;
  @useResult
  $Res call({
    String id,
    String userId,
    BlacklistLevel level,
    String reason,
    String? evidence,
    String? deviceFingerprint,
    String? ipAddress,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$BlacklistEntryCopyWithImpl<$Res, $Val extends BlacklistEntry>
    implements $BlacklistEntryCopyWith<$Res> {
  _$BlacklistEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BlacklistEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? level = null,
    Object? reason = null,
    Object? evidence = freezed,
    Object? deviceFingerprint = freezed,
    Object? ipAddress = freezed,
    Object? expiresAt = freezed,
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
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as BlacklistLevel,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            evidence: freezed == evidence
                ? _value.evidence
                : evidence // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceFingerprint: freezed == deviceFingerprint
                ? _value.deviceFingerprint
                : deviceFingerprint // ignore: cast_nullable_to_non_nullable
                      as String?,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BlacklistEntryImplCopyWith<$Res>
    implements $BlacklistEntryCopyWith<$Res> {
  factory _$$BlacklistEntryImplCopyWith(
    _$BlacklistEntryImpl value,
    $Res Function(_$BlacklistEntryImpl) then,
  ) = __$$BlacklistEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    BlacklistLevel level,
    String reason,
    String? evidence,
    String? deviceFingerprint,
    String? ipAddress,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$BlacklistEntryImplCopyWithImpl<$Res>
    extends _$BlacklistEntryCopyWithImpl<$Res, _$BlacklistEntryImpl>
    implements _$$BlacklistEntryImplCopyWith<$Res> {
  __$$BlacklistEntryImplCopyWithImpl(
    _$BlacklistEntryImpl _value,
    $Res Function(_$BlacklistEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BlacklistEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? level = null,
    Object? reason = null,
    Object? evidence = freezed,
    Object? deviceFingerprint = freezed,
    Object? ipAddress = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$BlacklistEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as BlacklistLevel,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        evidence: freezed == evidence
            ? _value.evidence
            : evidence // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceFingerprint: freezed == deviceFingerprint
            ? _value.deviceFingerprint
            : deviceFingerprint // ignore: cast_nullable_to_non_nullable
                  as String?,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
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
class _$BlacklistEntryImpl extends _BlacklistEntry {
  const _$BlacklistEntryImpl({
    required this.id,
    required this.userId,
    required this.level,
    required this.reason,
    this.evidence,
    this.deviceFingerprint,
    this.ipAddress,
    this.expiresAt,
    this.createdAt,
  }) : super._();

  factory _$BlacklistEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$BlacklistEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final BlacklistLevel level;
  @override
  final String reason;
  @override
  final String? evidence;
  @override
  final String? deviceFingerprint;
  @override
  final String? ipAddress;
  @override
  final DateTime? expiresAt;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'BlacklistEntry(id: $id, userId: $userId, level: $level, reason: $reason, evidence: $evidence, deviceFingerprint: $deviceFingerprint, ipAddress: $ipAddress, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BlacklistEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.evidence, evidence) ||
                other.evidence == evidence) &&
            (identical(other.deviceFingerprint, deviceFingerprint) ||
                other.deviceFingerprint == deviceFingerprint) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    level,
    reason,
    evidence,
    deviceFingerprint,
    ipAddress,
    expiresAt,
    createdAt,
  );

  /// Create a copy of BlacklistEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BlacklistEntryImplCopyWith<_$BlacklistEntryImpl> get copyWith =>
      __$$BlacklistEntryImplCopyWithImpl<_$BlacklistEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BlacklistEntryImplToJson(this);
  }
}

abstract class _BlacklistEntry extends BlacklistEntry {
  const factory _BlacklistEntry({
    required final String id,
    required final String userId,
    required final BlacklistLevel level,
    required final String reason,
    final String? evidence,
    final String? deviceFingerprint,
    final String? ipAddress,
    final DateTime? expiresAt,
    final DateTime? createdAt,
  }) = _$BlacklistEntryImpl;
  const _BlacklistEntry._() : super._();

  factory _BlacklistEntry.fromJson(Map<String, dynamic> json) =
      _$BlacklistEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  BlacklistLevel get level;
  @override
  String get reason;
  @override
  String? get evidence;
  @override
  String? get deviceFingerprint;
  @override
  String? get ipAddress;
  @override
  DateTime? get expiresAt;
  @override
  DateTime? get createdAt;

  /// Create a copy of BlacklistEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BlacklistEntryImplCopyWith<_$BlacklistEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReportStatistics _$ReportStatisticsFromJson(Map<String, dynamic> json) {
  return _ReportStatistics.fromJson(json);
}

/// @nodoc
mixin _$ReportStatistics {
  String get userId => throw _privateConstructorUsedError;
  int get totalReportsReceived => throw _privateConstructorUsedError;
  int get validReports => throw _privateConstructorUsedError;
  int get invalidReports => throw _privateConstructorUsedError;
  int get pendingReports => throw _privateConstructorUsedError;
  DateTime? get lastReportAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ReportStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportStatisticsCopyWith<ReportStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportStatisticsCopyWith<$Res> {
  factory $ReportStatisticsCopyWith(
    ReportStatistics value,
    $Res Function(ReportStatistics) then,
  ) = _$ReportStatisticsCopyWithImpl<$Res, ReportStatistics>;
  @useResult
  $Res call({
    String userId,
    int totalReportsReceived,
    int validReports,
    int invalidReports,
    int pendingReports,
    DateTime? lastReportAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$ReportStatisticsCopyWithImpl<$Res, $Val extends ReportStatistics>
    implements $ReportStatisticsCopyWith<$Res> {
  _$ReportStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalReportsReceived = null,
    Object? validReports = null,
    Object? invalidReports = null,
    Object? pendingReports = null,
    Object? lastReportAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalReportsReceived: null == totalReportsReceived
                ? _value.totalReportsReceived
                : totalReportsReceived // ignore: cast_nullable_to_non_nullable
                      as int,
            validReports: null == validReports
                ? _value.validReports
                : validReports // ignore: cast_nullable_to_non_nullable
                      as int,
            invalidReports: null == invalidReports
                ? _value.invalidReports
                : invalidReports // ignore: cast_nullable_to_non_nullable
                      as int,
            pendingReports: null == pendingReports
                ? _value.pendingReports
                : pendingReports // ignore: cast_nullable_to_non_nullable
                      as int,
            lastReportAt: freezed == lastReportAt
                ? _value.lastReportAt
                : lastReportAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ReportStatisticsImplCopyWith<$Res>
    implements $ReportStatisticsCopyWith<$Res> {
  factory _$$ReportStatisticsImplCopyWith(
    _$ReportStatisticsImpl value,
    $Res Function(_$ReportStatisticsImpl) then,
  ) = __$$ReportStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    int totalReportsReceived,
    int validReports,
    int invalidReports,
    int pendingReports,
    DateTime? lastReportAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ReportStatisticsImplCopyWithImpl<$Res>
    extends _$ReportStatisticsCopyWithImpl<$Res, _$ReportStatisticsImpl>
    implements _$$ReportStatisticsImplCopyWith<$Res> {
  __$$ReportStatisticsImplCopyWithImpl(
    _$ReportStatisticsImpl _value,
    $Res Function(_$ReportStatisticsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalReportsReceived = null,
    Object? validReports = null,
    Object? invalidReports = null,
    Object? pendingReports = null,
    Object? lastReportAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ReportStatisticsImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalReportsReceived: null == totalReportsReceived
            ? _value.totalReportsReceived
            : totalReportsReceived // ignore: cast_nullable_to_non_nullable
                  as int,
        validReports: null == validReports
            ? _value.validReports
            : validReports // ignore: cast_nullable_to_non_nullable
                  as int,
        invalidReports: null == invalidReports
            ? _value.invalidReports
            : invalidReports // ignore: cast_nullable_to_non_nullable
                  as int,
        pendingReports: null == pendingReports
            ? _value.pendingReports
            : pendingReports // ignore: cast_nullable_to_non_nullable
                  as int,
        lastReportAt: freezed == lastReportAt
            ? _value.lastReportAt
            : lastReportAt // ignore: cast_nullable_to_non_nullable
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
class _$ReportStatisticsImpl extends _ReportStatistics {
  const _$ReportStatisticsImpl({
    required this.userId,
    this.totalReportsReceived = 0,
    this.validReports = 0,
    this.invalidReports = 0,
    this.pendingReports = 0,
    this.lastReportAt,
    this.updatedAt,
  }) : super._();

  factory _$ReportStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportStatisticsImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final int totalReportsReceived;
  @override
  @JsonKey()
  final int validReports;
  @override
  @JsonKey()
  final int invalidReports;
  @override
  @JsonKey()
  final int pendingReports;
  @override
  final DateTime? lastReportAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ReportStatistics(userId: $userId, totalReportsReceived: $totalReportsReceived, validReports: $validReports, invalidReports: $invalidReports, pendingReports: $pendingReports, lastReportAt: $lastReportAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportStatisticsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.totalReportsReceived, totalReportsReceived) ||
                other.totalReportsReceived == totalReportsReceived) &&
            (identical(other.validReports, validReports) ||
                other.validReports == validReports) &&
            (identical(other.invalidReports, invalidReports) ||
                other.invalidReports == invalidReports) &&
            (identical(other.pendingReports, pendingReports) ||
                other.pendingReports == pendingReports) &&
            (identical(other.lastReportAt, lastReportAt) ||
                other.lastReportAt == lastReportAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    totalReportsReceived,
    validReports,
    invalidReports,
    pendingReports,
    lastReportAt,
    updatedAt,
  );

  /// Create a copy of ReportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportStatisticsImplCopyWith<_$ReportStatisticsImpl> get copyWith =>
      __$$ReportStatisticsImplCopyWithImpl<_$ReportStatisticsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportStatisticsImplToJson(this);
  }
}

abstract class _ReportStatistics extends ReportStatistics {
  const factory _ReportStatistics({
    required final String userId,
    final int totalReportsReceived,
    final int validReports,
    final int invalidReports,
    final int pendingReports,
    final DateTime? lastReportAt,
    final DateTime? updatedAt,
  }) = _$ReportStatisticsImpl;
  const _ReportStatistics._() : super._();

  factory _ReportStatistics.fromJson(Map<String, dynamic> json) =
      _$ReportStatisticsImpl.fromJson;

  @override
  String get userId;
  @override
  int get totalReportsReceived;
  @override
  int get validReports;
  @override
  int get invalidReports;
  @override
  int get pendingReports;
  @override
  DateTime? get lastReportAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ReportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportStatisticsImplCopyWith<_$ReportStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
