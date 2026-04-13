import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:ui';

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/direct-messages');
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
                backgroundColor: colors.surface.withValues(alpha: 0.7),
                elevation: 0,
                titleSpacing: 0,
                toolbarHeight: 70,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 22),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/direct-messages');
                    }
                  },
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
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'متصل الآن',
                                style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(icon: Icon(Icons.call_rounded, color: colors.primary, size: 22), onPressed: () {}),
                  IconButton(icon: Icon(Icons.videocam_rounded, color: colors.primary, size: 24), onPressed: () {}),
                  const SizedBox(width: 8),
                ],
                shape: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.2))),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? _buildEmptyState(colors)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 100, bottom: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatProvider.messages[index];
                        final isMine = msg['senderId'].toString() == currentUser?['id'].toString();
                        
                        // Grouping Logic
                        bool isLastInGroup = true;
                        if (index < chatProvider.messages.length - 1) {
                          isLastInGroup = chatProvider.messages[index + 1]['senderId'].toString() != msg['senderId'].toString();
                        }
  
                        bool isFirstInGroup = true;
                        if (index > 0) {
                          isFirstInGroup = chatProvider.messages[index - 1]['senderId'].toString() != msg['senderId'].toString();
                        }
                        
                        return _buildSmartMessageBubble(msg, isMine, isFirstInGroup, isLastInGroup, colors);
                      },
                    ),
            ),
            if (_isTyping) _buildTypingIndicator(colors),
            _buildInputArea(colors),
          ],
        ),
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

  Widget _buildSmartMessageBubble(Map<String, dynamic> msg, bool isMine, bool isFirst, bool isLast, dynamic colors) {
    final timeStr = msg['time'];
    final time = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();
    final formattedTime = intl.DateFormat('HH:mm').format(time);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 16 : 4,
        top: isFirst ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (isLast)
              _buildSmallAvatar(widget.otherUser, colors)
            else
              const SizedBox(width: 32),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? LinearGradient(
                        colors: colors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMine ? null : colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMine ? 22 : (isLast ? 4 : 22)),
                  bottomRight: Radius.circular(isMine ? (isLast ? 4 : 22) : 22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['message'],
                    style: TextStyle(
                      color: isMine ? Colors.white : colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: isMine ? Colors.white.withValues(alpha: 0.7) : colors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg['isRead'] == true || msg['isRead'] == 1 ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 10),
            if (isLast)
              _buildSmallAvatar(Provider.of<AuthProvider>(context).user!, colors)
            else
              const SizedBox(width: 32),
          ],
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
        left: 20,
        right: 20,
        top: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: colors.primary, size: 28),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.right,
                onChanged: (val) {
                  setState(() => _isTyping = val.isNotEmpty);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
