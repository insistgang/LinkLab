import 'dart:async';

import '../../core/utils/logger.dart';
import 'minimax_tts_service.dart';
import '../tts_service.dart';

/// 統一 TTS 服務
///
/// 優先使用 MiniMax TTS（高質量雲端語音），失敗時 fallback 到 Flutter TTS（本地語音）。
/// 提供統一的語音合成和播放接口。
class UnifiedTtsService {
  static final UnifiedTtsService _instance = UnifiedTtsService._internal();
  factory UnifiedTtsService() => _instance;
  UnifiedTtsService._internal();

  final MinimaxTtsService _minimaxTts = MinimaxTtsService();
  final TTSService _flutterTts = TTSService();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 是否正在朗讀
  bool get isSpeaking => _isSpeaking;

  /// 初始化服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _minimaxTts.initialize();
      await _flutterTts.initialize();
      _isInitialized = true;
      AppLogger.info('統一 TTS 服務初始化成功');
    } catch (e) {
      AppLogger.error('統一 TTS 服務初始化失敗', e);
    }
  }

  /// 朗讀文本
  ///
  /// 優先使用 MiniMax TTS，失敗時 fallback 到 Flutter TTS。
  /// [text] 要朗讀的文本
  /// [voiceId] MiniMax 音色 ID（僅對 MiniMax TTS 有效）
  Future<void> speak(String text, {String? voiceId}) async {
    if (text.isEmpty) return;

    if (!_isInitialized) {
      await initialize();
    }

    _isSpeaking = true;

    // 優先嚐試 MiniMax TTS
    try {
      await _minimaxTts.speak(text, voiceId: voiceId);
      AppLogger.info('使用 MiniMax TTS 朗讀');
      return;
    } catch (e) {
      AppLogger.warning('MiniMax TTS 失敗，降級到 Flutter TTS: $e');
    }

    // Fallback 到 Flutter TTS
    try {
      await _flutterTts.speak(text);
      AppLogger.info('使用 Flutter TTS 朗讀（降級）');
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('Flutter TTS 朗讀也失敗', e);
      rethrow;
    }
  }

  /// 停止朗讀
  Future<void> stop() async {
    try {
      await _minimaxTts.stop();
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('停止 TTS 失敗', e);
    }
  }

  /// 暫停朗讀
  Future<void> pause() async {
    try {
      await _minimaxTts.pause();
      await _flutterTts.pause();
    } catch (e) {
      AppLogger.error('暫停 TTS 失敗', e);
    }
  }

  /// 恢復朗讀
  Future<void> resume() async {
    try {
      await _minimaxTts.resume();
    } catch (e) {
      AppLogger.error('恢復 TTS 失敗', e);
    }
  }

  /// 設置音量
  ///
  /// [volume] 音量值，範圍 0.0 - 1.0
  Future<void> setVolume(double volume) async {
    try {
      await _minimaxTts.setVolume(volume);
      await _flutterTts.setVolume(volume);
    } catch (e) {
      AppLogger.error('設置 TTS 音量失敗', e);
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    await _minimaxTts.dispose();
    _isInitialized = false;
    AppLogger.info('統一 TTS 服務已釋放');
  }
}
