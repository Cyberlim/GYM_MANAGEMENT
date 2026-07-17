import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class PaymentsNotifier extends AsyncNotifier<List<PaymentRecord>> {
  @override
  Future<List<PaymentRecord>> build() async {
    return _fetchPayments();
  }

  Future<List<PaymentRecord>> _fetchPayments() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/payments');
    if (response != null && response is List) {
      return response.map((data) => PaymentRecord.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addPayment(PaymentRecord payment) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/payments', payment.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchPayments());
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.patch('/payments/$paymentId/status', {'status': status});
    } finally {
      state = await AsyncValue.guard(() => _fetchPayments());
    }
  }
  Future<void> updatePayment(PaymentRecord payment) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/payments/${payment.id}', payment.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchPayments());
    }
  }

  Future<void> removePayment(String paymentId) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/payments/$paymentId');
    } finally {
      state = await AsyncValue.guard(() => _fetchPayments());
    }
  }
}

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<PaymentRecord>>(PaymentsNotifier.new);
