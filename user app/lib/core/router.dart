import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/auth_provider.dart';
import 'package:user_app/features/auth/login_screen.dart';
import 'package:user_app/features/auth/change_password_screen.dart';
import 'package:user_app/features/dashboard/dashboard_screen.dart';
import 'package:user_app/features/onboarding/splash_screen.dart';
import 'package:user_app/features/onboarding/onboarding_screen.dart';
import 'package:user_app/features/auth/forgot_password_screen.dart';
import 'package:user_app/features/auth/reset_password_screen.dart';
import 'package:user_app/features/payment/payment_screen.dart';
import 'package:user_app/features/support/support_screen.dart';
import 'package:user_app/features/notifications/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<bool>(false);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isInitializing != next.isInitializing ||
        previous?.hasSeenOnboarding != next.hasSeenOnboarding) {
      notifier.value = !notifier.value;
    }
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final hasSeenOnboarding = authState.hasSeenOnboarding;
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isResetPassword = state.matchedLocation == '/reset-password';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (authState.isInitializing) {
        return isSplash ? null : '/splash';
      }

      if (!isAuth) {
        if (!hasSeenOnboarding) {
          return isOnboarding ? null : '/onboarding';
        }
        final isAuthRoute = isLoggingIn || isForgotPassword || isResetPassword;
        return isAuthRoute ? null : '/login';
      }

      final isAuthRoute = isLoggingIn || isForgotPassword || isResetPassword || isSplash || isOnboarding;
      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final plan = state.extra as Map<String, dynamic>;
          return PaymentScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
