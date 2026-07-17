import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class EquipmentNotifier extends AsyncNotifier<List<Equipment>> {
  @override
  Future<List<Equipment>> build() async {
    return _fetchEquipment();
  }

  Future<List<Equipment>> _fetchEquipment() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/equipment');
    if (response is List) {
      return response.map((data) => Equipment.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addEquipment(Equipment equipment) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/equipment', equipment.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchEquipment());
    }
  }

  Future<void> removeEquipment(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/equipment/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchEquipment());
    }
  }

  Future<void> updateEquipment(Equipment updatedEquipment) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/equipment/${updatedEquipment.id}', updatedEquipment.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchEquipment());
    }
  }
}

final equipmentProvider = AsyncNotifierProvider<EquipmentNotifier, List<Equipment>>(EquipmentNotifier.new);

class EquipmentSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

final equipmentSearchQueryProvider = NotifierProvider<EquipmentSearchQueryNotifier, String>(EquipmentSearchQueryNotifier.new);

class EquipmentFilterState {
  final String status;
  final String equipmentType;

  const EquipmentFilterState({
    this.status = 'All',
    this.equipmentType = 'All',
  });

  EquipmentFilterState copyWith({String? status, String? equipmentType}) {
    return EquipmentFilterState(
      status: status ?? this.status,
      equipmentType: equipmentType ?? this.equipmentType,
    );
  }
}

class EquipmentFilterNotifier extends Notifier<EquipmentFilterState> {
  @override
  EquipmentFilterState build() => const EquipmentFilterState();

  void setStatus(String status) => state = state.copyWith(status: status);
  void setType(String type) => state = state.copyWith(equipmentType: type);
  void reset() => state = const EquipmentFilterState();
}

final equipmentFilterProvider = NotifierProvider<EquipmentFilterNotifier, EquipmentFilterState>(EquipmentFilterNotifier.new);

final filteredEquipmentProvider = Provider<AsyncValue<List<Equipment>>>((ref) {
  final itemsAsync = ref.watch(equipmentProvider);
  final query = ref.watch(equipmentSearchQueryProvider).toLowerCase();
  final filter = ref.watch(equipmentFilterProvider);

  return itemsAsync.whenData((items) {
    var filteredItems = items;

    if (filter.status != 'All') {
      filteredItems = filteredItems.where((e) => e.status == filter.status).toList();
    }
    
    if (filter.equipmentType != 'All') {
      filteredItems = filteredItems.where((e) => e.equipmentType == filter.equipmentType).toList();
    }

    if (query.isNotEmpty) {
      filteredItems = filteredItems
          .where((e) =>
              e.machineName.toLowerCase().contains(query) ||
              e.brand.toLowerCase().contains(query) ||
              e.equipmentType.toLowerCase().contains(query) ||
              e.location.toLowerCase().contains(query) ||
              e.status.toLowerCase().contains(query) ||
              (e.supplier?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filteredItems;
  });
});
