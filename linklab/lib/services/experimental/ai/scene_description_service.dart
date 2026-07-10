import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// 场景描述服务
/// F3 物体/场景识别与描述 + F7 环境描述的核心实现
/// 集成通义千问VL多模态大模型
class SceneDescriptionService implements AIService {
  static const String _baseUrl = 'https://dashscope.aliyuncs.com/api/v1';
  static const String _model = 'qwen-vl-plus';

  final AIServiceConfig _config;

  SceneDescriptionService({required AIServiceConfig config}) : _config = config;

  @override
  String get serviceName => 'SceneDescriptionService';

  @override
  Future<bool> isAvailable() async {
    return _config.qwenApiKey != null && _config.qwenApiKey!.isNotEmpty;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    if (imageUrl == null) {
      return AIResponse.error('场景描述需要图片输入');
    }

    if (_config.qwenApiKey == null) {
      return AIResponse.error('通义千问API密钥未配置');
    }

    try {
      // 1. 读取图片并转为base64
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('图片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. 构建提示词
      final prompt = _buildPrompt(input);

      // 3. 调用通义千问VL API
      final result = await _callQwenVL(base64Image, prompt);

      // 4. 解析结构化输出
      final structuredDesc = _parseStructuredDescription(result);

      return AIResponse(
        text: structuredDesc.formattedText,
        intent: IntentType.sceneDescription,
        urgency: UrgencyLevel.normal,
        needsHuman: false,
        confidence: result.confidence,
        extraData: {
          'rawResponse': result.rawText,
          'objects': structuredDesc.objects,
          'spatialRelations': structuredDesc.spatialRelations,
          'safetyWarnings': structuredDesc.safetyWarnings,
        },
      );
    } catch (e) {
      return AIResponse.error('场景描述失败: $e');
    }
  }

  /// 构建提示词
  String _buildPrompt(String userInput) {
    final lowerInput = userInput.toLowerCase();

    // 根据用户输入判断描述类型
    if (lowerInput.contains('前面') ||
        lowerInput.contains('前方') ||
        lowerInput.contains('front')) {
      return '''请描述图片中前方/正前方的场景。请按以下格式输出：
1. 首先描述主要物体的名称和类型
2. 然后描述物体相对于观察者的位置（距离和方位）
3. 描述物体的特征（颜色、大小、形状等）
4. 如有潜在障碍物或危险，请特别指出

输出格式示例："前方约2米处有一张木质桌子，桌子左侧约1米处有一扇门，地面平整，可以安全通行。"'''
          ;
    }

    if (lowerInput.contains('周围') ||
        lowerInput.contains('环境') ||
        lowerInput.contains('around') ||
        lowerInput.contains('environment')) {
      return '''请描述图片中的整体环境布局。请按以下格式输出：
1. 描述场景类型（室内/室外，房间类型等）
2. 描述主要物体的位置分布（使用相对方位：前方、后方、左侧、右侧）
3. 描述通道/行走空间
4. 指出可能的障碍物或危险区域
5. 给出行动建议

输出格式示例："这是一个室内走廊场景。前方约3米处有拐角，右侧约1米处有椅子，左侧墙壁平整，中间有约1.5米宽的通道可以通行。地面平整，没有明显障碍物。"'''
          ;
    }

    if (lowerInput.contains('什么') ||
        lowerInput.contains('物体') ||
        lowerInput.contains('object') ||
        lowerInput.contains('what')) {
      return '''请识别图片中的主要物体。请按以下格式输出：
1. 描述物体的名称和类别
2. 描述物体的大致位置
3. 描述物体的关键特征（颜色、形状、大小）
4. 如有文字，请读出文字内容

输出格式示例："这是一张桌子，位于画面中央，是深色木质的方形桌子，桌面上有一本打开的书。"'''
          ;
    }

    // 默认描述
    return '''请详细描述这张图片的内容。请按以下格式输出：
1. 场景概述（室内/室外，环境类型）
2. 主要物体及其位置（使用距离和方位描述）
3. 空间布局和通道情况
4. 安全提示（如有障碍物或危险）

请使用视障人士友好的描述方式，提供清晰的空间方位信息。'''
        ;
  }

  /// 调用通义千问VL API
  Future<QwenResult> _callQwenVL(String base64Image, String prompt) async {
    final url = Uri.parse('$_baseUrl/services/aigc/multimodal-generation/generation');

    final requestBody = {
      'model': _model,
      'input': {
        'messages': [
          {
            'role': 'user',
            'content': [
              {'image': 'data:image/jpeg;base64,$base64Image'},
              {'text': prompt},
            ],
          },
        ],
      },
      'parameters': {
        'result_format': 'message',
        'max_tokens': 800,
        'temperature': 0.3, // 低温度以获得更确定的描述
      },
    };

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_config.qwenApiKey}',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(Duration(seconds: _config.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != null && data['code'] != '200') {
      throw Exception('API错误: ${data['message']}');
    }

    final output = data['output'] as Map<String, dynamic>?;
    final choices = output?['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('API返回结果为空');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String? ?? '';

    // 计算置信度（基于finish_reason）
    final finishReason = choices[0]['finish_reason'] as String?;
    final confidence = finishReason == 'stop' ? 0.9 : 0.7;

    return QwenResult(
      rawText: content,
      confidence: confidence,
    );
  }

  /// 解析结构化描述
  StructuredDescription _parseStructuredDescription(QwenResult result) {
    final text = result.rawText;

    // 提取物体信息
    final objects = _extractObjects(text);

    // 提取空间关系
    final spatialRelations = _extractSpatialRelations(text);

    // 提取安全警告
    final safetyWarnings = _extractSafetyWarnings(text);

    // 格式化输出
    final formattedText = _formatDescription(text, safetyWarnings);

    return StructuredDescription(
      formattedText: formattedText,
      objects: objects,
      spatialRelations: spatialRelations,
      safetyWarnings: safetyWarnings,
    );
  }

  /// 提取物体信息
  List<DetectedObject> _extractObjects(String text) {
    final objects = <DetectedObject>[];

    // 简单的正则匹配提取物体和位置
    final patterns = [
      // 匹配 "前方X米有/是Y" 格式
      RegExp(r'([前后左右])方(?:约)?(\d+)米(?:处)?[有是]([\u4e00-\u9fa5]+)'),
      // 匹配 "X侧有Y" 格式
      RegExp(r'([左右])侧(?:约)?(\d+)米?(?:处)?[有是]([\u4e00-\u9fa5]+)'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        objects.add(DetectedObject(
          name: match.group(3) ?? '',
          direction: match.group(1) ?? '',
          distance: double.tryParse(match.group(2) ?? '0') ?? 0,
        ));
      }
    }

    return objects;
  }

  /// 提取空间关系
  List<String> _extractSpatialRelations(String text) {
    final relations = <String>[];

    // 提取包含方位词和距离描述的句子
    final sentences = text.split('，');
    for (final sentence in sentences) {
      if (sentence.contains('米') ||
          sentence.contains('前方') ||
          sentence.contains('后方') ||
          sentence.contains('左侧') ||
          sentence.contains('右侧')) {
        relations.add(sentence.trim());
      }
    }

    return relations;
  }

  /// 提取安全警告
  List<String> _extractSafetyWarnings(String text) {
    final warnings = <String>[];
    final warningKeywords = [
      '注意',
      '小心',
      '危险',
      '障碍',
      '台阶',
      '楼梯',
      '门槛',
      '滑',
      '陡',
      '窄',
      '低',
      '碰撞',
    ];

    final sentences = text.split('。');
    for (final sentence in sentences) {
      for (final keyword in warningKeywords) {
        if (sentence.contains(keyword)) {
          warnings.add(sentence.trim());
          break;
        }
      }
    }

    return warnings;
  }

  /// 格式化描述文本
  String _formatDescription(String text, List<String> safetyWarnings) {
    final buffer = StringBuffer();

    buffer.writeln(text);

    if (safetyWarnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【安全提示】');
      for (final warning in safetyWarnings) {
        buffer.writeln('• $warning');
      }
    }

    return buffer.toString();
  }

  /// 追问功能 - 获取更详细的描述
  Future<AIResponse> askFollowUp(
    String imageUrl,
    String followUpQuestion, {
    DialogContext? context,
  }) async {
    final specificPrompt = '''基于同一张图片，用户追问：$followUpQuestion
请针对这个问题给出详细的回答，重点关注用户询问的具体内容。'''
        ;

    return process(specificPrompt, imageUrl: imageUrl, context: context);
  }
}

/// 通义千问返回结果
class QwenResult {
  final String rawText;
  final double confidence;

  const QwenResult({
    required this.rawText,
    required this.confidence,
  });
}

/// 结构化描述
class StructuredDescription {
  final String formattedText;
  final List<DetectedObject> objects;
  final List<String> spatialRelations;
  final List<String> safetyWarnings;

  const StructuredDescription({
    required this.formattedText,
    required this.objects,
    required this.spatialRelations,
    required this.safetyWarnings,
  });
}

/// 检测到的物体
class DetectedObject {
  final String name;
  final String direction;
  final double distance;

  const DetectedObject({
    required this.name,
    required this.direction,
    required this.distance,
  });

  @override
  String toString() => '$direction方约${distance}米的$name';
}
