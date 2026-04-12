/// AI演示回复数据
/// 用于演示版的AI功能，替代真实API调用

/// AI回复数据模型
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

/// OCR识别回复（药品）
const medicineOCRResponse = '''识别结果：阿司匹林肠溶片 100mg

用法用量：
• 每日一次，每次1片
• 饭后服用，温水送服

注意事项：
• 请勿空腹服用
• 如有不适请咨询医生

⚠️ 这是药品，建议志愿者确认''';

/// OCR识别回复（菜单）
const menuOCRResponse = '''识别结果：

🍽️ 今日推荐
宫保鸡丁 ........... 38元
鱼香肉丝 ........... 32元
麻婆豆腐 ........... 28元
清蒸鲈鱼 ........... 58元

🥬 素菜
蒜蓉西兰花 ....... 22元
干煸四季豆 ....... 26元''';

/// 场景描述回复
const sceneDescriptionResponse = '''场景描述：

📍 前方2米有一张木桌
📍 右侧1米有一扇门
📍 桌上有水杯（注意避让）
📍 地面平整，可以直行

💡 建议：
请缓慢前行，注意桌角''';

/// 颜色识别回复
const colorRecognitionResponse = '''颜色识别结果：

这件衣服是深蓝色

🎨 相近颜色：
• 藏青色
• 海军蓝
• 午夜蓝

💡 搭配建议：
适合搭配白色或浅灰色裤子''';

/// 对话回复模板
final Map<String, String> chatResponses = {
  'greeting': '您好！我是您的智能助手，有什么可以帮助您的吗？',
  'help_request': '我理解您需要帮助，请告诉我具体情况。',
  'volunteer_connect': '好的，正在为您连接志愿者，请稍候...',
  'ocr_request': '请拍照，我会帮您识别文字内容。',
  'scene_request': '请拍照，我会为您描述周围环境。',
  'color_request': '请拍照，我会帮您识别颜色。',
  'emergency': '⚠️ 检测到紧急情况！正在为您联系志愿者和紧急联系人。',
  'fallback': '抱歉，我不太明白。您可以换个说法，或者选择连接志愿者。',
};

/// 演示AI回复集合
final Map<String, AIResponse> demoAIResponses = {
  'medicine': const AIResponse(
    id: 'ai_001',
    type: 'ocr',
    title: '药品识别',
    input: '帮我看一下这个药',
    response: medicineOCRResponse,
    warning: '药品识别结果仅供参考',
  ),
  'menu': const AIResponse(
    id: 'ai_002',
    type: 'ocr',
    title: '菜单识别',
    input: '帮我读一下菜单',
    response: menuOCRResponse,
  ),
  'scene': const AIResponse(
    id: 'ai_003',
    type: 'scene',
    title: '场景描述',
    input: '帮我看一下周围环境',
    response: sceneDescriptionResponse,
  ),
  'color': const AIResponse(
    id: 'ai_004',
    type: 'color',
    title: '颜色识别',
    input: '这件衣服是什么颜色',
    response: colorRecognitionResponse,
  ),
};

/// 根据类型获取AI回复
AIResponse? getAIResponseByType(String type) {
  return demoAIResponses[type];
}

/// 模拟AI处理延迟
Future<AIResponse?> mockAIProcess(String type, {int delayMs = 1500}) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return getAIResponseByType(type);
}

/// 模拟流式回复（逐字输出）
Stream<String> mockAIStream(String text, {int charDelayMs = 50}) async* {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    buffer.write(text[i]);
    yield buffer.toString();
    await Future.delayed(Duration(milliseconds: charDelayMs));
  }
}
