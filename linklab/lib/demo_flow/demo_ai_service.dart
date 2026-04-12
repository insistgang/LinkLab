// 演示版AI服务
// 模拟AI回复，无需真实API调用

import 'dart:math';

/// AI消息类型
enum AIMessageType {
  text,
  image,
  voice,
}

/// AI消息
class AIMessage {
  final String id;
  final String content;
  final AIMessageType type;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  AIMessage({
    required this.id,
    required this.content,
    this.type = AIMessageType.text,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIMessage.loading() => AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        isUser: false,
        isLoading: true,
      );
}

/// 模拟AI回复数据
class DemoAIResponses {
  /// 通用回复模板
  static const List<String> generalResponses = [
    '我理解您的需求，让我帮您分析一下。',
    '这是一个很好的问题，我可以为您提供帮助。',
    '我已经记录下您的需求，正在为您寻找最佳解决方案。',
    '根据您的描述，我建议您可以尝试以下方法。',
    '这个问题我可以帮您解决，请稍等片刻。',
  ];

  /// 医疗相关回复（触发转人工）
  static const List<String> medicalResponses = [
    '您描述的症状需要专业医疗建议，我为您联系志愿者协助。',
    '这涉及健康问题，建议您咨询专业志愿者，正在为您匹配...',
    '医疗相关问题需要谨慎处理，让我为您联系有经验的志愿者。',
  ];

  /// 导航相关回复
  static const List<String> navigationResponses = [
    '您当前位置附近有以下地标：前方50米有便利店，右侧100米有公交站。',
    '根据您的位置，建议您向前直走200米后左转。',
    '我检测到您附近有地铁站，距离约300米。',
  ];

  /// OCR识别结果（模拟）
  static const List<String> ocrResults = [
    '识别结果：这是一盒感冒药，用法是每日三次，每次一片。',
    '识别结果：这是一张超市购物小票，总金额128元。',
    '识别结果：这是一封银行对账单，显示本月余额5000元。',
    '识别结果：这是一个食品包装，保质期至2026年12月。',
    '识别结果：这是一张名片，姓名：张三，电话：138****8888。',
  ];

  /// 场景描述结果（模拟）
  static const List<String> sceneDescriptions = [
    '场景描述：您面前是一张木质桌子，上面放着一杯水和一本书。',
    '场景描述：这是一个客厅环境，有沙发、电视和茶几。',
    '场景描述：您站在一条人行道上，前方是斑马线，左侧有树木。',
    '场景描述：这是一个厨房，可以看到灶台、冰箱和水槽。',
  ];

  /// 颜色识别结果（模拟）
  static const List<String> colorResults = [
    '主要颜色：深蓝色（60%）、白色（30%）、灰色（10%）',
    '主要颜色：红色（45%）、黄色（35%）、黑色（20%）',
    '主要颜色：绿色（50%）、棕色（40%）、米色（10%）',
  ];

  /// 检查是否医疗关键词
  static bool isMedicalQuery(String text) {
    final medicalKeywords = [
      '药', '病', '疼', '痛', '不舒服', '难受', '医院', '医生',
      '感冒', '发烧', '头晕', '恶心', '呕吐', '拉肚子',
    ];
    return medicalKeywords.any((keyword) => text.contains(keyword));
  }

  /// 检查是否导航关键词
  static bool isNavigationQuery(String text) {
    final navKeywords = [
      '路', '方向', '怎么走', '在哪', '附近', '前面', '后面',
      '左边', '右边', '东', '南', '西', '北',
    ];
    return navKeywords.any((keyword) => text.contains(keyword));
  }

  /// 获取随机回复
  static String getRandomResponse(List<String> responses) {
    return responses[Random().nextInt(responses.length)];
  }
}

/// 演示版AI服务
class DemoAIService {
  static final DemoAIService _instance = DemoAIService._internal();
  factory DemoAIService() => _instance;
  DemoAIService._internal();

  final List<AIMessage> _messages = [];
  List<AIMessage> get messages => List.unmodifiable(_messages);

  /// 添加用户消息
  void addUserMessage(String content, {AIMessageType type = AIMessageType.text}) {
    _messages.add(AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      isUser: true,
    ));
  }

  /// 模拟AI回复（带延迟）
  Future<AIMessage> getAIResponse(String userMessage) async {
    // 显示加载状态
    final loadingMessage = AIMessage.loading();
    _messages.add(loadingMessage);

    // 模拟思考延迟
    await Future.delayed(const Duration(seconds: 2));

    // 移除加载消息
    _messages.remove(loadingMessage);

    // 根据内容类型返回不同回复
    String response;
    bool shouldEscalate = false;

    if (DemoAIResponses.isMedicalQuery(userMessage)) {
      response = DemoAIResponses.getRandomResponse(
        DemoAIResponses.medicalResponses,
      );
      shouldEscalate = true;
    } else if (DemoAIResponses.isNavigationQuery(userMessage)) {
      response = DemoAIResponses.getRandomResponse(
        DemoAIResponses.navigationResponses,
      );
    } else {
      response = DemoAIResponses.getRandomResponse(
        DemoAIResponses.generalResponses,
      );
    }

    final aiMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      isUser: false,
    );

    _messages.add(aiMessage);

    // 如果是医疗问题，延迟后自动转人工
    if (shouldEscalate) {
      await Future.delayed(const Duration(seconds: 2));
      final escalateMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '正在为您匹配医疗志愿者，请稍候...',
        isUser: false,
      );
      _messages.add(escalateMessage);
    }

    return aiMessage;
  }

  /// 模拟OCR识别
  Future<AIMessage> recognizeImage() async {
    final loadingMessage = AIMessage.loading();
    _messages.add(loadingMessage);

    await Future.delayed(const Duration(seconds: 2));

    _messages.remove(loadingMessage);

    final response = DemoAIResponses.getRandomResponse(
      DemoAIResponses.ocrResults,
    );

    final aiMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: AIMessageType.image,
      isUser: false,
    );

    _messages.add(aiMessage);
    return aiMessage;
  }

  /// 模拟场景描述
  Future<AIMessage> describeScene() async {
    final loadingMessage = AIMessage.loading();
    _messages.add(loadingMessage);

    await Future.delayed(const Duration(seconds: 2));

    _messages.remove(loadingMessage);

    final response = DemoAIResponses.getRandomResponse(
      DemoAIResponses.sceneDescriptions,
    );

    final aiMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: AIMessageType.image,
      isUser: false,
    );

    _messages.add(aiMessage);
    return aiMessage;
  }

  /// 模拟颜色识别
  Future<AIMessage> recognizeColor() async {
    final loadingMessage = AIMessage.loading();
    _messages.add(loadingMessage);

    await Future.delayed(const Duration(seconds: 1));

    _messages.remove(loadingMessage);

    final response = DemoAIResponses.getRandomResponse(
      DemoAIResponses.colorResults,
    );

    final aiMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: AIMessageType.image,
      isUser: false,
    );

    _messages.add(aiMessage);
    return aiMessage;
  }

  /// 清空消息
  void clearMessages() {
    _messages.clear();
  }

  /// 获取最后一条消息
  AIMessage? get lastMessage => _messages.isEmpty ? null : _messages.last;

  /// 检查是否需要转人工
  bool shouldEscalateToHuman() {
    if (_messages.isEmpty) return false;
    final lastMsg = _messages.last;
    if (lastMsg.isUser) return false;
    return DemoAIResponses.isMedicalQuery(lastMsg.content);
  }
}
