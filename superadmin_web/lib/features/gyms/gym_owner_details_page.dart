import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';
import '../../data/mock/mock_data.dart';
import '../../core/theme/app_theme.dart';

class GymOwnerDetailsPage extends ConsumerWidget {
  final String gymId;

  const GymOwnerDetailsPage({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(superadminGymDetailsProvider(gymId)).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (gym) {
        if (gym.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Gym Details')),
            body: const Center(child: Text('Gym not found')),
          );
        }

        final gymName = gym['gymName'] ?? 'Unknown Gym';
        final ownerName = gym['ownerName'] ?? 'Unknown Owner';
        final email = gym['email'] ?? 'N/A';
        final phone = gym['phone'] ?? 'N/A';
        final status = gym['status'] ?? 'Pending';
        final plan = gym['plan'] ?? 'Basic';
        final regDateStr = gym['registeredAt'] ?? '';
        final DateTime regDate = DateTime.tryParse(regDateStr) ?? DateTime.now();
        final joinedText = 'Joined: ${regDate.month}/${regDate.day}/${regDate.year}';
        final imageUrl = gym['imageUrl'] as String?;
        final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft),
                onPressed: () => context.go('/gyms'),
              ),
              const SizedBox(width: 8),
              Text(
                'Gym Owner Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                child: Image.network(imageUrl, fit: BoxFit.contain),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover))
                      : Icon(LucideIcons.user, size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 0, width: isMobile ? 0 : 24),
                // Details
                if (isMobile)
                  Column(
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Text(
                        gymName,
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Owner: $ownerName',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      isMobile 
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.mail, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(phone, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(LucideIcons.mail, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(width: 24),
                              Icon(LucideIcons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(phone, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'Active' ? Colors.green.withOpacity(0.1) : (status == 'Pending' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(status, style: TextStyle(color: status == 'Active' ? Colors.green : (status == 'Pending' ? Colors.orange : Colors.red), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(width: 12),
                          Text(joinedText, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                if (!isMobile)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gymName,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner: $ownerName',
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(LucideIcons.mail, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(width: 24),
                            Icon(LucideIcons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(phone, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'Active' ? Colors.green.withOpacity(0.1) : (status == 'Pending' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(status, style: TextStyle(color: status == 'Active' ? Colors.green : (status == 'Pending' ? Colors.orange : Colors.red), fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                            const SizedBox(width: 12),
                            Text(joinedText, style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                // Action Buttons
                SizedBox(height: isMobile ? 24 : 0),
                Column(
                  children: [
                    if (gym['userStatus'] != 'suspended')
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await SuperadminActions.suspendGymOwner(gym['id']);
                            ref.invalidate(superadminGymDetailsProvider(gymId));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        icon: Icon(LucideIcons.ban, size: 16),
                        label: Text('Suspend Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await SuperadminActions.reactivateGymOwner(gym['id']);
                            ref.invalidate(superadminGymDetailsProvider(gymId));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        icon: Icon(LucideIcons.checkCircle, size: 16),
                        label: Text('Reactivate Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lower Section (Stats and Recent Activity)
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: [
              // Stats
              if (isMobile)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gym Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 24),
                      _buildStatRow(LucideIcons.users, 'Total Members', '${gym['stats']?['totalMembers'] ?? 0}'),
                      const Divider(height: 32),
                      _buildStatRow(LucideIcons.dollarSign, 'Monthly Revenue', gym['stats']?['monthlyRevenue'] ?? '\$0'),
                      const Divider(height: 32),
                      _buildStatRow(LucideIcons.creditCard, 'Current Plan', plan),
                      const Divider(height: 32),
                      _buildStatRow(LucideIcons.trendingUp, 'Growth (MoM)', gym['stats']?['growth'] ?? '+0%'),
                    ],
                  ),
                ),
              if (!isMobile)
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gym Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 24),
                        _buildStatRow(LucideIcons.users, 'Total Members', '${gym['stats']?['totalMembers'] ?? 0}'),
                        const Divider(height: 32),
                        _buildStatRow(LucideIcons.dollarSign, 'Monthly Revenue', gym['stats']?['monthlyRevenue'] ?? '\$0'),
                        const Divider(height: 32),
                        _buildStatRow(LucideIcons.creditCard, 'Current Plan', plan),
                        const Divider(height: 32),
                        _buildStatRow(LucideIcons.trendingUp, 'Growth (MoM)', gym['stats']?['growth'] ?? '+0%'),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: isMobile ? 24 : 0, width: isMobile ? 0 : 24),
              // Activity
              if (isMobile)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 24),
                      if (gym['recentActivity'] != null && (gym['recentActivity'] as List).isNotEmpty)
                        ...(gym['recentActivity'] as List).map((a) {
                          IconData iconData = LucideIcons.activity;
                          if (a['icon'] == 'userPlus') iconData = LucideIcons.userPlus;
                          else if (a['icon'] == 'creditCard') iconData = LucideIcons.creditCard;
                          else if (a['icon'] == 'users') iconData = LucideIcons.users;
                          
                          return _buildActivityItem(a['title'] ?? 'Activity', a['date'] ?? '', iconData);
                        })
                      else
                        const Text('No recent activity', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              if (!isMobile)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 24),
                        if (gym['recentActivity'] != null && (gym['recentActivity'] as List).isNotEmpty)
                          ...(gym['recentActivity'] as List).map((a) {
                            IconData iconData = LucideIcons.activity;
                            if (a['icon'] == 'userPlus') iconData = LucideIcons.userPlus;
                            else if (a['icon'] == 'creditCard') iconData = LucideIcons.creditCard;
                            else if (a['icon'] == 'users') iconData = LucideIcons.users;
                            
                            return _buildActivityItem(a['title'] ?? 'Activity', a['date'] ?? '', iconData);
                          })
                        else
                          const Text('No recent activity', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 24),
          
          // Tabbed Lists Section
          _TabbedListsSection(
            tabs: [
              _TabData(
                title: 'Staff Members',
                headerRow: _buildTableHeader(context, ['Name', 'Role', 'Email', 'Status']),
                data: List<Map<String, dynamic>>.from(gym['staff'] ?? []),
                rowBuilder: (context, item) => _buildStaffRow(context, gymId, item['_id'] ?? item['id'] ?? '', item['name'] ?? '', item['role'] ?? '', item['email'] ?? '', item['status'] ?? 'Active'),
              ),
              _TabData(
                title: 'Trainers',
                headerRow: _buildTableHeader(context, ['Name', 'Specialty', 'Email', 'Status']),
                data: List<Map<String, dynamic>>.from(gym['trainers'] ?? []),
                rowBuilder: (context, item) => _buildStaffRow(context, gymId, item['_id'] ?? item['id'] ?? '', item['name'] ?? '', item['role'] ?? 'Trainer', item['email'] ?? '', item['status'] ?? 'Active'),
              ),
              _TabData(
                title: 'Gym Members',
                headerRow: _buildTableHeader(context, ['Name', 'Plan Type', 'Join Date', 'Status']),
                data: List<Map<String, dynamic>>.from(gym['members'] ?? []),
                rowBuilder: (context, item) => _buildMemberRow(context, gymId, item['_id'] ?? item['id'] ?? '', item['name'] ?? '', item['membershipPlan'] ?? item['plan'] ?? '', item['joinDate'] ?? item['date'] ?? '', item['status'] ?? 'Active'),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTableHeader(BuildContext context, List<String> titles) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: titles.map((title) {
          int flex = title == 'STATUS' || title == 'Status' ? 1 : 2;
          return Expanded(
            flex: flex,
            child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildStaffRow(BuildContext context, String gymId, String id, String name, String role, String email, String status) {
    Color statusBg = status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    Color statusText = status == 'Active' ? Colors.green : Colors.red;

    return InkWell(
      onTap: () => context.go('/gyms/${Uri.encodeComponent(gymId)}/person/${Uri.encodeComponent(id)}?role=$role&name=${Uri.encodeComponent(name)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(LucideIcons.user, size: 14, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(role, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface))),
            Expanded(flex: 2, child: Text(email, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, String gymId, String id, String name, String plan, String date, String status) {
    Color statusBg = status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    Color statusText = status == 'Active' ? Colors.green : Colors.red;

    return InkWell(
      onTap: () => context.go('/gyms/${Uri.encodeComponent(gymId)}/person/${Uri.encodeComponent(id)}?role=Member&name=${Uri.encodeComponent(name)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(LucideIcons.user, size: 14, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(plan, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface))),
            Expanded(flex: 2, child: Text(date, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TabData {
  final String title;
  final Widget headerRow;
  final List<Map<String, dynamic>> data;
  final Widget Function(BuildContext, Map<String, dynamic>) rowBuilder;

  _TabData({
    required this.title,
    required this.headerRow,
    required this.data,
    required this.rowBuilder,
  });
}

class _TabbedListsSection extends StatefulWidget {
  final List<_TabData> tabs;

  const _TabbedListsSection({required this.tabs});

  @override
  State<_TabbedListsSection> createState() => _TabbedListsSectionState();
}

class _TabbedListsSectionState extends State<_TabbedListsSection> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentTab = widget.tabs[_selectedTabIndex];
    final filteredData = currentTab.data.where((item) {
      final name = item['name'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return name.split(' ').any((word) => word.startsWith(query));
    }).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.tabs.length, (index) {
                final tab = widget.tabs[index];
                final isSelected = _selectedTabIndex == index;
                return InkWell(
                  onTap: () => setState(() {
                    _selectedTabIndex = index;
                    _searchQuery = '';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(tab.title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${tab.data.length}', style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Divider(height: 1),
          
          // Content Area
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search ${currentTab.title.toLowerCase()} by name...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          currentTab.headerRow,
          Divider(height: 1),
          if (filteredData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: Text('No matching results found', style: TextStyle(color: Colors.grey))),
            )
          else
            ...filteredData.map((item) {
              return Column(
                children: [
                  currentTab.rowBuilder(context, item),
                  Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}
