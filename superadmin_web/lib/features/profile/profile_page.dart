import 'package:superadmin_web/core/config/env.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'package:go_router/go_router.dart';
import 'profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.fullName);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        ref.read(profileProvider.notifier).updateProfile(
          fullName: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please check your connection.')),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/auth/password'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to update password')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please check your connection.')),
        );
      }
    }
  }
  
  Future<void> _pickAndCropImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          dragMode: WebDragMode.move,
          viewwMode: WebViewMode.mode_3,
          cropBoxMovable: false,
          cropBoxResizable: false,
          customDialogBuilder: (cropper, initCropper, crop, rotate, scale) {
            return _CustomCropperDialog(
              cropper: cropper,
              initCropper: initCropper,
              crop: crop,
              scale: scale,
            );
          },
        ),
      ],
    );

    if (croppedFile != null) {
      final bytes = await croppedFile.readAsBytes();
      ref.read(profileProvider.notifier).updateAvatar(bytes);

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          final request = http.MultipartRequest('PUT', Uri.parse('${Env.apiUrl}/auth/profile-image'));
          request.headers['Authorization'] = 'Bearer $token';
          request.files.add(http.MultipartFile.fromBytes('profileImage', bytes, filename: 'avatar.png'));
          
          final response = await request.send();
          if (response.statusCode == 200) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload profile picture')));
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Failed to save image.')));
        }
      }
    }
  }

  void _showFullScreenImage(Uint8List avatarBytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  avatarBytes,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final profile = ref.watch(profileProvider);
    
    ref.listen(profileProvider, (previous, next) {
      if (previous?.fullName != next.fullName && _nameController.text != next.fullName) {
        _nameController.text = next.fullName;
      }
      if (previous?.email != next.email && _emailController.text != next.email) {
        _emailController.text = next.email;
      }
      if (previous?.phone != next.phone && _phoneController.text != next.phone) {
        _phoneController.text = next.phone;
      }
    });
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
              Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Manage your personal account details and credentials.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 32),
          
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
                Text('Profile Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 24),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MouseRegion(
                            cursor: profile.avatarBytes != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: profile.avatarBytes != null ? () => _showFullScreenImage(profile.avatarBytes!) : null,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: AppTheme.accentColor,
                                backgroundImage: profile.avatarBytes != null 
                                    ? MemoryImage(profile.avatarBytes!) 
                                    : (profile.profileImage != null && profile.profileImage!.isNotEmpty 
                                        ? NetworkImage(profile.profileImage!) as ImageProvider 
                                        : null),
                                child: profile.avatarBytes == null && (profile.profileImage == null || profile.profileImage!.isEmpty) 
                                    ? Text(profile.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)) 
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(text: 'Upload New', onPressed: _pickAndCropImage, isFullWidth: true, icon: LucideIcons.upload),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref.read(profileProvider.notifier).clearAvatar();
                                    },
                                    icon: const Icon(LucideIcons.trash2, size: 18),
                                    label: const Text('Remove', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Recommended size is 256x256px. Max size 2MB.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MouseRegion(
                            cursor: profile.avatarBytes != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: profile.avatarBytes != null ? () => _showFullScreenImage(profile.avatarBytes!) : null,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.accentColor,
                                backgroundImage: profile.avatarBytes != null 
                                    ? MemoryImage(profile.avatarBytes!) 
                                    : (profile.profileImage != null && profile.profileImage!.isNotEmpty 
                                        ? NetworkImage(profile.profileImage!) as ImageProvider 
                                        : null),
                                child: profile.avatarBytes == null && (profile.profileImage == null || profile.profileImage!.isEmpty) 
                                    ? Text(profile.initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)) 
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: PrimaryButton(text: 'Upload New', onPressed: _pickAndCropImage, isFullWidth: true, icon: LucideIcons.upload),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            ref.read(profileProvider.notifier).clearAvatar();
                                          },
                                          icon: const Icon(LucideIcons.trash2, size: 18),
                                          label: const Text('Remove', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Recommended size is 256x256px. Max size 2MB.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),
                
                Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 24),
                
                isMobile
                    ? Column(
                        children: [
                          CustomTextField(controller: _nameController, label: 'Full Name', hint: 'Enter full name', prefixIcon: LucideIcons.user),
                          const SizedBox(height: 24),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address', 
                            hint: 'Enter email address', 
                            prefixIcon: LucideIcons.mail,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: CustomTextField(controller: _nameController, label: 'Full Name', hint: 'Enter full name', prefixIcon: LucideIcons.user),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: CustomTextField(
                              controller: _emailController,
                              label: 'Email Address', 
                              hint: 'Enter email address', 
                              prefixIcon: LucideIcons.mail,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                CustomTextField(controller: _phoneController, label: 'Phone Number', hint: 'Enter phone number', prefixIcon: LucideIcons.phone),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PrimaryButton(text: 'Save Personal Details', onPressed: _saveChanges, isFullWidth: false),
                  ],
                ),
                
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),
                
                Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('Update your password to keep your account secure.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 24),
                
                CustomTextField(controller: _currentPasswordController, label: 'Current Password', hint: 'Enter current password', prefixIcon: LucideIcons.lock, isPassword: true),
                const SizedBox(height: 24),
                isMobile
                    ? Column(
                        children: [
                          CustomTextField(controller: _newPasswordController, label: 'New Password', hint: 'Enter new password', prefixIcon: LucideIcons.key, isPassword: true),
                          const SizedBox(height: 24),
                          CustomTextField(controller: _confirmPasswordController, label: 'Confirm New Password', hint: 'Confirm new password', prefixIcon: LucideIcons.key, isPassword: true),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: CustomTextField(controller: _newPasswordController, label: 'New Password', hint: 'Enter new password', prefixIcon: LucideIcons.key, isPassword: true),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: CustomTextField(controller: _confirmPasswordController, label: 'Confirm New Password', hint: 'Confirm new password', prefixIcon: LucideIcons.key, isPassword: true),
                          ),
                        ],
                      ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PrimaryButton(text: 'Update Password', onPressed: _updatePassword, isFullWidth: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomCropperDialog extends StatefulWidget {
  final Widget cropper;
  final void Function() initCropper;
  final Future<String?> Function() crop;
  final void Function(num) scale;

  const _CustomCropperDialog({
    required this.cropper,
    required this.initCropper,
    required this.crop,
    required this.scale,
  });

  @override
  State<_CustomCropperDialog> createState() => _CustomCropperDialogState();
}

class _CustomCropperDialogState extends State<_CustomCropperDialog> {
  bool _isProcessing = false;
  double _scaleValue = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.initCropper();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Adjust Avatar',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRect(child: widget.cropper),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.zoomOut, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                Expanded(
                  child: Slider(
                    value: _scaleValue,
                    min: 1.0,
                    max: 3.0,
                    onChanged: (value) {
                      setState(() => _scaleValue = value);
                      widget.scale(value);
                    },
                  ),
                ),
                Icon(LucideIcons.zoomIn, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          try {
                            final result = await widget.crop();
                            if (context.mounted) {
                              Navigator.of(context).pop(result);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
                        },
                  child: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
