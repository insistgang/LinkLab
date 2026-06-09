import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// 場景描述服務
/// F3 物體/場景識別與描述 + F7 環境描述的核心實現
/// 集成通義千問VL多模態大模型
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
      return AIResponse.error('場景描述需要圖片輸入');
    }

    if (_config.qwenApiKey == null) {
      return AIResponse.error('通義千問API密鑰未配置');
    }

    try {
      // 1. 讀取圖片並轉爲base64
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('圖片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. 構建提示詞
      final prompt = _buildPrompt(input);

      // 3. 調用通義千問VL API
      final result = await _callQwenVL(base64Image, prompt);

      // 4. 解析結構化輸出
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
      return AIResponse.error('場景描述失敗: $e');
    }
  }

  /// 構建提示詞
  String _buildPrompt(String userInput) {
    final lowerInput = userInput.toLowerCase();

    // 根據用戶輸入判斷描述類型
    if (lowerInput.contains('前面') ||
        lowerInput.contains('前方') ||
        lowerInput.contains('front')) {
      return '''請描述圖片中前方/正前方的場景。請按以下格式輸出：
1. 首先描述主要物體的名稱和類型
2. 然後描述物體相對於觀察者的位置（距離和方位）
3. 描述物體的特徵（顏色、大小、形狀等）
4. 如有潛在障礙物或危險，請特別指出

輸出格式示例："前方約2米處有一張木質桌子，桌子左側約1米處有一扇門，地面平整，可以安全通行。"'''
          ;
    }

    if (lowerInput.contains('周圍') ||
        lowerInput.contains('環境') ||
        lowerInput.contains('around') ||
        lowerInput.contains('environment')) {
      return '''請描述圖片中的整體環境佈局。請按以下格式輸出：
1. 描述場景類型（室內/室外，房間類型等）
2. 描述主要物體的位置分佈（使用相對方位：前方、後方、左側、右側）
3. 描述通道/行走空間
4. 指出可能的障礙物或危險區域
5. 給出行動建議

輸出格式示例："這是一個室內走廊場景。前方約3米處有拐角，右側約1米處有椅子，左側牆壁平整，中間有約1.5米寬的通道可以通行。地面平整，沒有明顯障礙物。"'''
          ;
    }

    if (lowerInput.contains('什麼') ||
        lowerInput.contains('物體') ||
        lowerInput.contains('object') ||
        lowerInput.contains('what')) {
      return '''請識別圖片中的主要物體。請按以下格式輸出：
1. 描述物體的名稱和類別
2. 描述物體的大致位置
3. 描述物體的關鍵特徵（顏色、形狀、大小）
4. 如有文字，請讀出文字內容

輸出格式示例："這是一張桌子，位於畫面中央，是深色木質的方形桌子，桌面上有一本打開的書。"'''
          ;
    }

    // 默認描述
    return '''請詳細描述這張圖片的內容。請按以下格式輸出：
1. 場景概述（室內/室外，環境類型）
2. 主要物體及其位置（使用距離和方位描述）
3. 空間佈局和通道情況
4. 安全提示（如有障礙物或危險）

請使用視障人士友好的描述方式，提供清晰的空間方位信息。'''
        ;
  }

  /// 調用通義千問VL API
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
        'temperature': 0.3, // 低溫度以獲得更確定的描述
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
      throw Exception('API請求失敗: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != null && data['code'] != '200') {
      throw Exception('API錯誤: ${data['message']}');
    }

    final output = data['output'] as Map<String, dynamic>?;
    final choices = output?['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('API返回結果爲空');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String? ?? '';

    // 計算置信度（基於finish_reason）
    final finishReason = choices[0]['finish_reason'] as String?;
    final confidence = finishReason == 'stop' ? 0.9 : 0.7;

    return QwenResult(
      rawText: content,
      confidence: confidence,
    );
  }

  /// 解析結構化描述
  StructuredDescription _parseStructuredDescription(QwenResult result) {
    final text = result.rawText;

    // 提取物體信息
    final objects = _extractObjects(text);

    // 提取空間關係
    final spatialRelations = _extractSpatialRelations(text);

    // 提取安全警告
    final safetyWarnings = _extractSafetyWarnings(text);

    // 格式化輸出
    final formattedText = _formatDescription(text, safetyWarnings);

    return StructuredDescription(
      formattedText: formattedText,
      objects: objects,
      spatialRelations: spatialRelations,
      safetyWarnings: safetyWarnings,
    );
  }

  /// 提取物體信息
  List<DetectedObject> _extractObjects(String text) {
    final objects = <DetectedObject>[];

    // 簡單的正則匹配提取物體和位置
    final patterns = [
      // 匹配 "前方X米有/是Y" 格式
      RegExp(r'([前後左右])方(?:約)?(\d+)米(?:處)?[有是]([\u4e00-\u9fa5]+)'),
      // 匹配 "X側有Y" 格式
      RegExp(r'([左右])側(?:約)?(\d+)米?(?:處)?[有是]([\u4e00-\u9fa5]+)'),
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

  /// 提取空間關係
  List<String> _extractSpatialRelations(String text) {
    final relations = <String>[];

    // 提取包含方位詞和距離描述的句子
    final sentences = text.split('，');
    for (final sentence in sentences) {
      if (sentence.contains('米') ||
          sentence.contains('前方') ||
          sentence.contains('後方') ||
          sentence.contains('左側') ||
          sentence.contains('右側')) {
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
      '危險',
      '障礙',
      '臺階',
      '樓梯',
      '門檻',
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

  /// 追問功能 - 獲取更詳細的描述
  Future<AIResponse> askFollowUp(
    String imageUrl,
    String followUpQuestion, {
    DialogContext? context,
  }) async {
    final specificPrompt = '''基於同一張圖片，用戶追問：$followUpQuestion
請針對這個問題給出詳細的回答，重點關注用戶詢問的具體內容。'''
        ;

    return process(specificPrompt, imageUrl: imageUrl, context: context);
  }
}

/// 通義千問返回結果
class QwenResult {
  final String rawText;
  final double confidence;

  const QwenResult({
    required this.rawText,
    required this.confidence,
  });
}

/// 結構化描述
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

/// 檢測到的物體
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
  String toString() => '$direction方約${distance}米的$name';
}
