import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'ai_service.dart';

/// 通義千問VL服務
/// F3 物體/場景識別與描述 + F7 環境描述的核心實現
/// 集成通義千問VL多模態大模型
class QwenVLService implements AIService {
  final _client = http.Client();

  @override
  String get serviceName => 'QwenVLService';

  @override
  Future<bool> isAvailable() async {
    return APIConfig.isQwenConfigured;
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

    if (!APIConfig.isQwenConfigured) {
      return AIResponse.error('通義千問API密鑰未配置，請在APIConfig中設置');
    }

    try {
      final result = await describeScene(File(imageUrl), customPrompt: input);

      if (!result.isSuccess) {
        return AIResponse.error(result.error?.message ?? '場景描述失敗');
      }

      final description = result.data!;

      return AIResponse(
        text: description.formattedText,
        intent: IntentType.sceneDescription,
        urgency: UrgencyLevel.normal,
        needsHuman: false,
        confidence: description.confidence,
        extraData: {
          'rawResponse': description.rawText,
          'objects': description.objects.map((o) => o.toString()).toList(),
          'spatialRelations': description.spatialRelations,
          'safetyWarnings': description.safetyWarnings,
          'sceneType': description.sceneType,
        },
      );
    } catch (e) {
      return AIResponse.error('場景描述失敗: $e');
    }
  }

  /// 描述場景
  /// [image] 圖片文件
  /// [customPrompt] 自定義提示詞（可選）
  Future<APIResponse<SceneDescription>> describeScene(
    File image, {
    String? customPrompt,
  }) async {
    final prompt = customPrompt?.isNotEmpty == true
        ? _buildCustomPrompt(customPrompt!)
        : _buildDefaultPrompt();

    return await _callQwenVLWithRetry(image, prompt);
  }

  /// 回答關於圖片的問題
  /// [image] 圖片文件
  /// [question] 用戶問題
  Future<APIResponse<String>> answerQuestion(
    File image,
    String question,
  ) async {
    final prompt = _buildQuestionPrompt(question);
    final result = await _callQwenVLWithRetry(image, prompt);

    if (result.isSuccess) {
      return APIResponse.success(result.data!.rawText);
    }
    return APIResponse.failure(result.error!);
  }

  /// 識別物體
  /// [image] 圖片文件
  /// [focusObject] 關注的物體類型（可選）
  Future<APIResponse<List<DetectedObject>>> detectObjects(
    File image, {
    String? focusObject,
  }) async {
    final prompt = _buildObjectDetectionPrompt(focusObject);
    final result = await _callQwenVLWithRetry(image, prompt);

    if (result.isSuccess) {
      return APIResponse.success(result.data!.objects);
    }
    return APIResponse.failure(result.error!);
  }

  /// 分析空間佈局
  /// [image] 圖片文件
  Future<APIResponse<SpatialLayout>> analyzeSpatialLayout(File image) async {
    final prompt = _buildSpatialLayoutPrompt();
    final result = await _callQwenVLWithRetry(image, prompt);

    if (result.isSuccess) {
      final desc = result.data!;
      return APIResponse.success(SpatialLayout(
        sceneType: desc.sceneType,
        objects: desc.objects,
        relations: desc.spatialRelations,
        passableAreas: desc.passableAreas,
        obstacles: desc.obstacles,
        safetyWarnings: desc.safetyWarnings,
      ));
    }
    return APIResponse.failure(result.error!);
  }

  /// 帶重試機制的API調用
  Future<APIResponse<SceneDescription>> _callQwenVLWithRetry(
    File image,
    String prompt, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await _callQwenVL(image, prompt);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (e is APIError) {
            return APIResponse.failure(e);
          }
          return APIResponse.failure(APIError(
            type: APIErrorType.unknown,
            message: '場景描述失敗，已重試$maxRetries次',
            originalError: e.toString(),
          ));
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    return APIResponse.failure(APIError(
      type: APIErrorType.unknown,
      message: '場景描述失敗',
    ));
  }

  /// 調用通義千問VL API
  Future<APIResponse<SceneDescription>> _callQwenVL(
    File image,
    String prompt,
  ) async {
    final base64Image = base64Encode(await image.readAsBytes());

    // 檢查圖片大小（限制5MB）
    final imageBytes = base64Decode(base64Image);
    if (imageBytes.length > 5 * 1024 * 1024) {
      return APIResponse.failure(APIError(
        type: APIErrorType.invalidParameter,
        message: '圖片過大，請壓縮後重試（最大5MB）',
      ));
    }

    final url = Uri.parse(
      '${APIConfig.qwenBaseUrl}/services/aigc/multimodal-generation/generation',
    );

    final requestBody = {
      'model': APIConfig.qwenModel,
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
        'max_tokens': APIConfig.qwenMaxTokens,
        'temperature': APIConfig.qwenTemperature,
      },
    };

    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${APIConfig.qwenApiKey}',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

    return _handleQwenResponse(response);
  }

  /// 處理通義千問響應
  APIResponse<SceneDescription> _handleQwenResponse(http.Response response) {
    if (response.statusCode != 200) {
      // 處理特定狀態碼
      if (response.statusCode == 401) {
        return APIResponse.failure(APIError.authentication(
          'Invalid API Key',
        ));
      }
      if (response.statusCode == 429) {
        return APIResponse.failure(APIError.quotaExceeded(
          'Rate limit exceeded',
        ));
      }
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}: ${response.body}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    // 檢查業務錯誤碼
    final code = data['code'];
    if (code != null && code != '200') {
      final message = data['message'] ?? '未知錯誤';

      if (code == 'InvalidApiKey') {
        return APIResponse.failure(APIError.authentication(message));
      }
      if (code == 'Throttling' || code == 'QuotaExceeded') {
        return APIResponse.failure(APIError.quotaExceeded(message));
      }

      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: 'API錯誤: $message',
        originalError: message,
      ));
    }

    final output = data['output'] as Map<String, dynamic>?;
    final choices = output?['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: 'API返回結果爲空',
      ));
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String? ?? '';

    // 計算置信度
    final finishReason = choices[0]['finish_reason'] as String?;
    final confidence = finishReason == 'stop' ? 0.9 : 0.7;

    // 解析結構化描述
    final description = _parseDescription(content, confidence);

    return APIResponse.success(description);
  }

  /// 構建默認提示詞
  String _buildDefaultPrompt() {
    return '''請詳細描述這張圖片的內容，幫助視障人士理解周圍環境。請按以下格式輸出：

1. 場景概述（室內/室外，環境類型）
2. 主要物體及其位置（使用距離和方位描述，如"前方約2米處"、"右側約1米處"）
3. 空間佈局和通道情況
4. 安全提示（如有障礙物或危險）

請使用視障人士友好的描述方式：
- 提供清晰的空間方位信息
- 使用具體的距離描述
- 指出可能的障礙物或危險
- 給出行動建議

輸出示例：
這是一個室內客廳場景。前方約2米處有一張沙發，右側約1米處有一扇窗戶，左側有一扇門。中間有約1.5米寬的通道可以通行。地面平整，沒有明顯障礙物。'''
        ;
  }

  /// 構建自定義提示詞
  String _buildCustomPrompt(String userInput) {
    final lowerInput = userInput.toLowerCase();

    // 前方場景
    if (lowerInput.contains('前面') ||
        lowerInput.contains('前方') ||
        lowerInput.contains('front') ||
        lowerInput.contains('ahead')) {
      return '''請描述圖片中前方/正前方的場景。請按以下格式輸出：

1. 首先描述主要物體的名稱和類型
2. 然後描述物體相對於觀察者的位置（距離和方位）
3. 描述物體的特徵（顏色、大小、形狀等）
4. 如有潛在障礙物或危險，請特別指出
5. 給出是否可以通行的建議

請使用視障人士友好的描述方式，提供清晰的空間方位信息和具體距離。

輸出示例："前方約2米處有一張木質桌子，桌子左側約1米處有一扇門，地面平整，可以安全通行。"'''
          ;
    }

    // 周圍環境
    if (lowerInput.contains('周圍') ||
        lowerInput.contains('環境') ||
        lowerInput.contains('場景') ||
        lowerInput.contains('around') ||
        lowerInput.contains('environment') ||
        lowerInput.contains('surrounding')) {
      return '''請描述圖片中的整體環境佈局。請按以下格式輸出：

1. 描述場景類型（室內/室外，房間類型等）
2. 描述主要物體的位置分佈（使用相對方位：前方、後方、左側、右側）
3. 描述通道/行走空間
4. 指出可能的障礙物或危險區域
5. 給出行動建議

請使用視障人士友好的描述方式，提供清晰的空間方位信息。

輸出示例："這是一個室內走廊場景。前方約3米處有拐角，右側約1米處有椅子，左側牆壁平整，中間有約1.5米寬的通道可以通行。地面平整，沒有明顯障礙物。"'''
          ;
    }

    // 物體識別
    if (lowerInput.contains('什麼') ||
        lowerInput.contains('物體') ||
        lowerInput.contains('東西') ||
        lowerInput.contains('object') ||
        lowerInput.contains('what')) {
      return '''請識別圖片中的主要物體。請按以下格式輸出：

1. 描述物體的名稱和類別
2. 描述物體的大致位置
3. 描述物體的關鍵特徵（顏色、形狀、大小、材質等）
4. 如有文字，請讀出文字內容
5. 說明物體是否可能造成障礙

請使用視障人士友好的描述方式。

輸出示例："這是一張桌子，位於畫面中央，是深色木質的方形桌子，桌面上有一本打開的書。桌子高度約75釐米，不會阻擋通行。"'''
          ;
    }

    // 導航相關
    if (lowerInput.contains('導航') ||
        lowerInput.contains('怎麼走') ||
        lowerInput.contains('路線') ||
        lowerInput.contains('navigate') ||
        lowerInput.contains('direction')) {
      return '''請分析圖片中的環境，提供導航指引。請按以下格式輸出：

1. 描述當前所在位置的環境特徵
2. 指出可通行的方向
3. 描述前方路徑情況
4. 指出需要注意的障礙物或危險
5. 給出具體的行走建議

請使用視障人士友好的描述方式，提供清晰的方向指引。

輸出示例："您當前在一個走廊中。前方約3米處有拐角，建議沿右側牆壁行走。中間通道寬約1.5米，地面平整，可以安全通行。到達拐角後請停下再次確認方向。"'''
          ;
    }

    // 默認使用用戶輸入作爲提示詞
    return '''$userInput

請使用視障人士友好的描述方式，提供清晰的空間方位信息和具體距離。如有障礙物或危險請特別指出。'''
        ;
  }

  /// 構建問題提示詞
  String _buildQuestionPrompt(String question) {
    return '''用戶問：$question

請基於圖片內容回答這個問題。回答要簡潔明瞭，適合語音播報。如果圖片中沒有相關信息，請明確說明。'''
        ;
  }

  /// 構建物體檢測提示詞
  String _buildObjectDetectionPrompt(String? focusObject) {
    final focus = focusObject?.isNotEmpty == true
        ? '特別關注$focusObject類物體。'
        : '';

    return '''請識別圖片中的所有主要物體。$focus

請按以下格式列出物體：
1. 物體名稱 - 位置描述 - 特徵描述
2. ...

位置描述請使用：前方、後方、左側、右側、中央等方位詞，並儘可能提供距離信息。
特徵描述包括：顏色、大小、形狀等。

最後總結是否有障礙物影響通行。'''
        ;
  }

  /// 構建空間佈局提示詞
  String _buildSpatialLayoutPrompt() {
    return '''請詳細分析圖片中的空間佈局，幫助視障人士理解環境結構。

請按以下格式輸出：

【場景類型】
室內/室外，具體場所類型

【主要物體分佈】
- 前方：...
- 後方：...
- 左側：...
- 右側：...

【可通行區域】
描述可以安全行走的空間

【障礙物/危險】
列出需要注意的障礙物

【行動建議】
給出具體的移動建議'''
        ;
  }

  /// 解析描述
  SceneDescription _parseDescription(String text, double confidence) {
    // 提取物體信息
    final objects = _extractObjects(text);

    // 提取空間關係
    final spatialRelations = _extractSpatialRelations(text);

    // 提取安全警告
    final safetyWarnings = _extractSafetyWarnings(text);

    // 檢測場景類型
    final sceneType = _detectSceneType(text);

    // 提取可通行區域
    final passableAreas = _extractPassableAreas(text);

    // 提取障礙物
    final obstacles = _extractObstacles(text);

    // 格式化輸出
    final formattedText = _formatDescription(text, safetyWarnings);

    return SceneDescription(
      rawText: text,
      formattedText: formattedText,
      objects: objects,
      spatialRelations: spatialRelations,
      safetyWarnings: safetyWarnings,
      sceneType: sceneType,
      passableAreas: passableAreas,
      obstacles: obstacles,
      confidence: confidence,
    );
  }

  /// 提取物體信息
  List<DetectedObject> _extractObjects(String text) {
    final objects = <DetectedObject>[];

    // 匹配 "前方X米有/是Y" 格式
    final pattern1 = RegExp(r'([前後左右])方(?:約)?(\d+)米(?:處)?[有是]([\u4e00-\u9fa5]+)');
    for (final match in pattern1.allMatches(text)) {
      objects.add(DetectedObject(
        name: match.group(3) ?? '',
        direction: match.group(1) ?? '',
        distance: double.tryParse(match.group(2) ?? '0') ?? 0,
      ));
    }

    // 匹配 "X側有Y" 格式
    final pattern2 = RegExp(r'([左右])側(?:約)?(\d+)?米?(?:處)?[有是]([\u4e00-\u9fa5]+)');
    for (final match in pattern2.allMatches(text)) {
      objects.add(DetectedObject(
        name: match.group(3) ?? '',
        direction: match.group(1) ?? '',
        distance: double.tryParse(match.group(2) ?? '0') ?? 0,
      ));
    }

    // 匹配 "Y在X方" 格式
    final pattern3 = RegExp(r'([\u4e00-\u9fa5]+)在([前後左右])方');
    for (final match in pattern3.allMatches(text)) {
      objects.add(DetectedObject(
        name: match.group(1) ?? '',
        direction: match.group(2) ?? '',
        distance: 0,
      ));
    }

    return objects;
  }

  /// 提取空間關係
  List<String> _extractSpatialRelations(String text) {
    final relations = <String>[];
    final sentences = text.split(RegExp(r'[。！\n]'));

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.contains('米') ||
          trimmed.contains('前方') ||
          trimmed.contains('後方') ||
          trimmed.contains('左側') ||
          trimmed.contains('右側') ||
          trimmed.contains('通道') ||
          trimmed.contains('距離')) {
        relations.add(trimmed);
      }
    }

    return relations;
  }

  /// 提取安全警告
  List<String> _extractSafetyWarnings(String text) {
    final warnings = <String>[];
    final warningKeywords = [
      '注意', '小心', '危險', '障礙', '臺階', '樓梯', '門檻',
      '滑', '陡', '窄', '低', '碰撞', '絆倒', '摔倒',
      '避讓', '繞行', '停止', '謹慎',
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

    return warnings.toSet().toList(); // 去重
  }

  /// 檢測場景類型
  String _detectSceneType(String text) {
    final indoorKeywords = ['室內', '房間', '客廳', '臥室', '廚房', '走廊', '辦公室'];
    final outdoorKeywords = ['室外', '街道', '馬路', '公園', '廣場', '戶外'];

    for (final keyword in indoorKeywords) {
      if (text.contains(keyword)) return 'indoor';
    }
    for (final keyword in outdoorKeywords) {
      if (text.contains(keyword)) return 'outdoor';
    }

    return 'unknown';
  }

  /// 提取可通行區域
  List<String> _extractPassableAreas(String text) {
    final areas = <String>[];
    final patterns = [
      RegExp(r'[有|中間|兩側]([^，。]+)通道'),
      RegExp(r'可以([^，。]+)通行'),
      RegExp(r'([^，。]+)可以走'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        areas.add(match.group(0) ?? '');
      }
    }

    return areas;
  }

  /// 提取障礙物
  List<String> _extractObstacles(String text) {
    final obstacles = <String>[];
    final obstacleKeywords = [
      '障礙物', '臺階', '門檻', '樓梯', '柱子', '牆壁', '欄杆',
      '椅子', '桌子', '箱子', '雜物',
    ];

    for (final keyword in obstacleKeywords) {
      if (text.contains(keyword)) {
        // 提取包含該關鍵詞的句子
        final sentences = text.split('。');
        for (final sentence in sentences) {
          if (sentence.contains(keyword)) {
            obstacles.add(sentence.trim());
            break;
          }
        }
      }
    }

    return obstacles.toSet().toList(); // 去重
  }

  /// 格式化描述
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

  /// 釋放資源
  void dispose() {
    _client.close();
  }
}

/// 場景描述
class SceneDescription {
  final String rawText;
  final String formattedText;
  final List<DetectedObject> objects;
  final List<String> spatialRelations;
  final List<String> safetyWarnings;
  final String sceneType;
  final List<String> passableAreas;
  final List<String> obstacles;
  final double confidence;

  const SceneDescription({
    required this.rawText,
    required this.formattedText,
    required this.objects,
    required this.spatialRelations,
    required this.safetyWarnings,
    required this.sceneType,
    required this.passableAreas,
    required this.obstacles,
    required this.confidence,
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
  String toString() => distance > 0
      ? '$direction方約${distance.toInt()}米的$name'
      : '$direction方的$name';
}

/// 空間佈局
class SpatialLayout {
  final String sceneType;
  final List<DetectedObject> objects;
  final List<String> relations;
  final List<String> passableAreas;
  final List<String> obstacles;
  final List<String> safetyWarnings;

  const SpatialLayout({
    required this.sceneType,
    required this.objects,
    required this.relations,
    required this.passableAreas,
    required this.obstacles,
    required this.safetyWarnings,
  });
}
