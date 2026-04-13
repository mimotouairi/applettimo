import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  late Post _currentPost;
  String? _replyToCommentId;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    Provider.of<PostProvider>(context, listen: false).markPostViewed(_currentPost.id);
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final result = await Provider.of<PostProvider>(context, listen: false).fetchComments(_currentPost.id);
    if (mounted) {
      setState(() {
        _comments = result['success'] ? result['data'] : [];
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = _replyToCommentId == null
        ? await postProvider.addComment(_currentPost.id, text)
        : await postProvider.addReply(_currentPost.id, _replyToCommentId!, text);
    if (result['success']) {
      _commentController.clear();
      _replyToCommentId = null;
      _fetchComments();
      // Update local post comment count
      setState(() {
        _currentPost = Post(
          id: _currentPost.id,
          userId: _currentPost.userId,
          userName: _currentPost.userName,
          userPhoto: _currentPost.userPhoto,
          content: _currentPost.content,
          mediaUrl: _currentPost.mediaUrl,
          mediaType: _currentPost.mediaType,
          likes: _currentPost.likes,
          commentsCount: _currentPost.commentsCount + 1,
          viewsCount: _currentPost.viewsCount,
          engagementScore: _currentPost.engagementScore,
          createdAt: _currentPost.createdAt,
          time: _currentPost.time,
          isLiked: _currentPost.isLiked,
          isSaved: _currentPost.isSaved,
          musicTitle: _currentPost.musicTitle,
          filterType: _currentPost.filterType,
          repostId: _currentPost.repostId,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'فشل إضافة التعليق')),
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'الآن';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inMinutes < 60) return '${difference.inMinutes} د';
      if (difference.inHours < 24) return '${difference.inHours} س';
      if (difference.inDays < 7) return '${difference.inDays} ي';
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (e) {
      return 'قديماً';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('تفاصيل المنشور', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostCard(post: _currentPost),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('التعليقات', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('${_comments.length}', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('لا توجد تعليقات بعد', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._comments.map((comment) => _buildCommentItem(comment, colors, false)),
                ],
              ),
            ),
          ),
          _buildCommentInput(colors),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, dynamic colors, bool isReply) {
    return Container(
      margin: isReply ? const EdgeInsets.only(left: 28) : null,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment['userPhoto'] != null ? NetworkImage(ApiService.getImageUrl(comment['userPhoto'])!) : null,
            child: comment['userPhoto'] == null ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment['userName'] ?? 'مستخدم', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 13)),
                    Text(_formatTime(comment['createdAt']), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['comment'] ?? '', style: TextStyle(color: colors.text, fontSize: 13, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Provider.of<PostProvider>(context, listen: false)
                            .toggleCommentLike(comment['id'].toString());
                        if (result['success']) {
                          _fetchComments();
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            (comment['isLiked'] == true) ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: (comment['isLiked'] == true) ? colors.error : colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment['likesCount'] ?? 0}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isReply)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _replyToCommentId = comment['id'].toString();
                          });
                        },
                        child: Text(
                          'رد',
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if ((comment['replies'] as List?)?.isNotEmpty ?? false)
                  ...((comment['replies'] as List)
                      .map((reply) => _buildCommentItem(Map<String, dynamic>.from(reply), colors, true))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(dynamic colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: null,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _replyToCommentId == null ? 'اكتب تعليقاً...' : 'اكتب ردًا...',
                  hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_replyToCommentId != null)
            IconButton(
              onPressed: () => setState(() => _replyToCommentId = null),
              icon: Icon(Icons.close, color: colors.textSecondary),
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _handleAddComment,
            icon: Icon(Icons.send, color: colors.primary),
          ),
        ],
      ),
    );
  }
}
