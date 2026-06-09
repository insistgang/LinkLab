// ignore: deprecated_member_use_from_same_package
import '../services/app_session_service.dart';
import '../services/local_storage.dart';
import '../core/utils/logger.dart';
import '../models/help_request_status.dart';

/// 記錄 Demo 主線中的 help_request 狀態流轉。
/// 僅服務競賽版本地閉環，不依賴真實後端。
class DemoHelpRequestTracker {
  DemoHelpRequestTracker._();

  static final LocalStorage _storage = LocalStorage();

  static Future<void> _ensureStorage() async {
    await _storage.initialize();
  }

  static String get _currentUserId =>
      AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

  static String _newRequestId() =>
      'demo_request_${DateTime.now().microsecondsSinceEpoch}';

  static Future<String?> currentRequestId() async {
    await _ensureStorage();
    return _storage.getString(StorageKeys.currentDemoHelpRequestId);
  }

  static Future<void> clearCurrentRequest() async {
    await _ensureStorage();
    await _storage.remove(StorageKeys.currentDemoHelpRequestId);
  }

  static Future<String> startCreated({
    required String intent,
    String urgency = 'normal',
    String type = 'ai_auto',
  }) async {
    final requestId = _newRequestId();
    await _storage.setString(StorageKeys.currentDemoHelpRequestId, requestId);
    await _upsertRecord(
      id: requestId,
      type: type,
      intent: intent,
      urgency: urgency,
      status: HelpRequestStatus.created,
      aiResponse: const {'source': 'demo_flow', 'stage': 'created'},
    );
    return requestId;
  }

  static Future<String> startAIProcessing({
    required String intent,
    String urgency = 'normal',
  }) async {
    final requestId = await startCreated(intent: intent, urgency: urgency);
    await markAIProcessing(requestId: requestId, intent: intent);
    return requestId;
  }

  static Future<void> markAIProcessing({
    String? requestId,
    required String intent,
  }) async {
    final id = requestId ?? await _ensureCurrentRequestId();
    final existing = await _getRecord(id);
    await _upsertRecord(
      id: id,
      type: existing?['type']?.toString() ?? 'ai_auto',
      intent: intent,
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.aiProcessing,
      createdAt: existing?['createdAt']?.toString(),
      aiResponse: _mergeAiResponse(existing, {
        'source': 'demo_ai',
        'stage': HelpRequestStatus.aiProcessing.wireName,
      }),
    );
  }

  static Future<String> ensureMatchingRequest({
    required String intent,
    String type = 'realtime_voice',
    String urgency = 'normal',
  }) async {
    final requestId = await _ensureCurrentRequestId();
    final existing = await _getRecord(requestId);

    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() == 'sos' ? 'sos' : type,
      intent: intent,
      urgency: existing?['urgency']?.toString() ?? urgency,
      status: HelpRequestStatus.matching,
      createdAt: existing?['createdAt']?.toString(),
      aiResponse: _mergeAiResponse(existing, {
        'source': 'demo_matching',
        'stage': HelpRequestStatus.matching.wireName,
      }),
    );
    return requestId;
  }

  static Future<String> startSOSUndoWindow({String intent = 'SOS緊急求助'}) async {
    final requestId = _newRequestId();
    await _storage.setString(StorageKeys.currentDemoHelpRequestId, requestId);
    await _upsertRecord(
      id: requestId,
      type: 'sos',
      intent: intent,
      urgency: 'emergency',
      status: HelpRequestStatus.created,
      aiResponse: const {
        'source': 'demo_sos',
        'stage': 'undo_window',
        'undoWindowSeconds': 10,
      },
    );
    return requestId;
  }

  static Future<void> markAIResolved({required String summary}) async {
    final requestId = await currentRequestId();
    if (requestId == null) {
      return;
    }

    final existing = await _getRecord(requestId);
    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'ai_auto',
      intent: existing?['intent']?.toString() ?? 'AI已處理當前問題',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.aiResolved,
      createdAt: existing?['createdAt']?.toString(),
      completedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {
        'summary': summary,
        'stage': HelpRequestStatus.aiResolved.wireName,
      }),
    );
    await clearCurrentRequest();
  }

  static Future<void> markConnected({
    required String volunteerId,
    required String volunteerName,
    List<String> volunteerSkills = const [],
  }) async {
    final requestId = await _ensureCurrentRequestId();
    final existing = await _getRecord(requestId);

    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'realtime_voice',
      intent: existing?['intent']?.toString() ?? '連接真人志願者獲取幫助',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.connected,
      volunteerId: volunteerId,
      createdAt: existing?['createdAt']?.toString(),
      matchedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {
        'summary': '已爲您接通真人志願者，正在進行語音協助。',
        'volunteerName': volunteerName,
        'volunteerSkills': volunteerSkills,
        'stage': HelpRequestStatus.connected.wireName,
      }),
    );
  }

  static Future<void> markCompleted({
    int? durationSeconds,
    int? seekerRating,
    String? feedback,
    List<String> ratingTags = const [],
  }) async {
    final requestId = await currentRequestId();
    if (requestId == null) {
      return;
    }

    final existing = await _getRecord(requestId);
    final mergedAiResponse = <String, dynamic>{
      ..._readAiResponse(existing),
      'stage': HelpRequestStatus.completed.wireName,
      if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      if (ratingTags.isNotEmpty) 'ratingTags': ratingTags,
    };

    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'realtime_voice',
      intent: existing?['intent']?.toString() ?? '真人語音協助',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.completed,
      volunteerId: existing?['volunteerId']?.toString(),
      createdAt: existing?['createdAt']?.toString(),
      matchedAt: _parseDate(existing?['matchedAt']),
      completedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      seekerRating: seekerRating,
      aiResponse: mergedAiResponse,
    );
  }

  static Future<void> markCancelled({String? reason}) async {
    final requestId = await currentRequestId();
    if (requestId == null) {
      return;
    }

    final existing = await _getRecord(requestId);
    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'realtime_voice',
      intent: existing?['intent']?.toString() ?? '已取消的求助',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.cancelled,
      volunteerId: existing?['volunteerId']?.toString(),
      createdAt: existing?['createdAt']?.toString(),
      matchedAt: _parseDate(existing?['matchedAt']),
      completedAt: DateTime.now(),
      cancelReason: reason,
      aiResponse: _mergeAiResponse(existing, {
        'stage': HelpRequestStatus.cancelled.wireName,
      }),
    );
    await clearCurrentRequest();
  }

  static Future<void> markExpired() async {
    final requestId = await currentRequestId();
    if (requestId == null) {
      return;
    }

    final existing = await _getRecord(requestId);
    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'realtime_voice',
      intent: existing?['intent']?.toString() ?? '匹配超時',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: HelpRequestStatus.expired,
      volunteerId: existing?['volunteerId']?.toString(),
      createdAt: existing?['createdAt']?.toString(),
      completedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {
        'stage': HelpRequestStatus.expired.wireName,
      }),
    );
    await clearCurrentRequest();
  }

  static Future<String> _ensureCurrentRequestId() async {
    await _ensureStorage();
    final existingId = _storage.getString(StorageKeys.currentDemoHelpRequestId);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final requestId = _newRequestId();
    await _storage.setString(StorageKeys.currentDemoHelpRequestId, requestId);
    return requestId;
  }

  static Future<Map<String, dynamic>?> _getRecord(String id) async {
    await _ensureStorage();
    try {
      return _storage.getHelpHistory().firstWhere(
        (item) => item['id']?.toString() == id,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _upsertRecord({
    required String id,
    required String type,
    required String intent,
    required String urgency,
    required HelpRequestStatus status,
    String? volunteerId,
    String? createdAt,
    DateTime? matchedAt,
    DateTime? completedAt,
    int? durationSeconds,
    int? seekerRating,
    String? cancelReason,
    Map<String, dynamic>? aiResponse,
  }) async {
    await _ensureStorage();
    await _storage.upsertHelpRecord({
      'id': id,
      'seekerId': _currentUserId,
      'type': type,
      'intent': intent,
      'urgency': urgency,
      'status': status.wireName,
      'volunteerId': ?volunteerId,
      'createdAt': ?createdAt,
      if (matchedAt != null) 'matchedAt': matchedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt.toIso8601String(),
      'durationSeconds': ?durationSeconds,
      'seekerRating': ?seekerRating,
      'cancelReason': ?cancelReason,
      'aiResponse': ?aiResponse,
    });
    AppLogger.info('Demo help_request $id -> ${status.wireName}');
  }

  static Map<String, dynamic> _mergeAiResponse(
    Map<String, dynamic>? existing,
    Map<String, dynamic> updates,
  ) {
    return {..._readAiResponse(existing), ...updates};
  }

  static Map<String, dynamic> _readAiResponse(Map<String, dynamic>? existing) {
    final value = existing?['aiResponse'];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
