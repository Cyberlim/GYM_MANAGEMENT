import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_URL']!,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // --- Generic Methods ---
  Future<dynamic> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }

  Future<dynamic> post(String path, [dynamic data]) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, [dynamic data]) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'loginId': loginId,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw e.message ?? 'Login failed';
    }
  }

  Future<void> changePassword(String newPassword, [String? currentPassword]) async {
    try {
      await _dio.post('/change-password', data: {
        'newPassword': newPassword,
        if (currentPassword != null) 'currentPassword': currentPassword,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw e.message ?? 'Failed to change password';
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw e.message ?? 'Failed to send OTP';
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _dio.post('/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw e.message ?? 'Failed to reset password';
    }
  }

  // --- Profile ---
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  // --- Attendance ---
  Future<List<dynamic>> getAttendance() async {
    try {
      final response = await _dio.get('/attendance');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  // --- Plans ---
  Future<List<dynamic>> getPlans() async {
    try {
      final response = await _dio.get('/plans');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  Future<Map<String, dynamic>> purchasePlan(String planId) async {
    try {
      final response = await _dio.post('/purchase-plan', data: {'planId': planId});
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  // --- Support ---
  Future<List<dynamic>> getSupportMessages() async {
    try {
      final response = await _dio.get('/support');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  Future<Map<String, dynamic>> sendSupportMessage(String message) async {
    try {
      final response = await _dio.post('/support', data: {'message': message});
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }

  Future<void> markSupportMessagesRead() async {
    try {
      await _dio.put('/support/read');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message;
    }
  }
}
