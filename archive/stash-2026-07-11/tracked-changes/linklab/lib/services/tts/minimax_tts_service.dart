import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';

/// MiniMax TTS 服务
///
/// 调用 MiniMax 语音合成 API，将文本转换为高质量语音并播放。
/// 支持多种音色、语速、音量调节。
class MinimaxTtsService {
  static final MinimaxTtsService _instance = MinimaxTtsService._internal();
  factory MinimaxTtsService() => _instance;
  MinimaxTtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  String? _currentTempFile;

  /// 是否正在朗读
  bool get isSpeaking => _isSpeaking;

  /// 初始化服务
  Future<void> initialize() async {
    AppLogger.info('MiniMax TTS 服务初始化');

    // 监听播放状态
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

  /// 合成语音
  ///
  /// [text] 要合成的文本
  /// [voiceId] 音色 ID，默认为 'female-shaonv'
  ///
  /// 返回 MP3 音频的字节数据
  Future<Uint8List> synthesize(String text, {String? voiceId}) async {
    if (text.isEmpty) {
      throw ArgumentError('文本不能为空');
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
      AppLogger.info('调用 MiniMax TTS API，文本长度: ${text.length}');

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

        // 检查 API 响应状态
        final baseResp = responseData['base_resp'] as Map<String, dynamic>?;
        if (baseResp != null && baseResp['status_code'] != 0) {
          final errorMsg = baseResp['status_msg'] as String? ?? '未知错误';
          throw Exception('MiniMax API 错误: $errorMsg');
        }

        // 获取音频数据
        final data = responseData['data'] as Map<String, dynamic>?;
        final audioBase64 = data?['audio'] as String?;
        if (audioBase64 == null || audioBase64.isEmpty) {
          throw Exception('MiniMax API 返回的音频数据为空');
        }

        // 解码 base64 音频数据
        final audioBytes = base64Decode(audioBase64);
        AppLogger.info('MiniMax TTS 合成成功，音频大小: ${audioBytes.length} bytes');
        return audioBytes;
      } else {
        throw Exception('MiniMax API 请求失败: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('MiniMax API 请求超时');
    } on http.ClientException catch (e) {
      throw Exception('MiniMax API 网络错误: $e');
    }
  }

  /// 直接播放文本
  ///
  /// [text] 要朗读的文本
  /// [voiceId] 音色 ID，默认为 'female-shaonv'
  Future<void> speak(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    try {
      // 停止当前播放
      await stop();

      _isSpeaking = true;

      // 合成语音
      final audioBytes = await synthesize(text, voiceId: voiceId);

      // 根据平台选择播放方式
      if (kIsWeb) {
        await _playOnWeb(audioBytes);
      } else {
        await _playOnMobile(audioBytes);
      }
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('MiniMax TTS 播放失败', e);
      rethrow;
    }
  }

  /// 在移动端/桌面端播放音频
  Future<void> _playOnMobile(Uint8List audioBytes) async {
    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/minimax_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');

      // 写入临时文件
      await tempFile.writeAsBytes(audioBytes);
      _currentTempFile = tempFile.path;

      // 播放音频文件
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      AppLogger.info('MiniMax TTS 开始播放');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('移动端音频播放失败', e);
      rethrow;
    }
  }

  /// 在 Web 平台播放音频
  Future<void> _playOnWeb(Uint8List audioBytes) async {
    try {
      // Web 平台使用 AudioPlayer 的 bytes 播放
      // 注意：audioplayers 5.x 支持 BytesSource
      final source = BytesSource(audioBytes);
      await _audioPlayer.play(source);
      AppLogger.info('MiniMax TTS Web 平台开始播放');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('Web 平台音频播放失败', e);
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
      AppLogger.error('停止播放失败', e);
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      AppLogger.error('暂停播放失败', e);
    }
  }

  /// 恢复播放
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      AppLogger.error('恢复播放失败', e);
    }
  }

  /// 设置音量
  ///
  /// [volume] 音量值，范围 0.0 - 1.0
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.error('设置音量失败', e);
    }
  }

  /// 清理临时文件
  void _cleanupTempFile() {
    if (_currentTempFile != null) {
      try {
        final file = File(_currentTempFile!);
        if (file.existsSync()) {
          file.deleteSync();
          AppLogger.debug('清理临时音频文件: $_currentTempFile');
        }
      } catch (e) {
        AppLogger.warning('清理临时文件失败: $e');
      }
      _currentTempFile = null;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
    _cleanupTempFile();
    AppLogger.info('MiniMax TTS 服务已释放');
  }
}
