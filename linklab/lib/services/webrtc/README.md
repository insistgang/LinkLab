# WebRTC 服務模塊

> 狀態提示：該模塊屬於實驗性真實 WebRTC 鏈路。競賽 Demo 默認不從這裏建立真實通話，不應把本模塊解讀爲生產級通話能力已完成。

## 文件說明

| 文件 | 說明 |
|------|------|
| `webrtc_config.dart` | WebRTC配置，包含ICE服務器、音頻約束等 |
| `real_webrtc_service.dart` | 真實WebRTC服務，管理PeerConnection |
| `signaling_service.dart` | 信令服務，使用Supabase Realtime |
| `call_recording_service.dart` | 通話錄音服務 |
| `webrtc_call_manager.dart` | 通話管理器，整合所有服務 |
| `webrtc_exports.dart` | 模塊導出文件 |

## 使用方式

```dart
import 'package:linklab/services/webrtc/webrtc_exports.dart';

// 初始化
await WebRTCCallManager().initialize();

// 發起通話
await WebRTCCallManager().startCallAsSeeker(...);

// 接聽通話
await WebRTCCallManager().acceptCallAsVolunteer(...);
```
