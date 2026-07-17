import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class PlansNotifier extends AsyncNotifier<List<MembershipPlan>> {
  @override
  Future<List<MembershipPlan>> build() async {
    return _fetchPlans();
  }

  Future<List<MembershipPlan>> _fetchPlans() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/plans');
    if (response != null && response is List) {
      return response.map((data) => MembershipPlan.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addPlan(MembershipPlan plan) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/plans', plan.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchPlans());
    }
  }

  Future<void> updatePlan(MembershipPlan plan) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/plans/${plan.id}', plan.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchPlans());
    }
  }

  Future<void> removePlan(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/plans/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchPlans());
    }
  }
}

final plansProvider = AsyncNotifierProvider<PlansNotifier, List<MembershipPlan>>(PlansNotifier.new);
