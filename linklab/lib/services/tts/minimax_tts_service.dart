import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';

/// MiniMax TTS 服務
///
/// 調用 MiniMax 語音合成 API，將文本轉換爲高質量語音並播放。
/// 支持多種音色、語速、音量調節。
class MinimaxTtsService {
  static final MinimaxTtsService _instance = MinimaxTtsService._internal();
  factory MinimaxTtsService() => _instance;
  MinimaxTtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  String? _currentTempFile;

  /// 是否正在朗讀
  bool get isSpeaking => _isSpeaking;

  /// 初始化服務
  Future<void> initialize() async {
    AppLogger.info('MiniMax TTS 服務初始化');

    // 監聽播放狀態
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _isSpeaking = false;
        _cleanupTempFile();
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      _cleanupTempFile();
    });
  }

  /// 合成語音
  ///
  /// [text] 要合成的文本
  /// [voiceId] 音色 ID，默認爲 'female-shaonv'
  ///
  /// 返回 MP3 音頻的字節數據
  Future<Uint8List> synthesize(String text, {String? voiceId}) async {
    if (text.isEmpty) {
      throw ArgumentError('文本不能爲空');
    }

    if (!APIConfig.isMinimaxTtsConfigured) {
      throw StateError('MiniMax API Key 未配置');
    }

    final requestBody = {
      'model': APIConfig.minimaxTtsModel,
      'text': text,
      'voice_setting': {
        'voice_id': voiceId ?? 'female-shaonv',
        'speed': 1.0,
        'vol': 1.0,
        'pitch': 0,
      },
      'audio_setting': {
        'sample_rate': 32000,
        'bitrate': 128000,
        'format': 'mp3',
      },
    };

    try {
      AppLogger.info('調用 MiniMax TTS API，文本長度: ${text.length}');

      final response = await http
          .post(
            Uri.parse(APIConfig.minimaxTtsEndpoint),
            headers: {
              'Authorization': 'Bearer ${APIConfig.minimaxApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: APIConfig.requestTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // 檢查 API 響應狀態
        final baseResp = responseData['base_resp'] as Map<String, dynamic>?;
        if (baseResp != null && baseResp['status_code'] != 0) {
          final errorMsg = baseResp['status_msg'] as String? ?? '未知錯誤';
          throw Exception('MiniMax API 錯誤: $errorMsg');
        }

        // 獲取音頻數據
        final data = responseData['data'] as Map<String, dynamic>?;
        final audioBase64 = data?['audio'] as String?;
        if (audioBase64 == null || audioBase64.isEmpty) {
          throw Exception('MiniMax API 返回的音頻數據爲空');
        }

        // 解碼 base64 音頻數據
        final audioBytes = base64Decode(audioBase64);
        AppLogger.info('MiniMax TTS 合成成功，音頻大小: ${audioBytes.length} bytes');
        return audioBytes;
      } else {
        throw Exception('MiniMax API 請求失敗: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('MiniMax API 請求超時');
    } on http.ClientException catch (e) {
      throw Exception('MiniMax API 網絡錯誤: $e');
    }
  }

  /// 直接播放文本
  ///
  /// [text] 要朗讀的文本
  /// [voiceId] 音色 ID，默認爲 'female-shaonv'
  Future<void> speak(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    try {
      // 停止當前播放
      await stop();

      _isSpeaking = true;

      // 合成語音
      final audioBytes = await synthesize(text, voiceId: voiceId);

      // 根據平臺選擇播放方式
      if (kIsWeb) {
        await _playOnWeb(audioBytes);
      } else {
        await _playOnMobile(audioBytes);
      }
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('MiniMax TTS 播放失敗', e);
      rethrow;
    }
  }

  /// 在移動端/桌面端播放音頻
  Future<void> _playOnMobile(Uint8List audioBytes) async {
    try {
      // 獲取臨時目錄
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/minimax_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');

      // 寫入臨時文件
      await tempFile.writeAsBytes(audioBytes);
      _currentTempFile = tempFile.path;

      // 播放音頻文件
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      AppLogger.info('MiniMax TTS 開始播放');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('移動端音頻播放失敗', e);
      rethrow;
    }
  }

  /// 在 Web 平臺播放音頻
  Future<void> _playOnWeb(Uint8List audioBytes) async {
    try {
      // Web 平臺使用 AudioPlayer 的 bytes 播放
      // 注意：audioplayers 5.x 支持 BytesSource
      final source = BytesSource(audioBytes);
      await _audioPlayer.play(source);
      AppLogger.info('MiniMax TTS Web 平臺開始播放');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('Web 平臺音頻播放失敗', e);
      rethrow;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _cleanupTempFile();
    } catch (e) {
      AppLogger.error('停止播放失敗', e);
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      AppLogger.error('暫停播放失敗', e);
    }
  }

  /// 恢復播放
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      AppLogger.error('恢復播放失敗', e);
    }
  }

  /// 設置音量
  ///
  /// [volume] 音量值，範圍 0.0 - 1.0
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.error('設置音量失敗', e);
    }
  }

  /// 清理臨時文件
  void _cleanupTempFile() {
    if (_currentTempFile != null) {
      try {
        final file = File(_currentTempFile!);
        if (file.existsSync()) {
          file.deleteSync();
          AppLogger.debug('清理臨時音頻文件: $_currentTempFile');
        }
      } catch (e) {
        AppLogger.warning('清理臨時文件失敗: $e');
      }
      _currentTempFile = null;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
    _cleanupTempFile();
    AppLogger.info('MiniMax TTS 服務已釋放');
  }
}
