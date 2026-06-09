import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../core/utils/logger.dart';
import '../../models/help_request_model.dart';
import '../local_storage.dart' as app_storage;

/// 異步任務服務 (F10/F22)
/// 兼容 Supabase 與本地演示模式
class AsyncTaskService {
  AsyncTaskService({
    SupabaseClient? supabase,
    app_storage.LocalStorage? storage,
  })  : _supabaseClient = supabase,
        _storage = storage ?? app_storage.LocalStorage();

  SupabaseClient? _supabaseClient;
  final app_storage.LocalStorage _storage;
  bool _localInitialized = false;

  bool get _hasSupabase => Supabase.instance.isInitialized;

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  Future<void> _ensureLocalStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  /// 創建異步留言任務
  Future<AsyncTaskModel?> createTask({
    required String seekerId,
    required String taskType,
    required String description,
    String? attachmentLabel,
  }) async {
    final now = DateTime.now();
    final helpRequestId = 'async_help_${now.microsecondsSinceEpoch}';
    final task = AsyncTaskModel(
      id: 'task_${now.microsecondsSinceEpoch}',
      helpRequestId: helpRequestId,
      seekerId: seekerId,
      taskType: taskType,
      description: attachmentLabel == null
          ? description.trim()
          : '${description.trim()}\n\n附件：$attachmentLabel',
      status: 'pending',
      createdAt: now,
    );

    if (!_hasSupabase) {
      try {
        final tasks = await _getAllLocalTasks();
        tasks.insert(0, task);
        await _saveLocalTasks(tasks);
        await _upsertLocalHelpRequest(task);
        return task;
      } catch (e) {
        AppLogger.error('創建本地異步任務失敗', e);
        return null;
      }
    }

    try {
      await _supabase.from('help_requests').insert({
        'id': helpRequestId,
        'seeker_id': seekerId,
        'type': 'async',
        'intent': description.trim(),
        'urgency': 'normal',
        'status': 'created',
        'created_at': now.toIso8601String(),
      });

      await _supabase.from('async_tasks').insert({
        'id': task.id,
        'help_request_id': helpRequestId,
        'seeker_id': seekerId,
        'task_type': taskType,
        'description': task.description,
        'status': 'pending',
        'created_at': now.toIso8601String(),
      });

      return task;
    } catch (e) {
      AppLogger.error('創建異步任務失敗', e);
      return null;
    }
  }

  /// 求助者查看自己的異步留言
  Future<List<AsyncTaskModel>> getSeekerTasks(
    String seekerId, {
    String? status,
    int limit = 20,
  }) async {
    if (!_hasSupabase) {
      final tasks = (await _getAllLocalTasks())
          .where((task) => task.seekerId == seekerId)
          .where((task) => status == null || task.status == status)
          .toList();

      tasks.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );

      return tasks.length > limit ? tasks.sublist(0, limit) : tasks;
    }

    try {
      dynamic query = _supabase
          .from('async_tasks')
          .select()
          .eq('seeker_id', seekerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => _taskFromStorageOrSupabaseJson(_mapJson(json)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取求助者異步任務失敗', e);
      return [];
    }
  }

  /// 獲取可領取的異步任務列表
  Future<List<AsyncTaskModel>> getAvailableTasks(
    String volunteerId, {
    AsyncTaskFilter? filter,
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_hasSupabase) {
      final tasks = await _getAllLocalTasks();
      var filtered = tasks
          .where((task) => task.status == 'pending' && task.volunteerId == null)
          .toList();

      if (filter?.taskType != null) {
        filtered = filtered
            .where((task) => task.taskType == filter!.taskType)
            .toList();
      }

      filtered.sort(
        (a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()),
      );

      if (offset >= filtered.length) {
        return [];
      }

      final end = (offset + limit).clamp(0, filtered.length).toInt();
      return filtered.sublist(offset, end);
    }

    try {
      final profileData = _mapJson(
        await _supabase
          .from('volunteer_profiles')
          .select('skills, level')
          .eq('user_id', volunteerId)
          .single(),
      );

      final skills = (profileData['skills'] as List?)?.cast<String>() ?? [];
      final level = (profileData['level'] as num?)?.toInt() ?? 1;

      if (level < 2) {
        return [];
      }

      dynamic query = _supabase
          .from('async_tasks')
          .select('''
            *,
            seeker:seeker_id(name, avatar_url)
          ''')
          .eq('status', 'pending')
          .isFilter('volunteer_id', null);

      if (filter?.taskType != null) {
        query = query.eq('task_type', filter!.taskType!);
      }

      if (filter?.timeRange != null) {
        final startTime = DateTime.now().subtract(filter!.timeRange!);
        query = query.gte('created_at', startTime.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      final tasks = (response as List)
          .map((json) => _taskFromStorageOrSupabaseJson(_mapJson(json)))
          .toList();

      if (skills.isNotEmpty) {
        tasks.sort((a, b) {
          final aMatch = skills.any(
            (skill) => a.taskType.toLowerCase().contains(skill.toLowerCase()),
          );
          final bMatch = skills.any(
            (skill) => b.taskType.toLowerCase().contains(skill.toLowerCase()),
          );
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return 0;
        });
      }

      return tasks;
    } catch (e) {
      AppLogger.error('獲取異步任務失敗', e);
      return [];
    }
  }

  /// 領取任務
  Future<bool> claimTask(String taskId, String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final tasks = await _getAllLocalTasks();
        final index = tasks.indexWhere((task) => task.id == taskId);
        if (index == -1) return false;

        final task = tasks[index];
        if (task.status != 'pending' || task.volunteerId != null) {
          return false;
        }

        final updated = task.copyWith(
          volunteerId: volunteerId,
          status: 'assigned',
          assignedAt: DateTime.now(),
        );
        tasks[index] = updated;
        await _saveLocalTasks(tasks);
        await _upsertLocalHelpRequest(updated);
        return true;
      } catch (e) {
        AppLogger.error('領取本地異步任務失敗', e);
        return false;
      }
    }

    try {
      final profileData = _mapJson(
        await _supabase
          .from('volunteer_profiles')
          .select('level')
          .eq('user_id', volunteerId)
          .single(),
      );

      final level = (profileData['level'] as num?)?.toInt() ?? 1;
      if (level < 2) {
        AppLogger.warning('志願者等級不足，無法領取異步任務: $volunteerId');
        return false;
      }

      final taskData = _mapJson(
        await _supabase
          .from('async_tasks')
          .select('status, volunteer_id')
          .eq('id', taskId)
          .single(),
      );

      if (taskData['status'] != 'pending' || taskData['volunteer_id'] != null) {
        AppLogger.warning('任務已被領取或狀態不正確: $taskId');
        return false;
      }

      await _supabase.from('async_tasks').update({
        'volunteer_id': volunteerId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      return true;
    } catch (e) {
      AppLogger.error('領取異步任務失敗', e);
      return false;
    }
  }

  /// 完成任務（簡化版）
  Future<bool> completeTask(String taskId, String result) async {
    if (!_hasSupabase) {
      try {
        final tasks = await _getAllLocalTasks();
        final index = tasks.indexWhere((task) => task.id == taskId);
        if (index == -1) return false;

        final current = tasks[index];
        final updated = current.copyWith(
          status: 'completed',
          result: result.trim(),
          completedAt: DateTime.now(),
          volunteerId: current.volunteerId ?? 'demo-volunteer-async',
        );
        tasks[index] = updated;
        await _saveLocalTasks(tasks);
        await _upsertLocalHelpRequest(updated);
        return true;
      } catch (e) {
        AppLogger.error('完成本地異步任務失敗', e);
        return false;
      }
    }

    try {
      await _supabase.from('async_tasks').update({
        'status': 'completed',
        'result': result,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      AppLogger.error('完成異步任務失敗', e);
      return false;
    }
  }

  /// 完成任務（完整版）
  Future<bool> completeTaskWithVolunteer(
    String taskId,
    String volunteerId,
    String response, {
    List<String>? attachments,
  }) async {
    if (!_hasSupabase) {
      return completeTask(taskId, response);
    }

    try {
      final taskData = _mapJson(
        await _supabase
          .from('async_tasks')
          .select('volunteer_id, status, help_request_id')
          .eq('id', taskId)
          .single(),
      );

      if (taskData['volunteer_id'] != volunteerId) {
        AppLogger.warning('無權完成此任務: $taskId');
        return false;
      }

      if (taskData['status'] == 'completed') {
        return true;
      }

      await _supabase.from('async_tasks').update({
        'status': 'completed',
        'result': response,
        'attachments': attachments,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      final helpRequestId = taskData['help_request_id'] as String?;
      if (helpRequestId != null) {
        await _supabase.from('help_requests').update({
          'status': 'completed',
          'volunteer_id': volunteerId,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', helpRequestId);
      }

      return true;
    } catch (e) {
      AppLogger.error('完成異步任務失敗', e);
      return false;
    }
  }

  /// 放棄任務
  Future<bool> abandonTask(
    String taskId,
    String volunteerId, {
    String? reason,
  }) async {
    if (!_hasSupabase) {
      try {
        final tasks = await _getAllLocalTasks();
        final index = tasks.indexWhere((task) => task.id == taskId);
        if (index == -1) return false;
        if (tasks[index].volunteerId != volunteerId) return false;

        final updated = tasks[index].copyWith(
          volunteerId: null,
          status: 'pending',
          assignedAt: null,
        );
        tasks[index] = updated;
        await _saveLocalTasks(tasks);
        await _upsertLocalHelpRequest(updated);
        return true;
      } catch (e) {
        AppLogger.error('放棄本地異步任務失敗', e);
        return false;
      }
    }

    try {
      final taskData = _mapJson(
        await _supabase
          .from('async_tasks')
          .select('volunteer_id, status')
          .eq('id', taskId)
          .single(),
      );

      if (taskData['volunteer_id'] != volunteerId) {
        return false;
      }

      await _supabase.from('async_tasks').update({
        'volunteer_id': null,
        'status': 'pending',
        'assigned_at': null,
        'abandon_reason': reason,
      }).eq('id', taskId);

      return true;
    } catch (e) {
      AppLogger.error('放棄異步任務失敗', e);
      return false;
    }
  }

  /// 獲取我的任務列表
  Future<List<AsyncTaskModel>> getMyTasks(
    String volunteerId, {
    String? status,
    int limit = 20,
  }) async {
    if (!_hasSupabase) {
      final tasks = (await _getAllLocalTasks())
          .where((task) => task.volunteerId == volunteerId)
          .where((task) => status == null || task.status == status)
          .toList();

      tasks.sort(
        (a, b) => (b.assignedAt ?? b.createdAt ?? DateTime.now()).compareTo(
          a.assignedAt ?? a.createdAt ?? DateTime.now(),
        ),
      );

      return tasks.length > limit ? tasks.sublist(0, limit) : tasks;
    }

    try {
      dynamic query = _supabase
          .from('async_tasks')
          .select('''
            *,
            seeker:seeker_id(name, avatar_url)
          ''')
          .eq('volunteer_id', volunteerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('assigned_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => _taskFromStorageOrSupabaseJson(_mapJson(json)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取我的任務失敗', e);
      return [];
    }
  }

  /// 獲取任務詳情
  Future<AsyncTaskModel?> getTaskDetail(String taskId) async {
    if (!_hasSupabase) {
      try {
        final tasks = await _getAllLocalTasks();
        return tasks.firstWhere((task) => task.id == taskId);
      } catch (_) {
        return null;
      }
    }

    try {
      final response = await _supabase
          .from('async_tasks')
          .select('''
            *,
            seeker:seeker_id(name, avatar_url),
            help_request:help_request_id(intent, images)
          ''')
          .eq('id', taskId)
          .single();

      return _taskFromStorageOrSupabaseJson(_mapJson(response));
    } catch (e) {
      AppLogger.error('獲取任務詳情失敗', e);
      return null;
    }
  }

  /// 檢查超時任務並重新分配
  Future<void> checkAndReassignExpiredTasks() async {
    if (!_hasSupabase) {
      final tasks = await _getAllLocalTasks();
      var changed = false;
      final expiredAt = DateTime.now().subtract(const Duration(hours: 24));

      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (task.status == 'assigned' &&
            task.assignedAt != null &&
            task.assignedAt!.isBefore(expiredAt)) {
          tasks[i] = task.copyWith(
            status: 'pending',
            volunteerId: null,
            assignedAt: null,
          );
          await _upsertLocalHelpRequest(tasks[i]);
          changed = true;
        }
      }

      if (changed) {
        await _saveLocalTasks(tasks);
      }
      return;
    }

    try {
      final expiredTime = DateTime.now().subtract(const Duration(hours: 24));
      final expiredTasks = await _supabase
          .from('async_tasks')
          .select()
          .eq('status', 'assigned')
          .lt('assigned_at', expiredTime.toIso8601String());

      for (final task in expiredTasks as List) {
        final taskData = _mapJson(task);
        final expiredTaskId = taskData['id'] as String?;
        if (expiredTaskId == null) {
          continue;
        }
        await _supabase.from('async_tasks').update({
          'volunteer_id': null,
          'status': 'pending',
          'assigned_at': null,
        }).eq('id', expiredTaskId);
      }
    } catch (e) {
      AppLogger.error('檢查超時任務失敗', e);
    }
  }

  /// 獲取任務統計
  Future<AsyncTaskStats> getTaskStats(String volunteerId) async {
    if (!_hasSupabase) {
      final tasks = await _getAllLocalTasks();
      final mine = tasks.where((task) => task.volunteerId == volunteerId).toList();
      final pendingCount = mine.where((task) => task.status == 'pending').length;
      final assignedCount = mine
          .where((task) => task.status == 'assigned' || task.status == 'processing')
          .length;
      final completedCount =
          mine.where((task) => task.status == 'completed').length;
      final cancelledCount =
          mine.where((task) => task.status == 'cancelled').length;

      return AsyncTaskStats(
        pendingCount: pendingCount,
        assignedCount: assignedCount,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );
    }

    try {
      final statuses = ['pending', 'assigned', 'completed', 'cancelled'];
      final stats = <String, int>{};

      for (final status in statuses) {
        final response = await _supabase
            .from('async_tasks')
            .select()
            .eq('volunteer_id', volunteerId)
            .eq('status', status)
            .count(CountOption.exact);

        stats[status] = response.count;
      }

      final completedTasks = await _supabase
          .from('async_tasks')
          .select('created_at, assigned_at, completed_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed');

      int totalResponseMinutes = 0;
      int totalCompletionMinutes = 0;

      for (final task in completedTasks as List) {
        final taskData = _mapJson(task);
        final createdAt = DateTime.parse(taskData['created_at'] as String);
        final assignedAt = taskData['assigned_at'] != null
            ? DateTime.parse(taskData['assigned_at'] as String)
            : null;
        final completedAt = taskData['completed_at'] != null
            ? DateTime.parse(taskData['completed_at'] as String)
            : null;

        if (assignedAt != null) {
          totalResponseMinutes += assignedAt.difference(createdAt).inMinutes;
        }
        if (completedAt != null && assignedAt != null) {
          totalCompletionMinutes +=
              completedAt.difference(assignedAt).inMinutes;
        }
      }

      final completedCount = completedTasks.length;

      return AsyncTaskStats(
        pendingCount: stats['pending'] ?? 0,
        assignedCount: stats['assigned'] ?? 0,
        completedCount: completedCount,
        cancelledCount: stats['cancelled'] ?? 0,
        averageResponseMinutes:
            completedCount > 0 ? totalResponseMinutes ~/ completedCount : 0,
        averageCompletionMinutes:
            completedCount > 0 ? totalCompletionMinutes ~/ completedCount : 0,
      );
    } catch (e) {
      AppLogger.error('獲取任務統計失敗', e);
      return const AsyncTaskStats();
    }
  }

  /// 添加任務回覆
  Future<bool> addTaskResponse(
    String taskId,
    String volunteerId,
    String content, {
    List<String>? attachments,
  }) async {
    if (!_hasSupabase) {
      return completeTask(taskId, content);
    }

    try {
      await _supabase.from('task_responses').insert({
        'task_id': taskId,
        'volunteer_id': volunteerId,
        'content': content,
        'attachments': attachments,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      AppLogger.error('添加任務回覆失敗', e);
      return false;
    }
  }

  /// 獲取任務回覆列表
  Future<List<TaskResponse>> getTaskResponses(String taskId) async {
    if (!_hasSupabase) {
      final task = await getTaskDetail(taskId);
      if (task?.result == null || task!.result!.trim().isEmpty) {
        return [];
      }

      return [
        TaskResponse(
          id: 'response_$taskId',
          taskId: taskId,
          volunteerId: task.volunteerId ?? 'demo-volunteer-async',
          content: task.result!,
          createdAt: task.completedAt ?? task.createdAt ?? DateTime.now(),
        ),
      ];
    }

    try {
      final response = await _supabase
          .from('task_responses')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => TaskResponse.fromJson(_mapJson(json)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取任務回覆失敗', e);
      return [];
    }
  }

  Future<List<AsyncTaskModel>> _getAllLocalTasks() async {
    await _ensureLocalStorage();
    return _storage
        .getAsyncTasks()
        .map((json) => AsyncTaskModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _saveLocalTasks(List<AsyncTaskModel> tasks) async {
    await _ensureLocalStorage();
    final normalized = List<AsyncTaskModel>.from(tasks)
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );

    await _storage.saveAsyncTasks(
      normalized.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> _upsertLocalHelpRequest(AsyncTaskModel task) async {
    await _ensureLocalStorage();
    final history = _storage.getHelpHistory();
    final index = history.indexWhere((item) => item['id'] == task.helpRequestId);

    final payload = <String, dynamic>{
      'id': task.helpRequestId,
      'seekerId': task.seekerId,
      'type': 'async',
      'intent': task.description,
      'urgency': 'normal',
      'status': task.isCompleted ? 'completed' : 'created',
      'volunteerId': task.volunteerId,
      'aiResponse': task.result == null
          ? null
          : {
              'summary': task.result,
            },
      'createdAt': task.createdAt?.toIso8601String(),
      'matchedAt': task.assignedAt?.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
    };

    if (index >= 0) {
      history[index] = payload;
    } else {
      history.insert(0, payload);
    }

    history.sort((a, b) {
      final aTime = DateTime.tryParse('${a['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse('${b['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    await _storage.setString(
      app_storage.StorageKeys.helpHistory,
      jsonEncode(history),
    );
  }

  AsyncTaskModel _taskFromStorageOrSupabaseJson(Map<String, dynamic> json) {
    return AsyncTaskModel.fromJson({
      'id': json['id'],
      'helpRequestId': json['helpRequestId'] ?? json['help_request_id'] ?? json['id'],
      'seekerId': json['seekerId'] ?? json['seeker_id'],
      'volunteerId': json['volunteerId'] ?? json['volunteer_id'],
      'taskType': json['taskType'] ?? json['task_type'] ?? '異步求助',
      'description': json['description'] ?? '',
      'imageUrl': json['imageUrl'] ?? json['image_url'] ?? json['content_url'],
      'status': json['status'] as String?,
      'result': json['result']?.toString(),
      'createdAt': json['createdAt'] ?? json['created_at'],
      'assignedAt': json['assignedAt'] ?? json['assigned_at'],
      'completedAt': json['completedAt'] ?? json['completed_at'],
    });
  }

  Map<String, dynamic> _mapJson(dynamic json) {
    return Map<String, dynamic>.from(json as Map);
  }
}

/// 異步任務篩選條件
class AsyncTaskFilter {
  final String? taskType;
  final double? latitude;
  final double? longitude;
  final double? maxDistance;
  final Duration? timeRange;

  AsyncTaskFilter({
    this.taskType,
    this.latitude,
    this.longitude,
    this.maxDistance,
    this.timeRange,
  });
}

/// 任務統計
class AsyncTaskStats {
  final int pendingCount;
  final int assignedCount;
  final int completedCount;
  final int cancelledCount;
  final int averageResponseMinutes;
  final int averageCompletionMinutes;

  const AsyncTaskStats({
    this.pendingCount = 0,
    this.assignedCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.averageResponseMinutes = 0,
    this.averageCompletionMinutes = 0,
  });

  int get totalCount =>
      pendingCount + assignedCount + completedCount + cancelledCount;

  double get completionRate {
    if (totalCount == 0) return 0;
    return completedCount / totalCount;
  }
}

/// 任務回覆
class TaskResponse {
  final String id;
  final String taskId;
  final String volunteerId;
  final String content;
  final List<String>? attachments;
  final DateTime createdAt;

  TaskResponse({
    required this.id,
    required this.taskId,
    required this.volunteerId,
    required this.content,
    this.attachments,
    required this.createdAt,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      id: json['id'] as String,
      taskId: (json['taskId'] ?? json['task_id']) as String,
      volunteerId: (json['volunteerId'] ?? json['volunteer_id']) as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List?)?.cast<String>(),
      createdAt:
          DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    );
  }
}
