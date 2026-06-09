import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 每日精選故事服務
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
    if (_useLocalStories) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  bool get _useLocalStories => !_hasSupabase || !FeatureFlags.enableCommunity;

  /// 提交故事
  Future<void> submitStory({
    required String title,
    required String content,
    String? summary,
    String? coverImage,
    String authorType = 'anonymous',
    String? authorName,
  }) async {
    if (_useLocalStories) {
      final story = FeaturedStory(
        id: 'story-local-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: desensitizeContent(content),
        summary: summary ?? _generateSummary(content),
        coverImage: coverImage,
        authorType: authorType,
        authorName: authorType == 'anonymous' ? null : (authorName ?? '社區用戶'),
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
      if (userId == null) throw Exception('用戶未登錄');

      await _supabase.from('featured_stories').insert({
        'title': title,
        'content': content,
        'summary': summary ?? _generateSummary(content),
        'cover_image': coverImage,
        'author_type': authorType,
        'author_name': authorType == 'anonymous'
            ? null
            : (authorName ?? '匿名用戶'),
        'submitted_by': userId,
        'status': 'pending',
        'like_count': 0,
        'read_count': 0,
      });

      AppLogger.info('提交故事成功: $title');
    } catch (e) {
      AppLogger.error('提交故事失敗', e);
      rethrow;
    }
  }

  /// 審覈故事（管理員）
  Future<void> approveStory(
    String storyId, {
    bool approved = true,
    String? reason,
  }) async {
    if (_useLocalStories) {
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
      if (userId == null) throw Exception('用戶未登錄');

      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理員可以審覈故事');
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

      AppLogger.info('審覈故事成功: $storyId, 狀態: $status');
    } catch (e) {
      AppLogger.error('審覈故事失敗', e);
      rethrow;
    }
  }

  /// 設置爲每日精選（管理員）
  Future<void> setAsFeatured(String storyId, DateTime featuredDate) async {
    if (_useLocalStories) {
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
      if (userId == null) throw Exception('用戶未登錄');

      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理員可以設置精選');
      }

      await _supabase
          .from('featured_stories')
          .update({
            'status': 'featured',
            'featured_date': featuredDate.toIso8601String(),
          })
          .eq('id', storyId);

      AppLogger.info('設置精選故事成功: $storyId');
    } catch (e) {
      AppLogger.error('設置精選故事失敗', e);
      rethrow;
    }
  }

  /// 獲取每日精選
  Future<List<FeaturedStory>> getDailyFeatured({int limit = 5}) async {
    if (_useLocalStories) {
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
      AppLogger.error('獲取每日精選失敗', e);
      return [];
    }
  }

  /// 獲取所有已審覈通過的故事
  Future<List<FeaturedStory>> getApprovedStories({
    int limit = 20,
    int offset = 0,
  }) async {
    if (_useLocalStories) {
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
      AppLogger.error('獲取已審覈故事失敗', e);
      return [];
    }
  }

  /// 獲取待審覈的故事（管理員）
  Future<List<FeaturedStory>> getPendingStories({
    int limit = 20,
    int offset = 0,
  }) async {
    if (_useLocalStories) {
      final stories =
          _demoStories
              .where((story) => story.status == StoryStatus.pending)
              .toList()
            ..sort(_sortByDisplayTimeDesc);
      return _sliceStories(stories, limit: limit, offset: offset);
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final user = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (user['role'] != 'admin') {
        throw Exception('只有管理員可以查看待審覈故事');
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
      AppLogger.error('獲取待審覈故事失敗', e);
      return [];
    }
  }

  /// 獲取故事詳情
  Future<FeaturedStory?> getStoryDetail(String storyId) async {
    if (_useLocalStories) {
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
      AppLogger.error('獲取故事詳情失敗', e);
      return null;
    }
  }

  /// 點贊故事
  Future<void> likeStory(String storyId, String userId) async {
    if (_useLocalStories) {
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
        AppLogger.info('用戶已點贊該故事');
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

      AppLogger.info('點贊故事成功: $storyId');
    } catch (e) {
      AppLogger.error('點贊故事失敗', e);
      rethrow;
    }
  }

  /// 取消點贊
  Future<void> unlikeStory(String storyId, String userId) async {
    if (_useLocalStories) {
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

      AppLogger.info('取消點贊成功: $storyId');
    } catch (e) {
      AppLogger.error('取消點贊失敗', e);
      rethrow;
    }
  }

  /// 檢查用戶是否點贊
  Future<bool> hasLiked(String storyId, String userId) async {
    if (_useLocalStories) {
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
      AppLogger.error('檢查點贊狀態失敗', e);
      return false;
    }
  }

  /// 獲取用戶提交的故事
  Future<List<FeaturedStory>> getMyStories(String userId) async {
    if (_useLocalStories) {
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
      AppLogger.error('獲取我的故事失敗', e);
      return [];
    }
  }

  /// 獲取熱門故事
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
      AppLogger.error('獲取熱門故事失敗', e);
      return [];
    }
  }

  /// 生成摘要
  String _generateSummary(String content, {int maxLength = 100}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// 脫敏處理內容
  String desensitizeContent(String content) {
    var result = content;

    result = result.replaceAll(RegExp(r'1[3-9]\d{9}'), '***');

    result = result.replaceAll(RegExp(r'\d{17}[\dXx]'), '***');

    result = result.replaceAll(RegExp(r'[\w.-]+@[\w.-]+\.\w+'), '***@***.com');

    result = result.replaceAll(
      RegExp(r'[\u4e00-\u9fa5]{2,}(省|市|區|縣|路|街|號|棟|單元|室)'),
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
        title: '從藥盒讀不清，到能獨立確認用量',
        summary: '一位視障用戶用 OCR 和志願者二次確認，把原本最擔心的服藥問題變成了可重複的日常流程。',
        content:
            '我以前最怕晚上喫藥，因爲小字說明書和不同顏色的藥盒很容易弄混。現在我會先用首頁的大按鈕進入識別，再把關鍵劑量轉給志願者做二次確認。平臺沒有替我做決定，但把最危險的那一步變得可驗證了。後來我還把常用藥都錄成了自己的幫助檔案，遇到新藥也沒有以前那麼慌。',
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
        title: '第一次做夜間遠程協助，我學會了慢一點說',
        summary: '志願者覆盤真實協助過程：比起給答案，更重要的是把環境信息拆成對方能立即執行的小步驟。',
        content:
            '那次對方在地鐵口附近迷路，我本來想一次性把全部路線說完，結果她越聽越亂。後來我改成每次只說一個動作，比如向右半步、摸到欄杆後停一下。通話結束後我意識到，好的協助不是快，而是讓對方每一步都能自己確認。這也讓我重新理解了“陪伴式幫助”的價值。',
        authorType: 'named',
        authorName: '志願者小周',
        likeCount: 54,
        readCount: 215,
        status: StoryStatus.approved,
        featuredDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      FeaturedStory(
        id: 'story-demo-3',
        title: '把求助記錄留存下來，家人終於知道我平時怎麼解決問題',
        summary: '幫助檔案不只是歷史列表，也讓家人看見了用戶已經建立起來的獨立解決能力。',
        content:
            '我以前不太願意和家裏人說自己出門時遇到的麻煩，因爲每說一次，他們就更擔心一次。後來我把幾次求助記錄給家人看，他們才發現很多事情其實已經有穩定流程：能先問 AI，必要時再找人。檔案不是爲了證明我有多困難，而是讓身邊人看到我已經有一套可執行的方法。',
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
