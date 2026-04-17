import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../../models/security/call_recording_model.dart';

/// 通话录音服务
class CallRecordingService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  final _uuid = const Uuid();

  // 存储当前录音的引用
  final Map<String, CallRecording> _activeRecordings = {};

  /// 开始录音
  Future<CallRecording?> startRecording({
    required String callId,
    required String seekerId,
    String? volunteerId,
  }) async {
    try {
      final recordingId = _uuid.v4();
      final recording = CallRecording(
        id: recordingId,
        callId: callId,
        seekerId: seekerId,
        volunteerId: volunteerId,
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          const Duration(days: RecordingConfig.defaultRetentionDays),
        ),
      );

      // 保存到数据库
      await _supabase.from('call_recordings').insert({
        'id': recordingId,
        'call_id': callId,
        'seeker_id': seekerId,
        'volunteer_id': volunteerId,
        'started_at': recording.startedAt?.toIso8601String(),
        'expires_at': recording.expiresAt?.toIso8601String(),
      });

      _activeRecordings[callId] = recording;

      AppLogger.info('录音开始: $recordingId for call: $callId');
      return recording;
    } catch (e) {
      AppLogger.error('开始录音失败', e);
      return null;
    }
  }

  /// 停止录音
  Future<CallRecording?> stopRecording(String callId) async {
    try {
      final recording = _activeRecordings[callId];
      if (recording == null) {
        AppLogger.warning('未找到活动录音: $callId');
        return null;
      }

      final endedAt = DateTime.now();
      final duration = recording.startedAt != null
          ? endedAt.difference(recording.startedAt!).inSeconds
          : 0;

      // 更新数据库
      await _supabase.from('call_recordings').update({
        'ended_at': endedAt.toIso8601String(),
        'duration': duration,
      }).eq('id', recording.id);

      _activeRecordings.remove(callId);

      AppLogger.info('录音结束: ${recording.id}, 时长: ${duration}s');
      return recording.copyWith(
        endedAt: endedAt,
        duration: duration,
      );
    } catch (e) {
      AppLogger.error('停止录音失败', e);
      return null;
    }
  }

  /// 上传录音文件
  Future<bool> uploadRecording(String recordingId, File audioFile) async {
    try {
      final fileName = 'recording_$recordingId.wav';
      final filePath = 'recordings/$fileName';

      await _supabase.storage
          .from('call-recordings')
          .upload(filePath, audioFile);

      final fileUrl = _supabase.storage
          .from('call-recordings')
          .getPublicUrl(filePath);

      final fileSize = await audioFile.length();

      // 更新数据库
      await _supabase.from('call_recordings').update({
        'file_url': fileUrl,
        'file_size': fileSize,
        'is_uploaded': true,
        'uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', recordingId);

      AppLogger.info('录音上传成功: $recordingId');
      return true;
    } catch (e) {
      AppLogger.error('上传录音失败', e);
      return false;
    }
  }

  /// 获取录音记录
  Future<CallRecording?> getRecording(String recordingId) async {
    try {
      final response = await _supabase
          .from('call_recordings')
          .select('*, detection_results(*)')
          .eq('id', recordingId)
          .single();

      return CallRecording.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('获取录音记录失败', e);
      return null;
    }
  }

  /// 获取通话的录音记录
  Future<CallRecording?> getRecordingByCallId(String callId) async {
    try {
      final response = await _supabase
          .from('call_recordings')
          .select('*, detection_results(*)')
          .eq('call_id', callId)
          .maybeSingle();

      if (response == null) return null;
      return CallRecording.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('获取通话录音记录失败', e);
      return null;
    }
  }

  /// 删除录音（自动清理过期录音）
  Future<void> deleteRecording(String recordingId) async {
    try {
      // 获取录音信息
      final recording = await getRecording(recordingId);
      if (recording == null) return;

      // 删除存储文件
      if (recording.fileUrl != null) {
        final fileName = 'recording_$recordingId.wav';
        await _supabase.storage
            .from('call-recordings')
            .remove(['recordings/$fileName']);
      }

      // 更新数据库
      await _supabase.from('call_recordings').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
        'file_url': null,
      }).eq('id', recordingId);

      AppLogger.info('录音已删除: $recordingId');
    } catch (e) {
      AppLogger.error('删除录音失败', e);
    }
  }

  /// 清理过期录音
  Future<int> cleanupExpiredRecordings() async {
    try {
      // 获取所有过期且未删除的录音
      final response = await _supabase
          .from('call_recordings')
          .select('id')
          .lte('expires_at', DateTime.now().toIso8601String())
          .eq('is_deleted', false);

      final expiredIds = (response as List)
          .map((r) => Map<String, dynamic>.from(r as Map)['id'] as String)
          .toList();

      // 删除每个过期录音
      for (final id in expiredIds) {
        await deleteRecording(id);
      }

      AppLogger.info('清理过期录音: ${expiredIds.length} 条');
      return expiredIds.length;
    } catch (e) {
      AppLogger.error('清理过期录音失败', e);
      return 0;
    }
  }

  /// 获取临时录音文件路径
  Future<String> getTempRecordingPath(String callId) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/recording_$callId.wav';
  }

  /// 检查录音是否启用
  Future<bool> isRecordingEnabled(String userId) async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select('recording_enabled')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return RecordingConfig.defaultEnabled;
      final preference = Map<String, dynamic>.from(response as Map);
      final enabled = preference['recording_enabled'];
      if (enabled is bool) {
        return enabled;
      }
      return RecordingConfig.defaultEnabled;
    } catch (e) {
      return RecordingConfig.defaultEnabled;
    }
  }

  /// 设置录音启用状态
  Future<void> setRecordingEnabled(String userId, bool enabled) async {
    try {
      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'recording_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('设置录音状态失败', e);
    }
  }
}
