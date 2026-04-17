import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_flow_controller.dart';
import '../../demo_flow/demo_help_request_tracker.dart';
import '../../services/demo/demo_ai_service.dart';
import '../../widgets/accessible/index.dart';

/// 演示版 AI 对话页面
/// 支持文字、图片、语音预填充，以及转人工与 SOS 演示衔接。
class DemoAIChatScreen extends StatefulWidget {
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
  State<DemoAIChatScreen> createState() => _DemoAIChatScreenState();
}

class _DemoAIChatScreenState extends State<DemoAIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DemoAIService _aiService = DemoAIService();

  bool _isProcessing = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
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
      '您好！我是 AI 助手“智动”。\n\n我可以帮您：\n• 识别文字和说明书\n• 描述周围环境\n• 分辨衣物或物品颜色\n• 判断是否需要转接志愿者\n\n您可以直接输入问题，或点击下方相机、语音按钮开始。';

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

    await DemoHelpRequestTracker.startAIProcessing(intent: input);
    _addBotMessage('思考中...');

    final result = await _aiService.process(input, imagePath: imagePath);

    if (!mounted) return;

    setState(() {
      _messages.removeLast();
    });

    if (result.success) {
      _addBotMessage(result.text, data: result.data);

      if (_isEmergencyResult(result)) {
        _showEmergencyAssistOption();
      } else if (_shouldTransferToHuman(result)) {
        _showTransferToHumanOption();
      }
      if (!_isEmergencyResult(result) && !_shouldTransferToHuman(result)) {
        await DemoHelpRequestTracker.markAIResolved(summary: result.text);
      }
    } else {
      _addBotMessage('抱歉，处理出错了：${result.error}');
      await DemoHelpRequestTracker.markCancelled(reason: result.error);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
  }

  bool _shouldTransferToHuman(AIResult result) {
    final text = result.text.toLowerCase();
    return text.contains('无法') ||
        text.contains('不清楚') ||
        text.contains('志愿者') ||
        result.data?['intent'] == 'need_human';
  }

  bool _isEmergencyResult(AIResult result) {
    return result.data?['isEmergency'] == true ||
        result.data?['action'] == 'sos_triggered';
  }

  void _showTransferToHumanOption() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AccessibleText(
          '需要人工帮助？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const AccessibleText(
          'AI 可能无法完全解决您的问题。是否现在为您连接志愿者？',
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AccessibleText('继续 AI 对话'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              _startMatchingFlow();
            },
            child: const AccessibleText('连接志愿者'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAssistOption() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AccessibleText(
          '检测到紧急情况',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: AppTheme.emergencyColor,
          ),
        ),
        content: const AccessibleText(
          '是否立即发起 SOS 广播，并同步通知志愿者与紧急联系人？',
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AccessibleText('暂不发起'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              DemoFlowNavigator.onSOSButtonPressed(context);
            },
            child: const AccessibleText('发起 SOS'),
          ),
        ],
      ),
    );
  }

  void _startMatchingFlow() {
    final lastUserMessage = _messages.lastWhere(
      (message) => message.isUser,
      orElse: () => ChatMessage(
        text: '连接真人志愿者获取帮助',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    DemoHelpRequestTracker.ensureMatchingRequest(
      intent: lastUserMessage.text,
      type: 'realtime_voice',
    );
    DemoFlowNavigator.onAIRequestMatching(context);
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
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const AccessibleText('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const AccessibleText('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: widget.title,
      body: Column(
        children: [
          if (widget.quickPrompts.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingM,
                AppTheme.spacingM,
                AppTheme.spacingM,
                AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.dividerColor.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final prompt in widget.quickPrompts) ...[
                      ActionChip(
                        label: Text(prompt),
                        onPressed: _isProcessing
                            ? null
                            : () => _sendPresetMessage(prompt),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                    ],
                  ],
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatMessageBubble(
                  message: _messages[index],
                  onTransferToHuman: _startMatchingFlow,
                );
              },
            ),
          ),

          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              color: AppTheme.surfaceColor,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: AccessibleText(_selectedImageName ?? '已选择图片'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedImageBytes = null;
                      _selectedImageName = null;
                    }),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: AppTheme.cardShadow,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  AccessibleIconButton(
                    icon: Icons.camera_alt,
                    semanticLabel: '拍照',
                    onPressed: _showImagePickerOptions,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  AccessibleIconButton(
                    icon: Icons.mic,
                    semanticLabel: '语音输入',
                    onPressed: () {
                      _textController.text = '帮我识别这段文字';
                    },
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusLarge,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isProcessing,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  AccessibleIconButton(
                    icon: Icons.send,
                    semanticLabel: '发送消息',
                    onPressed: _isProcessing ? null : _sendMessage,
                    iconColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  });

  final ChatMessage message;
  final VoidCallback onTransferToHuman;

  bool get _showTransferAction {
    return !message.isUser &&
        (message.text.contains('无法') ||
            message.text.contains('志愿者') ||
            message.text.contains('真人'));
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: AppTheme.textOnPrimary,
                  size: 24,
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
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
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
                        color: message.isUser
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: AccessibleText(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? AppTheme.textOnPrimary
                              : AppTheme.textPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                        ),
                      ),
                    ),
                  if (!message.isUser && !message.text.contains('思考中')) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccessibleIconButton(
                          icon: Icons.volume_up,
                          semanticLabel: '语音播放',
                          size: 36,
                          iconSize: AppTheme.fontSizeNormal,
                          onPressed: () {},
                        ),
                        if (_showTransferAction)
                          TextButton(
                            onPressed: onTransferToHuman,
                            child: const AccessibleText('转人工'),
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
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.textOnPrimary,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
