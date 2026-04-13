import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../providers/auth_provider.dart';

class ChatProvider with ChangeNotifier {
  AuthProvider _authProvider;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  String? _currentChattingWithId;

  ChatProvider(this._authProvider) {
    _initSocket();
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider == auth) return;
    
    final wasAuthenticated = _authProvider.isAuthenticated;
    final oldUserId = wasAuthenticated ? (_authProvider.user?['id']?.toString()) : null;
    
    _authProvider = auth;
    
    final isNowAuthenticated = _authProvider.isAuthenticated;
    final newUserId = isNowAuthenticated ? (_authProvider.user?['id']?.toString()) : null;

    if (isNowAuthenticated) {
      if (!wasAuthenticated || oldUserId != newUserId) {
        SocketService.disconnect();
        _initSocket();
        fetchConversations();
      }
    } else if (wasAuthenticated) {
      SocketService.disconnect();
      _conversations = [];
      _messages = [];
      notifyListeners();
    }
  }

  void _initSocket() {
    if (_authProvider.isAuthenticated) {
      SocketService.connect();
      SocketService.emit('join', _authProvider.user!['id'].toString());
      
      SocketService.on('new_message', (data) {
        final message = Map<String, dynamic>.from(data);
        if (_currentChattingWithId == message['senderId'].toString()) {
          _messages.add(message);
          notifyListeners();
        }
        fetchConversations();
      });

      SocketService.on('new_notification', (data) {
        final notification = Map<String, dynamic>.from(data);
        final actor = notification['actor'];
        final actorPhoto = actor != null ? ApiService.getImageUrl(actor['photo']) : null;
        
        NotificationService.showNotification(
          id: int.tryParse(notification['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch,
          title: notification['title'] ?? 'إشعار جديد',
          body: notification['body'] ?? '',
          imageUrl: actorPhoto,
        );
      });
    }
  }

  List<Map<String, dynamic>> get conversations => _conversations;
  List<Map<String, dynamic>> get messages => _messages;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;

  Future<void> fetchConversations() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    _loadingConversations = true;
    notifyListeners();

    try {
      final result = await ApiService.get('get_conversations?user_id=$userId');
      if (result['success']) {
        _conversations = List<Map<String, dynamic>>.from(result['data']);
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    } finally {
      _loadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String otherId) async {
    if (!_authProvider.isAuthenticated) return;
    _currentChattingWithId = otherId;
    final userId = _authProvider.user!['id'];

    _loadingMessages = true;
    notifyListeners();

    try {
      final result = await ApiService.get('get_messages?user_id=$userId&other_id=$otherId');
      if (result['success']) {
        _messages = List<Map<String, dynamic>>.from(result['data']);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String message) async {
    if (!_authProvider.isAuthenticated) return {'success': false};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('send_message', {
        'sender_id': userId,
        'receiver_id': receiverId,
        'content': message,
      });
      if (result['success']) {
        final newMessage = Map<String, dynamic>.from(result['data']);
        _messages.add(newMessage);
        notifyListeners();
        fetchConversations();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'فشل إرسال الرسالة'};
    }
  }

  void setCurrentChat(String? otherId) {
    _currentChattingWithId = otherId;
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }
}
