// 通話控制組件
// 提供通話過程中的控制按鈕（靜音、揚聲器、錄音、掛斷等）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/call_models.dart';
import '../../providers/webrtc_call_provider.dart';
import '../demo/linkable_icon.dart';

/// 通話控制按鈕配置
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

/// 通話控制欄
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
            // 網絡質量指示器
            if (callState.isConnected)
              _buildNetworkIndicator(context, callState),
            SizedBox(height: compact ? 12 : 20),
            // 控制按鈕
            _buildControlButtons(ref, callState),
          ],
        ),
      ),
    );
  }

  /// 構建網絡質量指示器
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
            '錄音中',
            style: TextStyle(color: Colors.red, fontSize: compact ? 12 : 14),
          ),
        ],
      ],
    );
  }

  /// 構建控制按鈕
  Widget _buildControlButtons(WidgetRef ref, CallStateData callState) {
    final buttons = <Widget>[];

    // 靜音按鈕
    buttons.add(
      _buildControlButton(
        icon: callState.isMuted ? Icons.mic_off : Icons.mic,
        label: callState.isMuted ? '靜音中' : '靜音',
        isActive: callState.isMuted,
        activeColor: Colors.orange,
        onPressed: () => ref.read(webRTCCallProvider.notifier).toggleMute(),
      ),
    );

    buttons.add(const SizedBox(width: 16));

    // 揚聲器按鈕
    buttons.add(
      _buildControlButton(
        icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
        label: callState.isSpeakerOn ? '揚聲器' : '聽筒',
        isActive: callState.isSpeakerOn,
        activeColor: Colors.blue,
        onPressed: () => ref.read(webRTCCallProvider.notifier).toggleSpeaker(),
      ),
    );

    // 錄音按鈕（可選）
    if (showRecordingButton) {
      buttons.add(const SizedBox(width: 16));
      buttons.add(
        _buildControlButton(
          icon: callState.isRecording
              ? Icons.stop_circle
              : Icons.fiber_manual_record,
          label: callState.isRecording ? '停止錄音' : '錄音',
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

    // 掛斷按鈕
    buttons.add(_buildEndCallButton(ref));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons);
  }

  /// 構建單個控制按鈕
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

  /// 構建掛斷按鈕
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
                semanticLabel: '掛斷',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '掛斷',
          style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 12),
        ),
      ],
    );
  }
}

/// 簡潔的通話控制欄
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

/// 通話狀態顯示
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
