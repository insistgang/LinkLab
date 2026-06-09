import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
// ignore: deprecated_member_use_from_same_package
import '../../services/app_session_service.dart';
import '../../services/community/interest_group_service.dart';
import '../../widgets/accessible/index.dart';

/// 小組聊天頁面
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.group,
  });

  final InterestGroup group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _groupService = InterestGroupService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<GroupMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _groupService.getMessages(widget.group.id);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _subscribeToMessages() {
    _groupService.subscribeToMessages(
      widget.group.id,
      onNewMessage: (message) {
        setState(() {
          _messages.insert(0, message);
        });
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

    try {
      await _groupService.postMessage(widget.group.id, userId, content);
      _messageController.clear();
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: widget.group.name,
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: AccessibleText(
                          '暫無消息，來發第一條吧！',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _MessageBubble(
                            message: message,
                            currentUserId:
                                AppSessionService.instance.currentUser?.id ??
                                'demo-user-id',
                          );
                        },
                      ),
          ),
          // 輸入框
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AccessibleInput(
                      controller: _messageController,
                      hint: '輸入消息...',
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppTheme.primaryColor),
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

/// 消息氣泡
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.currentUserId,
  });

  final GroupMessage message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isMe = message.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 20,
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              child: message.userAvatar == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AccessibleText(
                      message.userName ?? '匿名用戶',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: AccessibleText(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccessibleText(
                      _formatTime(message.createdAt),
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    IconButton(
                      onPressed: () {
                        // TODO: 點贊
                      },
                      icon: Icon(
                        message.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: message.isLiked
                            ? AppTheme.errorColor
                            : AppTheme.textHint,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    AccessibleText(
                      '${message.likeCount}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
