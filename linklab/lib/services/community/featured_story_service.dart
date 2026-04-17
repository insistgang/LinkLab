import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 每日精选故事服务
class FeaturedStoryService {
  FeaturedStoryService({SupabaseClient? supabase}) : _supabaseClient = supabase;

  SupabaseClient? _supabaseClient;

  static final List<FeaturedStory> _demoStories = _buildDemoStories();
  static final Set<String> _likedStoryKeys = <String>{};
  static final Map<String, String> _localStoryOwners = <String, String>{
    'story-demo-1': 'demo-seeker',
    'story-demo-2': 'demo-volunteer-1',
    'story-demo-3': 'demo-seeker',
  };

  bool get _hasSupabase {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
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
    if (!_hasSupabase) {
      final story = FeaturedStory(
        id: 'story-local-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: desensitizeContent(content),
        summary: summary ?? _generateSummary(content),
        coverImage: coverImage,
        authorType: authorType,
        authorName: authorType == 'anonymous' ? null : (authorName ?? '社区用户'),
        status: StoryStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _demoStories.insert(0, story);
      _localStoryOwners[story.id] = 'local-user';
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      await _supabase.from('featured_stories').insert({
        'title': title,
        'content': content,
        'summary': summary ?? _generateSummary(content),
        'cover_image': coverImage,
        'author_type': authorType,
        'author_name': authorType == 'anonymous'
            ? null
            : (authorName ?? '匿名用户'),
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
    if (!_hasSupabase) {
      final index = _findStoryIndex(storyId);
      if (index == -1) throw Exception('故事不存在');

      _demoStories[index] = _demoStories[index].copyWith(
        status: approved ? StoryStatus.approved : StoryStatus.rejected,
        updatedAt: DateTime.now(),
      );
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理员可以审核故事');
      }

      final status = approved ? 'approved' : 'rejected';

      await _supabase
          .from('featured_stories')
          .update({
            'status': status,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'rejection_reason': approved ? null : reason,
          })
          .eq('id', storyId);

      AppLogger.info('审核故事成功: $storyId, 状态: $status');
    } catch (e) {
      AppLogger.error('审核故事失败', e);
      rethrow;
    }
  }

  /// 设置为每日精选（管理员）
  Future<void> setAsFeatured(String storyId, DateTime featuredDate) async {
    if (!_hasSupabase) {
      final index = _findStoryIndex(storyId);
      if (index == -1) throw Exception('故事不存在');

      _demoStories[index] = _demoStories[index].copyWith(
        status: StoryStatus.featured,
        featuredDate: featuredDate,
        updatedAt: DateTime.now(),
      );
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理员可以设置精选');
      }

      await _supabase
          .from('featured_stories')
          .update({
            'status': 'featured',
            'featured_date': featuredDate.toIso8601String(),
          })
          .eq('id', storyId);

      AppLogger.info('设置精选故事成功: $storyId');
    } catch (e) {
      AppLogger.error('设置精选故事失败', e);
      rethrow;
    }
  }

  /// 获取每日精选
  Future<List<FeaturedStory>> getDailyFeatured({int limit = 5}) async {
    if (!_hasSupabase) {
      final stories =
          _demoStories
              .where(
                (story) =>
                    story.status == StoryStatus.featured ||
                    story.status == StoryStatus.approved,
              )
              .toList()
            ..sort(_sortByDisplayTimeDesc);
      return stories.take(limit).toList();
    }

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
          .map(
            (json) =>
                FeaturedStory.fromJson(Map<String, dynamic>.from(json as Map)),
          )
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
    if (!_hasSupabase) {
      final stories =
          _demoStories
              .where(
                (story) =>
                    story.status == StoryStatus.featured ||
                    story.status == StoryStatus.approved,
              )
              .toList()
            ..sort(_sortByDisplayTimeDesc);
      return _sliceStories(stories, limit: limit, offset: offset);
    }

    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .inFilter('status', ['approved', 'featured'])
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map(
            (json) =>
                FeaturedStory.fromJson(Map<String, dynamic>.from(json as Map)),
          )
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
    if (!_hasSupabase) {
      final stories =
          _demoStories
              .where((story) => story.status == StoryStatus.pending)
              .toList()
            ..sort(_sortByDisplayTimeDesc);
      return _sliceStories(stories, limit: limit, offset: offset);
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用户未登录');

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
          .map(
            (json) =>
                FeaturedStory.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取待审核故事失败', e);
      return [];
    }
  }

  /// 获取故事详情
  Future<FeaturedStory?> getStoryDetail(String storyId) async {
    if (!_hasSupabase) {
      final index = _findStoryIndex(storyId);
      if (index == -1) {
        return null;
      }

      final story = _demoStories[index];
      final updated = story.copyWith(
        readCount: story.readCount + 1,
        updatedAt: DateTime.now(),
      );
      _demoStories[index] = updated;
      return updated;
    }

    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('id', storyId)
          .single();

      await _supabase.rpc(
        'increment_story_read_count',
        params: {'story_id': storyId},
      );

      return FeaturedStory.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('获取故事详情失败', e);
      return null;
    }
  }

  /// 点赞故事
  Future<void> likeStory(String storyId, String userId) async {
    if (!_hasSupabase) {
      final key = _buildLikeKey(storyId, userId);
      if (_likedStoryKeys.contains(key)) {
        return;
      }

      final index = _findStoryIndex(storyId);
      if (index == -1) return;

      _likedStoryKeys.add(key);
      final story = _demoStories[index];
      _demoStories[index] = story.copyWith(
        likeCount: story.likeCount + 1,
        updatedAt: DateTime.now(),
      );
      return;
    }

    try {
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

      await _supabase.rpc(
        'increment_story_like_count',
        params: {'story_id': storyId},
      );

      AppLogger.info('点赞故事成功: $storyId');
    } catch (e) {
      AppLogger.error('点赞故事失败', e);
      rethrow;
    }
  }

  /// 取消点赞
  Future<void> unlikeStory(String storyId, String userId) async {
    if (!_hasSupabase) {
      final key = _buildLikeKey(storyId, userId);
      if (!_likedStoryKeys.remove(key)) {
        return;
      }

      final index = _findStoryIndex(storyId);
      if (index == -1) return;

      final story = _demoStories[index];
      _demoStories[index] = story.copyWith(
        likeCount: math.max(0, story.likeCount - 1),
        updatedAt: DateTime.now(),
      );
      return;
    }

    try {
      await _supabase
          .from('story_likes')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', userId);

      await _supabase.rpc(
        'decrement_story_like_count',
        params: {'story_id': storyId},
      );

      AppLogger.info('取消点赞成功: $storyId');
    } catch (e) {
      AppLogger.error('取消点赞失败', e);
      rethrow;
    }
  }

  /// 检查用户是否点赞
  Future<bool> hasLiked(String storyId, String userId) async {
    if (!_hasSupabase) {
      return _likedStoryKeys.contains(_buildLikeKey(storyId, userId));
    }

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
    if (!_hasSupabase) {
      return _demoStories
          .where((story) => _localStoryOwners[story.id] == userId)
          .toList()
        ..sort(_sortByDisplayTimeDesc);
    }

    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .eq('submitted_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                FeaturedStory.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取我的故事失败', e);
      return [];
    }
  }

  /// 获取热门故事
  Future<List<FeaturedStory>> getPopularStories({int limit = 10}) async {
    if (!_hasSupabase) {
      final stories = List<FeaturedStory>.from(_demoStories)
        ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
      return stories.take(limit).toList();
    }

    try {
      final response = await _supabase
          .from('featured_stories')
          .select()
          .inFilter('status', ['approved', 'featured'])
          .order('like_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map(
            (json) =>
                FeaturedStory.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取热门故事失败', e);
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
    var result = content;

    result = result.replaceAll(RegExp(r'1[3-9]\d{9}'), '***');

    result = result.replaceAll(RegExp(r'\d{17}[\dXx]'), '***');

    result = result.replaceAll(RegExp(r'[\w.-]+@[\w.-]+\.\w+'), '***@***.com');

    result = result.replaceAll(
      RegExp(r'[\u4e00-\u9fa5]{2,}(省|市|区|县|路|街|号|栋|单元|室)'),
      '***',
    );

    return result;
  }

  int _findStoryIndex(String storyId) {
    return _demoStories.indexWhere((story) => story.id == storyId);
  }

  String _buildLikeKey(String storyId, String userId) {
    return '$userId::$storyId';
  }

  int _sortByDisplayTimeDesc(FeaturedStory a, FeaturedStory b) {
    final aTime =
        a.featuredDate ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime =
        b.featuredDate ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  List<FeaturedStory> _sliceStories(
    List<FeaturedStory> stories, {
    required int limit,
    required int offset,
  }) {
    if (offset >= stories.length) {
      return [];
    }

    final end = math.min(offset + limit, stories.length);
    return stories.sublist(offset, end);
  }

  static List<FeaturedStory> _buildDemoStories() {
    final now = DateTime.now();

    return [
      FeaturedStory(
        id: 'story-demo-1',
        title: '从药盒读不清，到能独立确认用量',
        summary: '一位视障用户用 OCR 和志愿者二次确认，把原本最担心的服药问题变成了可重复的日常流程。',
        content:
            '我以前最怕晚上吃药，因为小字说明书和不同颜色的药盒很容易弄混。现在我会先用首页的大按钮进入识别，再把关键剂量转给志愿者做二次确认。平台没有替我做决定，但把最危险的那一步变得可验证了。后来我还把常用药都录成了自己的帮助档案，遇到新药也没有以前那么慌。',
        authorType: 'named',
        authorName: '林阿姨',
        likeCount: 86,
        readCount: 342,
        status: StoryStatus.featured,
        featuredDate: now,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      FeaturedStory(
        id: 'story-demo-2',
        title: '第一次做夜间远程协助，我学会了慢一点说',
        summary: '志愿者复盘真实协助过程：比起给答案，更重要的是把环境信息拆成对方能立即执行的小步骤。',
        content:
            '那次对方在地铁口附近迷路，我本来想一次性把全部路线说完，结果她越听越乱。后来我改成每次只说一个动作，比如向右半步、摸到栏杆后停一下。通话结束后我意识到，好的协助不是快，而是让对方每一步都能自己确认。这也让我重新理解了“陪伴式帮助”的价值。',
        authorType: 'named',
        authorName: '志愿者小周',
        likeCount: 54,
        readCount: 215,
        status: StoryStatus.approved,
        featuredDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      FeaturedStory(
        id: 'story-demo-3',
        title: '把求助记录留存下来，家人终于知道我平时怎么解决问题',
        summary: '帮助档案不只是历史列表，也让家人看见了用户已经建立起来的独立解决能力。',
        content:
            '我以前不太愿意和家里人说自己出门时遇到的麻烦，因为每说一次，他们就更担心一次。后来我把几次求助记录给家人看，他们才发现很多事情其实已经有稳定流程：能先问 AI，必要时再找人。档案不是为了证明我有多困难，而是让身边人看到我已经有一套可执行的方法。',
        authorType: 'anonymous',
        likeCount: 39,
        readCount: 164,
        status: StoryStatus.featured,
        featuredDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
