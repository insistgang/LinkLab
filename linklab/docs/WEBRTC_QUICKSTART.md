# WebRTC 快速开始指南

## 1. 添加依赖

确保 `pubspec.yaml` 中已包含以下依赖：

```yaml
dependencies:
  flutter_webrtc: ^0.12.12
  permission_handler: ^11.4.0
  wakelock_plus: ^1.2.11
  flutter_sound: ^9.28.0
```

## 2. 配置权限

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
<string>需要麦克风权限进行语音通话</string>
```

## 3. 初始化

在 `main.dart` 中初始化通话管理器：

```dart
import 'package:linklab/services/webrtc/webrtc_exports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Supabase
  await Supabase.initialize(...);
  
  // 初始化WebRTC通话管理器
  await WebRTCCallManager().initialize();
  
  runApp(MyApp());
}
```

## 4. 使用Provider管理状态

```dart
import 'package:linklab/providers/webrtc_call_provider.dart';

class CallPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);
    
    return Scaffold(
      body: Column(
        children: [
          Text('状态: ${callState.stateDescription}'),
          Text('时长: ${callState.formattedDuration}'),
          CallControls(),
        ],
      ),
    );
  }
}
```

## 5. 发起通话

### 作为求助者

```dart
await ref.read(webRTCCallProvider.notifier).startCallAsSeeker(
  seekerId: userId,
  helpRequestId: helpRequestId,
  volunteerId: volunteerId,  // 可选
  enableRecording: true,     // 可选：启用录音
);
```

### 作为志愿者

```dart
await ref.read(webRTCCallProvider.notifier).acceptCallAsVolunteer(
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 6. 导航到通话页面

```dart
// 作为求助者发起通话
RealCallPageRoute.startAsSeeker(
  context,
  seekerId: userId,
  helpRequestId: helpRequestId,
);

// 作为志愿者接听通话
RealCallPageRoute.acceptAsVolunteer(
  context,
  volunteerId: userId,
  seekerId: seekerId,
  helpRequestId: helpRequestId,
  roomId: roomId,
);
```

## 7. 通话控制

```dart
// 静音/取消静音
await ref.read(webRTCCallProvider.notifier).toggleMute();

// 切换扬声器
await ref.read(webRTCCallProvider.notifier).toggleSpeaker();

// 开始录音
await ref.read(webRTCCallProvider.notifier).startRecording();

// 停止录音
await ref.read(webRTCCallProvider.notifier).stopRecording();

// 结束通话
await ref.read(webRTCCallProvider.notifier).endCall(CallEndReason.userHangup);
```

## 8. 监听事件

```dart
// 监听通话状态
ref.listen(callStateProvider, (previous, current) {
  if (current == CallState.connected) {
    print('通话已连接');
  } else if (current == CallState.ended) {
    print('通话已结束');
  }
});

// 监听网络质量
ref.listen(networkQualityProvider, (previous, current) {
  print('网络质量: ${getNetworkQualityDescription(current)}');
});

// 监听错误
ref.listen(callErrorProvider, (previous, current) {
  if (current != null) {
    print('通话错误: $current');
  }
});
```

## 9. 双模式切换

应用支持演示模式和真实模式切换：

```dart
import 'package:linklab/services/call_service_factory.dart';

// 切换到真实模式（WebRTC P2P）
CallServiceFactory().useRealMode();

// 切换到演示模式（模拟通话）
CallServiceFactory().useDemoMode();

// 初始化通话服务
await initializeCallService(mode: CallMode.real);
```

## 10. 生产环境配置

### 配置TURN服务器

编辑 `lib/services/webrtc/webrtc_config.dart`：

```dart
static const List<Map<String, dynamic>> turnServers = [
  {
    'urls': 'turn:your-turn-server.com:3478',
    'username': 'your-username',
    'credential': 'your-password',
  },
];
```

### 推荐的TURN服务

- **Coturn**: 开源自建
- **Twilio**: https://www.twilio.com/stun-turn
- **Xirsys**: https://xirsys.com/
- **Metered**: https://www.metered.ca/

## 常见问题

### Q: 无法建立连接
A: 检查STUN/TURN服务器配置，确保防火墙允许UDP端口

### Q: 没有声音
A: 检查麦克风权限，确认音频轨道已启用

### Q: 连接不稳定
A: 配置TURN服务器处理对称NAT，启用ICE候选池

## 参考

- [完整实现文档](./WEBRTC_IMPLEMENTATION.md)
- [WebRTC官方文档](https://webrtc.org/getting-started/overview)
- [flutter_webrtc](https://pub.dev/packages/flutter_webrtc)
