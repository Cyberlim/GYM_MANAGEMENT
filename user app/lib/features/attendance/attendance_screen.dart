import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/auth_provider.dart';
import 'package:user_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

final attendanceProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiProvider).getAttendance();
});

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceProvider);
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (records) {
          DateTime? joinDate;
          if (user != null) {
            final joinDateStr = user['joinDate'] ?? user['createdAt'];
            if (joinDateStr != null) {
              final parsed = DateTime.tryParse(joinDateStr.toString());
              if (parsed != null) {
                joinDate = DateTime(parsed.year, parsed.month, parsed.day);
              }
            }
          }

          // Use the explicit date field, not checkInTime
          final recordsList = records.where((r) => r['date'] != null).toList();

          // Calculate summary for current month based on records
          int present = 0;
          for (var record in recordsList) {
            final date = DateTime.parse(record['date']);
            if (date.month == _focusedDay.month && date.year == _focusedDay.year && record['status'] == 'Present') {
              present++;
            }
          }

          // Convert records to sets of Dates for calendar marking
          final presentDates = <DateTime>{};
          final absentDates = <DateTime>{};

          for (var r in recordsList) {
            final d = DateTime.parse(r['date']);
            final dateOnly = DateTime(d.year, d.month, d.day);
            if (r['status'] == 'Present') {
              presentDates.add(dateOnly);
            } else if (r['status'] == 'Absent') {
              absentDates.add(dateOnly);
            }
          }

          // Count unmarked days (Orange)
          int unmarked = 0;
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;

          for (int i = 1; i <= daysInMonth; i++) {
            final d = DateTime(_focusedDay.year, _focusedDay.month, i);
            if (!d.isAfter(todayOnly)) {
              if (joinDate == null || !d.isBefore(joinDate!)) {
                if (!presentDates.contains(d) && !absentDates.contains(d)) {
                  unmarked++;
                }
              }
            }
          }

          int totalPresent = presentDates.length;
          int totalAbsent = absentDates.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Card
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurface),
                      rightChevronIcon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurface),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                      weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      outsideDaysVisible: false,
                    ),
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: (day) => ['dummy'],
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final dateOnly = DateTime(day.year, day.month, day.day);
                        final today = DateTime.now();
                        final todayOnly = DateTime(today.year, today.month, today.day);

                        // Highlight join date
                        if (joinDate != null && dateOnly.isAtSameMomentAs(joinDate!)) {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.3), shape: BoxShape.circle),
                              width: 32,
                              height: 32,
                              child: Center(child: Text('${day.day}', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold))),
                            ),
                          );
                        }

                        // Decrease opacity for dates before join date OR dates after today
                        if ((joinDate != null && dateOnly.isBefore(joinDate!)) || dateOnly.isAfter(todayOnly)) {
                          return Center(child: Text('${day.day}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.2))));
                        }

                        // Active dates (between join date and today)
                        return Center(child: Text('${day.day}', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)));
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Center(
                          child: Container(
                            decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                            width: 32,
                            height: 32,
                            child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white))),
                          ),
                        );
                      },
                      markerBuilder: (context, day, events) {
                        final dateOnly = DateTime(day.year, day.month, day.day);
                        final today = DateTime.now();
                        final todayOnly = DateTime(today.year, today.month, today.day);
                        
                        if (presentDates.contains(dateOnly)) {
                          return Positioned(
                            bottom: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                          );
                        } else if (absentDates.contains(dateOnly)) {
                          return Positioned(
                            bottom: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          );
                        } else if (!dateOnly.isAfter(todayOnly)) {
                          // Past dates and today without attendance are unmarked (Orange)
                          // Only show if date is after or equal to join date
                          if (joinDate == null || !dateOnly.isBefore(joinDate!)) {
                            return Positioned(
                              bottom: 6,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Summary Cards
                const Text('This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard(context, '$present', 'Present', Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard(context, '${absentDates.where((d) => d.year == _focusedDay.year && d.month == _focusedDay.month).length}', 'Absent', Colors.red)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Overall', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard(context, '$totalPresent', 'Present', Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard(context, '$totalAbsent', 'Absent', Colors.red)),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Check-ins
                const Text('Recent Check-ins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (recordsList.isEmpty)
                  const Text('No recent check-ins')
                else
                  ...recordsList.take(5).map((record) {
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(LucideIcons.calendar, size: 24, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy').format(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (displayTime.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(displayTime, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                    ]
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record['status'],
                                  style: TextStyle(
                                    color: isPresent ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String count, String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}
