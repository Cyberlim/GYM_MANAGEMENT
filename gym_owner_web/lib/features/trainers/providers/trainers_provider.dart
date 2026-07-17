import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/main.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class TrainersNotifier extends AsyncNotifier<List<Trainer>> {
  @override
  Future<List<Trainer>> build() async {
    return _fetchTrainers();
  }

  Future<List<Trainer>> _fetchTrainers() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.get('/trainers');
    if (response != null && response is List) {
      return response.map((data) => Trainer.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> addTrainer(Trainer trainer) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.post('/trainers', trainer.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchTrainers());
    }
  }

  Future<void> removeTrainer(String id) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.delete('/trainers/$id');
    } finally {
      state = await AsyncValue.guard(() => _fetchTrainers());
    }
  }

  Future<void> updateTrainer(Trainer updatedTrainer) async {
    final api = ref.read(apiServiceProvider);
    state = const AsyncValue.loading();
    try {
      await api.put('/trainers/${updatedTrainer.id}', updatedTrainer.toJson());
    } finally {
      state = await AsyncValue.guard(() => _fetchTrainers());
    }
  }
}

final trainersProvider = AsyncNotifierProvider<TrainersNotifier, List<Trainer>>(TrainersNotifier.new);

class TrainerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

final trainerSearchQueryProvider = NotifierProvider<TrainerSearchQueryNotifier, String>(TrainerSearchQueryNotifier.new);

final filteredTrainersProvider = Provider<AsyncValue<List<Trainer>>>((ref) {
  final trainersState = ref.watch(trainersProvider);
  final searchQuery = ref.watch(trainerSearchQueryProvider).toLowerCase();

  return trainersState.whenData((trainers) {
    return trainers.where((trainer) {
      return trainer.name.toLowerCase().contains(searchQuery) ||
             trainer.specialization.toLowerCase().contains(searchQuery);
    }).toList();
  });
});

class IsTrainerListViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isTrainerListView') ?? true;
  }

  void setMode(bool isList) {
    state = isList;
    ref.read(sharedPreferencesProvider).setBool('isTrainerListView', isList);
  }
}

final isTrainerListViewProvider = NotifierProvider<IsTrainerListViewNotifier, bool>(IsTrainerListViewNotifier.new);

