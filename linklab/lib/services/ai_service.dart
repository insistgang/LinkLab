import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// AI服务接口
abstract class AIService {
  /// 处理用户输入（文本或图片）
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  });
}

/// AI响应
class AIResponse {
  final String intent;
  final String response;
  final Map<String, dynamic>? data;
  final bool isEmergency;
  final double confidence;

  AIResponse({
    required this.intent,
    required this.response,
    this.data,
    this.isEmergency = false,
    this.confidence = 0.0,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      intent: json['intent'] ?? AppConstants.intentGeneral,
      response: json['response'] ?? '',
      data: json['data'],
      isEmergency: json['is_emergency'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'response': response,
      'data': data,
      'is_emergency': isEmergency,
      'confidence': confidence,
    };
  }
}

/// OCR服务
class OCRService implements AIService {
  @override
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    if (image == null) {
      return AIResponse(
        intent: AppConstants.intentOcr,
        response: '请提供需要识别的图片',
        confidence: 0.0,
      );
    }

    try {
      // TODO: 调用百度OCR API
      // 模拟响应
      await Future.delayed(const Duration(seconds: 1));

      return AIResponse(
        intent: AppConstants.intentOcr,
        response: '识别结果：这是一段示例文字，来自药品说明书。用法：每日两次，每次一片。',
        data: {
          'text': '这是一段示例文字，来自药品说明书。用法：每日两次，每次一片。',
          'words': ['用法', '每日两次', '每次一片'],
        },
        confidence: 0.95,
      );
    } catch (e) {
      AppLogger.error('OCR识别失败', e);
      return AIResponse(
        intent: AppConstants.intentOcr,
        response: '识别失败，请重试',
        confidence: 0.0,
      );
    }
  }
}

/// 场景描述服务
class SceneDescriptionService implements AIService {
  @override
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    if (image == null) {
      return AIResponse(
        intent: AppConstants.intentSceneDescription,
        response: '请提供需要描述的图片',
        confidence: 0.0,
      );
    }

    try {
      // TODO: 调用通义千问VL API
      // 模拟响应
      await Future.delayed(const Duration(seconds: 2));

      return AIResponse(
        intent: AppConstants.intentSceneDescription,
        response: '这是一张室内照片，画面中央有一张木质桌子，上面放着一杯咖啡和一本书。背景是窗户，可以看到外面的绿树。光线明亮，环境整洁舒适。',
        data: {
          'objects': ['桌子', '咖啡杯', '书', '窗户'],
          'scene': '室内',
          'lighting': '明亮',
        },
        confidence: 0.92,
      );
    } catch (e) {
      AppLogger.error('场景描述失败', e);
      return AIResponse(
        intent: AppConstants.intentSceneDescription,
        response: '描述失败，请重试',
        confidence: 0.0,
      );
    }
  }
}

/// 颜色识别服务
class ColorRecognitionService implements AIService {
  @override
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    if (image == null) {
      return AIResponse(
        intent: AppConstants.intentColorRecognition,
        response: '请提供需要识别颜色的图片',
        confidence: 0.0,
      );
    }

    try {
      // 本地颜色识别
      final dominantColor = await _extractDominantColor(image);
      final colorName = _getColorName(dominantColor);

      return AIResponse(
        intent: AppConstants.intentColorRecognition,
        response: '主要颜色是$colorName',
        data: {
          'color': colorName,
          'rgb': {
            'r': dominantColor.r,
            'g': dominantColor.g,
            'b': dominantColor.b,
          },
        },
        confidence: 0.88,
      );
    } catch (e) {
      AppLogger.error('颜色识别失败', e);
      return AIResponse(
        intent: AppConstants.intentColorRecognition,
        response: '识别失败，请重试',
        confidence: 0.0,
      );
    }
  }

  Future<img.ColorRgb8> _extractDominantColor(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('无法解码图片');
    }

    // 简化算法：取中心区域平均颜色
    int r = 0, g = 0, b = 0;
    int count = 0;

    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final radius = 50;

    for (int x = centerX - radius; x < centerX + radius; x++) {
      for (int y = centerY - radius; y < centerY + radius; y++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          r += pixel.r.toInt();
          g += pixel.g.toInt();
          b += pixel.b.toInt();
          count++;
        }
      }
    }

    return img.ColorRgb8(
      (r / count).round(),
      (g / count).round(),
      (b / count).round(),
    );
  }

  String _getColorName(img.ColorRgb8 color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;

    // 简单的颜色命名逻辑
    if (r > 200 && g > 200 && b > 200) return '白色';
    if (r < 50 && g < 50 && b < 50) return '黑色';
    if (r > 200 && g < 100 && b < 100) return '红色';
    if (r < 100 && g > 200 && b < 100) return '绿色';
    if (r < 100 && g < 100 && b > 200) return '蓝色';
    if (r > 200 && g > 200 && b < 100) return '黄色';
    if (r > 200 && g < 100 && b > 200) return '紫色';
    if (r < 100 && g > 200 && b > 200) return '青色';
    if (r > 150 && g > 100 && b < 100) return '橙色';
    if (r > 150 && g > 150 && b > 150) return '灰色';
    if (r > 150 && g > 100 && b > 100) return '粉色';
    if (r > 100 && g > 80 && b < 50) return '棕色';

    return '混合色';
  }
}

/// 智能对话服务
class ChatService implements AIService {
  @override
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    if (text == null || text.isEmpty) {
      return AIResponse(
        intent: AppConstants.intentGeneral,
        response: '请问有什么可以帮助您的？',
        confidence: 1.0,
      );
    }

    // 检测紧急关键词
    final isEmergency = _detectEmergency(text);

    if (isEmergency) {
      return AIResponse(
        intent: AppConstants.intentEmergency,
        response: '检测到紧急情况，正在为您触发SOS求助流程。请保持冷静，帮助正在路上。',
        isEmergency: true,
        confidence: 1.0,
      );
    }

    // 意图识别
    final intent = _recognizeIntent(text);

    // 根据意图生成响应
    final response = _generateResponse(intent, text);

    return AIResponse(
      intent: intent,
      response: response,
      confidence: 0.85,
    );
  }

  bool _detectEmergency(String text) {
    final lowerText = text.toLowerCase();
    for (final keyword in AppConstants.emergencyKeywords) {
      if (lowerText.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  String _recognizeIntent(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('文字') ||
        lowerText.contains('字') ||
        lowerText.contains('读') ||
        lowerText.contains('ocr')) {
      return AppConstants.intentOcr;
    }

    if (lowerText.contains('颜色') || lowerText.contains('色')) {
      return AppConstants.intentColorRecognition;
    }

    if (lowerText.contains('场景') ||
        lowerText.contains('环境') ||
        lowerText.contains('在哪')) {
      return AppConstants.intentSceneDescription;
    }

    if (lowerText.contains('导航') ||
        lowerText.contains('路') ||
        lowerText.contains('怎么走')) {
      return AppConstants.intentNavigation;
    }

    if (lowerText.contains('翻译') || lowerText.contains('英文')) {
      return AppConstants.intentTranslation;
    }

    return AppConstants.intentGeneral;
  }

  String _generateResponse(String intent, String text) {
    switch (intent) {
      case 'ocr':
        return '我可以帮您识别文字。请拍摄或选择包含文字的图片。';
      case 'color_recognition':
        return '我可以帮您识别颜色。请拍摄或选择需要识别颜色的物体。';
      case 'scene_description':
        return '我可以帮您描述周围环境。请拍摄一张照片。';
      case 'navigation':
        return '我可以帮您导航。请告诉我您要去哪里。';
      case 'translation':
        return '我可以帮您翻译。请告诉我需要翻译的内容。';
      default:
        return '我理解您的意思了。作为AI助手，我可以帮您识别文字、描述场景、识别颜色等。请问您需要哪方面的帮助？';
    }
  }
}

/// AI服务管理器
class AIServiceManager {
  static final AIServiceManager _instance = AIServiceManager._internal();
  factory AIServiceManager() => _instance;
  AIServiceManager._internal();

  final OCRService _ocrService = OCRService();
  final SceneDescriptionService _sceneService = SceneDescriptionService();
  final ColorRecognitionService _colorService = ColorRecognitionService();
  final ChatService _chatService = ChatService();

  /// 智能路由，根据输入选择合适的服务
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    // 如果有图片，根据文本意图选择服务
    if (image != null) {
      if (text != null && text.isNotEmpty) {
        final intent = _chatService.process(text: text, userId: userId);
        // 根据意图选择图片处理服务
        // TODO: 实现更智能的路由
      }

      // 默认使用场景描述
      return _sceneService.process(image: image, userId: userId);
    }

    // 纯文本使用对话服务
    return _chatService.process(text: text, userId: userId);
  }

  /// OCR识别
  Future<AIResponse> recognizeText(File image, String userId) async {
    return _ocrService.process(image: image, userId: userId);
  }

  /// 场景描述
  Future<AIResponse> describeScene(File image, String userId) async {
    return _sceneService.process(image: image, userId: userId);
  }

  /// 颜色识别
  Future<AIResponse> recognizeColor(File image, String userId) async {
    return _colorService.process(image: image, userId: userId);
  }

  /// 智能对话
  Future<AIResponse> chat(String text, String userId) async {
    return _chatService.process(text: text, userId: userId);
  }
}
