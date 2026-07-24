// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'package:gym_owner_web/core/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _updateSetting(String key, dynamic value) async {
    final userData = ref.read(userProvider).value;
    if (userData == null) return;
    
    final currentSettings = userData.user['settings'] ?? {};
    final newSettings = Map<String, dynamic>.from(currentSettings);
    newSettings[key] = value;

    if (key == 'pushNotifications') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final baseUrl = dotenv.env['API_URL']!;
        final headers = {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        };

        if (value == true) {
          // Fetch VAPID key
          final response = await http.get(Uri.parse('$baseUrl/notifications/vapid-public-key'), headers: headers);
          if (response.statusCode == 200) {
            final vapidKey = jsonDecode(response.body)['publicKey'];
            // Call JS Interop
            final promise = js_util.callMethod(js_util.globalThis, 'subscribeToPushNotifications', [vapidKey]);
            final subscriptionStr = await js_util.promiseToFuture(promise);
            
            // Send subscription to backend
            final subResponse = await http.post(
              Uri.parse('$baseUrl/notifications/subscribe'),
              headers: headers,
              body: jsonEncode({'subscription': jsonDecode(subscriptionStr)}),
            );
            
            if (subResponse.statusCode == 200 || subResponse.statusCode == 201) {
              // Success, message will be shown at the end
            } else {
              throw Exception('Backend returned ${subResponse.statusCode}');
            }
          } else {
            throw Exception('Could not fetch VAPID key');
          }
        } else {
          // Unsubscribe
          final promise = js_util.callMethod(js_util.globalThis, 'unsubscribeFromPushNotifications', []);
          final endpointStr = await js_util.promiseToFuture(promise);
          if (endpointStr != null) {
            final unsubResponse = await http.post(
              Uri.parse('$baseUrl/notifications/unsubscribe'),
              headers: headers,
              body: endpointStr, // already JSON encoded like {"endpoint": "..."}
            );
            
            if (unsubResponse.statusCode == 200) {
              // Success, message will be shown at the end
            } else {
              throw Exception('Backend returned ${unsubResponse.statusCode}');
            }
          } else {
             // Success, message will be shown at the end
          }
        }
      } catch (e) {
        print('Error handling push notification toggling: $e');
        if (mounted) {
          // Revert the setting since it failed
          setState(() {
            newSettings['pushNotifications'] = !(value as bool);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Setup Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
        return; // Prevent saving the setting to backend if setup failed
      }
    }

    try {
      await ref.read(userProvider.notifier).updateSettings(newSettings);
      if (mounted) {
        String successMessage = 'Setting updated successfully';
        if (key == 'emailNotifications') {
          successMessage = (value as bool) ? 'Email notifications enabled successfully' : 'Email notifications disabled successfully';
        } else if (key == 'pushNotifications') {
          successMessage = (value as bool) ? 'Push notifications enabled successfully' : 'Push notifications disabled successfully';
        } else if (key == 'twoFactorEnabled') {
          successMessage = (value as bool) ? 'Two-Factor Authentication enabled successfully' : 'Two-Factor Authentication disabled successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), duration: const Duration(seconds: 2), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 6) return 'Must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      obscureText: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val != newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setStateDialog(() => isLoading = true);
                      try {
                        await ref.read(userProvider.notifier).updatePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully'), duration: Duration(seconds: 2), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) setStateDialog(() => isLoading = false);
                      }
                    }
                  },
                  child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _handle2FAToggle(bool value) async {
    if (!value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disabling 2FA requires contacting support.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await ref.read(userProvider.notifier).setup2FA('app');
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading
      if (data != null && mounted) {
        _show2FAModal(data['qrCodeUrl']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  void _show2FAModal(String qrCodeUrl) {
    final controller = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text('Setup Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scan this QR code with your authenticator app.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Builder(
                      builder: (context) {
                        try {
                          final base64String = qrCodeUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
                          return Image.memory(
                            base64Decode(base64String), 
                            height: 200, 
                            width: 200,
                          );
                        } catch (e) {
                          print('Error decoding QR code: $e');
                          return const SizedBox(
                            height: 200, 
                            width: 200, 
                            child: Center(child: Icon(Icons.error, color: Colors.red)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Verification Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                ),
                isVerifying 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111), // Almost black
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (controller.text.length < 6) return;
                        setModalState(() => isVerifying = true);
                        try {
                          await ref.read(userProvider.notifier).verify2FASetup(controller.text);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA Enabled Successfully!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                          }
                        } finally {
                          setModalState(() => isVerifying = false);
                        }
                      },
                      child: const Text('Verify & Enable', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider).value;
    final isGoogleAuth = userData?.user['authProvider'] == 'google';
    final settings = userData?.user['settings'] ?? {};

    final emailNotifications = settings['emailNotifications'] ?? true;
    final pushNotifications = settings['pushNotifications'] ?? false;
    final twoFactorEnabled = settings['twoFactorEnabled'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your gym preferences and configurations',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildSettingsSection(
            context,
            title: 'Notifications',
            icon: LucideIcons.bell,
            children: [
              _buildSwitchTile(
                context,
                title: 'Email Notifications',
                subtitle: 'Receive daily summaries and alerts via email',
                value: emailNotifications,
                onChanged: (val) => _updateSetting('emailNotifications', val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: 'Push Notifications',
                subtitle: 'Get real-time alerts on your device',
                value: pushNotifications,
                onChanged: (val) => _updateSetting('pushNotifications', val),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            context,
            title: 'Security',
            icon: LucideIcons.lock,
            children: [
              if (!isGoogleAuth) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account password'),
                  trailing: ElevatedButton(
                    onPressed: () => _showChangePasswordDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Update'),
                  ),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Add an extra layer of security to your account'),
                trailing: ElevatedButton(
                  onPressed: () {
                    if (twoFactorEnabled) {
                      _updateSetting('twoFactorEnabled', false);
                    } else {
                      _handle2FAToggle(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: twoFactorEnabled
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: twoFactorEnabled
                        ? Theme.of(context).colorScheme.onError
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(twoFactorEnabled ? 'Disable' : 'Enable'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
