import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.fetchMessages(widget.otherUser['id'].toString());
    chatProvider.setCurrentChat(widget.otherUser['id'].toString());
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).setCurrentChat(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final text = _messageController.text.trim();
    _messageController.clear();

    final result = await chatProvider.sendMessage(widget.otherUser['id'].toString(), text);
    if (result['success']) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: colors.text, size: 30),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => context.push('/user-profile/${widget.otherUser['id']}'),
          child: Row(
            children: [
              _buildHeaderAvatar(widget.otherUser, colors),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name'],
                    style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'متصل الآن',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.call_outlined, color: colors.text), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam_outlined, color: colors.text), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState(colors)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatProvider.messages[index];
                      final isMine = msg['senderId'].toString() == currentUser?['id'].toString();
                      final showAvatar = index == 0 || 
                          chatProvider.messages[index - 1]['senderId'].toString() != msg['senderId'].toString();
                      
                      return _buildMessageBubble(msg, isMine, showAvatar, colors);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(colors),
          _buildInputArea(colors),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar(Map<String, dynamic> user, dynamic colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: user['photo'] != null
            ? Image.network(
                ApiService.getImageUrl(user['photo'])!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, color: colors.primary, size: 20),
              )
            : Icon(Icons.person, color: colors.primary, size: 20),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMine, bool showAvatar, dynamic colors) {
    final time = DateTime.parse(msg['time']);
    final formattedTime = intl.DateFormat('HH:mm').format(time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar) _buildSmallAvatar(widget.otherUser, colors),
          if (!isMine && !showAvatar) const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)])
                    : null,
                color: isMine ? null : colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMine ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg['message'],
                    style: TextStyle(
                      color: isMine ? Colors.white : colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: isMine ? Colors.white70 : colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg['isRead'] == true || msg['isRead'] == 1 ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMine && showAvatar) _buildSmallAvatar(Provider.of<AuthProvider>(context).user!, colors),
          if (isMine && !showAvatar) const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(Map<String, dynamic> user, dynamic colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: user['photo'] != null
            ? Image.network(
                ApiService.getImageUrl(user['photo'])!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, color: colors.primary, size: 16),
              )
            : Icon(Icons.person, color: colors.primary, size: 16),
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildDot(colors.primary),
                const SizedBox(width: 4),
                _buildDot(colors.primary),
                const SizedBox(width: 4),
                _buildDot(colors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInputArea(dynamic colors) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: colors.primary, size: 28),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.right,
                onChanged: (val) {
                  setState(() => _isTyping = val.isNotEmpty);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 50, color: colors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'ابدأ المحادثة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يرسل رسالة إلى ${widget.otherUser['name']}',
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
