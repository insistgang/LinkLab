import 'package:flutter_tts/flutter_tts.dart';
import '../core/utils/logger.dart';

/// 文字转语音服务
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 是否正在朗读
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
        AppLogger.debug('TTS开始朗读');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('TTS朗读完成');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('TTS错误: $msg');
      });

      _isInitialized = true;
      AppLogger.info('TTS服务初始化成功');
    } catch (e) {
      AppLogger.error('TTS服务初始化失败', e);
    }
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    try {
      await stop();
      await _flutterTts.speak(text);
      AppLogger.info('TTS朗读: $text');
    } catch (e) {
      AppLogger.error('TTS朗读失败', e);
    }
  }

  /// 停止朗读
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      AppLogger.error('TTS停止失败', e);
    }
  }

  /// 暂停朗读
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      AppLogger.error('TTS暂停失败', e);
    }
  }

  /// 设置语速
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      AppLogger.info('TTS语速设置为: $rate');
    } catch (e) {
      AppLogger.error('TTS设置语速失败', e);
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.error('TTS设置音量失败', e);
    }
  }

  /// 设置音调
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      AppLogger.error('TTS设置音调失败', e);
    }
  }

  /// 获取可用语音
  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      AppLogger.error('获取TTS语音列表失败', e);
      return [];
    }
  }

  /// 设置语音
  Future<void> setVoice(String voiceName) async {
    try {
      await _flutterTts.setVoice({'name': voiceName, 'locale': 'zh-CN'});
    } catch (e) {
      AppLogger.error('TTS设置语音失败', e);
    }
  }
}
