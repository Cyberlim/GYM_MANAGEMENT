import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:gym_owner_web/features/attendance/providers/attendance_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/staff/providers/staff_provider.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/features/plans/providers/plans_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  String selectedTab = 'Members';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final allMembers = ref.watch(membersProvider).value ?? [];
    final allStaff = ref.watch(staffProvider).value ?? [];
    final allTrainers = ref.watch(trainersProvider).value ?? [];

    final filteredMembers = allMembers.where((m) {
      bool matchesSearch = m.name.toLowerCase().contains(searchQuery.toLowerCase());
      bool joinedBeforeOrOnDate = m.joinDate.isBefore(selectedDate) || _isSameDay(m.joinDate, selectedDate);
      return matchesSearch && joinedBeforeOrOnDate;
    }).toList();
    final filteredStaff = allStaff.where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    final filteredTrainers = allTrainers.where((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track daily check-ins for your gym',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.info, size: 14, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Attendance records can only be modified up to 2 days retroactively.',
                          style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Members', label: Text('Members')),
                        ButtonSegment(value: 'Staff', label: Text('Staff')),
                        ButtonSegment(value: 'Trainers', label: Text('Trainers')),
                      ],
                      selected: {selectedTab},
                      onSelectionChanged: (val) {
                        setState(() {
                          selectedTab = val.first;
                        });
                      },
                    ),
                  ],
                ),
                _DateSelector(),
              ],
            ),
          ),

          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 900;
                  final listWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth > 800 ? constraints.maxWidth : 800.0);
                  
                  Widget content = selectedTab == 'Members'
                      ? (filteredMembers.isEmpty
                          ? const Center(child: Text('No members found.'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                    children: filteredMembers.map((member) => SizedBox(
                                      width: constraints.maxWidth < 432 ? constraints.maxWidth - 32 : 400,
                                      child: _AttendanceRow(member: member, date: selectedDate)
                                    )).toList(),
                                  ),
                                ))
                          : selectedTab == 'Staff'
                              ? (filteredStaff.isEmpty
                                  ? const Center(child: Text('No staff found.'))
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: filteredStaff.map((staff) => SizedBox(
                                          width: constraints.maxWidth < 432 ? constraints.maxWidth - 32 : 400,
                                          child: _StaffAttendanceRow(staff: staff, date: selectedDate)
                                        )).toList(),
                                      ),
                                    ))
                              : (filteredTrainers.isEmpty
                                  ? const Center(child: Text('No trainers found.'))
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: filteredTrainers.map((trainer) => SizedBox(
                                          width: constraints.maxWidth < 432 ? constraints.maxWidth - 32 : 400,
                                          child: _TrainerAttendanceRow(trainer: trainer, date: selectedDate)
                                        )).toList(),
                                  ),
                                ));

                  return content;
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    
    final allMembers = ref.watch(membersProvider).value ?? [];
    
    DateTime firstDate = DateTime(2020);
    if (allMembers.isNotEmpty) {
      firstDate = allMembers.map((m) => m.joinDate).reduce((a, b) => a.isBefore(b) ? a : b);
    }
    // Remove time portion for accurate date comparisons
    firstDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
    
    DateTime twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    twoDaysAgo = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);
    if (firstDate.isBefore(twoDaysAgo)) {
      firstDate = twoDaysAgo;
    }
    DateTime lastDate = DateTime.now();
    lastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    DateTime currentDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    bool canGoLeft = currentDate.subtract(const Duration(days: 1)).isAfter(firstDate.subtract(const Duration(days: 1)));
    bool canGoRight = currentDate.add(const Duration(days: 1)).isBefore(lastDate.add(const Duration(days: 1)));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, size: 20, color: canGoLeft ? null : Theme.of(context).dividerColor),
            onPressed: canGoLeft ? () {
              ref.read(selectedDateProvider.notifier).state = selectedDate.subtract(const Duration(days: 1));
            } : null,
          ),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: currentDate.isBefore(firstDate) ? firstDate : (currentDate.isAfter(lastDate) ? lastDate : currentDate),
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (date != null) {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.chevronRight, size: 20, color: canGoRight ? null : Theme.of(context).dividerColor),
            onPressed: canGoRight ? () {
              ref.read(selectedDateProvider.notifier).state = selectedDate.add(const Duration(days: 1));
            } : null,
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class _AttendanceRow extends ConsumerWidget {
  final Member member;
  final DateTime date;

  const _AttendanceRow({required this.member, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceProvider);
    final record = records.where((r) => r.memberId == member.id && _isSameDay(r.date, date)).firstOrNull;

    final plans = ref.watch(plansProvider).value ?? [];
    final plan = plans.where((p) => p.name == member.membershipPlan).firstOrNull;
    final planColor = plan != null ? _hexToColor(plan.colorHex) : Theme.of(context).colorScheme.primary;
    
    // We also need to watch attendanceProvider to trigger rebuilds when state changes
    ref.watch(attendanceProvider);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    member.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.membershipPlan,
                    style: TextStyle(color: planColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (record?.checkInTime != null)
                  Text(
                    'In at ${DateFormat('hh:mm a').format(record!.checkInTime!)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  )
                else
                  const SizedBox(),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: 'Present',
                      label: const Text('Present'),
                      icon: Icon(LucideIcons.checkCircle2, color: record?.status == 'Present' ? Colors.white : Colors.green),
                    ),
                    ButtonSegment(
                      value: 'Absent',
                      label: const Text('Absent'),
                      icon: Icon(LucideIcons.xCircle, color: record?.status == 'Absent' ? Colors.white : Colors.redAccent),
                    ),
                  ],
                  selected: record != null ? {record.status} : <String>{},
                  onSelectionChanged: (Set<String> selection) {
                    if (selection.isNotEmpty) {
                      ref.read(attendanceProvider.notifier).markAttendance(member.id, date, selection.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        if (record?.status == 'Present') return Colors.green.shade800;
                        if (record?.status == 'Absent') return Colors.red.shade800;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class _StaffAttendanceRow extends ConsumerWidget {
  final Staff staff;
  final DateTime date;

  const _StaffAttendanceRow({required this.staff, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceProvider);
    final record = records.where((r) => r.memberId == staff.id && _isSameDay(r.date, date)).firstOrNull;
    
    // We also need to watch attendanceProvider to trigger rebuilds when state changes
    ref.watch(attendanceProvider);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage: staff.imageUrl != null && staff.imageUrl!.isNotEmpty ? NetworkImage(staff.imageUrl!) : null,
                  child: (staff.imageUrl == null || staff.imageUrl!.isEmpty) ? Text(
                    staff.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        staff.email,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.role,
                    style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (record?.checkInTime != null)
                  Text(
                    'In at ${DateFormat('hh:mm a').format(record!.checkInTime!)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  )
                else
                  const SizedBox(),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: 'Present',
                      label: const Text('Present'),
                      icon: Icon(LucideIcons.checkCircle2, color: record?.status == 'Present' ? Colors.white : Colors.green),
                    ),
                    ButtonSegment(
                      value: 'Absent',
                      label: const Text('Absent'),
                      icon: Icon(LucideIcons.xCircle, color: record?.status == 'Absent' ? Colors.white : Colors.redAccent),
                    ),
                  ],
                  selected: record != null ? {record.status} : <String>{},
                  onSelectionChanged: (Set<String> selection) {
                    if (selection.isNotEmpty) {
                      ref.read(attendanceProvider.notifier).markAttendance(staff.id, date, selection.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        if (record?.status == 'Present') return Colors.green.shade800;
                        if (record?.status == 'Absent') return Colors.red.shade800;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class _TrainerAttendanceRow extends ConsumerWidget {
  final Trainer trainer;
  final DateTime date;

  const _TrainerAttendanceRow({required this.trainer, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceProvider);
    final record = records.where((r) => r.memberId == trainer.id && _isSameDay(r.date, date)).firstOrNull;
    
    // We also need to watch attendanceProvider to trigger rebuilds when state changes
    ref.watch(attendanceProvider);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  backgroundImage: trainer.imageUrl != null && trainer.imageUrl!.isNotEmpty ? NetworkImage(trainer.imageUrl!) : null,
                  child: (trainer.imageUrl == null || trainer.imageUrl!.isEmpty) ? Text(
                    trainer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        trainer.email,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trainer.specialization,
                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (record?.checkInTime != null)
                  Text(
                    'In at ${DateFormat('hh:mm a').format(record!.checkInTime!)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  )
                else
                  const SizedBox(),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: 'Present',
                      label: const Text('Present'),
                      icon: Icon(LucideIcons.checkCircle2, color: record?.status == 'Present' ? Colors.white : Colors.green),
                    ),
                    ButtonSegment(
                      value: 'Absent',
                      label: const Text('Absent'),
                      icon: Icon(LucideIcons.xCircle, color: record?.status == 'Absent' ? Colors.white : Colors.redAccent),
                    ),
                  ],
                  selected: record != null ? {record.status} : <String>{},
                  onSelectionChanged: (Set<String> selection) {
                    if (selection.isNotEmpty) {
                      ref.read(attendanceProvider.notifier).markAttendance(trainer.id, date, selection.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        if (record?.status == 'Present') return Colors.green.shade800;
                        if (record?.status == 'Absent') return Colors.red.shade800;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}
