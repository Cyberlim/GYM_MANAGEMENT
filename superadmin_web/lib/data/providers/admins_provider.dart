import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/superadmin_models.dart';

class AdminsNotifier extends Notifier<AsyncValue<List<AdminUser>>> {
  @override
  AsyncValue<List<AdminUser>> build() {
    fetchAdmins();
    return const AsyncValue.loading();
  }

  Future<void> fetchAdmins() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        state = AsyncValue.error('No token found', StackTrace.current);
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/superadmin/admins'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final admins = data.map((json) => AdminUser.fromJson(json)).toList();
        state = AsyncValue.data(admins);
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Failed to load admins';
        state = AsyncValue.error(msg, StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createAdmin(String name, String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return 'No authentication token';

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/superadmin/admins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        await fetchAdmins();
        return null;
      } else {
        return jsonDecode(response.body)['message'] ?? 'Failed to create admin';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> revokeAdmin(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return 'No authentication token';

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/superadmin/admins/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchAdmins();
        return null;
      } else {
        return jsonDecode(response.body)['message'] ?? 'Failed to revoke admin';
      }
    } catch (e) {
      return e.toString();
    }
  }
}

final adminsProvider = NotifierProvider<AdminsNotifier, AsyncValue<List<AdminUser>>>(() {
  return AdminsNotifier();
});
