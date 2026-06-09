# 真實AI服務集成指南

## 概述

本文檔介紹如何在LinkAble應用中集成真實的AI API服務，替換演示版的模擬數據。

## 已實現的AI服務

### 1. 百度OCR服務 (F2)

**文件**: `lib/services/ai/baidu_ocr_service.dart`

**功能**:
- 通用文字識別（標準版）
- 高精度文字識別
- 手寫體識別
- 身份證識別
- 銀行卡識別
- 營業執照識別

**API配置**:
```dart
APIConfig.baiduOcrApiKey = '您的API Key';
APIConfig.baiduOcrSecretKey = '您的Secret Key';
```

**使用方法**:
```dart
final ocrService = BaiduOCRService();
final result = await ocrService.recognizeText(imageFile);
if (result.isSuccess) {
  print('識別結果: ${result.data!.text}');
}
```

### 2. 通義千問VL服務 (F3/F7)

**文件**: `lib/services/ai/qwen_vl_service.dart`

**功能**:
- 場景描述
- 物體識別
- 問答功能
- 空間佈局分析

**API配置**:
```dart
APIConfig.qwenApiKey = '您的API Key';
```

**使用方法**:
```dart
final qwenService = QwenVLService();
final result = await qwenService.describeScene(imageFile);
if (result.isSuccess) {
  print('場景描述: ${result.data!.formattedText}');
}
```

### 3. 科大訊飛語音服務

**文件**: `lib/services/ai/xfyun_voice_service.dart`

**功能**:
- ASR語音識別（實時/WebSocket）
- TTS語音合成
- 流式語音合成

**API配置**:
```dart
APIConfig.xfyunAppId = '您的AppID';
APIConfig.xfyunApiKey = '您的API Key';
APIConfig.xfyunApiSecret = '您的API Secret';
```

**使用方法**:
```dart
final voiceService = XfyunVoiceService();

// 語音識別
final result = await voiceService.speechToText(audioFile);

// 語音合成
final ttsResult = await voiceService.textToSpeech('你好，世界');
```

### 4. 真實意圖分類器 (F1)

**文件**: `lib/services/ai/real_intent_classifier.dart`

**功能**:
- 支持12種意圖分類
- 上下文感知
- 緊急度判斷
- 中英文關鍵詞匹配

**支持的意圖類型**:
1. 文字識別 (textRecognition)
2. 物體識別 (objectRecognition)
3. 顏色識別 (colorRecognition)
4. 鈔票識別 (currencyRecognition)
5. 翻譯 (translation)
6. 導航 (navigation)
7. 場景描述 (sceneDescription)
8. 藥品確認 (medicineConfirmation)
9. 醫療問診 (medicalConsultation)
10. 情感陪伴 (emotionalSupport)
11. 緊急求助 (emergency)
12. 通用對話 (generalChat)

**使用方法**:
```dart
final classifier = RealIntentClassifier();
final result = classifier.classify('幫我識別這段文字');
print('意圖: ${result.intent}, 置信度: ${result.confidence}');
```

### 5. 緊急關鍵詞檢測 (F8)

**文件**: `lib/services/ai/real_emergency_detector.dart`

**功能**:
- 本地關鍵詞庫
- 語音情緒分析
- 5秒倒計時確認
- 三級緊急度判斷

**觸發級別**:
- **危急級別**: 立即觸發SOS，無需確認
- **緊急級別**: 5秒倒計時確認
- **情緒危機**: 特別關注，轉人工

**使用方法**:
```dart
final detector = RealEmergencyDetector();

detector.setCallbacks(
  onEmergency: (event) => print('緊急情況: ${event.text}'),
  onConfirmation: (event) => print('需要確認'),
);

final result = detector.detect('我摔倒了，爬不起來');
if (result.isEmergency) {
  print('觸發詞: ${result.triggerWord}');
}
```

## 統一服務管理器

**文件**: `lib/services/ai/real_ai_service_manager.dart`

**功能**:
- 統一管理所有AI服務
- 演示/真實模式切換
- 自動降級策略
- API錯誤處理

**使用方法**:
```dart
// 初始化
final aiManager = RealAIServiceManager.instance;
await aiManager.initialize(AIServiceConfig());

// 配置API密鑰
APIConfig.baiduOcrApiKey = 'xxx';
APIConfig.qwenApiKey = 'xxx';
APIConfig.xfyunAppId = 'xxx';

// 切換到真實模式
aiManager.setRealMode(true);

// 處理請求
final response = await aiManager.processRequest(
  input: '幫我識別這段文字',
  imageUrl: '/path/to/image.jpg',
);

// 語音播報
await aiManager.speak(response.text);
```

## API配置步驟

### 1. 獲取API密鑰

#### 百度OCR
1. 訪問 https://ai.baidu.com/tech/ocr
2. 註冊百度AI開放平臺賬號
3. 創建應用，獲取API Key和Secret Key

#### 通義千問VL
1. 訪問 https://dashscope.aliyun.com/
2. 註冊阿里雲賬號
3. 開通DashScope服務，獲取API Key

#### 科大訊飛
1. 訪問 https://www.xfyun.cn/
2. 註冊訊飛開放平臺賬號
3. 創建應用，獲取AppID、API Key和API Secret

### 2. 配置API密鑰

**方式1: 直接配置**（開發環境）
```dart
import 'package:linklab/config/api_config.dart';

void main() {
  APIConfig.baiduOcrApiKey = 'your_key_here';
  APIConfig.baiduOcrSecretKey = 'your_secret_here';
  APIConfig.qwenApiKey = 'your_key_here';
  APIConfig.xfyunAppId = 'your_app_id';
  APIConfig.xfyunApiKey = 'your_key_here';
  APIConfig.xfyunApiSecret = 'your_secret_here';
}
```

**方式2: 使用initialize方法**
```dart
APIConfig.initialize(
  baiduOcrKey: 'your_key',
  baiduOcrSecret: 'your_secret',
  qwenKey: 'your_key',
  xfyunApp: 'your_app_id',
  xfyunKey: 'your_key',
  xfyunSecret: 'your_secret',
);
```

**方式3: 從安全存儲讀取**（生產環境）
```dart
// 使用flutter_secure_storage或類似方案
final storage = FlutterSecureStorage();
APIConfig.baiduOcrApiKey = await storage.read(key: 'baidu_ocr_key') ?? '';
```

## 降級策略

當API調用失敗時，系統會自動降級到演示模式：

1. **網絡錯誤**: 提示用戶檢查網絡，使用本地模式
2. **認證錯誤**: 提示檢查API密鑰配置
3. **配額不足**: 提示聯繫管理員或稍後再試
4. **服務不可用**: 自動切換到演示模式

## 錯誤處理

所有API調用都返回`APIResponse<T>`包裝類：

```dart
final result = await ocrService.recognizeText(image);

if (result.isSuccess) {
  // 處理成功結果
  print(result.data!.text);
} else {
  // 處理錯誤
  final error = result.error!;
  print('錯誤類型: ${error.type}');
  print('錯誤信息: ${error.message}');
  
  // 根據錯誤類型處理
  switch (error.type) {
    case APIErrorType.networkError:
      // 提示檢查網絡
      break;
    case APIErrorType.authenticationError:
      // 提示檢查API密鑰
      break;
    default:
      // 其他錯誤處理
  }
}
```

## 文件清單

### 核心服務文件
- `lib/config/api_config.dart` - API配置
- `lib/config/api_config.example.dart` - API配置示例
- `lib/services/ai/ai_service.dart` - AI服務接口
- `lib/services/ai/ai_module_export.dart` - 模塊導出

### 真實AI服務實現
- `lib/services/ai/baidu_ocr_service.dart` - 百度OCR
- `lib/services/ai/qwen_vl_service.dart` - 通義千問VL
- `lib/services/ai/xfyun_voice_service.dart` - 科大訊飛語音
- `lib/services/ai/real_intent_classifier.dart` - 真實意圖分類器
- `lib/services/ai/real_emergency_detector.dart` - 真實緊急檢測器
- `lib/services/ai/real_ai_service_manager.dart` - 真實AI服務管理器

### 演示/降級服務
- `lib/services/ai/mock_ai_service.dart` - 模擬AI服務
- `lib/demo_data/ai_responses.dart` - 演示數據

## 注意事項

1. **API密鑰安全**: 不要將真實API密鑰提交到版本控制
2. **配額管理**: 注意各API的調用配額限制
3. **網絡依賴**: 真實AI服務需要網絡連接
4. **錯誤處理**: 始終處理API調用可能的錯誤情況
5. **降級策略**: 確保在API失敗時有良好的用戶體驗

## 測試建議

1. 先使用演示模式驗證功能流程
2. 配置測試環境的API密鑰
3. 測試各種錯誤場景（網絡斷開、密鑰錯誤等）
4. 驗證降級策略是否正常工作
5. 測試緊急關鍵詞檢測的準確性
