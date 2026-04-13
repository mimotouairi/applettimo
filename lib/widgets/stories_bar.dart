import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class StoriesBar extends StatelessWidget {
  final Function(UserStory) onStoryPress;
  final VoidCallback onAddStory;

  const StoriesBar({
    super.key,
    required this.onStoryPress,
    required this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final user = authProvider.user;
    final stories = storyProvider.stories;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.transparent, // Flow naturally with the background
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // My Story / Add Story
            _buildStoryItem(
              onTap: onAddStory,
              userName: 'قصتي',
              imageUrl: ApiService.getImageUrl(user?['photo']),
              isAdd: true,
              colors: colors,
            ),
            const SizedBox(width: 16),
            // Dynamic Stories
            ...stories.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildStoryItem(
                  onTap: () => onStoryPress(item),
                  userName: item.userName,
                  imageUrl: ApiService.getImageUrl(item.userPhoto),
                  colors: colors,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem({
    required VoidCallback onTap,
    required String userName,
    String? imageUrl,
    bool isAdd = false,
    required CustomColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAdd 
                        ? null 
                        : LinearGradient(
                            colors: colors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: isAdd 
                        ? Border.all(color: colors.border, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(3), // Space for inner circle
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background, // Creates the gap
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: colors.surface),
                              errorWidget: (context, url, error) => _buildPlaceholder(colors),
                            )
                          : _buildPlaceholder(colors),
                    ),
                  ),
                ),
                if (isAdd)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAdd ? FontWeight.w600 : FontWeight.w800,
                letterSpacing: -0.2,
                color: isAdd ? colors.textSecondary : colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CustomColors colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.05),
      child: Icon(Icons.person_rounded, size: 30, color: colors.primary.withValues(alpha: 0.5)),
    );
  }
}
