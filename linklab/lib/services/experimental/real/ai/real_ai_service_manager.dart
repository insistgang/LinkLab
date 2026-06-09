import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../config/api_config.dart';
import '../../../../core/utils/logger.dart';
import '../../../ai/ai_service.dart';
import '../../../ai/baidu_ocr_service.dart';
import '../../../ai/camera_service.dart';
import '../../../ai/dialog_manager.dart';
import '../../../ai/mock_ai_service.dart';
import '../../../ai/qwen_vl_service.dart';
import '../../../ai/real_emergency_detector.dart';
import '../../../ai/real_intent_classifier.dart';
import '../../../ai/xfyun_voice_service.dart';

/// 真實AI服務管理器
/// 統一管理真實的AI API調用（百度OCR、通義千問VL、科大訊飛）
/// 支持演示模式和真實模式切換，具備完整的降級策略
/// AGENTS.md §4.2：競賽版僅走 Demo 主線，當前文件只保留爲實驗性真實鏈路實現。
class RealAIServiceManager {
  static RealAIServiceManager? _instance;
  static RealAIServiceManager get instance =>
      _instance ??= RealAIServiceManager._();

  RealAIServiceManager._();

  // 配置
  AIServiceConfig _config = const AIServiceConfig();

  // 真實服務實例
  late final BaiduOCRService _baiduOcrService;
  late final QwenVLService _qwenVLService;
  late final XfyunVoiceService _xfyunVoiceService;
  late final RealIntentClassifier _intentClassifier;
  late final RealEmergencyDetector _emergencyDetector;
  late final DialogContextManager _dialogManager;
  late final CameraService _cameraService;

  // 模擬服務（降級使用）
  late final MockAIService _mockService;

  // 狀態
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _useRealMode = false; // 默認使用演示模式

  // 流控制器
  final _responseController = StreamController<AIResponse>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<AIResponse> get responseStream => _responseController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// 初始化
  Future<void> initialize(AIServiceConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // 初始化真實服務
    _baiduOcrService = BaiduOCRService();
    _qwenVLService = QwenVLService();
    _xfyunVoiceService = XfyunVoiceService();
    _intentClassifier = RealIntentClassifier();
    _emergencyDetector = RealEmergencyDetector();
    _dialogManager = DialogContextManager();
    _cameraService = CameraService();

    // 初始化模擬服務（降級使用）
    _mockService = MockAIService(simulateDelay: true);

    // 監聽網絡狀態
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        _connectionStatusController.add(_isOnline);
      }
    });

    _isInitialized = true;
  }

  /// 處理用戶請求（統一入口）
  Future<AIResponse> processRequest({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      return AIResponse.error('AI服務未初始化');
    }

    try {
      // 1. 首先檢測緊急關鍵詞（本地檢測，優先級最高）
      final emergencyResult = _emergencyDetector.detect(input);
      if (emergencyResult.isEmergency &&
          emergencyResult.level == UrgencyLevel.emergency) {
        final response = AIResponse(
          text: '檢測到緊急情況"${emergencyResult.triggerWord}"，正在立即啓動SOS流程！',
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

      // 2. 檢查是否需要確認（緊急但未達危急級別）
      if (emergencyResult.isEmergency && emergencyResult.requiresConfirmation) {
        final response = AIResponse(
          text:
              '檢測到可能的緊急情況"${emergencyResult.triggerWord}"，${emergencyResult.confirmationSeconds}秒內未取消將自動觸發SOS。',
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

      // 3. 根據模式選擇處理方式
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
    } catch (error, stackTrace) {
      AppLogger.error('真實 AI 請求處理失敗，準備降級到 Demo 路徑', error, stackTrace);
      // 發生錯誤時降級到模擬服務
      final errorResponse = await _handleErrorAndFallback(
        error: error,
        input: input,
        imageUrl: imageUrl,
        sessionId: sessionId,
      );
      _responseController.add(errorResponse);
      return errorResponse;
    }
  }

  /// 使用真實API處理
  Future<AIResponse> _processWithRealAPI({
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    // 1. 意圖分類
    final classification = _intentClassifier.classify(
      input,
      sessionId: sessionId,
      imageUrl: imageUrl,
    );

    // 2. 根據意圖路由到對應的真實服務
    AIResponse response;

    switch (classification.intent) {
      case IntentType.textRecognition:
        response = await _handleRealOCR(imageUrl, classification);
        break;

      case IntentType.objectRecognition:
      case IntentType.sceneDescription:
      case IntentType.colorRecognition:
        response = await _handleRealSceneDescription(
          input,
          imageUrl,
          classification,
        );
        break;

      case IntentType.emergency:
        response = AIResponse(
          text: '檢測到緊急情況，正在啓動SOS流程',
          intent: IntentType.emergency,
          urgency: UrgencyLevel.emergency,
          needsHuman: true,
          confidence: 1.0,
        );
        break;

      case IntentType.medicineConfirmation:
      case IntentType.medicalConsultation:
      case IntentType.emotionalSupport:
        // 醫療/情感場景強制轉人工
        response = AIResponse.handoff(
          _getHandoffMessage(classification.intent),
          intent: classification.intent,
        );
        break;

      default:
        // 通用對話 - 使用通義千問VL（如果有圖片）或模擬回覆
        if (imageUrl != null && APIConfig.isQwenConfigured) {
          response = await _handleRealSceneDescription(
            input,
            imageUrl,
            classification,
          );
        } else {
          response = await _mockService.process(input, imageUrl: imageUrl);
        }
    }

    // 3. 語音播報結果
    if (response.isSuccess) {
      await speak(response.text);
    }

    // 4. 發送響應到流
    _responseController.add(response);

    return response;
  }

  /// 使用模擬服務處理（降級）
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

    // 語音播報結果
    if (response.isSuccess) {
      await speak(response.text);
    }

    _responseController.add(response);
    return response;
  }

  /// 處理真實OCR請求
  Future<AIResponse> _handleRealOCR(
    String? imageUrl,
    IntentClassification classification,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '請拍照或選擇圖片，我來幫您識別文字。',
        intent: IntentType.textRecognition,
        confidence: 1.0,
      );
    }

    // 檢查百度OCR是否已配置
    if (!APIConfig.isBaiduOcrConfigured) {
      return AIResponse.error('百度OCR服務未配置，請在APIConfig中設置API密鑰，或使用演示模式。');
    }

    try {
      final file = File(imageUrl);
      if (!await file.exists()) {
        return AIResponse.error('圖片文件不存在');
      }

      // 調用百度OCR服務
      final result = await _baiduOcrService.recognizeText(file);

      if (!result.isSuccess) {
        // API錯誤時降級到模擬服務
        return await _handleAPIErrorAndFallback(
          error: result.error,
          intent: IntentType.textRecognition,
          imageUrl: imageUrl,
        );
      }

      final ocrResult = result.data!;

      // 檢查是否是藥品標籤
      final isMedicineLabel = _isMedicineLabel(ocrResult.text);

      // 構建響應文本
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
    } catch (error, stackTrace) {
      AppLogger.error('真實 OCR 處理失敗，準備降級', error, stackTrace);
      return await _handleAPIErrorAndFallback(
        error: APIError(
          type: APIErrorType.unknown,
          message: 'OCR識別失敗',
          originalError: error.toString(),
        ),
        intent: IntentType.textRecognition,
        imageUrl: imageUrl,
      );
    }
  }

  /// 處理真實場景描述請求
  Future<AIResponse> _handleRealSceneDescription(
    String input,
    String? imageUrl,
    IntentClassification classification,
  ) async {
    if (imageUrl == null) {
      return AIResponse(
        text: '請拍照，我來幫您描述周圍環境。',
        intent: classification.intent,
        confidence: 1.0,
      );
    }

    // 檢查通義千問是否已配置
    if (!APIConfig.isQwenConfigured) {
      return AIResponse.error('通義千問VL服務未配置，請在APIConfig中設置API密鑰，或使用演示模式。');
    }

    try {
      final file = File(imageUrl);
      if (!await file.exists()) {
        return AIResponse.error('圖片文件不存在');
      }

      // 調用通義千問VL服務
      final result = await _qwenVLService.describeScene(
        file,
        customPrompt: input.isNotEmpty ? input : null,
      );

      if (!result.isSuccess) {
        // API錯誤時降級到模擬服務
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
    } catch (error, stackTrace) {
      AppLogger.error('真實場景描述失敗，準備降級', error, stackTrace);
      return await _handleAPIErrorAndFallback(
        error: APIError(
          type: APIErrorType.unknown,
          message: '場景描述失敗',
          originalError: error.toString(),
        ),
        intent: classification.intent,
        imageUrl: imageUrl,
      );
    }
  }

  /// 處理API錯誤並降級
  Future<AIResponse> _handleAPIErrorAndFallback({
    APIError? error,
    required IntentType intent,
    String? imageUrl,
  }) async {
    // 記錄錯誤日誌
    AppLogger.warning(
      '真實 AI API 返回錯誤，進入降級: ${error?.message ?? 'unknown'}',
      error,
    );

    // 根據錯誤類型返回友好的降級提示
    String fallbackMessage;
    switch (error?.type) {
      case APIErrorType.networkError:
        fallbackMessage = '網絡連接失敗，已切換到離線模式。請檢查網絡設置後重試。';
        break;
      case APIErrorType.authenticationError:
        fallbackMessage = 'API認證失敗，請檢查API密鑰配置是否正確。';
        break;
      case APIErrorType.quotaExceeded:
        fallbackMessage = 'API調用配額已用完，請聯繫管理員或稍後再試。';
        break;
      case APIErrorType.timeout:
        fallbackMessage = '請求超時，已使用本地模式響應。';
        break;
      case APIErrorType.serviceUnavailable:
        fallbackMessage = 'AI服務暫時不可用，已切換到演示模式。';
        break;
      default:
        fallbackMessage = '服務暫時不可用，已使用演示模式響應。';
    }

    // 返回降級響應
    return AIResponse(
      text: fallbackMessage,
      intent: intent,
      urgency: UrgencyLevel.normal,
      needsHuman: false,
      confidence: 0.5,
      extraData: {'fallback': true, 'originalError': error?.message},
    );
  }

  /// 處理一般錯誤並降級
  Future<AIResponse> _handleErrorAndFallback({
    required dynamic error,
    required String input,
    String? imageUrl,
    String? sessionId,
  }) async {
    AppLogger.error('真實 AI 請求發生異常，進入降級', error);

    // 嘗試使用模擬服務
    try {
      final mockResponse = await _mockService.process(
        input,
        imageUrl: imageUrl,
      );

      // 包裝爲降級響應
      return AIResponse(
        text: '${mockResponse.text}\n\n[提示：當前使用演示模式，真實AI服務暫時不可用]',
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
    } catch (fallbackError, fallbackStackTrace) {
      AppLogger.error(
        '真實 AI 與 Demo fallback 均失敗',
        fallbackError,
        fallbackStackTrace,
      );
      // 模擬服務也失敗，返回錯誤
      return AIResponse.error('服務暫時不可用，請稍後重試');
    }
  }

  /// 判斷是否是藥品標籤
  bool _isMedicineLabel(String text) {
    final medicineKeywords = [
      '藥品',
      '藥物',
      '藥片',
      '膠囊',
      '顆粒',
      '口服液',
      '用法用量',
      '適應症',
      '禁忌',
      '不良反應',
      '國藥準字',
      '處方藥',
      'OTC',
      '非處方藥',
      '生產日期',
      '有效期',
      '批號',
      'medication',
      'dosage',
      'prescription',
      'tablet',
      'capsule',
      'mg',
      'ml',
    ];

    final lowerText = text.toLowerCase();
    return medicineKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// 構建OCR響應文本
  String _buildOCRResponseText(OCRResult result, bool isMedicineLabel) {
    if (result.text.isEmpty) {
      return '未能識別到文字，請嘗試重新拍攝，確保光線充足、文字清晰可見。';
    }

    final buffer = StringBuffer();

    if (isMedicineLabel) {
      buffer.writeln('檢測到藥品標籤，識別結果如下：');
      buffer.writeln();
    } else {
      buffer.writeln('識別到以下內容：');
      buffer.writeln();
    }

    buffer.writeln(result.text);

    if (isMedicineLabel) {
      buffer.writeln();
      buffer.writeln('【重要提醒】這是藥品標籤，用藥前請務必向志願者或醫生確認用法用量，確保用藥安全。');
    }

    return buffer.toString();
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

  // ==================== 公共方法 ====================

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
    } catch (error, stackTrace) {
      AppLogger.error('拍照後處理真實 AI 請求失敗', error, stackTrace);
      return AIResponse.error('拍照處理失敗: $error');
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
    } catch (error, stackTrace) {
      AppLogger.error('相冊圖片處理真實 AI 請求失敗', error, stackTrace);
      return AIResponse.error('圖片處理失敗: $error');
    }
  }

  /// 語音播報（使用科大訊飛TTS）
  Future<void> speak(String text) async {
    if (!APIConfig.isXfyunConfigured) {
      // 未配置科大訊飛，使用系統TTS
      AppLogger.info('科大訊飛未配置，使用系統TTS fallback');
      return;
    }

    try {
      final result = await _xfyunVoiceService.textToSpeech(text);
      if (result.isSuccess) {
        // 播放音頻數據
        // 實際項目中需要集成音頻播放器
        AppLogger.verbose(
          'TTS成功，音頻數據大小: ${result.data?.length ?? 0} bytes',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('真實 TTS 失敗', error, stackTrace);
    }
  }

  /// 停止播報
  Future<void> stopSpeaking() async {
    // 實際項目中需要停止音頻播放器
  }

  /// 開始語音識別（使用科大訊飛ASR）
  Future<bool> startVoiceRecognition({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function()? onStart,
    Function()? onEnd,
    Function(String)? onError,
  }) async {
    if (!APIConfig.isXfyunConfigured) {
      onError?.call('科大訊飛ASR未配置');
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

  /// 停止語音識別
  Future<void> stopVoiceRecognition() async {
    await _xfyunVoiceService.stopAsr();
  }

  /// 設置緊急檢測回調
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

  /// 確認緊急狀態（用戶主動確認）
  void confirmEmergency() {
    _emergencyDetector.confirmEmergency();
  }

  /// 取消緊急狀態
  void cancelEmergency() {
    _emergencyDetector.cancelEmergency();
  }

  /// 獲取確認狀態
  ConfirmationStatus? get confirmationStatus =>
      _emergencyDetector.confirmationStatus;

  /// 獲取服務配置狀態
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

  /// 獲取API配置狀態
  Map<String, bool> getApiConfigStatus() {
    return APIConfig.getConfigStatus();
  }

  /// 是否在線
  bool get isOnline => _isOnline;

  /// 是否使用真實模式
  bool get useRealMode => _useRealMode;

  /// 設置真實模式
  void setRealMode(bool enabled) {
    _useRealMode = enabled;
  }

  /// 切換模式
  void toggleMode() {
    _useRealMode = !_useRealMode;
  }

  /// 清理資源
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
