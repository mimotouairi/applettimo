import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {
    'posts': 0,
    'followers': 0,
    'following': 0,
    'likes': 0,
  };
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;

    final userPosts = postProvider.posts.where((p) => p.userId == user?['id'].toString()).toList();
    final savedPosts = postProvider.savedPosts;

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 340,
                floating: false,
                pinned: true,
                backgroundColor: colors.background,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.text),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.qr_code_2_rounded, color: colors.text),
                    onPressed: () => _showQrCode(context, user, colors),
                  ),
                  IconButton(
                    icon: Icon(Icons.bar_chart_outlined, color: colors.text),
                    onPressed: () => context.push('/stats'),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: colors.text),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0.2),
                              colors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colors.primary, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(55),
                                    child: user?['photo'] != null
                                        ? Image.network(
                                            ApiService.getImageUrl(user!['photo'])!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.person, size: 50, color: colors.textSecondary),
                                          )
                                        : Icon(Icons.person, size: 50, color: colors.textSecondary),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/edit-profile'),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              user?['name'] ?? '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              '@${user?['username'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 25),
                            // Stats
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('منشورات', _stats['posts'].toString(), colors),
                                  _buildDivider(colors),
                                  _buildStatItem('متابعين', _stats['followers'].toString(), colors),
                                  _buildDivider(colors),
                                  _buildStatItem('يتابع', _stats['following'].toString(), colors),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Text(
                    user?['bio'] ?? 'لا يوجد وصف متاح.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.text,
                      height: 1.5,
                    ),
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
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined), text: 'المنشورات'),
                      Tab(icon: Icon(Icons.bookmark_border_outlined), text: 'المحفوظات'),
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
              // Posts List
              userPosts.isEmpty
                  ? _buildEmptyState('لا توجد منشورات بعد', Icons.image_outlined, colors)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 100),
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) => PostCard(
                        key: ValueKey('user_post_${userPosts[index].id}'),
                        post: userPosts[index],
                        onComment: (p) => context.push('/post-details', extra: p),
                      ),
                    ),
              // Saved List
              savedPosts.isEmpty
                  ? _buildEmptyState('لا توجد محفوظات', Icons.bookmark_border, colors)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 100),
                      itemCount: savedPosts.length,
                      itemBuilder: (context, index) => PostCard(
                        key: ValueKey('saved_post_${savedPosts[index].id}'),
                        post: savedPosts[index],
                        onComment: (p) => context.push('/post-details', extra: p),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, dynamic colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colors.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(dynamic colors) {
    return Container(
      width: 1,
      height: 30,
      color: colors.border.withValues(alpha: 0.5),
    );
  }

  void _showQrCode(BuildContext context, dynamic user, dynamic colors) {
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
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'امسح الرمز للمتابعة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@${user?['username'] ?? ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: 'https://let_flutter.app/user/${user?['id']}',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: Colors.black,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.share_rounded),
              label: const Text('مشاركة الرابط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
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
