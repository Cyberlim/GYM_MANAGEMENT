import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/core/providers/user_provider.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:intl/intl.dart';
import 'package:gym_owner_web/main.dart'; // for sharedPreferencesProvider if needed

final apiServiceProvider = Provider((ref) => ApiService());

class SupportMessagesNotifier extends AsyncNotifier<List<MessageModel>> {
  @override
  Future<List<MessageModel>> build() async {
    return _fetchMessages();
  }

  Future<List<MessageModel>> _fetchMessages() async {
    final userState = ref.read(userProvider).value;
    if (userState == null || userState.user['suspensionId'] == null) {
      return [];
    }
    
    final suspensionId = userState.user['suspensionId'];
    final api = ref.read(apiServiceProvider);
    try {
      final response = await api.get('/support/suspensions/$suspensionId');
      if (response != null && response is List) {
        return response.map((data) {
          final isSentByMe = data['senderRole'] == 'gym_owner';
          final timestamp = DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String());
          return MessageModel(
            id: data['_id'] ?? '',
            sender: isSentByMe ? 'You' : 'Superadmin Support',
            content: data['message'] ?? '',
            time: DateFormat('hh:mm a').format(timestamp),
            timestamp: timestamp,
            isSentByMe: isSentByMe,
            isRead: data['isRead'] ?? true, 
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching support messages: $e');
      return [];
    }
  }

  Future<void> markAsRead(String messageId) async {
    final messages = state.value ?? [];
    state = AsyncValue.data(messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList());
  }

  Future<void> markAllAsRead() async {
    final userState = ref.read(userProvider).value;
    if (userState == null || userState.user['suspensionId'] == null) return;
    
    final suspensionId = userState.user['suspensionId'];
    final api = ref.read(apiServiceProvider);

    try {
      await api.put('/support/suspensions/$suspensionId/read', {});
    } catch (e) {
      print('Error marking messages as read: $e');
    }

    final messages = state.value ?? [];
    state = AsyncValue.data(messages.map((m) {
      return m.copyWith(isRead: true);
    }).toList());
  }



  Future<void> sendMessage(String content) async {
    final userState = ref.read(userProvider).value;
    if (userState == null || userState.user['suspensionId'] == null) {
      // Cannot send message without a suspensionId yet
      print('Cannot send message: No active support thread.');
      return;
    }
    
    final suspensionId = userState.user['suspensionId'];
    final api = ref.read(apiServiceProvider);
    
    try {
      await api.post('/support/suspensions/$suspensionId', {'message': content});
      // Refresh messages
      state = await AsyncValue.guard(() => _fetchMessages());
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}

final supportMessagesProvider = AsyncNotifierProvider<SupportMessagesNotifier, List<MessageModel>>(SupportMessagesNotifier.new);

final unreadMessagesCountProvider = Provider<int>((ref) {
  final messagesState = ref.watch(supportMessagesProvider);
  return messagesState.maybeWhen(
    data: (messages) => messages.where((m) => !m.isRead && !m.isSentByMe).length,
    orElse: () => 0,
  );
});

