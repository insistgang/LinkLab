/// AI演示回覆數據
/// 用於演示版的AI功能，替代真實API調用
library;

/// AI回覆數據模型
class AIResponse {
  final String id;
  final String type;
  final String title;
  final String input;
  final String response;
  final String? warning;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.input,
    required this.response,
    this.warning,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'input': input,
        'response': response,
        'warning': warning,
        'metadata': metadata,
      };

  factory AIResponse.fromJson(Map<String, dynamic> json) => AIResponse(
        id: (json['id'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        input: (json['input'] as String?) ?? '',
        response: (json['response'] as String?) ?? '',
        warning: json['warning'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// OCR識別回覆（藥品）
const medicineOCRResponse = '''識別結果：阿司匹林腸溶片 100mg

用法用量：
• 每日一次，每次1片
• 飯後服用，溫水送服

注意事項：
• 請勿空腹服用
• 如有不適請諮詢醫生

⚠️ 這是藥品，建議志願者確認''';

/// OCR識別回覆（菜單）
const menuOCRResponse = '''識別結果：

🍽️ 今日推薦
宮保雞丁 ........... 38元
魚香肉絲 ........... 32元
麻婆豆腐 ........... 28元
清蒸鱸魚 ........... 58元

🥬 素菜
蒜蓉西蘭花 ....... 22元
乾煸四季豆 ....... 26元''';

/// 場景描述回覆
const sceneDescriptionResponse = '''場景描述：

📍 前方2米有一張木桌
📍 右側1米有一扇門
📍 桌上有水杯（注意避讓）
📍 地面平整，可以直行

💡 建議：
請緩慢前行，注意桌角''';

/// 顏色識別回覆
const colorRecognitionResponse = '''顏色識別結果：

這件衣服是深藍色

🎨 相近顏色：
• 藏青色
• 海軍藍
• 午夜藍

💡 搭配建議：
適合搭配白色或淺灰色褲子''';

/// 對話回覆模板
final Map<String, String> chatResponses = {
  'greeting': '您好！我是您的智能助手，有什麼可以幫助您的嗎？',
  'help_request': '我理解您需要幫助，請告訴我具體情況。',
  'volunteer_connect': '好的，正在爲您連接志願者，請稍候...',
  'ocr_request': '請拍照，我會幫您識別文字內容。',
  'scene_request': '請拍照，我會爲您描述周圍環境。',
  'color_request': '請拍照，我會幫您識別顏色。',
  'emergency': '⚠️ 檢測到緊急情況！正在爲您聯繫志願者和緊急聯繫人。',
  'fallback': '抱歉，我不太明白。您可以換個說法，或者選擇連接志願者。',
};

/// 演示AI回覆集合
final Map<String, AIResponse> demoAIResponses = {
  'medicine': const AIResponse(
    id: 'ai_001',
    type: 'ocr',
    title: '藥品識別',
    input: '幫我看一下這個藥',
    response: medicineOCRResponse,
    warning: '藥品識別結果僅供參考',
  ),
  'menu': const AIResponse(
    id: 'ai_002',
    type: 'ocr',
    title: '菜單識別',
    input: '幫我讀一下菜單',
    response: menuOCRResponse,
  ),
  'scene': const AIResponse(
    id: 'ai_003',
    type: 'scene',
    title: '場景描述',
    input: '幫我看一下周圍環境',
    response: sceneDescriptionResponse,
  ),
  'color': const AIResponse(
    id: 'ai_004',
    type: 'color',
    title: '顏色識別',
    input: '這件衣服是什麼顏色',
    response: colorRecognitionResponse,
  ),
};

/// 根據類型獲取AI回覆
AIResponse? getAIResponseByType(String type) {
  return demoAIResponses[type];
}

/// 模擬AI處理延遲
Future<AIResponse?> mockAIProcess(String type, {int delayMs = 1500}) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return getAIResponseByType(type);
}

/// 模擬流式回覆（逐字輸出）
Stream<String> mockAIStream(String text, {int charDelayMs = 50}) async* {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    buffer.write(text[i]);
    yield buffer.toString();
    await Future.delayed(Duration(milliseconds: charDelayMs));
  }
}
