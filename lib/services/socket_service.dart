import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static io.Socket? _socket;

  static io.Socket get socket {
    if (_socket == null) {
      _initSocket();
    }
    return _socket!;
  }

  static void _initSocket() {
    // استخدم رابط السيرفر مباشرة بدون إضافات قد تسبب مشاكل في المنافذ
    const String socketUrl = 'https://let-backend.onrender.com';
    
    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setPath('/socket.io/') // تأكد من المسار الصحيح
      .enableAutoConnect()
      .enableReconnection()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Connected to WebSocket server');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from WebSocket server');
    });

    _socket!.onConnectError((data) {
      debugPrint('Connection Error: $data');
    });
  }

  static void connect() {
    if (_socket == null) {
      _initSocket();
    }
    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void on(String event, dynamic Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  static void off(String event) {
    _socket?.off(event);
  }
}
