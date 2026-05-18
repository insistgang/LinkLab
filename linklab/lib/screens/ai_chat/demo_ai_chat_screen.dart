import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_flow_controller.dart';
import '../../models/help_request_status.dart';
import '../../providers/demo_help_request_flow_provider.dart';
import '../../providers/demo_services_provider.dart';
import '../../services/demo/demo_ai_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

/// 演示版 AI 对话页面
/// 支持文字、图片、语音预填充，以及转人工与 SOS 演示衔接。
class DemoAIChatScreen extends ConsumerStatefulWidget {
  const DemoAIChatScreen({
    super.key,
    this.title = 'AI助手',
    this.introMessage,
    this.initialPrompt,
    this.quickPrompts = const [],
    this.autoSendInitialPrompt = false,
  });

  final String title;
  final String? introMessage;
  final String? initialPrompt;
  final List<String> quickPrompts;
  final bool autoSendInitialPrompt;

  @override
  ConsumerState<DemoAIChatScreen> createState() => _DemoAIChatScreenState();
}

class _DemoAIChatScreenState extends ConsumerState<DemoAIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DemoAIService _aiService;

  bool _isProcessing = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _aiService = ref.read(demoAIServiceProvider);
    _addBotMessage(widget.introMessage ?? _defaultIntroMessage);

    if (widget.initialPrompt != null && widget.autoSendInitialPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sendPresetMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _defaultIntroMessage =>
      '您好！我是 AI 助手“智动”。\n\n我可以帮您：\n• 读文字、说明书、路牌和通知单\n• 描述场景、环境和颜色\n• 模拟面额识别、翻译转译和找路提示\n• 检测紧急词并进入 SOS Mock\n\n不确定时，每个回答都可以转接志愿者。';

  void _addUserMessage(
    String text, {
    Uint8List? imageBytes,
    String? imageName,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          imageBytes: imageBytes,
          imageName: imageName,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text, {Map<String, dynamic>? data}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final imageBytes = _selectedImageBytes;
    final imageName = _selectedImageName;

    if (text.isEmpty && imageBytes == null) return;

    final visibleText = text.isEmpty ? '发送了图片' : text;
    final requestText = text.isEmpty ? '这是什么？' : text;

    _addUserMessage(visibleText, imageBytes: imageBytes, imageName: imageName);
    _textController.clear();

    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });

    await _processAIResponse(
      requestText,
      imagePath: imageName ?? (imageBytes != null ? 'selected-image' : null),
    );
  }

  Future<void> _sendPresetMessage(String prompt) async {
    if (_isProcessing) return;

    _addUserMessage(prompt);
    await _processAIResponse(prompt);
  }

  Future<void> _processAIResponse(String input, {String? imagePath}) async {
    setState(() {
      _isProcessing = true;
    });

    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .startAiProcessing(intent: input);
    final history = _buildAIHistory();
    _addBotMessage('AI 正在分析...');

    final result = await _aiService.process(
      input,
      imagePath: imagePath,
      history: history,
    );

    if (!mounted) return;

    setState(() {
      _messages.removeLast();
    });

    if (result.success) {
      _addBotMessage(result.text, data: result.data);

      if (_isEmergencyResult(result)) {
        _startSOSFlowFromAI();
      } else if (_shouldTransferToHuman(result)) {
        _showTransferToHumanOption();
      }
      if (!_isEmergencyResult(result) && !_shouldTransferToHuman(result)) {
        await ref
            .read(demoHelpRequestFlowProvider.notifier)
            .resolveByAI(summary: result.text);
      }
    } else {
      _addBotMessage('抱歉，处理出错了：${result.error}');
      await ref
          .read(demoHelpRequestFlowProvider.notifier)
          .markCancelled(reason: result.error);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
  }

  bool _shouldTransferToHuman(AIResult result) {
    return result.data?['requiresHumanFallback'] == true ||
        result.data?['intent'] == 'need_human' ||
        result.data?['nextStatus'] == 'matching';
  }

  bool _isEmergencyResult(AIResult result) {
    return result.data?['isEmergency'] == true ||
        result.data?['action'] == 'sos_triggered';
  }

  void _showTransferToHumanOption() {
    showDemoStageDialog<void>(
      context,
      builder: (context) => DemoDialog(
        title: '需要人工帮助？',
        icon: Icons.headset_mic_outlined,
        description: 'AI 可能无法完全解决您的问题。是否现在为您连接志愿者？',
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(demoHelpRequestFlowProvider.notifier)
                  .markCancelled(reason: '用户选择继续 AI 对话');
            },
            child: Text(
              '继续 AI 对话',
              style: TextStyle(color: AppTheme.stageTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stageAccent,
              foregroundColor: AppTheme.stageBackground,
            ),
            onPressed: () {
              Navigator.pop(context);
              _startMatchingFlow();
            },
            child: const Text('连接志愿者'),
          ),
        ],
      ),
    );
  }

  void _startSOSFlowFromAI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DemoFlowNavigator.onSOSButtonPressed(context, autoStartUndoWindow: true);
    });
  }

  Future<void> _startMatchingFlow() async {
    final lastUserMessage = _messages.lastWhere(
      (message) => message.isUser,
      orElse: () => ChatMessage(
        text: '连接真人志愿者获取帮助',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    final flowState = ref.read(demoHelpRequestFlowProvider);
    if (flowState.status.isTerminal ||
        flowState.status == HelpRequestStatus.cancelled ||
        flowState.status == HelpRequestStatus.expired) {
      ref.read(demoHelpRequestFlowProvider.notifier).reset();
    }
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(
          intent: '连接真人志愿者：${lastUserMessage.text}',
          type: 'realtime_voice',
        );
    if (!mounted) return;
    DemoFlowNavigator.onAIRequestMatching(context);
  }

  List<Map<String, String>> _buildAIHistory() {
    return _messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList(growable: false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = pickedFile.name.isEmpty
          ? 'selected-image'
          : pickedFile.name;
    });

    await _sendMessage();
  }

  void _showImagePickerOptions() {
    showDemoStageBottomSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const LinkableSvgIcon(
              icon: LinkableIconName.photoHelp,
              size: 32,
              semanticLabel: '拍照',
            ),
            title: AccessibleText(
              '拍照',
              style: TextStyle(color: AppTheme.stageTextPrimary),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const LinkableSvgIcon(
              icon: LinkableIconName.photoHelp,
              size: 32,
              semanticLabel: '从相册选择',
            ),
            title: AccessibleText(
              '从相册选择',
              style: TextStyle(color: AppTheme.stageTextPrimary),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: widget.title,
          subtitle: '支持文字、图片与语音预置输入',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  0,
                ),
                child: Column(
                  children: [
                    DemoReveal(
                      child: DemoSurfaceCard(
                        color: AppTheme.stageSurfaceStrong.withValues(
                          alpha: 0.94,
                        ),
                        borderColor: AppTheme.stageBorder.withValues(
                          alpha: 0.4,
                        ),
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DemoPill(
                                  icon: Icons.multitrack_audio_rounded,
                                  label: 'AI 助手在线',
                                  color: AppTheme.stageAccent,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                DemoPill(
                                  icon: Icons.headset_mic_outlined,
                                  label: '可转真人',
                                  color: AppTheme.stageSuccess,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            AccessibleText(
                              '先由 AI 快速完成 OCR、场景描述与颜色识别；不确定时再无缝转接志愿者。',
                              style: TextStyle(
                                color: AppTheme.stageTextSecondary,
                                fontSize: AppTheme.fontSizeSmall,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Wrap(
                              spacing: AppTheme.spacingS,
                              runSpacing: AppTheme.spacingS,
                              children: [
                                DemoPill(
                                  label: 'OCR',
                                  icon: Icons.document_scanner_outlined,
                                  color: AppTheme.stageInfo,
                                ),
                                DemoPill(
                                  label: '场景描述',
                                  icon: Icons.visibility_outlined,
                                  color: AppTheme.stageWarning,
                                ),
                                DemoPill(
                                  label: '紧急词检测',
                                  icon: Icons.warning_amber_rounded,
                                  color: AppTheme.stageDanger,
                                ),
                              ],
                            ),
                            if (widget.quickPrompts.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingM),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final prompt
                                        in widget.quickPrompts) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppTheme.spacingS,
                                        ),
                                        child: ActionChip(
                                          backgroundColor: AppTheme.stageAccent
                                              .withValues(alpha: 0.14),
                                          side: BorderSide(
                                            color: AppTheme.stageAccent
                                                .withValues(alpha: 0.24),
                                          ),
                                          label: Text(
                                            prompt,
                                            style: TextStyle(
                                              color: AppTheme.stageTextPrimary,
                                            ),
                                          ),
                                          onPressed: _isProcessing
                                              ? null
                                              : () =>
                                                    _sendPresetMessage(prompt),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                    AppTheme.spacingL,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _ChatMessageBubble(
                      message: _messages[index],
                      onTransferToHuman: _startMatchingFlow,
                      onStartSOS: _startSOSFlowFromAI,
                    );
                  },
                ),
              ),
            ],
          ),
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImageBytes != null)
                DemoSurfaceCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: AccessibleText(
                          _selectedImageName ?? '已选择图片',
                          style: TextStyle(color: AppTheme.stageTextPrimary),
                        ),
                      ),
                      AccessibleIconButton(
                        icon: Icons.close,
                        semanticLabel: '移除已选择的图片',
                        iconColor: AppTheme.stageTextSecondary,
                        onPressed: () => setState(() {
                          _selectedImageBytes = null;
                          _selectedImageName = null;
                        }),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: AppTheme.stageCardDecoration(
                  color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    AccessibleIconButton(
                      icon: Icons.camera_alt_outlined,
                      semanticLabel: '拍照',
                      backgroundColor: AppTheme.stageSurface,
                      iconColor: AppTheme.stageAccent,
                      onPressed: _showImagePickerOptions,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    AccessibleIconButton(
                      icon: Icons.mic_none_rounded,
                      semanticLabel: '语音输入',
                      backgroundColor: AppTheme.stageSurface,
                      iconColor: AppTheme.stageTextPrimary,
                      onPressed: () {
                        _textController.text = '帮我识别这段文字';
                      },
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: AppTheme.stageTextPrimary),
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          hintStyle: TextStyle(color: AppTheme.stageTextHint),
                          filled: true,
                          fillColor: AppTheme.stageSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: AppTheme.stageAccent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isProcessing,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.stageAccentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: AccessibleIconButton(
                        icon: Icons.send,
                        semanticLabel: '发送消息',
                        iconColor: AppTheme.stageBackground,
                        onPressed: _isProcessing ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageBytes,
    this.imageName,
    this.data,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final Uint8List? imageBytes;
  final String? imageName;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.onTransferToHuman,
    required this.onStartSOS,
  });

  final ChatMessage message;
  final VoidCallback onTransferToHuman;
  final VoidCallback onStartSOS;

  bool get _isFinalBotResult {
    return !message.isUser &&
        message.data != null &&
        !message.text.contains('AI 正在分析');
  }

  bool get _isEmergencyResult {
    return message.data?['isEmergency'] == true ||
        message.data?['action'] == 'sos_triggered';
  }

  bool get _showTransferAction {
    return _isFinalBotResult &&
        !_isEmergencyResult &&
        message.data?['canTransferToHuman'] != false;
  }

  bool get _showSOSAction {
    return _isFinalBotResult && _isEmergencyResult;
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser
        ? AppTheme.stageAccent
        : AppTheme.stageSurfaceStrong;
    final textColor = message.isUser
        ? AppTheme.stageBackground
        : AppTheme.stageTextPrimary;

    return Semantics(
      label: message.isUser ? '我说：${message.text}' : 'AI 助手说：${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: Row(
          mainAxisAlignment: message.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.stageAccentGradient,
                  shape: BoxShape.circle,
                ),
                child: const LinkableSvgIcon(
                  icon: LinkableIconName.aiChat,
                  size: 32,
                  semanticLabel: 'AI 助手',
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(20),
                        border: message.isUser
                            ? null
                            : Border.all(
                                color: AppTheme.stageBorder.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                      ),
                      child: AccessibleText(
                        message.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppTheme.fontSizeNormal,
                          height: 1.6,
                        ),
                      ),
                    ),
                  if (!message.isUser && !message.text.contains('AI 正在分析')) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccessibleIconButton(
                          icon: Icons.volume_up_outlined,
                          semanticLabel: '语音播放',
                          size: 36,
                          iconSize: AppTheme.fontSizeNormal,
                          backgroundColor: AppTheme.stageSurface,
                          iconColor: AppTheme.stageTextSecondary,
                          onPressed: () {},
                        ),
                        if (_showTransferAction)
                          TextButton(
                            onPressed: onTransferToHuman,
                            child: Text(
                              '转人工',
                              style: TextStyle(color: AppTheme.stageAccent),
                            ),
                          ),
                        if (_showSOSAction)
                          TextButton(
                            onPressed: onStartSOS,
                            child: Text(
                              '进入 SOS',
                              style: TextStyle(color: AppTheme.stageDanger),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: AppTheme.spacingS),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.stageInfo.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.stageInfo.withValues(alpha: 0.32),
                  ),
                ),
                child: const LinkableSvgIcon(
                  icon: LinkableIconName.profile,
                  size: 32,
                  semanticLabel: '我',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
