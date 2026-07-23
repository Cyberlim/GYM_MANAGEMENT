// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/profile_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (context.canPop()) ...[
                        IconButton(
                          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Manage platform configurations and preferences.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Notifications'),
                    Tab(text: 'Security'),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
      },
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: TabBarView(
          controller: _tabController,
          children: const [
            _NotificationSettingsView(),
            _SecuritySettingsView(),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 50.0;
  
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // prevents content scrolling underneath from showing
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// ============================================================================
// NOTIFICATION SETTINGS VIEW
// ============================================================================
class _NotificationSettingsView extends ConsumerStatefulWidget {
  const _NotificationSettingsView();

  @override
  ConsumerState<_NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends ConsumerState<_NotificationSettingsView> {
  bool _systemAlerts = true;
  bool _newSignups = true;
  bool _paymentReceived = true;
  bool _paymentFailures = true;
  bool _pushNotifications = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = ref.read(profileProvider);
      final settings = profile.settings;
      if (settings != null) {
        if (mounted) {
          setState(() {
            _systemAlerts = settings['systemAlerts'] ?? true;
            _newSignups = settings['newGymSignups'] ?? true;
            _paymentReceived = settings['paymentReceived'] ?? true;
            _paymentFailures = settings['paymentFailures'] ?? true;
            _pushNotifications = settings['pushNotifications'] ?? false;
          });
        }
      }
    });
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await ref.read(profileProvider.notifier).updateSettings({
      'systemAlerts': _systemAlerts,
      'newGymSignups': _newSignups,
      'paymentReceived': _paymentReceived,
      'paymentFailures': _paymentFailures,
      'pushNotifications': _pushNotifications,
    });
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Preferences saved successfully' : 'Failed to save preferences'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Notification Preferences',
      description: 'Manage what emails and alerts you receive.',
      children: [
        _buildToggle(context, 'Push Notifications', 'Receive push notifications even when the app is closed.', _pushNotifications, (val) {
          setState(() => _pushNotifications = val);
          _handlePushNotificationToggle(val);
        }),
        if (_pushNotifications) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Divider(),
          ),
          _buildToggle(context, 'System Alerts', 'Receive critical system performance alerts.', _systemAlerts, (val) => setState(() => _systemAlerts = val)),
          _buildToggle(context, 'New Gym Signups', 'Get notified when a new gym registers.', _newSignups, (val) => setState(() => _newSignups = val)),
          _buildToggle(context, 'Payment Received', 'Alert me when a subscription payment is received.', _paymentReceived, (val) => setState(() => _paymentReceived = val)),
          _buildToggle(context, 'Payment Failures', 'Alert me when a subscription payment fails.', _paymentFailures, (val) => setState(() => _paymentFailures = val)),
        ],
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _isSaving 
              ? const CircularProgressIndicator() 
              : PrimaryButton(text: 'Save Preferences', onPressed: _saveSettings, isFullWidth: false),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle(BuildContext context, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF16A34A), // Green
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _handlePushNotificationToggle(bool value) async {
    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      if (value == true) {
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
            // Success, message will be shown at the end
          } else {
            throw Exception('Backend returned ${subResponse.statusCode}');
          }
        } else {
          throw Exception('Could not fetch VAPID key');
        }
      } else {
        final promise = js_util.callMethod(js_util.globalThis, 'unsubscribeFromPushNotifications', []);
        final endpointStr = await js_util.promiseToFuture(promise);
        if (endpointStr != null) {
          final unsubResponse = await http.post(
            Uri.parse('$baseUrl/notifications/unsubscribe'),
            headers: headers,
            body: endpointStr,
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
      
      if (mounted) {
        String successMessage = (value as bool) ? 'Push notifications enabled successfully' : 'Push notifications disabled successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), duration: const Duration(seconds: 2), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error handling push notification toggling: $e');
      if (mounted) {
        // Revert toggle state on error
        setState(() => _pushNotifications = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateSetting(String key, dynamic value) async {
    try {
      await ref.read(profileProvider.notifier).updateSettings({key: value});
      
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update setting'), backgroundColor: Colors.red));
      }
    }
  }
}

// ============================================================================
// SECURITY SETTINGS VIEW
// ============================================================================
class _SecuritySettingsView extends ConsumerStatefulWidget {
  const _SecuritySettingsView();

  @override
  ConsumerState<_SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends ConsumerState<_SecuritySettingsView> {
  bool _twoFactorAuth = false;
  List<dynamic> _activeSessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = ref.read(profileProvider);
      if (mounted) {
        setState(() {
          _twoFactorAuth = profile.settings?['twoFactorEnabled'] ?? false;
        });
      }
      _fetchSessions();
    });
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoadingSessions = true);
    final sessions = await ref.read(profileProvider.notifier).getActiveSessions();
    if (mounted) {
      setState(() {
        _activeSessions = sessions;
        _isLoadingSessions = false;
      });
    }
  }

  void _handleRevoke(String sessionId) async {
    final success = await ref.read(profileProvider.notifier).revokeSession(sessionId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session revoked'), backgroundColor: Colors.green));
      _fetchSessions();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to revoke session'), backgroundColor: Colors.red));
    }
  }

  void _handle2FAToggle(bool value) async {
    if (!value) {
      // Logic to disable 2FA could go here. For now, we only support enabling.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disabling 2FA requires contacting support.')));
      return;
    }

    final data = await ref.read(profileProvider.notifier).setup2FA();
    if (data != null && mounted) {
      _show2FAModal(data['qrCodeUrl']);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to setup 2FA'), backgroundColor: Colors.red));
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
              title: const Text('Setup Two-Factor Authentication'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scan this QR code with your authenticator app.'),
                  const SizedBox(height: 16),
                  Image.network(qrCodeUrl, height: 200, width: 200),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Verification Code',
                    hint: 'Enter 6-digit code',
                    controller: controller,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                isVerifying 
                  ? const CircularProgressIndicator() 
                  : PrimaryButton(
                      text: 'Verify & Enable',
                      onPressed: () async {
                        if (controller.text.length < 6) return;
                        setModalState(() => isVerifying = true);
                        final success = await ref.read(profileProvider.notifier).verify2FASetup(controller.text);
                        setModalState(() => isVerifying = false);

                        if (success) {
                          setState(() => _twoFactorAuth = true);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA Enabled Successfully!'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Code'), backgroundColor: Colors.red));
                        }
                      },
                      isFullWidth: false,
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
    return _SettingsSection(
      title: 'Security Settings',
      description: 'Secure your account and manage active sessions.',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Two-Factor Authentication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('Add an extra layer of security to your account.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Switch(
                value: _twoFactorAuth,
                activeColor: const Color(0xFF16A34A),
                onChanged: _handle2FAToggle,
              ),
            ],
          ),
        ),
        Text('Active Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 16),
        if (_isLoadingSessions)
          const Center(child: CircularProgressIndicator())
        else if (_activeSessions.isEmpty)
          const Text('No active sessions found.')
        else
          ..._activeSessions.map((session) {
            final isCurrent = false; // Add logic to identify current session if needed
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.monitor, color: Theme.of(context).colorScheme.onSurface, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session['userAgent'] ?? 'Unknown Device', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text('IP: ${session['ipAddress']} • ${DateTime.parse(session['lastActive']).toLocal().toString().split('.')[0]}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _handleRevoke(session['_id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Revoke'),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ============================================================================
// SETTINGS SECTION WIDGET
// ============================================================================
class _SettingsSection extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                ...children,
              ],
            ),
          ),
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }
}
