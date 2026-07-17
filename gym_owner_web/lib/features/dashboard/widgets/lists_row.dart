import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class ListsRow extends StatelessWidget {
  final DashboardData data;
  
  const ListsRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        final children = [
          _buildListCard(
            context: context,
            title: 'Recent Members',
            route: '/members',
            child: _RecentMembersList(members: data.recentMembers),
          ),
          const SizedBox(width: 16),
          _buildListCard(
            context: context,
            title: 'Recent Payments',
            route: '/payments',
            child: _RecentPaymentsList(payments: data.recentTransactions),
          ),
          const SizedBox(width: 16),
          _buildListCard(
            context: context,
            title: 'Upcoming Renewals',
            route: '/members',
            child: _UpcomingRenewalsList(renewals: data.upcomingRenewals),
          ),
        ];

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((c) {
                if (c is SizedBox) return c;
                return SizedBox(width: 320, child: c);
              }).toList(),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: children[0]),
            children[1], // SizedBox
            Expanded(flex: 4, child: children[2]),
            children[3], // SizedBox
            Expanded(flex: 3, child: children[4]),
          ],
        );
      }
    );
  }

  Widget _buildListCard({required BuildContext context, required String title, required String route, required Widget child}) {
    return HoverZoomEffect(
      scale: 1.02,
      child: Container(
        height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go(route),
                  child: Row(
                    children: [
                      Text('View All', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, size: 16, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
}

class _RecentMembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  const _RecentMembersList({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: Text('No recent members.'));
    }

    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor, height: 1),
      itemBuilder: (context, index) {
        final m = members[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).dividerColor,
                backgroundImage: m['imageUrl'] != null && m['imageUrl']!.toString().isNotEmpty
                    ? NetworkImage(m['imageUrl'])
                    : null,
                child: m['imageUrl'] == null || m['imageUrl']!.toString().isEmpty
                    ? Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final planName = m['membershipPlan'] ?? 'Plan';
                    Color planColor;
                    if (planName.contains('Gold')) planColor = Colors.amber;
                    else if (planName.contains('Pro')) planColor = Colors.purple;
                    else if (planName.contains('Silver')) planColor = Colors.blueGrey;
                    else planColor = Colors.blue;
                    
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: planColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: planColor.withOpacity(0.3)),
                        ),
                        child: Text(planName, style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text(m['status'] ?? 'Active', style: TextStyle(
                      color: m['status'] == 'Active' ? Colors.green : Colors.red, 
                      fontSize: 12, 
                      fontWeight: FontWeight.w500
                    )),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  m['joinDate'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(m['joinDate'])) : '', 
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)
                ),
              ),
              Icon(LucideIcons.moreVertical, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        );
      },
    );
  }
}

class _RecentPaymentsList extends ConsumerWidget {
  final List<Map<String, dynamic>> payments;
  const _RecentPaymentsList({required this.payments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (payments.isEmpty) {
      return const Center(child: Text('No recent payments.'));
    }

    final members = ref.watch(membersProvider).value ?? [];

    return ListView.separated(
      itemCount: payments.length,
      separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor, height: 1),
      itemBuilder: (context, index) {
        final p = payments[index];
        final status = p['status'] ?? 'Completed';
        final isPaid = status == 'Completed';
        final isPending = status == 'Pending';
        
        final statusColor = isPaid ? Colors.green : (isPending ? Colors.orange : Colors.red);
        final statusBg = isPaid ? Colors.green.withOpacity(0.1) : (isPending ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1));
        
        // Handle both populated member object and raw member ID string
        String memberName = 'Unknown Member';
        if (p['memberId'] == null) {
          memberName = 'Deleted Member';
        } else if (p['memberId'] is Map) {
          memberName = p['memberId']['name'] ?? 'Unknown Member';
        } else if (p['memberId'] is String) {
          try {
            final member = members.firstWhere((m) => m.id == p['memberId']);
            memberName = member.name;
          } catch (_) {
            memberName = 'Unknown Member';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  p['date'] != null ? DateFormat('MMM dd, yy').format(DateTime.parse(p['date'])) : '', 
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(memberName, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                    if (p['description'] != null && p['description'].toString().isNotEmpty)
                      Text(p['description'], style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text('₹${p['amount'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(
                      isPaid ? LucideIcons.checkCircle2 : (isPending ? LucideIcons.clock : LucideIcons.xCircle),
                      size: 10,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.moreVertical, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingRenewalsList extends StatelessWidget {
  final List<Map<String, dynamic>> renewals;
  const _UpcomingRenewalsList({required this.renewals});

  @override
  Widget build(BuildContext context) {
    if (renewals.isEmpty) {
      return const Center(child: Text('No upcoming renewals.'));
    }
    return ListView.builder(
      itemCount: renewals.length,
      itemBuilder: (context, index) {
        final r = renewals[index];
        final iconColor = Colors.orange;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.calendarClock, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(r['membershipPlan'] ?? 'Plan', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              Text(
                r['expiryDate'] != null ? DateFormat('MMM dd').format(DateTime.parse(r['expiryDate'])) : '', 
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11)
              ),
            ],
          ),
        );
      },
    );
  }
}
