# WebRTC 快速開始指南

> 狀態提示：本文僅用於本地實驗真實 WebRTC，不適用於競賽 Demo 默認路徑。競賽和對外演示默認使用 Demo Call，不初始化真實 WebRTC、不要求真實 Supabase Realtime 或 TURN 服務。

## 1. 添加依賴

確保 `pubspec.yaml` 中已包含以下依賴：

```yaml
dependencies:
  flutter_webrtc: ^0.12.12
  permission_handler: ^11.4.0
  wakelock_plus: ^1.2.11
  flutter_sound: ^9.28.0
```

## 2. 配置權限

### Android

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麥克風權限進行語音通話</string>
```

## 3. 初始化

在 `main.dart` 中初始化通話管理器：

```dart
import 'package:linklab/services/webrtc/webrtc_exports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Supabase
  await Supabase.initialize(...);
  
  // 初始化WebRTC通話管理器
  await WebRTCCallManager().initialize();
  
  runApp(MyApp());
}
```

## 4. 使用Provider管理狀態

```dart
import 'package:linklab/providers/webrtc_call_provider.dart';

class CallPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);
    
    return Scaffold(
      body: Column(
        children: [
          Text('狀態: ${callState.stateDescription}'),
          Text('時長: ${callState.formattedDuration}'),
          CallControls(),
        ],
      ),
    );
  }
}
```

## 5. 發起通話

### 作爲求助者

```dart
await ref.read(webRTCCallProvider.notifier).startCallAsSeeker(
  seekerId: userId,
  helpRequestId: helpRequestId,
  volunteerId: volunteerId,  // 可選
  enableRecording: true,     // 可選：啓用錄音
);
```

### 作爲志願者

```dart
await ref.read(webRTCCallProvider.notifier).acceptCallAsVolunteer(
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 6. 導航到通話頁面

```dart
// 作爲求助者發起通話
RealCallPageRoute.startAsSeeker(
  context,
  seekerId: userId,
  helpRequestId: helpRequestId,
);

// 作爲志願者接聽通話
RealCallPageRoute.acceptAsVolunteer(
  context,
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 7. 通話控制

```dart
// 靜音/取消靜音
await ref.read(webRTCCallProvider.notifier).toggleMute();

// 切換揚聲器
await ref.read(webRTCCallProvider.notifier).toggleSpeaker();

// 開始錄音
await ref.read(webRTCCallProvider.notifier).startRecording();

// 停止錄音
await ref.read(webRTCCallProvider.notifier).stopRecording();

// 結束通話
await ref.read(webRTCCallProvider.notifier).endCall(CallEndReason.userHangup);
```

## 8. 監聽事件

```dart
// 監聽通話狀態
ref.listen(callStateProvider, (previous, current) {
  if (current == CallState.connected) {
    print('通話已連接');
  } else if (current == CallState.ended) {
    print('通話已結束');
  }
});

// 監聽網絡質量
ref.listen(networkQualityProvider, (previous, current) {
  print('網絡質量: ${getNetworkQualityDescription(current)}');
});

// 監聽錯誤
ref.listen(callErrorProvider, (previous, current) {
  if (current != null) {
    print('通話錯誤: $current');
  }
});
```

## 9. 雙模式切換

應用支持演示模式和真實模式切換：

```dart
import 'package:linklab/services/call_service_factory.dart';

// 切換到真實模式（WebRTC P2P）
CallServiceFactory().useRealMode();

// 切換到演示模式（模擬通話）
CallServiceFactory().useDemoMode();

// 初始化通話服務
await initializeCallService(mode: CallMode.real);
```

## 10. 生產環境配置

### 配置TURN服務器

編輯 `lib/services/webrtc/webrtc_config.dart`：

```dart
static const List<Map<String, dynamic>> turnServers = [
  {
    'urls': 'turn:your-turn-server.com:3478',
    'username': 'your-username',
    'credential': 'your-password',
  },
];
```

### 推薦的TURN服務

- **Coturn**: 開源自建
- **Twilio**: https://www.twilio.com/stun-turn
- **Xirsys**: https://xirsys.com/
- **Metered**: https://www.metered.ca/

## 常見問題

### Q: 無法建立連接
A: 檢查STUN/TURN服務器配置，確保防火牆允許UDP端口

### Q: 沒有聲音
A: 檢查麥克風權限，確認音頻軌道已啓用

### Q: 連接不穩定
A: 配置TURN服務器處理對稱NAT，啓用ICE候選池

## 參考

- [完整實現文檔](./WEBRTC_IMPLEMENTATION.md)
- [WebRTC官方文檔](https://webrtc.org/getting-started/overview)
- [flutter_webrtc](https://pub.dev/packages/flutter_webrtc)
