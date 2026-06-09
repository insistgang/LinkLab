// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_recording_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CallRecording _$CallRecordingFromJson(Map<String, dynamic> json) {
  return _CallRecording.fromJson(json);
}

/// @nodoc
mixin _$CallRecording {
  String get id => throw _privateConstructorUsedError;
  String get callId => throw _privateConstructorUsedError;
  String get seekerId => throw _privateConstructorUsedError;
  String? get volunteerId => throw _privateConstructorUsedError;
  String? get fileUrl => throw _privateConstructorUsedError;
  String? get filePath => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  int? get duration => throw _privateConstructorUsedError; // 錄音時長（秒）
  bool get isUploaded => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  List<DetectionResult> get detectionResults =>
      throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  DateTime? get uploadedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError; // 7天后自動刪除
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CallRecording to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CallRecording
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CallRecordingCopyWith<CallRecording> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallRecordingCopyWith<$Res> {
  factory $CallRecordingCopyWith(
    CallRecording value,
    $Res Function(CallRecording) then,
  ) = _$CallRecordingCopyWithImpl<$Res, CallRecording>;
  @useResult
  $Res call({
    String id,
    String callId,
    String seekerId,
    String? volunteerId,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    int? duration,
    bool isUploaded,
    bool isDeleted,
    List<DetectionResult> detectionResults,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? uploadedAt,
    DateTime? deletedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$CallRecordingCopyWithImpl<$Res, $Val extends CallRecording>
    implements $CallRecordingCopyWith<$Res> {
  _$CallRecordingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallRecording
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? callId = null,
    Object? seekerId = null,
    Object? volunteerId = freezed,
    Object? fileUrl = freezed,
    Object? filePath = freezed,
    Object? fileSize = freezed,
    Object? duration = freezed,
    Object? isUploaded = null,
    Object? isDeleted = null,
    Object? detectionResults = null,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? uploadedAt = freezed,
    Object? deletedAt = freezed,
    Object? expiresAt = freezed,
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
            seekerId: null == seekerId
                ? _value.seekerId
                : seekerId // ignore: cast_nullable_to_non_nullable
                      as String,
            volunteerId: freezed == volunteerId
                ? _value.volunteerId
                : volunteerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileUrl: freezed == fileUrl
                ? _value.fileUrl
                : fileUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            filePath: freezed == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileSize: freezed == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int?,
            isUploaded: null == isUploaded
                ? _value.isUploaded
                : isUploaded // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            detectionResults: null == detectionResults
                ? _value.detectionResults
                : detectionResults // ignore: cast_nullable_to_non_nullable
                      as List<DetectionResult>,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            uploadedAt: freezed == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$CallRecordingImplCopyWith<$Res>
    implements $CallRecordingCopyWith<$Res> {
  factory _$$CallRecordingImplCopyWith(
    _$CallRecordingImpl value,
    $Res Function(_$CallRecordingImpl) then,
  ) = __$$CallRecordingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String callId,
    String seekerId,
    String? volunteerId,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    int? duration,
    bool isUploaded,
    bool isDeleted,
    List<DetectionResult> detectionResults,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? uploadedAt,
    DateTime? deletedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$CallRecordingImplCopyWithImpl<$Res>
    extends _$CallRecordingCopyWithImpl<$Res, _$CallRecordingImpl>
    implements _$$CallRecordingImplCopyWith<$Res> {
  __$$CallRecordingImplCopyWithImpl(
    _$CallRecordingImpl _value,
    $Res Function(_$CallRecordingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CallRecording
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? callId = null,
    Object? seekerId = null,
    Object? volunteerId = freezed,
    Object? fileUrl = freezed,
    Object? filePath = freezed,
    Object? fileSize = freezed,
    Object? duration = freezed,
    Object? isUploaded = null,
    Object? isDeleted = null,
    Object? detectionResults = null,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? uploadedAt = freezed,
    Object? deletedAt = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CallRecordingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        callId: null == callId
            ? _value.callId
            : callId // ignore: cast_nullable_to_non_nullable
                  as String,
        seekerId: null == seekerId
            ? _value.seekerId
            : seekerId // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteerId: freezed == volunteerId
            ? _value.volunteerId
            : volunteerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileUrl: freezed == fileUrl
            ? _value.fileUrl
            : fileUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        filePath: freezed == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileSize: freezed == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int?,
        isUploaded: null == isUploaded
            ? _value.isUploaded
            : isUploaded // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        detectionResults: null == detectionResults
            ? _value._detectionResults
            : detectionResults // ignore: cast_nullable_to_non_nullable
                  as List<DetectionResult>,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        uploadedAt: freezed == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
class _$CallRecordingImpl extends _CallRecording {
  const _$CallRecordingImpl({
    required this.id,
    required this.callId,
    required this.seekerId,
    this.volunteerId,
    this.fileUrl,
    this.filePath,
    this.fileSize,
    this.duration,
    this.isUploaded = false,
    this.isDeleted = false,
    final List<DetectionResult> detectionResults = const [],
    this.startedAt,
    this.endedAt,
    this.uploadedAt,
    this.deletedAt,
    this.expiresAt,
    this.createdAt,
  }) : _detectionResults = detectionResults,
       super._();

  factory _$CallRecordingImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallRecordingImplFromJson(json);

  @override
  final String id;
  @override
  final String callId;
  @override
  final String seekerId;
  @override
  final String? volunteerId;
  @override
  final String? fileUrl;
  @override
  final String? filePath;
  @override
  final int? fileSize;
  @override
  final int? duration;
  // 錄音時長（秒）
  @override
  @JsonKey()
  final bool isUploaded;
  @override
  @JsonKey()
  final bool isDeleted;
  final List<DetectionResult> _detectionResults;
  @override
  @JsonKey()
  List<DetectionResult> get detectionResults {
    if (_detectionResults is EqualUnmodifiableListView)
      return _detectionResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectionResults);
  }

  @override
  final DateTime? startedAt;
  @override
  final DateTime? endedAt;
  @override
  final DateTime? uploadedAt;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime? expiresAt;
  // 7天后自動刪除
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CallRecording(id: $id, callId: $callId, seekerId: $seekerId, volunteerId: $volunteerId, fileUrl: $fileUrl, filePath: $filePath, fileSize: $fileSize, duration: $duration, isUploaded: $isUploaded, isDeleted: $isDeleted, detectionResults: $detectionResults, startedAt: $startedAt, endedAt: $endedAt, uploadedAt: $uploadedAt, deletedAt: $deletedAt, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallRecordingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.callId, callId) || other.callId == callId) &&
            (identical(other.seekerId, seekerId) ||
                other.seekerId == seekerId) &&
            (identical(other.volunteerId, volunteerId) ||
                other.volunteerId == volunteerId) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.isUploaded, isUploaded) ||
                other.isUploaded == isUploaded) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            const DeepCollectionEquality().equals(
              other._detectionResults,
              _detectionResults,
            ) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
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
    callId,
    seekerId,
    volunteerId,
    fileUrl,
    filePath,
    fileSize,
    duration,
    isUploaded,
    isDeleted,
    const DeepCollectionEquality().hash(_detectionResults),
    startedAt,
    endedAt,
    uploadedAt,
    deletedAt,
    expiresAt,
    createdAt,
  );

  /// Create a copy of CallRecording
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CallRecordingImplCopyWith<_$CallRecordingImpl> get copyWith =>
      __$$CallRecordingImplCopyWithImpl<_$CallRecordingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CallRecordingImplToJson(this);
  }
}

abstract class _CallRecording extends CallRecording {
  const factory _CallRecording({
    required final String id,
    required final String callId,
    required final String seekerId,
    final String? volunteerId,
    final String? fileUrl,
    final String? filePath,
    final int? fileSize,
    final int? duration,
    final bool isUploaded,
    final bool isDeleted,
    final List<DetectionResult> detectionResults,
    final DateTime? startedAt,
    final DateTime? endedAt,
    final DateTime? uploadedAt,
    final DateTime? deletedAt,
    final DateTime? expiresAt,
    final DateTime? createdAt,
  }) = _$CallRecordingImpl;
  const _CallRecording._() : super._();

  factory _CallRecording.fromJson(Map<String, dynamic> json) =
      _$CallRecordingImpl.fromJson;

  @override
  String get id;
  @override
  String get callId;
  @override
  String get seekerId;
  @override
  String? get volunteerId;
  @override
  String? get fileUrl;
  @override
  String? get filePath;
  @override
  int? get fileSize;
  @override
  int? get duration; // 錄音時長（秒）
  @override
  bool get isUploaded;
  @override
  bool get isDeleted;
  @override
  List<DetectionResult> get detectionResults;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get endedAt;
  @override
  DateTime? get uploadedAt;
  @override
  DateTime? get deletedAt;
  @override
  DateTime? get expiresAt; // 7天后自動刪除
  @override
  DateTime? get createdAt;

  /// Create a copy of CallRecording
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CallRecordingImplCopyWith<_$CallRecordingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectionResult _$DetectionResultFromJson(Map<String, dynamic> json) {
  return _DetectionResult.fromJson(json);
}

/// @nodoc
mixin _$DetectionResult {
  String get id => throw _privateConstructorUsedError;
  DetectionType get type => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError; // 0.0 - 1.0
  bool get isViolation => throw _privateConstructorUsedError;
  ViolationLevel? get violationLevel => throw _privateConstructorUsedError;
  String? get detectedText => throw _privateConstructorUsedError;
  String? get matchedKeywords => throw _privateConstructorUsedError;
  int? get timestamp => throw _privateConstructorUsedError; // 在錄音中的時間點（毫秒）
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this DetectionResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectionResultCopyWith<DetectionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionResultCopyWith<$Res> {
  factory $DetectionResultCopyWith(
    DetectionResult value,
    $Res Function(DetectionResult) then,
  ) = _$DetectionResultCopyWithImpl<$Res, DetectionResult>;
  @useResult
  $Res call({
    String id,
    DetectionType type,
    double confidence,
    bool isViolation,
    ViolationLevel? violationLevel,
    String? detectedText,
    String? matchedKeywords,
    int? timestamp,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$DetectionResultCopyWithImpl<$Res, $Val extends DetectionResult>
    implements $DetectionResultCopyWith<$Res> {
  _$DetectionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? confidence = null,
    Object? isViolation = null,
    Object? violationLevel = freezed,
    Object? detectedText = freezed,
    Object? matchedKeywords = freezed,
    Object? timestamp = freezed,
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
                      as DetectionType,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            isViolation: null == isViolation
                ? _value.isViolation
                : isViolation // ignore: cast_nullable_to_non_nullable
                      as bool,
            violationLevel: freezed == violationLevel
                ? _value.violationLevel
                : violationLevel // ignore: cast_nullable_to_non_nullable
                      as ViolationLevel?,
            detectedText: freezed == detectedText
                ? _value.detectedText
                : detectedText // ignore: cast_nullable_to_non_nullable
                      as String?,
            matchedKeywords: freezed == matchedKeywords
                ? _value.matchedKeywords
                : matchedKeywords // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$DetectionResultImplCopyWith<$Res>
    implements $DetectionResultCopyWith<$Res> {
  factory _$$DetectionResultImplCopyWith(
    _$DetectionResultImpl value,
    $Res Function(_$DetectionResultImpl) then,
  ) = __$$DetectionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DetectionType type,
    double confidence,
    bool isViolation,
    ViolationLevel? violationLevel,
    String? detectedText,
    String? matchedKeywords,
    int? timestamp,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$DetectionResultImplCopyWithImpl<$Res>
    extends _$DetectionResultCopyWithImpl<$Res, _$DetectionResultImpl>
    implements _$$DetectionResultImplCopyWith<$Res> {
  __$$DetectionResultImplCopyWithImpl(
    _$DetectionResultImpl _value,
    $Res Function(_$DetectionResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DetectionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? confidence = null,
    Object? isViolation = null,
    Object? violationLevel = freezed,
    Object? detectedText = freezed,
    Object? matchedKeywords = freezed,
    Object? timestamp = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$DetectionResultImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as DetectionType,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        isViolation: null == isViolation
            ? _value.isViolation
            : isViolation // ignore: cast_nullable_to_non_nullable
                  as bool,
        violationLevel: freezed == violationLevel
            ? _value.violationLevel
            : violationLevel // ignore: cast_nullable_to_non_nullable
                  as ViolationLevel?,
        detectedText: freezed == detectedText
            ? _value.detectedText
            : detectedText // ignore: cast_nullable_to_non_nullable
                  as String?,
        matchedKeywords: freezed == matchedKeywords
            ? _value.matchedKeywords
            : matchedKeywords // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int?,
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
class _$DetectionResultImpl implements _DetectionResult {
  const _$DetectionResultImpl({
    required this.id,
    required this.type,
    required this.confidence,
    this.isViolation = false,
    this.violationLevel,
    this.detectedText,
    this.matchedKeywords,
    this.timestamp,
    this.createdAt,
  });

  factory _$DetectionResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionResultImplFromJson(json);

  @override
  final String id;
  @override
  final DetectionType type;
  @override
  final double confidence;
  // 0.0 - 1.0
  @override
  @JsonKey()
  final bool isViolation;
  @override
  final ViolationLevel? violationLevel;
  @override
  final String? detectedText;
  @override
  final String? matchedKeywords;
  @override
  final int? timestamp;
  // 在錄音中的時間點（毫秒）
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DetectionResult(id: $id, type: $type, confidence: $confidence, isViolation: $isViolation, violationLevel: $violationLevel, detectedText: $detectedText, matchedKeywords: $matchedKeywords, timestamp: $timestamp, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.isViolation, isViolation) ||
                other.isViolation == isViolation) &&
            (identical(other.violationLevel, violationLevel) ||
                other.violationLevel == violationLevel) &&
            (identical(other.detectedText, detectedText) ||
                other.detectedText == detectedText) &&
            (identical(other.matchedKeywords, matchedKeywords) ||
                other.matchedKeywords == matchedKeywords) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    confidence,
    isViolation,
    violationLevel,
    detectedText,
    matchedKeywords,
    timestamp,
    createdAt,
  );

  /// Create a copy of DetectionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionResultImplCopyWith<_$DetectionResultImpl> get copyWith =>
      __$$DetectionResultImplCopyWithImpl<_$DetectionResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionResultImplToJson(this);
  }
}

abstract class _DetectionResult implements DetectionResult {
  const factory _DetectionResult({
    required final String id,
    required final DetectionType type,
    required final double confidence,
    final bool isViolation,
    final ViolationLevel? violationLevel,
    final String? detectedText,
    final String? matchedKeywords,
    final int? timestamp,
    final DateTime? createdAt,
  }) = _$DetectionResultImpl;

  factory _DetectionResult.fromJson(Map<String, dynamic> json) =
      _$DetectionResultImpl.fromJson;

  @override
  String get id;
  @override
  DetectionType get type;
  @override
  double get confidence; // 0.0 - 1.0
  @override
  bool get isViolation;
  @override
  ViolationLevel? get violationLevel;
  @override
  String? get detectedText;
  @override
  String? get matchedKeywords;
  @override
  int? get timestamp; // 在錄音中的時間點（毫秒）
  @override
  DateTime? get createdAt;

  /// Create a copy of DetectionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectionResultImplCopyWith<_$DetectionResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
