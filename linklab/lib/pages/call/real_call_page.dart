// 真实WebRTC通话页面
// 使用 RealWebRTCService 进行 P2P 语音通话

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/call_models.dart';
import '../../providers/webrtc_call_provider.dart';
import '../../widgets/call/call_controls.dart';

/// 真实通话页面参数
class RealCallPageArgs {
  final String helpRequestId;
  final String roomId;
  final CallRole myRole;
  final String? seekerId;
  final String? volunteerId;
  final bool enableRecording;

  RealCallPageArgs({
    required this.helpRequestId,
    required this.roomId,
    required this.myRole,
    this.seekerId,
    this.volunteerId,
    this.enableRecording = false,
  });
}

/// 真实WebRTC通话页面
class RealCallPage extends ConsumerStatefulWidget {
  final RealCallPageArgs args;

  const RealCallPage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<RealCallPage> createState() => _RealCallPageState();
}

class _RealCallPageState extends ConsumerState<RealCallPage> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  /// 初始化通话
  Future<void> _initializeCall() async {
    try {
      if (widget.args.myRole == CallRole.seeker) {
        // 作为求助者发起通话
        await ref.read(webRTCCallProvider.notifier).startCallAsSeeker(
              seekerId: widget.args.seekerId!,
              helpRequestId: widget.args.helpRequestId,
              volunteerId: widget.args.volunteerId,
              enableRecording: widget.args.enableRecording,
            );
      } else {
        // 作为志愿者接听通话
        await ref.read(webRTCCallProvider.notifier).acceptCallAsVolunteer(
              volunteerId: widget.args.volunteerId!,
              seekerId: widget.args.seekerId!,
              helpRequestId: widget.args.helpRequestId,
              roomId: widget.args.roomId,
              enableRecording: widget.args.enableRecording,
            );
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(webRTCCallProvider);

    // 监听通话结束
    ref.listen(webRTCCallProvider, (previous, current) {
      if (current.state == CallState.ended ||
          current.state == CallState.failed) {
        // 延迟返回，让用户看到结束状态
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(current.state == CallState.ended);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部信息栏
            _buildHeader(callState),

            // 主要内容区域
            Expanded(
              child: _buildContent(callState),
            ),

            // 底部控制栏
            CallControls(
              onEndCall: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildHeader(CallStateData callState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () => _showEndCallDialog(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),

          const Spacer(),

          // 网络质量指示
          if (callState.isConnected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getNetworkQualityIcon(callState.networkQuality),
                  color: getNetworkQualityColor(callState.networkQuality),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  getNetworkQualityDescription(callState.networkQuality),
                  style: TextStyle(
                    color: getNetworkQualityColor(callState.networkQuality),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

          const Spacer(),

          // 占位，保持对称
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// 构建主要内容区域
  Widget _buildContent(CallStateData callState) {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 对方头像
        _buildAvatar(),

        const SizedBox(height: 32),

        // 对方名称/角色
        Text(
          widget.args.myRole == CallRole.seeker ? '志愿者' : '求助者',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // 通话状态
        CallStatusDisplay(showDuration: callState.isConnected),

        const SizedBox(height: 32),

        // 连接状态指示器
        if (callState.isConnecting) _buildConnectingIndicator(),

        // 错误提示
        if (callState.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              callState.error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 64,
        color: Colors.white54,
      ),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            '正在初始化通话...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '通话初始化失败',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              _initializeCall();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建连接指示器
  Widget _buildConnectingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text(
            '正在建立连接...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示结束通话对话框
  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束通话'),
        content: const Text('确定要结束当前通话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(webRTCCallProvider.notifier)
                  .endCall(CallEndReason.userHangup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('结束通话'),
          ),
        ],
      ),
    );
  }
}

/// 通话页面路由辅助方法
class RealCallPageRoute {
  /// 导航到通话页面（作为求助者）
  static Future<bool?> startAsSeeker(
    BuildContext context, {
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealCallPage(
          args: RealCallPageArgs(
            helpRequestId: helpRequestId,
            roomId: '', // 将由WebRTC服务生成
            myRole: CallRole.seeker,
            seekerId: seekerId,
            volunteerId: volunteerId,
            enableRecording: enableRecording,
          ),
        ),
      ),
    );
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
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealCallPage(
          args: RealCallPageArgs(
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
