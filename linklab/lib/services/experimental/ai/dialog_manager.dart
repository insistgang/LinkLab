import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import '../../core/utils/logger.dart';

/// 對話上下文管理器
/// 負責管理多輪對話的狀態和歷史記錄
class DialogContextManager {
  static const String _storageKey = 'dialog_sessions';
  static const int _maxHistoryPerSession = 20;
  static const int _maxStoredSessions = 10;

  final SharedPreferences? _prefs;
  final Map<String, DialogContext> _activeSessions = {};

  DialogContextManager([this._prefs]);

  /// 創建新會話
  DialogContext createSession({String? userId}) {
    final session = DialogContext.create(userId: userId);
    _activeSessions[session.sessionId] = session;
    return session;
  }

  /// 獲取或創建會話
  DialogContext getOrCreateSession(String? sessionId, {String? userId}) {
    if (sessionId != null && _activeSessions.containsKey(sessionId)) {
      return _activeSessions[sessionId]!;
    }
    return createSession(userId: userId);
  }

  /// 添加用戶消息
  DialogContext addUserMessage(
    String sessionId,
    String content, {
    String? imageUrl,
  }) {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }

    final message = DialogMessage(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    final updatedSession = session.addMessage(message);
    _activeSessions[sessionId] = updatedSession;
    return updatedSession;
  }

  /// 添加助手消息
  DialogContext addAssistantMessage(
    String sessionId,
    String content, {
    Map<String, dynamic>? extraData,
  }) {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }

    final message = DialogMessage(
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );

    final updatedSession = session.addMessage(message);
    _activeSessions[sessionId] = updatedSession;
    return updatedSession;
  }

  /// 添加系統消息
  DialogContext addSystemMessage(String sessionId, String content) {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }

    final message = DialogMessage(
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
    );

    final updatedSession = session.addMessage(message);
    _activeSessions[sessionId] = updatedSession;
    return updatedSession;
  }

  /// 獲取會話歷史
  List<DialogMessage> getSessionHistory(String sessionId) {
    final session = _activeSessions[sessionId];
    return session?.history ?? [];
  }

  /// 獲取格式化的對話歷史（用於AI模型輸入）
  List<Map<String, String>> getFormattedHistory(
    String sessionId, {
    int maxMessages = 10,
  }) {
    final session = _activeSessions[sessionId];
    if (session == null) return [];

    final recentMessages = session.getRecentMessages(maxMessages);
    return recentMessages.map((msg) {
      return {
        'role': _mapRoleToString(msg.role),
        'content': msg.content,
      };
    }).toList();
  }

  /// 清除會話歷史
  void clearSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  /// 結束會話並保存
  Future<void> endSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    // 保存到持久化存儲
    await _saveSession(session);

    // 從活躍會話中移除
    _activeSessions.remove(sessionId);
  }

  /// 獲取會話統計信息
  DialogStatistics getStatistics(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null) {
      return DialogStatistics.empty();
    }

    final history = session.history;
    final userMessages = history.where((m) => m.role == MessageRole.user).length;
    final assistantMessages =
        history.where((m) => m.role == MessageRole.assistant).length;

    return DialogStatistics(
      totalMessages: history.length,
      userMessages: userMessages,
      assistantMessages: assistantMessages,
      duration: DateTime.now().difference(session.createdAt),
    );
  }

  /// 檢查會話是否超時（默認30分鐘）
  bool isSessionTimeout(String sessionId, {Duration timeout = const Duration(minutes: 30)}) {
    final session = _activeSessions[sessionId];
    if (session == null) return true;

    final lastMessage = session.history.isNotEmpty
        ? session.history.last.timestamp
        : session.createdAt;

    return DateTime.now().difference(lastMessage) > timeout;
  }

  /// 清理超時會話
  void cleanupTimeoutSessions({Duration timeout = const Duration(minutes: 30)}) {
    final timeoutSessions = _activeSessions.entries
        .where((e) => isSessionTimeout(e.key, timeout: timeout))
        .map((e) => e.key)
        .toList();

    for (final sessionId in timeoutSessions) {
      _activeSessions.remove(sessionId);
    }
  }

  /// 保存會話到本地存儲
  Future<void> _saveSession(DialogContext session) async {
    if (_prefs == null) return;

    try {
      final sessionsJson = _prefs!.getString(_storageKey);
      final Map<String, dynamic> sessions = sessionsJson != null
          ? jsonDecode(sessionsJson)
          : {};

      // 添加新會話
      sessions[session.sessionId] = _serializeSession(session);

      // 限制存儲數量
      while (sessions.length > _maxStoredSessions) {
        final oldestKey = sessions.keys.first;
        sessions.remove(oldestKey);
      }

      await _prefs!.setString(_storageKey, jsonEncode(sessions));
    } catch (error, stackTrace) {
      // 存儲失敗不拋出異常
      AppLogger.error(
        '保存對話會話失敗，已跳過持久化',
        error,
        stackTrace,
      );
    }
  }

  /// 加載歷史會話
  Future<List<DialogContext>> loadHistorySessions() async {
    if (_prefs == null) return [];

    try {
      final sessionsJson = _prefs!.getString(_storageKey);
      if (sessionsJson == null) return [];

      final Map<String, dynamic> sessions = jsonDecode(sessionsJson);
      return sessions.values
          .map((data) => _deserializeSession(data))
          .whereType<DialogContext>()
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        '加載歷史對話會話失敗，已回退爲空列表',
        error,
        stackTrace,
      );
      return [];
    }
  }

  /// 序列化會話
  Map<String, dynamic> _serializeSession(DialogContext session) {
    return {
      'sessionId': session.sessionId,
      'userId': session.userId,
      'createdAt': session.createdAt.toIso8601String(),
      'turnCount': session.turnCount,
      'history': session.history.map((m) => m.toJson()).toList(),
    };
  }

  /// 反序列化會話
  DialogContext? _deserializeSession(Map<String, dynamic> data) {
    try {
      return DialogContext(
        sessionId: data['sessionId'],
        userId: data['userId'],
        createdAt: DateTime.parse(data['createdAt']),
        turnCount: data['turnCount'] ?? 0,
        history: (data['history'] as List?)
                ?.map((m) => _deserializeMessage(m))
                .whereType<DialogMessage>()
                .toList() ??
            [],
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '反序列化對話會話失敗，已跳過損壞記錄',
        error,
        stackTrace,
      );
      return null;
    }
  }

  /// 反序列化消息
  DialogMessage? _deserializeMessage(Map<String, dynamic> data) {
    try {
      return DialogMessage(
        role: MessageRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => MessageRole.user,
        ),
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
        imageUrl: data['imageUrl'],
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '反序列化對話消息失敗，已跳過損壞消息',
        error,
        stackTrace,
      );
      return null;
    }
  }

  /// 映射角色到字符串
  String _mapRoleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }
}

/// 對話統計信息
class DialogStatistics {
  final int totalMessages;
  final int userMessages;
  final int assistantMessages;
  final Duration duration;

  const DialogStatistics({
    required this.totalMessages,
    required this.userMessages,
    required this.assistantMessages,
    required this.duration,
  });

  factory DialogStatistics.empty() {
    return const DialogStatistics(
      totalMessages: 0,
      userMessages: 0,
      assistantMessages: 0,
      duration: Duration.zero,
    );
  }
}
