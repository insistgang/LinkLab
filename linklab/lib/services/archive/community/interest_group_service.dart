import 'package:flutter/material.dart' show Icons;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 興趣小組服務
class InterestGroupService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 獲取所有興趣小組
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
      AppLogger.error('獲取興趣小組失敗', e);
      return [];
    }
  }

  /// 獲取用戶加入的小組
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
      AppLogger.error('獲取我的小組失敗', e);
      return [];
    }
  }

  /// 創建興趣小組
  Future<void> createGroup(
    String name,
    String description,
    String category, {
    String? iconUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 創建小組
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

      // 自動加入小組
      await _supabase.from('group_members').insert({
        'group_id': groupResponse['id'],
        'user_id': userId,
        'role': 'admin',
      });

      AppLogger.info('創建興趣小組成功: $name');
    } catch (e) {
      AppLogger.error('創建興趣小組失敗', e);
      rethrow;
    }
  }

  /// 加入小組
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      // 檢查是否已加入
      final existing = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用戶已在小組中');
        return;
      }

      // 加入小組
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      // 更新成員數
      await _supabase.rpc('increment_group_member_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('加入小組成功: $groupId');
    } catch (e) {
      AppLogger.error('加入小組失敗', e);
      rethrow;
    }
  }

  /// 離開小組
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // 更新成員數
      await _supabase.rpc('decrement_group_member_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('離開小組成功: $groupId');
    } catch (e) {
      AppLogger.error('離開小組失敗', e);
      rethrow;
    }
  }

  /// 獲取小組消息
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
          'user_name': userData?['name'] ?? '匿名用戶',
          'user_avatar': userData?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      AppLogger.error('獲取小組消息失敗', e);
      return [];
    }
  }

  /// 發送消息
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

      // 更新帖子數
      await _supabase.rpc('increment_group_post_count', params: {
        'group_id': groupId,
      });

      AppLogger.info('發送消息成功: $groupId');
    } catch (e) {
      AppLogger.error('發送消息失敗', e);
      rethrow;
    }
  }

  /// 點贊消息
  Future<void> likeMessage(String messageId, String userId) async {
    try {
      await _supabase.from('message_likes').insert({
        'message_id': messageId,
        'user_id': userId,
      });

      AppLogger.info('點贊消息成功: $messageId');
    } catch (e) {
      AppLogger.error('點贊消息失敗', e);
      rethrow;
    }
  }

  /// 取消點贊
  Future<void> unlikeMessage(String messageId, String userId) async {
    try {
      await _supabase
          .from('message_likes')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);

      AppLogger.info('取消點贊成功: $messageId');
    } catch (e) {
      AppLogger.error('取消點贊失敗', e);
      rethrow;
    }
  }

  /// 獲取預設小組列表
  List<Map<String, dynamic>> getPresetGroups() {
    return [
      {
        'id': 'preset_medical',
        'name': '醫療輔助組',
        'description': '協助視障人士識別藥品、閱讀醫療說明、理解醫囑等醫療相關幫助',
        'category': GroupCategory.medical,
        'icon': Icons.local_hospital,
      },
      {
        'id': 'preset_translation',
        'name': '外語翻譯組',
        'description': '幫助視障人士閱讀外文材料、翻譯標識、理解外語內容',
        'category': GroupCategory.translation,
        'icon': Icons.translate,
      },
      {
        'id': 'preset_psychological',
        'name': '心理支持組',
        'description': '提供情感支持、傾聽傾訴、心理健康指導等心理援助',
        'category': GroupCategory.psychological,
        'icon': Icons.favorite,
      },
      {
        'id': 'preset_technical',
        'name': '技術指導組',
        'description': '指導視障人士使用輔助技術、APP操作、設備設置等技術問題',
        'category': GroupCategory.technical,
        'icon': Icons.computer,
      },
    ];
  }

  /// 初始化預設小組
  Future<void> initializePresetGroups() async {
    try {
      final presetGroups = getPresetGroups();

      for (final group in presetGroups) {
        // 檢查是否已存在
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

      AppLogger.info('預設小組初始化完成');
    } catch (e) {
      AppLogger.error('初始化預設小組失敗', e);
    }
  }

  /// 訂閱小組消息實時更新
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
