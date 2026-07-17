import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? gym;
  
  UserData({required this.user, this.gym});
}

class UserNotifier extends AsyncNotifier<UserData?> {
  @override
  Future<UserData?> build() async {
    return _fetchUserData();
  }

  Future<UserData?> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('http://localhost:5000/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserData(
        user: data['user'] as Map<String, dynamic>,
        gym: data['gym'] as Map<String, dynamic>?,
      );
    } else {
      if (response.statusCode == 401) {
        await prefs.remove('token');
      } else if (response.statusCode == 403) {
        // Handle suspension logout
        await prefs.remove('token');
      }
      throw Exception('Failed to fetch user data');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUserData());
  }

  void clearUserData() {
    state = const AsyncValue.data(null);
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('http://localhost:5000/api/auth/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'settings': settings}),
    );

    if (response.statusCode == 200) {
      final updatedSettings = jsonDecode(response.body);
      final currentData = state.value;
      if (currentData != null) {
        final updatedUser = Map<String, dynamic>.from(currentData.user);
        updatedUser['settings'] = updatedSettings;
        state = AsyncValue.data(UserData(user: updatedUser, gym: currentData.gym));
      }
    } else {
      throw Exception('Failed to update settings');
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('http://localhost:5000/api/auth/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update password');
    }
  }

  Future<Map<String, dynamic>> setup2FA(String method) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/2fa/setup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'method': method}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to setup 2FA');
    }
    
    return jsonDecode(response.body);
  }

  Future<void> verify2FASetup(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/2fa/verify-setup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to verify 2FA code');
    }

    // Update local state to reflect that 2FA is now enabled
    final currentData = state.value;
    if (currentData != null) {
      final updatedUser = Map<String, dynamic>.from(currentData.user);
      updatedUser['settings'] = Map<String, dynamic>.from(updatedUser['settings'] ?? {});
      updatedUser['settings']['twoFactorEnabled'] = true;
      state = AsyncValue.data(UserData(user: updatedUser, gym: currentData.gym));
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserData?>(() {
  return UserNotifier();
});
