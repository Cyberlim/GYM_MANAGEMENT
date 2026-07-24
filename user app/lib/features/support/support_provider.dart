import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/api_service.dart';

final supportMessagesProvider = AsyncNotifierProvider<SupportMessagesNotifier, List<dynamic>>(SupportMessagesNotifier.new);

class SupportMessagesNotifier extends AsyncNotifier<List<dynamic>> {
  final ApiService _apiService = ApiService();

  @override
  Future<List<dynamic>> build() async {
    return _fetchMessages();
  }

  Future<List<dynamic>> _fetchMessages() async {
    try {
      final messages = await _apiService.getSupportMessages();
      await _apiService.markSupportMessagesRead();
      return messages;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendMessage(String text) async {
    try {
      final newMessage = await _apiService.sendSupportMessage(text);
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, newMessage]);
      } else {
        ref.invalidateSelf();
      }
    } catch (e) {
      throw e.toString();
    }
  }

  void receiveMessage(Map<String, dynamic> message) {
    if (state.value != null) {
      // Check if message already exists
      final exists = state.value!.any((m) => m['_id'] == message['_id']);
      if (!exists) {
        state = AsyncValue.data([...state.value!, message]);
        _apiService.markSupportMessagesRead(); // Mark as read since user is actively viewing
      }
    } else {
      ref.invalidateSelf();
    }
  }
}
