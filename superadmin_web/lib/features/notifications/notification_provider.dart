import 'package:superadmin_web/core/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/socket_service.dart';

enum NotificationType { registration, payment, system, support }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? route;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.route,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      route: route,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationNotifier extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() {
    _loadNotifications();
    return [];
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${Env.apiUrl}/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = data.map((n) => NotificationModel(
          id: n['_id'],
          title: n['title'],
          message: n['message'],
          timestamp: DateTime.parse(n['createdAt']),
          type: NotificationType.values.firstWhere(
            (e) => e.name == n['type'],
            orElse: () => NotificationType.system,
          ),
          route: n['route'],
          isRead: n['isRead'],
        )).toList();
      }

      // Initialize socket listener for real-time notifications
      final socket = SocketService();
      socket.initSocket('superadmin'); // join superadmin room
      socket.onNewNotification = (n) {
        final newNotif = NotificationModel(
          id: n['_id'],
          title: n['title'],
          message: n['message'],
          timestamp: DateTime.parse(n['createdAt']),
          type: NotificationType.values.firstWhere(
            (e) => e.name == n['type'],
            orElse: () => NotificationType.system,
          ),
          route: n['route'],
          isRead: n['isRead'],
        );
        state = [newNotif, ...state];
      };

    } catch (e) {
      print('Failed to load notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${Env.apiUrl}/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        state = state.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
        }).toList();
      }
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${Env.apiUrl}/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        state = state.map((n) => n.copyWith(isRead: true)).toList();
      }
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }
  
  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});
