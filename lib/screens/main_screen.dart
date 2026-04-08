import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'home/feed_screen.dart';
import 'home/profile_screen.dart';
import 'home/video_feed_screen.dart';
import 'home/search_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const VideoFeedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
            _buildNavItem(1, Icons.search_rounded, 'استكشاف'),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(2, Icons.play_circle_outline_rounded, 'فيديو'),
            _buildNavItem(3, Icons.person_outline_rounded, 'ملفي'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GoRouter.of(context).push('/create-post'),
        backgroundColor: colors.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final colors = Theme.of(context).extension<CustomColors>()!;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? colors.primary : colors.textSecondary,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? colors.primary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
