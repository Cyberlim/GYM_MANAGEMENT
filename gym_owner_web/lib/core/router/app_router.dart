import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final isGymSetup = prefs.getBool('isGymSetup') ?? false;
    
    final isPublicRoute = state.uri.path == '/login' || 
                          state.uri.path == '/signup' || 
                          state.uri.path.startsWith('/verify-email') || 
                          state.uri.path.startsWith('/suspended') || 
                          state.uri.path == '/forgot-password' || 
                          state.uri.path == '/';

    if (token == null && !isPublicRoute) {
      return '/login';
    }

    if (token != null) {
      final isOnboardingRoute = state.uri.path == '/gym-setup' ||
                                state.uri.path == '/start-trial' ||
                                state.uri.path == '/choose-plan' ||
                                state.uri.path == '/payment' ||
                                state.uri.path == '/success';
                                
      if (!isGymSetup && !isOnboardingRoute && !isPublicRoute) {
        return '/gym-setup';
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
