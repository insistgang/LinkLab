import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/report_model.dart';

/// 黑名單服務
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

  /// 添加用戶到黑名單
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

      // 保存到黑名單
      await _supabase.from('blacklist').insert({
        'id': entry.id,
        'user_id': userId,
        'level': level.name,
        'reason': reason,
        'evidence': evidence,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': entry.createdAt?.toIso8601String(),
      });

      // 如果是用戶級封禁，同時封禁設備
      if (level == BlacklistLevel.user) {
        await _banUserDevices(userId);
      }

      // 記錄用戶狀態變更
      await _supabase.from('user_status_changes').insert({
        'user_id': userId,
        'from_status': 'active',
        'to_status': 'banned',
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('用戶已加入黑名單: $userId, 級別: ${level.name}');
    } catch (e) {
      AppLogger.error('添加黑名單失敗', e);
      rethrow;
    }
  }

  /// 檢查用戶是否在黑名單中
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
      AppLogger.error('檢查黑名單失敗', e);
      return false;
    }
  }

  /// 添加設備封禁
  Future<void> addDeviceBan(String deviceFingerprint, {String? reason}) async {
    try {
      await _supabase.from('blacklist').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'level': 'device',
        'device_fingerprint': deviceFingerprint,
        'reason': reason ?? '設備違規',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('設備已封禁: $deviceFingerprint');
    } catch (e) {
      AppLogger.error('添加設備封禁失敗', e);
      rethrow;
    }
  }

  /// 檢查設備是否被封禁
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
      AppLogger.error('檢查設備封禁失敗', e);
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
        'reason': reason ?? 'IP違規',
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('IP已封禁: $ipAddress');
    } catch (e) {
      AppLogger.error('添加IP封禁失敗', e);
      rethrow;
    }
  }

  /// 檢查IP是否被封禁
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
      AppLogger.error('檢查IP封禁失敗', e);
      return false;
    }
  }

  /// 從黑名單移除
  Future<void> removeFromBlacklist(String entryId) async {
    try {
      await _supabase
          .from('blacklist')
          .delete()
          .eq('id', entryId);

      AppLogger.info('已從黑名單移除: $entryId');
    } catch (e) {
      AppLogger.error('移除黑名單失敗', e);
      rethrow;
    }
  }

  /// 解封用戶
  Future<void> unbanUser(String userId, {String? reason}) async {
    try {
      // 刪除用戶級黑名單記錄
      await _supabase
          .from('blacklist')
          .delete()
          .eq('user_id', userId)
          .eq('level', 'user');

      // 記錄狀態變更
      await _supabase.from('user_status_changes').insert({
        'user_id': userId,
        'from_status': 'banned',
        'to_status': 'active',
        'reason': reason ?? '人工解封',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('用戶已解封: $userId');
    } catch (e) {
      AppLogger.error('解封用戶失敗', e);
      rethrow;
    }
  }

  /// 獲取設備指紋
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

      // 使用簡單的哈希
      return _simpleHash(deviceId);
    } catch (e) {
      AppLogger.error('獲取設備指紋失敗', e);
      return '';
    }
  }

  /// 封禁用戶的所有設備
  Future<void> _banUserDevices(String userId) async {
    try {
      // 獲取用戶的所有設備指紋
      final devices = await _supabase
          .from('user_devices')
          .select('device_fingerprint')
          .eq('user_id', userId);

      for (final device in devices as List<dynamic>) {
        final deviceMap = Map<String, dynamic>.from(device as Map);
        final fingerprint = deviceMap['device_fingerprint'].toString();
        await addDeviceBan(fingerprint, reason: '關聯違規賬號');
      }
    } catch (e) {
      AppLogger.error('封禁用戶設備失敗', e);
    }
  }

  /// 記錄設備信息
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

      await _supabase.from('user_devices').upsert(
        {
          'user_id': userId,
          'device_fingerprint': fingerprint,
          'device_info': deviceInfo,
          'last_used_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      AppLogger.error('記錄設備信息失敗', e);
    }
  }

  /// 獲取黑名單列表（管理後臺）
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

      return (response as List<dynamic>)
          .map((json) => BlacklistEntry.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取黑名單失敗', e);
      return [];
    }
  }

  /// 檢查當前環境是否受限
  Future<BlacklistCheckResult> checkCurrentEnvironment() async {
    final deviceFingerprint = await getDeviceFingerprint();

    final isDeviceBannedResult = await isDeviceBanned(deviceFingerprint);
    if (isDeviceBannedResult) {
      return BlacklistCheckResult(
        isRestricted: true,
        reason: '設備已被封禁',
        level: BlacklistLevel.device,
      );
    }

    return BlacklistCheckResult(
      isRestricted: false,
      reason: null,
      level: null,
    );
  }

  /// 簡單哈希函數
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

/// 黑名單檢查結果
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
