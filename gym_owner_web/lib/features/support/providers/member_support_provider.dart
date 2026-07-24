import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

// Provider for members who have open chats
final memberChatsProvider = AsyncNotifierProvider<MemberChatsNotifier, List<dynamic>>(MemberChatsNotifier.new);

class MemberChatsNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    return _fetchMembersWithMessages();
  }

  Future<List<dynamic>> _fetchMembersWithMessages() async {
    try {
      final api = ApiService();
      final response = await api.get('/members/support/users');
      return response as List<dynamic>;
    } catch (e) {
      throw e.toString();
    }
  }
}

// Provider for active member's messages
final memberMessagesProvider = AsyncNotifierProvider<MemberMessagesNotifier, List<dynamic>>(MemberMessagesNotifier.new);

class MemberMessagesNotifier extends AsyncNotifier<List<dynamic>> {
  String? _activeMemberId;

  @override
  Future<List<dynamic>> build() async {
    return [];
  }

  Future<void> loadMessages(String memberId) async {
    _activeMemberId = memberId;
    state = const AsyncValue.loading();
    try {
      final api = ApiService();
      final response = await api.get('/members/support/$memberId');
      await api.put('/members/support/$memberId/read', {});
      state = AsyncValue.data(response as List<dynamic>);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> sendMessage(String memberId, String message) async {
    try {
      final api = ApiService();
      final response = await api.post('/members/support/$memberId', {'message': message});
      if (state.value != null && _activeMemberId == memberId) {
        state = AsyncValue.data([...state.value!, response]);
      }
    } catch (e) {
      throw e.toString();
    }
  }

  void receiveMessage(Map<String, dynamic> message) {
    if (state.value != null && _activeMemberId == message['memberId']) {
      final exists = state.value!.any((m) => m['_id'] == message['_id']);
      if (!exists) {
        state = AsyncValue.data([...state.value!, message]);
        final api = ApiService();
        api.put('/members/support/${message['memberId']}/read', {});
      }
    }
  }
}
