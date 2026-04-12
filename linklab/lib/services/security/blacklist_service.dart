import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/report_model.dart';

/// 黑名单服务
class BlacklistService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 添加用户到黑名单
  Future<void> addToBlacklist({
    required String userId,
    required BlacklistLevel level,
    required String reason,
    String? evidence,
    Duration? duration,
  }) async {
    try {
      final expiresAt = duration != null
          ? DateTime.now().add(duration)
          : null;

      final entry = BlacklistEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        level: level,
        reason: reason,
        evidence: evidence,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      // 保存到黑名单
      await _supabase.from('blacklist').insert({
        'id': entry.id,
        'user_id': userId,
        'level': level.name,
        'reason': reason,
        'evidence': evidence,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': entry.createdAt?.toIso8601String(),
      });

      // 如果是用户级封禁，同时封禁设备
      if (level == BlacklistLevel.user) {
        await _banUserDevices(userId);
      }

      // 记录用户状态变更
      await _supabase.from('user_status_changes').insert({
        'user_id': userId,
        'from_status': 'active',
        'to_status': 'banned',
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('用户已加入黑名单: $userId, 级别: ${level.name}');
    } catch (e) {
      AppLogger.error('添加黑名单失败', e);
      rethrow;
    }
  }

  /// 检查用户是否在黑名单中
  Future<bool> isBlacklisted(String userId) async {
    try {
      final response = await _supabase
          .from('blacklist')
          .select()
          .eq('user_id', userId)
          .eq('level', 'user')
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查黑名单失败', e);
      return false;
    }
  }

  /// 添加设备封禁
  Future<void> addDeviceBan(String deviceFingerprint, {String? reason}) async {
    try {
      await _supabase.from('blacklist').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'level': 'device',
        'device_fingerprint': deviceFingerprint,
        'reason': reason ?? '设备违规',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('设备已封禁: $deviceFingerprint');
    } catch (e) {
      AppLogger.error('添加设备封禁失败', e);
      rethrow;
    }
  }

  /// 检查设备是否被封禁
  Future<bool> isDeviceBanned(String deviceFingerprint) async {
    try {
      final response = await _supabase
          .from('blacklist')
          .select()
          .eq('level', 'device')
          .eq('device_fingerprint', deviceFingerprint)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查设备封禁失败', e);
      return false;
    }
  }

  /// 添加IP封禁
  Future<void> addIPBan(String ipAddress, {String? reason, Duration? duration}) async {
    try {
      final expiresAt = duration != null
          ? DateTime.now().add(duration)
          : null;

      await _supabase.from('blacklist').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'level': 'ip',
        'ip_address': ipAddress,
        'reason': reason ?? 'IP违规',
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('IP已封禁: $ipAddress');
    } catch (e) {
      AppLogger.error('添加IP封禁失败', e);
      rethrow;
    }
  }

  /// 检查IP是否被封禁
  Future<bool> isIPBanned(String ipAddress) async {
    try {
      final response = await _supabase
          .from('blacklist')
          .select()
          .eq('level', 'ip')
          .eq('ip_address', ipAddress)
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查IP封禁失败', e);
      return false;
    }
  }

  /// 从黑名单移除
  Future<void> removeFromBlacklist(String entryId) async {
    try {
      await _supabase
          .from('blacklist')
          .delete()
          .eq('id', entryId);

      AppLogger.info('已从黑名单移除: $entryId');
    } catch (e) {
      AppLogger.error('移除黑名单失败', e);
      rethrow;
    }
  }

  /// 解封用户
  Future<void> unbanUser(String userId, {String? reason}) async {
    try {
      // 删除用户级黑名单记录
      await _supabase
          .from('blacklist')
          .delete()
          .eq('user_id', userId)
          .eq('level', 'user');

      // 记录状态变更
      await _supabase.from('user_status_changes').insert({
        'user_id': userId,
        'from_status': 'banned',
        'to_status': 'active',
        'reason': reason ?? '人工解封',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('用户已解封: $userId');
    } catch (e) {
      AppLogger.error('解封用户失败', e);
      rethrow;
    }
  }

  /// 获取设备指纹
  Future<String> getDeviceFingerprint() async {
    try {
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
      }

      // 使用简单的哈希
      return _simpleHash(deviceId);
    } catch (e) {
      AppLogger.error('获取设备指纹失败', e);
      return '';
    }
  }

  /// 封禁用户的所有设备
  Future<void> _banUserDevices(String userId) async {
    try {
      // 获取用户的所有设备指纹
      final devices = await _supabase
          .from('user_devices')
          .select('device_fingerprint')
          .eq('user_id', userId);

      for (final device in devices) {
        final fingerprint = device['device_fingerprint'] as String;
        await addDeviceBan(fingerprint, reason: '关联违规账号');
      }
    } catch (e) {
      AppLogger.error('封禁用户设备失败', e);
    }
  }

  /// 记录设备信息
  Future<void> recordDeviceInfo(String userId) async {
    try {
      final fingerprint = await getDeviceFingerprint();
      if (fingerprint.isEmpty) return;

      String deviceInfo = '';
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo = '${iosInfo.name} ${iosInfo.model}';
      }

      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'device_fingerprint': fingerprint,
        'device_info': deviceInfo,
        'last_used_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('记录设备信息失败', e);
    }
  }

  /// 获取黑名单列表（管理后台）
  Future<List<BlacklistEntry>> getBlacklist({
    BlacklistLevel? level,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('blacklist').select();

      if (level != null) {
        query = query.eq('level', level.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => BlacklistEntry.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取黑名单失败', e);
      return [];
    }
  }

  /// 检查当前环境是否受限
  Future<BlacklistCheckResult> checkCurrentEnvironment() async {
    final deviceFingerprint = await getDeviceFingerprint();

    final isDeviceBannedResult = await isDeviceBanned(deviceFingerprint);
    if (isDeviceBannedResult) {
      return BlacklistCheckResult(
        isRestricted: true,
        reason: '设备已被封禁',
        level: BlacklistLevel.device,
      );
    }

    return BlacklistCheckResult(
      isRestricted: false,
      reason: null,
      level: null,
    );
  }

  /// 简单哈希函数
  String _simpleHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash.toRadixString(16);
  }
}

/// 黑名单检查结果
class BlacklistCheckResult {
  final bool isRestricted;
  final String? reason;
  final BlacklistLevel? level;

  BlacklistCheckResult({
    required this.isRestricted,
    this.reason,
    this.level,
  });
}
