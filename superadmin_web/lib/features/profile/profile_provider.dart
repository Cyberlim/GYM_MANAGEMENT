import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final Uint8List? avatarBytes;
  final String? profileImage;
  final Map<String, dynamic>? settings;
  final String? createdBy;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.role,
    required this.phone,
    this.avatarBytes,
    this.profileImage,
    this.settings,
    this.createdBy,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? role,
    String? phone,
    Uint8List? avatarBytes,
    String? profileImage,
    Map<String, dynamic>? settings,
    String? createdBy,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
      profileImage: clearAvatar ? null : (profileImage ?? this.profileImage),
      settings: settings ?? this.settings,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get initials {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length > 1 ? 2 : 1).toUpperCase();
  }
}

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return UserProfile(
      fullName: 'Super Admin',
      email: '',
      role: 'Super Admin',
      phone: '',
    );
  }

  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        state = state.copyWith(
          fullName: user['name'] ?? '',
          email: user['email'] ?? '',
          phone: user['phone'] ?? '',
          role: user['role'] ?? 'superadmin',
          profileImage: user['profileImage'],
          settings: user['settings'] as Map<String, dynamic>?,
          createdBy: user['createdBy'],
        );
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }
  }

  Future<bool> updateProfile({String? fullName, String? email, String? phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (fullName != null) 'name': fullName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          fullName: fullName,
          email: email,
          phone: phone,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/superadmin/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(newSettings),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(settings: jsonDecode(response.body));
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to update settings: $e');
      return false;
    }
  }

  void updateAvatar(Uint8List avatarBytes) {
    state = state.copyWith(avatarBytes: avatarBytes);
  }

  void clearAvatar() {
    state = state.copyWith(clearAvatar: true);
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

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

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to update password: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> setup2FA() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/2fa/setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'method': 'app'}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // { qrCodeUrl, secret }
      }
      return null;
    } catch (e) {
      print('Failed to setup 2FA: $e');
      return null;
    }
  }

  Future<bool> verify2FASetup(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/2fa/verify-setup'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        // Update local state to reflect 2FA is enabled
        if (state.settings != null) {
          final newSettings = Map<String, dynamic>.from(state.settings!);
          newSettings['twoFactorEnabled'] = true;
          state = state.copyWith(settings: newSettings);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to verify 2FA: $e');
      return false;
    }
  }

  Future<List<dynamic>> getActiveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/auth/sessions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Failed to fetch active sessions: $e');
      return [];
    }
  }

  Future<bool> revokeSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/auth/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to revoke session: $e');
      return false;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});
