import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// AI服務接口
abstract class AIService {
  /// 處理用戶輸入（文本或圖片）
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  });
}

/// AI響應
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

/// OCR服務
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
        response: '請提供需要識別的圖片',
        confidence: 0.0,
      );
    }

    try {
      // TODO: 調用百度OCR API
      // 模擬響應
      await Future.delayed(const Duration(seconds: 1));

      return AIResponse(
        intent: AppConstants.intentOcr,
        response: '識別結果：這是一段示例文字，來自藥品說明書。用法：每日兩次，每次一片。',
        data: {
          'text': '這是一段示例文字，來自藥品說明書。用法：每日兩次，每次一片。',
          'words': ['用法', '每日兩次', '每次一片'],
        },
        confidence: 0.95,
      );
    } catch (e) {
      AppLogger.error('OCR識別失敗', e);
      return AIResponse(
        intent: AppConstants.intentOcr,
        response: '識別失敗，請重試',
        confidence: 0.0,
      );
    }
  }
}

/// 場景描述服務
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
        response: '請提供需要描述的圖片',
        confidence: 0.0,
      );
    }

    try {
      // TODO: 調用通義千問VL API
      // 模擬響應
      await Future.delayed(const Duration(seconds: 2));

      return AIResponse(
        intent: AppConstants.intentSceneDescription,
        response: '這是一張室內照片，畫面中央有一張木質桌子，上面放着一杯咖啡和一本書。背景是窗戶，可以看到外面的綠樹。光線明亮，環境整潔舒適。',
        data: {
          'objects': ['桌子', '咖啡杯', '書', '窗戶'],
          'scene': '室內',
          'lighting': '明亮',
        },
        confidence: 0.92,
      );
    } catch (e) {
      AppLogger.error('場景描述失敗', e);
      return AIResponse(
        intent: AppConstants.intentSceneDescription,
        response: '描述失敗，請重試',
        confidence: 0.0,
      );
    }
  }
}

/// 顏色識別服務
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
        response: '請提供需要識別顏色的圖片',
        confidence: 0.0,
      );
    }

    try {
      // 本地顏色識別
      final dominantColor = await _extractDominantColor(image);
      final colorName = _getColorName(dominantColor);

      return AIResponse(
        intent: AppConstants.intentColorRecognition,
        response: '主要顏色是$colorName',
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
      AppLogger.error('顏色識別失敗', e);
      return AIResponse(
        intent: AppConstants.intentColorRecognition,
        response: '識別失敗，請重試',
        confidence: 0.0,
      );
    }
  }

  Future<img.ColorRgb8> _extractDominantColor(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('無法解碼圖片');
    }

    // 簡化算法：取中心區域平均顏色
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

    // 簡單的顏色命名邏輯
    if (r > 200 && g > 200 && b > 200) return '白色';
    if (r < 50 && g < 50 && b < 50) return '黑色';
    if (r > 200 && g < 100 && b < 100) return '紅色';
    if (r < 100 && g > 200 && b < 100) return '綠色';
    if (r < 100 && g < 100 && b > 200) return '藍色';
    if (r > 200 && g > 200 && b < 100) return '黃色';
    if (r > 200 && g < 100 && b > 200) return '紫色';
    if (r < 100 && g > 200 && b > 200) return '青色';
    if (r > 150 && g > 100 && b < 100) return '橙色';
    if (r > 150 && g > 150 && b > 150) return '灰色';
    if (r > 150 && g > 100 && b > 100) return '粉色';
    if (r > 100 && g > 80 && b < 50) return '棕色';

    return '混合色';
  }
}

/// 智能對話服務
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
        response: '請問有什麼可以幫助您的？',
        confidence: 1.0,
      );
    }

    // 檢測緊急關鍵詞
    final isEmergency = _detectEmergency(text);

    if (isEmergency) {
      return AIResponse(
        intent: AppConstants.intentEmergency,
        response: '檢測到緊急情況，正在爲您觸發SOS求助流程。請保持冷靜，幫助正在路上。',
        isEmergency: true,
        confidence: 1.0,
      );
    }

    // 意圖識別
    final intent = _recognizeIntent(text);

    // 根據意圖生成響應
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
        lowerText.contains('讀') ||
        lowerText.contains('ocr')) {
      return AppConstants.intentOcr;
    }

    if (lowerText.contains('顏色') || lowerText.contains('色')) {
      return AppConstants.intentColorRecognition;
    }

    if (lowerText.contains('場景') ||
        lowerText.contains('環境') ||
        lowerText.contains('在哪')) {
      return AppConstants.intentSceneDescription;
    }

    if (lowerText.contains('導航') ||
        lowerText.contains('路') ||
        lowerText.contains('怎麼走')) {
      return AppConstants.intentNavigation;
    }

    if (lowerText.contains('翻譯') || lowerText.contains('英文')) {
      return AppConstants.intentTranslation;
    }

    return AppConstants.intentGeneral;
  }

  String _generateResponse(String intent, String text) {
    switch (intent) {
      case 'ocr':
        return '我可以幫您識別文字。請拍攝或選擇包含文字的圖片。';
      case 'color_recognition':
        return '我可以幫您識別顏色。請拍攝或選擇需要識別顏色的物體。';
      case 'scene_description':
        return '我可以幫您描述周圍環境。請拍攝一張照片。';
      case 'navigation':
        return '我可以幫您導航。請告訴我您要去哪裏。';
      case 'translation':
        return '我可以幫您翻譯。請告訴我需要翻譯的內容。';
      default:
        return '我理解您的意思了。作爲AI助手，我可以幫您識別文字、描述場景、識別顏色等。請問您需要哪方面的幫助？';
    }
  }
}

/// AI服務管理器
class AIServiceManager {
  static final AIServiceManager _instance = AIServiceManager._internal();
  factory AIServiceManager() => _instance;
  AIServiceManager._internal();

  final OCRService _ocrService = OCRService();
  final SceneDescriptionService _sceneService = SceneDescriptionService();
  final ColorRecognitionService _colorService = ColorRecognitionService();
  final ChatService _chatService = ChatService();

  /// 智能路由，根據輸入選擇合適的服務
  Future<AIResponse> process({
    String? text,
    File? image,
    required String userId,
  }) async {
    // 如果有圖片，根據文本意圖選擇服務
    if (image != null) {
      if (text != null && text.isNotEmpty) {
        final intent = _chatService.process(text: text, userId: userId);
        // 根據意圖選擇圖片處理服務
        // TODO: 實現更智能的路由
      }

      // 默認使用場景描述
      return _sceneService.process(image: image, userId: userId);
    }

    // 純文本使用對話服務
    return _chatService.process(text: text, userId: userId);
  }

  /// OCR識別
  Future<AIResponse> recognizeText(File image, String userId) async {
    return _ocrService.process(image: image, userId: userId);
  }

  /// 場景描述
  Future<AIResponse> describeScene(File image, String userId) async {
    return _sceneService.process(image: image, userId: userId);
  }

  /// 顏色識別
  Future<AIResponse> recognizeColor(File image, String userId) async {
    return _colorService.process(image: image, userId: userId);
  }

  /// 智能對話
  Future<AIResponse> chat(String text, String userId) async {
    return _chatService.process(text: text, userId: userId);
  }
}
