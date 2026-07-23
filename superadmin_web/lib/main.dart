import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superadmin_web/core/theme/app_theme.dart';
import 'package:superadmin_web/core/theme/theme_provider.dart';
import 'package:superadmin_web/core/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(child: SuperAdminApp()));
}

class SuperAdminApp extends ConsumerWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gym Management Super Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),
      themeAnimationDuration: Duration.zero,
      routerConfig: appRouter,
    );
  }
}

