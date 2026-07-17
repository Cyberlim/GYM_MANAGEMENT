import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/main.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/data/api/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class MembersNotifier extends AsyncNotifier<List<Member>> {
  @override
  Future<List<Member>> build() async {
    return _fetchMembers();
  }

  Future<List<Member>> _fetchMembers() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/members');
    if (response != null && response is List) {
      return response.map((data) => Member.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addMember(Member member) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/members', member.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchMembers());
    }
  }

  Future<void> updateMember(Member member) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/members/${member.id}', member.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchMembers());
    }
  }

  Future<void> removeMember(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/members/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchMembers());
    }
  }
}

final membersProvider = AsyncNotifierProvider<MembersNotifier, List<Member>>(MembersNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class FilterStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void updateFilter(String filter) => state = filter;
}

final filterStatusProvider = NotifierProvider<FilterStatusNotifier, String>(FilterStatusNotifier.new);

final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final membersState = ref.watch(membersProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final filterStatus = ref.watch(filterStatusProvider);

  return membersState.whenData((members) {
    return members.where((member) {
      final matchesSearch = member.name.toLowerCase().contains(searchQuery) ||
                            member.email.toLowerCase().contains(searchQuery);
      
      final matchesFilter = filterStatus == 'All' || member.status == filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  });
});

class IsMemberListViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isMemberListView') ?? true;
  }

  void setMode(bool isList) {
    state = isList;
    ref.read(sharedPreferencesProvider).setBool('isMemberListView', isList);
  }
}

final isMemberListViewProvider = NotifierProvider<IsMemberListViewNotifier, bool>(IsMemberListViewNotifier.new);
