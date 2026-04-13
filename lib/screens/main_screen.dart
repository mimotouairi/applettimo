import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'home/feed_screen.dart';
import 'home/profile_screen.dart';
import 'home/video_feed_screen.dart';
import 'home/search_screen.dart';
import 'home/direct_messages_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../services/api_service.dart';
import '../widgets/mini_music_player.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialVideoPostId;
  const MainScreen({super.key, this.initialIndex = 0, this.initialVideoPostId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late int _currentIndex;
  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize animation controllers for each nav item (now 4 items)
    _animControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    _scales = _animControllers.map((controller) => 
      Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      )
    ).toList();
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _animControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    
    // Tap animation
    _animControllers[index].forward().then((_) {
      _animControllers[index].reverse();
    });

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    
    final musicProvider = Provider.of<MusicProvider>(context);
    
    // We use IndexedStack to maintain the state of all screens efficiently
    // Removed SearchScreen (extra tab) as there is a search button in the header
    final screens = [
      const FeedScreen(),
      VideoFeedScreen(initialVideoPostId: widget.initialVideoPostId),
      const DirectMessagesScreen(),
      const ProfileScreen(),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // Crucial for floating nav bar
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          
          // Telegram-style Top Music Player Overlay
          if (musicProvider.activeMusicUrl != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 5,
              left: 16,
              right: 16,
              child: MiniMusicPlayer(
                musicUrl: musicProvider.activeMusicUrl!,
                title: musicProvider.activeMusicTitle ?? 'موسيقى قيد التشغيل',
                onStop: () => musicProvider.stopMusic(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, paddingBottom > 0 ? paddingBottom : 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: colors.glass,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
                    _buildNavItem(1, Icons.play_circle_filled, Icons.play_circle_outline),
                    _buildNavItem(2, Icons.chat_bubble, Icons.chat_bubble_outline),
                    _buildProfileNavItem(3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    final colors = Theme.of(context).extension<CustomColors>()!;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scales[index],
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: isSelected ? 28 : 26,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index) {
    final isSelected = _currentIndex == index;
    final colors = Theme.of(context).extension<CustomColors>()!;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final avatarUrl = ApiService.getImageUrl(user?['photo']);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scales[index],
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected 
                      ? LinearGradient(colors: colors.primaryGradient)
                      : null,
                  border: !isSelected 
                      ? Border.all(color: colors.textSecondary.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: colors.surface,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null 
                      ? Icon(Icons.person, size: 16, color: colors.textSecondary) 
                      : null,
                ),
              ),
              if (isSelected) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                ]
            ],
          ),
        ),
      ),
    );
  }
}
