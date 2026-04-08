import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      setState(() {
        if (offset <= 0) {
          _headerOpacity = 1.0;
        } else if (offset < 100) {
          _headerOpacity = 1.0 - (offset / 1000); // Subtle opacity change
        } else {
          _headerOpacity = 0.9;
        }
      });

      // Pagination: Load more when near bottom
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        final postProvider = Provider.of<PostProvider>(context, listen: false);
        if (!postProvider.loading) {
          postProvider.loadMorePosts();
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
    final storyProvider = Provider.of<StoryProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await postProvider.fetchPosts();
              await storyProvider.fetchStories();
            },
            color: colors.primary,
            child: postProvider.loading && postProvider.posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : postProvider.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'فشل في تحميل المنشورات',
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          postProvider.error ?? 'حدث خطأ غير متوقع',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => postProvider.fetchPosts(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : postProvider.posts.isEmpty && !postProvider.loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          size: 64,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منشورات بعد',
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'كن أول من ينشر شيئاً!',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.push('/create-post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إنشاء منشور'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    cacheExtent:
                        1000, // Cache more items for smoother scrolling
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 60,
                      bottom: 20,
                    ),
                    itemCount: postProvider.posts.length + 1,
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
                            _buildSectionHeader(colors),
                          ],
                        );
                      }
                      final post = postProvider.posts[index - 1];
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
          // Animated Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _headerOpacity,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: _headerOpacity),
                  boxShadow: [
                    if (_headerOpacity < 1.0)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo_camera_rounded,
                          color: colors.textSecondary, size: 28),
                      onPressed: () {},
                    ),
                    Text(
                      'Lettuce',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        fontFamily: 'Outfit', // Assuming it's set up or fallback to default
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded,
                              color: colors.textSecondary, size: 28),
                          onPressed: () => context.push('/notifications'),
                        ),
                        IconButton(
                          icon: Icon(Icons.search_rounded,
                              color: colors.textSecondary, size: 28),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, dynamic colors) {
    final fullName = user?['name'] ?? 'أحمد علي';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً $fullName! 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'شارك أفكارك وتفاعلك مع المجتمع اليوم واستمتع بكل ما هو جديد وحصري',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'آخر التحديثات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.text,
            ),
          ),
          Text(
            'الكل',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
