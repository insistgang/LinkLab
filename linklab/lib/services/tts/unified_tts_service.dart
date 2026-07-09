import 'dart:async';

import '../../core/utils/logger.dart';
import 'minimax_tts_service.dart';
import '../tts_service.dart';

/// 统一 TTS 服务
///
/// 优先使用 MiniMax TTS（高质量云端语音），失败时 fallback 到 Flutter TTS（本地语音）。
/// 提供统一的语音合成和播放接口。
class UnifiedTtsService {
  static final UnifiedTtsService _instance = UnifiedTtsService._internal();
  factory UnifiedTtsService() => _instance;
  UnifiedTtsService._internal();

  final MinimaxTtsService _minimaxTts = MinimaxTtsService();
  final TTSService _flutterTts = TTSService();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 是否正在朗读
  bool get isSpeaking => _isSpeaking;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _minimaxTts.initialize();
      await _flutterTts.initialize();
      _isInitialized = true;
      AppLogger.info('统一 TTS 服务初始化成功');
    } catch (e) {
      AppLogger.error('统一 TTS 服务初始化失败', e);
    }
  }

  /// 朗读文本
  ///
  /// 优先使用 MiniMax TTS，失败时 fallback 到 Flutter TTS。
  /// [text] 要朗读的文本
  /// [voiceId] MiniMax 音色 ID（仅对 MiniMax TTS 有效）
  Future<void> speak(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    if (!_isInitialized) {
      await initialize();
    }

    _isSpeaking = true;

    // 优先尝试 MiniMax TTS
    try {
      await _minimaxTts.speak(text, voiceId: voiceId);
      AppLogger.info('使用 MiniMax TTS 朗读');
      return;
    } catch (e) {
      AppLogger.warning('MiniMax TTS 失败，降级到 Flutter TTS: $e');
    }

    // Fallback 到 Flutter TTS
    try {
      await _flutterTts.speak(text);
      AppLogger.info('使用 Flutter TTS 朗读（降级）');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('Flutter TTS 朗读也失败', e);
      rethrow;
    }
  }

  /// 停止朗读
  Future<void> stop() async {
    try {
      await _minimaxTts.stop();
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('停止 TTS 失败', e);
    }
  }

  /// 暂停朗读
  Future<void> pause() async {
    try {
      await _minimaxTts.pause();
      await _flutterTts.pause();
    } catch (e) {
      AppLogger.error('暂停 TTS 失败', e);
    }
  }

  /// 恢复朗读
  Future<void> resume() async {
    try {
      await _minimaxTts.resume();
    } catch (e) {
      AppLogger.error('恢复 TTS 失败', e);
    }
  }

  /// 设置音量
  ///
  /// [volume] 音量值，范围 0.0 - 1.0
  Future<void> setVolume(double volume) async {
    try {
      await _minimaxTts.setVolume(volume);
      await _flutterTts.setVolume(volume);
    } catch (e) {
      AppLogger.error('设置 TTS 音量失败', e);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _minimaxTts.dispose();
    _isInitialized = false;
    AppLogger.info('统一 TTS 服务已释放');
  }
}
