import 'package:gym_owner_web/core/config/env.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_owner_web/core/providers/user_provider.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    
    if (userState is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userState.value == null || userState.value!.user.isEmpty) {
      return const Center(child: Text("User data not available"));
    }

    final user = userState.value!.user;
    final gym = userState.value!.gym;

    String userName = user['name'] ?? 'Not provided';
    String email = user['email'] ?? 'Not provided';
    String role = user['role'] == 'superadmin' ? 'Superadmin' : 'Gym Owner';
    String profileImage = user['profileImage'] ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150&h=150';
    if (profileImage.isEmpty) {
      profileImage = 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150&h=150';
    }

    String gymName = gym?['name'] ?? 'Not provided';
    String address = gym?['address'] ?? 'Not provided';
    String gymPhone = gym?['contactPhone'] ?? 'Not provided';
    String userPhone = user['phone'] ?? 'Not provided';
    String plan = (gym?['subscriptionPlan'] ?? 'FREE').toString().toUpperCase();
    
    String establishedDate = 'Not provided';
    if (gym?['createdAt'] != null) {
      establishedDate = DateFormat('MMMM d, yyyy').format(DateTime.parse(gym!['createdAt']));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profile Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showEditAvatarDialog(context, profileImage),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          backgroundImage: NetworkImage(profileImage),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                            ),
                            child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$role • $gymName',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(address, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Two Column Layout
          // Two Column Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              
              Widget leftColumn = Column(
                children: [
                  _buildInfoCard(
                    context,
                    title: 'Personal Information',
                    icon: LucideIcons.user,
                    fields: {
                      'Full Name': userName,
                      'Email Address': email,
                      'Phone Number': userPhone,
                      'Role': role,
                    },
                    onEdit: () => _showEditPersonalDialog(context, user),
                  ),
                  const SizedBox(height: 24),
                  if (gym == null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                      ),
                      child: isDesktop 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.alertTriangle, color: Theme.of(context).colorScheme.error),
                                        const SizedBox(width: 8),
                                        Text('Gym Setup Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You have not completed your gym setup. Please provide your gym details to unlock all features.',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/gym-setup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Theme.of(context).colorScheme.onError,
                                ),
                                child: const Text('Setup Gym Now'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.alertTriangle, color: Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text('Gym Setup Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You have not completed your gym setup. Please provide your gym details to unlock all features.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/gym-setup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Theme.of(context).colorScheme.onError,
                                ),
                                child: const Text('Setup Gym Now'),
                              ),
                            ],
                          ),
                    )
                  else
                    _buildInfoCard(
                      context,
                      title: 'Gym Information',
                      icon: LucideIcons.building,
                      topWidget: gym['logo'] != null && gym['logo'].toString().isNotEmpty 
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(context, gym['logo']),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                                    image: DecorationImage(
                                      image: NetworkImage(gym['logo']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                      fields: {
                        'Gym Name': gymName,
                        'Address': address,
                        'Contact Phone': gymPhone,
                        'Established Date': establishedDate,
                      },
                      onEdit: () => _showEditGymDialog(context, gym),
                    ),
                ],
              );
              
              Widget rightColumn = Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.creditCard, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Current Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(plan, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                plan == 'FREE' 
                                    ? 'You are on the free tier. Upgrade to unlock advanced analytics and unlimited members.'
                                    : 'You are enjoying all premium features on the $plan plan.', 
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/choose-plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                  ),
                                  child: const Text('Upgrade to Pro'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: leftColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: rightColumn),
                  ],
                );
              }
              
              return Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 24),
                  rightColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required IconData icon, required Map<String, String> fields, VoidCallback? onEdit, Widget? topWidget}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (topWidget != null) ...[
            topWidget,
            const SizedBox(height: 16),
          ],
          ...fields.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    entry.key,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showEditAvatarDialog(BuildContext context, String currentUrl) {
    String tempUrl = currentUrl;
    XFile? selectedImage;
    bool isUploading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Edit Avatar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Drag and pinch to adjust the image inside the circle.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: selectedImage != null
                            ? FutureBuilder(
                                future: selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data as dynamic,
                                      fit: BoxFit.cover,
                                      width: 200,
                                      height: 200,
                                    );
                                  }
                                  return const CircularProgressIndicator();
                                },
                              )
                            : Image.network(
                                tempUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, size: 48),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          selectedImage = image;
                        });
                      }
                    },
                    icon: const Icon(LucideIcons.upload, size: 16),
                    label: const Text('Upload New Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (selectedImage == null) {
                      Navigator.pop(context);
                      return;
                    }
                    setState(() {
                      isUploading = true;
                    });
                    
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token');
                      
                      var uri = Uri.parse('${Env.apiUrl}/auth/profile-image');
                      var request = http.MultipartRequest('PUT', uri);
                      request.headers['Authorization'] = 'Bearer $token';
                      
                      var bytes = await selectedImage!.readAsBytes();
                      var multipartFile = http.MultipartFile.fromBytes(
                        'profileImage',
                        bytes,
                        filename: selectedImage!.name,
                      );
                      request.files.add(multipartFile);
                      
                      var response = await request.send();
                      
                      if (response.statusCode == 200) {
                        if (tempUrl.startsWith('http') && !tempUrl.contains('unsplash.com')) {
                          try {
                            await ref.read(apiServiceProvider).deleteFile(tempUrl);
                          } catch (e) {
                            debugPrint('Failed to delete old avatar from cloud: $e');
                          }
                        }
                        
                        ref.read(userProvider.notifier).refresh();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar updated successfully.'),
                              backgroundColor: Colors.green,
                            )
                          );
                        }
                      } else {
                        throw Exception('Failed to upload image');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          isUploading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: isUploading 
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Avatar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPersonalDialog(BuildContext context, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final roleController = TextEditingController(text: user['role'] == 'superadmin' ? 'Superadmin' : 'Gym Owner');
    
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Edit Personal Information', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(context, 'Full Name', controller: nameController),
                    const SizedBox(height: 12),
                    _buildTextField(context, 'Email Address', controller: emailController, enabled: false),
                    const SizedBox(height: 12),
                    _buildTextField(context, 'Phone Number', controller: phoneController),
                    const SizedBox(height: 12),
                    _buildTextField(context, 'Role', controller: roleController, enabled: false),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token');
                      final response = await http.put(
                        Uri.parse('${Env.apiUrl}/auth/profile'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({ 
                          'name': nameController.text,
                          'phone': phoneController.text,
                        }),
                      );
                      if (response.statusCode == 200) {
                        ref.read(userProvider.notifier).refresh();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal Information updated!'), backgroundColor: Colors.green));
                        }
                      } else {
                        throw Exception('Failed to update personal information');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (context.mounted) setState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGymDialog(BuildContext context, Map<String, dynamic>? gym) {
    final phoneController = TextEditingController(text: gym?['contactPhone'] ?? '');
    final gymNameController = TextEditingController(text: gym?['name'] ?? '');
    final addressController = TextEditingController(text: gym?['address'] ?? '');
    
    XFile? newLogo;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Edit Gym Information', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(context, 'Gym Name', controller: gymNameController),
                        const SizedBox(height: 12),
                        _buildTextField(context, 'Address', controller: addressController),
                        const SizedBox(height: 12),
                        _buildTextField(context, 'Phone Number', controller: phoneController),
                        const SizedBox(height: 24),
                        const Text('Gym Logo', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                image: newLogo == null && gym?['logo'] != null && gym!['logo'].isNotEmpty
                                    ? DecorationImage(image: NetworkImage(gym['logo']), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: newLogo != null
                                  ? const Icon(LucideIcons.checkCircle2, color: Colors.green)
                                  : (gym?['logo'] == null || gym!['logo'].isEmpty)
                                      ? const Icon(LucideIcons.image, color: Colors.grey)
                                      : null,
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  setState(() {
                                    newLogo = image;
                                  });
                                }
                              },
                              icon: const Icon(LucideIcons.upload, size: 16),
                              label: const Text('Change Logo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token');
                      
                      // 1. Update text fields
                      final response = await http.put(
                        Uri.parse('${Env.apiUrl}/auth/profile'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'gymName': gymNameController.text,
                          'address': addressController.text,
                          'contactPhone': phoneController.text,
                        }),
                      );
                      
                      if (response.statusCode != 200) {
                        throw Exception('Failed to update gym details');
                      }

                      // 2. Upload new logo if selected
                      if (newLogo != null) {
                        var request = http.MultipartRequest('PUT', Uri.parse('${Env.apiUrl}/auth/gym-logo'));
                        request.headers['Authorization'] = 'Bearer $token';
                        var bytes = await newLogo!.readAsBytes();
                        var multipartFile = http.MultipartFile.fromBytes('logo', bytes, filename: newLogo!.name);
                        request.files.add(multipartFile);
                        var logoRes = await request.send();
                        if (logoRes.statusCode != 200) {
                          throw Exception('Failed to upload logo');
                        }
                      }
                      
                      ref.read(userProvider.notifier).refresh();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gym Information updated!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (context.mounted) setState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(BuildContext context, String label, {TextEditingController? controller, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: !enabled,
      style: TextStyle(color: enabled ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : Colors.grey),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.withOpacity(0.1) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
