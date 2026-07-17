import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import '../../../core/providers/dashboard_provider.dart';

class RevenueFilterNotifier extends Notifier<String> {
  @override
  String build() => 'This Month';
  void setFilter(String value) => state = value;
}
final revenueFilterProvider = NotifierProvider<RevenueFilterNotifier, String>(RevenueFilterNotifier.new);

class MembershipFilterNotifier extends Notifier<String> {
  @override
  String build() => 'This Month';
  void setFilter(String value) => state = value;
}
final membershipFilterProvider = NotifierProvider<MembershipFilterNotifier, String>(MembershipFilterNotifier.new);

class AttendanceFilterNotifier extends Notifier<String> {
  @override
  String build() => 'Today';
  void setFilter(String value) => state = value;
}
final attendanceFilterProvider = NotifierProvider<AttendanceFilterNotifier, String>(AttendanceFilterNotifier.new);

class ChartsRow extends ConsumerWidget {
  final DashboardData data;
  
  const ChartsRow({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueFilter = ref.watch(revenueFilterProvider);
    final membershipFilter = ref.watch(membershipFilterProvider);
    final attendanceFilter = ref.watch(attendanceFilterProvider);
    final attendanceRoleFilter = ref.watch(attendanceRoleFilterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Overview
            Expanded(
              flex: 5,
              child: _buildChartCard(
                context: context,
                title: 'Revenue Overview',
                actionLabel: 'Last 6 Months',
                filterOptions: ['Last 6 Months'],
                onFilterSelected: (value) {},
                child: _RevenueLineChart(data: data),
                valueSubtitle: '₹${data.monthlyRevenue.toStringAsFixed(0)}',
                trendSubtitle: 'This Month',
                trendColor: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            // Membership Status
            Expanded(
              flex: 4,
              child: _buildChartCard(
                context: context,
                title: 'Membership Status',
                actionLabel: membershipFilter,
                filterOptions: ['This Month', 'Last Month', 'All Time'],
                onFilterSelected: (value) => ref.read(membershipFilterProvider.notifier).setFilter(value),
                child: _MembershipDonutChart(data: data),
              ),
            ),
            const SizedBox(width: 16),
            // Today's Attendance
            Expanded(
              flex: 3,
              child: _buildChartCard(
                context: context,
                title: 'Attendance',
                actionLabel: attendanceFilter,
                filterOptions: ['Today', 'Yesterday', 'This Week'],
                onFilterSelected: (value) => ref.read(attendanceFilterProvider.notifier).setFilter(value),
                secondaryActionLabel: attendanceRoleFilter,
                secondaryFilterOptions: ['Member', 'Staff', 'Trainer'],
                onSecondaryFilterSelected: (value) => ref.read(attendanceRoleFilterProvider.notifier).setFilter(value),
                isActionIcon: true,
                child: _AttendanceCircularChart(filter: attendanceFilter, roleFilter: attendanceRoleFilter, data: data),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required List<String> filterOptions,
    required ValueChanged<String> onFilterSelected,
    required Widget child,
    bool isActionIcon = false,
    String? secondaryActionLabel,
    List<String>? secondaryFilterOptions,
    ValueChanged<String>? onSecondaryFilterSelected,
    String? valueSubtitle,
    String? trendSubtitle,
    Color trendColor = Colors.green,
  }) {
    return HoverZoomEffect(
      scale: 1.02,
      child: Container(
        height: 350,
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  if (secondaryActionLabel != null && secondaryFilterOptions != null && onSecondaryFilterSelected != null) ...[
                    PopupMenuButton<String>(
                      onSelected: onSecondaryFilterSelected,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      itemBuilder: (context) => secondaryFilterOptions.map((option) => PopupMenuItem(
                        value: option,
                        child: Text(option, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                      )).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(secondaryActionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronDown, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                  PopupMenuButton<String>(
                    onSelected: onFilterSelected,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (context) => filterOptions.map((option) => PopupMenuItem(
                      value: option,
                      child: Text(option, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                    )).toList(),
                    child: isActionIcon
                      ? Row(
                          children: [
                            Text(actionLabel, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.moreVertical, size: 16),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.chevronDown, size: 14),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (valueSubtitle != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  valueSubtitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trendSubtitle ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
}

class _RevenueLineChart extends StatelessWidget {
  final DashboardData data;
  const _RevenueLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    double maxY = 10000;
    if (data.revenueTrend.isNotEmpty) {
      double maxRev = data.revenueTrend.map((e) => e['revenue'] as num).reduce((a, b) => a > b ? a : b).toDouble();
      if (maxRev > maxY) maxY = maxRev * 1.2;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade100,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 11);
                int index = value.toInt() - 1;
                String text = '';
                if (index >= 0 && index < data.revenueTrend.length) {
                  text = data.revenueTrend[index]['month'];
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value == 0 ? '₹0' : '₹${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: data.revenueTrend.length > 0 ? data.revenueTrend.length.toDouble() : 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: data.revenueTrend.isEmpty ? [const FlSpot(1, 0)] : List.generate(data.revenueTrend.length, (index) {
              return FlSpot((index + 1).toDouble(), (data.revenueTrend[index]['revenue'] as num).toDouble());
            }),
            isCurved: true,
            color: const Color(0xFF6366F1), // Indigo
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == barData.spots.length - 3) { // Highlight a point
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF6366F1),
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF6366F1),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.2),
                  const Color(0xFF6366F1).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipDonutChart extends StatelessWidget {
  final DashboardData data;
  const _MembershipDonutChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final int active = data.activeMembers;
    final int inactive = data.totalMembers - active;
    final int total = data.totalMembers > 0 ? data.totalMembers : 1;
    final double activePct = (active / total) * 100;
    final double inactivePct = (inactive / total) * 100;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(color: Colors.green, value: active.toDouble(), title: '', radius: 20),
                    PieChartSectionData(color: Colors.grey.shade300, value: inactive.toDouble(), title: '', radius: 20),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${data.totalMembers}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Text('Total Members', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(context, 'Active', '$active (${activePct.toStringAsFixed(1)}%)', Colors.green),
              const SizedBox(height: 16),
              _buildLegendItem(context, 'Inactive', '$inactive (${inactivePct.toStringAsFixed(1)}%)', Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _AttendanceCircularChart extends StatelessWidget {
  final String filter;
  final String roleFilter;
  final DashboardData data;
  const _AttendanceCircularChart({required this.filter, required this.roleFilter, required this.data});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> roleStats = data.attendanceStats[roleFilter] ?? {};
    final Map<String, dynamic> stats = roleStats[filter] ?? {'present': 0, 'total': 0};
    // Ensure present count doesn't exceed total for UI consistency, though it's an edge case
    int rawPresent = stats['present'] ?? 0;
    final int total = stats['total'] ?? 0;
    final int present = rawPresent > total && total > 0 ? total : rawPresent;
    
    final int absent = total > 0 ? (total - present) : 0;
    
    final double presentPct = total > 0 ? (present / total) : 0.0;
    final String ratioStr = '$present / $total';

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: presentPct,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6366F1)), // Indigo gradient stand-in
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ratioStr, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Text('Present', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttendanceStat(context, '$present', 'Present', Icons.check_circle, Colors.green),
            _buildAttendanceStat(context, '$absent', 'Absent', Icons.cancel, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceStat(BuildContext context, String count, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ],
    );
  }
}
