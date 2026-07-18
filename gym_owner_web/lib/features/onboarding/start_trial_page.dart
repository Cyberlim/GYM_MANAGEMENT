import 'package:gym_owner_web/core/config/env.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StartTrialPage extends StatefulWidget {
  const StartTrialPage({super.key});

  @override
  State<StartTrialPage> createState() => _StartTrialPageState();
}

class _StartTrialPageState extends State<StartTrialPage> {
  bool _isLoading = false;

  Future<void> _startTrial() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final response = await http.post(
        Uri.parse('${Env.apiUrl}/gyms/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan': 'trial',
          'isTrialActive': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) context.go('/dashboard');
      } else {
        var data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to start trial');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.rocket, color: Color(0xFF6366F1), size: 48),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Start Your 14-Day Free Trial',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Get full access to all premium features. No credit card required. Upgrade anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _startTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Start Free Trial Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, size: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
