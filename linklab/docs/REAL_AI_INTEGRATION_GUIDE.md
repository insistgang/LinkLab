# 真实AI服务集成指南

## 概述

本文档介绍如何在LinkAble应用中集成真实的AI API服务，替换演示版的模拟数据。

## 已实现的AI服务

### 1. 百度OCR服务 (F2)

**文件**: `lib/services/ai/baidu_ocr_service.dart`

**功能**:
- 通用文字识别（标准版）
- 高精度文字识别
- 手写体识别
- 身份证识别
- 银行卡识别
- 营业执照识别

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
  print('识别结果: ${result.data!.text}');
}
```

### 2. 通义千问VL服务 (F3/F7)

**文件**: `lib/services/ai/qwen_vl_service.dart`

**功能**:
- 场景描述
- 物体识别
- 问答功能
- 空间布局分析

**API配置**:
```dart
APIConfig.qwenApiKey = '您的API Key';
```

**使用方法**:
```dart
final qwenService = QwenVLService();
final result = await qwenService.describeScene(imageFile);
if (result.isSuccess) {
  print('场景描述: ${result.data!.formattedText}');
}
```

### 3. 科大讯飞语音服务

**文件**: `lib/services/ai/xfyun_voice_service.dart`

**功能**:
- ASR语音识别（实时/WebSocket）
- TTS语音合成
- 流式语音合成

**API配置**:
```dart
APIConfig.xfyunAppId = '您的AppID';
APIConfig.xfyunApiKey = '您的API Key';
APIConfig.xfyunApiSecret = '您的API Secret';
```

**使用方法**:
```dart
final voiceService = XfyunVoiceService();

// 语音识别
final result = await voiceService.speechToText(audioFile);

// 语音合成
final ttsResult = await voiceService.textToSpeech('你好，世界');
```

### 4. 真实意图分类器 (F1)

**文件**: `lib/services/ai/real_intent_classifier.dart`

**功能**:
- 支持12种意图分类
- 上下文感知
- 紧急度判断
- 中英文关键词匹配

**支持的意图类型**:
1. 文字识别 (textRecognition)
2. 物体识别 (objectRecognition)
3. 颜色识别 (colorRecognition)
4. 钞票识别 (currencyRecognition)
5. 翻译 (translation)
6. 导航 (navigation)
7. 场景描述 (sceneDescription)
8. 药品确认 (medicineConfirmation)
9. 医疗问诊 (medicalConsultation)
10. 情感陪伴 (emotionalSupport)
11. 紧急求助 (emergency)
12. 通用对话 (generalChat)

**使用方法**:
```dart
final classifier = RealIntentClassifier();
final result = classifier.classify('帮我识别这段文字');
print('意图: ${result.intent}, 置信度: ${result.confidence}');
```

### 5. 紧急关键词检测 (F8)

**文件**: `lib/services/ai/real_emergency_detector.dart`

**功能**:
- 本地关键词库
- 语音情绪分析
- 5秒倒计时确认
- 三级紧急度判断

**触发级别**:
- **危急级别**: 立即触发SOS，无需确认
- **紧急级别**: 5秒倒计时确认
- **情绪危机**: 特别关注，转人工

**使用方法**:
```dart
final detector = RealEmergencyDetector();

detector.setCallbacks(
  onEmergency: (event) => print('紧急情况: ${event.text}'),
  onConfirmation: (event) => print('需要确认'),
);

final result = detector.detect('我摔倒了，爬不起来');
if (result.isEmergency) {
  print('触发词: ${result.triggerWord}');
}
```

## 统一服务管理器

**文件**: `lib/services/ai/real_ai_service_manager.dart`

**功能**:
- 统一管理所有AI服务
- 演示/真实模式切换
- 自动降级策略
- API错误处理

**使用方法**:
```dart
// 初始化
final aiManager = RealAIServiceManager.instance;
await aiManager.initialize(AIServiceConfig());

// 配置API密钥
APIConfig.baiduOcrApiKey = 'xxx';
APIConfig.qwenApiKey = 'xxx';
APIConfig.xfyunAppId = 'xxx';

// 切换到真实模式
aiManager.setRealMode(true);

// 处理请求
final response = await aiManager.processRequest(
  input: '帮我识别这段文字',
  imageUrl: '/path/to/image.jpg',
);

// 语音播报
await aiManager.speak(response.text);
```

## API配置步骤

### 1. 获取API密钥

#### 百度OCR
1. 访问 https://ai.baidu.com/tech/ocr
2. 注册百度AI开放平台账号
3. 创建应用，获取API Key和Secret Key

#### 通义千问VL
1. 访问 https://dashscope.aliyun.com/
2. 注册阿里云账号
3. 开通DashScope服务，获取API Key

#### 科大讯飞
1. 访问 https://www.xfyun.cn/
2. 注册讯飞开放平台账号
3. 创建应用，获取AppID、API Key和API Secret

### 2. 配置API密钥

**方式1: 直接配置**（开发环境）
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

**方式3: 从安全存储读取**（生产环境）
```dart
// 使用flutter_secure_storage或类似方案
final storage = FlutterSecureStorage();
APIConfig.baiduOcrApiKey = await storage.read(key: 'baidu_ocr_key') ?? '';
```

## 降级策略

当API调用失败时，系统会自动降级到演示模式：

1. **网络错误**: 提示用户检查网络，使用本地模式
2. **认证错误**: 提示检查API密钥配置
3. **配额不足**: 提示联系管理员或稍后再试
4. **服务不可用**: 自动切换到演示模式

## 错误处理

所有API调用都返回`APIResponse<T>`包装类：

```dart
final result = await ocrService.recognizeText(image);

if (result.isSuccess) {
  // 处理成功结果
  print(result.data!.text);
} else {
  // 处理错误
  final error = result.error!;
  print('错误类型: ${error.type}');
  print('错误信息: ${error.message}');
  
  // 根据错误类型处理
  switch (error.type) {
    case APIErrorType.networkError:
      // 提示检查网络
      break;
    case APIErrorType.authenticationError:
      // 提示检查API密钥
      break;
    default:
      // 其他错误处理
  }
}
```

## 文件清单

### 核心服务文件
- `lib/config/api_config.dart` - API配置
- `lib/config/api_config.example.dart` - API配置示例
- `lib/services/ai/ai_service.dart` - AI服务接口
- `lib/services/ai/ai_module_export.dart` - 模块导出

### 真实AI服务实现
- `lib/services/ai/baidu_ocr_service.dart` - 百度OCR
- `lib/services/ai/qwen_vl_service.dart` - 通义千问VL
- `lib/services/ai/xfyun_voice_service.dart` - 科大讯飞语音
- `lib/services/ai/real_intent_classifier.dart` - 真实意图分类器
- `lib/services/ai/real_emergency_detector.dart` - 真实紧急检测器
- `lib/services/ai/real_ai_service_manager.dart` - 真实AI服务管理器

### 演示/降级服务
- `lib/services/ai/mock_ai_service.dart` - 模拟AI服务
- `lib/demo_data/ai_responses.dart` - 演示数据

## 注意事项

1. **API密钥安全**: 不要将真实API密钥提交到版本控制
2. **配额管理**: 注意各API的调用配额限制
3. **网络依赖**: 真实AI服务需要网络连接
4. **错误处理**: 始终处理API调用可能的错误情况
5. **降级策略**: 确保在API失败时有良好的用户体验

## 测试建议

1. 先使用演示模式验证功能流程
2. 配置测试环境的API密钥
3. 测试各种错误场景（网络断开、密钥错误等）
4. 验证降级策略是否正常工作
5. 测试紧急关键词检测的准确性
