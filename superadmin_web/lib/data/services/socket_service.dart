import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final Set<String> _suspensionRooms = {};
  
  // Callback for new messages
  Function(Map<String, dynamic>)? onNewMessage;
  // Callback for notifications
  Function(Map<String, dynamic>)? onNewNotification;

  void initSocket(String adminId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Superadmin Socket connected');
      _socket!.emit('join', adminId);
      for (final room in _suspensionRooms) {
        _socket!.emit('join_suspension', room);
      }
    });

    _socket!.on('new_suspension_message', (data) {
      debugPrint('Received new_suspension_message event: $data');
      if (onNewMessage != null) {
        onNewMessage!(data);
      }
    });

    _socket!.on('notification', (data) {
      debugPrint('Received notification event: $data');
      if (onNewNotification != null) {
        onNewNotification!(data);
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Superadmin Socket disconnected'));
  }

  void joinSuspensionRoom(String suspensionId) {
    _suspensionRooms.add(suspensionId);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_suspension', suspensionId);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
