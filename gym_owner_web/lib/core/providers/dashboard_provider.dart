import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardData {
  final int totalMembers;
  final int activeMembers;
  final int totalTrainers;
  final double monthlyRevenue;
  final List<Map<String, dynamic>> revenueTrend;
  final List<Map<String, dynamic>> memberGrowth;
  final List<Map<String, dynamic>> recentMembers;
  final List<Map<String, dynamic>> upcomingRenewals;
  final List<Map<String, dynamic>> recentTransactions;
  final Map<String, dynamic> attendanceStats;

  DashboardData({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalTrainers,
    required this.monthlyRevenue,
    required this.revenueTrend,
    required this.memberGrowth,
    required this.recentMembers,
    required this.upcomingRenewals,
    required this.recentTransactions,
    required this.attendanceStats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalMembers: json['totalMembers'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      totalTrainers: json['totalTrainers'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      revenueTrend: List<Map<String, dynamic>>.from(json['revenueTrend'] ?? []),
      memberGrowth: List<Map<String, dynamic>>.from(json['memberGrowth'] ?? []),
      recentMembers: List<Map<String, dynamic>>.from(json['recentMembers'] ?? []),
      upcomingRenewals: List<Map<String, dynamic>>.from(json['upcomingRenewals'] ?? []),
      recentTransactions: List<Map<String, dynamic>>.from(json['recentTransactions'] ?? []),
      attendanceStats: json['attendanceStats'] ?? {
        'Member': {
          'Today': {'present': 0, 'total': 0, 'late': 0},
          'Yesterday': {'present': 0, 'total': 0, 'late': 0},
          'This Week': {'present': 0, 'total': 0, 'late': 0},
        },
        'Staff': {
          'Today': {'present': 0, 'total': 0, 'late': 0},
          'Yesterday': {'present': 0, 'total': 0, 'late': 0},
          'This Week': {'present': 0, 'total': 0, 'late': 0},
        },
        'Trainer': {
          'Today': {'present': 0, 'total': 0, 'late': 0},
          'Yesterday': {'present': 0, 'total': 0, 'late': 0},
          'This Week': {'present': 0, 'total': 0, 'late': 0},
        }
      },
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardData?> {
  @override
  Future<DashboardData?> build() async {
    return _fetchDashboardData();
  }

  Future<DashboardData?> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('http://localhost:5000/api/dashboard/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DashboardData.fromJson(data);
    } else {
      throw Exception('Failed to fetch dashboard data');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDashboardData());
  }
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardData?>(() {
  return DashboardNotifier();
});

class AttendanceRoleFilterNotifier extends Notifier<String> {
  @override
  String build() => 'Member';

  void setFilter(String filter) {
    state = filter;
  }
}

final attendanceRoleFilterProvider = NotifierProvider<AttendanceRoleFilterNotifier, String>(() {
  return AttendanceRoleFilterNotifier();
});
