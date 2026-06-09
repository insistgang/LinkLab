import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../../models/security/call_recording_model.dart';

/// 通話錄音服務
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

  // 存儲當前錄音的引用
  final Map<String, CallRecording> _activeRecordings = {};

  /// 開始錄音
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

      // 保存到數據庫
      await _supabase.from('call_recordings').insert({
        'id': recordingId,
        'call_id': callId,
        'seeker_id': seekerId,
        'volunteer_id': volunteerId,
        'started_at': recording.startedAt?.toIso8601String(),
        'expires_at': recording.expiresAt?.toIso8601String(),
      });

      _activeRecordings[callId] = recording;

      AppLogger.info('錄音開始: $recordingId for call: $callId');
      return recording;
    } catch (e) {
      AppLogger.error('開始錄音失敗', e);
      return null;
    }
  }

  /// 停止錄音
  Future<CallRecording?> stopRecording(String callId) async {
    try {
      final recording = _activeRecordings[callId];
      if (recording == null) {
        AppLogger.warning('未找到活動錄音: $callId');
        return null;
      }

      final endedAt = DateTime.now();
      final duration = recording.startedAt != null
          ? endedAt.difference(recording.startedAt!).inSeconds
          : 0;

      // 更新數據庫
      await _supabase.from('call_recordings').update({
        'ended_at': endedAt.toIso8601String(),
        'duration': duration,
      }).eq('id', recording.id);

      _activeRecordings.remove(callId);

      AppLogger.info('錄音結束: ${recording.id}, 時長: ${duration}s');
      return recording.copyWith(
        endedAt: endedAt,
        duration: duration,
      );
    } catch (e) {
      AppLogger.error('停止錄音失敗', e);
      return null;
    }
  }

  /// 上傳錄音文件
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

      // 更新數據庫
      await _supabase.from('call_recordings').update({
        'file_url': fileUrl,
        'file_size': fileSize,
        'is_uploaded': true,
        'uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', recordingId);

      AppLogger.info('錄音上傳成功: $recordingId');
      return true;
    } catch (e) {
      AppLogger.error('上傳錄音失敗', e);
      return false;
    }
  }

  /// 獲取錄音記錄
  Future<CallRecording?> getRecording(String recordingId) async {
    try {
      final response = await _supabase
          .from('call_recordings')
          .select('*, detection_results(*)')
          .eq('id', recordingId)
          .single();

      return CallRecording.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('獲取錄音記錄失敗', e);
      return null;
    }
  }

  /// 獲取通話的錄音記錄
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
      AppLogger.error('獲取通話錄音記錄失敗', e);
      return null;
    }
  }

  /// 刪除錄音（自動清理過期錄音）
  Future<void> deleteRecording(String recordingId) async {
    try {
      // 獲取錄音信息
      final recording = await getRecording(recordingId);
      if (recording == null) return;

      // 刪除存儲文件
      if (recording.fileUrl != null) {
        final fileName = 'recording_$recordingId.wav';
        await _supabase.storage
            .from('call-recordings')
            .remove(['recordings/$fileName']);
      }

      // 更新數據庫
      await _supabase.from('call_recordings').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
        'file_url': null,
      }).eq('id', recordingId);

      AppLogger.info('錄音已刪除: $recordingId');
    } catch (e) {
      AppLogger.error('刪除錄音失敗', e);
    }
  }

  /// 清理過期錄音
  Future<int> cleanupExpiredRecordings() async {
    try {
      // 獲取所有過期且未刪除的錄音
      final response = await _supabase
          .from('call_recordings')
          .select('id')
          .lte('expires_at', DateTime.now().toIso8601String())
          .eq('is_deleted', false);

      final expiredIds = (response as List)
          .map((r) => Map<String, dynamic>.from(r as Map)['id'] as String)
          .toList();

      // 刪除每個過期錄音
      for (final id in expiredIds) {
        await deleteRecording(id);
      }

      AppLogger.info('清理過期錄音: ${expiredIds.length} 條');
      return expiredIds.length;
    } catch (e) {
      AppLogger.error('清理過期錄音失敗', e);
      return 0;
    }
  }

  /// 獲取臨時錄音文件路徑
  Future<String> getTempRecordingPath(String callId) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/recording_$callId.wav';
  }

  /// 檢查錄音是否啓用
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

  /// 設置錄音啓用狀態
  Future<void> setRecordingEnabled(String userId, bool enabled) async {
    try {
      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'recording_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('設置錄音狀態失敗', e);
    }
  }
}
