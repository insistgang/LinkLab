# WebRTC 服务模块

> 状态提示：该模块属于实验性真实 WebRTC 链路。竞赛 Demo 默认不从这里建立真实通话，不应把本模块解读为生产级通话能力已完成。

## 文件说明

| 文件 | 说明 |
|------|------|
| `webrtc_config.dart` | WebRTC配置，包含ICE服务器、音频约束等 |
| `real_webrtc_service.dart` | 真实WebRTC服务，管理PeerConnection |
| `signaling_service.dart` | 信令服务，使用Supabase Realtime |
| `call_recording_service.dart` | 通话录音服务 |
| `webrtc_call_manager.dart` | 通话管理器，整合所有服务 |
| `webrtc_exports.dart` | 模块导出文件 |

## 使用方式

```dart
import 'package:linklab/services/webrtc/webrtc_exports.dart';

// 初始化
await WebRTCCallManager().initialize();

// 发起通话
await WebRTCCallManager().startCallAsSeeker(...);

// 接听通话
await WebRTCCallManager().acceptCallAsVolunteer(...);
```
