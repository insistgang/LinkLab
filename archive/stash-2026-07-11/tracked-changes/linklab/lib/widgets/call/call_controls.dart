// 通话控制组件
// 提供通话过程中的控制按钮（静音、扬声器、录音、挂断等）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/call_models.dart';
import '../../providers/webrtc_call_provider.dart';
import '../demo/linkable_icon.dart';

/// 通话控制按钮配置
class CallControlButton {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? activeLabel;
  final Color? color;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback onPressed;

  CallControlButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.activeLabel,
    this.color,
    this.activeColor,
    this.isActive = false,
    required this.onPressed,
  });
}

/// 通话控制栏
class CallControls extends ConsumerWidget {
  final VoidCallback? onEndCall;
  final bool showRecordingButton;
  final bool compact;

  const CallControls({
    super.key,
    this.onEndCall,
    this.showRecordingButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: compact ? 12 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 网络质量指示器
            if (callState.isConnected)
              _buildNetworkIndicator(context, callState),
            SizedBox(height: compact ? 12 : 20),
            // 控制按钮
            _buildControlButtons(ref, callState),
          ],
        ),
      ),
    );
  }

  /// 构建网络质量指示器
  Widget _buildNetworkIndicator(BuildContext context, CallStateData callState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinkableMaterialIcon(
          icon: getNetworkQualityIcon(callState.networkQuality),
          size: compact ? 14 : 16,
          color: getNetworkQualityColor(callState.networkQuality),
          semanticLabel: getNetworkQualityDescription(callState.networkQuality),
        ),
        const SizedBox(width: 4),
        Text(
          getNetworkQualityDescription(callState.networkQuality),
          style: TextStyle(
            color: getNetworkQualityColor(callState.networkQuality),
            fontSize: compact ? 12 : 14,
          ),
        ),
        if (callState.isRecording) ...[
          const SizedBox(width: 16),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '录音中',
            style: TextStyle(color: Colors.red, fontSize: compact ? 12 : 14),
          ),
        ],
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(WidgetRef ref, CallStateData callState) {
    final buttons = <Widget>[];

    // 静音按钮
    buttons.add(
      _buildControlButton(
        icon: callState.isMuted ? Icons.mic_off : Icons.mic,
        label: callState.isMuted ? '静音中' : '静音',
        isActive: callState.isMuted,
        activeColor: Colors.orange,
        onPressed: () => ref.read(webRTCCallProvider.notifier).toggleMute(),
      ),
    );

    buttons.add(const SizedBox(width: 16));

    // 扬声器按钮
    buttons.add(
      _buildControlButton(
        icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
        label: callState.isSpeakerOn ? '扬声器' : '听筒',
        isActive: callState.isSpeakerOn,
        activeColor: Colors.blue,
        onPressed: () => ref.read(webRTCCallProvider.notifier).toggleSpeaker(),
      ),
    );

    // 录音按钮（可选）
    if (showRecordingButton) {
      buttons.add(const SizedBox(width: 16));
      buttons.add(
        _buildControlButton(
          icon: callState.isRecording
              ? Icons.stop_circle
              : Icons.fiber_manual_record,
          label: callState.isRecording ? '停止录音' : '录音',
          isActive: callState.isRecording,
          activeColor: Colors.red,
          onPressed: () {
            if (callState.isRecording) {
              ref.read(webRTCCallProvider.notifier).stopRecording();
            } else {
              ref.read(webRTCCallProvider.notifier).startRecording();
            }
          },
        ),
      );
    }

    buttons.add(const SizedBox(width: 24));

    // 挂断按钮
    buttons.add(_buildEndCallButton(ref));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons);
  }

  /// 构建单个控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onPressed,
  }) {
    final size = compact ? 48.0 : 64.0;
    final iconSize = compact ? 24.0 : 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? (activeColor ?? Colors.white).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: activeColor ?? Colors.white, width: 2)
                    : null,
              ),
              child: LinkableMaterialIcon(
                icon: icon,
                size: iconSize,
                color: isActive ? (activeColor ?? Colors.white) : Colors.white,
                semanticLabel: label,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 12),
        ),
      ],
    );
  }

  /// 构建挂断按钮
  Widget _buildEndCallButton(WidgetRef ref) {
    final size = compact ? 56.0 : 72.0;
    final iconSize = compact ? 28.0 : 36.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.red,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              ref
                  .read(webRTCCallProvider.notifier)
                  .endCall(CallEndReason.userHangup);
              onEndCall?.call();
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: LinkableMaterialIcon(
                icon: Icons.call_end,
                color: Colors.white,
                size: iconSize,
                semanticLabel: '挂断',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '挂断',
          style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 12),
        ),
      ],
    );
  }
}

/// 简洁的通话控制栏
class CompactCallControls extends StatelessWidget {
  final VoidCallback? onEndCall;

  const CompactCallControls({super.key, this.onEndCall});

  @override
  Widget build(BuildContext context) {
    return CallControls(
      onEndCall: onEndCall,
      showRecordingButton: false,
      compact: true,
    );
  }
}

/// 通话状态显示
class CallStatusDisplay extends ConsumerWidget {
  final bool showDuration;

  const CallStatusDisplay({super.key, this.showDuration = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(webRTCCallProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          callState.stateDescription,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showDuration && callState.isConnected) ...[
          const SizedBox(height: 8),
          Text(
            callState.formattedDuration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
