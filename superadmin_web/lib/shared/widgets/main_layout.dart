import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:superadmin_web/core/theme/app_theme.dart';
import 'package:superadmin_web/core/theme/theme_provider.dart';
import 'package:superadmin_web/features/profile/profile_provider.dart';
import 'package:superadmin_web/features/notifications/notification_provider.dart';
import 'package:superadmin_web/features/calendar/calendar_provider.dart';
import 'package:superadmin_web/features/calendar/widgets/add_event_dialog.dart';
import 'package:superadmin_web/features/support/support_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superadmin_web/data/providers/superadmin_provider.dart';

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
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScreenTypeLayout.builder(
        mobile: (context) => _MobileLayout(title: widget.title, child: widget.child),
        tablet: (context) => _DesktopLayout(title: widget.title, isTablet: true, child: widget.child),
        desktop: (context) => _DesktopLayout(title: widget.title, isTablet: false, child: widget.child),
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const _MobileLayout({required this.child, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          const _NotificationDropdown(),
          const SizedBox(width: 8),
          const _MessagesDropdown(),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'search_dialog') {
                showDialog(
                  context: context,
                  builder: (context) => Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight),
                      child: Material(
                        color: Colors.transparent,
                        child: _GlobalSearchField(),
                      ),
                    ),
                  ),
                );
              } else if (value == 'calendar_dialog') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use desktop view to manage events directly.')));
              } else if (value == 'profile') context.go('/profile');
              else if (value == 'settings') context.go('/settings');
              else if (value == 'theme') ref.read(themeProvider.notifier).toggleTheme();
              else if (value == 'logout') {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.remove('token');
                  if (context.mounted) context.go('/login');
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'search_dialog', child: Row(children: [Icon(LucideIcons.search, size: 16), const SizedBox(width: 12), const Text('Search')])),
              PopupMenuItem(value: 'calendar_dialog', child: Row(children: [Icon(LucideIcons.calendar, size: 16), const SizedBox(width: 12), const Text('Upcoming Events')])),
              PopupMenuItem(value: 'theme', child: Row(children: [Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 16), const SizedBox(width: 12), Text(isDark ? 'Light Mode' : 'Dark Mode')])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'profile', child: Row(children: [Icon(LucideIcons.user, size: 16), const SizedBox(width: 12), const Text('My Profile')])),
              PopupMenuItem(value: 'settings', child: Row(children: [Icon(LucideIcons.settings, size: 16), const SizedBox(width: 12), const Text('Settings')])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Row(children: [const Icon(LucideIcons.logOut, size: 16, color: Colors.red), const SizedBox(width: 12), const Text('Logout', style: TextStyle(color: Colors.red))])),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                backgroundImage: profile.avatarBytes != null 
                    ? MemoryImage(profile.avatarBytes!) 
                    : (profile.profileImage != null && profile.profileImage!.isNotEmpty 
                        ? NetworkImage(profile.profileImage!) as ImageProvider 
                        : null),
                child: profile.avatarBytes == null && (profile.profileImage == null || profile.profileImage!.isEmpty)
                    ? Text(profile.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface)) 
                    : null,
              ),
            ),
          ),
        ],
      ),
      drawer: _Sidebar(isMobile: true, currentTitle: title),
      body: child,
    );
  }
}

class _GlobalSearchField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsState = ref.watch(superadminGymsProvider);
    final gyms = gymsState.value ?? [];

    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Autocomplete<Object>(
              displayStringForOption: (option) {
                if (option is String) return option;
                if (option is Map) return option['gymName'] ?? '';
                return option.toString();
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Object>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                final filtered = gyms.where((gym) {
                  if (gym is! Map) return false;
                  final gymName = (gym['gymName'] ?? '').toString().toLowerCase();
                  final ownerName = (gym['ownerName'] ?? '').toString().toLowerCase();
                  return gymName.contains(query) || ownerName.contains(query);
                }).toList().cast<Object>();

                if (filtered.isEmpty) {
                  return ['no search avilable'];
                }
                return filtered;
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Search gyms, owners, i...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    hoverColor: Colors.transparent,
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
                      width: 220,
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
                          final option = options.elementAt(index);
                          final isNoResult = option is String && option == 'no search avilable';
                          final displayText = isNoResult 
                              ? option as String
                              : (option is Map ? '${option['gymName']} (${option['ownerName']})' : option.toString());

                          return InkWell(
                            onTap: () {
                              if (isNoResult) return;
                              onSelected(option);
                              
                              // Check if we are inside a dialog (for mobile view search)
                              if (MediaQuery.of(context).size.width < 900 && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              if (option is Map && option['id'] != null) {
                                context.go('/gyms/${option['id']}');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(displayText, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final bool isTablet;

  const _DesktopLayout({required this.child, required this.title, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Sidebar(isMobile: false, isTablet: isTablet, currentTitle: title),
        Expanded(
          child: Column(
            children: [
              _TopNavigationBar(title: title),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final String currentTitle;

  const _Sidebar({this.isMobile = false, this.isTablet = false, required this.currentTitle});

  @override
  Widget build(BuildContext context) {
    final width = isMobile ? 280.0 : (isTablet ? 80.0 : 260.0);
    
    Widget content = Container(
      width: width,
      color: AppTheme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Logo
          if (!isTablet || isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'GYM ',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'X',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Text('X', style: TextStyle(fontSize: 28, color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(icon: LucideIcons.layoutDashboard, title: 'Dashboard', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Dashboard', route: '/dashboard'),
                
                if (!isTablet || isMobile)
                  const Padding(padding: EdgeInsets.only(left: 24, top: 24, bottom: 8), child: Text('MANAGEMENT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
                  
                _SidebarItem(icon: LucideIcons.users, title: 'Gym Owners', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Gym Management', route: '/gyms'),
                _SidebarItem(icon: LucideIcons.list, title: 'Subscription Plans', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Plans & Pricing', route: '/plans'),
                _SidebarItem(icon: LucideIcons.clock, title: 'Active Subscriptions', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Subscriptions', route: '/subscriptions'),
                
                if (!isTablet || isMobile)
                  const Padding(padding: EdgeInsets.only(left: 24, top: 24, bottom: 8), child: Text('FINANCE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
                  
                _SidebarItem(icon: LucideIcons.wallet, title: 'Finance', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Finance & Billing', route: '/finance'),

                if (!isTablet || isMobile)
                  const Padding(padding: EdgeInsets.only(left: 24, top: 24, bottom: 8), child: Text('ANALYTICS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
                  
                _SidebarItem(icon: LucideIcons.barChart2, title: 'Analytics', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Analytics', route: '/analytics'),
                _SidebarItem(icon: LucideIcons.fileOutput, title: 'Reports', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Reports', route: '/reports'),

                if (!isTablet || isMobile)
                  const Padding(padding: EdgeInsets.only(left: 24, top: 24, bottom: 8), child: Text('SUPPORT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
                  
                _SidebarItem(icon: LucideIcons.lifeBuoy, title: 'Support', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Support', route: '/support'),

                if (!isTablet || isMobile)
                  const Padding(padding: EdgeInsets.only(left: 24, top: 24, bottom: 8), child: Text('SYSTEM', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600))),
                  
                _SidebarItem(icon: LucideIcons.settings, title: 'Settings', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Settings', route: '/settings'),
                _SidebarItem(icon: LucideIcons.user, title: 'Profile', isTablet: isTablet, isMobile: isMobile, isSelected: currentTitle == 'Profile', route: '/profile'),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Drawer(child: content);
    }
    return content;
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isTablet;
  final bool isMobile;
  final bool isSelected;
  final String? route;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isTablet = false,
    this.isMobile = false,
    this.isSelected = false,
    this.route,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final showTitle = !widget.isTablet || widget.isMobile;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.route != null) {
            context.go(widget.route!);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? const Color(0xFF2A2A2A) 
                : (_isHovering ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: widget.isSelected ? AppTheme.accentColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: showTitle ? 16 : 0, 
            vertical: 10
          ),
          child: AnimatedScale(
            scale: _isHovering ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Row(
              mainAxisAlignment: showTitle ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSelected ? AppTheme.accentColor : (_isHovering ? Colors.white : Colors.white70),
                  size: 18,
                ),
                if (showTitle) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: widget.isSelected ? Colors.white : (_isHovering ? Colors.white : Colors.white70),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavigationBar extends ConsumerWidget {
  final String title;

  const _TopNavigationBar({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final profile = ref.watch(profileProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileOrTablet = screenWidth < 900;
    
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
      color: Colors.transparent, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, Super Admin! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s what\'s happening on the platform today.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          
          // Right Side Actions
          Row(
            children: [
              // Search Bar
              if (!isMobileOrTablet) ...[
                _GlobalSearchField(),
                const SizedBox(width: 16),
              ],
              
              const _NotificationDropdown(),
              const SizedBox(width: 12),
              const SizedBox(width: 12),
              const _MessagesDropdown(),
              if (!isMobileOrTablet) ...[
                const SizedBox(width: 12),
                const _CalendarDropdown(),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  context, 
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  onTap: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  }
                ),
              ],
              const SizedBox(width: 16),
              
              // Profile Dropdown
              HoverIcon(
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tooltip: 'Profile options',
                  onSelected: (value) {
                    if (value == 'search_dialog') {
                      showDialog(
                        context: context,
                        builder: (context) => Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: kToolbarHeight),
                            child: Material(
                              color: Colors.transparent,
                              child: _GlobalSearchField(),
                            ),
                          ),
                        ),
                      );
                    } else if (value == 'calendar_dialog') {
                      // Note: since CalendarDropdown uses a popup menu natively, we'll just show its internal builder directly or navigate.
                      // The simplest approach is to use a dialog wrapper:
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use desktop view to manage events directly.')));
                    } else if (value == 'theme_toggle') {
                      ref.read(themeProvider.notifier).toggleTheme();
                    } else if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      context.go('/settings');
                    } else if (value == 'logout') {
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.remove('token');
                        if (context.mounted) {
                          context.go('/login');
                        }
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    if (isMobileOrTablet) ...[
                      PopupMenuItem(
                        value: 'search_dialog',
                        child: Row(
                          children: [
                            Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            const Text('Search'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'calendar_dialog',
                        child: Row(
                          children: [
                            Icon(LucideIcons.calendar, size: 16, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            const Text('Upcoming Events'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'theme_toggle',
                        child: Row(
                          children: [
                            Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 16, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Text(isDark ? 'Light Mode' : 'Dark Mode'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                    ],
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('My Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(LucideIcons.settings, size: 16, color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.logOut, size: 16, color: Colors.red),
                          const SizedBox(width: 12),
                          const Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).colorScheme.onSurface,
                          backgroundImage: profile.avatarBytes != null 
                              ? MemoryImage(profile.avatarBytes!) 
                              : (profile.profileImage != null && profile.profileImage!.isNotEmpty 
                                  ? NetworkImage(profile.profileImage!) as ImageProvider 
                                  : null),
                          child: profile.avatarBytes == null && (profile.profileImage == null || profile.profileImage!.isEmpty)
                              ? Text(profile.initials, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface)) 
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(profile.fullName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            Text(profile.role, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, IconData icon, {int? badgeCount, VoidCallback? onTap}) {
    return HoverIcon(
      child: Stack(
        clipBehavior: Clip.none,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: CircleBorder(
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: onTap ?? () {},
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ),
        if (badgeCount != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(), 
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
              ),
            ),
          ),
      ],
    ));
  }
}

class _NotificationDropdown extends ConsumerWidget {
  const _NotificationDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = ref.read(notificationProvider.notifier).unreadCount;
    return HoverIcon(
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.bell, size: 18, color: Colors.grey),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...notifications.map((n) {
            Widget iconWidget;
            switch (n.type) {
              case NotificationType.registration:
                iconWidget = Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.userPlus, size: 16, color: Colors.green));
                break;
              case NotificationType.payment:
                iconWidget = Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.dollarSign, size: 16, color: Colors.blue));
                break;
              case NotificationType.system:
                iconWidget = Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.server, size: 16, color: Colors.orange));
                break;
              case NotificationType.support:
                iconWidget = Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.lifeBuoy, size: 16, color: Colors.purple));
                break;
            }

            return PopupMenuItem<String>(
              value: n.id,
              onTap: () {
                ref.read(notificationProvider.notifier).markAsRead(n.id);
                if (n.route != null) {
                  context.go(n.route!);
                }
              },
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                n.title, 
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                )
                              ),
                              if (!n.isRead)
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ];
      },
    ));
  }
}

class _MessagesDropdown extends ConsumerWidget {
  const _MessagesDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportProvider);
    final unreadTickets = tickets.where((t) => t.messages.any((m) => !m.isRead && !m.isFromAdmin)).toList();

    return HoverIcon(
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Support Messages',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.mail, size: 18, color: Colors.grey),
          ),
          if (unreadTickets.isNotEmpty)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '${unreadTickets.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Text('Support Tickets', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ),
          const PopupMenuDivider(),
          ...unreadTickets.take(3).map((ticket) {
            return PopupMenuItem<String>(
              value: ticket.id,
              onTap: () {
                ref.read(selectedTicketIdProvider.notifier).setTicketId(ticket.id);
                context.go('/support');
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(ticket.gymOwnerName.substring(0, 1))),
                title: Text(ticket.gymOwnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ticket.messages.last.message, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          }),
          if (unreadTickets.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: Text('No unread tickets')),
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            child: const Center(child: Text('View all tickets', style: TextStyle(color: Colors.blue))),
            onTap: () {
              context.go('/support');
            },
          ),
        ];
      },
    ));
  }
}

class _CalendarDropdown extends ConsumerWidget {
  const _CalendarDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(calendarProvider);
    return HoverIcon(
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Calendar',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Icon(LucideIcons.calendar, size: 18, color: Colors.grey),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ),
          const PopupMenuDivider(),
          ...events.map((e) {
            return PopupMenuItem<String>(
              value: e.id,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: e.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.date.day.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: e.color)), 
                      Text(_getMonth(e.date.month), style: TextStyle(fontSize: 10, color: e.color))
                    ],
                  ),
                ),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(e.description),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                  onPressed: () {
                    ref.read(calendarProvider.notifier).deleteEvent(e.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }),
          if (events.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: Text('No upcoming events')),
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            child: const Center(child: Text('+ Add New Event', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
            onTap: () {
              Future.delayed(Duration.zero, () {
                showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(),
                );
              });
            },
          ),
        ];
      },
    ));
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class HoverIcon extends StatefulWidget {
  final Widget child;
  const HoverIcon({super.key, required this.child});

  @override
  State<HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovering ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
