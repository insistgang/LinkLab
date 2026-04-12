/// 演示场景数据
/// 用于演示版的5个核心场景

class DemoScenario {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<DemoStep> steps;

  const DemoScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.steps,
  });
}

class DemoStep {
  final int stepNumber;
  final String screen;
  final String action;
  final String? userInput;
  final String? aiResponse;
  final String? volunteerAction;
  final int delayMs;

  const DemoStep({
    required this.stepNumber,
    required this.screen,
    required this.action,
    this.userInput,
    this.aiResponse,
    this.volunteerAction,
    this.delayMs = 1500,
  });
}

/// 场景1：药品识别 → 转人工 → 匹配 → 通话
const scenarioMedicine = DemoScenario(
  id: 'scenario_001',
  title: '药品识别求助',
  category: 'OCR识别',
  description: '用户拍摄药品，AI识别后建议转人工确认',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '点击大按钮"语音求助"',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'ai_chat',
      action: '进入AI对话界面',
      aiResponse: '您好！我是您的智能助手，有什么可以帮助您的吗？',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_chat',
      action: '用户语音输入',
      userInput: '帮我看一下这个药怎么吃',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'ai_chat',
      action: 'AI识别药品并回复',
      aiResponse: '识别结果：阿司匹林肠溶片 100mg\n\n用法用量：\n• 每日一次，每次1片\n• 饭后服用\n\n⚠️ 这是药品，建议志愿者确认',
      delayMs: 2500,
    ),
    DemoStep(
      stepNumber: 5,
      screen: 'ai_chat',
      action: '用户请求人工确认',
      userInput: '我想让志愿者帮我确认一下',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 6,
      screen: 'matching',
      action: '进入匹配页面，显示匹配动画',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 7,
      screen: 'call',
      action: '匹配成功，进入通话',
      volunteerAction: '小李：您好，我是小李，让我帮您确认这个药品',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 8,
      screen: 'call',
      action: '志愿者确认药品信息',
      volunteerAction: '小李：是的，这是阿司匹林，每天一片饭后吃。您有什么不舒服吗？',
      delayMs: 5000,
    ),
    DemoStep(
      stepNumber: 9,
      screen: 'rating',
      action: '通话结束，进入评价页面',
      delayMs: 2000,
    ),
  ],
);

/// 场景2：菜单识别 → AI直接回答
const scenarioMenu = DemoScenario(
  id: 'scenario_002',
  title: '菜单识别',
  category: 'OCR识别',
  description: '用户拍摄餐厅菜单，AI直接读出菜品和价格',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '点击"文字识别"按钮',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍摄菜单照片',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI识别并朗读',
      aiResponse: '识别结果：\n\n宫保鸡丁 38元\n鱼香肉丝 32元\n麻婆豆腐 28元\n清蒸鲈鱼 58元',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用户满意，返回首页',
      delayMs: 1000,
    ),
  ],
);

/// 场景3：场景描述 → AI直接回答
const scenarioScene = DemoScenario(
  id: 'scenario_003',
  title: '场景描述',
  category: '视觉辅助',
  description: '用户拍摄周围环境，AI描述场景帮助导航',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '点击"场景描述"按钮',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍摄周围环境',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI描述场景',
      aiResponse: '场景描述：\n\n前方2米有一张木桌\n右侧1米有一扇门\n桌上有水杯（注意避让）\n地面平整，可以直行',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用户了解环境，返回首页',
      delayMs: 1000,
    ),
  ],
);

/// 场景4：颜色识别 → AI直接回答
const scenarioColor = DemoScenario(
  id: 'scenario_004',
  title: '颜色识别',
  category: '视觉辅助',
  description: '用户拍摄衣服，AI识别颜色并给出搭配建议',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '点击"颜色识别"按钮',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍摄衣服',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI识别颜色',
      aiResponse: '这件衣服是深蓝色\n\n相近颜色：\n• 藏青色\n• 海军蓝\n• 午夜蓝\n\n搭配建议：\n适合搭配白色或浅灰色裤子',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用户满意，返回首页',
      delayMs: 1000,
    ),
  ],
);

/// 场景5：SOS紧急 → SOS页面 → 匹配 → 通话
const scenarioSOS = DemoScenario(
  id: 'scenario_005',
  title: 'SOS紧急求助',
  category: '紧急求助',
  description: '用户触发SOS，快速匹配志愿者并建立通话',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '用户连按电源键3次触发SOS',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'sos',
      action: '进入SOS紧急页面，显示倒计时',
      aiResponse: '⚠️ 紧急模式启动\n\n正在联系志愿者和紧急联系人...',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'sos',
      action: '倒计时期间显示取消按钮',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'matching',
      action: '进入紧急匹配，优先匹配最近志愿者',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 5,
      screen: 'call',
      action: '快速匹配成功，进入通话',
      volunteerAction: '张医生：您好，我是张医生，收到您的紧急求助。您现在安全吗？需要什么帮助？',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 6,
      screen: 'call',
      action: '志愿者提供紧急指导',
      volunteerAction: '张医生：请不要慌张，告诉我您的具体位置，我帮您联系救援。',
      delayMs: 5000,
    ),
    DemoStep(
      stepNumber: 7,
      screen: 'rating',
      action: '通话结束，进入评价',
      delayMs: 2000,
    ),
  ],
);

/// 所有演示场景
final List<DemoScenario> allDemoScenarios = [
  scenarioMedicine,
  scenarioMenu,
  scenarioScene,
  scenarioColor,
  scenarioSOS,
];

/// 根据ID获取场景
DemoScenario? getScenarioById(String id) {
  try {
    return allDemoScenarios.firstWhere((s) => s.id == id);
  } catch (e) {
    return null;
  }
}

/// 演示流程总览
const demoFlowOverview = '''
共感 LinkAble 演示流程

【场景1】药品识别 → 转人工 → 匹配 → 通话
展示：OCR识别 + 人工确认流程

【场景2】菜单识别 → AI直接回答
展示：OCR快速识别能力

【场景3】场景描述 → AI直接回答
展示：视觉理解能力

【场景4】颜色识别 → AI直接回答
展示：颜色识别和搭配建议

【场景5】SOS紧急 → SOS页面 → 匹配 → 通话
展示：紧急求助快速响应
''';
