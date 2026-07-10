import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'ai_service.dart';

/// 语音服务
/// 负责TTS语音输出和ASR语音输入
class VoiceService {
  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;

  // ASR
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _asrInitialized = false;
  bool _isListening = false;

  // 回调
  Function(String)? _onSpeechResult;
  Function()? _onSpeechStart;
  Function()? _onSpeechEnd;
  Function(String)? _onSpeechError;

  /// 初始化
  Future<void> initialize() async {
    await _initTTS();
    await _initASR();
  }

  /// 初始化TTS
  Future<void> _initTTS() async {
    if (_ttsInitialized) return;

    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5); // 语速适中
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      // TTS完成
    });

    _ttsInitialized = true;
  }

  /// 初始化ASR
  Future<void> _initASR() async {
    if (_asrInitialized) return;

    _asrInitialized = await _speechToText.initialize(
      onError: (error) {
        _onSpeechError?.call(error.errorMsg);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          _onSpeechEnd?.call();
        }
      },
    );
  }

  // ==================== TTS 方法 ====================

  /// 语音播报
  Future<void> speak(String text) async {
    if (!_ttsInitialized) await _initTTS();

    // 停止当前播报
    await stopSpeaking();

    await _flutterTts.speak(text);
  }

  /// 停止播报
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// 暂停播报
  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
  }

  /// 设置语速
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  /// 获取支持的语言
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }

  // ==================== ASR 方法 ====================

  /// 设置ASR回调
  void setASRCallbacks({
    Function(String)? onResult,
    Function()? onStart,
    Function()? onEnd,
    Function(String)? onError,
  }) {
    _onSpeechResult = onResult;
    _onSpeechStart = onStart;
    _onSpeechEnd = onEnd;
    _onSpeechError = onError;
  }

  /// 开始语音识别
  Future<bool> startListening({
    String localeId = 'zh_CN',
    Duration listenDuration = const Duration(seconds: 30),
    bool partialResults = true,
  }) async {
    if (!_asrInitialized) {
      await _initASR();
    }

    if (!_asrInitialized) {
      _onSpeechError?.call('语音识别初始化失败');
      return false;
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;
    _onSpeechStart?.call();

    return await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult || partialResults) {
          _onSpeechResult?.call(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenFor: listenDuration,
      pauseFor: const Duration(seconds: 3),
      partialResults: partialResults,
    );
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _speechToText.stop();
  }

  /// 是否正在监听
  bool get isListening => _isListening;

  /// ASR是否可用
  bool get isASRAvailable => _asrInitialized;

  // ==================== 语音唤醒（模拟）====================

  /// 唤醒词检测器
  VoiceWakeDetector? _wakeDetector;

  /// 启动语音唤醒
  void startWakeWordDetection({
    required List<String> wakeWords,
    required VoidCallback onWake,
  }) {
    _wakeDetector = VoiceWakeDetector(
      wakeWords: wakeWords,
      onWake: onWake,
    );
    _wakeDetector?.start();
  }

  /// 停止语音唤醒
  void stopWakeWordDetection() {
    _wakeDetector?.stop();
    _wakeDetector = null;
  }
}

/// 语音唤醒检测器（简化实现）
class VoiceWakeDetector {
  final List<String> wakeWords;
  final VoidCallback onWake;
  bool _isRunning = false;

  VoiceWakeDetector({
    required this.wakeWords,
    required this.onWake,
  });

  void start() {
    _isRunning = true;
    // 实际项目中需要集成专门的唤醒词SDK
    // 如：科大讯飞语音唤醒、百度语音唤醒等
  }

  void stop() {
    _isRunning = false;
  }

  void processAudio(String text) {
    if (!_isRunning) return;

    final lowerText = text.toLowerCase();
    for (final word in wakeWords) {
      if (lowerText.contains(word.toLowerCase())) {
        onWake();
        break;
      }
    }
  }
}

typedef VoidCallback = void Function();

/// TTS服务（包装为AIService接口）
class TTSService implements AIService {
  final VoiceService _voiceService = VoiceService();

  @override
  String get serviceName => 'TTSService';

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    await _voiceService.speak(input);

    return AIResponse(
      text: '语音播报完成',
      intent: IntentType.generalChat,
      confidence: 1.0,
    );
  }

  VoiceService get voiceService => _voiceService;
}
