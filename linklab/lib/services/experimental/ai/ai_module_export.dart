// AI Agent 模塊導出文件
// 統一導出所有 AI 服務相關的類和接口。

// 核心接口和模型
export 'ai_service.dart';

// 服務管理器
export 'ai_service_manager.dart';

// 模擬服務（演示模式）
export 'mock_ai_service.dart';

// 真實AI底層組件仍可獨立複用；真實管理器已遷移到 experimental/real/ai。
export 'baidu_ocr_service.dart' show BaiduOCRService, OCRResult, OCRWord, IdCardResult, BankCardResult, BusinessLicenseResult;
export 'qwen_vl_service.dart' show QwenVLService;
export 'xfyun_voice_service.dart';
export 'real_intent_classifier.dart' show RealIntentClassifier;
export 'real_emergency_detector.dart' show RealEmergencyDetector;

// 輔助組件
export 'urgency_detector.dart';
export 'dialog_manager.dart';
export 'camera_service.dart';
export 'voice_service.dart';
