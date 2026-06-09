import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'ai_service.dart';

/// 語音服務
/// 負責TTS語音輸出和ASR語音輸入
class VoiceService {
  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;

  // ASR
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _asrInitialized = false;
  bool _isListening = false;

  // 回調
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
    await _flutterTts.setSpeechRate(0.5); // 語速適中
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

  /// 語音播報
  Future<void> speak(String text) async {
    if (!_ttsInitialized) await _initTTS();

    // 停止當前播報
    await stopSpeaking();

    await _flutterTts.speak(text);
  }

  /// 停止播報
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// 暫停播報
  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
  }

  /// 設置語速
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  /// 設置音量
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// 設置語言
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  /// 獲取支持的語言
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }

  // ==================== ASR 方法 ====================

  /// 設置ASR回調
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

  /// 開始語音識別
  Future<bool> startListening({
    String localeId = 'zh_CN',
    Duration listenDuration = const Duration(seconds: 30),
    bool partialResults = true,
  }) async {
    if (!_asrInitialized) {
      await _initASR();
    }

    if (!_asrInitialized) {
      _onSpeechError?.call('語音識別初始化失敗');
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

  /// 停止語音識別
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _speechToText.stop();
  }

  /// 是否正在監聽
  bool get isListening => _isListening;

  /// ASR是否可用
  bool get isASRAvailable => _asrInitialized;

  // ==================== 語音喚醒（模擬）====================

  /// 喚醒詞檢測器
  VoiceWakeDetector? _wakeDetector;

  /// 啓動語音喚醒
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

  /// 停止語音喚醒
  void stopWakeWordDetection() {
    _wakeDetector?.stop();
    _wakeDetector = null;
  }
}

/// 語音喚醒檢測器（簡化實現）
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
    // 實際項目中需要集成專門的喚醒詞SDK
    // 如：科大訊飛語音喚醒、百度語音喚醒等
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

/// TTS服務（包裝爲AIService接口）
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
      text: '語音播報完成',
      intent: IntentType.generalChat,
      confidence: 1.0,
    );
  }

  VoiceService get voiceService => _voiceService;
}
