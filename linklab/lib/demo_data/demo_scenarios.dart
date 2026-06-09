/// 演示場景數據
/// 用於演示版的5個核心場景
library;

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

/// 場景1：藥品識別 → 轉人工 → 匹配 → 通話
const scenarioMedicine = DemoScenario(
  id: 'scenario_001',
  title: '藥品識別求助',
  category: 'OCR識別',
  description: '用戶拍攝藥品，AI識別後建議轉人工確認',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '點擊大按鈕"語音求助"',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'ai_chat',
      action: '進入AI對話界面',
      aiResponse: '您好！我是您的智能助手，有什麼可以幫助您的嗎？',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_chat',
      action: '用戶語音輸入',
      userInput: '幫我看一下這個藥怎麼喫',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'ai_chat',
      action: 'AI識別藥品並回復',
      aiResponse: '識別結果：阿司匹林腸溶片 100mg\n\n用法用量：\n• 每日一次，每次1片\n• 飯後服用\n\n⚠️ 這是藥品，建議志願者確認',
      delayMs: 2500,
    ),
    DemoStep(
      stepNumber: 5,
      screen: 'ai_chat',
      action: '用戶請求人工確認',
      userInput: '我想讓志願者幫我確認一下',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 6,
      screen: 'matching',
      action: '進入匹配頁面，顯示匹配動畫',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 7,
      screen: 'call',
      action: '匹配成功，進入通話',
      volunteerAction: '小李：您好，我是小李，讓我幫您確認這個藥品',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 8,
      screen: 'call',
      action: '志願者確認藥品信息',
      volunteerAction: '小李：是的，這是阿司匹林，每天一片飯後喫。您有什麼不舒服嗎？',
      delayMs: 5000,
    ),
    DemoStep(
      stepNumber: 9,
      screen: 'rating',
      action: '通話結束，進入評價頁面',
      delayMs: 2000,
    ),
  ],
);

/// 場景2：菜單識別 → AI直接回答
const scenarioMenu = DemoScenario(
  id: 'scenario_002',
  title: '菜單識別',
  category: 'OCR識別',
  description: '用戶拍攝餐廳菜單，AI直接讀出菜品和價格',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '點擊"文字識別"按鈕',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍攝菜單照片',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI識別並朗讀',
      aiResponse: '識別結果：\n\n宮保雞丁 38元\n魚香肉絲 32元\n麻婆豆腐 28元\n清蒸鱸魚 58元',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用戶滿意，返回首頁',
      delayMs: 1000,
    ),
  ],
);

/// 場景3：場景描述 → AI直接回答
const scenarioScene = DemoScenario(
  id: 'scenario_003',
  title: '場景描述',
  category: '視覺輔助',
  description: '用戶拍攝周圍環境，AI描述場景幫助導航',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '點擊"場景描述"按鈕',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍攝周圍環境',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI描述場景',
      aiResponse: '場景描述：\n\n前方2米有一張木桌\n右側1米有一扇門\n桌上有水杯（注意避讓）\n地面平整，可以直行',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用戶瞭解環境，返回首頁',
      delayMs: 1000,
    ),
  ],
);

/// 場景4：顏色識別 → AI直接回答
const scenarioColor = DemoScenario(
  id: 'scenario_004',
  title: '顏色識別',
  category: '視覺輔助',
  description: '用戶拍攝衣服，AI識別顏色並給出搭配建議',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '點擊"顏色識別"按鈕',
      delayMs: 1000,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'camera',
      action: '拍攝衣服',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'ai_result',
      action: 'AI識別顏色',
      aiResponse: '這件衣服是深藍色\n\n相近顏色：\n• 藏青色\n• 海軍藍\n• 午夜藍\n\n搭配建議：\n適合搭配白色或淺灰色褲子',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'home',
      action: '用戶滿意，返回首頁',
      delayMs: 1000,
    ),
  ],
);

/// 場景5：SOS緊急 → SOS頁面 → 匹配 → 通話
const scenarioSOS = DemoScenario(
  id: 'scenario_005',
  title: 'SOS緊急求助',
  category: '緊急求助',
  description: '用戶觸發SOS，快速匹配志願者並建立通話',
  steps: [
    DemoStep(
      stepNumber: 1,
      screen: 'home',
      action: '用戶連按電源鍵3次觸發SOS',
      delayMs: 1500,
    ),
    DemoStep(
      stepNumber: 2,
      screen: 'sos',
      action: '進入SOS緊急頁面，顯示倒計時',
      aiResponse: '⚠️ 緊急模式啓動\n\n正在聯繫志願者和緊急聯繫人...',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 3,
      screen: 'sos',
      action: '倒計時期間顯示取消按鈕',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 4,
      screen: 'matching',
      action: '進入緊急匹配，優先匹配最近志願者',
      delayMs: 2000,
    ),
    DemoStep(
      stepNumber: 5,
      screen: 'call',
      action: '快速匹配成功，進入通話',
      volunteerAction: '張醫生：您好，我是張醫生，收到您的緊急求助。您現在安全嗎？需要什麼幫助？',
      delayMs: 3000,
    ),
    DemoStep(
      stepNumber: 6,
      screen: 'call',
      action: '志願者提供緊急指導',
      volunteerAction: '張醫生：請不要慌張，告訴我您的具體位置，我幫您聯繫救援。',
      delayMs: 5000,
    ),
    DemoStep(
      stepNumber: 7,
      screen: 'rating',
      action: '通話結束，進入評價',
      delayMs: 2000,
    ),
  ],
);

/// 所有演示場景
final List<DemoScenario> allDemoScenarios = [
  scenarioMedicine,
  scenarioMenu,
  scenarioScene,
  scenarioColor,
  scenarioSOS,
];

/// 根據ID獲取場景
DemoScenario? getScenarioById(String id) {
  try {
    return allDemoScenarios.firstWhere((s) => s.id == id);
  } catch (e) {
    return null;
  }
}

/// 演示流程總覽
const demoFlowOverview = '''
共感 LinkAble 演示流程

【場景1】藥品識別 → 轉人工 → 匹配 → 通話
展示：OCR識別 + 人工確認流程

【場景2】菜單識別 → AI直接回答
展示：OCR快速識別能力

【場景3】場景描述 → AI直接回答
展示：視覺理解能力

【場景4】顏色識別 → AI直接回答
展示：顏色識別和搭配建議

【場景5】SOS緊急 → SOS頁面 → 匹配 → 通話
展示：緊急求助快速響應
''';
