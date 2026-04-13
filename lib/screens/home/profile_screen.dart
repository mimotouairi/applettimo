import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/music_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import '../../widgets/mini_music_player.dart';
import '../../widgets/rich_bio_text.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {
    'posts': 0,
    'followers': 0,
    'following': 0,
    'likes': 0,
  };
  bool _loadingStats = true;
  String _selectedAccountId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      final userId = authProvider.user!['id'].toString();
      final result = await postProvider.getUserStats(userId);
      
      if (mounted && result['success']) {
        setState(() {
          _stats = result['data'];
          _loadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;
    _selectedAccountId = _selectedAccountId.isEmpty ? (user?['id']?.toString() ?? '') : _selectedAccountId;

    final userPosts = postProvider.posts.where((p) => p.userId == user?['id'].toString()).toList();
    final savedPosts = postProvider.savedPosts;
    final repostedPosts = postProvider.posts.where((p) => p.repostId != null && p.userId == user?['id'].toString()).toList();
    final taggedPosts = postProvider.posts.where((p) => p.content.contains('@${user?['username'] ?? ''}')).toList();
    final coverUrl = ApiService.getImageUrl(user?['coverPhoto']);
    final avatarUrl = ApiService.getImageUrl(user?['photo']);
    final followersCount = int.tryParse(_stats['followers']?.toString() ?? '0') ?? 0;
    final isCelebrity = followersCount >= 10000 || _stats['isCelebrity'] == true;

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTabController(
        length: 4,
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 460,
                    floating: false,
                    pinned: true,
                    backgroundColor: colors.background,
                    elevation: 0,
                    toolbarHeight: 60,
                    centerTitle: true,
                    title: innerBoxIsScrolled ? Text(user?['name'] ?? 'الملف الشخصي', style: const TextStyle(fontWeight: FontWeight.w900)) : null,
                    actions: [
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: Icon(Icons.more_vert_rounded, color: colors.text),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Stack(
                        children: [
                          // Premium Background Cover with Gradient Overlay
                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              image: coverUrl != null
                                  ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                                  : null,
                              gradient: coverUrl == null
                                  ? LinearGradient(
                                      colors: colors.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    colors.background.withValues(alpha: 0.0),
                                    colors.background,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Profile Info Section
                          Positioned(
                            top: 140,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Avatar with glowing ring
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(colors: colors.primaryGradient),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.primary.withValues(alpha: 0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 5),
                                            )
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 46,
                                          backgroundColor: colors.background,
                                          child: CircleAvatar(
                                            radius: 42,
                                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                            child: avatarUrl == null ? Icon(Icons.person, size: 40, color: colors.primary) : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  user?['name'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    color: colors.text,
                                                  ),
                                                ),
                                                if (isCelebrity) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.verified_rounded, color: Colors.blue.shade500, size: 18),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Simple Stats Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _buildCompactStat(_stats['posts'].toString(), 'منشور', colors),
                                                _buildCompactStat(_stats['followers'].toString(), 'متابع', colors),
                                                _buildCompactStat(_stats['following'].toString(), 'يتابع', colors),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Bio Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichBioText(
                                        text: user?['bio'] ?? 'أضف لمسة خاصة لبروفايلك من هنا ✨',
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (user?['musicTrack'] != null) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Provider.of<MusicProvider>(context, listen: false).playMusic(
                                              user?['musicTrack'],
                                              user?['musicTitle'] ?? 'موسيقى الملف الشخصي',
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: colors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.music_note_rounded, color: colors.primary, size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  user?['musicTitle'] ?? 'استمع للموسيقى',
                                                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                // Action Buttons
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => context.push('/edit-profile'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colors.surface,
                                            foregroundColor: colors.text,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: BorderSide(color: colors.border),
                                            ),
                                          ),
                                          child: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildIconButton(Icons.qr_code_2_rounded, colors, () => _showQrCode(context, user, colors)),
                                      const SizedBox(width: 12),
                                      _buildIconButton(Icons.share_rounded, colors, () {
                                        Share.share('https://let_let.app/user/${user?['username']}');
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: colors.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: colors.primary,
                        unselectedLabelColor: colors.textSecondary.withValues(alpha: 0.5),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_view_rounded, size: 24)),
                          Tab(icon: Icon(Icons.video_collection_rounded, size: 24)),
                          Tab(icon: Icon(Icons.bookmark_rounded, size: 24)),
                          Tab(icon: Icon(Icons.person_pin_rounded, size: 24)),
                        ],
                      ),
                      colors.background,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(userPosts, colors),
                  _buildPostsGrid(repostedPosts, colors),
                  _buildPostsGrid(savedPosts, colors),
                  _buildPostsGrid(taggedPosts, colors),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, CustomColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.text),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, CustomColors colors, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildPostsGrid(List<dynamic> posts, CustomColors colors) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_off_rounded, size: 60, color: colors.border),
            const SizedBox(height: 16),
            Text('لا توجد منشورات حتى الآن', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 120), // Added bottom padding for floating navbar
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = post.mediaUrl != null ? ApiService.getImageUrl(post.mediaUrl) : null;
        
        return GestureDetector(
          onTap: () => context.push('/post-details', extra: post),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
            ),
            child: imageUrl != null 
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Center(child: Icon(Icons.text_fields_rounded, color: colors.border)),
          ),
        );
      },
    );
  }

  void _showQrCode(BuildContext context, dynamic user, CustomColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            Text('رمز Lettuce الخاص بك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.text)),
            const SizedBox(height: 8),
            Text('@${user?['username'] ?? ''}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: colors.primary.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: QrImageView(
                data: 'https://let_flutter.app/user/${user?['id']}',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF014871)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF014871)),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
