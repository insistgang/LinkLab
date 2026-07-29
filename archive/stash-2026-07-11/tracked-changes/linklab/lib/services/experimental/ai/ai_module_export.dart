// AI Agent 模块导出文件
// 统一导出所有 AI 服务相关的类和接口。

// 核心接口和模型
export 'ai_service.dart';

// 服务管理器
export 'ai_service_manager.dart';

// 模拟服务（演示模式）
export 'mock_ai_service.dart';

// 真实AI底层组件仍可独立复用；真实管理器已迁移到 experimental/real/ai。
export 'baidu_ocr_service.dart' show BaiduOCRService, OCRResult, OCRWord, IdCardResult, BankCardResult, BusinessLicenseResult;
export 'qwen_vl_service.dart' show QwenVLService;
export 'xfyun_voice_service.dart';
export 'real_intent_classifier.dart' show RealIntentClassifier;
export 'real_emergency_detector.dart' show RealEmergencyDetector;

// 辅助组件
export 'urgency_detector.dart';
export 'dialog_manager.dart';
export 'camera_service.dart';
export 'voice_service.dart';
