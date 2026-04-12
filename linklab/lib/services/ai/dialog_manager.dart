import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

/// 对话上下文管理器
/// 负责管理多轮对话的状态和历史记录
class DialogContextManager {
  static const String _storageKey = 'dialog_sessions';
  static const int _maxHistoryPerSession = 20;
  static const int _maxStoredSessions = 10;

  final SharedPreferences? _prefs;
  final Map<String, DialogContext> _activeSessions = {};

  DialogContextManager([this._prefs]);

  /// 创建新会话
  DialogContext createSession({String? userId}) {
    final session = DialogContext.create(userId: userId);
    _activeSessions[session.sessionId] = session;
    return session;
  }

  /// 获取或创建会话
  DialogContext getOrCreateSession(String? sessionId, {String? userId}) {
    if (sessionId != null && _activeSessions.containsKey(sessionId)) {
      return _activeSessions[sessionId]!;
    }
    return createSession(userId: userId);
  }

  /// 添加用户消息
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

  /// 添加系统消息
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

  /// 获取会话历史
  List<DialogMessage> getSessionHistory(String sessionId) {
    final session = _activeSessions[sessionId];
    return session?.history ?? [];
  }

  /// 获取格式化的对话历史（用于AI模型输入）
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

  /// 清除会话历史
  void clearSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  /// 结束会话并保存
  Future<void> endSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    // 保存到持久化存储
    await _saveSession(session);

    // 从活跃会话中移除
    _activeSessions.remove(sessionId);
  }

  /// 获取会话统计信息
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

  /// 检查会话是否超时（默认30分钟）
  bool isSessionTimeout(String sessionId, {Duration timeout = const Duration(minutes: 30)}) {
    final session = _activeSessions[sessionId];
    if (session == null) return true;

    final lastMessage = session.history.isNotEmpty
        ? session.history.last.timestamp
        : session.createdAt;

    return DateTime.now().difference(lastMessage) > timeout;
  }

  /// 清理超时会话
  void cleanupTimeoutSessions({Duration timeout = const Duration(minutes: 30)}) {
    final timeoutSessions = _activeSessions.entries
        .where((e) => isSessionTimeout(e.key, timeout: timeout))
        .map((e) => e.key)
        .toList();

    for (final sessionId in timeoutSessions) {
      _activeSessions.remove(sessionId);
    }
  }

  /// 保存会话到本地存储
  Future<void> _saveSession(DialogContext session) async {
    if (_prefs == null) return;

    try {
      final sessionsJson = _prefs!.getString(_storageKey);
      final Map<String, dynamic> sessions = sessionsJson != null
          ? jsonDecode(sessionsJson)
          : {};

      // 添加新会话
      sessions[session.sessionId] = _serializeSession(session);

      // 限制存储数量
      while (sessions.length > _maxStoredSessions) {
        final oldestKey = sessions.keys.first;
        sessions.remove(oldestKey);
      }

      await _prefs!.setString(_storageKey, jsonEncode(sessions));
    } catch (e) {
      // 存储失败不抛出异常
      print('Failed to save session: $e');
    }
  }

  /// 加载历史会话
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
    } catch (e) {
      print('Failed to load sessions: $e');
      return [];
    }
  }

  /// 序列化会话
  Map<String, dynamic> _serializeSession(DialogContext session) {
    return {
      'sessionId': session.sessionId,
      'userId': session.userId,
      'createdAt': session.createdAt.toIso8601String(),
      'turnCount': session.turnCount,
      'history': session.history.map((m) => m.toJson()).toList(),
    };
  }

  /// 反序列化会话
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
    } catch (e) {
      print('Failed to deserialize session: $e');
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
    } catch (e) {
      print('Failed to deserialize message: $e');
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

/// 对话统计信息
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
