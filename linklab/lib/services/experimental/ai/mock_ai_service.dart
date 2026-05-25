import 'dart:math';
import 'ai_service.dart';

/// 模拟AI服务
/// 演示优先策略：使用预置回复数据，不调用真实API
class MockAIService implements AIService {
  final Random _random = Random();
  final bool _simulateDelay;

  MockAIService({bool simulateDelay = true}) : _simulateDelay = simulateDelay;

  @override
  String get serviceName => 'MockAIService';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    // 模拟网络延迟（演示效果）
    if (_simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 根据输入内容返回对应的模拟回复
    final lowerInput = input.toLowerCase();

    // 1. 检查紧急关键词
    if (_containsEmergencyKeyword(lowerInput)) {
      return _emergencyResponse(input);
    }

    // 2. 根据意图返回对应回复
    if (_containsAny(lowerInput, ['颜色', 'color', '什么色'])) {
      return _colorRecognitionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['字', '文字', 'text', '写了什么'])) {
      return _ocrResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['什么', '物体', '东西', 'object', '这是什么'])) {
      return _objectRecognitionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['环境', '周围', '场景', 'scene', 'around'])) {
      return _sceneDescriptionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['药', '药品', 'medicine', '吃药'])) {
      return _medicineResponse();
    }

    if (_containsAny(lowerInput, ['病', '医生', '医院', 'sick', 'doctor'])) {
      return _medicalResponse();
    }

    if (_containsAny(lowerInput, ['难过', '伤心', 'sad', '孤独', 'lonely'])) {
      return _emotionalResponse();
    }

    if (_containsAny(lowerInput, ['你好', 'hello', '您好'])) {
      return _greetingResponse();
    }

    if (_containsAny(lowerInput, ['谢谢', '感谢', 'thank'])) {
      return _gratitudeResponse();
    }

    if (_containsAny(lowerInput, ['能做什么', '功能', 'help'])) {
      return _helpResponse();
    }

    // 默认回复
    return _defaultResponse();
  }

  // ==================== 预置回复数据 ====================

  AIResponse _colorRecognitionResponse(String? imageUrl) {
    final colors = [
      _ColorPreset('红色', '暖色调，类似番茄的颜色', 'RGB(255, 0, 0)'),
      _ColorPreset('蓝色', '冷色调，类似天空的颜色', 'RGB(0, 0, 255)'),
      _ColorPreset('绿色', '冷色调，类似草地的颜色', 'RGB(0, 128, 0)'),
      _ColorPreset('黄色', '明亮暖色调，类似柠檬的颜色', 'RGB(255, 255, 0)'),
      _ColorPreset('白色', '很浅的色调，类似雪的颜色', 'RGB(255, 255, 255)'),
      _ColorPreset('黑色', '很深的色调，类似夜晚的颜色', 'RGB(0, 0, 0)'),
      _ColorPreset('棕色', '深暖色调，类似木头的颜色', 'RGB(165, 42, 42)'),
      _ColorPreset('灰色', '中等色调，类似石头的颜色', 'RGB(128, 128, 128)'),
    ];

    final color = colors[_random.nextInt(colors.length)];

    return AIResponse(
      text: '主要颜色是${color.name}。\n\n色盲友好描述：${color.description}。\n\n色值：${color.rgbValue}',
      intent: IntentType.colorRecognition,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.92,
      extraData: {
        'color': color.name,
        'rgb': color.rgbValue,
        'mock': true,
      },
    );
  }

  AIResponse _ocrResponse(String? imageUrl) {
    final texts = [
      '识别到以下内容：\n\n新鲜水果\n苹果 5元/斤\n香蕉 3元/斤\n橙子 4元/斤',
      '识别到以下内容：\n\n快递单号：SF1234567890\n收件人：张先生\n地址：北京市朝阳区',
      '识别到以下内容：\n\n温馨提示\n请勿吸烟\n谢谢配合',
      '识别到以下内容：\n\n菜单\n红烧肉 38元\n清蒸鱼 48元\n炒时蔬 18元',
      '识别到以下内容：\n\n药品名称：阿莫西林胶囊\n用法：一次2粒，一日3次\n【重要提醒】这是药品标签，用药前请务必向志愿者或医生确认用法用量。',
    ];

    final text = texts[_random.nextInt(texts.length)];
    final isMedicine = text.contains('药品');

    return AIResponse(
      text: text,
      intent: IntentType.textRecognition,
      urgency: isMedicine ? UrgencyLevel.important : UrgencyLevel.normal,
      needsHuman: isMedicine,
      confidence: 0.95,
      extraData: {
        'isMedicineLabel': isMedicine,
        'mock': true,
      },
    );
  }

  AIResponse _objectRecognitionResponse(String? imageUrl) {
    final objects = [
      '这是一张木质桌子，位于画面中央，是深棕色的方形桌子，桌面上有一杯水和一本书。',
      '这是一把椅子，位于画面右侧，是黑色的办公椅，有扶手和滚轮。',
      '这是一扇门，位于画面左侧，是白色的木门，门把手在右侧。',
      '这是一辆汽车，位于画面中央，是银色的轿车，车头朝向右侧。',
      '这是一本书，位于画面中央偏下，封面是蓝色的，看起来有一定厚度。',
    ];

    return AIResponse(
      text: objects[_random.nextInt(objects.length)],
      intent: IntentType.objectRecognition,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.88,
      extraData: {'mock': true},
    );
  }

  AIResponse _sceneDescriptionResponse(String? imageUrl) {
    final scenes = [
      '这是一个室内客厅场景。前方约2米处有一张沙发，右侧约1米处有一扇窗户，左侧有一扇门。中间有约1.5米宽的通道可以通行。地面平整，没有明显障碍物。',
      '这是一个走廊场景。前方约3米处有拐角，右侧约1米处有椅子，左侧墙壁平整。中间有约1.5米宽的通道可以通行。地面平整，【安全提示】前方拐角处请注意。',
      '这是一个室外街道场景。前方约5米处有斑马线，右侧是人行道，左侧有树木。天气晴朗，光线充足。',
      '这是一个餐厅场景。前方约2米处有餐桌，右侧约1.5米处有服务台，左侧是窗户。中间有约2米宽的通道可以通行。',
    ];

    return AIResponse(
      text: scenes[_random.nextInt(scenes.length)],
      intent: IntentType.sceneDescription,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.90,
      extraData: {'mock': true},
    );
  }

  AIResponse _medicineResponse() {
    return AIResponse(
      text: '您咨询的是药品相关问题，药品使用需要谨慎确认，我将为您转接志愿者协助核对药品信息，请稍候。',
      intent: IntentType.medicineConfirmation,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _medicalResponse() {
    return AIResponse(
      text: '您咨询的是医疗相关问题，为了您的健康安全，我将为您转接专业医疗志愿者，请稍候。',
      intent: IntentType.medicalConsultation,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _emotionalResponse() {
    return AIResponse(
      text: '我理解您可能需要情感支持，让我为您转接心理支持志愿者，他们会更好地陪伴您。',
      intent: IntentType.emotionalSupport,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _emergencyResponse(String input) {
    return AIResponse(
      text: '检测到紧急情况"$input"，正在立即启动SOS流程！',
      intent: IntentType.emergency,
      urgency: UrgencyLevel.emergency,
      needsHuman: true,
      confidence: 0.98,
      extraData: {'triggerSOS': true, 'mock': true},
    );
  }

  AIResponse _greetingResponse() {
    return AIResponse(
      text: '您好！我是LinkAble智能助手，有什么可以帮助您的吗？您可以问我关于文字识别、物体识别、颜色识别、导航等问题。',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _gratitudeResponse() {
    return AIResponse(
      text: '不客气！很高兴能帮到您。如果还有其他问题，随时告诉我。',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _helpResponse() {
    return AIResponse(
      text: '我可以帮您：1. 识别图片中的文字并朗读；2. 识别物体和场景；3. 识别颜色；4. 识别钞票面额；5. 翻译外文；6. 提供导航指引；7. 描述周围环境。请告诉我您需要什么帮助？',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _defaultResponse() {
    final defaults = [
      '我理解您的意思。您可以拍照或详细描述一下，我会尽力帮助您。',
      '明白了，让我来帮您处理这个问题。',
      '好的，我来帮您看看。',
      '收到，请稍等片刻。',
    ];

    return AIResponse(
      text: defaults[_random.nextInt(defaults.length)],
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.7,
      extraData: {'mock': true},
    );
  }

  // ==================== 辅助方法 ====================

  bool _containsEmergencyKeyword(String input) {
    final keywords = [
      '救命', 'help', 'emergency', '救救我', '杀人', '抢劫',
      'fire', '着火了', '心脏病', '中风', '昏迷', '大出血',
    ];
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }
}

/// 颜色预设
class _ColorPreset {
  final String name;
  final String description;
  final String rgbValue;

  _ColorPreset(this.name, this.description, this.rgbValue);
}
