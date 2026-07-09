// 统一通话页面入口
// 根据配置自动选择演示版或真实版通话页面

import 'package:flutter/material.dart';

import '../../models/call_models.dart';
import '../../services/call_service_factory.dart';
import 'real_call_page.dart';

/// 通话页面参数
class CallPageArgs {
  final String helpRequestId;
  final String? roomId;
  final CallRole myRole;
  final String? seekerId;
  final String? volunteerId;
  final bool enableRecording;

  const CallPageArgs({
    required this.helpRequestId,
    this.roomId,
    required this.myRole,
    this.seekerId,
    this.volunteerId,
    this.enableRecording = false,
  });
}

/// 统一通话页面
/// 根据当前通话模式自动选择演示版或真实版
class CallPage extends StatelessWidget {
  final CallPageArgs args;

  const CallPage({
    super.key,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    final mode = CallServiceFactory().currentMode;

    switch (mode) {
      case CallMode.real:
        // 真实模式：使用WebRTC P2P通话
        return RealCallPage(
          args: RealCallPageArgs(
            helpRequestId: args.helpRequestId,
            roomId: args.roomId ?? '',
            myRole: args.myRole,
            seekerId: args.seekerId,
            volunteerId: args.volunteerId,
            enableRecording: args.enableRecording,
          ),
        );

      case CallMode.demo:
        // 演示模式：导航到演示版通话页面
        // 注意：演示版页面在screens目录中
        return _DemoCallPageWrapper();
    }
  }
}

/// 演示版通话页面包装器
class _DemoCallPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 演示版页面在screens/call/demo_call_screen.dart
    // 这里返回一个占位页面，实际使用时需要导入演示版页面
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_in_talk,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                '演示模式',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请使用 DemoCallScreen',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 通话页面路由
class CallPageRoute {
  /// 导航到通话页面（作为求助者）
  static Future<bool?> startAsSeeker(
    BuildContext context, {
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    final mode = CallServiceFactory().currentMode;

    if (mode == CallMode.real) {
      return RealCallPageRoute.startAsSeeker(
        context,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteerId,
        enableRecording: enableRecording,
      );
    } else {
      // 演示模式：导航到演示版页面
      // 实际使用时替换为演示版页面路由
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CallPage(
            args: CallPageArgs(
              helpRequestId: helpRequestId,
              myRole: CallRole.seeker,
              seekerId: seekerId,
              volunteerId: volunteerId,
              enableRecording: enableRecording,
            ),
          ),
        ),
      );
    }
  }

  /// 导航到通话页面（作为志愿者）
  static Future<bool?> acceptAsVolunteer(
    BuildContext context, {
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    final mode = CallServiceFactory().currentMode;

    if (mode == CallMode.real) {
      return RealCallPageRoute.acceptAsVolunteer(
        context,
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
        enableRecording: enableRecording,
      );
    } else {
      // 演示模式：导航到演示版页面
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CallPage(
            args: CallPageArgs(
              helpRequestId: helpRequestId,
              roomId: roomId,
              myRole: CallRole.volunteer,
              seekerId: seekerId,
              volunteerId: volunteerId,
              enableRecording: enableRecording,
            ),
          ),
        ),
      );
    }
  }
}
