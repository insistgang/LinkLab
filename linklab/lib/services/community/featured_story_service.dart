import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 每日精选故事服务
class FeaturedStoryService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 提交故事
  Future<void> submitStory({
    required String title,
    required String content,
    String? summary,
    String? coverImage,
    String authorType = 'anonymous',
    String? authorName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      await _supabase.from('featured_stories').insert({
        'title': title,
        'content': content,
        'summary': summary ?? _generateSummary(content),
        'cover_image': coverImage,
        'author_type': authorType,
        'author_name': authorType == 'anonymous' ? null : (authorName ?? '匿名用户'),
        'submitted_by': userId,
        'status': 'pending',
        'like_count': 0,
        'read_count': 0,
      });

      AppLogger.info('提交故事成功: $title');
    } catch (e) {
      AppLogger.error('提交故事失败', e);
      rethrow;
    }
  }

  /// 审核故事（管理员）
  Future<void> approveStory(
    String storyId, {
    bool approved = true,
    String? reason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      // 检查用户是否是管理员
      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理员可以审核故事');
      }

      final status = approved ? 'approved' : 'rejected';

      await _supabase.from('featured_stories').update({
        'status': status,
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': approved ? null : reason,
      }).eq('id', storyId);

      AppLogger.info('审核故事成功: $storyId, 状态: $status');
    } catch (e) {
      AppLogger.error('审核故事失败', e);
      rethrow;
    }
  }

  /// 设置为每日精选（管理员）
  Future<void> setAsFeatured(String storyId, DateTime featuredDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      // 检查用户是否是管理员
      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理员可以设置精选');
      }

      await _supabase.from('featured_stories').update({
        'status': 'featured',
        'featured_date': featuredDate.toIso8601String(),
      }).eq('id', storyId);

      AppLogger.info('设置精选故事成功: $storyId');
    } catch (e) {
      AppLogger.error('设置精选故事失败', e);
      rethrow;
    }
  }

  /// 获取每日精选
  Future<List<FeaturedStory>> getDailyFeatured({int limit = 5}) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('status', 'featured')
          .gte('featured_date', startOfDay.toIso8601String())
          .order('featured_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => FeaturedStory.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取每日精选失败', e);
      return [];
    }
  }

  /// 获取所有已审核通过的故事
  Future<List<FeaturedStory>> getApprovedStories({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .inFilter('status', ['approved', 'featured'])
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => FeaturedStory.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取已审核故事失败', e);
      return [];
    }
  }

  /// 获取待审核的故事（管理员）
  Future<List<FeaturedStory>> getPendingStories({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      // 检查用户是否是管理员
      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理员可以查看待审核故事');
      }

      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => FeaturedStory.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取待审核故事失败', e);
      return [];
    }
  }

  /// 获取故事详情
  Future<FeaturedStory?> getStoryDetail(String storyId) async {
    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('id', storyId)
          .single();

      // 增加阅读数
      await _supabase.rpc('increment_story_read_count', params: {
        'story_id': storyId,
      });

      return FeaturedStory.fromJson(response);
    } catch (e) {
      AppLogger.error('获取故事详情失败', e);
      return null;
    }
  }

  /// 点赞故事
  Future<void> likeStory(String storyId, String userId) async {
    try {
      // 检查是否已点赞
      final existing = await _supabase
          .from('story_likes')
          .select()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用户已点赞该故事');
        return;
      }

      await _supabase.from('story_likes').insert({
        'story_id': storyId,
        'user_id': userId,
      });

      await _supabase.rpc('increment_story_like_count', params: {
        'story_id': storyId,
      });

      AppLogger.info('点赞故事成功: $storyId');
    } catch (e) {
      AppLogger.error('点赞故事失败', e);
      rethrow;
    }
  }

  /// 取消点赞
  Future<void> unlikeStory(String storyId, String userId) async {
    try {
      await _supabase
          .from('story_likes')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', userId);

      await _supabase.rpc('decrement_story_like_count', params: {
        'story_id': storyId,
      });

      AppLogger.info('取消点赞成功: $storyId');
    } catch (e) {
      AppLogger.error('取消点赞失败', e);
      rethrow;
    }
  }

  /// 检查用户是否点赞
  Future<bool> hasLiked(String storyId, String userId) async {
    try {
      final response = await _supabase
          .from('story_likes')
          .select()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查点赞状态失败', e);
      return false;
    }
  }

  /// 获取用户提交的故事
  Future<List<FeaturedStory>> getMyStories(String userId) async {
    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('submitted_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FeaturedStory.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取我的故事失败', e);
      return [];
    }
  }

  /// 生成摘要
  String _generateSummary(String content, {int maxLength = 100}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// 脱敏处理内容
  String desensitizeContent(String content) {
    // 移除或替换敏感信息
    var result = content;

    // 替换电话号码
    result = result.replaceAll(
      RegExp(r'1[3-9]\d{9}'),
      '***',
    );

    // 替换身份证号
    result = result.replaceAll(
      RegExp(r'\d{17}[\dXx]'),
      '***',
    );

    // 替换邮箱
    result = result.replaceAll(
      RegExp(r'[\w.-]+@[\w.-]+\.\w+'),
      '***@***.com',
    );

    // 替换具体地址
    result = result.replaceAll(
      RegExp(r'[\u4e00-\u9fa5]{2,}(省|市|区|县|路|街|号|栋|单元|室)'),
      '***',
    );

    return result;
  }

  /// 获取热门故事
  Future<List<FeaturedStory>> getPopularStories({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .inFilter('status', ['approved', 'featured'])
          .order('like_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => FeaturedStory.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取热门故事失败', e);
      return [];
    }
  }
}
