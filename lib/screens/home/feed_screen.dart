import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/stories_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late ScrollController _scrollController;
  double _headerOpacity = 1.0;
  bool _isLoadingMore = false;
  String _selectedFeedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      double nextOpacity;
      if (offset <= 0) {
        nextOpacity = 1.0;
      } else if (offset < 100) {
        nextOpacity = 1.0 - (offset / 1000);
      } else {
        nextOpacity = 0.95; // More solid but still glassy
      }
      if ((nextOpacity - _headerOpacity).abs() > 0.02) {
        setState(() => _headerOpacity = nextOpacity);
      }

      // Pagination: Load more when near bottom
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        final postProvider = Provider.of<PostProvider>(context, listen: false);
        if (!postProvider.loading && !_isLoadingMore) {
          _isLoadingMore = true;
          postProvider.loadMorePosts().whenComplete(() {
            _isLoadingMore = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final user = authProvider.user;
    final filteredPosts = postProvider.posts.where((post) {
      if (_selectedFeedFilter == 'video') return post.isVideo;
      if (_selectedFeedFilter == 'image') return post.isImage;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await postProvider.fetchPosts();
              await storyProvider.fetchStories();
            },
            color: colors.primary,
            backgroundColor: colors.surface,
            child: (postProvider.loading && postProvider.posts.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : postProvider.error != null
                    ? _buildErrorView(colors, postProvider)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        cacheExtent: 450,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 70, 
                          bottom: 120, 
                        ),
                        itemCount: filteredPosts.isEmpty ? 1 : filteredPosts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              children: [
                                StoriesBar(
                                  onStoryPress: (story) {
                                    context.push(
                                      '/story-viewer',
                                      extra: {
                                        'userWithStories': story,
                                        'initialIndex': 0,
                                      },
                                    );
                                  },
                                  onAddStory: () => context.push('/create-story'),
                                ),
                                _buildWelcomeCard(user, colors),
                                if (filteredPosts.isEmpty) ...[
                                  const SizedBox(height: 40),
                                  _buildEmptyView(colors),
                                ] else ...[
                                  _buildSectionHeader(colors),
                                  _buildFeedFilters(colors),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            );
                          }
                          final post = filteredPosts[index - 1];
                          return PostCard(
                            key: ValueKey(post.id),
                            post: post,
                            onLike: (id) => postProvider.likePost(id),
                            onComment: (p) =>
                                context.push('/post-details', extra: p),
                          );
                        },
                      ),
          ),
          
          // Ultra-Premium Glassmorphic Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.75 * _headerOpacity),
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border.withValues(alpha: 0.5 * _headerOpacity),
                        width: 0.5,
                      )
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.background.withValues(alpha: 0.5),
                          backgroundImage: ApiService.getImageUrl(user?['photo']) != null
                              ? NetworkImage(ApiService.getImageUrl(user?['photo'])!)
                              : null,
                          child: ApiService.getImageUrl(user?['photo']) == null
                              ? Icon(Icons.person, color: colors.text, size: 20)
                              : null,
                        ),
                      ),
                      Text(
                        'Lettuce',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          foreground: Paint()..shader = LinearGradient(
                            colors: colors.primaryGradient,
                          ).createShader(const Rect.fromLTWH(0.0, 0.0, 150.0, 20.0)),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNotificationButton(colors, notificationProvider),
                          const SizedBox(width: 8),
                          _buildHeaderIconButton(
                            Icons.search_rounded, 
                            colors, 
                            () => context.push('/search')
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, CustomColors colors, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 26),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildNotificationButton(CustomColors colors, NotificationProvider notificationProvider) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: colors.text, size: 26),
            if (notificationProvider.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => context.push('/notifications'),
        splashRadius: 24,
      ),
    );
  }

  Widget _buildErrorView(CustomColors colors, PostProvider postProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 64, color: colors.muted),
          const SizedBox(height: 16),
          Text(
            'فشل في تحميل المنشورات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            postProvider.error ?? 'حدث خطأ غير متوقع',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => postProvider.fetchPosts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(CustomColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add_rounded, size: 64, color: colors.muted),
          const SizedBox(height: 16),
          Text(
            'لا توجد منشورات بعد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من ينشر شيئاً!',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/create-post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('إنشاء منشور', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, CustomColors colors) {
    final fullName = user?['name'] ?? 'صديقي';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Decorative Watermark Pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.stars_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: 20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: ApiService.getImageUrl(user?['photo']) != null
                          ? NetworkImage(ApiService.getImageUrl(user?['photo'])!)
                          : null,
                      child: ApiService.getImageUrl(user?['photo']) == null
                          ? const Icon(Icons.person, color: Colors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً $fullName!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            '✨ استمتع بيومك',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'شارك أفكارك وتفاعلك مع المجتمع اليوم واستمتع بكل ما هو جديد وحصري',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(CustomColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'آخر التحديثات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: colors.text,
            ),
          ),
          Icon(Icons.tune_rounded, color: colors.textSecondary, size: 22),
        ],
      ),
    );
  }

  Widget _buildFeedFilters(CustomColors colors) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('all', 'الكل', Icons.grid_view_rounded, colors),
          _buildFilterChip('image', 'صور', Icons.image_rounded, colors),
          _buildFilterChip('video', 'فيديو', Icons.play_circle_rounded, colors),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, CustomColors colors) {
    final isSelected = _selectedFeedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : colors.textSecondary
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFeedFilter = value),
          showCheckmark: false,
          elevation: isSelected ? 4 : 0,
          pressElevation: 0,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          selectedColor: colors.primary,
          backgroundColor: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : colors.border,
            ),
          ),
        ),
      ),
    );
  }
}
