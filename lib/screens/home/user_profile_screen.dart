import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profileData;
  List<Post> _userPosts = [];
  bool _loading = true;
  bool _followingLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = await postProvider.getUserProfile(widget.userId);
    
    if (mounted && result['success']) {
      setState(() {
        _profileData = result['data']['user'];
        _userPosts = (result['data']['posts'] as List)
            .map((json) => Post.fromJson(json))
            .toList();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFollow() async {
    if (_profileData == null) return;
    
    setState(() => _followingLoading = true);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = await postProvider.toggleFollow(widget.userId);
    
    if (mounted && result['success']) {
      setState(() {
        final isFollowing = _profileData!['isFollowing'] == true || _profileData!['isFollowing'] == 1;
        _profileData!['isFollowing'] = !isFollowing;
        _profileData!['followersCount'] = isFollowing 
            ? (_profileData!['followersCount'] as int) - 1 
            : (_profileData!['followersCount'] as int) + 1;
      });
    }
    setState(() => _followingLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    final mediaPosts = _userPosts.where((p) => p.mediaUrl != null).toList();
    final isFollowing = _profileData!['isFollowing'] == true || _profileData!['isFollowing'] == 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 380,
                floating: false,
                pinned: true,
                backgroundColor: colors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    children: [
                      // Cover View (Gradient for now)
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Avatar
                      Positioned(
                        top: 170,
                        left: 20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: _profileData!['photo'] != null
                                ? Image.network(
                                    ApiService.getImageUrl(_profileData!['photo'])!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.person, size: 50, color: colors.textSecondary),
                                  )
                                : Icon(Icons.person, size: 50, color: colors.textSecondary),
                          ),
                        ),
                      ),
                      // User Info below Avatar
                      Positioned(
                        top: 275,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileData!['name'] ?? '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              '@${_profileData!['username'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_profileData!['bio'] != null)
                              Text(
                                _profileData!['bio'],
                                style: TextStyle(color: colors.text),
                              ),
                            const SizedBox(height: 20),
                            // Stats Row
                            Row(
                              children: [
                                _buildStatItem(_profileData!['followersCount'].toString(), 'متابع', colors),
                                const SizedBox(width: 30),
                                _buildStatItem(_profileData!['followingCount'].toString(), 'يتابع', colors),
                                const SizedBox(width: 30),
                                _buildStatItem(_userPosts.length.toString(), 'منشور', colors),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _handleToggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing ? Colors.transparent : colors.primary,
                                      foregroundColor: isFollowing ? colors.primary : Colors.white,
                                      elevation: 0,
                                      side: isFollowing ? BorderSide(color: colors.primary) : null,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      minimumSize: const Size(double.infinity, 44),
                                    ),
                                    child: _followingLoading 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildIconButton(Icons.chat_bubble_outline, () => context.push('/chat', extra: _profileData), colors),
                                const SizedBox(width: 10),
                                _buildIconButton(Icons.share_outlined, () {}, colors),
                              ],
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
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined), text: 'المنشورات'),
                      Tab(icon: Icon(Icons.image_outlined), text: 'الوسائط'),
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
              _userPosts.isEmpty
                  ? _buildEmptyState('لا توجد منشورات بعد', colors)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _userPosts.length,
                      itemBuilder: (context, index) => PostCard(
                        key: ValueKey(_userPosts[index].id),
                        post: _userPosts[index],
                      ),
                    ),
              mediaPosts.isEmpty
                  ? _buildEmptyState('لا توجد وسائط', colors)
                  : GridView.builder(
                      padding: const EdgeInsets.all(5),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: mediaPosts.length,
                      itemBuilder: (context, index) => Image.network(
                        ApiService.getImageUrl(mediaPosts[index].mediaUrl)!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed, dynamic colors) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colors.border),
      ),
      child: Icon(icon, color: colors.text, size: 20),
    );
  }

  Widget _buildEmptyState(String message, dynamic colors) {
    return Center(
      child: Text(message, style: TextStyle(color: colors.textSecondary)),
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
