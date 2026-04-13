import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      Provider.of<PostProvider>(context, listen: false).fetchSuggestions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        setState(() => _isSearching = true);
        Provider.of<PostProvider>(context, listen: false).searchUsers(query).then((_) {
          if (mounted) setState(() => _isSearching = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final query = _searchController.text;
    final showResults = query.length >= 2;

    // Filter posts locally for the search
    final filteredPosts = postProvider.posts.where((post) {
      final q = query.toLowerCase();
      return post.content.toLowerCase().contains(q) || post.userName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            style: TextStyle(color: colors.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن أشخاص أو منشورات...',
              hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.cancel, color: colors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        bottom: showResults
            ? TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textSecondary,
                tabs: [
                  Tab(text: 'المنشورات (${filteredPosts.length})'),
                  Tab(text: 'الأشخاص (${postProvider.foundUsers.length})'),
                ],
              )
            : null,
      ),
      body: showResults
          ? TabBarView(
              controller: _tabController,
              children: [
                // Posts Results
                _buildPostsResults(filteredPosts, colors),
                // People Results
                _buildPeopleResults(postProvider.foundUsers, colors, authProvider.user!['id'].toString()),
              ],
            )
          : _buildSuggestions(postProvider.suggestedUsers, colors),
    );
  }

  Widget _buildPostsResults(List<dynamic> posts, dynamic colors) {
    if (posts.isEmpty) {
      return _buildEmptyState('لا توجد منشورات تطابق بحثك', Icons.search_off, colors);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Added bottom padding for floating navbar
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(
        key: ValueKey(posts[index].id),
        post: posts[index],
        onComment: (p) => context.push('/post-details', extra: p),
      ),
    );
  }

  Widget _buildPeopleResults(List<dynamic> users, dynamic colors, String currentUserId) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (users.isEmpty) {
      return _buildEmptyState('لم نجد أحداً بهذا الاسم', Icons.person_off_outlined, colors);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Added bottom padding for floating navbar
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index], colors, currentUserId),
    );
  }

  Widget _buildSuggestions(List<dynamic> suggestions, dynamic colors) {
    if (suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Added bottom padding for floating navbar
      children: [
        Text(
          'مقترح لك',
          style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w900),
        ).marginBottom,
        ...suggestions.map((user) => _buildUserCard(user, colors, '')).toList(),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, dynamic colors, String currentUserId) {
    final bool isFollowing = user['isFollowing'] == true || user['isFollowing'] == 1;
    final String userId = user['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/user-profile/$userId'),
            child: CircleAvatar(
              radius: 25,
              backgroundImage: user['photo'] != null ? NetworkImage(ApiService.getImageUrl(user['photo'])!) : null,
              child: user['photo'] == null ? const Icon(Icons.person) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/user-profile/$userId'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? '', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 15)),
                  Text('@${user['username'] ?? ''}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          if (userId != currentUserId)
            StatefulBuilder(
              builder: (context, setState) {
                final bool isFollowing = user['isFollowing'] == true || user['isFollowing'] == 1;
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      user['isFollowing'] = !isFollowing;
                    });
                    Provider.of<PostProvider>(context, listen: false).toggleFollow(userId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.transparent : colors.primary,
                    foregroundColor: isFollowing ? colors.primary : Colors.white,
                    elevation: 0,
                    side: isFollowing ? BorderSide(color: colors.primary) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(isFollowing ? 'متابع' : 'متابعة', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                );
              }
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
extension on Text {
  Text copyWith({TextStyle? style}) => Text(data!, style: style ?? this.style);
}

// Fixed spacing issue in ListView children
extension on Widget {
  Widget get marginBottom => Padding(padding: const EdgeInsets.only(bottom: 16), child: this);
}
