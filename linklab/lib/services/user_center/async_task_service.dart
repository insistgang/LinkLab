import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/help_request_model.dart';

/// 异步任务服务 (F22)
/// 管理志愿者的异步任务队列
class AsyncTaskService {
  final SupabaseClient _supabase;

  AsyncTaskService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 获取可领取的异步任务列表
  /// [volunteerId] 志愿者ID
  /// [filters] 筛选条件
  Future<List<AsyncTaskModel>> getAvailableTasks(
    String volunteerId, {
    AsyncTaskFilter? filter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 获取志愿者的技能标签
      final profileResponse = await _supabase
          .from('volunteer_profiles')
          .select('skills, level')
          .eq('user_id', volunteerId)
          .single();

      final skills = (profileResponse['skills'] as List?)?.cast<String>() ?? [];
      final level = profileResponse['level'] ?? 1;

      // Lv2以下不能领取异步任务
      if (level < 2) {
        return [];
      }

      // 构建查询
      var query = _supabase
          .from('async_tasks')
          .select('''
            *,
            seeker:seeker_id(name, avatar_url)
          ''')
          .eq('status', 'pending')
          .isFilter('volunteer_id', null);

      // 应用筛选
      if (filter?.taskType != null) {
        query = query.eq('task_type', filter!.taskType!);
      }

      if (filter?.maxDistance != null && filter?.latitude != null && filter?.longitude != null) {
        // 距离筛选（需要PostGIS支持）
        query = query.ilike('location', '%${filter!.latitude},${filter.longitude}%');
      }

      if (filter?.timeRange != null) {
        final now = DateTime.now();
        final range = filter!.timeRange!;
        final startTime = now.subtract(range);
        query = query.gte('created_at', startTime.toIso8601String());
      }

      // 按技能匹配度排序（简单实现：优先显示匹配技能的任务）
      final response = await query
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      final tasks = (response as List).map((json) {
        // 合并求助者信息
        final seeker = json['seeker'];
        if (seeker != null) {
          json['seeker_name'] = seeker['name'];
          json['seeker_avatar'] = seeker['avatar_url'];
        }
        return AsyncTaskModel.fromJson(json);
      }).toList();

      // 按技能匹配度排序
      if (skills.isNotEmpty) {
        tasks.sort((a, b) {
          final aMatch = skills.any((s) =>
              a.taskType.toLowerCase().contains(s.toLowerCase()));
          final bMatch = skills.any((s) =>
              b.taskType.toLowerCase().contains(s.toLowerCase()));

          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return 0;
        });
      }

      return tasks;
    } catch (e) {
      AppLogger.error('获取异步任务失败', e);
      return [];
    }
  }

  /// 领取任务
  Future<bool> claimTask(String taskId, String volunteerId) async {
    try {
      // 检查志愿者等级
      final profileResponse = await _supabase
          .from('volunteer_profiles')
          .select('level')
          .eq('user_id', volunteerId)
          .single();

      final level = profileResponse['level'] ?? 1;
      if (level < 2) {
        AppLogger.warning('志愿者等级不足，无法领取异步任务: $volunteerId');
        return false;
      }

      // 检查任务状态
      final taskResponse = await _supabase
          .from('async_tasks')
          .select('status, volunteer_id')
          .eq('id', taskId)
          .single();

      if (taskResponse['status'] != 'pending' ||
          taskResponse['volunteer_id'] != null) {
        AppLogger.warning('任务已被领取或状态不正确: $taskId');
        return false;
      }

      // 领取任务
      await _supabase.from('async_tasks').update({
        'volunteer_id': volunteerId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      AppLogger.info('志愿者领取异步任务: $volunteerId -> $taskId');
      return true;
    } catch (e) {
      AppLogger.error('领取异步任务失败', e);
      return false;
    }
  }

  /// 完成任务（简化版，兼容UI调用）
  Future<bool> completeTask(String taskId, String result) async {
    try {
      await _supabase.from('async_tasks').update({
        'status': 'completed',
        'result': result,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      return true;
    } catch (e) {
      AppLogger.error('完成异步任务失败', e);
      return false;
    }
  }

  /// 完成任务（完整版）
  Future<bool> completeTaskWithVolunteer(
    String taskId,
    String volunteerId,
    String response, {
    List<String>? attachments,
  }) async {
    try {
      // 验证任务归属
      final taskResponse = await _supabase
          .from('async_tasks')
          .select('volunteer_id, status')
          .eq('id', taskId)
          .single();

      if (taskResponse['volunteer_id'] != volunteerId) {
        AppLogger.warning('无权完成此任务: $taskId');
        return false;
      }

      if (taskResponse['status'] == 'completed') {
        return true; // 已完成
      }

      // 更新任务状态
      await _supabase.from('async_tasks').update({
        'status': 'completed',
        'result': response,
        'attachments': attachments,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      // 更新关联的帮助请求状态
      await _supabase
          .from('help_requests')
          .update({'status': 'completed'})
          .eq('id', taskId);

      AppLogger.info('异步任务完成: $taskId');
      return true;
    } catch (e) {
      AppLogger.error('完成异步任务失败', e);
      return false;
    }
  }

  /// 放弃任务
  Future<bool> abandonTask(String taskId, String volunteerId, {String? reason}) async {
    try {
      // 验证任务归属
      final taskResponse = await _supabase
          .from('async_tasks')
          .select('volunteer_id, status')
          .eq('id', taskId)
          .single();

      if (taskResponse['volunteer_id'] != volunteerId) {
        return false;
      }

      // 重置任务状态
      await _supabase.from('async_tasks').update({
        'volunteer_id': null,
        'status': 'pending',
        'assigned_at': null,
        'abandon_reason': reason,
      }).eq('id', taskId);

      AppLogger.info('志愿者放弃异步任务: $volunteerId -> $taskId, 原因: $reason');
      return true;
    } catch (e) {
      AppLogger.error('放弃异步任务失败', e);
      return false;
    }
  }

  /// 获取我的任务列表
  Future<List<AsyncTaskModel>> getMyTasks(
    String volunteerId, {
    String? status,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('async_tasks')
          .select('''
            *,
            seeker:seeker_id(name, avatar_url)
          ''')
          .eq('volunteer_id', volunteerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('assigned_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        final seeker = json['seeker'];
        if (seeker != null) {
          json['seeker_name'] = seeker['name'];
          json['seeker_avatar'] = seeker['avatar_url'];
        }
        return AsyncTaskModel.fromJson(json);
      }).toList();
    } catch (e) {
      AppLogger.error('获取我的任务失败', e);
      return [];
    }
  }

  /// 获取任务详情
  Future<AsyncTaskModel?> getTaskDetail(String taskId) async {
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

      return AsyncTaskModel.fromJson(response);
    } catch (e) {
      AppLogger.error('获取任务详情失败', e);
      return null;
    }
  }

  /// 检查超时任务并重新分配
  Future<void> checkAndReassignExpiredTasks() async {
    try {
      final expiredTime = DateTime.now().subtract(const Duration(hours: 24));

      final expiredTasks = await _supabase
          .from('async_tasks')
          .select()
          .eq('status', 'assigned')
          .lt('assigned_at', expiredTime.toIso8601String());

      for (final task in expiredTasks as List) {
        // 重置任务状态
        await _supabase.from('async_tasks').update({
          'volunteer_id': null,
          'status': 'pending',
          'assigned_at': null,
        }).eq('id', task['id']);

        AppLogger.info('任务超时重新分配: ${task['id']}');
      }
    } catch (e) {
      AppLogger.error('检查超时任务失败', e);
    }
  }

  /// 获取任务统计
  Future<AsyncTaskStats> getTaskStats(String volunteerId) async {
    try {
      // 获取各种状态的任务数
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

      // 计算平均响应时间
      final completedTasks = await _supabase
          .from('async_tasks')
          .select('created_at, assigned_at, completed_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed');

      int totalResponseMinutes = 0;
      int totalCompletionMinutes = 0;

      for (final task in completedTasks as List) {
        final createdAt = DateTime.parse(task['created_at']);
        final assignedAt = task['assigned_at'] != null
            ? DateTime.parse(task['assigned_at'])
            : null;
        final completedAt = task['completed_at'] != null
            ? DateTime.parse(task['completed_at'])
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
        averageResponseMinutes: completedCount > 0
            ? totalResponseMinutes ~/ completedCount
            : 0,
        averageCompletionMinutes: completedCount > 0
            ? totalCompletionMinutes ~/ completedCount
            : 0,
      );
    } catch (e) {
      AppLogger.error('获取任务统计失败', e);
      return const AsyncTaskStats();
    }
  }

  /// 添加任务回复
  Future<bool> addTaskResponse(
    String taskId,
    String volunteerId,
    String content, {
    List<String>? attachments,
  }) async {
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
      AppLogger.error('添加任务回复失败', e);
      return false;
    }
  }

  /// 获取任务回复列表
  Future<List<TaskResponse>> getTaskResponses(String taskId) async {
    try {
      final response = await _supabase
          .from('task_responses')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => TaskResponse.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取任务回复失败', e);
      return [];
    }
  }
}

/// 异步任务筛选条件
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

/// 任务统计
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

  /// 总任务数
  int get totalCount =>
      pendingCount + assignedCount + completedCount + cancelledCount;

  /// 完成率
  double get completionRate {
    if (totalCount == 0) return 0;
    return completedCount / totalCount;
  }
}

/// 任务回复
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
      id: json['id'],
      taskId: json['task_id'],
      volunteerId: json['volunteer_id'],
      content: json['content'],
      attachments: (json['attachments'] as List?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
