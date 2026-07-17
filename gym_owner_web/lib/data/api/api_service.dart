import 'package:gym_owner_web/core/config/env.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SuspensionException implements Exception {
  final String message;
  final String suspensionId;
  SuspensionException(this.message, this.suspensionId);
}

class ApiService {
  static String get baseUrl => Env.apiUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _processResponse(response);
  }

  Future<String?> uploadFile(List<int> bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final result = _processResponse(response);
    return result?['url'] as String?;
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body['isSuspended'] == true) {
          throw SuspensionException(body['message'] ?? 'Account Suspended', body['suspensionId'] ?? '');
        }
      } catch (_) {}
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
