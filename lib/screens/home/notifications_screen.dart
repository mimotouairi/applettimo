import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, dynamic>> _mockNotifications = const [
    {
      'type': 'like',
      'user_name': 'مريم أحمد',
      'avatar': 'https://i.pravatar.cc/150?u=1',
      'time': 'منذ 5 د',
      'content': 'أعجبت بمنشورك "كيف تبدأ في تعلم البرمجة؟"',
      'is_new': true,
    },
    {
      'type': 'comment',
      'user_name': 'يوسف خالد',
      'avatar': 'https://i.pravatar.cc/150?u=2',
      'time': 'منذ 1 س',
      'content': 'علق على منشورك: "معلومات قيمة جداً، شكراً لك!"',
      'is_new': true,
    },
    {
      'type': 'follow',
      'user_name': 'سارة محمد',
      'avatar': 'https://i.pravatar.cc/150?u=3',
      'time': 'منذ 3 س',
      'content': 'بدأت بمتابعتك',
      'is_new': false,
    },
    {
      'type': 'like',
      'user_name': 'خالد عبدالله',
      'avatar': 'https://i.pravatar.cc/150?u=4',
      'time': 'منذ 5 س',
      'content': 'أعجب بصورتك الجديدة',
      'is_new': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: _mockNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: colors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات حتى الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _mockNotifications.length,
              itemBuilder: (context, index) {
                final notification = _mockNotifications[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: _buildNotificationItem(notification, colors),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, dynamic colors) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment_rounded;
        iconColor = colors.primary;
        break;
      case 'follow':
        icon = Icons.person_add_alt_1_rounded;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = colors.primary;
    }

    return Container(
      color: notification['is_new']
          ? colors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(notification['avatar']),
                backgroundColor: colors.surface,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                  child: Icon(icon, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: colors.text, fontSize: 14, fontFamily: 'ExpoArabic', height: 1.4),
                    children: [
                      TextSpan(
                        text: notification['user_name'] + ' ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: notification['content'],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification['time'],
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (notification['type'] == 'follow')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text('رد المتابعة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
