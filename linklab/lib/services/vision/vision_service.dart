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
      fallbackText: '这是一个场景图片。当前AI视觉服务不可用，请转人工协助描述环境。',
    );
  }

  Future<VisionResult> recognizeColor(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'color_identify',
      action: (path) => _zhipuService.recognizeColor(path),
      fallbackText: '当前AI颜色识别服务不可用，请转人工协助识别颜色。',
    );
  }

  Future<VisionResult> identifyObject(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'object_identify',
      action: (path) => _zhipuService.identifyObject(path),
      fallbackText: '当前AI物体识别服务不可用，请转人工协助识别物体。',
    );
  }

  Future<VisionResult> recognizeMoney(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'money_identify',
      action: (path) => _zhipuService.recognizeMoney(path),
      fallbackText: '当前AI钞票识别服务不可用，请转人工协助识别面额。',
    );
  }

  Future<VisionResult> checkMedicine(String imagePath) async {
    return _executeWithFallback(
      imagePath: imagePath,
      intent: 'medicine_check',
      action: (path) => _zhipuService.checkMedicine(path),
      fallbackText: '当前AI药品识别服务不可用，请转人工确认药品信息。',
    );
  }

  Future<VisionResult> _executeWithFallback({
    required String imagePath,
    required String intent,
    required Future<String> Function(String path) action,
    required String fallbackText,
  }) async {
    if (!_zhipuService.isConfigured) {
      AppLogger.warning('智谱AI未配置，使用Demo fallback: $intent');
      return VisionResult(
        success: false,
        text: fallbackText,
        intent: intent,
        confidence: 0.0,
        isFromRealApi: false,
        error: '智谱AI未配置',
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
      AppLogger.warning('智谱AI调用失败，降级到Demo: ${e.message}');
      return VisionResult(
        success: false,
        text: fallbackText,
        intent: intent,
        confidence: 0.0,
        isFromRealApi: false,
        error: e.message,
      );
    } catch (e) {
      AppLogger.error('视觉识别异常', e);
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
