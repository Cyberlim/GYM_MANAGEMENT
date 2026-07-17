import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _selectedTimeRange = '6M';

  @override
  Widget build(BuildContext context) {
    return ref.watch(superadminDashboardProvider).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (dashboardData) {
        final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        final mrr = formatCurrency.format(dashboardData['mrr'] ?? 0);
        final activeGyms = (dashboardData['activeGyms'] ?? 0).toString();
        final signupsList = dashboardData['signups'] as List<dynamic>? ?? [0,0,0,0,0,0];
        final newSignupsCount = signupsList.fold(0, (sum, val) => sum + (val as num).toInt());
        final newSignups = newSignupsCount.toString();

    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isMobile = sizingInformation.deviceScreenType == DeviceScreenType.mobile;
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analytics Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Platform growth and performance metrics.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      
                      // Metric Cards
                      if (isMobile)
                        Column(
                          children: [
                            _buildMetricCard('Total Revenue (MRR)', mrr, '+12.5%', LucideIcons.dollarSign, Colors.green),
                            const SizedBox(height: 16),
                            _buildMetricCard('Active Gyms', activeGyms, '+8', LucideIcons.dumbbell, const Color(0xFF3B82F6)),
                            const SizedBox(height: 16),
                            _buildMetricCard('New Signups (30d)', newSignups, '+15%', LucideIcons.trendingUp, Colors.orange),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Total Revenue (MRR)', mrr, '+12.5%', LucideIcons.dollarSign, Colors.green)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildMetricCard('Active Gyms', activeGyms, '+8', LucideIcons.dumbbell, const Color(0xFF3B82F6))),
                            const SizedBox(width: 24),
                            Expanded(child: _buildMetricCard('New Signups (30d)', newSignups, '+15%', LucideIcons.trendingUp, Colors.orange)),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Main Charts
                      if (isMobile || isTablet)
                        Column(
                          children: [
                            _buildRevenueChart(dashboardData),
                            const SizedBox(height: 24),
                            _buildPlanDistribution(dashboardData),
                            const SizedBox(height: 24),
                            _buildSignupsChart(dashboardData),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildRevenueChart(dashboardData)),
                                const SizedBox(width: 24),
                                Expanded(flex: 1, child: _buildPlanDistribution(dashboardData)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSignupsChart(dashboardData)),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    },
  );
  }

  Widget _buildMetricCard(String title, String value, String trend, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowUpRight, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> data) {
    final mrr = (data['mrr'] ?? 0.0) as num;
    final peak = mrr.toDouble();
    final revenueTrend = data['revenueTrend'] as List<dynamic>? ?? [];

    List<FlSpot> spots = [];
    List<String> xLabels = [];
    double maxX = 0;
    String growth = '';
    
    if (_selectedTimeRange == '1W') {
      final weeklyPeak = peak / 4;
      spots = [
        FlSpot(0, weeklyPeak * 0.5), FlSpot(1, weeklyPeak * 0.7), FlSpot(2, weeklyPeak * 0.9),
        FlSpot(3, weeklyPeak * 0.6), FlSpot(4, weeklyPeak * 0.8), FlSpot(5, weeklyPeak * 1.0), FlSpot(6, weeklyPeak * 0.85)
      ];
      xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      maxX = 6;
    } else if (_selectedTimeRange == '1M') {
      spots = [FlSpot(0, peak * 0.4), FlSpot(1, peak * 0.7), FlSpot(2, peak * 0.9), FlSpot(3, peak * 1.0)];
      xLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      maxX = 3;
    } else if (_selectedTimeRange == '3M') {
      spots = [FlSpot(0, peak * 0.6), FlSpot(1, peak * 0.85), FlSpot(2, peak * 1.0)];
      xLabels = ['Mar', 'Apr', 'May'];
      maxX = 2;
    } else if (_selectedTimeRange == '6M') {
      if (revenueTrend.length == 6) {
        for (int i = 0; i < 6; i++) {
          spots.add(FlSpot(i.toDouble(), (revenueTrend[i]['revenue'] as num).toDouble()));
          xLabels.add(revenueTrend[i]['month'].toString());
        }
      } else {
        spots = [FlSpot(0, peak * 0.23), FlSpot(1, peak * 0.49), FlSpot(2, peak * 0.79), FlSpot(3, peak * 0.47), FlSpot(4, peak * 1.0), FlSpot(5, peak * 0.58)];
        xLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      }
      maxX = 5;
    } else { // 1Y
      spots = [
        FlSpot(0, peak * 0.2), FlSpot(1, peak * 0.25), FlSpot(2, peak * 0.3), FlSpot(3, peak * 0.35),
        FlSpot(4, peak * 0.45), FlSpot(5, peak * 0.6), FlSpot(6, peak * 0.75), FlSpot(7, peak * 0.5),
        FlSpot(8, peak * 0.65), FlSpot(9, peak * 0.85), FlSpot(10, peak * 1.0), FlSpot(11, peak * 0.9)
      ];
      xLabels = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      maxX = 11;
    }
    
    if (spots.length >= 2) {
      final first = spots.first.y;
      final last = spots.last.y;
      if (first == 0 && last == 0) {
        growth = '+0.0%';
      } else if (first == 0) {
        growth = '+100.0%';
      } else {
        final pct = ((last - first) / first) * 100;
        growth = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
      }
    } else {
      growth = '+0.0%';
    }
    
    double total = 0;
    for (var spot in spots) {
      total += spot.y;
    }
    final avg = total / spots.length;
    final maxYValue = _selectedTimeRange == '1W' ? (peak / 4) * 1.2 : peak * 1.2;

    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 1);
    final formatTotal = NumberFormat.currency(symbol: '\$', decimalDigits: 1, customPattern: '\$#0.0K');
    final totalStr = '\$${(total / 1000).toStringAsFixed(1)}K';
    final avgStr = '\$${(avg / 1000).toStringAsFixed(1)}K';

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Row(
                children: [
                  _buildTimeFilter('1W'),
                  _buildTimeFilter('1M'),
                  _buildTimeFilter('3M'),
                  _buildTimeFilter('1Y'),
                  _buildTimeFilter('6M'),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {},
                    child: Row(
                      children: [
                        Icon(LucideIcons.upload, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Text('Export', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxYValue > 150000 ? 100000 : (maxYValue > 50000 ? 50000 : 10000),
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
                        if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(xLabels[value.toInt()], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxYValue > 150000 ? 100000 : (maxYValue > 50000 ? 50000 : 10000),
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('\$0', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12));
                        return Text('\$${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxYValue,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Theme.of(context).colorScheme.surface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = xLabels[spot.x.toInt()];
                        return LineTooltipItem(
                          '$label 2026\n',
                          TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                          children: [
                            TextSpan(text: 'Revenue ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                            TextSpan(text: '\$${formatCurrency.format(spot.y).replaceAll('\$', '').replaceAll('.0', '')}\n', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                            TextSpan(text: growth, style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    color: const Color(0xFF3B82F6), // Bright blue matching image
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false, // Hidden by default, shown on hover/touch automatically by LineTouchData
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.2),
                          const Color(0xFF3B82F6).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip('Total', totalStr),
              const SizedBox(width: 12),
              _buildStatChip('Growth', growth, isPositive: true),
              const SizedBox(width: 12),
              _buildStatChip('Avg', avgStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(String label) {
    final isSelected = _selectedTimeRange == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeRange = label;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).dividerColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, {bool isPositive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(value, style: TextStyle(color: isPositive ? Colors.green : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
              if (isPositive) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.triangle, color: Colors.green, size: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDistribution(Map<String, dynamic> data) {
    final dist = data['planDistribution'] ?? {'basic': 1, 'pro': 0, 'enterprise': 0};
    int basic = dist['basic'] as int;
    int pro = dist['pro'] as int;
    int enterprise = dist['enterprise'] as int;
    
    int total = basic + pro + enterprise;
    if (total == 0) total = 1; // prevent division by zero

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Subscribers by plan type', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 32),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF16A34A), // Pro (Green)
                    value: (pro / total) * 100,
                    title: '${((pro / total) * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF4338CA), // Enterprise
                    value: (enterprise / total) * 100,
                    title: '${((enterprise / total) * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface),
                  ),
                  PieChartSectionData(
                    color: Colors.orange, // Basic
                    value: (basic / total) * 100,
                    title: '${((basic / total) * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.orange, 'Basic'),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFF16A34A), 'Pro'),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFF4338CA), 'Enterprise'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSignupsChart(Map<String, dynamic> data) {
    final signups = data['signups'] as List<dynamic>? ?? [0,0,0,0,0,0];
    final maxY = signups.isEmpty ? 50.0 : signups.reduce((a, b) => (a as num) > (b as num) ? a : b).toDouble() * 1.5;
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Gym Signups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Weekly breakdown of new gym onboardings', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 10 ? maxY : 10,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(weeks[value.toInt()], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('');
                        return Text(value.toInt().toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < signups.length; i++)
                    _buildBarData(i, (signups[i] as num).toDouble()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF3B82F6), // Blue
          width: 24,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        ),
      ],
    );
  }
}
