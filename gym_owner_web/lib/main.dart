import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/core/theme/app_theme.dart';
import 'package:gym_owner_web/core/theme/theme_provider.dart';
import 'package:gym_owner_web/core/router/app_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const GymOwnerApp(),
    ),
  );
}

class GymOwnerApp extends ConsumerWidget {
  const GymOwnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Gym Owner Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      routerConfig: appRouter,
    );
  }
}

