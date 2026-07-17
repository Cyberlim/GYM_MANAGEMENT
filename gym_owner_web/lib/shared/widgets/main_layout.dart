import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/core/theme/theme_provider.dart';
import 'package:gym_owner_web/core/providers/app_settings_provider.dart';
import 'package:gym_owner_web/features/support/providers/support_provider.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/dashboard/providers/events_provider.dart';
import 'package:gym_owner_web/features/notifications/providers/notifications_provider.dart';
import 'package:gym_owner_web/core/providers/user_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/features/staff/providers/staff_provider.dart';
import 'package:gym_owner_web/features/members/members_page.dart';
import 'package:gym_owner_web/features/staff/staff_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gym_owner_web/data/services/socket_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String title;

  const MainLayout({super.key, required this.child, required this.title});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocket();
    });
  }

  void _initSocket() {
    final userState = ref.read(userProvider).value;
    if (userState != null && userState.user['_id'] != null) {
      final socketService = SocketService();
      socketService.initSocket(userState.user['_id']);
      socketService.onAccountSuspended = (data) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        ref.read(userProvider.notifier).clearUserData();
        socketService.disconnect();
        if (mounted) {
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has been suspended.')),
          );
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: showSidebar ? null : const Drawer(
        width: 260,
        backgroundColor: Color(0xFF161616),
        child: _Sidebar()
      ),
      body: Row(
        children: [
          if (showSidebar) const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final int unreadCount = ref.watch(unreadNotificationsCountProvider);
    final String appName = ref.watch(appNameProvider);
    final userState = ref.watch(userProvider);

    int trialDaysRemaining = 0;
    bool isTrial = false;
    
    if (userState.value != null && userState.value!.gym != null) {
      final gymData = userState.value!.gym!;
      isTrial = gymData['trialActive'] == true || gymData['trialActive'] == 'true';
      if (isTrial && gymData['createdAt'] != null) {
         final createdAt = DateTime.parse(gymData['createdAt']);
         final trialEnd = createdAt.add(const Duration(days: 14));
         trialDaysRemaining = trialEnd.difference(DateTime.now()).inDays;
         if (trialDaysRemaining < 0) trialDaysRemaining = 0;
      }
    }

    return Container(
      width: 260,
      color: const Color(0xFF161616), // Dark sidebar background
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFFF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.dumbbell, color: Color(0xFFCFFF50), size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'GYM MANAGEMENT',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: LucideIcons.layoutDashboard,
                  title: 'Dashboard',
                  isActive: location == '/dashboard',
                  route: '/dashboard',
                  isMainTab: true,
                ),
                const _SidebarSectionLabel(title: 'PEOPLE'),
                _SidebarItem(
                  icon: LucideIcons.users,
                  title: 'Members',
                  isActive: location == '/members',
                  route: '/members',
                ),
                _SidebarItem(
                  icon: LucideIcons.contact,
                  title: 'Trainers',
                  isActive: location == '/trainers',
                  route: '/trainers',
                ),
                _SidebarItem(
                  icon: LucideIcons.userCheck,
                  title: 'Staff',
                  isActive: location == '/staff',
                  route: '/staff',
                ),

                const _SidebarSectionLabel(title: 'MEMBERSHIP'),
                _SidebarItem(
                  icon: LucideIcons.creditCard,
                  title: 'Membership Plans',
                  isActive: location == '/plans',
                  route: '/plans',
                ),
                _SidebarItem(
                  icon: LucideIcons.clock,
                  title: 'Attendance',
                  isActive: location == '/attendance',
                  route: '/attendance',
                ),

                const _SidebarSectionLabel(title: 'FINANCE'),
                _SidebarItem(
                  icon: LucideIcons.creditCard,
                  title: 'Payments',
                  isActive: location == '/payments',
                  route: '/payments',
                ),
                _SidebarItem(
                  icon: LucideIcons.pieChart,
                  title: 'Expenses',
                  isActive: location == '/expenses',
                  route: '/expenses',
                ),
                const _SidebarSectionLabel(title: 'OPERATIONS'),
                _SidebarItem(
                  icon: LucideIcons.package,
                  title: 'Inventory',
                  isActive: location == '/inventory',
                  route: '/inventory',
                ),
                _SidebarItem(
                  icon: LucideIcons.dumbbell,
                  title: 'Equipment',
                  isActive: location == '/equipment',
                  route: '/equipment',
                ),

                const _SidebarSectionLabel(title: 'REPORTS'),
                _SidebarItem(
                  icon: LucideIcons.barChart2,
                  title: 'Reports & Analytics',
                  isActive: location == '/reports',
                  route: '/reports',
                ),

                const _SidebarSectionLabel(title: 'COMMUNICATION'),
                _SidebarItem(
                  icon: LucideIcons.bellRing,
                  title: 'Notifications',
                  isActive: location == '/notifications',
                  route: '/notifications',
                  badgeCount: unreadCount,
                ),
                _SidebarItem(
                  icon: LucideIcons.lifeBuoy,
                  title: 'Support',
                  isActive: location == '/support',
                  route: '/support',
                ),

                const _SidebarSectionLabel(title: 'SYSTEM'),
                _SidebarItem(
                  icon: LucideIcons.settings,
                  title: 'Settings',
                  isActive: location == '/settings',
                  route: '/settings',
                ),
                _SidebarItem(
                  icon: LucideIcons.user,
                  title: 'Profile',
                  isActive: location == '/profile',
                  route: '/profile',
                ),

                // Upgrade Plan Widget
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C23), // Dark background for the card
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.zap, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isTrial ? '$trialDaysRemaining Days Trial Left' : 'Free Plan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upgrade to Pro for more features.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.push('/choose-plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF161616),
                            elevation: 0,
                          ),
                          child: const Text('Upgrade Plan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String title;
  const _SidebarSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final String? route;
  final bool isMainTab;
  final int badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    this.route,
    this.isMainTab = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // For Dashboard tab which has a special pill style when active
    if (isMainTab) {
      return HoverZoomEffect(
        scale: 1.02,
        child: InkWell(
        onTap: () {
          if (route != null) context.go(route!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFDEBCA) : Colors.transparent, // Pale yellow from design
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white70,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (badgeCount > 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else if (isActive) ...[
                const Spacer(),
                const Icon(LucideIcons.chevronRight, color: Colors.black, size: 16),
              ]
            ],
          ),
        ),
      ),
    );
  }

    return HoverZoomEffect(
      scale: 1.02,
      child: InkWell(
      onTap: () {
        if (route != null) context.go(route!);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (badgeCount > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    ),
  );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showGreeting = screenWidth >= 1200;
    final showSidebar = screenWidth >= 900;
    final isMobile = screenWidth < 600;
    final events = ref.watch(eventsProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final unreadMessagesCount = ref.watch(unreadMessagesCountProvider);
    final supportMessages = ref.watch(supportMessagesProvider);
    final membersState = ref.watch(membersProvider);
    final trainersState = ref.watch(trainersProvider);
    final staffState = ref.watch(staffProvider);
    final userState = ref.watch(userProvider);

    String userName = '';
    String userRole = '';
    String profileImage = '';

    if (userState.value != null && userState.value!.user.isNotEmpty) {
      userName = userState.value!.user['name'] ?? '';
      userRole = userState.value!.user['role'] == 'superadmin' ? 'Superadmin' : 'Gym Owner';
      if (userState.value!.user['profileImage'] != null && userState.value!.user['profileImage'].toString().isNotEmpty) {
        profileImage = userState.value!.user['profileImage'];
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      color: Colors.transparent, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!showSidebar)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(LucideIcons.menu, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            
          // Left Greeting
          if (showGreeting)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning${userName.isNotEmpty ? ', $userName' : ''}! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s what\'s happening with your gym today.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

          if (showGreeting)
            const SizedBox(width: 24),

          // Right Actions
          Builder(
            builder: (context) {
              final searchField = Container(
                width: showGreeting ? 320 : null,
                height: 44,
                decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          final searchTerms = <String>[];
                          if (membersState.value != null) {
                            searchTerms.addAll(membersState.value!.map((m) => m.name));
                          }
                          if (trainersState.value != null) {
                            searchTerms.addAll(trainersState.value!.map((t) => t.name));
                          }
                          if (staffState.value != null) {
                            searchTerms.addAll(staffState.value!.map((s) => s.name));
                          }
                          
                          if (searchTerms.isEmpty) {
                            searchTerms.addAll([
                              'Emily Johnson', 'Michael Brown', 'Sophia Davis',
                              'John Doe', 'Sarah Connor', 'Invoice INV-001',
                              'Invoice INV-002', 'Gold Plan', 'Silver Plan',
                            ]);
                          }
                          final filtered = searchTerms.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                          if (filtered.isEmpty) {
                            return ['No results found'];
                          }
                          return filtered;
                        },
                        onSelected: (String selection) {
                          if (selection == 'No results found') return;
                          
                          final member = membersState.value?.cast<Member?>().firstWhere((m) => m?.name == selection, orElse: () => null);
                          final trainer = trainersState.value?.cast<Trainer?>().firstWhere((t) => t?.name == selection, orElse: () => null);
                          final staff = staffState.value?.cast<Staff?>().firstWhere((s) => s?.name == selection, orElse: () => null);

                          if (member != null) {
                            showMemberDetailsDialog(context, ref, member);
                          } else if (trainer != null) {
                            context.go('/trainer-details/${trainer.id}');
                          } else if (staff != null) {
                            showStaffDetailsDialog(context, ref, staff);
                          }
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                              prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 18),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: isMobile ? 250 : 320,
                                constraints: const BoxConstraints(maxHeight: 250),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    if (option == 'No results found') {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Text(option, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                      );
                                    }
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Text(option, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );

              final rightActions = Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Search Field
                  if (!isMobile)
                    showGreeting ? searchField : Expanded(child: searchField),
                  if (!isMobile)
                    const SizedBox(width: 16),
                
                // Action Icons
                if (screenWidth > 400) ...[
                  // Notifications
                  HoverZoomEffect(
                    scale: 1.1,
                    child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.surface,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const PopupMenuDivider(),
                      ...notifications.take(5).map((n) => PopupMenuItem(
                        value: n.id,
                        padding: EdgeInsets.zero,
                        onTap: () {
                          if (n.targetRoute != null) {
                            if (!n.isRead) {
                              ref.read(notificationsProvider.notifier).markAsRead(n.id);
                            }
                            context.go(n.targetRoute!);
                          }
                        },
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.bell, size: 16, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(timeago.format(n.timestamp), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'view_all',
                        child: Center(
                          child: Text('View All Notifications', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        onTap: () => context.go('/notifications'),
                      ),
                    ],
                    child: _buildIconWithBadge(context, LucideIcons.bell, badgeCount: unreadCount, isHoverZoomed: false),
                  ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Messages
                  HoverZoomEffect(
                    scale: 1.1,
                    child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (value) {
                      if (value == 'view_all') {
                        context.go('/support');
                      } else {
                        context.go('/support?messageId=$value');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const PopupMenuDivider(),
                      ...(supportMessages.value ?? []).where((m) => !m.isSentByMe).take(5).map((m) => PopupMenuItem(
                        value: m.id,
                        padding: EdgeInsets.zero,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                            color: m.isRead ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                child: Text(m.sender[0], style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(m.sender, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: m.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                                        Text(m.time, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(m.content, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(m.isRead ? 0.6 : 0.8), fontSize: 12, fontWeight: m.isRead ? FontWeight.normal : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'view_all',
                        child: Center(
                          child: Text('Open Support Chat', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    child: _buildIconWithBadge(context, LucideIcons.mail, badgeCount: unreadMessagesCount, isHoverZoomed: false),
                  ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Calendar
                  HoverZoomEffect(
                    scale: 1.1,
                    child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.surface,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const PopupMenuDivider(),
                      ...events.map((e) => PopupMenuItem(
                        value: e.id,
                        padding: EdgeInsets.zero,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.calendar, size: 16, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(e.date, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'add_event',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Add Event', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'add_event') {
                        _showAddEventDialog(context, ref);
                      }
                    },
                    child: _buildIconWithBadge(context, LucideIcons.calendar, badgeCount: events.length, isHoverZoomed: false),
                  ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Dark Mode Toggle
                Builder(
                  builder: (context) {
                    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                    return _buildIconWithBadge(
                      context,
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                      onTap: () {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    );
                  }
                ),
                const SizedBox(width: 16),
                
                // Profile
                HoverZoomEffect(
                  scale: 1.02,
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (value) async {
                      if (value == 'profile') {
                        context.go('/profile');
                      } else if (value == 'settings') {
                        context.go('/settings');
                      } else if (value == 'logout') {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');
                        SocketService().disconnect();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Text('My Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(LucideIcons.settings, size: 16, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(LucideIcons.logOut, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 12),
                            Text('Log Out', style: TextStyle(color: Colors.red.shade400)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                            onBackgroundImageError: (_, __) {},
                            child: profileImage.isEmpty ? Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.primary) : null,
                          ),
                          if (screenWidth > 500) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                                ),
                                Text(
                                  userRole,
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.chevronDown, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );

              return showGreeting ? rightActions : Expanded(child: rightActions);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithBadge(BuildContext context, IconData icon, {int? badgeCount, VoidCallback? onTap, bool isHoverZoomed = true}) {
    Widget iconContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    
    if (isHoverZoomed) {
      return HoverZoomEffect(
        scale: 1.1,
        child: iconContent,
      );
    }
    
    return iconContent;
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Add Upcoming Event', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Date & Time (e.g., Tomorrow, 10:00 AM)',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && dateController.text.isNotEmpty) {
                  final newEvent = EventModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    date: dateController.text,
                  );
                  ref.read(eventsProvider.notifier).addEvent(newEvent);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Save Event'),
            ),
          ],
        );
      },
    );
  }
}
