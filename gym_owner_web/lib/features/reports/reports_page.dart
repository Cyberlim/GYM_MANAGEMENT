import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_web/features/reports/providers/reports_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  void _showRevenueDetails(BuildContext context, List<PaymentRecord> revenues) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Revenue Details'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: revenues.isEmpty
              ? const Center(child: Text('No recent revenue data'))
              : ListView.builder(
                  itemCount: revenues.length,
                  itemBuilder: (context, index) {
                    final payment = revenues[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.indianRupee, color: Colors.green),
                      title: Text('Amount: ₹${payment.amount}'),
                      subtitle: Text('Date: ${DateFormat.yMMMd().format(payment.date)} • Method: ${payment.paymentMethod}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/payments?highlightId=${payment.id}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, List<ExpenseRecord> expenses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Expense Details'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: expenses.isEmpty
              ? const Center(child: Text('No recent expense data'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.trendingDown, color: Colors.red),
                      title: Text('${expense.title} - ₹${expense.amount}'),
                      subtitle: Text('Date: ${DateFormat.yMMMd().format(expense.date)} • Category: ${expense.category}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/expenses?highlightId=${expense.id}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNetProfitDetails(BuildContext context, ReportsData reportsData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Net Profit Summary'),
        content: SizedBox(
          width: 400,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Total Revenue'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${reportsData.totalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/payments');
                },
              ),
              ListTile(
                title: const Text('Total Expenses'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${reportsData.totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/expenses');
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('₹${reportsData.netProfit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showActiveMembers(BuildContext context, List<Member> members) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Members'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: members.isEmpty
              ? const Center(child: Text('No active members'))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.user, color: Colors.orange),
                      title: Text(member.name),
                      subtitle: Text('Plan: ${member.membershipPlan} • Joined: ${DateFormat.yMMMd().format(member.joinDate)}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/members?highlightId=${member.id}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsData = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Financial and operational performance at a glance',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 32),

            // KPI Dashboard
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(child: _KPICard(
                        title: 'Total Revenue', 
                        value: '₹${NumberFormat('#,##0.00').format(reportsData.totalRevenue)}', 
                        icon: LucideIcons.indianRupee, 
                        color: Colors.green,
                        onTap: () => _showRevenueDetails(context, reportsData.recentRevenues),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _KPICard(
                        title: 'Total Expenses', 
                        value: '₹${NumberFormat('#,##0.00').format(reportsData.totalExpenses)}', 
                        icon: LucideIcons.trendingDown, 
                        color: Colors.red,
                        onTap: () => _showExpenseDetails(context, reportsData.recentExpenses),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _KPICard(
                        title: 'Net Profit', 
                        value: '₹${NumberFormat('#,##0.00').format(reportsData.netProfit)}', 
                        icon: LucideIcons.pieChart, 
                        color: Colors.blue,
                        onTap: () => _showNetProfitDetails(context, reportsData),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _KPICard(
                        title: 'Active Members', 
                        value: '${reportsData.activeMembers}', 
                        icon: LucideIcons.users, 
                        color: Colors.orange,
                        onTap: () => _showActiveMembers(context, reportsData.activeMembersList),
                      )),
                    ],
                  );
                }

                final isMobile = constraints.maxWidth < 500;
                final cardWidth = isMobile ? (constraints.maxWidth - 16) / 2 : 200.0;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: cardWidth, child: _KPICard(
                      title: 'Total Revenue', 
                      value: '₹${NumberFormat('#,##0.00').format(reportsData.totalRevenue)}', 
                      icon: LucideIcons.indianRupee, 
                      color: Colors.green,
                      onTap: () => _showRevenueDetails(context, reportsData.recentRevenues),
                    )),
                    SizedBox(width: cardWidth, child: _KPICard(
                      title: 'Total Expenses', 
                      value: '₹${NumberFormat('#,##0.00').format(reportsData.totalExpenses)}', 
                      icon: LucideIcons.trendingDown, 
                      color: Colors.red,
                      onTap: () => _showExpenseDetails(context, reportsData.recentExpenses),
                    )),
                    SizedBox(width: cardWidth, child: _KPICard(
                      title: 'Net Profit', 
                      value: '₹${NumberFormat('#,##0.00').format(reportsData.netProfit)}', 
                      icon: LucideIcons.pieChart, 
                      color: Colors.blue,
                      onTap: () => _showNetProfitDetails(context, reportsData),
                    )),
                    SizedBox(width: cardWidth, child: _KPICard(
                      title: 'Active Members', 
                      value: '${reportsData.activeMembers}', 
                      icon: LucideIcons.users, 
                      color: Colors.orange,
                      onTap: () => _showActiveMembers(context, reportsData.activeMembersList),
                    )),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),

            // Charts
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                
                Widget cashFlowChart = Container(
                  height: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cash Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: ref.watch(reportsTimeFilterProvider),
                            underline: const SizedBox(),
                            items: ['3 Months', '6 Months', '12 Months'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                ref.read(reportsTimeFilterProvider.notifier).setFilter(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _CashFlowChart(monthlyData: reportsData.monthlyData),
                      ),
                    ],
                  ),
                );

                Widget expensePieChart = Container(
                  height: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expenses Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _ExpensePieChart(expensesByCategory: reportsData.expensesByCategory),
                      ),
                    ],
                  ),
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: cashFlowChart),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: expensePieChart),
                    ],
                  );
                }

                return Column(
                  children: [
                    cashFlowChart,
                    const SizedBox(height: 24),
                    expensePieChart,
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KPICard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 200;

            if (isSmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;

  const _CashFlowChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate max Y value for scaling
    double maxY = 0;
    for (var data in monthlyData) {
      if (data.revenue > maxY) maxY = data.revenue;
      if (data.expense > maxY) maxY = data.expense;
    }
    // Give some padding on top
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 1000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withOpacity(isDark ? 0.2 : 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
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
                if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(monthlyData[value.toInt()].monthLabel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == maxY) return const Text('');
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (monthlyData.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Revenue Line
          LineChartBarData(
            spots: List.generate(monthlyData.length, (index) => FlSpot(index.toDouble(), monthlyData[index].revenue)),
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
          // Expense Line
          LineChartBarData(
            spots: List.generate(monthlyData.length, (index) => FlSpot(index.toDouble(), monthlyData[index].expense)),
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isRevenue = spot.barIndex == 0;
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(0)}',
                  TextStyle(color: isRevenue ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _ExpensePieChart extends StatefulWidget {
  final Map<String, double> expensesByCategory;

  const _ExpensePieChart({required this.expensesByCategory});

  @override
  State<_ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<_ExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.expensesByCategory.isEmpty) {
      return const Center(child: Text('No expenses recorded'));
    }

    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.indigo];
    
    int i = 0;
    final List<PieChartSectionData> sections = widget.expensesByCategory.entries.map((entry) {
      final isTouched = i == touchedIndex;
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '${entry.key}\n₹${entry.value.toStringAsFixed(0)}' : entry.key,
        radius: isTouched ? 70 : 60,
        titlePositionPercentageOffset: 1.6, // Pushes title far away outside the slice
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}
