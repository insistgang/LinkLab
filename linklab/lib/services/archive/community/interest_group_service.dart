import 'package:flutter/material.dart' show Icons;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 兴趣小组服务
class InterestGroupService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 获取所有兴趣小组
  Future<List<InterestGroup>> getGroups() async {
    try {
      final response = await _supabase
          .from('interest_groups')
          .select()
          .order('member_count', ascending: false);

      return (response as List)
          .map((json) => InterestGroup.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取兴趣小组失败', e);
      return [];
    }
  }

  /// 获取用户加入的小组
  Future<List<InterestGroup>> getMyGroups(String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('group_id, interest_groups(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((json) => InterestGroup.fromJson(json['interest_groups']))
          .toList();
    } catch (e) {
      AppLogger.error('获取我的小组失败', e);
      return [];
    }
  }

  /// 创建兴趣小组
  Future<void> createGroup(
    String name,
    String description,
    String category, {
    String? iconUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      // 创建小组
      final groupResponse = await _supabase
          .from('interest_groups')
          .insert({
            'name': name,
            'description': description,
            'category': category,
            'icon_url': iconUrl,
            'member_count': 1,
            'post_count': 0,
            'created_by': userId,
          })
          .select()
          .single();

      // 自动加入小组
      await _supabase.from('group_members').insert({
        'group_id': groupResponse['id'],
        'user_id': userId,
        'role': 'admin',
      });

      AppLogger.info('创建兴趣小组成功: $name');
    } catch (e) {
      AppLogger.error('创建兴趣小组失败', e);
      rethrow;
    }
  }

  /// 加入小组
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      // 检查是否已加入
      final existing = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用户已在小组中');
        return;
      }

      // 加入小组
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      // 更新成员数
      await _supabase.rpc('increment_group_member_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('加入小组成功: $groupId');
    } catch (e) {
      AppLogger.error('加入小组失败', e);
      rethrow;
    }
  }

  /// 离开小组
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // 更新成员数
      await _supabase.rpc('decrement_group_member_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('离开小组成功: $groupId');
    } catch (e) {
      AppLogger.error('离开小组失败', e);
      rethrow;
    }
  }

  /// 获取小组消息
  Future<List<GroupMessage>> getMessages(
    String groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('group_messages')
          .select('*, users(name, avatar_url)')
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        final userData = json['users'] as Map<String, dynamic>?;
        return GroupMessage.fromJson({
          ...json,
          'user_name': userData?['name'] ?? '匿名用户',
          'user_avatar': userData?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      AppLogger.error('获取小组消息失败', e);
      return [];
    }
  }

  /// 发送消息
  Future<void> postMessage(
    String groupId,
    String userId,
    String content, {
    List<String> attachments = const [],
  }) async {
    try {
      await _supabase.from('group_messages').insert({
        'group_id': groupId,
        'user_id': userId,
        'content': content,
        'attachments': attachments,
      });

      // 更新帖子数
      await _supabase.rpc('increment_group_post_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('发送消息成功: $groupId');
    } catch (e) {
      AppLogger.error('发送消息失败', e);
      rethrow;
    }
  }

  /// 点赞消息
  Future<void> likeMessage(String messageId, String userId) async {
    try {
      await _supabase.from('message_likes').insert({
        'message_id': messageId,
        'user_id': userId,
      });

      AppLogger.info('点赞消息成功: $messageId');
    } catch (e) {
      AppLogger.error('点赞消息失败', e);
      rethrow;
    }
  }

  /// 取消点赞
  Future<void> unlikeMessage(String messageId, String userId) async {
    try {
      await _supabase
          .from('message_likes')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);

      AppLogger.info('取消点赞成功: $messageId');
    } catch (e) {
      AppLogger.error('取消点赞失败', e);
      rethrow;
    }
  }

  /// 获取预设小组列表
  List<Map<String, dynamic>> getPresetGroups() {
    return [
      {
        'id': 'preset_medical',
        'name': '医疗辅助组',
        'description': '协助视障人士识别药品、阅读医疗说明、理解医嘱等医疗相关帮助',
        'category': GroupCategory.medical,
        'icon': Icons.local_hospital,
      },
      {
        'id': 'preset_translation',
        'name': '外语翻译组',
        'description': '帮助视障人士阅读外文材料、翻译标识、理解外语内容',
        'category': GroupCategory.translation,
        'icon': Icons.translate,
      },
      {
        'id': 'preset_psychological',
        'name': '心理支持组',
        'description': '提供情感支持、倾听倾诉、心理健康指导等心理援助',
        'category': GroupCategory.psychological,
        'icon': Icons.favorite,
      },
      {
        'id': 'preset_technical',
        'name': '技术指导组',
        'description': '指导视障人士使用辅助技术、APP操作、设备设置等技术问题',
        'category': GroupCategory.technical,
        'icon': Icons.computer,
      },
    ];
  }

  /// 初始化预设小组
  Future<void> initializePresetGroups() async {
    try {
      final presetGroups = getPresetGroups();

      for (final group in presetGroups) {
        // 检查是否已存在
        final existing = await _supabase
            .from('interest_groups')
            .select()
            .eq('category', group['category'])
            .eq('is_preset', true)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('interest_groups').insert({
            'name': group['name'],
            'description': group['description'],
            'category': group['category'],
            'is_preset': true,
            'member_count': 0,
            'post_count': 0,
          });
        }
      }

      AppLogger.info('预设小组初始化完成');
    } catch (e) {
      AppLogger.error('初始化预设小组失败', e);
    }
  }

  /// 订阅小组消息实时更新
  RealtimeChannel subscribeToMessages(
    String groupId, {
    required Function(GroupMessage) onNewMessage,
  }) {
    return _supabase
        .channel('group_messages:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final message = GroupMessage.fromJson(payload.newRecord);
            onNewMessage(message);
          },
        )
        .subscribe();
  }
}
