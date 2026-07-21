import 'package:superadmin_web/core/config/env.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GymOwnerSelection {
  final String id;
  final String ownerName;
  final String gymName;
  final String status;

  GymOwnerSelection({
    required this.id,
    required this.ownerName,
    required this.gymName,
    this.status = 'active',
  });

  factory GymOwnerSelection.fromJson(Map<String, dynamic> json) {
    return GymOwnerSelection(
      id: json['id'] ?? '',
      ownerName: json['ownerName'] ?? '',
      gymName: json['gymName'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}

class BroadcastHistoryItem {
  final String id;
  final String subject;
  final String message;
  final DateTime sentAt;
  final List<String> recipients;

  BroadcastHistoryItem({
    required this.id,
    required this.subject,
    required this.message,
    required this.sentAt,
    required this.recipients,
  });

  factory BroadcastHistoryItem.fromJson(Map<String, dynamic> json) {
    return BroadcastHistoryItem(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      sentAt: DateTime.parse(json['createdAt']),
      recipients: List<String>.from(json['recipients'] ?? []),
    );
  }
}

class BroadcastStatusItem {
  final String userId;
  final String ownerName;
  final String gymName;
  final bool isRead;
  final DateTime? readAt;

  BroadcastStatusItem({
    required this.userId,
    required this.ownerName,
    required this.gymName,
    required this.isRead,
    this.readAt,
  });

  factory BroadcastStatusItem.fromJson(Map<String, dynamic> json) {
    return BroadcastStatusItem(
      userId: json['userId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      gymName: json['gymName'] ?? '',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

class BroadcastNotifier extends AsyncNotifier<void> {
  static String get baseUrl => '${Env.apiUrl}/superadmin';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<void> build() async {}

  Future<List<GymOwnerSelection>> fetchGymOwners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/gym-owners'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GymOwnerSelection.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching gym owners: $e');
    }
    return [];
  }

  Future<bool> sendBroadcast(String subject, String message, List<String> recipientIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/broadcast'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'subject': subject,
          'message': message,
          'recipientIds': recipientIds,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error sending broadcast: $e');
      return false;
    }
  }

  Future<List<BroadcastHistoryItem>> fetchBroadcastHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/broadcasts'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BroadcastHistoryItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching broadcast history: $e');
    }
    return [];
  }

  Future<List<BroadcastStatusItem>> fetchBroadcastStatus(String broadcastId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/broadcasts/$broadcastId/status'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BroadcastStatusItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching broadcast status: $e');
    }
    return [];
  }
}

final broadcastProvider = AsyncNotifierProvider<BroadcastNotifier, void>(() {
  return BroadcastNotifier();
});
