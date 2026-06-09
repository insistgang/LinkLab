# WebRTC P2P語音通話實現文檔

> 狀態提示：本文描述的是實驗性真實 WebRTC 設計與接入思路，不是競賽 Demo 或生產上線證明。當前默認演示走 Demo Call 狀態機；真實 WebRTC 依賴 Supabase Realtime、設備權限、ICE/TURN 和弱網驗證，需單獨驗收。

## 概述

本文檔描述了共感LinkAble應用中真實WebRTC P2P語音通話功能的實驗實現。

## 架構設計

### 核心組件

```
┌─────────────────────────────────────────────────────────────┐
│                    WebRTCCallManager                        │
│                   (通話管理器 - 統一入口)                     │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
    ┌──────────▼──────────┐      ┌───────────▼────────────┐
    │ RealWebRTCService   │      │   SignalingService     │
    │  (WebRTC核心服務)    │      │   (信令服務)            │
    └──────────┬──────────┘      └───────────┬────────────┘
               │                              │
    ┌──────────▼──────────┐      ┌───────────▼────────────┐
    │ flutter_webrtc      │      │  Supabase Realtime     │
    │  (WebRTC插件)       │      │   (實時通信)            │
    └─────────────────────┘      └────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CallRecordingService                           │
│               (通話錄音服務 - 可選)                          │
└─────────────────────────────────────────────────────────────┘
```

## 文件結構

```
lib/
├── services/
│   └── webrtc/
│       ├── webrtc_config.dart           # WebRTC配置
│       ├── real_webrtc_service.dart     # 真實WebRTC服務
│       ├── signaling_service.dart       # 信令服務
│       ├── call_recording_service.dart  # 錄音服務
│       ├── webrtc_call_manager.dart     # 通話管理器
│       └── webrtc_exports.dart          # 導出文件
├── providers/
│   └── webrtc_call_provider.dart        # Riverpod狀態管理
├── widgets/
│   └── call/
│       └── call_controls.dart           # 通話控制組件
├── pages/
│   └── call/
│       └── real_call_page.dart          # 真實通話頁面
└── models/
    └── call_models.dart                 # 通話數據模型
```

## 核心功能實現

### 1. WebRTC配置 (webrtc_config.dart)

```dart
class WebRTCConfig {
  // STUN服務器配置
  static const List<Map<String, dynamic>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    // ...
  ];

  // TURN服務器配置（生產環境需要）
  static const List<Map<String, dynamic>> turnServers = [
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'your-username',
    //   'credential': 'your-password',
    // },
  ];

  // 音頻約束配置
  static Map<String, dynamic> get audioConstraints => {
    'audio': {
      'echoCancellation': true,      // 回聲消除
      'noiseSuppression': true,      // 噪聲抑制
      'autoGainControl': true,       // 自動增益控制
      'sampleRate': 48000,
      'channelCount': 2,
    },
    'video': false,
  };
}
```

### 2. WebRTC服務 (real_webrtc_service.dart)

核心功能：
- PeerConnection管理
- Offer/Answer處理
- ICE候選處理
- 媒體流管理
- 通話狀態監聽
- 統計信息收集

```dart
class RealWebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 初始化通話
  Future<CallInfo> initializeCallAsSeeker({...});
  Future<CallInfo> initializeCallAsVolunteer({...});

  // 信令處理
  Future<void> createOffer();
  Future<void> handleOffer(String sdp, String type);
  Future<void> handleAnswer(String sdp, String type);
  Future<void> addIceCandidate(String candidate, String? sdpMid, int? sdpMLineIndex);

  // 通話控制
  Future<void> endCall(CallEndReason reason);
  Future<bool> toggleMute();
  Future<bool> toggleSpeaker();
}
```

### 3. 信令服務 (signaling_service.dart)

使用Supabase Realtime進行信令交換：

```dart
class SignalingService {
  // 加入/離開房間
  Future<void> joinRoom(String roomId, {CallRole? role});
  Future<void> leaveRoom();

  // 發送信令消息
  Future<void> sendOffer(String roomId, String sdp, String type);
  Future<void> sendAnswer(String roomId, String sdp, String type);
  Future<void> sendIceCandidate(String roomId, String candidate, {...});
  Future<void> sendBye(String roomId, {CallEndReason? reason});
}
```

信令流程：
1. 求助者創建房間並加入
2. 志願者加入房間
3. 求助者創建併發送Offer
4. 志願者接收Offer，創建併發送Answer
5. 雙方交換ICE候選
6. 建立P2P連接

### 4. 通話錄音服務 (call_recording_service.dart)

```dart
class CallRecordingService {
  Future<RecordingInfo?> startRecording();
  Future<RecordingInfo?> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();

  // 錄音狀態流
  Stream<RecordingState> get stateStream;
  Stream<Duration> get durationStream;
  Stream<double> get levelStream;  // 音量電平
}
```

### 5. 通話管理器 (webrtc_call_manager.dart)

整合所有服務的統一入口：

```dart
class WebRTCCallManager {
  // 初始化
  Future<void> initialize();

  // 發起/接聽通話
  Future<CallInfo> startCallAsSeeker({...});
  Future<CallInfo> acceptCallAsVolunteer({...});

  // 結束通話
  Future<void> endCall(CallEndReason reason);

  // 媒體控制
  Future<bool> toggleMute();
  Future<bool> toggleSpeaker();

  // 錄音控制
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

  // 初始化通話管理器
  await WebRTCCallManager().initialize();

  runApp(MyApp());
}
```

### 2. 使用Provider管理狀態

```dart
class CallPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);

    return Scaffold(
      body: Column(
        children: [
          // 顯示通話狀態
          Text(callState.stateDescription),
          Text(callState.formattedDuration),

          // 控制按鈕
          CallControls(),
        ],
      ),
    );
  }
}
```

### 3. 發起通話（求助者）

```dart
await ref.read(webRTCCallProvider.notifier).startCallAsSeeker(
  seekerId: userId,
  helpRequestId: helpRequestId,
  volunteerId: volunteerId,
  enableRecording: true,  // 可選：啓用錄音
);
```

### 4. 接聽通話（志願者）

```dart
await ref.read(webRTCCallProvider.notifier).acceptCallAsVolunteer(
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
  enableRecording: false,
);
```

### 5. 導航到通話頁面

```dart
// 作爲求助者
RealCallPageRoute.startAsSeeker(
  context,
  seekerId: userId,
  helpRequestId: helpRequestId,
);

// 作爲志願者
RealCallPageRoute.acceptAsVolunteer(
  context,
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 權限配置

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- 網絡權限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 音頻權限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- 存儲權限（錄音） -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- 前臺服務（保持通話） -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麥克風權限進行語音通話</string>

<key>NSCameraUsageDescription</key>
<string>需要相機權限（僅語音通話不需要）</string>
```

## 生產環境配置

### 1. 配置TURN服務器

在 `webrtc_config.dart` 中配置自己的TURN服務器：

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

推薦的TURN服務器：
- Coturn (開源自建)
- Twilio STUN/TURN
- Xirsys
- Metered.ca

### 2. Supabase Realtime配置

確保Supabase項目中啓用了Realtime功能：

```sql
-- 啓用Realtime（在Supabase Dashboard中）
-- Database -> Replication -> Realtime
```

## 調試與監控

### 日誌輸出

所有組件都會輸出詳細的日誌，格式爲：

```
[WebRTC] 消息內容
[Signaling] 消息內容
[Recording] 消息內容
[CallManager] 消息內容
```

### 網絡質量監控

```dart
// 監聽網絡質量
ref.listen(networkQualityProvider, (previous, current) {
  print('網絡質量: ${getNetworkQualityDescription(current)}');
});

// 監聽通話統計
ref.listen(webRTCCallProvider.select((s) => s.duration), (previous, current) {
  print('通話時長: $current');
});
```

### 通話統計信息

```dart
final stats = await WebRTCCallManager().getCurrentStats();
print('接收: ${stats?.bytesReceived} bytes');
print('發送: ${stats?.bytesSent} bytes');
print('丟包率: ${stats?.packetLoss}%');
```

## 常見問題

### 1. 無法建立連接

- 檢查STUN/TURN服務器配置
- 確認防火牆允許UDP端口
- 檢查網絡類型（對稱NAT需要TURN）

### 2. 沒有聲音

- 檢查麥克風權限
- 確認音頻軌道已啓用
- 檢查靜音狀態

### 3. 連接斷開

- 實現自動重連機制
- 監控網絡狀態變化
- 處理ICE連接失敗

### 4. 錄音失敗

- 檢查存儲權限
- 確認錄音目錄存在
- 檢查磁盤空間

## 性能優化

1. **音頻處理優化**
   - 啓用回聲消除和噪聲抑制
   - 使用合適的採樣率和比特率
   - 根據網絡質量動態調整

2. **連接優化**
   - 配置多個STUN/TURN服務器
   - 使用ICE候選池
   - 設置合理的超時時間

3. **資源管理**
   - 及時釋放媒體流
   - 關閉不再使用的PeerConnection
   - 取消未完成的訂閱

## 安全注意事項

1. **信令安全**
   - 使用Supabase RLS保護信令數據
   - 驗證用戶身份
   - 限制房間訪問權限

2. **媒體安全**
   - 使用DTLS-SRTP加密媒體
   - 不存儲敏感通話內容
   - 錄音文件加密存儲

3. **隱私保護**
   - 獲取用戶錄音同意
   - 提供錄音刪除功能
   - 遵守數據保護法規

## 參考文檔

- [WebRTC官方文檔](https://webrtc.org/getting-started/overview)
- [flutter_webrtc插件](https://pub.dev/packages/flutter_webrtc)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [WebRTC信令流程](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Signaling_and_video_calling)
