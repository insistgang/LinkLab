// AGENTS.md §4.2：競賽版已凍結 Demo 主線。
// 默認 AI 管理器只走本地 mock / fallback；真實 AI 管理器已隔離到 services/experimental/real/ai/。

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

/// AI服務管理器
/// 統一管理和調度所有AI服務
class AIServiceManager {
  static AIServiceManager? _instance;
  static AIServiceManager get instance => _instance ??= AIServiceManager._();

  AIServiceManager._();

  // 配置
  AIServiceConfig _config = const AIServiceConfig();

  // 服務實例
  late final SmartDialogService _smartDialogService;
  late final OcrService _ocrService;
  late final SceneDescriptionService _sceneDescriptionService;
  late final ColorRecognitionService _colorRecognitionService;
  late final EmergencyDetectionService _emergencyService;
  late final DialogContextManager _dialogManager;
  late final CameraService _cameraService;
  late final VoiceService _voiceService;

  // 演示模式：使用模擬服務
  late final MockAIService _mockService;

  /// 競賽版默認只允許本地 mock fallback。
  bool get _useMockMode => true;

  // 狀態
  bool _isInitialized = false;
  bool _isOnline = true;

  // 流控制器
  final _responseController = StreamController<AIResponse>.broadcast();
  Stream<AIResponse> get responseStream => _responseController.stream;

  /// 初始化
  Future<void> initialize(AIServiceConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // 初始化各服務
    _smartDialogService = SmartDialogService(config: config);
    _ocrService = OcrService(config: config);
    _sceneDescriptionService = SceneDescriptionService(config: config);
    _colorRecognitionService = ColorRecognitionService();
    _emergencyService = EmergencyDetectionService();
    _dialogManager = DialogContextManager();
    _cameraService = CameraService();
    _voiceService = VoiceService();

    // 初始化模擬服務（演示模式）
    _mockService = MockAIService(simulateDelay: true);

    // 初始化語音服務
    await _voiceService.initialize();

    // 監聽網絡狀態
    Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
    });

    _isInitialized = true;
  }

  /// 處理用戶請求（統一入口）
  /// 演示模式：使用模擬數據，不調用真實API
  Future<AIResponse> processRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      return AIResponse.error('AI服務未初始化');
    }

    try {
      // AGENTS.md §4.2：競賽版默認 AI 主線只走本地 mock fallback。
      // 如需驗證真實 AI，請顯式使用 services/experimental/real/ai/real_ai_service_manager.dart。
      return await _processMockRequest(
        input: input,
        imageUrl: imageUrl,
        sessionId: sessionId,
      );
    } catch (e) {
      final errorResponse = AIResponse.error('處理請求失敗: $e');
      _responseController.add(errorResponse);
      return errorResponse;
    }
  }

  /// 模擬模式處理
  Future<AIResponse> _processMockRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 首先檢測緊急關鍵詞（本地檢測，不走網絡）
    final emergencyResult = _emergencyService.detector.detect(input);
    if (emergencyResult.isEmergency &&
        emergencyResult.level == UrgencyLevel.emergency) {
      final response = await _emergencyService.process(input);
      await _voiceService.speak(response.text);
      _responseController.add(response);
      return response;
    }

    // 2. 使用模擬服務返回預置回覆
    final response = await _mockService.process(
      input,
      imageUrl: imageUrl,
      context: sessionId != null
          ? _dialogManager.getOrCreateSession(sessionId)
          : null,
    );

    // 3. 語音播報結果
    if (response.isSuccess) {
      await _voiceService.speak(response.text);
    }

    // 4. 發送響應到流
    _responseController.add(response);

    return response;
  }

  /// 真實模式處理（保留原有完整邏輯）
  Future<AIResponse> _processRealRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 首先檢測緊急關鍵詞
    final emergencyResult = _emergencyService.detector.detect(input);
    if (emergencyResult.isEmergency &&
        emergencyResult.level == UrgencyLevel.emergency) {
      return await _emergencyService.process(input);
    }

    // 2. 獲取或創建會話上下文
    final context = sessionId != null
        ? _dialogManager.getOrCreateSession(sessionId)
        : _dialogManager.createSession();

    // 3. 意圖識別
    final classifier = IntentClassifier();
    final intentResult = classifier.classify(input, imageUrl: imageUrl);

    // 4. 根據意圖路由到對應服務
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
        // 醫療/情感場景強制轉人工
        response = AIResponse.handoff(
          _getHandoffMessage(intentResult.intent),
          intent: intentResult.intent,
        );
        break;
      default:
        // 通用對話
        response = await _smartDialogService.process(
          input,
          imageUrl: imageUrl,
          context: context,
        );
    }

    // 5. 語音播報結果
    if (response.isSuccess) {
      await _voiceService.speak(response.text);
    }

    // 6. 發送響應到流
    _responseController.add(response);

    return response;
  }

  /// 處理OCR請求
  Future<AIResponse> _handleOCR(String? imageUrl, DialogContext context) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '請拍照或選擇圖片，我來幫您識別文字。',
        intent: IntentType.textRecognition,
        confidence: 1.0,
      );
    }

    if (!_isOnline) {
      return AIResponse.error('文字識別需要網絡連接，請檢查網絡後重試。');
    }

    return await _ocrService.process('', imageUrl: imageUrl, context: context);
  }

  /// 處理場景描述請求
  Future<AIResponse> _handleSceneDescription(
    String input,
    String? imageUrl,
    DialogContext context,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '請拍照，我來幫您描述周圍環境。',
        intent: IntentType.sceneDescription,
        confidence: 1.0,
      );
    }

    if (!_isOnline) {
      return AIResponse.error('場景描述需要網絡連接，請檢查網絡後重試。');
    }

    return await _sceneDescriptionService.process(
      input,
      imageUrl: imageUrl,
      context: context,
    );
  }

  /// 處理顏色識別請求
  Future<AIResponse> _handleColorRecognition(
    String? imageUrl,
    DialogContext context,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '請拍照，我來幫您識別顏色。',
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

  /// 獲取轉人工消息
  String _getHandoffMessage(IntentType intent) {
    switch (intent) {
      case IntentType.medicalConsultation:
        return '您諮詢的是醫療相關問題，爲了您的健康安全，我將爲您轉接專業醫療志願者。';
      case IntentType.medicineConfirmation:
        return '藥品使用需要謹慎確認，我將爲您轉接志願者協助覈對藥品信息。';
      case IntentType.emotionalSupport:
        return '我理解您可能需要情感支持，讓我爲您轉接心理支持志願者。';
      default:
        return '這個問題可能需要人工協助，正在爲您轉接志願者。';
    }
  }

  /// 拍照並處理
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

      // 2. 壓縮圖片
      final compressedPath = await _cameraService.compressToSize(
        result.path,
        maxSizeKB: 500,
      );

      // 3. 處理請求
      final response = await processRequest(
        input: input,
        imageUrl: compressedPath,
        sessionId: sessionId,
      );

      return response;
    } catch (e) {
      return AIResponse.error('拍照處理失敗: $e');
    }
  }

  /// 選擇圖片並處理
  Future<AIResponse> pickImageAndProcess({
    required String input,
    String? sessionId,
  }) async {
    try {
      // 1. 選擇圖片
      final result = await _cameraService.pickFromGallery();
      if (result == null) {
        return AIResponse.error('選擇圖片已取消');
      }

      // 2. 壓縮圖片
      final compressedPath = await _cameraService.compressToSize(
        result.path,
        maxSizeKB: 500,
      );

      // 3. 處理請求
      final response = await processRequest(
        input: input,
        imageUrl: compressedPath,
        sessionId: sessionId,
      );

      return response;
    } catch (e) {
      return AIResponse.error('圖片處理失敗: $e');
    }
  }

  /// 開始語音輸入
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

  /// 停止語音輸入
  Future<void> stopVoiceInput() async {
    await _voiceService.stopListening();
  }

  /// 語音播報
  Future<void> speak(String text) async {
    await _voiceService.speak(text);
  }

  /// 停止播報
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
  }

  /// 設置緊急檢測回調
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

  /// 獲取服務狀態
  Map<String, bool> getServiceStatus() {
    return {
      'smartDialog': _isOnline,
      'ocr': _isOnline,
      'sceneDescription': _isOnline,
      'colorRecognition': true,
      'emergencyDetection': true,
    };
  }

  /// 是否在線
  bool get isOnline => _isOnline;

  /// 是否使用模擬模式
  bool get useMockMode => _useMockMode;

  /// 設置模擬模式
  void setMockMode(bool enabled) {
    AppLogger.warning(
      'AGENTS.md §4.2：競賽版已凍結 Demo 主線，AIServiceManager 始終保持本地 mock fallback',
    );
  }

  /// 清理資源
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
