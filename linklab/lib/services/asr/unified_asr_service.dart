import 'dart:async';
import 'dart:typed_data';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';
import 'xfyun_asr_service.dart';

/// 統一 ASR 服務
///
/// AGENTS.md §12.5 / §8.1：AI 能力必須掛在 facade 後方，
/// 外部 API 不可用時自動回退到本地能力。
///
/// 識別鏈路：訊飛 ASR（雲端） → speech_to_text（設備本地）
/// 全部失敗時拋出異常，由 UI 層展示友好錯誤提示，不僞造輸入。
class UnifiedAsrService {
  static final UnifiedAsrService _instance = UnifiedAsrService._internal();
  factory UnifiedAsrService() => _instance;
  UnifiedAsrService._internal();

  final XfyunAsrService _xfyunAsr = XfyunAsrService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isUsingLocalAsr = false;
  bool _speechInitialized = false;
  String _lastLocalRecognized = '';
  Timer? _localCompletionTimer;

  /// 當前活躍的識別 Completer，供 onError / stop 共同訪問
  Completer<String>? _activeCompleter;

  bool get isListening =>
      _isUsingLocalAsr ? _speech.isListening : _xfyunAsr.isListening;

  // ────────────── 識別已有音頻 ──────────────

  Future<String> recognize(Uint8List audioData) async {
    try {
      AppLogger.info('[UnifiedASR] 使用訊飛 ASR 識別音頻 (${audioData.length} bytes)');
      final result = await _xfyunAsr.recognize(audioData);
      AppLogger.info('[UnifiedASR] 訊飛 ASR 結果: $result');
      return result;
    } catch (e) {
      AppLogger.warning('[UnifiedASR] 訊飛 ASR 失敗: $e');
      rethrow;
    }
  }

  // ────────────── 實時錄音識別 ──────────────

  Future<String> startListening() async {
    // 1️⃣ 優先嚐試訊飛雲端 ASR
    if (APIConfig.isXfyunConfigured) {
      try {
        AppLogger.info('[UnifiedASR] 嘗試訊飛雲端 ASR');
        final result = await _xfyunAsr.startListening();
        AppLogger.info('[UnifiedASR] 訊飛 ASR 成功');
        _isUsingLocalAsr = false;
        return result;
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 訊飛 ASR 失敗，回退到設備本地: $e');
      }
    }

    // 2️⃣ 回退到設備本地 speech_to_text
    try {
      AppLogger.info('[UnifiedASR] 使用設備本地語音識別');
      return await _startLocalListening();
    } catch (e) {
      AppLogger.warning('[UnifiedASR] 本地語音識別也失敗: $e');
    }

    // 3️⃣ 全部失敗，拋出異常讓 UI 層展示錯誤提示
    throw Exception('語音識別不可用，請檢查網絡或麥克風權限');
  }

  Future<void> stopListening() async {
    if (_isUsingLocalAsr) {
      try {
        if (_speech.isListening) {
          await _speech.stop();
        }
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 停止本地錄音失敗: $e');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      _completeLocalListening();
      _isUsingLocalAsr = false;
    } else {
      try {
        await _xfyunAsr.stopListening();
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 停止訊飛錄音失敗: $e');
      }
    }
  }

  /// 當 completer 仍懸空時，用最近一次非空轉寫兜底 complete。
  void _completeLocalListening({String? text, Object? error}) {
    final c = _activeCompleter;
    if (c != null && !c.isCompleted) {
      _localCompletionTimer?.cancel();
      final recognized = normalizeRecognizedText(text ?? _lastLocalRecognized);
      if (recognized.isNotEmpty) {
        AppLogger.info('[UnifiedASR] 本地語音識別完成: $recognized');
        c.complete(recognized);
      } else if (error != null) {
        c.completeError(error);
      } else {
        AppLogger.warning('[UnifiedASR] 本地語音識別結束但沒有文本結果');
        c.complete('');
      }
    }
  }

  void _scheduleCompleteLocalListening({
    Duration delay = const Duration(milliseconds: 450),
  }) {
    final c = _activeCompleter;
    if (c == null || c.isCompleted) return;

    _localCompletionTimer?.cancel();
    _localCompletionTimer = Timer(delay, _completeLocalListening);
  }

  // ────────────── speech_to_text 本地識別 ──────────────

  Future<String> _startLocalListening() async {
    if (!_speechInitialized) {
      final available = await _speech.initialize(
        onError: (error) {
          AppLogger.error('[UnifiedASR] speech_to_text onError', error);
          if (error.permanent) {
            _completeLocalListening(
              error: Exception(_friendlySpeechError(error.errorMsg)),
            );
          } else {
            _scheduleCompleteLocalListening();
          }
        },
        onStatus: (status) {
          AppLogger.info('[UnifiedASR] speech_to_text 狀態: $status');
          if (isTerminalSpeechStatus(status)) {
            _scheduleCompleteLocalListening();
          }
        },
      );
      if (!available) {
        throw Exception('設備不支持本地語音識別');
      }
      _speechInitialized = true;
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    _isUsingLocalAsr = true;
    final completer = Completer<String>();
    _activeCompleter = completer;
    _lastLocalRecognized = '';
    _localCompletionTimer?.cancel();

    await _speech.listen(
      onResult: (result) {
        final recognized = normalizeRecognizedText(result.recognizedWords);
        if (recognized.isNotEmpty) {
          _lastLocalRecognized = recognized;
        }
        if (result.finalResult) {
          _completeLocalListening(text: recognized);
        }
      },
      localeId: 'zh_CN',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          final recognized = normalizeRecognizedText(_lastLocalRecognized);
          if (recognized.isNotEmpty) {
            return recognized;
          }
          throw TimeoutException('本地語音識別超時');
        },
      );
    } finally {
      _localCompletionTimer?.cancel();
      _localCompletionTimer = null;
      _activeCompleter = null;
    }
  }

  static bool isTerminalSpeechStatus(String status) {
    return status == 'notListening' ||
        status == 'done' ||
        status == 'doneNoResult';
  }

  static String normalizeRecognizedText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _friendlySpeechError(String errorMsg) {
    if (errorMsg.contains('permission') || errorMsg.contains('not-allowed')) {
      return '麥克風權限未開啓，請允許瀏覽器使用麥克風。';
    }
    if (errorMsg.contains('language')) {
      return '當前瀏覽器暫不支持這個語音識別語言。';
    }
    return '語音識別不可用，請檢查麥克風權限或稍後重試。';
  }

  void dispose() {
    _localCompletionTimer?.cancel();
    _xfyunAsr.dispose();
    _speech.stop();
    _activeCompleter = null;
  }
}
