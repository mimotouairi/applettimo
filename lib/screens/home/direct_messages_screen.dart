import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final chatProvider = Provider.of<ChatProvider>(context);

    final filteredConversations = chatProvider.conversations.where((conv) {
      final name = conv['otherUser']['name'].toString().toLowerCase();
      final username = conv['otherUser']['username'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             username.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'الرسائل',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colors.primary),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? colors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                  border: InputBorder.none,
                  hintText: 'ابحث في الرسائل...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: chatProvider.loadingConversations
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => chatProvider.fetchConversations(),
                    child: filteredConversations.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.builder(
                            itemCount: filteredConversations.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemBuilder: (context, index) {
                              final conv = filteredConversations[index];
                              return _buildConversationCard(conv, colors);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conv, dynamic colors) {
    final otherUser = conv['otherUser'];
    final lastMessage = conv['lastMessage'] ?? 'ابدأ المحادثة الآن...';
    final unreadCount = conv['unreadCount'] ?? 0;
    final time = DateTime.parse(conv['time']);
    final formattedTime = intl.DateFormat('HH:mm').format(time);

    return GestureDetector(
      onTap: () => context.push('/chat', extra: otherUser),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: otherUser['photo'] != null
                        ? Image.network(
                            ApiService.getImageUrl(otherUser['photo'])!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person, color: colors.primary),
                          )
                        : Icon(Icons.person, color: colors.primary),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Main Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUser['name'],
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: colors.text),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0 ? colors.text : colors.textSecondary,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 70, color: colors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            'لا توجد رسائل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.text),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'تواصل مع أصدقائك وشاركهم اهتماماتك الشخصية!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
