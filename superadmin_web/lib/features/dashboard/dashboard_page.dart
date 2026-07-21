import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/superadmin_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _revenueTimeRange = 'This Month';
  String _statusTimeRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final isDesktop = sizingInfo.deviceScreenType == DeviceScreenType.desktop;
        final isTablet = sizingInfo.deviceScreenType == DeviceScreenType.tablet;
        final isMobile = sizingInfo.deviceScreenType == DeviceScreenType.mobile;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: ref.watch(superadminDashboardProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (dashboardData) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopMetricsRow(isDesktop, isMobile, dashboardData),
                  const SizedBox(height: 24),
                  
                  // Charts Row
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildRevenueChart(dashboardData)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildGymStatusChart(dashboardData)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildPlatformHealthChart(dashboardData)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRevenueChart(dashboardData),
                        const SizedBox(height: 24),
                        _buildGymStatusChart(dashboardData),
                        const SizedBox(height: 24),
                        _buildPlatformHealthChart(dashboardData),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Lists Row
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildRecentGymsList(dashboardData, true)),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildRecentInvoicesList(dashboardData, true)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildActivityFeed(dashboardData)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRecentGymsList(dashboardData, false),
                        const SizedBox(height: 24),
                        _buildRecentInvoicesList(dashboardData, false),
                        const SizedBox(height: 24),
                        _buildActivityFeed(dashboardData),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  _buildBottomActionBar(context, isDesktop, isMobile),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }),
        );
      },
    );
  }

  // --- Top Metrics Row ---
  Widget _buildTopMetricsRow(bool isDesktop, bool isMobile, Map<String, dynamic> data) {
    final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 0);
    final totalGyms = data['totalGyms'].toString();
    final activeGyms = data['activeGyms'].toString();
    final mrr = formatCurrency.format(data['mrr'] ?? 0);
    final costs = formatCurrency.format(data['costs'] ?? 0);
    final profit = formatCurrency.format(data['profit'] ?? 0);
    final renewals = (data['renewals'] ?? 0).toString();
    
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Gyms', totalGyms, 'this month', true, Colors.purple, LucideIcons.building)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Active Gyms', activeGyms, 'this month', true, Colors.green, LucideIcons.checkCircle)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Pending', data['gymStatus']['pending'].toString(), 'this month', true, Colors.orange, LucideIcons.clock)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('App Users', data['totalUsers'].toString(), 'this month', true, Colors.blue, LucideIcons.users)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('MRR', mrr, 'vs last month', true, Colors.green, LucideIcons.dollarSign)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Costs', costs, '- 6.2% vs last month', false, Colors.red, LucideIcons.briefcase)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Profit', profit, '+ 22.3% vs last month', true, Colors.purpleAccent, LucideIcons.wallet)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Renewals', renewals, '+ 18 this week', true, Colors.orangeAccent, LucideIcons.refreshCw)),
            ],
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Gyms', totalGyms, 'this month', true, Colors.purple, LucideIcons.building)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Active Gyms', activeGyms, 'this month', true, Colors.green, LucideIcons.checkCircle)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Pending', data['gymStatus']['pending'].toString(), 'this month', true, Colors.orange, LucideIcons.clock)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('App Users', data['totalUsers'].toString(), 'this month', true, Colors.blue, LucideIcons.users)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('MRR', mrr, 'vs last month', true, Colors.green, LucideIcons.dollarSign)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Costs', costs, 'vs last month', false, Colors.red, LucideIcons.briefcase)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Profit', profit, 'vs last month', true, Colors.purpleAccent, LucideIcons.wallet)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Renewals', renewals, 'this week', true, Colors.orangeAccent, LucideIcons.refreshCw)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String trend, bool isPositive, Color color, IconData icon) {
    return HoverCard(
      child: Container(
        padding: const EdgeInsets.all(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  // --- Middle Charts Row ---
  Widget _buildRevenueChart(Map<String, dynamic> data) {
    final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 0);
    final mrr = data['mrr'] ?? 0;
    final trendList = data['revenueTrend'] as List<dynamic>? ?? [];
    
    // Create spots from backend data
    final spots = <FlSpot>[];
    for (int i = 0; i < trendList.length; i++) {
      final revenue = (trendList[i]['revenue'] as num).toDouble();
      spots.add(FlSpot((i * 4 / (trendList.length > 1 ? trendList.length - 1 : 1)).toDouble(), revenue));
    }
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    final maxY = spots.map((s) => s.y).fold<double>(0, (prev, y) => y > prev ? y : prev) * 1.2;
    
    return GestureDetector(
      onTap: () => context.go('/finance'),
      child: HoverCard(
        child: Container(
          height: 350,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              _buildFilterDropdown(_revenueTimeRange, (value) {
                setState(() => _revenueTimeRange = value);
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(formatCurrency.format(mrr), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 8),
              Icon(LucideIcons.arrowUp, size: 14, color: Colors.green),
              Text(' 15.6% ', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('from last month', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15000,
                  getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor!, strokeWidth: 1),
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
                        const labels = ['Feb 1', 'Feb 8', 'Feb 15', 'Feb 22', 'Feb 28'];
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(labels[value.toInt()], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 15000,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('\$0', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11));
                        return Text('\$${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: maxY < 100 ? 100 : maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Theme.of(context).colorScheme.onSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Feb 21, 2025\n',
                          TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 10),
                          children: [
                            TextSpan(text: 'Revenue ', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 12)),
                            TextSpan(text: '\$${spot.y.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6B46C1), // Purple theme matching image
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 4, // Show dot only at the end or hover
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(radius: 4, color: const Color(0xFF6B46C1), strokeWidth: 2, strokeColor: Theme.of(context).colorScheme.surface);
                      }
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF6B46C1).withOpacity(0.3),
                          const Color(0xFF6B46C1).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildGymStatusChart(Map<String, dynamic> data) {
    final totalGyms = data['totalGyms'] as int;
    final active = data['gymStatus']['active'] as int;
    final trial = data['gymStatus']['trial'] as int;
    final suspended = data['gymStatus']['suspended'] as int;
    final pending = data['gymStatus']['pending'] as int;
    
    final activePct = totalGyms > 0 ? (active / totalGyms * 100).toStringAsFixed(1) : '0.0';
    final trialPct = totalGyms > 0 ? (trial / totalGyms * 100).toStringAsFixed(1) : '0.0';
    final suspendedPct = totalGyms > 0 ? (suspended / totalGyms * 100).toStringAsFixed(1) : '0.0';
    final pendingPct = totalGyms > 0 ? (pending / totalGyms * 100).toStringAsFixed(1) : '0.0';

    return GestureDetector(
      onTap: () => context.go('/gyms'),
      child: HoverCard(
        child: Container(
          height: 350,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gym Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              _buildFilterDropdown(_statusTimeRange, (value) {
                setState(() => _statusTimeRange = value);
              }),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(color: Colors.green, value: active.toDouble(), radius: 20, showTitle: false),
                            PieChartSectionData(color: Colors.redAccent, value: suspended.toDouble(), radius: 20, showTitle: false),
                            PieChartSectionData(color: Colors.orange, value: pending.toDouble(), radius: 20, showTitle: false),
                            PieChartSectionData(color: Colors.blue, value: trial.toDouble(), radius: 20, showTitle: false),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(totalGyms.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          Text('Total Gyms', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.green, 'Active', active.toString(), '$activePct%'),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.redAccent, 'Suspended', suspended.toString(), '$suspendedPct%'),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.orange, 'Pending', pending.toString(), '$pendingPct%'),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.blue, 'Trial', trial.toString(), '$trialPct%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value, String percent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4, right: 8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(value, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(width: 4),
                  Text('($percent)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFilterDropdown(String currentValue, Function(String) onChanged) {
    return PopupMenuButton<String>(
      initialValue: currentValue,
      onSelected: onChanged,
      offset: const Offset(0, 30),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'This Week', child: Text('This Week', style: TextStyle(fontSize: 13))),
        PopupMenuItem(value: 'This Month', child: Text('This Month', style: TextStyle(fontSize: 13))),
        PopupMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months', style: TextStyle(fontSize: 13))),
        PopupMenuItem(value: 'This Year', child: Text('This Year', style: TextStyle(fontSize: 13))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentValue, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHealthChart(Map<String, dynamic> data) {
    final health = data['platformHealth'] ?? {'uptime': 99.9, 'warnings': 0, 'errors': 0};
    final uptime = health['uptime']?.toString() ?? '99.9';
    final warnings = health['warnings']?.toString() ?? '0';
    final errors = health['errors']?.toString() ?? '0';

    return Container(
      height: 350,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Icon(LucideIcons.moreVertical, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(color: Colors.green, value: double.tryParse(uptime) ?? 99.9, radius: 20, showTitle: false),
                      PieChartSectionData(color: Theme.of(context).dividerColor, value: 100 - (double.tryParse(uptime) ?? 99.9), radius: 20, showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$uptime%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Text('Uptime', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    Text('Running smooth', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthStat(LucideIcons.checkCircle2, Colors.green, '$uptime%', 'Uptime'),
              _buildHealthStat(LucideIcons.alertTriangle, Colors.orange, warnings, 'Warnings'),
              _buildHealthStat(LucideIcons.xCircle, Colors.red, errors, 'Errors'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  // --- Lists Row ---
  Widget _buildRecentGymsList(Map<String, dynamic> data, bool isDesktop) {
    final recentGymsList = data['recentGyms'] as List<dynamic>? ?? [];
    return GestureDetector(
      onTap: () => context.go('/gyms'),
      child: HoverCard(
        child: Container(
          height: 400,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Gyms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              InkWell(
                onTap: () => context.go('/gyms'),
                child: Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: Theme.of(context).colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          recentGymsList.isEmpty
            ? Center(child: Text('No recent gyms found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))
            : Expanded(
            child: ListView.separated(
              itemCount: recentGymsList.length,
              separatorBuilder: (context, index) => isDesktop ? Divider(height: 24, color: Theme.of(context).dividerColor) : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final gym = recentGymsList[index] as Map<String, dynamic>;

                Color planColor;
                Color planBgColor;
                final normalizedPlan = gym['plan']!.replaceAll(' Plan', '').toLowerCase();
                
                if (normalizedPlan == 'pro') {
                  planBgColor = const Color(0xFFD3E2FF);
                  planColor = const Color(0xFF0055FF);
                } else if (normalizedPlan == 'enterprise') {
                  planBgColor = const Color(0xFFE0E7FF);
                  planColor = const Color(0xFF4338CA);
                } else if (normalizedPlan == 'basic') {
                  planBgColor = const Color(0xFFF3E8FF);
                  planColor = const Color(0xFF7E22CE);
                } else {
                  final palettes = [
                    [const Color(0xFFFEF3C7), const Color(0xFFB45309)], // Amber
                    [const Color(0xFFD1FAE5), const Color(0xFF047857)], // Emerald
                    [const Color(0xFFFFE4E6), const Color(0xFFBE123C)], // Rose
                    [const Color(0xFFE0F2FE), const Color(0xFF0369A1)], // Sky
                    [const Color(0xFFFCE7F3), const Color(0xFFBE185D)], // Pink
                  ];
                  final hash = gym['plan']!.hashCode.abs();
                  final palette = palettes[hash % palettes.length];
                  planBgColor = palette[0];
                  planColor = palette[1];
                }

                if (!isDesktop) {
                  return InkWell(
                    onTap: () => context.go('/gyms/${gym['id']}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 20, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), child: Icon(LucideIcons.user, size: 20, color: Theme.of(context).colorScheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gym['name']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text(gym['date']!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.moreVertical, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: planBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(gym['plan']!, style: TextStyle(fontSize: 12, color: planColor, fontWeight: FontWeight.bold)),
                            ),
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                                const SizedBox(width: 6),
                                Text(gym['status']!, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                }

                return InkWell(
                  onTap: () => context.go('/gyms/${gym['id']}'),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), child: Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Text(gym['name']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: planBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(gym['plan']!, style: TextStyle(fontSize: 11, color: planColor, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                          const SizedBox(width: 6),
                          Text(gym['status']!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(gym['date']!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ),
                    Icon(LucideIcons.moreVertical, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ],
                ),
              );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildRecentInvoicesList(Map<String, dynamic> data, bool isDesktop) {
    final recentInvoicesList = data['recentInvoices'] as List<dynamic>? ?? [];
    return GestureDetector(
      onTap: () => context.go('/finance', extra: {'initialTab': 1}),
      child: HoverCard(
        child: Container(
          height: 400,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              InkWell(
                onTap: () => context.go('/finance', extra: {'initialTab': 1}),
                child: Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: Theme.of(context).colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          recentInvoicesList.isEmpty
            ? Center(child: Text('No recent invoices found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))
            : Expanded(
            child: ListView.separated(
              itemCount: recentInvoicesList.length,
              separatorBuilder: (context, index) => isDesktop ? Divider(height: 24, color: Theme.of(context).dividerColor) : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invoice = recentInvoicesList[index] as Map<String, dynamic>;
                final id = invoice['id'].toString();
                final name = invoice['gymName'].toString();
                final amountStr = '\$${invoice['amount']}';
                final status = invoice['status'].toString();

                Color statusColor;
                switch (status) {
                  case 'Paid':
                  case 'Completed':
                  case 'Success':
                    statusColor = Colors.green;
                    break;
                  case 'Pending':
                    statusColor = Colors.orange;
                    break;
                  case 'Failed':
                  case 'Overdue':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                if (!isDesktop) {
                  return InkWell(
                    onTap: () => context.go('/finance', extra: {'initialTab': 1}),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(id, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            Text(amountStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                                const SizedBox(width: 6),
                                Text(status, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Icon(LucideIcons.moreVertical, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                }

                return InkWell(
                  onTap: () => context.go('/finance', extra: {'initialTab': 1}),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(id, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      ),
                    Expanded(
                      flex: 3,
                      child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(amountStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                          const SizedBox(width: 4),
                          Icon(
                            (status == 'Paid' || status == 'Completed' || status == 'Success') ? LucideIcons.checkCircle : 
                            (status == 'Pending' ? LucideIcons.clock : LucideIcons.xCircle),
                            size: 10, color: statusColor
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(Map<String, dynamic> data) {
    final activities = data['activities'] as List<dynamic>? ?? [];
    return GestureDetector(
      onTap: () => context.go('/gyms'),
      child: HoverCard(
        child: Container(
          height: 400,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              InkWell(
                onTap: () => context.go('/gyms'),
                child: Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: Theme.of(context).colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          activities.isEmpty
            ? Center(child: Text('No recent activity.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))
            : Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final activity = activities[index] as Map<String, dynamic>;
                final title = activity['title'].toString();
                final desc = activity['desc'].toString();
                final time = activity['time'].toString();
                final type = activity['type'].toString();

                IconData icon;
                Color color;
                if (type == 'gym') {
                  icon = LucideIcons.userPlus;
                  color = Colors.purple;
                } else if (type == 'payment') {
                  icon = LucideIcons.wallet;
                  color = Colors.green;
                } else {
                  icon = LucideIcons.activity;
                  color = Colors.blue;
                }
                
                return InkWell(
                  onTap: () {
                    if (activity['gymId'] != null) {
                      context.go('/gyms/${activity['gymId']}');
                    } else if (type == 'payment') {
                      context.go('/finance');
                    } else {
                      context.go('/gyms');
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(desc, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    Text(time, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              );
              },
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  // --- Bottom Action Bar ---
  Widget _buildBottomActionBar(BuildContext context, bool isDesktop, bool isMobile) {
    void showAction(String action) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action triggered: $action')));
    }

    return Row(
      children: [
        Expanded(child: _buildActionButton(context, 'Add Gym', LucideIcons.userPlus, Colors.purple, () => context.go('/gyms'))),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, 'Approvals', LucideIcons.checkSquare, Colors.green, () => showAction('Review Approvals'))),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, 'Invoices', LucideIcons.wallet, Colors.orange, () => context.go('/finance', extra: {'initialTab': 1}))),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, 'Admins', LucideIcons.users, Colors.blue, () => context.go('/admins'))),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, 'Plans', LucideIcons.layoutGrid, Colors.pink, () => context.go('/plans', extra: {'showAddPlan': true}))),
        const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, 'Broadcast', LucideIcons.bellRing, Colors.orangeAccent, () => context.go('/broadcast'))),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return HoverCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
