// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist, deprecated_member_use
import 'package:flutter/material.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/charts_row.dart';
import 'widgets/lists_row.dart';
import 'widgets/bottom_actions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

String? _lastPromptedToken;

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkPushPermissions());
  }

  Future<void> _checkPushPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('token');
    
    if (currentToken == null || _lastPromptedToken == currentToken) return;
    
    final userData = ref.read(userProvider).value;
    if (userData == null) return;
    
    final settings = userData.user['settings'] ?? {};
    final pushEnabled = settings['pushNotifications'] == true;
    
    if (pushEnabled) {
      _lastPromptedToken = currentToken;
      return;
    }

    _lastPromptedToken = currentToken;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enable Push Notifications'),
              content: const Text('Would you like to receive real-time push notifications for important events?'),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    try {
                      await _enablePushNotifications();
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Push Notifications Enabled Successfully'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Setup Error: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                        Navigator.of(context).pop();
                      }
                    } finally {
                       if (mounted) setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enable'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _enablePushNotifications() async {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse('$baseUrl/notifications/vapid-public-key'), headers: headers);
    if (response.statusCode == 200) {
      final vapidKey = jsonDecode(response.body)['publicKey'];
      final promise = js_util.callMethod(js_util.globalThis, 'subscribeToPushNotifications', [vapidKey]);
      final subscriptionStr = await js_util.promiseToFuture(promise);
      
      final subResponse = await http.post(
        Uri.parse('$baseUrl/notifications/subscribe'),
        headers: headers,
        body: jsonEncode({'subscription': jsonDecode(subscriptionStr)}),
      );
      
      if (subResponse.statusCode == 200 || subResponse.statusCode == 201) {
         final userData = ref.read(userProvider).value;
         if (userData != null) {
           final currentSettings = userData.user['settings'] ?? {};
           final newSettings = Map<String, dynamic>.from(currentSettings);
           newSettings['pushNotifications'] = true;
           await ref.read(userProvider.notifier).updateSettings(newSettings);
         }
      } else {
        throw Exception('Backend returned ${subResponse.statusCode}');
      }
    } else {
      throw Exception('Could not fetch VAPID key');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return dashboardState.when(
      data: (data) {
        if (data == null) {
          return const Center(child: Text("Failed to load dashboard data"));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatCardsRow(data: data),
              const SizedBox(height: 24),
              ChartsRow(data: data),
              const SizedBox(height: 24),
              ListsRow(data: data),
              const SizedBox(height: 24),
              const BottomActionsRow(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
