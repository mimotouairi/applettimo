import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isScreenVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.microtask(() => 
      Provider.of<PostProvider>(context, listen: false).fetchVideos()
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final videos = postProvider.videoPosts;

    if (postProvider.loading && videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text('لا توجد فيديوهات حالياً', style: TextStyle(color: Colors.white, fontSize: 18)),
              TextButton(
                onPressed: () => postProvider.fetchVideos(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: const Key('video-feed-screen'),
      onVisibilityChanged: (info) {
        if (mounted) {
          setState(() {
            _isScreenVisible = info.visibleFraction > 0.5;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return VideoPlayerItem(
              key: ValueKey(videos[index].id),
              post: videos[index],
              isActive: index == _currentIndex && _isScreenVisible,
            );
          },
        ),
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final Post post;
  final bool isActive;

  const VideoPlayerItem({
    super.key,
    required this.post,
    required this.isActive,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> with WidgetsBindingObserver, RouteAware {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isBackground = false;
  bool _isRoutePushed = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (_isBackground) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed && widget.isActive && !_isRoutePushed) {
      _controller.play();
    }
  }

  @override
  void didPushNext() {
    _isRoutePushed = true;
    _controller.pause();
  }

  @override
  void didPopNext() {
    _isRoutePushed = false;
    if (widget.isActive && !_isBackground) {
      _controller.play();
    }
  }

  void _initializeController() {
    final url = ApiService.getImageUrl(widget.post.mediaUrl)!;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _error = null;
          });
          if (widget.isActive) {
            _controller.play();
            _controller.setLooping(true);
          }
        }
      }).catchError((e) {
        debugPrint('VideoFeed init error: $e');
        if (mounted) {
          setState(() {
            _error = 'تعذر تشغيل الفيديو';
          });
        }
      });
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_isBackground && !_isRoutePushed) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        if (_isInitialized)
          GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80), // Centered with space for UI
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Colors.black12,
              ),
              clipBehavior: Clip.antiAlias,
              child: FittedBox(
                fit: BoxFit.contain, // Prevent cropping/zoom
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          )
        else if (_error != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Gradient Overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(
                icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: widget.post.likes.toString(),
                color: widget.post.isLiked ? Colors.red : Colors.white,
                onTap: () => Provider.of<PostProvider>(context, listen: false).likePost(widget.post.id),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: widget.post.commentsCount.toString(),
                onTap: () => context.push('/post-details', extra: widget.post),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.repeat,
                label: 'إعادة نشر',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'مشاركة',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/user-profile/${widget.post.userId}'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.post.userPhoto != null
                          ? NetworkImage(ApiService.getImageUrl(widget.post.userPhoto!)!)
                          : null,
                      child: widget.post.userPhoto == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '@${widget.post.userName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text('الصوت الأصلي', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
