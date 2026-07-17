import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final superadminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('No token');

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/superadmin/dashboard'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load dashboard data');
  }
});

final superadminGymsProvider = FutureProvider<List<dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('No token');

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/superadmin/gyms'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load gyms');
  }
});

final superadminFinanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('No token');

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/superadmin/finance'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load finance data');
  }
});

final superadminGymDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, gymId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('No token');

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/superadmin/gyms/$gymId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load gym details');
  }
});

final superadminPersonDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, roleAndId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('No token');

  final parts = roleAndId.split(':');
  final role = parts[0];
  final id = parts[1];

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/superadmin/person/$role/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load person details');
  }
});

class SuperadminActions {
  static Future<void> suspendGymOwner(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token');

    final response = await http.put(
      Uri.parse('http://localhost:5000/api/superadmin/gyms/$gymId/suspend'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to suspend account: ${response.body}');
    }
  }

  static Future<void> reactivateGymOwner(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token');

    final response = await http.put(
      Uri.parse('http://localhost:5000/api/superadmin/gyms/$gymId/reactivate'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reactivate account: ${response.body}');
    }
  }

  static Future<List<dynamic>> fetchReportData(String type, String range) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token');

    final uri = Uri.parse('http://localhost:5000/api/superadmin/reports').replace(queryParameters: {
      'type': type,
      'range': range,
    });

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch report data: ${response.body}');
    }
  }
}
