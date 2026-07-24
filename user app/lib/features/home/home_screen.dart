import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/auth_provider.dart';
import 'package:user_app/features/attendance/attendance_screen.dart';
import 'package:user_app/features/plans/plans_screen.dart';
import 'package:user_app/features/notifications/notifications_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?['name']?.toString().split(' ').first ?? 'User';
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(attendanceProvider);
    final plansAsync = ref.watch(plansProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadNotifications = notificationsAsync.value?.where((n) => n['isRead'] == false).length ?? 0;

    final expiryDate = user?['expiryDate'] != null ? DateTime.tryParse(user!['expiryDate']) : null;
    final daysLeft = expiryDate != null ? expiryDate.difference(DateTime.now()).inDays : 0;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    final planName = user?['membershipPlan'] ?? 'No Plan';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name 👋',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep pushing your limits!',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.bell),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadNotifications',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Plan Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Plan Status', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isExpired || expiryDate == null) ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text((isExpired || expiryDate == null) ? 'Expired' : 'Active', style: TextStyle(color: (isExpired || expiryDate == null) ? Colors.redAccent : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(planName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            const Text('Valid Till', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(expiryDate != null ? expiryDate.toString().substring(0, 10) : 'N/A', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(daysLeft > 0 ? '$daysLeft' : '0', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                const Text('Days Left', style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Overview
              const Text('Quick Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              attendanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load stats: $err')),
                data: (records) {
                  final recordsList = records.where((r) => r['date'] != null).toList();
                  int totalDays = recordsList.where((r) => r['status'] == 'Present').length;
                  int thisMonth = 0;
                  final now = DateTime.now();
                  for (var r in recordsList) {
                    if (r['status'] == 'Present') {
                      final d = DateTime.parse(r['date']);
                      if (d.month == now.month && d.year == now.year) {
                        thisMonth++;
                      }
                    }
                  }
                  
                  // Simple streak calculation (consecutive days ending today or yesterday)
                  int streak = 0;
                  final presentRecords = recordsList.where((r) => r['status'] == 'Present').toList();
                  if (presentRecords.isNotEmpty) {
                    // Sort descending by date
                    final sortedDates = presentRecords.map((r) {
                      final d = DateTime.parse(r['date']);
                      return DateTime(d.year, d.month, d.day);
                    }).toSet().toList()..sort((a, b) => b.compareTo(a));
                    
                    DateTime checkDate = DateTime(now.year, now.month, now.day);
                    if (!sortedDates.contains(checkDate)) {
                      checkDate = checkDate.subtract(const Duration(days: 1));
                    }
                    
                    for (var d in sortedDates) {
                      if (d.isAtSameMomentAs(checkDate)) {
                        streak++;
                        checkDate = checkDate.subtract(const Duration(days: 1));
                      } else if (d.isBefore(checkDate)) {
                        break;
                      }
                    }
                  }

                  // Overall Percentage Calculation
                  int overallPercentage = 0;
                  if (user != null) {
                    final joinDateStr = user['joinDate'] ?? user['createdAt'];
                    if (joinDateStr != null) {
                      final joinDate = DateTime.tryParse(joinDateStr.toString());
                      if (joinDate != null) {
                        int daysSinceJoin = DateTime.now().difference(joinDate).inDays + 1;
                        if (daysSinceJoin > 0) {
                          overallPercentage = ((totalDays / daysSinceJoin) * 100).clamp(0, 100).toInt();
                        }
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildOverviewCard(context, LucideIcons.activity, 'Overall', '$overallPercentage%', 'Attendance')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOverviewCard(context, LucideIcons.clock, 'This Month', '$thisMonth', 'Days')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOverviewCard(context, LucideIcons.flame, 'Streak', '$streak', 'Total')),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Recent Check-ins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (recordsList.isEmpty)
                        const Text('No recent check-ins yet.')
                      else
                        ...recordsList.take(3).map((record) {
                          final date = DateTime.parse(record['date']);
                          final isPresent = record['status'] == 'Present';
                          final displayTime = isPresent && record['checkInTime'] != null
                              ? DateFormat('hh:mm a').format(DateTime.parse(record['checkInTime']).toLocal())
                              : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.calendarCheck, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (displayTime.isNotEmpty)
                                      Text(displayTime, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(record['status'], style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Banner
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surface,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=1470&auto=format&fit=crop'), // Fallback high quality image
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Stay Strong,\nStay Consistent!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Every workout brings\nyou closer to your goals.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Featured Plans
              const Text('Featured Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              plansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load plans: $err')),
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Text('No plans available.');
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: plans.map((plan) {
                        final isGold = plan['name']?.toString().toLowerCase().contains('gold') ?? false;
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isGold ? const Color(0xFF6C5CE7) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isGold ? const Color(0xFF6C5CE7) : theme.colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan['name'] ?? 'Plan', style: TextStyle(color: isGold ? Colors.white : theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('₹${plan['price']}', style: TextStyle(color: isGold ? Colors.white : theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text(' /mo', style: TextStyle(color: isGold ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Can navigate to plans tab
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isGold ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.1),
                                  foregroundColor: isGold ? const Color(0xFF6C5CE7) : theme.colorScheme.onSurface,
                                  minimumSize: const Size(double.infinity, 36),
                                  elevation: 0,
                                ),
                                child: const Text('View Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, IconData icon, String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C5CE7), size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}
