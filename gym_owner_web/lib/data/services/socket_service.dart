import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final Set<String> _suspensionRooms = {};
  
  // Callback when account is suspended
  Function(Map<String, dynamic>)? onAccountSuspended;
  
  // Callback when account is reactivated
  Function(Map<String, dynamic>)? onAccountReactivated;
  
  // Callback for new messages
  Function(Map<String, dynamic>)? onNewMessage;

  void initSocket(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      // Join general user room
      _socket!.emit('join', userId);
      // Join suspension rooms
      for (final room in _suspensionRooms) {
        _socket!.emit('join_suspension', room);
      }
    });

    _socket!.on('account_suspended', (data) {
      debugPrint('Received account_suspended event: $data');
      if (onAccountSuspended != null) {
        onAccountSuspended!(data);
      }
    });

    _socket!.on('account_reactivated', (data) {
      debugPrint('Received account_reactivated event: $data');
      if (onAccountReactivated != null) {
        onAccountReactivated!(data);
      }
    });

    _socket!.on('new_suspension_message', (data) {
      debugPrint('Received new_suspension_message event: $data');
      if (onNewMessage != null) {
        onNewMessage!(data);
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Socket disconnected'));
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
