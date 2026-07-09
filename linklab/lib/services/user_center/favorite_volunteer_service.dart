import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../core/utils/logger.dart';
import '../../models/favorite_volunteer_model.dart';
import '../local_storage.dart' as app_storage;

/// 常用志愿者服务 (F16)
/// 管理求助者与志愿者之间的收藏关系，并兼容本地演示模式。
class FavoriteVolunteerService {
  FavoriteVolunteerService({
    SupabaseClient? supabase,
    app_storage.LocalStorage? storage,
  }) : _supabaseClient = supabase,
       _storage = storage ?? app_storage.LocalStorage();

  SupabaseClient? _supabaseClient;
  final app_storage.LocalStorage _storage;
  bool _localInitialized = false;

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

  Future<void> _ensureLocalStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  /// 添加常用志愿者
  /// 通常在双方互评高分（>=4星）后调用
  Future<bool> addFavorite(
    String seekerId,
    String volunteerId, {
    String? volunteerName,
    String? volunteerAvatar,
    double? initialRating,
  }) async {
    if (!_hasSupabase) {
      try {
        await _ensureLocalStorage();
        final favorites = _storage.getFavoriteVolunteers();
        final index = favorites.indexWhere(
          (item) =>
              item['seekerId'] == seekerId &&
              item['volunteerId'] == volunteerId,
        );

        if (index >= 0) {
          final current = Map<String, dynamic>.from(favorites[index]);
          final currentCount =
              (current['cooperationCount'] as num?)?.toInt() ?? 1;
          if (initialRating != null) {
            current['averageRating'] = _calculateAverageRating(
              currentAverage:
                  (current['averageRating'] as num?)?.toDouble() ?? 0.0,
              currentCount: currentCount,
              nextRating: initialRating,
            );
          }
          current['cooperationCount'] = currentCount + 1;
          current['lastCooperationAt'] = DateTime.now().toIso8601String();
          favorites[index] = current;
        } else {
          favorites.add({
            'id': 'favorite_${DateTime.now().microsecondsSinceEpoch}',
            'seekerId': seekerId,
            'volunteerId': volunteerId,
            'name': volunteerName ?? '志愿者',
            'avatarUrl': _normalizeLocalAvatar(volunteerAvatar),
            'cooperationCount': 1,
            'averageRating': initialRating,
            'createdAt': DateTime.now().toIso8601String(),
            'lastCooperationAt': DateTime.now().toIso8601String(),
          });
        }

        await _saveLocalFavorites(favorites);
        AppLogger.info('本地添加常用志愿者成功: $seekerId -> $volunteerId');
        return true;
      } catch (e) {
        AppLogger.error('本地添加常用志愿者失败', e);
        return false;
      }
    }

    try {
      final existing = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        final existingMap = Map<String, dynamic>.from(existing as Map);
        final favoriteId = existingMap['id'];
        if (favoriteId is! Object) {
          throw StateError('favorite_volunteers record missing id');
        }
        await _supabase
            .from('favorite_volunteers')
            .update({
              'cooperation_count':
                  ((existingMap['cooperation_count'] as num?) ?? 1).toInt() + 1,
              'last_cooperation_at': DateTime.now().toIso8601String(),
            })
            .eq('id', favoriteId);

        AppLogger.info('更新常用志愿者合作次数: $seekerId -> $volunteerId');
        return true;
      }

      final volunteerResponse = await _supabase
          .from('users')
          .select('name, avatar_url')
          .eq('id', volunteerId)
          .single();
      final volunteerMap = Map<String, dynamic>.from(volunteerResponse as Map);
      final remoteVolunteerName = _asTrimmedString(volunteerMap['name']);
      final remoteVolunteerAvatar = _normalizeLocalAvatar(
        _asTrimmedString(volunteerMap['avatar_url']),
      );

      await _supabase.from('favorite_volunteers').insert({
        'seeker_id': seekerId,
        'volunteer_id': volunteerId,
        'volunteer_name': remoteVolunteerName ?? '志愿者',
        'volunteer_avatar': remoteVolunteerAvatar,
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
    if (!_hasSupabase) {
      try {
        await _ensureLocalStorage();
        final items = _storage
            .getFavoriteVolunteers()
            .where((item) => item['seekerId'] == seekerId)
            .map((item) => FavoriteVolunteerModel.fromJson(item))
            .toList();

        items.sort((a, b) {
          final countDiff = b.cooperationCount.compareTo(a.cooperationCount);
          if (countDiff != 0) return countDiff;
          return (b.lastCooperationAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                a.lastCooperationAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              );
        });

        return items.length > limit ? items.sublist(0, limit) : items;
      } catch (e) {
        AppLogger.error('获取本地常用志愿者列表失败', e);
        return [];
      }
    }

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
        final item = Map<String, dynamic>.from(json as Map);
        final volunteer = item['volunteer'];
        if (volunteer != null) {
          final volunteerMap = Map<String, dynamic>.from(volunteer as Map);
          final volunteerName = _asTrimmedString(volunteerMap['name']);
          final volunteerAvatar = _normalizeLocalAvatar(
            _asTrimmedString(volunteerMap['avatar_url']),
          );
          if (volunteerName != null) {
            item['volunteer_name'] = volunteerName;
          }
          if (volunteerAvatar != null) {
            item['volunteer_avatar'] = volunteerAvatar;
          }

          final profiles = volunteerMap['volunteer_profiles'];
          if (profiles != null && profiles is List && profiles.isNotEmpty) {
            final profile = Map<String, dynamic>.from(profiles[0] as Map);
            item['volunteer_level'] = profile['level'];
            item['is_online'] = profile['is_online'];
          }
        }
        return FavoriteVolunteerModel.fromJson(_normalizeFavoriteJson(item));
      }).toList();

      return favorites;
    } catch (e) {
      AppLogger.error('获取常用志愿者列表失败', e);
      return [];
    }
  }

  /// 移除常用志愿者
  Future<bool> removeFavorite(String seekerId, String volunteerId) async {
    if (!_hasSupabase) {
      try {
        await _ensureLocalStorage();
        final favorites = _storage.getFavoriteVolunteers();
        favorites.removeWhere(
          (item) =>
              item['seekerId'] == seekerId &&
              item['volunteerId'] == volunteerId,
        );
        await _saveLocalFavorites(favorites);
        AppLogger.info('移除本地常用志愿者: $seekerId -> $volunteerId');
        return true;
      } catch (e) {
        AppLogger.error('移除本地常用志愿者失败', e);
        return false;
      }
    }

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
    if (!_hasSupabase) {
      await _ensureLocalStorage();
      return _storage.getFavoriteVolunteers().any(
        (item) =>
            item['seekerId'] == seekerId && item['volunteerId'] == volunteerId,
      );
    }

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
    if (!_hasSupabase) {
      try {
        final favorites = await getFavorites(seekerId, limit: 200);
        if (favorites.isEmpty) {
          return const FavoriteVolunteerStats();
        }

        final totalCooperations = favorites.fold<int>(
          0,
          (sum, item) => sum + item.cooperationCount,
        );
        final mostFrequent = favorites.reduce(
          (curr, next) =>
              curr.cooperationCount >= next.cooperationCount ? curr : next,
        );

        return FavoriteVolunteerStats(
          totalFavorites: favorites.length,
          totalCooperations: totalCooperations,
          mostFrequentVolunteerId: mostFrequent.volunteerId,
          mostFrequentVolunteerName: mostFrequent.volunteerName,
        );
      } catch (e) {
        AppLogger.error('获取本地常用志愿者统计失败', e);
        return const FavoriteVolunteerStats();
      }
    }

    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId);

      final favorites = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (favorites.isEmpty) {
        return const FavoriteVolunteerStats();
      }

      final totalCooperations = favorites.fold<int>(
        0,
        (sum, f) => sum + (((f['cooperation_count'] as num?) ?? 1).toInt()),
      );

      final mostFrequent = favorites.reduce((curr, next) {
        final currentCount = ((curr['cooperation_count'] as num?) ?? 1).toInt();
        final nextCount = ((next['cooperation_count'] as num?) ?? 1).toInt();
        return currentCount > nextCount ? curr : next;
      });

      return FavoriteVolunteerStats(
        totalFavorites: favorites.length,
        totalCooperations: totalCooperations,
        mostFrequentVolunteerId: _asTrimmedString(mostFrequent['volunteer_id']),
        mostFrequentVolunteerName: _asTrimmedString(
          mostFrequent['volunteer_name'],
        ),
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
    String? volunteerName,
    String? volunteerAvatar,
  }) async {
    if (!_hasSupabase) {
      try {
        await _ensureLocalStorage();
        final favorites = _storage.getFavoriteVolunteers();
        final index = favorites.indexWhere(
          (item) =>
              item['seekerId'] == seekerId &&
              item['volunteerId'] == volunteerId,
        );

        if (index >= 0) {
          final current = Map<String, dynamic>.from(favorites[index]);
          final currentCount =
              (current['cooperationCount'] as num?)?.toInt() ?? 1;
          if (volunteerName != null && volunteerName.trim().isNotEmpty) {
            current['name'] = volunteerName.trim();
          }
          if (rating != null) {
            current['averageRating'] = _calculateAverageRating(
              currentAverage:
                  (current['averageRating'] as num?)?.toDouble() ?? 0.0,
              currentCount: currentCount,
              nextRating: rating.toDouble(),
            );
          }
          current['cooperationCount'] = currentCount + 1;
          current['lastCooperationAt'] = DateTime.now().toIso8601String();
          favorites[index] = current;
          await _saveLocalFavorites(favorites);
          return;
        }

        if (rating != null && rating >= 4) {
          await addFavorite(
            seekerId,
            volunteerId,
            volunteerName: volunteerName,
            volunteerAvatar: volunteerAvatar,
            initialRating: rating.toDouble(),
          );
        }
      } catch (e) {
        AppLogger.error('更新本地合作次数失败', e);
      }
      return;
    }

    try {
      final existing = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        final existingMap = Map<String, dynamic>.from(existing as Map);
        final favoriteId = existingMap['id'];
        if (favoriteId is! Object) {
          throw StateError('favorite_volunteers record missing id');
        }
        final updates = <String, dynamic>{
          'cooperation_count':
              ((existingMap['cooperation_count'] as num?) ?? 1).toInt() + 1,
          'last_cooperation_at': DateTime.now().toIso8601String(),
        };

        if (rating != null) {
          final currentAvg =
              (existingMap['average_rating'] as num?)?.toDouble() ?? 0.0;
          final currentCount = ((existingMap['cooperation_count'] as num?) ?? 1)
              .toInt();
          final newAvg =
              ((currentAvg * currentCount) + rating) / (currentCount + 1);
          updates['average_rating'] = newAvg;
        }

        await _supabase
            .from('favorite_volunteers')
            .update(updates)
            .eq('id', favoriteId);
      } else if (rating != null && rating >= 4) {
        await addFavorite(seekerId, volunteerId);
      }
    } catch (e) {
      AppLogger.error('更新合作次数失败', e);
    }
  }

  /// 获取重逢提示信息
  /// 在匹配到常用志愿者时调用
  Future<String?> getReunionMessage(String seekerId, String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final favorites = await getFavorites(seekerId, limit: 200);
        FavoriteVolunteerModel? favorite;
        for (final item in favorites) {
          if (item.volunteerId == volunteerId) {
            favorite = item;
            break;
          }
        }

        if (favorite == null) return null;
        final count = favorite.cooperationCount;
        if (count == 1) return '首次合作，感谢信任！';
        if (count < 5) return '你们已经是第$count次合作了！';
        if (count < 10) return '默契搭档！这是你们的第$count次合作';
        return '资深搭档！你们已经合作$count次了！';
      } catch (e) {
        AppLogger.error('获取本地重逢信息失败', e);
        return null;
      }
    }

    try {
      final response = await _supabase
          .from('favorite_volunteers')
          .select()
          .eq('seeker_id', seekerId)
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (response == null) return null;
      final responseMap = Map<String, dynamic>.from(response as Map);

      final count = ((responseMap['cooperation_count'] as num?) ?? 1).toInt();

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
  Future<List<FavoriteVolunteerModel>> getOnlineFavorites(
    String seekerId,
  ) async {
    if (!_hasSupabase) {
      return getFavorites(seekerId);
    }

    try {
      final allFavorites = await getFavorites(seekerId);
      final onlineFavorites = <FavoriteVolunteerModel>[];

      for (final favorite in allFavorites) {
        final volunteerResponse = await _supabase
            .from('volunteer_profiles')
            .select('is_online')
            .eq('user_id', favorite.volunteerId)
            .maybeSingle();

        final volunteerMap = volunteerResponse == null
            ? null
            : Map<String, dynamic>.from(volunteerResponse as Map);
        if (volunteerMap != null && volunteerMap['is_online'] == true) {
          onlineFavorites.add(favorite);
        }
      }

      return onlineFavorites;
    } catch (e) {
      AppLogger.error('获取在线常用志愿者失败', e);
      return [];
    }
  }

  Future<void> _saveLocalFavorites(List<Map<String, dynamic>> favorites) async {
    favorites.sort((a, b) {
      final countDiff = ((b['cooperationCount'] as num?)?.toInt() ?? 0)
          .compareTo((a['cooperationCount'] as num?)?.toInt() ?? 0);
      if (countDiff != 0) return countDiff;
      final aTime =
          DateTime.tryParse('${a['lastCooperationAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse('${b['lastCooperationAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    await _storage.saveFavoriteVolunteers(favorites);
  }

  double _calculateAverageRating({
    required double currentAverage,
    required int currentCount,
    required double nextRating,
  }) {
    return ((currentAverage * currentCount) + nextRating) / (currentCount + 1);
  }

  Map<String, dynamic> _normalizeFavoriteJson(Map<String, dynamic> source) {
    return {
      'id':
          _asTrimmedString(source['id']) ??
          'favorite_${DateTime.now().microsecondsSinceEpoch}',
      'seekerId':
          _asTrimmedString(source['seekerId'] ?? source['seeker_id']) ?? '',
      'volunteerId':
          _asTrimmedString(source['volunteerId'] ?? source['volunteer_id']) ??
          '',
      'name': _asTrimmedString(source['name'] ?? source['volunteer_name']),
      'avatarUrl': _normalizeLocalAvatar(
        _asTrimmedString(source['avatarUrl'] ?? source['volunteer_avatar']),
      ),
      'cooperationCount':
          ((source['cooperationCount'] as num?) ??
                  (source['cooperation_count'] as num?) ??
                  1)
              .toInt(),
      'averageRating':
          ((source['averageRating'] as num?) ??
                  (source['average_rating'] as num?))
              ?.toDouble(),
      'lastCooperationAt': _asTrimmedString(
        source['lastCooperationAt'] ?? source['last_cooperation_at'],
      ),
      'createdAt': _asTrimmedString(
        source['createdAt'] ?? source['created_at'],
      ),
    };
  }

  String? _asTrimmedString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? _normalizeLocalAvatar(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty) {
      return null;
    }
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }
    return null;
  }
}
