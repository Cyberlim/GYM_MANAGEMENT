import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_owner_web/core/config/env.dart';
import 'package:flutter/foundation.dart';
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    Future.microtask(() => fetchNotifications());
    return [];
  }

  Future<void> fetchNotifications() async {
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
        state = data.map((json) => AppNotification.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    state = state.map((notification) {
      if (notification.id == id) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      await http.put(
        Uri.parse('${Env.apiUrl}/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    state = state.map((notification) => notification.copyWith(isRead: true)).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      await http.put(
        Uri.parse('${Env.apiUrl}/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void addNotification(AppNotification notification) {
    if (!state.any((n) => n.id == notification.id)) {
      state = [notification, ...state];
    }
  }

  void deleteNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
