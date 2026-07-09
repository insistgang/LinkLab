import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/logger.dart';
import '../../providers/demo_flow_navigator.dart';
import '../../models/agent_input_model.dart';
import '../../models/agent_response_model.dart';
import '../../models/help_request_status.dart';
import '../../providers/demo_help_request_flow_provider.dart';
import '../../providers/demo_services_provider.dart';
import '../../services/demo/demo_ai_service.dart';
import '../../services/facades/agent_result.dart';
import '../../services/facades/agent_service_facade.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

enum DemoAIChatToolMode { chat, ocr, color }

extension DemoAIChatToolModeCopy on DemoAIChatToolMode {
  String get imageOnlyPrompt {
    switch (this) {
      case DemoAIChatToolMode.ocr:
        return '请帮我识别这张图片里的文字';
      case DemoAIChatToolMode.color:
        return '请帮我识别这张图片里的主要颜色';
      case DemoAIChatToolMode.chat:
        return '请描述这张图片';
    }
  }
}

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
    this.embeddedInTab = false,
    this.toolMode = DemoAIChatToolMode.chat,
  });

  final String title;
  final String? introMessage;
  final String? initialPrompt;
  final List<String> quickPrompts;
  final bool autoSendInitialPrompt;
  final bool embeddedInTab;
  final DemoAIChatToolMode toolMode;

  @override
  ConsumerState<DemoAIChatScreen> createState() => _DemoAIChatScreenState();
}

class _DemoAIChatScreenState extends ConsumerState<DemoAIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DemoAIService _aiService;
  late final AgentServiceFacade _agentFacade;
  static const _uuid = Uuid();

  bool _isProcessing = false;
  bool _isListening = false;
  int? _speakingMessageIndex;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _aiService = ref.read(demoAIServiceProvider);
    _agentFacade = AgentServiceFacade();
    _addBotMessage(widget.introMessage ?? _defaultIntroMessage);

    final initialPrompt = widget.initialPrompt?.trim();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      if (widget.autoSendInitialPrompt) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _sendPresetMessage(initialPrompt);
        });
      } else {
        _textController.text = initialPrompt;
      }
    }
  }

  @override
  void dispose() {
    _agentFacade.stopSpeaking();
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

  void _addBotMessage(
    String text, {
    Map<String, dynamic>? data,
    UiCopy? uiCopy,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          data: data,
          uiCopy: uiCopy,
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
    final imagePath = _selectedImagePath;

    if (text.isEmpty && imageBytes == null) return;

    final visibleText = text.isEmpty ? '发送了图片' : text;
    final requestText = text.isEmpty ? _imageOnlyPrompt : text;

    _addUserMessage(visibleText, imageBytes: imageBytes, imageName: imageName);
    _textController.clear();

    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImagePath = null;
    });

    await _processAIResponse(
      requestText,
      imagePath: imagePath ?? (imageBytes != null ? imageName : null),
    );
  }

  String get _imageOnlyPrompt => widget.toolMode.imageOnlyPrompt;

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
    _addBotMessage('AI 正在分析...');

    // 优先使用统一 Agent facade，真实 OCR/VLM/ASR/TTS 由 facade 决定，
    // 失败时继续回到 Demo fallback，避免主链路无响应。
    AgentResponse? response;
    try {
      final agentResult = await _agentFacade.processInput(
        text: input,
        imagePath: imagePath,
        inputType: imagePath != null ? 'mixed' : 'text',
      );
      response = _agentResponseFromAgentResult(
        agentResult,
        requestId: _uuid.v4(),
      );
    } catch (e) {
      // Agent facade 失败时降级到旧 processRequest / process() 方法
      AppLogger.warning(
        '[DemoAIChat] Agent facade failed, fallback to DemoAIService',
        e,
      );
      try {
        final agentInput = AgentInput(
          requestId: _uuid.v4(),
          userId: 'demo-user',
          inputType: imagePath != null ? 'mixed' : 'text',
          text: input,
          imageUri: imagePath,
        );
        response = await _aiService.processRequest(agentInput);
      } catch (e2) {
        try {
          final history = _buildAIHistory();
          final result = await _aiService.process(
            input,
            imagePath: imagePath,
            history: history,
          );
          if (result.success) {
            response = AgentResponse.fromAIResult(
              result,
              requestId: _uuid.v4(),
            );
          } else {
            if (!mounted) return;
            setState(() {
              _messages.removeLast();
            });
            _addBotMessage('抱歉，处理出错了：${result.error}');
            await ref
                .read(demoHelpRequestFlowProvider.notifier)
                .markCancelled(reason: result.error);
            setState(() {
              _isProcessing = false;
            });
            return;
          }
        } catch (e3) {
          if (!mounted) return;
          setState(() {
            _messages.removeLast();
          });
          _addBotMessage('抱歉，处理出错了：$e3');
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _messages.removeLast();
    });

    final isEmergency = response.urgency == 'emergency';
    final shouldTransfer =
        response.nextAction == 'match_volunteer' ||
        response.nextAction == 'show_fallback' ||
        (!response.canResolveByAi && !isEmergency);

    _addBotMessage(
      response.answerText,
      data: response.toJson(),
      uiCopy: response.uiCopy,
    );

    if (isEmergency) {
      _startSOSFlowFromAI();
    } else if (shouldTransfer) {
      _showTransferToHumanOption();
    }
    if (!isEmergency && !shouldTransfer && response.canResolveByAi) {
      await ref
          .read(demoHelpRequestFlowProvider.notifier)
          .resolveByAI(summary: response.answerText);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
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

  AgentResponse _agentResponseFromAgentResult(
    AgentResult result, {
    required String requestId,
  }) {
    final rawUiCopy = result.uiCopy;
    final uiCopy = UiCopy(
      title: _readUiCopyValue(rawUiCopy, 'title', 'AI 已完成处理'),
      body: _readUiCopyValue(rawUiCopy, 'body', result.answerText),
      primaryAction: _readUiCopyValue(
        rawUiCopy,
        'primaryAction',
        '继续',
        fallbackKey: 'primary_action',
      ),
      secondaryAction: _readUiCopyValue(
        rawUiCopy,
        'secondaryAction',
        '转人工协助',
        fallbackKey: 'secondary_action',
      ),
    );

    return AgentResponse(
      requestId: requestId,
      intent: result.intent,
      urgency: result.urgency,
      confidence: result.confidence,
      canResolveByAi: result.canResolveByAi,
      answerText: result.answerText,
      spokenText: result.spokenText,
      nextAction: result.nextAction,
      handoffReason: result.handoffReason,
      recommendedVolunteerTags: result.recommendedVolunteerTags,
      safetyFlags: result.safetyFlags,
      uiCopy: uiCopy,
    );
  }

  String _readUiCopyValue(
    Map<String, dynamic>? source,
    String key,
    String fallback, {
    String? fallbackKey,
  }) {
    final value =
        source?[key] ?? (fallbackKey == null ? null : source?[fallbackKey]);
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  void _startSOSFlowFromAI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DemoFlowNavigator.onSOSButtonPressed(
        ref,
        context,
        autoStartUndoWindow: true,
      );
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
    DemoFlowNavigator.onAIRequestMatching(ref, context);
  }

  Future<void> _speakText(String text, int messageIndex) async {
    if (text.isEmpty) return;

    setState(() {
      _speakingMessageIndex = messageIndex;
    });

    try {
      await _agentFacade.speakText(text);
      if (!mounted) return;
      AppLogger.info('[DemoAIChat] TTS 朗读成功');
    } catch (e) {
      if (!mounted) return;
      AppLogger.warning('[DemoAIChat] TTS 朗读失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('语音播放失败，请稍后重试'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _speakingMessageIndex = null;
        });
      }
    }
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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (!mounted || pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = pickedFile.path.isEmpty ? null : pickedFile.path;
        _selectedImageName = pickedFile.name.isEmpty
            ? 'selected-image'
            : pickedFile.name;
      });

      await _sendMessage();
    } catch (error, stackTrace) {
      AppLogger.warning('[DemoAIChat] 图片选择失败', error, stackTrace);
      if (!mounted) return;
      _addBotMessage('暂时无法读取图片。请检查相机或相册权限后重试。');
    }
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

  Future<void> _toggleVoiceInput() async {
    if (_isProcessing) return;

    if (_isListening) {
      try {
        await _agentFacade.stopVoiceInput();
      } catch (e) {
        AppLogger.warning('[DemoAIChat] 停止语音输入失败', e);
      }
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    setState(() => _isListening = true);
    _addBotMessage('正在听您说...');

    try {
      final recognizedText = await _agentFacade.startVoiceInput();

      if (!mounted) return;

      setState(() {
        _isListening = false;
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }
      });

      if (recognizedText.trim().isNotEmpty) {
        _textController.text = recognizedText;
        await _sendMessage();
      } else {
        _addBotMessage('没有听清，请再试一次。');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }
      });
      _addBotMessage('语音识别遇到了问题，请检查麦克风权限后重试，也可以直接输入文字。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final textScale = mediaQuery.textScaler.scale(1);
        final compactLayout = mediaQuery.size.width < 430 || textScale > 1.15;
        final chatBody = _buildChatBody(compactLayout: compactLayout);
        final inputBar = _buildInputBar(compactLayout: compactLayout);

        if (widget.embeddedInTab) {
          return Material(
            color: Colors.transparent,
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.stageHeroGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
                      compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
                      compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
                      compactLayout ? AppTheme.spacingXS : AppTheme.spacingS,
                    ),
                    child: Column(
                      children: [
                        _buildEmbeddedHeader(compactLayout: compactLayout),
                        SizedBox(
                          height: compactLayout
                              ? AppTheme.spacingS
                              : AppTheme.spacingM,
                        ),
                        Expanded(child: chatBody),
                        const SizedBox(height: AppTheme.spacingS),
                        inputBar,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return DemoStageScaffold(
          title: widget.title,
          subtitle: compactLayout ? '文字、图片、语音输入' : '支持文字、图片与语音预置输入',
          showBackButton: true,
          body: chatBody,
          bottomBar: inputBar,
        );
      },
    );
  }

  Widget _buildEmbeddedHeader({required bool compactLayout}) {
    return Semantics(
      header: true,
      label: 'AI 助手，第一响应入口',
      child: Row(
        children: [
          DemoGlassIconBadge(
            icon: Icons.multitrack_audio_rounded,
            size: compactLayout ? 40 : 48,
            iconSize: compactLayout ? 20 : 24,
            shape: DemoGlassIconShape.circle,
            semanticLabel: 'AI 助手',
          ),
          SizedBox(
            width: compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  widget.title,
                  isHeader: true,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: compactLayout
                        ? AppTheme.fontSizeNormal
                        : AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  'AI 先判断，必要时转真人',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          DemoPill(
            icon: Icons.offline_bolt_outlined,
            label: '本地可用',
            color: AppTheme.stageAccentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody({required bool compactLayout}) {
    final hasUserConversation = _messages.any((message) => message.isUser);
    return Column(
      children: [
        if (!widget.embeddedInTab || !hasUserConversation)
          _buildAssistantContextCard(compactLayout: compactLayout)
        else
          _buildCompactPromptStrip(compactLayout: compactLayout),
        Expanded(child: _buildMessageList(compactLayout: compactLayout)),
      ],
    );
  }

  Widget _buildAssistantContextCard({required bool compactLayout}) {
    final showCapabilityPills = !widget.embeddedInTab || !compactLayout;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.embeddedInTab ? 0 : AppTheme.spacingL,
        widget.embeddedInTab ? 0 : AppTheme.spacingL,
        widget.embeddedInTab ? 0 : AppTheme.spacingL,
        0,
      ),
      child: DemoReveal(
        child: DemoSurfaceCard(
          color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.94),
          borderColor: AppTheme.stageBorder.withValues(alpha: 0.4),
          padding: EdgeInsets.all(
            compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTheme.spacingS,
                runSpacing: AppTheme.spacingS,
                children: [
                  DemoPill(
                    icon: Icons.multitrack_audio_rounded,
                    label: 'AI 助手在线',
                    color: AppTheme.stageAccentLight,
                  ),
                  DemoPill(
                    icon: Icons.headset_mic_outlined,
                    label: '可转真人',
                    color: AppTheme.stageAccentLight,
                  ),
                ],
              ),
              if (!compactLayout) ...[
                const SizedBox(height: AppTheme.spacingM),
                AccessibleText(
                  '先由 AI 快速完成 OCR、场景描述与颜色识别；不确定时再无缝转接志愿者。',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.5,
                  ),
                ),
              ],
              if (showCapabilityPills) ...[
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: [
                    DemoPill(
                      label: 'OCR',
                      icon: Icons.document_scanner_outlined,
                      color: AppTheme.stageAccentLight,
                    ),
                    DemoPill(
                      label: '场景描述',
                      icon: Icons.visibility_outlined,
                      color: AppTheme.stageAccentLight,
                    ),
                    DemoPill(
                      label: '紧急词检测',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.stageAccentLight,
                    ),
                  ],
                ),
              ],
              if (widget.quickPrompts.isNotEmpty) ...[
                SizedBox(
                  height: compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final prompt in widget.quickPrompts) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacingS,
                          ),
                          child: _QuickPromptButton(
                            label: prompt,
                            compactLayout: compactLayout,
                            onPressed: _isProcessing
                                ? null
                                : () => _sendPresetMessage(prompt),
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
    );
  }

  Widget _buildCompactPromptStrip({required bool compactLayout}) {
    if (widget.quickPrompts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: DemoSurfaceCard(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.9),
        borderColor: AppTheme.stageBorder.withValues(alpha: 0.32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingS,
          vertical: AppTheme.spacingS,
        ),
        child: Row(
          children: [
            DemoPill(
              icon: Icons.offline_bolt_outlined,
              label: '本地可用',
              color: AppTheme.stageAccentLight,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final prompt in widget.quickPrompts) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingS,
                        ),
                        child: _QuickPromptButton(
                          label: prompt,
                          compactLayout: compactLayout,
                          onPressed: _isProcessing
                              ? null
                              : () => _sendPresetMessage(prompt),
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
    );
  }

  Widget _buildMessageList({required bool compactLayout}) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        widget.embeddedInTab ? 0 : AppTheme.spacingL,
        compactLayout ? AppTheme.spacingS : AppTheme.spacingL,
        widget.embeddedInTab ? 0 : AppTheme.spacingL,
        compactLayout ? AppTheme.spacingS : AppTheme.spacingL,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _ChatMessageBubble(
          message: _messages[index],
          onTransferToHuman: _startMatchingFlow,
          onStartSOS: _startSOSFlowFromAI,
          onSpeak: () => _speakText(_messages[index].text, index),
          isSpeaking: _speakingMessageIndex == index,
          compactLayout: compactLayout,
        );
      },
    );
  }

  Widget _buildInputBar({required bool compactLayout}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImageBytes != null)
          DemoSurfaceCard(
            margin: EdgeInsets.only(
              bottom: compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingS),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: compactLayout ? 48 : 60,
                    height: compactLayout ? 48 : 60,
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
                    _selectedImagePath = null;
                  }),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.all(compactLayout ? 6 : AppTheme.spacingS),
          decoration: AppTheme.stageCardDecoration(
            color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(compactLayout ? 24 : 28),
          ),
          child: Row(
            children: [
              AccessibleIconButton(
                icon: Icons.camera_alt_outlined,
                semanticLabel: '拍照',
                backgroundColor: AppTheme.stageSurface,
                iconColor: AppTheme.stageAccent,
                iconSize: compactLayout ? 22 : AppTheme.fontSizeLarge,
                onPressed: _showImagePickerOptions,
              ),
              SizedBox(width: compactLayout ? 6 : AppTheme.spacingS),
              Semantics(
                button: true,
                label: _isListening ? '停止录音' : '语音输入',
                hint: '双击执行${_isListening ? '停止录音' : '语音输入'}',
                enabled: !_isProcessing,
                child: Material(
                  color: _isListening
                      ? AppTheme.stageDanger.withValues(alpha: 0.2)
                      : AppTheme.stageSurface,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  child: InkWell(
                    onTap: _toggleVoiceInput,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                    child: SizedBox(
                      width: AppTheme.minTouchTarget,
                      height: AppTheme.minTouchTarget,
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening
                            ? AppTheme.stageDanger
                            : AppTheme.stageAccent,
                        size: compactLayout ? 24 : 28,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: compactLayout ? 6 : AppTheme.spacingS),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: compactLayout
                        ? AppTheme.fontSizeSmall
                        : AppTheme.fontSizeNormal,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(
                      color: AppTheme.stageTextHint,
                      fontSize: compactLayout
                          ? AppTheme.fontSizeSmall
                          : AppTheme.fontSizeNormal,
                    ),
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
                      vertical: AppTheme.spacingS,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isProcessing,
                ),
              ),
              SizedBox(width: compactLayout ? 6 : AppTheme.spacingS),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.stageAccentGradient,
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  button: true,
                  label: '发送消息',
                  hint: '双击执行发送消息',
                  enabled: !_isProcessing,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _isProcessing ? null : _sendMessage,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: AppTheme.minTouchTarget,
                        height: AppTheme.minTouchTarget,
                        child: LinkableSvgIcon(
                          icon: LinkableIconName.send,
                          size: compactLayout ? 22 : AppTheme.fontSizeLarge,
                          semanticLabel: '发送消息',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickPromptButton extends StatelessWidget {
  const _QuickPromptButton({
    required this.label,
    required this.compactLayout,
    required this.onPressed,
  });

  final String label;
  final bool compactLayout;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(compactLayout ? 14 : 16);

    return Semantics(
      button: true,
      label: '快捷问题：$label',
      hint: '双击发送这个问题',
      enabled: onPressed != null,
      child: Material(
        color: AppTheme.stageAccent.withValues(
          alpha: onPressed == null ? 0.08 : 0.14,
        ),
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: Container(
            constraints: BoxConstraints(
              minHeight: AppTheme.minTouchTarget,
              maxWidth: compactLayout ? 210 : 260,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compactLayout ? 12 : AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: AppTheme.stageAccent.withValues(alpha: 0.28),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: compactLayout
                    ? AppTheme.fontSizeSmall
                    : AppTheme.fontSizeNormal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
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
    this.uiCopy,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final Uint8List? imageBytes;
  final String? imageName;
  final Map<String, dynamic>? data;
  final UiCopy? uiCopy;
  final DateTime timestamp;
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.onTransferToHuman,
    required this.onStartSOS,
    required this.onSpeak,
    required this.compactLayout,
    this.isSpeaking = false,
  });

  final ChatMessage message;
  final VoidCallback onTransferToHuman;
  final VoidCallback onStartSOS;
  final VoidCallback onSpeak;
  final bool compactLayout;
  final bool isSpeaking;

  bool get _isFinalBotResult {
    return !message.isUser &&
        message.data != null &&
        !message.text.contains('AI 正在分析');
  }

  bool get _isEmergencyResult {
    // 优先读取 AgentResponse 标准字段
    final urgency = message.data?['urgency'] as String?;
    if (urgency == 'emergency') return true;
    // 兼容旧 AIResult 格式
    return message.data?['isEmergency'] == true ||
        message.data?['action'] == 'sos_triggered';
  }

  bool get _hasStandardAgentResponse {
    return message.data?.containsKey('next_action') == true ||
        message.data?.containsKey('can_resolve_by_ai') == true;
  }

  String? get _standardNextAction {
    return message.data?['next_action'] as String? ??
        message.data?['nextAction'] as String?;
  }

  bool get _canResolveByAI {
    return message.data?['can_resolve_by_ai'] as bool? ??
        message.data?['canResolveByAi'] as bool? ??
        true;
  }

  bool get _requiresTransferAction {
    if (!_isFinalBotResult || _isEmergencyResult) return false;
    if (_hasStandardAgentResponse) {
      return _standardNextAction == 'match_volunteer' ||
          _standardNextAction == 'show_fallback' ||
          !_canResolveByAI;
    }
    // 兼容旧格式
    return message.data?['canTransferToHuman'] != false;
  }

  bool get _canOfferManualReview {
    final intent = message.data?['intent'] as String?;
    final rawConfidence = message.data?['confidence'];
    final confidence = rawConfidence is num ? rawConfidence.toDouble() : 0.0;
    final highConfidenceSmallTalk =
        intent == 'fallback' && confidence >= 0.80 && _canResolveByAI;

    return _isFinalBotResult &&
        !_isEmergencyResult &&
        !_requiresTransferAction &&
        !highConfidenceSmallTalk &&
        _canResolveByAI;
  }

  bool get _showSOSAction {
    return _isFinalBotResult && _isEmergencyResult;
  }

  String get _transferActionLabel {
    final label = message.uiCopy?.primaryAction.trim();
    if (label == null || label.isEmpty) {
      return '连接志愿者';
    }
    if (label.contains('继续') ||
        label.contains('重新') ||
        label.contains('等待') ||
        label.contains('稍后')) {
      return '连接志愿者';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser
        ? AppTheme.stageAccent
        : AppTheme.stageSurfaceStrong;
    final textColor = message.isUser
        ? AppTheme.stageBackground
        : AppTheme.stageTextPrimary;
    final avatarSize = compactLayout ? 34.0 : 40.0;
    final iconSize = compactLayout ? 26.0 : 32.0;
    final bubbleRadius = compactLayout ? 16.0 : 20.0;
    final bubblePadding = compactLayout
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(AppTheme.spacingM);

    return Semantics(
      label: message.isUser ? '我说：${message.text}' : 'AI 助手说：${message.text}',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
        ),
        child: Row(
          mainAxisAlignment: message.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  gradient: AppTheme.stageAccentGradient,
                  shape: BoxShape.circle,
                ),
                child: LinkableSvgIcon(
                  icon: LinkableIconName.aiChat,
                  size: iconSize,
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
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width *
                            (message.isUser ? 0.72 : 0.82),
                      ),
                      child: Container(
                        padding: bubblePadding,
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(bubbleRadius),
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
                            fontSize: compactLayout
                                ? AppTheme.fontSizeSmall
                                : AppTheme.fontSizeNormal,
                            height: compactLayout ? 1.45 : 1.6,
                          ),
                        ),
                      ),
                    ),
                  if (!message.isUser && !message.text.contains('AI 正在分析')) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Wrap(
                      spacing: AppTheme.spacingS,
                      runSpacing: AppTheme.spacingS,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AccessibleIconButton(
                          icon: isSpeaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          semanticLabel: isSpeaking ? '停止播放' : '语音播放',
                          size: 36,
                          iconSize: compactLayout
                              ? AppTheme.fontSizeSmall
                              : AppTheme.fontSizeNormal,
                          backgroundColor: isSpeaking
                              ? AppTheme.stageDanger.withValues(alpha: 0.2)
                              : AppTheme.stageSurface,
                          iconColor: isSpeaking
                              ? AppTheme.stageDanger
                              : AppTheme.stageTextSecondary,
                          onPressed: onSpeak,
                        ),
                        if (_showSOSAction)
                          _BubbleActionButton(
                            label: '进入 SOS',
                            icon: Icons.emergency_outlined,
                            foregroundColor: AppTheme.stageBackground,
                            backgroundColor: AppTheme.stageDanger,
                            onPressed: onStartSOS,
                          )
                        else if (_requiresTransferAction)
                          _BubbleActionButton(
                            label: _transferActionLabel,
                            icon: Icons.headset_mic_outlined,
                            foregroundColor: AppTheme.stageBackground,
                            backgroundColor: AppTheme.stageAccent,
                            onPressed: onTransferToHuman,
                          )
                        else if (_canOfferManualReview)
                          TextButton(
                            onPressed: onTransferToHuman,
                            child: Text(
                              '转人工复核',
                              style: TextStyle(color: AppTheme.stageAccent),
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
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: AppTheme.stageInfo.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.stageInfo.withValues(alpha: 0.32),
                  ),
                ),
                child: LinkableSvgIcon(
                  icon: LinkableIconName.profile,
                  size: iconSize,
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

class _BubbleActionButton extends StatelessWidget {
  const _BubbleActionButton({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: '双击执行$label',
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          minimumSize: const Size(0, AppTheme.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: AppTheme.fontSizeNormal),
        label: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
