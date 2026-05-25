import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 地区社群服务
class RegionalCommunityService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 创建地区社群
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
      if (userId == null) throw Exception('用户未登录');

      // 创建社群
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

      // 自动加入社群
      await _supabase.from('community_members').insert({
        'community_id': communityResponse['id'],
        'user_id': userId,
        'role': 'admin',
      });

      AppLogger.info('创建地区社群成功: $city');
    } catch (e) {
      AppLogger.error('创建地区社群失败', e);
      rethrow;
    }
  }

  /// 获取附近的社群
  Future<List<RegionalCommunity>> getNearbyCommunities({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      // 使用 PostGIS 或手动计算距离
      final response = await _supabase
          .from('regional_communities')
          .select()
          .order('created_at', ascending: false);

      final communities = (response as List)
          .map((json) => RegionalCommunity.fromJson(json))
          .toList();

      // 计算距离并排序
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

      // 按距离排序
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
      AppLogger.error('获取附近社群失败', e);
      return [];
    }
  }

  /// 获取所有社群（按城市）
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
      AppLogger.error('获取城市社群失败', e);
      return [];
    }
  }

  /// 获取热门社群
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
      AppLogger.error('获取热门社群失败', e);
      return [];
    }
  }

  /// 加入社群
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      // 检查是否已加入
      final existing = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用户已在社群中');
        return;
      }

      // 加入社群
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': 'member',
      });

      // 更新成员数
      await _supabase.rpc('increment_community_member_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('加入社群成功: $communityId');
    } catch (e) {
      AppLogger.error('加入社群失败', e);
      rethrow;
    }
  }

  /// 离开社群
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // 更新成员数
      await _supabase.rpc('decrement_community_member_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('离开社群成功: $communityId');
    } catch (e) {
      AppLogger.error('离开社群失败', e);
      rethrow;
    }
  }

  /// 获取用户加入的社群
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
      AppLogger.error('获取我的社群失败', e);
      return [];
    }
  }

  /// 创建活动
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
      if (userId == null) throw Exception('用户未登录');

      // 检查用户是否是社群成员
      final membership = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (membership == null) {
        throw Exception('用户不是该社群成员');
      }

      // 创建活动
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

      // 更新活动数
      await _supabase.rpc('increment_community_event_count', params: {
        'community_id': communityId,
      });

      AppLogger.info('创建活动成功: $title');
    } catch (e) {
      AppLogger.error('创建活动失败', e);
      rethrow;
    }
  }

  /// 获取社群活动
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
      AppLogger.error('获取活动失败', e);
      return [];
    }
  }

  /// 参加活动
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      // 检查活动容量
      final event = await _supabase
          .from('community_events')
          .select()
          .eq('id', eventId)
          .single();

      if (event['participant_count'] >= event['max_participants']) {
        throw Exception('活动已满员');
      }

      // 检查是否已参加
      final existing = await _supabase
          .from('event_participants')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用户已参加活动');
        return;
      }

      // 参加活动
      await _supabase.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
      });

      // 更新参与人数
      await _supabase.rpc('increment_event_participant_count', params: {
        'event_id': eventId,
      });

      AppLogger.info('参加活动成功: $eventId');
    } catch (e) {
      AppLogger.error('参加活动失败', e);
      rethrow;
    }
  }

  /// 取消参加活动
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // 更新参与人数
      await _supabase.rpc('decrement_event_participant_count', params: {
        'event_id': eventId,
      });

      AppLogger.info('取消参加活动成功: $eventId');
    } catch (e) {
      AppLogger.error('取消参加活动失败', e);
      rethrow;
    }
  }

  /// 计算两点之间的距离（使用Haversine公式）
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // 地球半径，单位公里

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
