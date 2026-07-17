import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/admins_provider.dart';
import '../../features/profile/profile_provider.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class AdminsPage extends ConsumerStatefulWidget {
  const AdminsPage({super.key});

  @override
  ConsumerState<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends ConsumerState<AdminsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAddAdminModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub-Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              hint: 'john@example.com',
              controller: _emailController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              hint: 'Secure password',
              controller: _passwordController,
              isPassword: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Add Admin',
            isFullWidth: false,
            onPressed: () async {
              if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) return;
              
              setState(() => _isAdding = true);
              final error = await ref.read(adminsProvider.notifier).createAdmin(
                _nameController.text,
                _emailController.text,
                _passwordController.text,
              );
              setState(() => _isAdding = false);
              
              if (mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  _nameController.clear();
                  _emailController.clear();
                  _passwordController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin added successfully'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Admin'),
        content: Text('Are you sure you want to revoke access for $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref.read(adminsProvider.notifier).revokeAdmin(id);
              if (mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin revoked successfully'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminsState = ref.watch(adminsProvider);
    final profile = ref.watch(profileProvider);
    
    // Only master admin (no createdBy) can add/revoke
    final isMasterAdmin = profile.createdBy == null;

    return Scaffold(
      body: adminsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (admins) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Admins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text('View and manage superadmin access.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                    if (isMasterAdmin)
                      PrimaryButton(
                        text: 'Add Admin',
                        icon: LucideIcons.plus,
                        isFullWidth: false,
                        onPressed: _showAddAdminModal,
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: admins.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        final isSelf = admin.email == profile.email;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(admin.email),
                          trailing: (isMasterAdmin && !isSelf) 
                            ? OutlinedButton(
                                onPressed: () => _confirmRevoke(admin.id, admin.name),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Revoke'),
                              )
                            : isSelf 
                              ? const Chip(label: Text('You'))
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
