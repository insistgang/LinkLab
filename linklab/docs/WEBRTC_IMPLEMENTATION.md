# WebRTC P2P语音通话实现文档

## 概述

本文档描述了共感LinkAble应用中真实WebRTC P2P语音通话功能的实现。

## 架构设计

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                    WebRTCCallManager                        │
│                   (通话管理器 - 统一入口)                     │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
    ┌──────────▼──────────┐      ┌───────────▼────────────┐
    │ RealWebRTCService   │      │   SignalingService     │
    │  (WebRTC核心服务)    │      │   (信令服务)            │
    └──────────┬──────────┘      └───────────┬────────────┘
               │                              │
    ┌──────────▼──────────┐      ┌───────────▼────────────┐
    │ flutter_webrtc      │      │  Supabase Realtime     │
    │  (WebRTC插件)       │      │   (实时通信)            │
    └─────────────────────┘      └────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CallRecordingService                           │
│               (通话录音服务 - 可选)                          │
└─────────────────────────────────────────────────────────────┘
```

## 文件结构

```
lib/
├── services/
│   └── webrtc/
│       ├── webrtc_config.dart           # WebRTC配置
│       ├── real_webrtc_service.dart     # 真实WebRTC服务
│       ├── signaling_service.dart       # 信令服务
│       ├── call_recording_service.dart  # 录音服务
│       ├── webrtc_call_manager.dart     # 通话管理器
│       └── webrtc_exports.dart          # 导出文件
├── providers/
│   └── webrtc_call_provider.dart        # Riverpod状态管理
├── widgets/
│   └── call/
│       └── call_controls.dart           # 通话控制组件
├── pages/
│   └── call/
│       └── real_call_page.dart          # 真实通话页面
└── models/
    └── call_models.dart                 # 通话数据模型
```

## 核心功能实现

### 1. WebRTC配置 (webrtc_config.dart)

```dart
class WebRTCConfig {
  // STUN服务器配置
  static const List<Map<String, dynamic>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    // ...
  ];

  // TURN服务器配置（生产环境需要）
  static const List<Map<String, dynamic>> turnServers = [
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'your-username',
    //   'credential': 'your-password',
    // },
  ];

  // 音频约束配置
  static Map<String, dynamic> get audioConstraints => {
    'audio': {
      'echoCancellation': true,      // 回声消除
      'noiseSuppression': true,      // 噪声抑制
      'autoGainControl': true,       // 自动增益控制
      'sampleRate': 48000,
      'channelCount': 2,
    },
    'video': false,
  };
}
```

### 2. WebRTC服务 (real_webrtc_service.dart)

核心功能：
- PeerConnection管理
- Offer/Answer处理
- ICE候选处理
- 媒体流管理
- 通话状态监听
- 统计信息收集

```dart
class RealWebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 初始化通话
  Future<CallInfo> initializeCallAsSeeker({...});
  Future<CallInfo> initializeCallAsVolunteer({...});

  // 信令处理
  Future<void> createOffer();
  Future<void> handleOffer(String sdp, String type);
  Future<void> handleAnswer(String sdp, String type);
  Future<void> addIceCandidate(String candidate, String? sdpMid, int? sdpMLineIndex);

  // 通话控制
  Future<void> endCall(CallEndReason reason);
  Future<bool> toggleMute();
  Future<bool> toggleSpeaker();
}
```

### 3. 信令服务 (signaling_service.dart)

使用Supabase Realtime进行信令交换：

```dart
class SignalingService {
  // 加入/离开房间
  Future<void> joinRoom(String roomId, {CallRole? role});
  Future<void> leaveRoom();

  // 发送信令消息
  Future<void> sendOffer(String roomId, String sdp, String type);
  Future<void> sendAnswer(String roomId, String sdp, String type);
  Future<void> sendIceCandidate(String roomId, String candidate, {...});
  Future<void> sendBye(String roomId, {CallEndReason? reason});
}
```

信令流程：
1. 求助者创建房间并加入
2. 志愿者加入房间
3. 求助者创建并发送Offer
4. 志愿者接收Offer，创建并发送Answer
5. 双方交换ICE候选
6. 建立P2P连接

### 4. 通话录音服务 (call_recording_service.dart)

```dart
class CallRecordingService {
  Future<RecordingInfo?> startRecording();
  Future<RecordingInfo?> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();

  // 录音状态流
  Stream<RecordingState> get stateStream;
  Stream<Duration> get durationStream;
  Stream<double> get levelStream;  // 音量电平
}
```

### 5. 通话管理器 (webrtc_call_manager.dart)

整合所有服务的统一入口：

```dart
class WebRTCCallManager {
  // 初始化
  Future<void> initialize();

  // 发起/接听通话
  Future<CallInfo> startCallAsSeeker({...});
  Future<CallInfo> acceptCallAsVolunteer({...});

  // 结束通话
  Future<void> endCall(CallEndReason reason);

  // 媒体控制
  Future<bool> toggleMute();
  Future<bool> toggleSpeaker();

  // 录音控制
  Future<RecordingInfo?> startRecording();
  Future<RecordingInfo?> stopRecording();

  // 事件流
  Stream<CallManagerEvent> get eventStream;
  Stream<CallState> get callStateStream;
  Stream<NetworkQuality> get networkQualityStream;
}
```

## 使用方法

### 1. 在main.dart中初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Supabase
  await Supabase.initialize(...);

  // 初始化通话管理器
  await WebRTCCallManager().initialize();

  runApp(MyApp());
}
```

### 2. 使用Provider管理状态

```dart
class CallPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);

    return Scaffold(
      body: Column(
        children: [
          // 显示通话状态
          Text(callState.stateDescription),
          Text(callState.formattedDuration),

          // 控制按钮
          CallControls(),
        ],
      ),
    );
  }
}
```

### 3. 发起通话（求助者）

```dart
await ref.read(webRTCCallProvider.notifier).startCallAsSeeker(
  seekerId: userId,
  helpRequestId: helpRequestId,
  volunteerId: volunteerId,
  enableRecording: true,  // 可选：启用录音
);
```

### 4. 接听通话（志愿者）

```dart
await ref.read(webRTCCallProvider.notifier).acceptCallAsVolunteer(
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
  enableRecording: false,
);
```

### 5. 导航到通话页面

```dart
// 作为求助者
RealCallPageRoute.startAsSeeker(
  context,
  seekerId: userId,
  helpRequestId: helpRequestId,
);

// 作为志愿者
RealCallPageRoute.acceptAsVolunteer(
  context,
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 权限配置

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 音频权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- 存储权限（录音） -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- 前台服务（保持通话） -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限进行语音通话</string>

<key>NSCameraUsageDescription</key>
<string>需要相机权限（仅语音通话不需要）</string>
```

## 生产环境配置

### 1. 配置TURN服务器

在 `webrtc_config.dart` 中配置自己的TURN服务器：

```dart
static const List<Map<String, dynamic>> turnServers = [
  {
    'urls': 'turn:your-turn-server.com:3478',
    'username': 'your-username',
    'credential': 'your-password',
  },
  {
    'urls': 'turns:your-turn-server.com:5349',  // TLS
    'username': 'your-username',
    'credential': 'your-password',
  },
];
```

推荐的TURN服务器：
- Coturn (开源自建)
- Twilio STUN/TURN
- Xirsys
- Metered.ca

### 2. Supabase Realtime配置

确保Supabase项目中启用了Realtime功能：

```sql
-- 启用Realtime（在Supabase Dashboard中）
-- Database -> Replication -> Realtime
```

## 调试与监控

### 日志输出

所有组件都会输出详细的日志，格式为：

```
[WebRTC] 消息内容
[Signaling] 消息内容
[Recording] 消息内容
[CallManager] 消息内容
```

### 网络质量监控

```dart
// 监听网络质量
ref.listen(networkQualityProvider, (previous, current) {
  print('网络质量: ${getNetworkQualityDescription(current)}');
});

// 监听通话统计
ref.listen(webRTCCallProvider.select((s) => s.duration), (previous, current) {
  print('通话时长: $current');
});
```

### 通话统计信息

```dart
final stats = await WebRTCCallManager().getCurrentStats();
print('接收: ${stats?.bytesReceived} bytes');
print('发送: ${stats?.bytesSent} bytes');
print('丢包率: ${stats?.packetLoss}%');
```

## 常见问题

### 1. 无法建立连接

- 检查STUN/TURN服务器配置
- 确认防火墙允许UDP端口
- 检查网络类型（对称NAT需要TURN）

### 2. 没有声音

- 检查麦克风权限
- 确认音频轨道已启用
- 检查静音状态

### 3. 连接断开

- 实现自动重连机制
- 监控网络状态变化
- 处理ICE连接失败

### 4. 录音失败

- 检查存储权限
- 确认录音目录存在
- 检查磁盘空间

## 性能优化

1. **音频处理优化**
   - 启用回声消除和噪声抑制
   - 使用合适的采样率和比特率
   - 根据网络质量动态调整

2. **连接优化**
   - 配置多个STUN/TURN服务器
   - 使用ICE候选池
   - 设置合理的超时时间

3. **资源管理**
   - 及时释放媒体流
   - 关闭不再使用的PeerConnection
   - 取消未完成的订阅

## 安全注意事项

1. **信令安全**
   - 使用Supabase RLS保护信令数据
   - 验证用户身份
   - 限制房间访问权限

2. **媒体安全**
   - 使用DTLS-SRTP加密媒体
   - 不存储敏感通话内容
   - 录音文件加密存储

3. **隐私保护**
   - 获取用户录音同意
   - 提供录音删除功能
   - 遵守数据保护法规

## 参考文档

- [WebRTC官方文档](https://webrtc.org/getting-started/overview)
- [flutter_webrtc插件](https://pub.dev/packages/flutter_webrtc)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [WebRTC信令流程](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Signaling_and_video_calling)
