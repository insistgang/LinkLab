/// 演示模式配置文件
/// 用於控制演示版的行爲和數據
library;

/// 演示場景模型
class DemoScenario {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> steps;
  final bool requiresMatching;
  final bool isEmergency;

  const DemoScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.steps,
    this.requiresMatching = false,
    this.isEmergency = false,
  });

  int get stepCount => steps.length;

  String getStep(int index) {
    if (index < 0 || index >= steps.length) return '步驟結束';
    return steps[index];
  }
}

class DemoConfig {
  /// 是否演示模式
  static bool isDemoMode = true;

  /// 模擬延遲時間（秒）
  static int mockDelaySeconds = 2;

  /// 模擬延遲時間（毫秒）- 用於更精細的控制
  static int get mockDelayMs => mockDelaySeconds * 1000;

  /// AI思考延遲範圍（毫秒）
  static int aiMinDelayMs = 800;
  static int aiMaxDelayMs = 2000;

  /// 匹配等待時間（秒）
  static int matchingWaitSeconds = 4;

  /// 通話自動結束時間（秒）
  static int callAutoEndSeconds = 30;

  /// SOS響應時間（秒）
  static int sosResponseSeconds = 5;

  /// 是否啓用自動流程
  static bool autoFlowEnabled = true;

  /// 是否顯示演示模式指示器
  static bool showDemoIndicator = true;

  /// 演示場景列表
  static final List<DemoScenario> scenarios = [
    const DemoScenario(
      id: 'ocr_medicine',
      name: '藥品識別',
      description: '拍照識別藥品說明書，AI建議轉人工確認',
      icon: 'medication',
      requiresMatching: true,
      steps: [
        '用戶點擊"文字識別"',
        '拍照藥品包裝',
        'AI識別並朗讀："阿莫西林膠囊，每粒0.25克，成人每次2粒..."',
        'AI建議："這是藥品，建議志願者確認用法"',
        '用戶點擊"連接志願者"',
        '進入匹配等待頁面',
        '匹配成功：志願者"熱心小李"',
        '進入模擬通話頁面',
        '通話中（志願者確認藥品用法）',
        '通話結束',
        '進入評價頁面',
        '用戶提交5星評價',
        '返回首頁',
      ],
    ),
    const DemoScenario(
      id: 'ocr_menu',
      name: '菜單識別',
      description: '識別餐廳菜單，AI直接讀出菜品',
      icon: 'restaurant_menu',
      requiresMatching: false,
      steps: [
        '用戶說"幫我讀菜單"',
        'AI響應："好的，請拍照菜單"',
        '用戶拍照菜單',
        'AI識別："今日特推：紅燒肉38元，清蒸鱸魚58元，麻婆豆腐22元..."',
        '用戶滿意，結束對話',
      ],
    ),
    const DemoScenario(
      id: 'scene_navigation',
      name: '場景描述',
      description: '描述周圍環境輔助導航',
      icon: 'camera_alt',
      requiresMatching: false,
      steps: [
        '用戶說"前方有什麼"',
        'AI響應："請拍照，我幫您描述"',
        '用戶拍照前方',
        'AI描述："前方3米有一張沙發，右側1米有一扇門，地面平整..."',
        '用戶滿意，結束對話',
      ],
    ),
    const DemoScenario(
      id: 'color_recognition',
      name: '顏色識別',
      description: '識別物體顏色',
      icon: 'color_lens',
      requiresMatching: false,
      steps: [
        '用戶說"這件衣服什麼顏色"',
        'AI響應："請拍照，我幫您識別"',
        '用戶拍照衣物',
        'AI識別："這是深藍色，類似於海軍藍，沉穩大氣"',
        '用戶滿意，結束對話',
      ],
    ),
    const DemoScenario(
      id: 'sos_emergency',
      name: 'SOS緊急求助',
      description: '緊急情況下快速求助',
      icon: 'emergency',
      isEmergency: true,
      requiresMatching: true,
      steps: [
        '用戶長按SOS按鈕3秒',
        '顯示確認對話框',
        '用戶確認求助',
        '進入SOS頁面（全屏紅色+倒計時）',
        '顯示"正在發送位置給緊急聯繫人"',
        '顯示"正在廣播匹配附近志願者"',
        '匹配成功：志願者"熱心小李"',
        '進入模擬通話頁面',
        '志願者接聽："您好，我是志願者小李，請問需要什麼幫助？"',
        '通話結束',
        '進入評價頁面',
        '用戶提交評價',
        '返回首頁',
      ],
    ),
  ];

  /// 默認演示場景
  static DemoScenario get defaultScenario => scenarios.first;

  /// 獲取指定場景
  static DemoScenario? getScenario(String id) {
    try {
      return scenarios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 是否啓用語音播報
  static bool enableVoiceFeedback = true;

  /// 是否啓用震動反饋
  static bool enableHapticFeedback = true;

  /// 匹配超時時間（秒）
  static int matchingTimeoutSeconds = 5;

  /// 模擬通話時長（秒）
  static int mockCallDurationSeconds = 15;

  /// SOS倒計時時間（秒）
  static int sosCountdownSeconds = 5;

  /// 是否顯示調試信息
  static bool showDebugInfo = false;

  /// 志願者等級配置
  static Map<String, Map<String, String>> volunteerLevels = {
    '燈塔': {
      'badge': '🏠',
      'description': '資深志願者，幫助超過100次',
    },
    '星辰': {
      'badge': '⭐',
      'description': '專業志願者，具備專業技能',
    },
    '暖陽': {
      'badge': '☀️',
      'description': '熱心志願者，深受用戶好評',
    },
    '微光': {
      'badge': '✨',
      'description': '新晉志願者，充滿熱情',
    },
    '燭光': {
      'badge': '🕯️',
      'description': '穩定志願者，長期服務',
    },
  };

  /// AI回覆類型
  static Map<String, String> aiResponseTypes = {
    'ocr': '文字識別',
    'scene': '場景描述',
    'color': '顏色識別',
    'chat': '智能對話',
    'emergency': '緊急檢測',
  };

  /// 獲取場景標題
  static String getScenarioTitle(String scenarioId) {
    final scenario = getScenario(scenarioId);
    return scenario?.name ?? '未知場景';
  }

  /// 獲取場景描述
  static String getScenarioDescription(String scenarioId) {
    final scenario = getScenario(scenarioId);
    return scenario?.description ?? '';
  }

  /// 演示志願者信息
  static final Map<String, dynamic> demoVolunteer = {
    'id': 'volunteer_001',
    'name': '李曉明',
    'nickname': '熱心小李',
    'avatar': '',
    'level': 5,
    'levelName': '資深志願者',
    'rating': 4.9,
    'helpCount': 328,
    'skills': ['藥品識別', '導航輔助', '日常協助'],
    'bio': '退休藥劑師，擅長藥品識別和健康諮詢',
    'responseTime': '平均15秒響應',
  };

  /// 演示用戶檔案
  static final Map<String, dynamic> demoUser = {
    'id': 'user_demo_001',
    'name': '張阿姨',
    'phone': '138****8888',
    'role': 'seeker',
    'disabilityType': 'visual',
    'preferences': {
      'fontScale': 1.2,
      'voiceSpeed': 1.0,
      'highContrast': false,
    },
  };

  /// 演示數據版本
  static const String demoDataVersion = '1.0.0';

  /// 切換演示模式
  static void setDemoMode(bool value) {
    isDemoMode = value;
  }

  /// 設置模擬延遲
  static void setMockDelay(int seconds) {
    mockDelaySeconds = seconds;
  }

  /// 重置爲默認配置
  static void resetToDefaults() {
    isDemoMode = true;
    mockDelaySeconds = 2;
    enableVoiceFeedback = true;
    enableHapticFeedback = true;
    matchingTimeoutSeconds = 5;
    mockCallDurationSeconds = 15;
    sosCountdownSeconds = 5;
    showDebugInfo = false;
    autoFlowEnabled = true;
    showDemoIndicator = true;
  }
}

/// 演示步驟狀態
enum DemoStepStatus {
  pending,
  current,
  completed,
  skipped,
}

/// 演示流程控制器
class DemoFlowController {
  static final DemoFlowController _instance = DemoFlowController._internal();
  factory DemoFlowController() => _instance;
  DemoFlowController._internal();

  DemoScenario? _currentScenario;
  int _currentStepIndex = 0;
  final List<DemoStepStatus> _stepStatuses = [];

  DemoScenario? get currentScenario => _currentScenario;
  int get currentStepIndex => _currentStepIndex;
  bool get isActive => _currentScenario != null;

  void startScenario(String scenarioId) {
    final scenario = DemoConfig.getScenario(scenarioId);
    if (scenario == null) return;

    _currentScenario = scenario;
    _currentStepIndex = 0;
    _stepStatuses.clear();
    _stepStatuses.addAll(
      List.generate(scenario.stepCount, (_) => DemoStepStatus.pending),
    );
    _stepStatuses[0] = DemoStepStatus.current;
  }

  void nextStep() {
    if (_currentScenario == null) return;

    if (_currentStepIndex < _stepStatuses.length) {
      _stepStatuses[_currentStepIndex] = DemoStepStatus.completed;
    }

    _currentStepIndex++;
    if (_currentStepIndex < _stepStatuses.length) {
      _stepStatuses[_currentStepIndex] = DemoStepStatus.current;
    }
  }

  void skipStep() {
    if (_currentScenario == null) return;
    if (_currentStepIndex < _stepStatuses.length) {
      _stepStatuses[_currentStepIndex] = DemoStepStatus.skipped;
      nextStep();
    }
  }

  String get currentStepText {
    if (_currentScenario == null) return '未開始';
    return _currentScenario!.getStep(_currentStepIndex);
  }

  DemoStepStatus getStepStatus(int index) {
    if (index < 0 || index >= _stepStatuses.length) {
      return DemoStepStatus.pending;
    }
    return _stepStatuses[index];
  }

  bool get isCompleted {
    if (_currentScenario == null) return false;
    return _currentStepIndex >= _stepStatuses.length;
  }

  void reset() {
    _currentScenario = null;
    _currentStepIndex = 0;
    _stepStatuses.clear();
  }

  double get progress {
    if (_currentScenario == null || _currentScenario!.stepCount == 0) {
      return 0.0;
    }
    return (_currentStepIndex + 1) / _currentScenario!.stepCount;
  }
}

/// 演示提示信息
class DemoHints {
  static const String welcome = '歡迎使用共感LinkAble演示模式';
  static const String selectScenario = '請選擇一個演示場景開始';
  static const String tapToContinue = '點擊屏幕繼續下一步';
  static const String longPressSOS = '長按SOS按鈕3秒觸發緊急求助';
  static const String swipeToNavigate = '左右滑動切換頁面';
  static const String doubleTapToActivate = '雙擊按鈕激活功能';

  static String getScenarioHint(String scenarioId) {
    switch (scenarioId) {
      case 'ocr_medicine':
        return '演示藥品識別流程：拍照 → AI識別 → 轉人工 → 通話';
      case 'ocr_menu':
        return '演示菜單識別：語音輸入 → 拍照 → AI朗讀';
      case 'scene_navigation':
        return '演示場景描述：拍照 → AI描述周圍環境';
      case 'color_recognition':
        return '演示顏色識別：拍照 → AI識別顏色';
      case 'sos_emergency':
        return '演示SOS緊急求助：長按 → 確認 → 廣播 → 通話';
      default:
        return '點擊開始演示';
    }
  }
}

/// 演示模式下的全局配置訪問
class DemoMode {
  static DemoConfig get config => DemoConfig();
  static DemoFlowController get flow => DemoFlowController();
}
