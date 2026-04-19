import '../services/app_session_service.dart';
import '../services/local_storage.dart';

/// 记录 Demo 主线中的 help_request 状态流转。
/// 仅服务竞赛版本地闭环，不依赖真实后端。
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

  static Future<String> startAIProcessing({
    required String intent,
    String urgency = 'normal',
  }) async {
    final requestId = _newRequestId();
    await _storage.setString(StorageKeys.currentDemoHelpRequestId, requestId);
    await _upsertRecord(
      id: requestId,
      type: 'ai_auto',
      intent: intent,
      urgency: urgency,
      status: 'ai_processing',
      aiResponse: const {'source': 'demo_ai', 'stage': 'ai_processing'},
    );
    return requestId;
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
      status: 'matching',
      createdAt: existing?['createdAt']?.toString(),
      aiResponse: _mergeAiResponse(existing, {
        'source': 'demo_matching',
        'stage': 'matching',
      }),
    );
    return requestId;
  }

  static Future<String> startSOSUndoWindow({String intent = 'SOS紧急求助'}) async {
    final requestId = _newRequestId();
    await _storage.setString(StorageKeys.currentDemoHelpRequestId, requestId);
    await _upsertRecord(
      id: requestId,
      type: 'sos',
      intent: intent,
      urgency: 'emergency',
      status: 'created',
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
      intent: existing?['intent']?.toString() ?? 'AI已处理当前问题',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: 'ai_resolved',
      createdAt: existing?['createdAt']?.toString(),
      completedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {
        'summary': summary,
        'stage': 'ai_resolved',
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
      intent: existing?['intent']?.toString() ?? '连接真人志愿者获取帮助',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: 'connected',
      volunteerId: volunteerId,
      createdAt: existing?['createdAt']?.toString(),
      matchedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {
        'summary': '已为您接通真人志愿者，正在进行语音协助。',
        'volunteerName': volunteerName,
        'volunteerSkills': volunteerSkills,
        'stage': 'connected',
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
      'stage': 'completed',
      if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      if (ratingTags.isNotEmpty) 'ratingTags': ratingTags,
    };

    await _upsertRecord(
      id: requestId,
      type: existing?['type']?.toString() ?? 'realtime_voice',
      intent: existing?['intent']?.toString() ?? '真人语音协助',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: 'completed',
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
      status: 'cancelled',
      volunteerId: existing?['volunteerId']?.toString(),
      createdAt: existing?['createdAt']?.toString(),
      matchedAt: _parseDate(existing?['matchedAt']),
      completedAt: DateTime.now(),
      cancelReason: reason,
      aiResponse: _mergeAiResponse(existing, {'stage': 'cancelled'}),
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
      intent: existing?['intent']?.toString() ?? '匹配超时',
      urgency: existing?['urgency']?.toString() ?? 'normal',
      status: 'expired',
      volunteerId: existing?['volunteerId']?.toString(),
      createdAt: existing?['createdAt']?.toString(),
      completedAt: DateTime.now(),
      aiResponse: _mergeAiResponse(existing, {'stage': 'expired'}),
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
    required String status,
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
      'status': status,
      'volunteerId': ?volunteerId,
      'createdAt': ?createdAt,
      if (matchedAt != null) 'matchedAt': matchedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt.toIso8601String(),
      'durationSeconds': ?durationSeconds,
      'seekerRating': ?seekerRating,
      'cancelReason': ?cancelReason,
      'aiResponse': ?aiResponse,
    });
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
