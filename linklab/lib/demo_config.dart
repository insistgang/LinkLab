/// 演示模式配置文件
/// 用于控制演示版的行为和数据

/// 演示场景模型
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
    if (index < 0 || index >= steps.length) return '步骤结束';
    return steps[index];
  }
}

class DemoConfig {
  /// 是否演示模式
  static bool isDemoMode = true;

  /// 模拟延迟时间（秒）
  static int mockDelaySeconds = 2;

  /// 模拟延迟时间（毫秒）- 用于更精细的控制
  static int get mockDelayMs => mockDelaySeconds * 1000;

  /// AI思考延迟范围（毫秒）
  static int aiMinDelayMs = 800;
  static int aiMaxDelayMs = 2000;

  /// 匹配等待时间（秒）
  static int matchingWaitSeconds = 4;

  /// 通话自动结束时间（秒）
  static int callAutoEndSeconds = 30;

  /// SOS响应时间（秒）
  static int sosResponseSeconds = 5;

  /// 是否启用自动流程
  static bool autoFlowEnabled = true;

  /// 是否显示演示模式指示器
  static bool showDemoIndicator = true;

  /// 演示场景列表
  static final List<DemoScenario> scenarios = [
    DemoScenario(
      id: 'ocr_medicine',
      name: '药品识别',
      description: '拍照识别药品说明书，AI建议转人工确认',
      icon: 'medication',
      requiresMatching: true,
      steps: [
        '用户点击"文字识别"',
        '拍照药品包装',
        'AI识别并朗读："阿莫西林胶囊，每粒0.25克，成人每次2粒..."',
        'AI建议："这是药品，建议志愿者确认用法"',
        '用户点击"连接志愿者"',
        '进入匹配等待页面',
        '匹配成功：志愿者"热心小李"',
        '进入模拟通话页面',
        '通话中（志愿者确认药品用法）',
        '通话结束',
        '进入评价页面',
        '用户提交5星评价',
        '返回首页',
      ],
    ),
    DemoScenario(
      id: 'ocr_menu',
      name: '菜单识别',
      description: '识别餐厅菜单，AI直接读出菜品',
      icon: 'restaurant_menu',
      requiresMatching: false,
      steps: [
        '用户说"帮我读菜单"',
        'AI响应："好的，请拍照菜单"',
        '用户拍照菜单',
        'AI识别："今日特推：红烧肉38元，清蒸鲈鱼58元，麻婆豆腐22元..."',
        '用户满意，结束对话',
      ],
    ),
    DemoScenario(
      id: 'scene_navigation',
      name: '场景描述',
      description: '描述周围环境辅助导航',
      icon: 'camera_alt',
      requiresMatching: false,
      steps: [
        '用户说"前方有什么"',
        'AI响应："请拍照，我帮您描述"',
        '用户拍照前方',
        'AI描述："前方3米有一张沙发，右侧1米有一扇门，地面平整..."',
        '用户满意，结束对话',
      ],
    ),
    DemoScenario(
      id: 'color_recognition',
      name: '颜色识别',
      description: '识别物体颜色',
      icon: 'color_lens',
      requiresMatching: false,
      steps: [
        '用户说"这件衣服什么颜色"',
        'AI响应："请拍照，我帮您识别"',
        '用户拍照衣物',
        'AI识别："这是深蓝色，类似于海军蓝，沉稳大气"',
        '用户满意，结束对话',
      ],
    ),
    DemoScenario(
      id: 'sos_emergency',
      name: 'SOS紧急求助',
      description: '紧急情况下快速求助',
      icon: 'emergency',
      isEmergency: true,
      requiresMatching: true,
      steps: [
        '用户长按SOS按钮3秒',
        '显示确认对话框',
        '用户确认求助',
        '进入SOS页面（全屏红色+倒计时）',
        '显示"正在发送位置给紧急联系人"',
        '显示"正在广播匹配附近志愿者"',
        '匹配成功：志愿者"热心小李"',
        '进入模拟通话页面',
        '志愿者接听："您好，我是志愿者小李，请问需要什么帮助？"',
        '通话结束',
        '进入评价页面',
        '用户提交评价',
        '返回首页',
      ],
    ),
  ];

  /// 默认演示场景
  static DemoScenario get defaultScenario => scenarios.first;

  /// 获取指定场景
  static DemoScenario? getScenario(String id) {
    try {
      return scenarios.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 是否启用语音播报
  static bool enableVoiceFeedback = true;

  /// 是否启用震动反馈
  static bool enableHapticFeedback = true;

  /// 匹配超时时间（秒）
  static int matchingTimeoutSeconds = 5;

  /// 模拟通话时长（秒）
  static int mockCallDurationSeconds = 15;

  /// SOS倒计时时间（秒）
  static int sosCountdownSeconds = 5;

  /// 是否显示调试信息
  static bool showDebugInfo = false;

  /// 志愿者等级配置
  static Map<String, Map<String, String>> volunteerLevels = {
    '灯塔': {
      'badge': '🏠',
      'description': '资深志愿者，帮助超过100次',
    },
    '星辰': {
      'badge': '⭐',
      'description': '专业志愿者，具备专业技能',
    },
    '暖阳': {
      'badge': '☀️',
      'description': '热心志愿者，深受用户好评',
    },
    '微光': {
      'badge': '✨',
      'description': '新晋志愿者，充满热情',
    },
    '烛光': {
      'badge': '🕯️',
      'description': '稳定志愿者，长期服务',
    },
  };

  /// AI回复类型
  static Map<String, String> aiResponseTypes = {
    'ocr': '文字识别',
    'scene': '场景描述',
    'color': '颜色识别',
    'chat': '智能对话',
    'emergency': '紧急检测',
  };

  /// 获取场景标题
  static String getScenarioTitle(String scenarioId) {
    final scenario = getScenario(scenarioId);
    return scenario?.name ?? '未知场景';
  }

  /// 获取场景描述
  static String getScenarioDescription(String scenarioId) {
    final scenario = getScenario(scenarioId);
    return scenario?.description ?? '';
  }

  /// 演示志愿者信息
  static final Map<String, dynamic> demoVolunteer = {
    'id': 'volunteer_001',
    'name': '李晓明',
    'nickname': '热心小李',
    'avatar': 'assets/images/avatars/volunteer_1.png',
    'level': 5,
    'levelName': '资深志愿者',
    'rating': 4.9,
    'helpCount': 328,
    'skills': ['药品识别', '导航辅助', '日常协助'],
    'bio': '退休药剂师，擅长药品识别和健康咨询',
    'responseTime': '平均15秒响应',
  };

  /// 演示用户档案
  static final Map<String, dynamic> demoUser = {
    'id': 'user_demo_001',
    'name': '张阿姨',
    'phone': '138****8888',
    'role': 'seeker',
    'disabilityType': 'visual',
    'preferences': {
      'fontScale': 1.2,
      'voiceSpeed': 1.0,
      'highContrast': false,
    },
  };

  /// 演示数据版本
  static const String demoDataVersion = '1.0.0';

  /// 切换演示模式
  static void setDemoMode(bool value) {
    isDemoMode = value;
  }

  /// 设置模拟延迟
  static void setMockDelay(int seconds) {
    mockDelaySeconds = seconds;
  }

  /// 重置为默认配置
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

/// 演示步骤状态
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
    if (_currentScenario == null) return '未开始';
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
  static const String welcome = '欢迎使用共感LinkAble演示模式';
  static const String selectScenario = '请选择一个演示场景开始';
  static const String tapToContinue = '点击屏幕继续下一步';
  static const String longPressSOS = '长按SOS按钮3秒触发紧急求助';
  static const String swipeToNavigate = '左右滑动切换页面';
  static const String doubleTapToActivate = '双击按钮激活功能';

  static String getScenarioHint(String scenarioId) {
    switch (scenarioId) {
      case 'ocr_medicine':
        return '演示药品识别流程：拍照 → AI识别 → 转人工 → 通话';
      case 'ocr_menu':
        return '演示菜单识别：语音输入 → 拍照 → AI朗读';
      case 'scene_navigation':
        return '演示场景描述：拍照 → AI描述周围环境';
      case 'color_recognition':
        return '演示颜色识别：拍照 → AI识别颜色';
      case 'sos_emergency':
        return '演示SOS紧急求助：长按 → 确认 → 广播 → 通话';
      default:
        return '点击开始演示';
    }
  }
}

/// 演示模式下的全局配置访问
class DemoMode {
  static DemoConfig get config => DemoConfig();
  static DemoFlowController get flow => DemoFlowController();
}
