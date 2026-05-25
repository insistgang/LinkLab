import 'dart:async';
import 'dart:typed_data';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';
import 'xfyun_asr_service.dart';

/// 统一 ASR 服务
///
/// AGENTS.md §12.5 / §8.1：AI 能力必须挂在 facade 后方，
/// 外部 API 不可用时自动回退到本地能力。
///
/// 识别链路：讯飞 ASR（云端） → speech_to_text（设备本地）
/// 全部失败时抛出异常，由 UI 层展示友好错误提示，不伪造输入。
class UnifiedAsrService {
  static final UnifiedAsrService _instance = UnifiedAsrService._internal();
  factory UnifiedAsrService() => _instance;
  UnifiedAsrService._internal();

  final XfyunAsrService _xfyunAsr = XfyunAsrService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isUsingLocalAsr = false;
  bool _speechInitialized = false;

  /// 当前活跃的识别 Completer，供 onError / stop 共同访问
  Completer<String>? _activeCompleter;

  bool get isListening =>
      _isUsingLocalAsr ? _speech.isListening : _xfyunAsr.isListening;

  // ────────────── 识别已有音频 ──────────────

  Future<String> recognize(Uint8List audioData) async {
    try {
      AppLogger.info('[UnifiedASR] 使用讯飞 ASR 识别音频 (${audioData.length} bytes)');
      final result = await _xfyunAsr.recognize(audioData);
      AppLogger.info('[UnifiedASR] 讯飞 ASR 结果: $result');
      return result;
    } catch (e) {
      AppLogger.warning('[UnifiedASR] 讯飞 ASR 失败: $e');
      rethrow;
    }
  }

  // ────────────── 实时录音识别 ──────────────

  Future<String> startListening() async {
    // 1️⃣ 优先尝试讯飞云端 ASR
    if (APIConfig.isXfyunConfigured) {
      try {
        AppLogger.info('[UnifiedASR] 尝试讯飞云端 ASR');
        final result = await _xfyunAsr.startListening();
        AppLogger.info('[UnifiedASR] 讯飞 ASR 成功');
        _isUsingLocalAsr = false;
        return result;
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 讯飞 ASR 失败，回退到设备本地: $e');
      }
    }

    // 2️⃣ 回退到设备本地 speech_to_text
    try {
      AppLogger.info('[UnifiedASR] 使用设备本地语音识别');
      return await _startLocalListening();
    } catch (e) {
      AppLogger.warning('[UnifiedASR] 本地语音识别也失败: $e');
    }

    // 3️⃣ 全部失败，抛出异常让 UI 层展示错误提示
    throw Exception('语音识别不可用，请检查网络或麦克风权限');
  }

  Future<void> stopListening() async {
    if (_isUsingLocalAsr) {
      try {
        if (_speech.isListening) {
          await _speech.stop();
        }
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 停止本地录音失败: $e');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      _forceCompleteIfNeeded();
      _isUsingLocalAsr = false;
    } else {
      try {
        await _xfyunAsr.stopListening();
      } catch (e) {
        AppLogger.warning('[UnifiedASR] 停止讯飞录音失败: $e');
      }
    }
  }

  /// 当 completer 仍悬空时，用空串兜底 complete
  void _forceCompleteIfNeeded() {
    final c = _activeCompleter;
    if (c != null && !c.isCompleted) {
      AppLogger.warning('[UnifiedASR] force-complete 悬空 completer');
      c.complete('');
    }
  }

  // ────────────── speech_to_text 本地识别 ──────────────

  Future<String> _startLocalListening() async {
    if (!_speechInitialized) {
      final available = await _speech.initialize(
        onError: (error) {
          AppLogger.error('[UnifiedASR] speech_to_text onError', error);
          _forceCompleteIfNeeded();
        },
        onStatus: (status) {
          AppLogger.info('[UnifiedASR] speech_to_text 状态: $status');
          if (status == 'notListening' || status == 'done') {
            _forceCompleteIfNeeded();
          }
        },
      );
      if (!available) {
        throw Exception('设备不支持本地语音识别');
      }
      _speechInitialized = true;
    }

    _isUsingLocalAsr = true;
    final completer = Completer<String>();
    _activeCompleter = completer;
    String lastRecognized = '';

    await _speech.listen(
      onResult: (result) {
        lastRecognized = result.recognizedWords;
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(lastRecognized);
        }
      },
      localeId: 'zh_CN',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!completer.isCompleted) {
            if (lastRecognized.isNotEmpty) {
              completer.complete(lastRecognized);
              return lastRecognized;
            }
            completer.completeError(TimeoutException('本地语音识别超时'));
          }
          throw TimeoutException('本地语音识别超时');
        },
      );
    } finally {
      _activeCompleter = null;
    }
  }

  void dispose() {
    _xfyunAsr.dispose();
    _speech.stop();
    _activeCompleter = null;
  }
}
