import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 地區社羣服務
class RegionalCommunityService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 創建地區社羣
  Future<void> createCommunity(
    String city,
    String description, {
    String? province,
    double? latitude,
    double? longitude,
    String? coverImage,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 創建社羣
      final communityResponse = await _supabase
          .from('regional_communities')
          .insert({
            'city': city,
            'province': province ?? city,
            'description': description,
            'latitude': latitude,
            'longitude': longitude,
            'cover_image': coverImage,
            'member_count': 1,
            'event_count': 0,
            'created_by': userId,
          })
          .select()
          .single();

      // 自動加入社羣
      await _supabase.from('community_members').insert({
        'community_id': communityResponse['id'],
        'user_id': userId,
        'role': 'admin',
      });

      AppLogger.info('創建地區社羣成功: $city');
    } catch (e) {
      AppLogger.error('創建地區社羣失敗', e);
      rethrow;
    }
  }

  /// 獲取附近的社羣
  Future<List<RegionalCommunity>> getNearbyCommunities({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      // 使用 PostGIS 或手動計算距離
      final response = await _supabase
          .from('regional_communities')
          .select()
          .order('created_at', ascending: false);

      final communities = (response as List)
          .map((json) => RegionalCommunity.fromJson(json))
          .toList();

      // 計算距離並排序
      final sortedCommunities = communities.where((community) {
        if (community.latitude == null || community.longitude == null) {
          return false;
        }
        final distance = _calculateDistance(
          latitude,
          longitude,
          community.latitude!,
          community.longitude!,
        );
        return distance <= radiusKm;
      }).toList();

      // 按距離排序
      sortedCommunities.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });

      return sortedCommunities.take(limit).toList();
    } catch (e) {
      AppLogger.error('獲取附近社羣失敗', e);
      return [];
    }
  }

  /// 獲取所有社羣（按城市）
  Future<List<RegionalCommunity>> getCommunitiesByCity(String city) async {
    try {
      final response = await _supabase
          .from('regional_communities')
          .select()
          .ilike('city', '%$city%')
          .order('member_count', ascending: false);

      return (response as List)
          .map((json) => RegionalCommunity.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('獲取城市社羣失敗', e);
      return [];
    }
  }

  /// 獲取熱門社羣
  Future<List<RegionalCommunity>> getPopularCommunities({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('regional_communities')
          .select()
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RegionalCommunity.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('獲取熱門社羣失敗', e);
      return [];
    }
  }

  /// 加入社羣
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      // 檢查是否已加入
      final existing = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用戶已在社羣中');
        return;
      }

      // 加入社羣
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': 'member',
      });

      // 更新成員數
      await _supabase.rpc('increment_community_member_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('加入社羣成功: $communityId');
    } catch (e) {
      AppLogger.error('加入社羣失敗', e);
      rethrow;
    }
  }

  /// 離開社羣
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // 更新成員數
      await _supabase.rpc('decrement_community_member_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('離開社羣成功: $communityId');
    } catch (e) {
      AppLogger.error('離開社羣失敗', e);
      rethrow;
    }
  }

  /// 獲取用戶加入的社羣
  Future<List<RegionalCommunity>> getMyCommunities(String userId) async {
    try {
      final response = await _supabase
          .from('community_members')
          .select('community_id, regional_communities(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((json) => RegionalCommunity.fromJson(json['regional_communities']))
          .toList();
    } catch (e) {
      AppLogger.error('獲取我的社羣失敗', e);
      return [];
    }
  }

  /// 創建活動
  Future<void> createEvent(
    String communityId,
    String title, {
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    int maxParticipants = 50,
    String? coverImage,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 檢查用戶是否是社羣成員
      final membership = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (membership == null) {
        throw Exception('用戶不是該社羣成員');
      }

      // 創建活動
      await _supabase.from('community_events').insert({
        'community_id': communityId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'max_participants': maxParticipants,
        'cover_image': coverImage,
        'created_by': userId,
        'status': 'upcoming',
      });

      // 更新活動數
      await _supabase.rpc('increment_community_event_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('創建活動成功: $title');
    } catch (e) {
      AppLogger.error('創建活動失敗', e);
      rethrow;
    }
  }

  /// 獲取社羣活動
  Future<List<CommunityEvent>> getEvents(
    String communityId, {
    String? status,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('community_events')
          .select()
          .eq('community_id', communityId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('start_time', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => CommunityEvent.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('獲取活動失敗', e);
      return [];
    }
  }

  /// 參加活動
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      // 檢查活動容量
      final event = await _supabase
          .from('community_events')
          .select()
          .eq('id', eventId)
          .single();

      if (event['participant_count'] >= event['max_participants']) {
        throw Exception('活動已滿員');
      }

      // 檢查是否已參加
      final existing = await _supabase
          .from('event_participants')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用戶已參加活動');
        return;
      }

      // 參加活動
      await _supabase.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
      });

      // 更新參與人數
      await _supabase.rpc('increment_event_participant_count', params: {
        'event_id': eventId,
      });

      AppLogger.info('參加活動成功: $eventId');
    } catch (e) {
      AppLogger.error('參加活動失敗', e);
      rethrow;
    }
  }

  /// 取消參加活動
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // 更新參與人數
      await _supabase.rpc('decrement_event_participant_count', params: {
        'event_id': eventId,
      });

      AppLogger.info('取消參加活動成功: $eventId');
    } catch (e) {
      AppLogger.error('取消參加活動失敗', e);
      rethrow;
    }
  }

  /// 計算兩點之間的距離（使用Haversine公式）
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // 地球半徑，單位公里

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
