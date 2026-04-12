import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../config/api_config.dart';
import 'ai_service.dart';
import 'baidu_ocr_service.dart';
import 'qwen_vl_service.dart';
import 'xfyun_voice_service.dart';
import 'real_intent_classifier.dart';
import 'real_emergency_detector.dart';
import 'mock_ai_service.dart';
import 'camera_service.dart';
import 'dialog_manager.dart';

/// 真实AI服务管理器
/// 统一管理真实的AI API调用（百度OCR、通义千问VL、科大讯飞）
/// 支持演示模式和真实模式切换，具备完整的降级策略
class RealAIServiceManager {
  static RealAIServiceManager? _instance;
  static RealAIServiceManager get instance => _instance ??= RealAIServiceManager._();

  RealAIServiceManager._();

  // 配置
  AIServiceConfig _config = const AIServiceConfig();

  // 真实服务实例
  late final BaiduOCRService _baiduOcrService;
  late final QwenVLService _qwenVLService;
  late final XfyunVoiceService _xfyunVoiceService;
  late final RealIntentClassifier _intentClassifier;
  late final RealEmergencyDetector _emergencyDetector;
  late final DialogContextManager _dialogManager;
  late final CameraService _cameraService;

  // 模拟服务（降级使用）
  late final MockAIService _mockService;

  // 状态
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _useRealMode = false; // 默认使用演示模式

  // 流控制器
  final _responseController = StreamController<AIResponse>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<AIResponse> get responseStream => _responseController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// 初始化
  Future<void> initialize(AIServiceConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // 初始化真实服务
    _baiduOcrService = BaiduOCRService();
    _qwenVLService = QwenVLService();
    _xfyunVoiceService = XfyunVoiceService();
    _intentClassifier = RealIntentClassifier();
    _emergencyDetector = RealEmergencyDetector();
    _dialogManager = DialogContextManager();
    _cameraService = CameraService();

    // 初始化模拟服务（降级使用）
    _mockService = MockAIService(simulateDelay: true);

    // 监听网络状态
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      if (wasOnline != _isOnline) {
        _connectionStatusController.add(_isOnline);
      }
    });

    _isInitialized = true;
  }

  /// 处理用户请求（统一入口）
  Future<AIResponse> processRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      return AIResponse.error('AI服务未初始化');
    }

    try {
      // 1. 首先检测紧急关键词（本地检测，优先级最高）
      final emergencyResult = _emergencyDetector.detect(input);
      if (emergencyResult.isEmergency &&
          emergencyResult.level == UrgencyLevel.emergency) {
        final response = AIResponse(
          text: '检测到紧急情况"${emergencyResult.triggerWord}"，正在立即启动SOS流程！',
          intent: IntentType.emergency,
          urgency: UrgencyLevel.emergency,
          needsHuman: true,
          confidence: 0.95,
          extraData: {
            'triggerWord': emergencyResult.triggerWord,
            'requiresConfirmation': false,
            'reason': emergencyResult.reason,
          },
        );
        _responseController.add(response);
        return response;
      }

      // 2. 检查是否需要确认（紧急但未达危急级别）
      if (emergencyResult.isEmergency && emergencyResult.requiresConfirmation) {
        final response = AIResponse(
          text: '检测到可能的紧急情况"${emergencyResult.triggerWord}"，${emergencyResult.confirmationSeconds}秒内未取消将自动触发SOS。',
          intent: IntentType.emergency,
          urgency: UrgencyLevel.urgent,
          needsHuman: true,
          confidence: 0.9,
          extraData: {
            'triggerWord': emergencyResult.triggerWord,
            'requiresConfirmation': true,
            'confirmationSeconds': emergencyResult.confirmationSeconds,
            'reason': emergencyResult.reason,
          },
        );
        _responseController.add(response);
        return response;
      }

      // 3. 根据模式选择处理方式
      if (_useRealMode && _isOnline) {
        return await _processWithRealAPI(
          input: input,
          imageUrl: imageUrl,
          sessionId: sessionId,
        );
      } else {
        return await _processWithMock(
          input: input,
          imageUrl: imageUrl,
          sessionId: sessionId,
        );
      }
    } catch (e) {
      // 发生错误时降级到模拟服务
      final errorResponse = await _handleErrorAndFallback(
        error: e,
        input: input,
        imageUrl: imageUrl,
        sessionId: sessionId,
      );
      _responseController.add(errorResponse);
      return errorResponse;
    }
  }

  /// 使用真实API处理
  Future<AIResponse> _processWithRealAPI({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 意图分类
    final classification = _intentClassifier.classify(
      input,
      sessionId: sessionId,
      imageUrl: imageUrl,
    );

    // 2. 根据意图路由到对应的真实服务
    AIResponse response;

    switch (classification.intent) {
      case IntentType.textRecognition:
        response = await _handleRealOCR(imageUrl, classification);
        break;

      case IntentType.objectRecognition:
      case IntentType.sceneDescription:
      case IntentType.colorRecognition:
        response = await _handleRealSceneDescription(input, imageUrl, classification);
        break;

      case IntentType.emergency:
        response = AIResponse(
          text: '检测到紧急情况，正在启动SOS流程',
          intent: IntentType.emergency,
          urgency: UrgencyLevel.emergency,
          needsHuman: true,
          confidence: 1.0,
        );
        break;

      case IntentType.medicineConfirmation:
      case IntentType.medicalConsultation:
      case IntentType.emotionalSupport:
        // 医疗/情感场景强制转人工
        response = AIResponse.handoff(
          _getHandoffMessage(classification.intent),
          intent: classification.intent,
        );
        break;

      default:
        // 通用对话 - 使用通义千问VL（如果有图片）或模拟回复
        if (imageUrl != null && APIConfig.isQwenConfigured) {
          response = await _handleRealSceneDescription(input, imageUrl, classification);
        } else {
          response = await _mockService.process(input, imageUrl: imageUrl);
        }
    }

    // 3. 语音播报结果
    if (response.isSuccess) {
      await speak(response.text);
    }

    // 4. 发送响应到流
    _responseController.add(response);

    return response;
  }

  /// 使用模拟服务处理（降级）
  Future<AIResponse> _processWithMock({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    final response = await _mockService.process(
      input,
      imageUrl: imageUrl,
      context: sessionId != null
          ? _dialogManager.getOrCreateSession(sessionId)
          : null,
    );

    // 语音播报结果
    if (response.isSuccess) {
      await speak(response.text);
    }

    _responseController.add(response);
    return response;
  }

  /// 处理真实OCR请求
  Future<AIResponse> _handleRealOCR(
    String? imageUrl,
    IntentClassification classification,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '请拍照或选择图片，我来帮您识别文字。',
        intent: IntentType.textRecognition,
        confidence: 1.0,
      );
    }

    // 检查百度OCR是否已配置
    if (!APIConfig.isBaiduOcrConfigured) {
      return AIResponse.error(
        '百度OCR服务未配置，请在APIConfig中设置API密钥，或使用演示模式。',
      );
    }

    try {
      final file = File(imageUrl);
      if (!await file.exists()) {
        return AIResponse.error('图片文件不存在');
      }

      // 调用百度OCR服务
      final result = await _baiduOcrService.recognizeText(file);

      if (!result.isSuccess) {
        // API错误时降级到模拟服务
        return await _handleAPIErrorAndFallback(
          error: result.error,
          intent: IntentType.textRecognition,
          imageUrl: imageUrl,
        );
      }

      final ocrResult = result.data!;

      // 检查是否是药品标签
      final isMedicineLabel = _isMedicineLabel(ocrResult.text);

      // 构建响应文本
      final responseText = _buildOCRResponseText(ocrResult, isMedicineLabel);

      return AIResponse(
        text: responseText,
        intent: IntentType.textRecognition,
        urgency: isMedicineLabel ? UrgencyLevel.important : UrgencyLevel.normal,
        needsHuman: isMedicineLabel,
        confidence: ocrResult.confidence,
        extraData: {
          'rawText': ocrResult.text,
          'words': ocrResult.words.map((w) => w.text).toList(),
          'isMedicineLabel': isMedicineLabel,
          'language': ocrResult.language,
          'service': 'baidu_ocr',
        },
      );
    } catch (e) {
      return await _handleAPIErrorAndFallback(
        error: APIError(
          type: APIErrorType.unknown,
          message: 'OCR识别失败',
          originalError: e.toString(),
        ),
        intent: IntentType.textRecognition,
        imageUrl: imageUrl,
      );
    }
  }

  /// 处理真实场景描述请求
  Future<AIResponse> _handleRealSceneDescription(
    String input,
    String? imageUrl,
    IntentClassification classification,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '请拍照，我来帮您描述周围环境。',
        intent: classification.intent,
        confidence: 1.0,
      );
    }

    // 检查通义千问是否已配置
    if (!APIConfig.isQwenConfigured) {
      return AIResponse.error(
        '通义千问VL服务未配置，请在APIConfig中设置API密钥，或使用演示模式。',
      );
    }

    try {
      final file = File(imageUrl);
      if (!await file.exists()) {
        return AIResponse.error('图片文件不存在');
      }

      // 调用通义千问VL服务
      final result = await _qwenVLService.describeScene(
        file,
        customPrompt: input.isNotEmpty ? input : null,
      );

      if (!result.isSuccess) {
        // API错误时降级到模拟服务
        return await _handleAPIErrorAndFallback(
          error: result.error,
          intent: classification.intent,
          imageUrl: imageUrl,
        );
      }

      final description = result.data!;

      return AIResponse(
        text: description.formattedText,
        intent: classification.intent,
        urgency: description.safetyWarnings.isNotEmpty
            ? UrgencyLevel.important
            : UrgencyLevel.normal,
        needsHuman: false,
        confidence: description.confidence,
        extraData: {
          'rawResponse': description.rawText,
          'objects': description.objects.map((o) => o.toString()).toList(),
          'spatialRelations': description.spatialRelations,
          'safetyWarnings': description.safetyWarnings,
          'sceneType': description.sceneType,
          'service': 'qwen_vl',
        },
      );
    } catch (e) {
      return await _handleAPIErrorAndFallback(
        error: APIError(
          type: APIErrorType.unknown,
          message: '场景描述失败',
          originalError: e.toString(),
        ),
        intent: classification.intent,
        imageUrl: imageUrl,
      );
    }
  }

  /// 处理API错误并降级
  Future<AIResponse> _handleAPIErrorAndFallback({
    APIError? error,
    required IntentType intent,
    String? imageUrl,
  }) async {
    // 记录错误日志
    print('API错误: ${error?.message}');

    // 根据错误类型返回友好的降级提示
    String fallbackMessage;
    switch (error?.type) {
      case APIErrorType.networkError:
        fallbackMessage = '网络连接失败，已切换到离线模式。请检查网络设置后重试。';
        break;
      case APIErrorType.authenticationError:
        fallbackMessage = 'API认证失败，请检查API密钥配置是否正确。';
        break;
      case APIErrorType.quotaExceeded:
        fallbackMessage = 'API调用配额已用完，请联系管理员或稍后再试。';
        break;
      case APIErrorType.timeout:
        fallbackMessage = '请求超时，已使用本地模式响应。';
        break;
      case APIErrorType.serviceUnavailable:
        fallbackMessage = 'AI服务暂时不可用，已切换到演示模式。';
        break;
      default:
        fallbackMessage = '服务暂时不可用，已使用演示模式响应。';
    }

    // 返回降级响应
    return AIResponse(
      text: fallbackMessage,
      intent: intent,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.5,
      extraData: {
        'fallback': true,
        'originalError': error?.message,
      },
    );
  }

  /// 处理一般错误并降级
  Future<AIResponse> _handleErrorAndFallback({
    required dynamic error,
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    print('处理请求时发生错误: $error');

    // 尝试使用模拟服务
    try {
      final mockResponse = await _mockService.process(
        input,
        imageUrl: imageUrl,
      );

      // 包装为降级响应
      return AIResponse(
        text: '${mockResponse.text}\n\n[提示：当前使用演示模式，真实AI服务暂时不可用]',
        intent: mockResponse.intent,
        urgency: mockResponse.urgency,
        needsHuman: mockResponse.needsHuman,
        confidence: mockResponse.confidence * 0.8, // 降低置信度
        extraData: {
          ...?mockResponse.extraData,
          'fallback': true,
          'originalError': error.toString(),
        },
      );
    } catch (e) {
      // 模拟服务也失败，返回错误
      return AIResponse.error('服务暂时不可用，请稍后重试');
    }
  }

  /// 判断是否是药品标签
  bool _isMedicineLabel(String text) {
    final medicineKeywords = [
      '药品', '药物', '药片', '胶囊', '颗粒', '口服液',
      '用法用量', '适应症', '禁忌', '不良反应',
      '国药准字', '处方药', 'OTC', '非处方药',
      '生产日期', '有效期', '批号',
      'medication', 'dosage', 'prescription',
      'tablet', 'capsule', 'mg', 'ml',
    ];

    final lowerText = text.toLowerCase();
    return medicineKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// 构建OCR响应文本
  String _buildOCRResponseText(OCRResult result, bool isMedicineLabel) {
    if (result.text.isEmpty) {
      return '未能识别到文字，请尝试重新拍摄，确保光线充足、文字清晰可见。';
    }

    final buffer = StringBuffer();

    if (isMedicineLabel) {
      buffer.writeln('检测到药品标签，识别结果如下：');
      buffer.writeln();
    } else {
      buffer.writeln('识别到以下内容：');
      buffer.writeln();
    }

    buffer.writeln(result.text);

    if (isMedicineLabel) {
      buffer.writeln();
      buffer.writeln('【重要提醒】这是药品标签，用药前请务必向志愿者或医生确认用法用量，确保用药安全。');
    }

    return buffer.toString();
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

  // ==================== 公共方法 ====================

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

  /// 语音播报（使用科大讯飞TTS）
  Future<void> speak(String text) async {
    if (!APIConfig.isXfyunConfigured) {
      // 未配置科大讯飞，使用系统TTS
      print('科大讯飞未配置，使用系统TTS: $text');
      return;
    }

    try {
      final result = await _xfyunVoiceService.textToSpeech(text);
      if (result.isSuccess) {
        // 播放音频数据
        // 实际项目中需要集成音频播放器
        print('TTS成功，音频数据大小: ${result.data?.length ?? 0} bytes');
      }
    } catch (e) {
      print('TTS失败: $e');
    }
  }

  /// 停止播报
  Future<void> stopSpeaking() async {
    // 实际项目中需要停止音频播放器
  }

  /// 开始语音识别（使用科大讯飞ASR）
  Future<bool> startVoiceRecognition({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function()? onStart,
    Function()? onEnd,
    Function(String)? onError,
  }) async {
    if (!APIConfig.isXfyunConfigured) {
      onError?.call('科大讯飞ASR未配置');
      return false;
    }

    _xfyunVoiceService.setAsrCallbacks(
      onResult: onResult,
      onPartialResult: onPartialResult,
      onStart: onStart,
      onEnd: onEnd,
      onError: onError,
    );

    return await _xfyunVoiceService.startRealTimeAsr();
  }

  /// 停止语音识别
  Future<void> stopVoiceRecognition() async {
    await _xfyunVoiceService.stopAsr();
  }

  /// 设置紧急检测回调
  void setEmergencyCallbacks({
    EmergencyCallback? onEmergency,
    EmergencyCallback? onUrgent,
    EmergencyCallback? onConfirmation,
    EmergencyCallback? onEmotionalCrisis,
  }) {
    _emergencyDetector.setCallbacks(
      onEmergency: onEmergency,
      onUrgent: onUrgent,
      onConfirmation: onConfirmation,
      onEmotionalCrisis: onEmotionalCrisis,
    );
  }

  /// 确认紧急状态（用户主动确认）
  void confirmEmergency() {
    _emergencyDetector.confirmEmergency();
  }

  /// 取消紧急状态
  void cancelEmergency() {
    _emergencyDetector.cancelEmergency();
  }

  /// 获取确认状态
  ConfirmationStatus? get confirmationStatus => _emergencyDetector.confirmationStatus;

  /// 获取服务配置状态
  Map<String, dynamic> getServiceStatus() {
    return {
      'isOnline': _isOnline,
      'useRealMode': _useRealMode,
      'baiduOcr': APIConfig.isBaiduOcrConfigured,
      'qwenVL': APIConfig.isQwenConfigured,
      'xfyun': APIConfig.isXfyunConfigured,
      'emergencyDetector': true,
    };
  }

  /// 获取API配置状态
  Map<String, bool> getApiConfigStatus() {
    return APIConfig.getConfigStatus();
  }

  /// 是否在线
  bool get isOnline => _isOnline;

  /// 是否使用真实模式
  bool get useRealMode => _useRealMode;

  /// 设置真实模式
  void setRealMode(bool enabled) {
    _useRealMode = enabled;
  }

  /// 切换模式
  void toggleMode() {
    _useRealMode = !_useRealMode;
  }

  /// 清理资源
  void dispose() {
    _responseController.close();
    _connectionStatusController.close();
    _baiduOcrService.dispose();
    _qwenVLService.dispose();
    _xfyunVoiceService.dispose();
  }

  // ==================== Getter ====================

  BaiduOCRService get baiduOcrService => _baiduOcrService;
  QwenVLService get qwenVLService => _qwenVLService;
  XfyunVoiceService get xfyunVoiceService => _xfyunVoiceService;
  RealIntentClassifier get intentClassifier => _intentClassifier;
  RealEmergencyDetector get emergencyDetector => _emergencyDetector;
  DialogContextManager get dialogManager => _dialogManager;
  CameraService get cameraService => _cameraService;
  MockAIService get mockService => _mockService;
}
