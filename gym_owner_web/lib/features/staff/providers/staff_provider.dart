import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/main.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class StaffNotifier extends AsyncNotifier<List<Staff>> {
  @override
  Future<List<Staff>> build() async {
    return _fetchStaff();
  }

  Future<List<Staff>> _fetchStaff() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/staff');
    if (response != null && response is List) {
      return response.map((data) => Staff.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addStaff(Staff staffMember) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/staff', staffMember.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchStaff());
    }
  }

  Future<void> removeStaff(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/staff/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchStaff());
    }
  }

  Future<void> updateStaff(Staff updatedStaff) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/staff/${updatedStaff.id}', updatedStaff.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchStaff());
    }
  }
}

final staffProvider = AsyncNotifierProvider<StaffNotifier, List<Staff>>(StaffNotifier.new);

class StaffSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

final staffSearchQueryProvider = NotifierProvider<StaffSearchQueryNotifier, String>(StaffSearchQueryNotifier.new);

final filteredStaffProvider = Provider<AsyncValue<List<Staff>>>((ref) {
  final staffState = ref.watch(staffProvider);
  final searchQuery = ref.watch(staffSearchQueryProvider).toLowerCase();

  return staffState.whenData((staffList) {
    if (searchQuery.isEmpty) return staffList;

    return staffList.where((staff) {
      return staff.name.toLowerCase().contains(searchQuery) ||
             staff.role.toLowerCase().contains(searchQuery);
    }).toList();
  });
});


class IsStaffListViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isStaffListView') ?? true;
  }

  void setMode(bool isList) {
    state = isList;
    ref.read(sharedPreferencesProvider).setBool('isStaffListView', isList);
  }
}

final isStaffListViewProvider = NotifierProvider<IsStaffListViewNotifier, bool>(IsStaffListViewNotifier.new);
