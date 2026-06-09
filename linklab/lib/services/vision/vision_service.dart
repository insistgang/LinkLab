import '../../core/utils/logger.dart';
import 'zhipu_vl_service.dart';

class VisionService {
  final ZhipuVlService _zhipuService;

  VisionService({ZhipuVlService? zhipuService})
      : _zhipuService = zhipuService ?? ZhipuVlService();

  bool get hasRealService => _zhipuService.isConfigured;

  Future<VisionResult> describeScene(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'scene_describe',
      action: (path) => _zhipuService.describeScene(path),
      fallbackText: '這是一個場景圖片。當前AI視覺服務不可用，請轉人工協助描述環境。',
    );
  }

  Future<VisionResult> recognizeColor(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'color_identify',
      action: (path) => _zhipuService.recognizeColor(path),
      fallbackText: '當前AI顏色識別服務不可用，請轉人工協助識別顏色。',
    );
  }

  Future<VisionResult> identifyObject(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'object_identify',
      action: (path) => _zhipuService.identifyObject(path),
      fallbackText: '當前AI物體識別服務不可用，請轉人工協助識別物體。',
    );
  }

  Future<VisionResult> recognizeMoney(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'money_identify',
      action: (path) => _zhipuService.recognizeMoney(path),
      fallbackText: '當前AI鈔票識別服務不可用，請轉人工協助識別面額。',
    );
  }

  Future<VisionResult> checkMedicine(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'medicine_check',
      action: (path) => _zhipuService.checkMedicine(path),
      fallbackText: '當前AI藥品識別服務不可用，請轉人工確認藥品信息。',
    );
  }

  Future<VisionResult> _executeWithFallback({
    required String imagePath,
    required String intent,
    required Future<String> Function(String path) action,
    required String fallbackText,
  }) async {
    if (!_zhipuService.isConfigured) {
      AppLogger.warning('智譜AI未配置，使用Demo fallback: $intent');
      return VisionResult(
        success: false,
        text: fallbackText,
        intent: intent,
        confidence: 0.0,
        isFromRealApi: false,
        error: '智譜AI未配置',
      );
    }

    try {
      final text = await action(imagePath);
      return VisionResult(
        success: true,
        text: text,
        intent: intent,
        confidence: 0.9,
        isFromRealApi: true,
      );
    } on ZhipuVlException catch (e) {
      AppLogger.warning('智譜AI調用失敗，降級到Demo: ${e.message}');
      return VisionResult(
        success: false,
        text: fallbackText,
        intent: intent,
        confidence: 0.0,
        isFromRealApi: false,
        error: e.message,
      );
    } catch (e) {
      AppLogger.error('視覺識別異常', e);
      return VisionResult(
        success: false,
        text: fallbackText,
        intent: intent,
        confidence: 0.0,
        isFromRealApi: false,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _zhipuService.dispose();
  }
}

class VisionResult {
  final bool success;
  final String text;
  final String intent;
  final double confidence;
  final bool isFromRealApi;
  final String? error;

  const VisionResult({
    required this.success,
    required this.text,
    required this.intent,
    required this.confidence,
    required this.isFromRealApi,
    this.error,
  });
}
