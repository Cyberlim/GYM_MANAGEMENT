import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/features/payments/providers/payments_provider.dart';
import 'package:gym_owner_web/features/expenses/providers/expenses_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:intl/intl.dart';

class MonthlyData {
  final String monthLabel;
  final double revenue;
  final double expense;

  MonthlyData({required this.monthLabel, required this.revenue, required this.expense});
}

class ReportsData {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int activeMembers;
  final List<MonthlyData> monthlyData;
  final Map<String, double> expensesByCategory;
  
  final List<PaymentRecord> recentRevenues;
  final List<ExpenseRecord> recentExpenses;
  final List<Member> activeMembersList;

  ReportsData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.activeMembers,
    required this.monthlyData,
    required this.expensesByCategory,
    required this.recentRevenues,
    required this.recentExpenses,
    required this.activeMembersList,
  });
}

class ReportsTimeFilterNotifier extends Notifier<String> {
  @override
  String build() => '6 Months';

  void setFilter(String filter) => state = filter;
}

final reportsTimeFilterProvider = NotifierProvider<ReportsTimeFilterNotifier, String>(ReportsTimeFilterNotifier.new);

final reportsProvider = Provider<ReportsData>((ref) {
  final payments = ref.watch(paymentsProvider).value ?? [];
  final expenses = ref.watch(expensesProvider).value ?? [];
  final members = ref.watch(membersProvider).value ?? [];

  double totalRevenue = 0;
  double totalExpenses = 0;
  
  Map<String, double> expensesByCategory = {};
  
  List<PaymentRecord> recentRevenues = [];
  List<ExpenseRecord> recentExpenses = [];
  
  final timeFilter = ref.watch(reportsTimeFilterProvider);
  int monthsToFetch = 6;
  if (timeFilter == '3 Months') monthsToFetch = 3;
  if (timeFilter == '12 Months') monthsToFetch = 12;

  final now = DateTime.now();
  final cutoffDate = DateTime(now.year, now.month - monthsToFetch + 1, 1);

  for (var p in payments) {
    if (p.status == 'Completed' && !p.date.isBefore(cutoffDate)) {
      totalRevenue += p.amount;
      recentRevenues.add(p);
    }
  }

  for (var e in expenses) {
    if (e.status == 'Paid' && !e.date.isBefore(cutoffDate)) {
      totalExpenses += e.amount;
      expensesByCategory[e.category] = (expensesByCategory[e.category] ?? 0) + e.amount;
      recentExpenses.add(e);
    }
  }

  final netProfit = totalRevenue - totalExpenses;
  
  final activeMembersList = members.where((m) => m.status == 'Active').toList();
  final activeMembersCount = activeMembersList.length;

  // Generate historical data
  List<MonthlyData> monthlyData = [];
  
  for (int i = monthsToFetch - 1; i >= 0; i--) {
    final targetMonth = DateTime(now.year, now.month - i, 1);
    final monthLabel = DateFormat('MMM').format(targetMonth);
    
    double mRevenue = 0;
    double mExpense = 0;

    for (var p in payments) {
      if (p.status == 'Completed' && p.date.year == targetMonth.year && p.date.month == targetMonth.month) {
        mRevenue += p.amount;
      }
    }

    for (var e in expenses) {
      if (e.status == 'Paid' && e.date.year == targetMonth.year && e.date.month == targetMonth.month) {
        mExpense += e.amount;
      }
    }

    monthlyData.add(MonthlyData(monthLabel: monthLabel, revenue: mRevenue, expense: mExpense));
  }

  // Sort recent revenues and expenses by date descending
  recentRevenues.sort((a, b) => b.date.compareTo(a.date));
  recentExpenses.sort((a, b) => b.date.compareTo(a.date));

  return ReportsData(
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    activeMembers: activeMembersCount,
    monthlyData: monthlyData,
    expensesByCategory: expensesByCategory,
    recentRevenues: recentRevenues,
    recentExpenses: recentExpenses,
    activeMembersList: activeMembersList,
  );
});
