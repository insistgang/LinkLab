import 'dart:typed_data';

import '../../core/utils/logger.dart';
import 'xfyun_asr_service.dart';

class UnifiedAsrService {
  static final UnifiedAsrService _instance = UnifiedAsrService._internal();
  factory UnifiedAsrService() => _instance;
  UnifiedAsrService._internal();

  final XfyunAsrService _xfyunAsr = XfyunAsrService();

  bool get isListening => _xfyunAsr.isListening;

  Future<String> recognize(Uint8List audioData) async {
    try {
      AppLogger.info('使用讯飞 ASR 识别音频数据 (${audioData.length} bytes)');
      final result = await _xfyunAsr.recognize(audioData);
      AppLogger.info('讯飞 ASR 识别结果: $result');
      return result;
    } catch (e) {
      AppLogger.error('讯飞 ASR 识别失败', e);
      rethrow;
    }
  }

  Future<String> startListening() async {
    try {
      AppLogger.info('开始录音并识别');
      return await _xfyunAsr.startListening();
    } catch (e) {
      AppLogger.error('开始录音失败', e);
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      await _xfyunAsr.stopListening();
    } catch (e) {
      AppLogger.error('停止录音失败', e);
    }
  }

  void dispose() {
    _xfyunAsr.dispose();
  }
}
