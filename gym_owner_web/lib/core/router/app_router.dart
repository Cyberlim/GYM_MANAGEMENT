import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/verify_email_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/suspended_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/members/members_page.dart';
import '../../features/trainers/trainers_page.dart';
import '../../features/trainers/trainer_details_page.dart';
import '../../features/staff/staff_page.dart';
import '../../features/plans/plans_page.dart';
import '../../features/attendance/attendance_page.dart';
import '../../features/payments/payments_page.dart';
import '../../features/expenses/expenses_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/equipment/equipment_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/support/support_page.dart';
import '../../features/broadcast/broadcast_page.dart';
import '../../shared/widgets/main_layout.dart';

import '../../features/onboarding/landing_page.dart';
import '../../features/onboarding/signup_page.dart';
import '../../features/onboarding/gym_setup_page.dart';
import '../../features/onboarding/start_trial_page.dart';
import '../../features/onboarding/choose_plan_page.dart';
import '../../features/onboarding/payment_page.dart';
import '../../features/onboarding/success_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final isPublicRoute = state.uri.path == '/login' ||
                          state.uri.path == '/signup' ||
                          state.uri.path.startsWith('/verify-email') ||
                          state.uri.path.startsWith('/suspended') ||
                          state.uri.path == '/forgot-password' ||
                          state.uri.path == '/';

    // No token — only allow public routes
    if (token == null) {
      if (!isPublicRoute) return '/login';
      return null;
    }

    // Token exists — verify from the server so we always have fresh state
    bool isGymSetup = false;
    bool requiresUpgrade = false;
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final gymData = data['gym'] as Map<String, dynamic>?;
        isGymSetup = gymData != null;

        // Persist for use elsewhere in the app
        await prefs.setBool('isGymSetup', isGymSetup);

        if (isGymSetup && gymData != null) {
          final planStr = (gymData['subscriptionPlan'] ?? '').toString().toLowerCase();
          final isTrial = planStr == 'trial' || planStr == 'free trial';
          final hasPlan = planStr.isNotEmpty && planStr != 'null' && planStr != 'pending' && !isTrial;

          int trialDaysRemaining = 0;
          int planDaysRemaining = 0;

          if (isTrial && gymData['createdAt'] != null) {
            final createdAt = DateTime.parse(gymData['createdAt']);
            final trialEnd = createdAt.add(const Duration(days: 14));
            trialDaysRemaining = trialEnd.difference(DateTime.now()).inDays;
            if (trialDaysRemaining < 0) trialDaysRemaining = 0;
          }
          if (hasPlan && gymData['subscriptionExpiryDate'] != null) {
            final expiryDate = DateTime.parse(gymData['subscriptionExpiryDate']);
            planDaysRemaining = expiryDate.difference(DateTime.now()).inDays;
            if (planDaysRemaining < 0) planDaysRemaining = 0;
          } else if (hasPlan) {
            planDaysRemaining = 30;
          }
          requiresUpgrade = (!hasPlan && (!isTrial || trialDaysRemaining <= 0)) ||
                            (hasPlan && planDaysRemaining <= 0);
          await prefs.setBool('requiresUpgrade', requiresUpgrade);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or suspended — clear and redirect to login
        await prefs.remove('token');
        if (!isPublicRoute) return '/login';
        return null;
      }
    } catch (e) {
      // Network error — fall back to cached prefs
      isGymSetup = prefs.getBool('isGymSetup') ?? false;
      requiresUpgrade = prefs.getBool('requiresUpgrade') ?? false;
    }

    final isInitialOnboardingRoute =
        state.uri.path == '/gym-setup' || state.uri.path == '/start-trial';
    final isOnboardingRoute = isInitialOnboardingRoute ||
        state.uri.path == '/choose-plan' ||
        state.uri.path == '/payment' ||
        state.uri.path == '/success';

    if (!isGymSetup) {
      if (!isOnboardingRoute) return '/gym-setup';
    } else {
      if (isPublicRoute || isInitialOnboardingRoute) return '/dashboard';

      if (requiresUpgrade) {
        final isAllowedWhenLocked =
            state.uri.path == '/dashboard' || isOnboardingRoute;
        if (!isAllowedWhenLocked) return '/dashboard';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/verify-email/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        return VerifyEmailPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/suspended/:suspensionId',
      builder: (context, state) {
        final suspensionId = state.pathParameters['suspensionId'] ?? '';
        return SuspendedPage(suspensionId: suspensionId);
      },
    ),
    GoRoute(
      path: '/gym-setup',
      builder: (context, state) => const GymSetupPage(),
    ),
    GoRoute(
      path: '/start-trial',
      builder: (context, state) => const StartTrialPage(),
    ),
    GoRoute(
      path: '/choose-plan',
      builder: (context, state) => const ChoosePlanPage(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const PaymentPage(),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => const SuccessPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        String title = 'Dashboard';
        if (state.uri.path.contains('/members')) title = 'Members';
        if (state.uri.path.contains('/trainers')) title = 'Trainers';
        if (state.uri.path.contains('/staff')) title = 'Staff';
        if (state.uri.path.contains('/plans')) title = 'Membership Plans';
        if (state.uri.path.contains('/attendance')) title = 'Attendance';
        if (state.uri.path.contains('/profile')) title = 'Profile';
        if (state.uri.path.contains('/settings')) title = 'Settings';
        if (state.uri.path.contains('/support')) title = 'Support';
        if (state.uri.path.contains('/broadcasts')) title = 'Broadcasts';
        
        return MainLayout(title: title, child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/members',
          builder: (context, state) => const MembersPage(),
        ),
        GoRoute(
          path: '/trainers',
          builder: (context, state) => const TrainersPage(),
        ),
        GoRoute(
          path: '/staff',
          builder: (context, state) => const StaffPage(),
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => const PlansPage(),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendancePage(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsPage(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesPage(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/equipment',
          builder: (context, state) => const EquipmentPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportPage(),
        ),
        GoRoute(
          path: '/broadcasts',
          builder: (context, state) => const BroadcastPage(),
        ),
        GoRoute(
          path: '/trainer-details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 't1';
            return TrainerDetailsPage(trainerId: id);
          },
        ),
      ],
    ),
  ],
);
