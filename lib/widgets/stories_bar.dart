import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/theme_provider.dart';
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
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            const SizedBox(width: 20),
            // Dynamic Stories
            ...stories.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
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
    required dynamic colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAdd ? colors.textSecondary.withValues(alpha: 0.2) : colors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
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
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAdd ? FontWeight.w500 : FontWeight.w700,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(dynamic colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: 26, color: colors.primary),
    );
  }
}
