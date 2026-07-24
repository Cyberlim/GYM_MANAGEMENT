import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Callbacks
  Function(Map<String, dynamic>)? onNewSupportMessage;
  Function(Map<String, dynamic>)? onAttendanceUpdated;
  Function(dynamic)? onNewNotification;

  void initSocket(String userId) {
    if (_socket != null && _socket!.connected) return;

    final socketUrl = dotenv.env['API_URL']?.replaceAll('/api', '') ?? 'http://localhost:5000';

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('User App Socket connected');
      // Join personal room for messages
      _socket!.emit('join', userId);
    });

    _socket!.on('new_member_support_message', (data) {
      debugPrint('Received new_member_support_message event: $data');
      if (onNewSupportMessage != null) {
        onNewSupportMessage!(data);
      }
    });

    _socket!.on('attendance_updated', (data) {
      debugPrint('Received attendance_updated event: $data');
      if (onAttendanceUpdated != null) {
        onAttendanceUpdated!(data);
      }
    });

    _socket!.on('new_notification', (data) {
      debugPrint('Received new_notification event: $data');
      if (onNewNotification != null) {
        onNewNotification!(data);
      }
    });

    _socket!.onDisconnect((_) => debugPrint('User App Socket disconnected'));
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
