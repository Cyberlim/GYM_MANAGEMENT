import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/mock/mock_data.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/data_table_widget.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  String _searchQuery = '';
  String _selectedPlan = 'All';

  @override
  Widget build(BuildContext context) {
    return ref.watch(superadminGymsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (gyms) {
        final query = _searchQuery.toLowerCase();
        
        // Filter gyms for the table
        final filteredGyms = gyms.where((gym) {
          if (_selectedPlan != 'All' && gym['plan'] != _selectedPlan) return false;
          if (query.isEmpty) return true;
          return gym['gymName'].toString().toLowerCase().contains(query) || gym['ownerName'].toString().toLowerCase().contains(query);
        }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Subscriptions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and monitor all active subscriptions across the platform.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 300,
                      height: 40,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search gym or owner...',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildDropdown('Plan', _selectedPlan, ['All', 'Basic', 'Pro', 'Enterprise'], (val) => setState(() => _selectedPlan = val!)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Table
          DataTableWidget(
            columns: const ['Gym Name', 'Owner', 'Plan', 'Active Members', 'Status', 'Registered'],
            rows: filteredGyms.map((gym) {
              final regDate = DateTime.tryParse(gym['registeredAt'] ?? '') ?? DateTime.now();
              return [
                Text(gym['gymName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(gym['ownerName'] ?? ''),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    gym['plan'] ?? '',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                ),
                Text((gym['activeMembers'] ?? 0).toString()),
                _buildStatusBadge(gym['status'] ?? ''),
                Text('${regDate.month}/${regDate.day}/${regDate.year}'),
              ];
            }).toList(),
          ),
        ],
      ),
    );
    },
  );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'Pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Suspended':
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
