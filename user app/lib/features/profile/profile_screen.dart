import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/auth_provider.dart';
import 'package:user_app/core/theme_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showFullScreenAvatar(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeModeProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final expiryDate = user['expiryDate'] != null ? DateTime.parse(user['expiryDate']) : null;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.logOut),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user['imageUrl'] != null && user['imageUrl'].isNotEmpty) {
                        _showFullScreenAvatar(context, user['imageUrl']);
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                      backgroundImage: user['imageUrl'] != null && user['imageUrl'].isNotEmpty ? NetworkImage(user['imageUrl']) : null,
                      child: user['imageUrl'] == null || user['imageUrl'].isEmpty
                          ? Icon(LucideIcons.user, size: 40, color: const Color(0xFF6C5CE7))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user['name'] ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(user['email'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isExpired ? Colors.red : Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  Icon(isExpired ? LucideIcons.alertTriangle : LucideIcons.checkCircle, color: isExpired ? Colors.red : Colors.green, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Status: ${isExpired ? 'Expired' : 'Active'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (expiryDate != null)
                          Text('Expires on ${DateFormat.yMMMd().format(expiryDate)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildInfoTile(context, LucideIcons.phone, 'Phone', user['phone'] ?? 'N/A'),
            _buildInfoTile(context, LucideIcons.creditCard, 'Current Plan', user['membershipPlan'] ?? 'N/A'),
            _buildInfoTile(context, LucideIcons.mapPin, 'Address', (user['address'] == null || user['address'].isEmpty) ? 'N/A' : user['address']),
            _buildInfoTile(context, LucideIcons.calendar, 'Date of Birth', user['dob'] != null ? DateFormat.yMMMd().format(DateTime.parse(user['dob'])) : 'N/A'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Icon(themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun, color: const Color(0xFF6C5CE7)),
              ),
              title: Text('Dark Mode', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleTheme(value);
                },
                activeColor: const Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: const Icon(LucideIcons.lock, color: Color(0xFF6C5CE7)),
              ),
              title: const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/change-password'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/support'),
                icon: const Icon(LucideIcons.messageCircle, size: 18),
                label: const Text('Support Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF6C5CE7).withOpacity(0.5)),
                  foregroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Icon(icon, color: const Color(0xFF6C5CE7)),
      ),
      title: Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}
