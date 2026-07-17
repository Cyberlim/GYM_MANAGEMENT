import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/notifications/providers/notifications_provider.dart';
import 'package:uuid/uuid.dart';

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    return _fetchInventory();
  }

  Future<List<InventoryItem>> _fetchInventory() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/inventory');
    if (response is List) {
      final items = response.map((data) => InventoryItem.fromJson(data)).toList();
      _checkExpiryNotifications(items);
      return items;
    }
    return [];
  }

  Future<void> addItem(InventoryItem item) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/inventory', item.toJson());
      _checkAndNotifyLowStock(item);
    } finally {
      state = await AsyncValue.guard(() => _fetchInventory());
    }
  }

  Future<void> removeItem(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/inventory/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchInventory());
    }
  }

  Future<void> updateItem(InventoryItem updatedItem) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/inventory/${updatedItem.id}', updatedItem.toJson());
      _checkAndNotifyLowStock(updatedItem);
    } finally {
      state = await AsyncValue.guard(() => _fetchInventory());
    }
  }

  void _checkAndNotifyLowStock(InventoryItem item) {
    if (item.minimumStock != null && item.quantity <= item.minimumStock!) {
      final notification = AppNotification(
        id: const Uuid().v4(),
        title: 'Low Stock Alert',
        message: '${item.itemName} stock is at ${item.quantity}, which is below or equal to the minimum stock of ${item.minimumStock}. Please restock.',
        timestamp: DateTime.now(),
        type: 'Inventory',
        targetRoute: '/inventory?highlightId=${item.id}',
      );
      ref.read(notificationsProvider.notifier).addNotification(notification);
    }
  }

  void _checkExpiryNotifications(List<InventoryItem> items) {
    Future.microtask(() {
      final now = DateTime.now();
      for (final item in items) {
        if (item.expiryDate == null) continue;
        
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
        
        if (daysUntilExpiry == 30) {
          _pushExpiryNotification(item, '30_days', '1 month');
        } else if (daysUntilExpiry == 15) {
          _pushExpiryNotification(item, '15_days', '15 days');
        } else if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) {
          _pushExpiryNotification(item, 'daily_${now.year}_${now.month}_${now.day}', '$daysUntilExpiry days');
        }
      }
    });
  }

  void _pushExpiryNotification(InventoryItem item, String type, String timeLabel) {
    final notification = AppNotification(
      id: 'expiry_${item.id}_$type',
      title: 'Expiry Alert',
      message: '${item.itemName} will expire in $timeLabel.',
      timestamp: DateTime.now(),
      type: 'Inventory',
      targetRoute: '/inventory?highlightId=${item.id}',
    );
    ref.read(notificationsProvider.notifier).addNotification(notification);
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(InventoryNotifier.new);

// Filters and search logic can be added here if needed
class InventorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

final inventorySearchQueryProvider = NotifierProvider<InventorySearchQueryNotifier, String>(InventorySearchQueryNotifier.new);

class InventoryFilterState {
  final String status;
  final String category;

  const InventoryFilterState({
    this.status = 'All',
    this.category = 'All',
  });

  InventoryFilterState copyWith({String? status, String? category}) {
    return InventoryFilterState(
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}

class InventoryFilterNotifier extends Notifier<InventoryFilterState> {
  @override
  InventoryFilterState build() => const InventoryFilterState();

  void setStatus(String status) => state = state.copyWith(status: status);
  void setCategory(String category) => state = state.copyWith(category: category);
  void reset() => state = const InventoryFilterState();
}

final inventoryFilterProvider = NotifierProvider<InventoryFilterNotifier, InventoryFilterState>(InventoryFilterNotifier.new);

final filteredInventoryProvider = Provider<AsyncValue<List<InventoryItem>>>((ref) {
  final itemsAsync = ref.watch(inventoryProvider);
  final query = ref.watch(inventorySearchQueryProvider).toLowerCase();
  final filter = ref.watch(inventoryFilterProvider);

  return itemsAsync.whenData((items) {
    var filteredItems = items;

    if (filter.status != 'All') {
      filteredItems = filteredItems.where((i) => i.status == filter.status).toList();
    }
    
    if (filter.category != 'All') {
      filteredItems = filteredItems.where((i) => i.category == filter.category).toList();
    }

    if (query.isNotEmpty) {
      filteredItems = filteredItems
          .where((i) =>
              i.itemName.toLowerCase().contains(query) ||
              i.category.toLowerCase().contains(query) ||
              i.status.toLowerCase().contains(query) ||
              (i.supplier?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filteredItems;
  });
});
