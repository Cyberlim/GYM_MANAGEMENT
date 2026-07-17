import 'package:go_router/go_router.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/gyms/gym_list_page.dart';
import '../../features/subscriptions/subscriptions_page.dart';
import '../../features/support/support_page.dart';
import '../../shared/widgets/main_layout.dart';
import '../../features/broadcast/broadcast_page.dart';
import '../../features/admins/admins_page.dart';

import '../../features/gyms/gym_owner_details_page.dart';
import '../../features/gyms/person_details_page.dart';
import '../../features/plans/plans_page.dart';
import '../../features/finance/finance_page.dart';
import '../../features/analytics/analytics_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/profile/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        String title = 'Dashboard';
        if (state.uri.path.contains('/gyms')) title = 'Gym Management';
        if (state.uri.path.contains('/subscriptions')) title = 'Subscriptions';
        if (state.uri.path.contains('/plans')) title = 'Plans & Pricing';
        if (state.uri.path.contains('/finance')) title = 'Finance & Billing';
        if (state.uri.path.contains('/analytics')) title = 'Analytics';
        if (state.uri.path.contains('/reports')) title = 'Reports';
        if (state.uri.path.contains('/support')) title = 'Support';
        if (state.uri.path.contains('/settings')) title = 'Settings';
        if (state.uri.path.contains('/profile')) title = 'Profile';
        if (state.uri.path.contains('/broadcast')) title = 'Send Broadcast';
        
        return MainLayout(title: title, child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/gyms',
          builder: (context, state) => GymListPage(
            initialPlan: state.uri.queryParameters['plan'],
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => GymOwnerDetailsPage(
                gymId: state.pathParameters['id'] ?? '',
              ),
              routes: [
                GoRoute(
                  path: 'person/:personId',
                  builder: (context, state) {
                    return PersonDetailsPage(
                      gymId: state.pathParameters['id'] ?? '',
                      personId: state.pathParameters['personId'] ?? '',
                      role: state.uri.queryParameters['role'] ?? 'Member',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => const SubscriptionsPage(),
          routes: [
            GoRoute(
              path: 'plan/:planName',
              builder: (context, state) => GymListPage(
                initialPlan: state.pathParameters['planName'],
                showBackButton: true,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final showAddPlan = extra?['showAddPlan'] as bool? ?? false;
            return PlansPage(showAddPlan: showAddPlan);
          },
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int? ?? 0;
            return FinancePage(initialTabIndex: initialTab);
          },
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportPage(),
        ),
        GoRoute(
          path: '/broadcast',
          builder: (context, state) => const BroadcastPage(),
        ),
        GoRoute(
          path: '/admins',
          builder: (context, state) => const AdminsPage(),
        ),
      ],
    ),
  ],
);
