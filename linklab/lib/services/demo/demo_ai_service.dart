import 'dart:math';
import 'demo_data_loader.dart';

/// AI服务类型
enum AIServiceType {
  ocr,              // 文字识别
  sceneDescription, // 场景描述
  colorRecognition, // 颜色识别
  chat,             // 对话
  intentDetection,  // 意图识别
  emergency,        // 紧急检测
}

/// AI服务结果
class AIResult {
  final bool success;
  final String text;
  final Map<String, dynamic>? data;
  final String? error;

  AIResult({
    required this.success,
    required this.text,
    this.data,
    this.error,
  });

  factory AIResult.success(String text, {Map<String, dynamic>? data}) {
    return AIResult(success: true, text: text, data: data);
  }

  factory AIResult.error(String errorMessage) {
    return AIResult(success: false, text: '', error: errorMessage);
  }
}

/// 演示版AI服务
/// 用于替代真实的AI API调用
class DemoAIService {
  static final DemoAIService _instance = DemoAIService._internal();
  factory DemoAIService() => _instance;
  DemoAIService._internal();

  final _random = Random();

  /// 模拟处理延迟
  Future<void> _simulateDelay({int minMs = 500, int maxMs = 2000}) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// OCR文字识别
  Future<AIResult> recognizeText(String imagePath) async {
    await _simulateDelay();

    final scenarios = DemoDataLoader.getOCRScenarios();
    if (scenarios.isEmpty) {
      return AIResult.error('演示数据未加载');
    }

    // 随机选择一个场景
    final scenario = scenarios[_random.nextInt(scenarios.length)];

    return AIResult.success(
      scenario['summary'] ?? '识别失败',
      data: {
        'recognizedText': scenario['recognizedText'],
        'scenario': scenario['scenario'],
        'confidence': 0.95,
      },
    );
  }

  /// 场景描述
  Future<AIResult> describeScene(String imagePath) async {
    await _simulateDelay(minMs: 800, maxMs: 2500);

    final descriptions = DemoDataLoader.getSceneDescriptions();
    if (descriptions.isEmpty) {
      return AIResult.error('演示数据未加载');
    }

    final description = descriptions[_random.nextInt(descriptions.length)];

    return AIResult.success(
      description['description'] ?? '描述失败',
      data: {
        'scenario': description['scenario'],
        'confidence': 0.92,
      },
    );
  }

  /// 颜色识别
  Future<AIResult> recognizeColor(String imagePath) async {
    await _simulateDelay(minMs: 300, maxMs: 1000);

    final colors = DemoDataLoader.getColorRecognitions();
    if (colors.isEmpty) {
      return AIResult.error('演示数据未加载');
    }

    final color = colors[_random.nextInt(colors.length)];

    return AIResult.success(
      color['description'] ?? '识别失败',
      data: {
        'dominantColor': color['dominantColor'],
        'colorHex': color['colorHex'],
      },
    );
  }

  /// 对话回复
  Future<AIResult> chat(String userMessage, {List<Map<String, String>>? history}) async {
    await _simulateDelay(minMs: 300, maxMs: 1500);

    // 检测意图
    final intent = DemoDataLoader.detectIntent(userMessage);

    // 获取对应回复
    final response = DemoDataLoader.getChatResponseByIntent(intent);

    return AIResult.success(
      response,
      data: {
        'intent': intent,
        'confidence': 0.88,
      },
    );
  }

  /// 意图识别
  Future<AIResult> detectIntent(String input) async {
    await _simulateDelay(minMs: 200, maxMs: 500);

    final intent = DemoDataLoader.detectIntent(input);

    return AIResult.success(
      '意图识别完成',
      data: {
        'intent': intent,
        'confidence': 0.90,
      },
    );
  }

  /// 紧急检测
  Future<AIResult> detectEmergency(String input) async {
    await _simulateDelay(minMs: 100, maxMs: 300);

    final isEmergency = DemoDataLoader.detectEmergency(input);

    if (isEmergency) {
      return AIResult.success(
        '检测到紧急情况！正在为您联系志愿者和紧急联系人。',
        data: {
          'isEmergency': true,
          'urgencyLevel': 'high',
          'action': 'sos_triggered',
        },
      );
    }

    return AIResult.success(
      '未检测到紧急情况',
      data: {
        'isEmergency': false,
        'urgencyLevel': 'normal',
      },
    );
  }

  /// 综合AI处理（根据输入自动选择服务）
  Future<AIResult> process(String input, {String? imagePath}) async {
    // 如果有图片路径，优先进行图像识别
    if (imagePath != null) {
      // 根据输入内容判断使用OCR还是场景描述
      if (input.contains('字') || input.contains('文字') || input.contains('读')) {
        return recognizeText(imagePath);
      } else if (input.contains('颜色') || input.contains('色')) {
        return recognizeColor(imagePath);
      } else {
        return describeScene(imagePath);
      }
    }

    // 纯文本输入，进行对话或紧急检测
    final emergencyResult = await detectEmergency(input);
    if (emergencyResult.data?['isEmergency'] == true) {
      return emergencyResult;
    }

    return chat(input);
  }

  /// 流式对话（模拟）
  Stream<String> chatStream(String userMessage) async* {
    final response = await chat(userMessage);

    if (!response.success) {
      yield '抱歉，处理出错了';
      return;
    }

    // 模拟流式输出，逐字显示
    final text = response.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      yield buffer.toString();
      await Future.delayed(Duration(milliseconds: 30 + _random.nextInt(50)));
    }
  }
}
