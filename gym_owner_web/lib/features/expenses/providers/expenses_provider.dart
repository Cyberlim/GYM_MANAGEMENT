import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class ExpensesNotifier extends AsyncNotifier<List<ExpenseRecord>> {
  @override
  Future<List<ExpenseRecord>> build() async {
    return _fetchExpenses();
  }

  Future<List<ExpenseRecord>> _fetchExpenses() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/expenses');
    if (response != null && response is List) {
      return response.map((data) => ExpenseRecord.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addExpense(ExpenseRecord expense) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/expenses', expense.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchExpenses());
    }
  }

  Future<void> updateExpense(ExpenseRecord updatedExpense) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/expenses/${updatedExpense.id}', updatedExpense.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchExpenses());
    }
  }

  Future<void> removeExpense(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/expenses/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchExpenses());
    }
  }

  Future<void> updateExpenseStatus(String expenseId, String status) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/expenses/$expenseId', {'status': status});
    } finally {
      state = await AsyncValue.guard(() => _fetchExpenses());
    }
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<ExpenseRecord>>(ExpensesNotifier.new);
