import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNameNotifier extends Notifier<String> {
  @override
  String build() {
    return 'FitZone';
  }

  void updateName(String newName) {
    state = newName;
  }
}

final appNameProvider = NotifierProvider<AppNameNotifier, String>(AppNameNotifier.new);
