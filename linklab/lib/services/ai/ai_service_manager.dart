// AGENTS.md §4.2：竞赛版已冻结 Demo 主线。
// 默认 AI 管理器只走本地 mock / fallback；真实 AI 管理器已隔离到 services/experimental/real/ai/。

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/logger.dart';
import 'ai_service.dart';
import 'smart_dialog_service.dart';
import 'ocr_service.dart';
import 'scene_description_service.dart';
import 'color_recognition_service.dart';
import 'emergency_detector.dart';
import 'intent_classifier.dart';
import 'dialog_manager.dart';
import 'camera_service.dart';
import 'voice_service.dart';
import 'mock_ai_service.dart';

/// AI服务管理器
/// 统一管理和调度所有AI服务
class AIServiceManager {
  static AIServiceManager? _instance;
  static AIServiceManager get instance => _instance ??= AIServiceManager._();

  AIServiceManager._();

  // 配置
  AIServiceConfig _config = const AIServiceConfig();

  // 服务实例
  late final SmartDialogService _smartDialogService;
  late final OcrService _ocrService;
  late final SceneDescriptionService _sceneDescriptionService;
  late final ColorRecognitionService _colorRecognitionService;
  late final EmergencyDetectionService _emergencyService;
  late final DialogContextManager _dialogManager;
  late final CameraService _cameraService;
  late final VoiceService _voiceService;

  // 演示模式：使用模拟服务
  late final MockAIService _mockService;

  /// 竞赛版默认只允许本地 mock fallback。
  bool get _useMockMode => true;

  // 状态
  bool _isInitialized = false;
  bool _isOnline = true;

  // 流控制器
  final _responseController = StreamController<AIResponse>.broadcast();
  Stream<AIResponse> get responseStream => _responseController.stream;

  /// 初始化
  Future<void> initialize(AIServiceConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // 初始化各服务
    _smartDialogService = SmartDialogService(config: config);
    _ocrService = OcrService(config: config);
    _sceneDescriptionService = SceneDescriptionService(config: config);
    _colorRecognitionService = ColorRecognitionService();
    _emergencyService = EmergencyDetectionService();
    _dialogManager = DialogContextManager();
    _cameraService = CameraService();
    _voiceService = VoiceService();

    // 初始化模拟服务（演示模式）
    _mockService = MockAIService(simulateDelay: true);

    // 初始化语音服务
    await _voiceService.initialize();

    // 监听网络状态
    Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
    });

    _isInitialized = true;
  }

  /// 处理用户请求（统一入口）
  /// 演示模式：使用模拟数据，不调用真实API
  Future<AIResponse> processRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      return AIResponse.error('AI服务未初始化');
    }

    try {
      // AGENTS.md §4.2：竞赛版默认 AI 主线只走本地 mock fallback。
      // 如需验证真实 AI，请显式使用 services/experimental/real/ai/real_ai_service_manager.dart。
      return await _processMockRequest(
        input: input,
        imageUrl: imageUrl,
        sessionId: sessionId,
      );
    } catch (e) {
      final errorResponse = AIResponse.error('处理请求失败: $e');
      _responseController.add(errorResponse);
      return errorResponse;
    }
  }

  /// 模拟模式处理
  Future<AIResponse> _processMockRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 首先检测紧急关键词（本地检测，不走网络）
    final emergencyResult = _emergencyService.detector.detect(input);
    if (emergencyResult.isEmergency &&
        emergencyResult.level == UrgencyLevel.emergency) {
      final response = await _emergencyService.process(input);
      await _voiceService.speak(response.text);
      _responseController.add(response);
      return response;
    }

    // 2. 使用模拟服务返回预置回复
    final response = await _mockService.process(
      input,
      imageUrl: imageUrl,
      context: sessionId != null
          ? _dialogManager.getOrCreateSession(sessionId)
          : null,
    );

    // 3. 语音播报结果
    if (response.isSuccess) {
      await _voiceService.speak(response.text);
    }

    // 4. 发送响应到流
    _responseController.add(response);

    return response;
  }

  /// 真实模式处理（保留原有完整逻辑）
  Future<AIResponse> _processRealRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 首先检测紧急关键词
    final emergencyResult = _emergencyService.detector.detect(input);
    if (emergencyResult.isEmergency &&
        emergencyResult.level == UrgencyLevel.emergency) {
      return await _emergencyService.process(input);
    }

    // 2. 获取或创建会话上下文
    final context = sessionId != null
        ? _dialogManager.getOrCreateSession(sessionId)
        : _dialogManager.createSession();

    // 3. 意图识别
    final classifier = IntentClassifier();
    final intentResult = classifier.classify(input, imageUrl: imageUrl);

    // 4. 根据意图路由到对应服务
    AIResponse response;
    switch (intentResult.intent) {
      case IntentType.textRecognition:
        response = await _handleOCR(imageUrl, context);
        break;
      case IntentType.objectRecognition:
      case IntentType.sceneDescription:
        response = await _handleSceneDescription(input, imageUrl, context);
        break;
      case IntentType.colorRecognition:
        response = await _handleColorRecognition(imageUrl, context);
        break;
      case IntentType.emergency:
        response = await _emergencyService.process(input);
        break;
      case IntentType.medicineConfirmation:
      case IntentType.medicalConsultation:
      case IntentType.emotionalSupport:
        // 医疗/情感场景强制转人工
        response = AIResponse.handoff(
          _getHandoffMessage(intentResult.intent),
          intent: intentResult.intent,
        );
        break;
      default:
        // 通用对话
        response = await _smartDialogService.process(
          input,
          imageUrl: imageUrl,
          context: context,
        );
    }

    // 5. 语音播报结果
    if (response.isSuccess) {
      await _voiceService.speak(response.text);
    }

    // 6. 发送响应到流
    _responseController.add(response);

    return response;
  }

  /// 处理OCR请求
  Future<AIResponse> _handleOCR(String? imageUrl, DialogContext context) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '请拍照或选择图片，我来帮您识别文字。',
        intent: IntentType.textRecognition,
        confidence: 1.0,
      );
    }

    if (!_isOnline) {
      return AIResponse.error('文字识别需要网络连接，请检查网络后重试。');
    }

    return await _ocrService.process('', imageUrl: imageUrl, context: context);
  }

  /// 处理场景描述请求
  Future<AIResponse> _handleSceneDescription(
    String input,
    String? imageUrl,
    DialogContext context,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '请拍照，我来帮您描述周围环境。',
        intent: IntentType.sceneDescription,
        confidence: 1.0,
      );
    }

    if (!_isOnline) {
      return AIResponse.error('场景描述需要网络连接，请检查网络后重试。');
    }

    return await _sceneDescriptionService.process(
      input,
      imageUrl: imageUrl,
      context: context,
    );
  }

  /// 处理颜色识别请求
  Future<AIResponse> _handleColorRecognition(
    String? imageUrl,
    DialogContext context,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '请拍照，我来帮您识别颜色。',
        intent: IntentType.colorRecognition,
        confidence: 1.0,
      );
    }

    return await _colorRecognitionService.process(
      '',
      imageUrl: imageUrl,
      context: context,
    );
  }

  /// 获取转人工消息
  String _getHandoffMessage(IntentType intent) {
    switch (intent) {
      case IntentType.medicalConsultation:
        return '您咨询的是医疗相关问题，为了您的健康安全，我将为您转接专业医疗志愿者。';
      case IntentType.medicineConfirmation:
        return '药品使用需要谨慎确认，我将为您转接志愿者协助核对药品信息。';
      case IntentType.emotionalSupport:
        return '我理解您可能需要情感支持，让我为您转接心理支持志愿者。';
      default:
        return '这个问题可能需要人工协助，正在为您转接志愿者。';
    }
  }

  /// 拍照并处理
  Future<AIResponse> takePhotoAndProcess({
    required String input,
    String? sessionId,
  }) async {
    try {
      // 1. 拍照
      final result = await _cameraService.takePhoto();
      if (result == null) {
        return AIResponse.error('拍照已取消');
      }

      // 2. 压缩图片
      final compressedPath = await _cameraService.compressToSize(
        result.path,
        maxSizeKB: 500,
      );

      // 3. 处理请求
      final response = await processRequest(
        input: input,
        imageUrl: compressedPath,
        sessionId: sessionId,
      );

      return response;
    } catch (e) {
      return AIResponse.error('拍照处理失败: $e');
    }
  }

  /// 选择图片并处理
  Future<AIResponse> pickImageAndProcess({
    required String input,
    String? sessionId,
  }) async {
    try {
      // 1. 选择图片
      final result = await _cameraService.pickFromGallery();
      if (result == null) {
        return AIResponse.error('选择图片已取消');
      }

      // 2. 压缩图片
      final compressedPath = await _cameraService.compressToSize(
        result.path,
        maxSizeKB: 500,
      );

      // 3. 处理请求
      final response = await processRequest(
        input: input,
        imageUrl: compressedPath,
        sessionId: sessionId,
      );

      return response;
    } catch (e) {
      return AIResponse.error('图片处理失败: $e');
    }
  }

  /// 开始语音输入
  Future<bool> startVoiceInput({
    required Function(String) onResult,
    Function()? onStart,
    Function()? onEnd,
    Function(String)? onError,
  }) async {
    _voiceService.setASRCallbacks(
      onResult: onResult,
      onStart: onStart,
      onEnd: onEnd,
      onError: onError,
    );

    return await _voiceService.startListening(
      listenDuration: const Duration(seconds: 30),
      partialResults: true,
    );
  }

  /// 停止语音输入
  Future<void> stopVoiceInput() async {
    await _voiceService.stopListening();
  }

  /// 语音播报
  Future<void> speak(String text) async {
    await _voiceService.speak(text);
  }

  /// 停止播报
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
  }

  /// 设置紧急检测回调
  void setEmergencyCallbacks({
    EmergencyCallback? onEmergency,
    EmergencyCallback? onUrgent,
    EmergencyCallback? onConfirmation,
  }) {
    _emergencyService.detector.setCallbacks(
      onEmergency: onEmergency,
      onUrgent: onUrgent,
      onConfirmation: onConfirmation,
    );
  }

  /// 获取服务状态
  Map<String, bool> getServiceStatus() {
    return {
      'smartDialog': _isOnline,
      'ocr': _isOnline,
      'sceneDescription': _isOnline,
      'colorRecognition': true,
      'emergencyDetection': true,
    };
  }

  /// 是否在线
  bool get isOnline => _isOnline;

  /// 是否使用模拟模式
  bool get useMockMode => _useMockMode;

  /// 设置模拟模式
  void setMockMode(bool enabled) {
    AppLogger.warning(
      'AGENTS.md §4.2：竞赛版已冻结 Demo 主线，AIServiceManager 始终保持本地 mock fallback',
    );
  }

  /// 清理资源
  void dispose() {
    _responseController.close();
  }

  // ==================== Getter ====================

  SmartDialogService get smartDialogService => _smartDialogService;
  OcrService get ocrService => _ocrService;
  SceneDescriptionService get sceneDescriptionService =>
      _sceneDescriptionService;
  ColorRecognitionService get colorRecognitionService =>
      _colorRecognitionService;
  EmergencyDetectionService get emergencyService => _emergencyService;
  DialogContextManager get dialogManager => _dialogManager;
  CameraService get cameraService => _cameraService;
  VoiceService get voiceService => _voiceService;
  MockAIService get mockService => _mockService;
}
