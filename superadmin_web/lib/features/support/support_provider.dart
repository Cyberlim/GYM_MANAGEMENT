import 'package:superadmin_web/core/config/env.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/socket_service.dart';

enum TicketStatus { open, inProgress, resolved }

class ChatMessage {
  final String id;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromAdmin;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromAdmin,
    this.isRead = true,
  });
}

class SupportTicket {
  final String id;
  final String gymOwnerName;
  final String gymName;
  final String? gymId;
  final String issueType;
  final TicketStatus status;
  final List<ChatMessage> messages;

  SupportTicket({
    required this.id,
    required this.gymOwnerName,
    required this.gymName,
    this.gymId,
    required this.issueType,
    required this.status,
    required this.messages,
  });

  SupportTicket copyWith({
    TicketStatus? status,
    List<ChatMessage>? messages,
  }) {
    return SupportTicket(
      id: id,
      gymOwnerName: gymOwnerName,
      gymName: gymName,
      gymId: gymId,
      issueType: issueType,
      status: status ?? this.status,
      messages: messages ?? this.messages,
    );
  }
}

class SupportNotifier extends Notifier<List<SupportTicket>> {
  @override
  List<SupportTicket> build() {
    _loadSuspensions();
    return [];
  }

  Future<void> _loadSuspensions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${Env.apiUrl}/support/suspensions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        
        for (final user in users) {
          final suspensionId = user['suspensionId'];
          if (suspensionId == null) continue;

          // Fetch messages for this suspension
          final msgResponse = await http.get(
            Uri.parse('${Env.apiUrl}/support/suspensions/$suspensionId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          List<ChatMessage> chatMsgs = [];
          if (msgResponse.statusCode == 200) {
            final List<dynamic> msgs = jsonDecode(msgResponse.body);
            chatMsgs = msgs.map((m) => ChatMessage(
              id: m['_id'],
              senderName: m['senderRole'] == 'superadmin' ? 'Superadmin' : user['name'],
              message: m['message'],
              timestamp: DateTime.parse(m['createdAt']),
              isFromAdmin: m['senderRole'] == 'superadmin',
              isRead: m['isRead'] ?? true,
            )).toList();
          }

          final newTicket = SupportTicket(
            id: suspensionId,
            gymOwnerName: user['name'],
            gymName: user['gymName'] ?? 'Suspended Account',
            gymId: user['gymId'],
            issueType: 'Account Suspension',
            status: TicketStatus.open,
            messages: chatMsgs,
          );

          state = [newTicket, ...state.where((t) => t.id != suspensionId)];
        }

        if (state.isNotEmpty) {
          final currentSelectedId = ref.read(selectedTicketIdProvider);
          if (currentSelectedId == null || !state.any((t) => t.id == currentSelectedId)) {
            ref.read(selectedTicketIdProvider.notifier).setTicketId(state.first.id);
          }
        }

        // Initialize socket and listen for new messages
        final socket = SocketService();
        socket.initSocket('superadmin'); // Join a generic superadmin room or just connect
        for (final user in users) {
          if (user['suspensionId'] != null) {
            socket.joinSuspensionRoom(user['suspensionId']);
          }
        }
        
        socket.onNewMessage = (m) {
          final msg = ChatMessage(
            id: m['_id'],
            senderName: m['senderRole'] == 'superadmin' ? 'Superadmin' : 'Gym Owner',
            message: m['message'],
            timestamp: DateTime.parse(m['createdAt']),
            isFromAdmin: m['senderRole'] == 'superadmin',
            isRead: m['isRead'] ?? false,
          );
          addMessageToTicket(m['suspensionId'], msg);
        };
      }
    } catch (e) {
      print('Error loading suspensions: $e');
    }
  }

  void addMessageToTicket(String ticketId, ChatMessage msg) {
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        // Prevent duplicate messages
        if (ticket.messages.any((m) => m.id == msg.id)) return ticket;
        return ticket.copyWith(messages: [...ticket.messages, msg]);
      }
      return ticket;
    }).toList();
  }

  Future<void> sendMessage(String ticketId, String messageText) async {
    // If ticketId starts with SUSP-, it's a suspension ticket
    if (ticketId.startsWith('SUSP-')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) return;

        final response = await http.post(
          Uri.parse('${Env.apiUrl}/support/suspensions/$ticketId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'message': messageText}),
        );
        if (response.statusCode == 201) {
          final m = jsonDecode(response.body);
          final msg = ChatMessage(
            id: m['_id'],
            senderName: 'Superadmin',
            message: m['message'],
            timestamp: DateTime.parse(m['createdAt']),
            isFromAdmin: true,
            isRead: true,
          );
          addMessageToTicket(ticketId, msg);
        }
      } catch (e) {
        print('Error sending message: $e');
      }
      return;
    }

    final newMessage = ChatMessage(
      id: const Uuid().v4(),
      senderName: 'Admin',
      message: messageText,
      timestamp: DateTime.now(),
      isFromAdmin: true,
      isRead: true,
    );

    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        return ticket.copyWith(messages: [...ticket.messages, newMessage]);
      }
      return ticket;
    }).toList();
  }

  void updateTicketStatus(String ticketId, TicketStatus newStatus) {
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        return ticket.copyWith(status: newStatus);
      }
      return ticket;
    }).toList();
  }

  Future<void> markTicketAsRead(String ticketId) async {
    // Update local state first for immediate UI feedback
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        final updatedMessages = ticket.messages.map((m) => ChatMessage(
          id: m.id,
          senderName: m.senderName,
          message: m.message,
          timestamp: m.timestamp,
          isFromAdmin: m.isFromAdmin,
          isRead: true, // mark all as read
        )).toList();
        return ticket.copyWith(messages: updatedMessages);
      }
      return ticket;
    }).toList();

    if (ticketId.startsWith('SUSP-')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) return;

        await http.put(
          Uri.parse('${Env.apiUrl}/support/suspensions/$ticketId/read'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        print('Error marking ticket as read: $e');
      }
    }
  }

  Future<void> clearChat(String ticketId) async {
    if (ticketId.startsWith('SUSP-')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) return;

        final response = await http.delete(
          Uri.parse('${Env.apiUrl}/support/suspensions/$ticketId/messages'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          state = state.map((ticket) {
            if (ticket.id == ticketId) {
              return ticket.copyWith(messages: []);
            }
            return ticket;
          }).toList();
        }
      } catch (e) {
        print('Error clearing chat: $e');
      }
    } else {
      state = state.map((ticket) {
        if (ticket.id == ticketId) {
          return ticket.copyWith(messages: []);
        }
        return ticket;
      }).toList();
    }
  }
}

final supportProvider = NotifierProvider<SupportNotifier, List<SupportTicket>>(() {
  return SupportNotifier();
});

class SelectedTicketIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(supportProvider).firstOrNull?.id;
  }

  void setTicketId(String? id) {
    state = id;
  }
}

final selectedTicketIdProvider = NotifierProvider<SelectedTicketIdNotifier, String?>(() {
  return SelectedTicketIdNotifier();
});
