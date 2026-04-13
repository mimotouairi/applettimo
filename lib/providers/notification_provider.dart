import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  AuthProvider _authProvider;

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;

  NotificationProvider(this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    if (_authProvider.isAuthenticated) {
      fetchNotifications();
    }
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider == auth) return;
    _authProvider.removeListener(_onAuthChanged);
    _authProvider = auth;
    _authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      fetchNotifications();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    if (!_authProvider.isAuthenticated) return;
    _loading = true;
    notifyListeners();
    final userId = _authProvider.user?['id']?.toString();
    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final result = await ApiService.get('get_notifications?user_id=$userId');
      if (result['success']) {
        _notifications = List<Map<String, dynamic>>.from(result['data']);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user?['id']?.toString();
    if (userId == null) return;
    await ApiService.post('mark_all_notifications_read', {'user_id': userId});
    _notifications = _notifications.map((n) => {...n, 'isRead': true}).toList();
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user?['id']?.toString();
    if (userId == null) return;
    await ApiService.post('mark_notification_read', {
      'user_id': userId,
      'notification_id': notificationId,
    });
    _notifications = _notifications
        .map((n) => n['id']?.toString() == notificationId ? {...n, 'isRead': true} : n)
        .toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
