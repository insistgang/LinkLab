import 'package:flutter_tts/flutter_tts.dart';
import '../core/utils/logger.dart';

/// 文字轉語音服務
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 是否正在朗讀
  bool get isSpeaking => _isSpeaking;

  /// 初始化TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        AppLogger.debug('TTS開始朗讀');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('TTS朗讀完成');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('TTS錯誤: $msg');
      });

      _isInitialized = true;
      AppLogger.info('TTS服務初始化成功');
    } catch (e) {
      AppLogger.error('TTS服務初始化失敗', e);
    }
  }

  /// 朗讀文本
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    try {
      await stop();
      await _flutterTts.speak(text);
      AppLogger.info('TTS朗讀: $text');
    } catch (e) {
      AppLogger.error('TTS朗讀失敗', e);
    }
  }

  /// 停止朗讀
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('TTS停止失敗', e);
    }
  }

  /// 暫停朗讀
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      AppLogger.error('TTS暫停失敗', e);
    }
  }

  /// 設置語速
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      AppLogger.info('TTS語速設置爲: $rate');
    } catch (e) {
      AppLogger.error('TTS設置語速失敗', e);
    }
  }

  /// 設置音量
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.error('TTS設置音量失敗', e);
    }
  }

  /// 設置音調
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      AppLogger.error('TTS設置音調失敗', e);
    }
  }

  /// 獲取可用語音
  Future<List<dynamic>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        return List<dynamic>.from(voices);
      }
      return const [];
    } catch (e) {
      AppLogger.error('獲取TTS語音列表失敗', e);
      return [];
    }
  }

  /// 設置語音
  Future<void> setVoice(String voiceName) async {
    try {
      await _flutterTts.setVoice({'name': voiceName, 'locale': 'zh-CN'});
    } catch (e) {
      AppLogger.error('TTS設置語音失敗', e);
    }
  }
}
