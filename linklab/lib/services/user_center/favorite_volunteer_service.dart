import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/favorite_volunteer_model.dart';
import '../../models/user_model.dart';

/// 常用志愿者服务 (F16)
/// 管理求助者与志愿者之间的收藏关系
class FavoriteVolunteerService {
  final SupabaseClient _supabase;

  FavoriteVolunteerService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 添加常用志愿者
  /// 通常在双方互评高分（>=4星）后调用
  Future<bool> addFavorite(String seekerId, String volunteerId) async {
    try {
      // 检查是否已存在
      final existing = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        // 已存在，增加合作次数
        await _supabase
            .from('favorite_volunteers')
            .update({
              'cooperation_count': (existing['cooperation_count'] ?? 1) + 1,
              'last_cooperation_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);

        AppLogger.info('更新常用志愿者合作次数: $seekerId -> $volunteerId');
        return true;
      }

      // 获取志愿者信息
      final volunteerResponse = await _supabase
          .from('users')
          .select('name, avatar_url')
          .eq('id', volunteerId)
          .single();

      // 创建新记录
      await _supabase.from('favorite_volunteers').insert({
        'seeker_id': seekerId,
        'volunteer_id': volunteerId,
        'volunteer_name': volunteerResponse['name'] ?? '志愿者',
        'volunteer_avatar': volunteerResponse['avatar_url'],
        'cooperation_count': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_cooperation_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('添加常用志愿者成功: $seekerId -> $volunteerId');
      return true;
    } catch (e) {
      AppLogger.error('添加常用志愿者失败', e);
      return false;
    }
  }

  /// 获取常用志愿者列表（别名方法，兼容UI调用）
  Future<List<FavoriteVolunteerModel>> getFavoriteVolunteers(
    String seekerId, {
    int limit = 50,
  }) async {
    return getFavorites(seekerId, limit: limit);
  }

  /// 获取常用志愿者列表
  Future<List<FavoriteVolunteerModel>> getFavorites(
    String seekerId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select('''
            *,
            volunteer:volunteer_id(
              id,
              name,
              avatar_url,
              volunteer_profiles(level, is_online)
            )
          ''')
          .eq('seeker_id', seekerId)
          .order('cooperation_count', ascending: false)
          .order('last_cooperation_at', ascending: false)
          .limit(limit);

      final favorites = (response as List).map((json) {
        // 合并志愿者最新信息
        final volunteer = json['volunteer'];
        if (volunteer != null) {
          json['volunteer_name'] = volunteer['name'] ?? json['volunteer_name'];
          json['volunteer_avatar'] =
              volunteer['avatar_url'] ?? json['volunteer_avatar'];

          final profiles = volunteer['volunteer_profiles'];
          if (profiles != null && profiles is List && profiles.isNotEmpty) {
            json['volunteer_level'] = profiles[0]['level'];
            json['is_online'] = profiles[0]['is_online'];
          }
        }
        return FavoriteVolunteerModel.fromJson(json);
      }).toList();

      return favorites;
    } catch (e) {
      AppLogger.error('获取常用志愿者列表失败', e);
      return [];
    }
  }

  /// 移除常用志愿者
  Future<bool> removeFavorite(String seekerId, String volunteerId) async {
    try {
      await _supabase
          .from('favorite_volunteers')
          .delete()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId);

      AppLogger.info('移除常用志愿者: $seekerId -> $volunteerId');
      return true;
    } catch (e) {
      AppLogger.error('移除常用志愿者失败', e);
      return false;
    }
  }

  /// 检查是否为常用志愿者
  Future<bool> isFavorite(String seekerId, String volunteerId) async {
    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查常用志愿者状态失败', e);
      return false;
    }
  }

  /// 获取常用志愿者统计
  Future<FavoriteVolunteerStats> getStats(String seekerId) async {
    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId);

      final favorites = response as List;

      if (favorites.isEmpty) {
        return const FavoriteVolunteerStats();
      }

      // 计算总合作次数
      final totalCooperations = favorites.fold<int>(
          0, (sum, f) => sum + (f['cooperation_count'] ?? 1));

      // 找出合作最多的志愿者
      final mostFrequent = favorites.reduce((curr, next) =>
          (curr['cooperation_count'] ?? 1) > (next['cooperation_count'] ?? 1)
              ? curr
              : next);

      return FavoriteVolunteerStats(
        totalFavorites: favorites.length,
        totalCooperations: totalCooperations,
        mostFrequentVolunteerId: mostFrequent['volunteer_id'],
        mostFrequentVolunteerName: mostFrequent['volunteer_name'],
      );
    } catch (e) {
      AppLogger.error('获取常用志愿者统计失败', e);
      return const FavoriteVolunteerStats();
    }
  }

  /// 更新合作次数（在帮助完成后调用）
  Future<void> incrementCooperation(
    String seekerId,
    String volunteerId, {
    int? rating,
  }) async {
    try {
      // 检查是否已存在
      final existing = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        // 更新合作次数和评分
        final updates = <String, dynamic>{
          'cooperation_count': (existing['cooperation_count'] ?? 1) + 1,
          'last_cooperation_at': DateTime.now().toIso8601String(),
        };

        if (rating != null) {
          // 更新平均评分
          final currentAvg = existing['average_rating']?.toDouble() ?? 0.0;
          final currentCount = existing['cooperation_count'] ?? 1;
          final newAvg =
              ((currentAvg * currentCount) + rating) / (currentCount + 1);
          updates['average_rating'] = newAvg;
        }

        await _supabase
            .from('favorite_volunteers')
            .update(updates)
            .eq('id', existing['id']);
      } else if (rating != null && rating >= 4) {
        // 首次合作且评分>=4，自动添加为常用志愿者
        await addFavorite(seekerId, volunteerId);
      }
    } catch (e) {
      AppLogger.error('更新合作次数失败', e);
    }
  }

  /// 获取重逢提示信息
  /// 在匹配到常用志愿者时调用
  Future<String?> getReunionMessage(String seekerId, String volunteerId) async {
    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (response == null) return null;

      final count = response['cooperation_count'] ?? 1;

      if (count == 1) {
        return '首次合作，感谢信任！';
      } else if (count < 5) {
        return '你们已经是第$count次合作了！';
      } else if (count < 10) {
        return '默契搭档！这是你们的第$count次合作';
      } else {
        return '资深搭档！你们已经合作$count次了！';
      }
    } catch (e) {
      AppLogger.error('获取重逢信息失败', e);
      return null;
    }
  }

  /// 获取在线的常用志愿者
  Future<List<FavoriteVolunteerModel>> getOnlineFavorites(String seekerId) async {
    try {
      final allFavorites = await getFavorites(seekerId);

      // 过滤在线的志愿者
      final onlineFavorites = <FavoriteVolunteerModel>[];

      for (final favorite in allFavorites) {
        final volunteerResponse = await _supabase
            .from('volunteer_profiles')
            .select('is_online')
            .eq('user_id', favorite.volunteerId)
            .maybeSingle();

        if (volunteerResponse != null && volunteerResponse['is_online'] == true) {
          onlineFavorites.add(favorite);
        }
      }

      return onlineFavorites;
    } catch (e) {
      AppLogger.error('获取在线常用志愿者失败', e);
      return [];
    }
  }
}
