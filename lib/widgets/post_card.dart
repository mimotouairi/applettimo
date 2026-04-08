import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../navigation/app_router.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String)? onLike;
  final Function(Post)? onComment;
  final Function(String)? onDelete;
  final Function(String)? onFollow;
  final bool hideComments;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onFollow,
    this.hideComments = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late AnimationController _likeController;
  late AnimationController _overlayHeartController;
  VideoPlayerController? _videoController;
  bool _isVideoVisible = false;
  bool _showHeartOverlay = false;
  String? _videoError;
  bool _isBackground = false;
  bool _isRoutePushed = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _overlayHeartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _isRoutePushed = true;
    _videoController?.pause();
  }

  @override
  void didPopNext() {
    _isRoutePushed = false;
    if (_isVideoVisible && !_isBackground) {
      _videoController?.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (_isBackground) {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _likeController.dispose();
    _overlayHeartController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _triggerLikeAnimation() {
    _likeController.forward().then((_) => _likeController.reverse());
  }

  void _handleDoubleTap() {
    setState(() => _showHeartOverlay = true);
    _overlayHeartController.forward().then((_) {
      _overlayHeartController.reverse().then((_) {
        setState(() => _showHeartOverlay = false);
      });
    });
    
    if (!widget.post.isLiked) {
      _triggerLikeAnimation();
      widget.onLike?.call(widget.post.id);
    }
  }

  void _onVideoVisibilityChanged(VisibilityInfo info) {
    if (widget.post.isVideo && widget.post.mediaUrl != null) {
      if (info.visibleFraction > 0.5 && !_isVideoVisible && !_isBackground && !_isRoutePushed) {
        _isVideoVisible = true;
        _initializeVideoController();
        _videoController?.play(); // Ensure it starts if it was ready
      } else if (info.visibleFraction < 0.1 && _isVideoVisible) {
        _isVideoVisible = false;
        _videoController?.pause();
      }
    }
  }

  void _initializeVideoController() {
    if (_videoController == null && widget.post.mediaUrl != null) {
      final videoUrl = ApiService.getImageUrl(widget.post.mediaUrl);
      if (videoUrl != null) {
        try {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
            ..initialize().then((_) {
              if (mounted) setState(() => _videoError = null);
            }).catchError((error) {
              debugPrint('Video init error: $error');
              if (mounted) setState(() => _videoError = 'فشل تحميل الفيديو');
            });
        } catch (e) {
          debugPrint('Video try-catch error: $e');
          if (mounted) setState(() => _videoError = 'خطأ غير متوقع');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;
    final isOwnPost = widget.post.userId == user?['id']?.toString();
    final colors = themeProvider.colors;

    final mediaUrl = ApiService.getImageUrl(widget.post.mediaUrl);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isOwnPost) {
                        GoRouter.of(context).push('/profile');
                      } else {
                        GoRouter.of(context).push('/user-profile/${widget.post.userId}');
                      }
                    },
                    child: Row(
                      children: [
                        _buildAvatar(colors),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.userName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              widget.post.time,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: colors.textSecondary, size: 20),
                    onPressed: () => _showPostOptions(context, postProvider, isOwnPost, colors),
                  ),
                ],
              ),
            ),
            // Post Content Text
            if (widget.post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  widget.post.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.text,
                    height: 1.4,
                  ),
                ),
              ),
            // Media Area
            if (mediaUrl != null)
              GestureDetector(
                onDoubleTap: _handleDoubleTap,
                onTap: () {
                  if (widget.post.isVideo) {
                    context.push('/main', extra: 2);
                  } else {
                    context.push('/post-details', extra: widget.post);
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colors.background,
                    border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      widget.post.isVideo
                          ? VisibilityDetector(
                              key: Key('video-${widget.post.id}'),
                              onVisibilityChanged: _onVideoVisibilityChanged,
                              child: _videoController != null && _videoController!.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          VideoPlayer(_videoController!),
                                          if (!_videoController!.value.isPlaying)
                                            const Icon(
                                              Icons.play_circle_outline,
                                              size: 50,
                                              color: Colors.white70,
                                            ),
                                        ],
                                      ),
                                    )
                                  : _videoError != null
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.error_outline, color: Colors.white, size: 40),
                                              const SizedBox(height: 8),
                                              Text(_videoError!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                            ],
                                          ),
                                        )
                                      : const Center(child: CircularProgressIndicator()),
                            )
                          : CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: colors.surface,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 50, color: colors.textSecondary.withValues(alpha: 0.5)),
                                    const SizedBox(height: 8),
                                    Text('الوسائط غير متوفرة', style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7))),
                                  ],
                                ),
                              ),
                            ),
                      if (_showHeartOverlay)
                        ZoomIn(
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            // Actions Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.post.isLiked ? colors.error : colors.textSecondary,
                    onTap: () {
                      _triggerLikeAnimation();
                      widget.onLike?.call(widget.post.id);
                    },
                    count: widget.post.likes.toString(),
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colors.textSecondary,
                    onTap: () {
                      if (widget.onComment != null) {
                        widget.onComment!(widget.post);
                      } else {
                        GoRouter.of(context).push('/post-details', extra: widget.post);
                      }
                    },
                    count: widget.post.commentsCount.toString(),
                  ),
                  _buildActionButton(
                    icon: Icons.repeat_rounded,
                    color: colors.textSecondary,
                    onTap: () => _showRepostDialog(context, postProvider),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    color: colors.textSecondary,
                    onTap: () => Share.share(widget.post.content),
                  ),
                  _buildActionButton(
                    icon: widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.post.isSaved ? colors.primary : colors.textSecondary,
                    onTap: () => postProvider.toggleSavePost(widget.post.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            if (count != null && count != "0") ...[
              const SizedBox(width: 4),
              Text(
                count,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic colors) {
    final avatarUrl = ApiService.getImageUrl(widget.post.userPhoto);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
          : Container(
              color: colors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: colors.primary, size: 22),
            ),
    );
  }

  void _showPostOptions(BuildContext context, PostProvider provider, bool isOwnPost, dynamic colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف المنشور', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, provider);
                },
              ),
            if (!isOwnPost)
              ListTile(
                leading: Icon(Icons.report_problem_outlined, color: colors.text),
                title: Text('إبلاغ عن المنشور', style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ.')));
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PostProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف المنشور', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنشور بشكل نهائي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await provider.deletePost(widget.post.id);
              if (mounted) {
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنشور بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'فشل الحذف')),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showRepostDialog(BuildContext context, PostProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعادة نشر', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('هل تريد إعادة نشر هذا المنشور على صفحتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); 
              final result = await provider.repostPost(widget.post.id);
              if (mounted) {
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إعادة نشر المنشور بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['error'] ?? 'حدث خطأ')),
                  );
                }
              }
            },
            child: const Text('تأكيد', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
