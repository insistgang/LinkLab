import 'dart:math';
import 'ai_service.dart';

/// 模擬AI服務
/// 演示優先策略：使用預置回覆數據，不調用真實API
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
    // 模擬網絡延遲（演示效果）
    if (_simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 根據輸入內容返回對應的模擬回覆
    final lowerInput = input.toLowerCase();

    // 1. 檢查緊急關鍵詞
    if (_containsEmergencyKeyword(lowerInput)) {
      return _emergencyResponse(input);
    }

    // 2. 根據意圖返回對應回覆
    if (_containsAny(lowerInput, ['顏色', 'color', '什麼色'])) {
      return _colorRecognitionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['字', '文字', 'text', '寫了什麼'])) {
      return _ocrResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['什麼', '物體', '東西', 'object', '這是什麼'])) {
      return _objectRecognitionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['環境', '周圍', '場景', 'scene', 'around'])) {
      return _sceneDescriptionResponse(imageUrl);
    }

    if (_containsAny(lowerInput, ['藥', '藥品', 'medicine', '喫藥'])) {
      return _medicineResponse();
    }

    if (_containsAny(lowerInput, ['病', '醫生', '醫院', 'sick', 'doctor'])) {
      return _medicalResponse();
    }

    if (_containsAny(lowerInput, ['難過', '傷心', 'sad', '孤獨', 'lonely'])) {
      return _emotionalResponse();
    }

    if (_containsAny(lowerInput, ['你好', 'hello', '您好'])) {
      return _greetingResponse();
    }

    if (_containsAny(lowerInput, ['謝謝', '感謝', 'thank'])) {
      return _gratitudeResponse();
    }

    if (_containsAny(lowerInput, ['能做什麼', '功能', 'help'])) {
      return _helpResponse();
    }

    // 默認回覆
    return _defaultResponse();
  }

  // ==================== 預置回覆數據 ====================

  AIResponse _colorRecognitionResponse(String? imageUrl) {
    final colors = [
      _ColorPreset('紅色', '暖色調，類似番茄的顏色', 'RGB(255, 0, 0)'),
      _ColorPreset('藍色', '冷色調，類似天空的顏色', 'RGB(0, 0, 255)'),
      _ColorPreset('綠色', '冷色調，類似草地的顏色', 'RGB(0, 128, 0)'),
      _ColorPreset('黃色', '明亮暖色調，類似檸檬的顏色', 'RGB(255, 255, 0)'),
      _ColorPreset('白色', '很淺的色調，類似雪的顏色', 'RGB(255, 255, 255)'),
      _ColorPreset('黑色', '很深的色調，類似夜晚的顏色', 'RGB(0, 0, 0)'),
      _ColorPreset('棕色', '深暖色調，類似木頭的顏色', 'RGB(165, 42, 42)'),
      _ColorPreset('灰色', '中等色調，類似石頭的顏色', 'RGB(128, 128, 128)'),
    ];

    final color = colors[_random.nextInt(colors.length)];

    return AIResponse(
      text: '主要顏色是${color.name}。\n\n色盲友好描述：${color.description}。\n\n色值：${color.rgbValue}',
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
      '識別到以下內容：\n\n新鮮水果\n蘋果 5元/斤\n香蕉 3元/斤\n橙子 4元/斤',
      '識別到以下內容：\n\n快遞單號：SF1234567890\n收件人：張先生\n地址：北京市朝陽區',
      '識別到以下內容：\n\n溫馨提示\n請勿吸菸\n謝謝配合',
      '識別到以下內容：\n\n菜單\n紅燒肉 38元\n清蒸魚 48元\n炒時蔬 18元',
      '識別到以下內容：\n\n藥品名稱：阿莫西林膠囊\n用法：一次2粒，一日3次\n【重要提醒】這是藥品標籤，用藥前請務必向志願者或醫生確認用法用量。',
    ];

    final text = texts[_random.nextInt(texts.length)];
    final isMedicine = text.contains('藥品');

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
      '這是一張木質桌子，位於畫面中央，是深棕色的方形桌子，桌面上有一杯水和一本書。',
      '這是一把椅子，位於畫面右側，是黑色的辦公椅，有扶手和滾輪。',
      '這是一扇門，位於畫面左側，是白色的木門，門把手在右側。',
      '這是一輛汽車，位於畫面中央，是銀色的轎車，車頭朝向右側。',
      '這是一本書，位於畫面中央偏下，封面是藍色的，看起來有一定厚度。',
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
      '這是一個室內客廳場景。前方約2米處有一張沙發，右側約1米處有一扇窗戶，左側有一扇門。中間有約1.5米寬的通道可以通行。地面平整，沒有明顯障礙物。',
      '這是一個走廊場景。前方約3米處有拐角，右側約1米處有椅子，左側牆壁平整。中間有約1.5米寬的通道可以通行。地面平整，【安全提示】前方拐角處請注意。',
      '這是一個室外街道場景。前方約5米處有斑馬線，右側是人行道，左側有樹木。天氣晴朗，光線充足。',
      '這是一個餐廳場景。前方約2米處有餐桌，右側約1.5米處有服務檯，左側是窗戶。中間有約2米寬的通道可以通行。',
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
      text: '您諮詢的是藥品相關問題，藥品使用需要謹慎確認，我將爲您轉接志願者協助覈對藥品信息，請稍候。',
      intent: IntentType.medicineConfirmation,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _medicalResponse() {
    return AIResponse(
      text: '您諮詢的是醫療相關問題，爲了您的健康安全，我將爲您轉接專業醫療志願者，請稍候。',
      intent: IntentType.medicalConsultation,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _emotionalResponse() {
    return AIResponse(
      text: '我理解您可能需要情感支持，讓我爲您轉接心理支持志願者，他們會更好地陪伴您。',
      intent: IntentType.emotionalSupport,
      urgency: UrgencyLevel.important,
      needsHuman: true,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _emergencyResponse(String input) {
    return AIResponse(
      text: '檢測到緊急情況"$input"，正在立即啓動SOS流程！',
      intent: IntentType.emergency,
      urgency: UrgencyLevel.emergency,
      needsHuman: true,
      confidence: 0.98,
      extraData: {'triggerSOS': true, 'mock': true},
    );
  }

  AIResponse _greetingResponse() {
    return AIResponse(
      text: '您好！我是LinkAble智能助手，有什麼可以幫助您的嗎？您可以問我關於文字識別、物體識別、顏色識別、導航等問題。',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _gratitudeResponse() {
    return AIResponse(
      text: '不客氣！很高興能幫到您。如果還有其他問題，隨時告訴我。',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _helpResponse() {
    return AIResponse(
      text: '我可以幫您：1. 識別圖片中的文字並朗讀；2. 識別物體和場景；3. 識別顏色；4. 識別鈔票面額；5. 翻譯外文；6. 提供導航指引；7. 描述周圍環境。請告訴我您需要什麼幫助？',
      intent: IntentType.generalChat,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 1.0,
      extraData: {'mock': true},
    );
  }

  AIResponse _defaultResponse() {
    final defaults = [
      '我理解您的意思。您可以拍照或詳細描述一下，我會盡力幫助您。',
      '明白了，讓我來幫您處理這個問題。',
      '好的，我來幫您看看。',
      '收到，請稍等片刻。',
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

  // ==================== 輔助方法 ====================

  bool _containsEmergencyKeyword(String input) {
    final keywords = [
      '救命', 'help', 'emergency', '救救我', '殺人', '搶劫',
      'fire', '着火了', '心臟病', '中風', '昏迷', '大出血',
    ];
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }
}

/// 顏色預設
class _ColorPreset {
  final String name;
  final String description;
  final String rgbValue;

  _ColorPreset(this.name, this.description, this.rgbValue);
}
