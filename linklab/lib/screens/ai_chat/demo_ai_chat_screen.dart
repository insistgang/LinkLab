import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../services/demo/demo_ai_service.dart';
import '../../demo_flow/demo_flow_controller.dart';

/// 演示版AI对话页面
/// 支持完整的演示流程：输入 -> AI回复 -> 触发匹配
class DemoAIChatScreen extends StatefulWidget {
  const DemoAIChatScreen({super.key});

  @override
  State<DemoAIChatScreen> createState() => _DemoAIChatScreenState();
}

class _DemoAIChatScreenState extends State<DemoAIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DemoAIService _aiService = DemoAIService();

  bool _isProcessing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _addBotMessage('您好！我是AI助手"智动"。\n\n我可以帮您：\n• 识别文字（拍照识别药品说明书、菜单等）\n• 描述场景（了解周围环境）\n• 识别颜色\n• 回答各种问题\n\n请直接说话或输入您的问题，如需拍照请点击下方相机按钮。');
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text, {File? image}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        image: image,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text, {Map<String, dynamic>? data}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        data: data,
        timestamp: DateTime.now(),
      ));
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
    if (text.isEmpty && _selectedImage == null) return;

    // 添加用户消息
    _addUserMessage(text.isEmpty ? '发送了图片' : text, image: _selectedImage);
    _textController.clear();

    // 处理AI回复
    await _processAIResponse(text, image: _selectedImage);

    // 清除已选图片
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _processAIResponse(String input, {File? image}) async {
    setState(() {
      _isProcessing = true;
    });

    // 显示思考中
    _addBotMessage('思考中...');

    // 调用AI服务
    final result = await _aiService.process(
      input,
      imagePath: image?.path,
    );

    // 移除"思考中"消息
    setState(() {
      _messages.removeLast();
    });

    if (result.success) {
      _addBotMessage(result.text, data: result.data);

      // 检查是否需要转人工（演示流程）
      if (_shouldTransferToHuman(result)) {
        _showTransferToHumanOption();
      }
    } else {
      _addBotMessage('抱歉，处理出错了：${result.error}');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  bool _shouldTransferToHuman(AIResult result) {
    // 演示逻辑：随机触发转人工，或者特定关键词
    final text = result.text.toLowerCase();
    return text.contains('无法') ||
           text.contains('不清楚') ||
           text.contains('志愿者') ||
           result.data?['intent'] == 'need_human';
  }

  void _showTransferToHumanOption() {
    showDialog(
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
          'AI可能无法完全解决您的问题。是否为您连接志愿者？',
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AccessibleText('继续AI对话'),
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

  void _startMatchingFlow() {
    DemoFlowNavigator.onAIRequestMatching(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // 自动发送图片
      _addUserMessage('发送了图片', image: _selectedImage);
      await _processAIResponse('这是什么？', image: _selectedImage);

      setState(() {
        _selectedImage = null;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
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
      title: 'AI助手',
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),

          // 已选图片预览
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              color: AppTheme.surfaceColor,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: Image.file(
                      _selectedImage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  const Expanded(
                    child: AccessibleText('已选择图片'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // 输入栏
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: AppTheme.cardShadow,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 相机按钮
                  AccessibleIconButton(
                    icon: Icons.camera_alt,
                    semanticLabel: '拍照',
                    onPressed: _showImagePickerOptions,
                  ),
                  const SizedBox(width: AppTheme.spacingS),

                  // 语音按钮（演示版）
                  AccessibleIconButton(
                    icon: Icons.mic,
                    semanticLabel: '语音输入',
                    onPressed: () {
                      // 演示：模拟语音输入
                      _textController.text = '帮我识别这段文字';
                    },
                  ),
                  const SizedBox(width: AppTheme.spacingS),

                  // 文本输入
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
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

                  // 发送按钮
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

/// 聊天消息
class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.data,
    required this.timestamp,
  });
}

/// 聊天消息气泡
class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message.isUser ? '我说：${message.text}' : 'AI助手说：${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              // AI头像
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: AppTheme.textOnPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
            ],

            // 消息内容
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 图片
                  if (message.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      child: Image.file(
                        message.image!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  // 文字
                  if (message.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: message.isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: AccessibleText(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                        ),
                      ),
                    ),

                  // 操作按钮（仅AI消息）
                  if (!message.isUser && !message.text.contains('思考中'))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 语音播放按钮
                        AccessibleIconButton(
                          icon: Icons.volume_up,
                          semanticLabel: '语音播放',
                          size: 36,
                          iconSize: AppTheme.fontSizeNormal,
                          onPressed: () {
                            // TODO: 调用TTS播放
                          },
                        ),
                        // 转人工按钮
                        if (message.text.contains('无法') || message.text.contains('志愿者'))
                          TextButton(
                            onPressed: () {
                              // 触发匹配流程
                            },
                            child: const AccessibleText('转人工'),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            if (message.isUser) ...[
              const SizedBox(width: AppTheme.spacingS),
              // 用户头像
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
