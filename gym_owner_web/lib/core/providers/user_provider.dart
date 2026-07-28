import 'package:gym_owner_web/core/config/env.dart';
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
      Uri.parse('${Env.apiUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final gymData = data['gym'] as Map<String, dynamic>?;
      
      if (gymData != null) {
        await prefs.setBool('isGymSetup', true);
        
        bool hasPlan = false;
        bool isTrial = false;
        int trialDaysRemaining = 0;
        int planDaysRemaining = 0;
        
        final planStr = (gymData['subscriptionPlan'] ?? '').toString().toLowerCase();
        isTrial = planStr == 'trial' || planStr == 'free trial';
        hasPlan = planStr.isNotEmpty && planStr != 'null' && planStr != 'pending' && !isTrial;
        
        if (isTrial && gymData['createdAt'] != null) {
           final createdAt = DateTime.parse(gymData['createdAt']);
           final trialEnd = createdAt.add(const Duration(days: 14));
           trialDaysRemaining = trialEnd.difference(DateTime.now()).inDays;
           if (trialDaysRemaining < 0) trialDaysRemaining = 0;
        }
        
        if (hasPlan && gymData['subscriptionExpiryDate'] != null) {
           final expiryDate = DateTime.parse(gymData['subscriptionExpiryDate']);
           planDaysRemaining = expiryDate.difference(DateTime.now()).inDays;
           if (planDaysRemaining < 0) planDaysRemaining = 0;
        } else if (hasPlan) {
           planDaysRemaining = 30;
        }
        final bool requiresUpgrade = (!hasPlan && (!isTrial || trialDaysRemaining <= 0)) || (hasPlan && planDaysRemaining <= 0);
        await prefs.setBool('requiresUpgrade', requiresUpgrade);
      } else {
        await prefs.setBool('isGymSetup', false);
        await prefs.setBool('requiresUpgrade', false);
      }

      return UserData(
        user: data['user'] as Map<String, dynamic>,
        gym: gymData,
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
      Uri.parse('${Env.apiUrl}/auth/settings'),
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
      Uri.parse('${Env.apiUrl}/auth/password'),
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
      Uri.parse('${Env.apiUrl}/auth/2fa/setup'),
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

  Future<void> disable2FA(String method, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('${Env.apiUrl}/auth/2fa/disable'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'method': method,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to disable 2FA');
    }
    
    await refresh();
  }

  Future<void> verify2FASetup(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('${Env.apiUrl}/auth/2fa/verify-setup'),
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
