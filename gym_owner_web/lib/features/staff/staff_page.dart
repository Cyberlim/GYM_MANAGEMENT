import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/staff/providers/staff_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

void showStaffDialog(BuildContext context, WidgetRef ref, {Staff? staffToEdit}) {
  final nameController = TextEditingController(text: staffToEdit?.name ?? '');
  final roleController = TextEditingController(text: staffToEdit?.role ?? '');
  final shiftController = TextEditingController(text: staffToEdit?.shift ?? '');
  final emailController = TextEditingController(text: staffToEdit?.email ?? '');
  final phoneController = TextEditingController(text: staffToEdit?.phone ?? '');
  String? pickedImagePath = staffToEdit?.imageUrl;
  String? pickedIdProofPath = staffToEdit?.idProofUrl;
  DateTime? selectedDob = staffToEdit?.dob;
  final ImagePicker picker = ImagePicker();
  bool isUploadingProfile = false;
  bool isUploadingIdProof = false;

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showImagePopup(BuildContext ctx, String path, {bool isCircle = false}) {
    showDialog(
      context: ctx,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: isCircle
                  ? ClipOval(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Image.network(path, fit: BoxFit.cover),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: Image.network(path, fit: BoxFit.contain),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(staffToEdit == null ? 'Add New Staff' : 'Edit Staff', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: SizedBox(
              width: 400,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile Photo Upload
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (pickedImagePath != null && pickedImagePath!.isNotEmpty) {
                                _showImagePopup(context, pickedImagePath!, isCircle: true);
                              }
                            },
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: (pickedImagePath != null && pickedImagePath!.isNotEmpty) ? NetworkImage(pickedImagePath!) : null,
                              child: (pickedImagePath == null || pickedImagePath!.isEmpty)
                                  ? Icon(LucideIcons.user, size: 32, color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
                                  : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() => isUploadingProfile = true);
                                try {
                                  final bytes = await image.readAsBytes();
                                  final url = await ref.read(apiServiceProvider).uploadFile(bytes, image.name);
                                  if (url != null) {
                                    if (pickedImagePath != null && pickedImagePath!.startsWith('http') && !pickedImagePath!.contains('unsplash.com')) {
                                      try { await ref.read(apiServiceProvider).deleteFile(pickedImagePath!); } catch (e) { debugPrint('Failed to delete old image: $e'); }
                                    }
                                    setState(() => pickedImagePath = url);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
                                } finally {
                                  setState(() => isUploadingProfile = false);
                                }
                              }
                            },
                            child: isUploadingProfile
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                                    ),
                                    child: Icon(LucideIcons.camera, size: 14, color: Theme.of(context).colorScheme.onPrimary),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Role (e.g. Front Desk, Cleaning)'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Shift Dropdown
                    DropdownButtonFormField<String>(
                      value: ['Morning', 'Evening', 'Night'].contains(shiftController.text) 
                          ? shiftController.text 
                          : null,
                      decoration: const InputDecoration(labelText: 'Shift'),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      items: const [
                        DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                        DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                        DropdownMenuItem(value: 'Night', child: Text('Night')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            shiftController.text = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDob ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) setState(() => selectedDob = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth (Optional)',
                              ),
                              child: Text(selectedDob != null ? '${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}' : 'Select Date', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // ID Proof Uploader
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID Proof (Aadhar/PAN)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        TextButton.icon(
                          onPressed: () async {
                            final XFile? doc = await picker.pickImage(source: ImageSource.gallery);
                            if (doc != null) {
                              setState(() => isUploadingIdProof = true);
                              try {
                                final bytes = await doc.readAsBytes();
                                final url = await ref.read(apiServiceProvider).uploadFile(bytes, doc.name);
                                if (url != null) {
                                  if (pickedIdProofPath != null && pickedIdProofPath!.startsWith('http')) {
                                    try { await ref.read(apiServiceProvider).deleteFile(pickedIdProofPath!); } catch (e) { debugPrint('Failed to delete old id proof: $e'); }
                                  }
                                  setState(() => pickedIdProofPath = url);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
                              } finally {
                                setState(() => isUploadingIdProof = false);
                              }
                            }
                          },
                          icon: isUploadingIdProof 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(LucideIcons.upload, size: 16, color: Theme.of(context).colorScheme.primary),
                          label: Text(isUploadingIdProof ? 'Uploading...' : 'Upload', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (pickedIdProofPath == null || pickedIdProofPath!.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Text('No document uploaded', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  pickedIdProofPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.imageOff)),
                                ),
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('ID Proof', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.eye, size: 18),
                              tooltip: 'View',
                              onPressed: () => _showImagePopup(context, pickedIdProofPath!, isCircle: false),
                            ),
                            if (pickedIdProofPath!.startsWith('http'))
                              IconButton(
                                icon: const Icon(LucideIcons.download, size: 18),
                                tooltip: 'Download',
                                onPressed: () async {
                                  final url = Uri.parse(pickedIdProofPath!);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    title: const Text('Remove ID Proof?'),
                                    content: const Text('Are you sure you want to remove this ID proof?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await ref.read(apiServiceProvider).deleteFile(pickedIdProofPath!);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Warning: Failed to delete file from cloud: $e'), backgroundColor: Colors.orange),
                                              );
                                            }
                                          }
                                          setState(() => pickedIdProofPath = null);
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                          }
                                        },
                                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && roleController.text.isNotEmpty) {
                    final newStaff = Staff(
                      id: staffToEdit?.id ?? '',
                      name: nameController.text.trim(),
                      role: roleController.text.trim(),
                      shift: shiftController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim(),
                      dob: selectedDob,
                      imageUrl: pickedImagePath,
                      idProofUrl: pickedIdProofPath,
                    );
                    
                    final isNew = staffToEdit == null;
                    if (isNew) {
                      ref.read(staffProvider.notifier).addStaff(newStaff);
                    } else {
                      ref.read(staffProvider.notifier).updateStaff(newStaff);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isNew ? 'Staff added successfully!' : 'Staff updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                child: Text(staffToEdit == null ? 'Save Staff' : 'Update Staff', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      );
    }
  );
}

class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(filteredStaffProvider);
    final isListViewSetting = ref.watch(isStaffListViewProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isListView = isMobile ? false : isListViewSetting;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your gym staff and receptionists',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeader(context, ref, isListViewSetting, isMobile),
          const SizedBox(height: 24),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
              data: (staffMembers) => staffMembers.isEmpty
                ? Center(
                    child: Text(
                      'No staff found',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  )
                : isListView
                    ? Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tableWidth = constraints.maxWidth > 600 ? constraints.maxWidth : 600.0;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints.tightFor(
                                  width: tableWidth,
                                  height: constraints.maxHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTableHeader(context),
                                    Divider(color: Theme.of(context).dividerColor, height: 1),
                                    Expanded(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: staffMembers.length,
                                        separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                                        itemBuilder: (context, index) {
                                          return _StaffTableRow(staff: staffMembers[index]);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 340,
                        ),
                        itemCount: staffMembers.length,
                        itemBuilder: (context, index) {
                          return _StaffCard(staff: staffMembers[index]);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isListView, bool isMobile) {
    final searchField = TextField(
      onChanged: (val) => ref.read(staffSearchQueryProvider.notifier).updateQuery(val),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search staff by name or role...',
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(LucideIcons.search, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    return Row(
      children: [
        if (isMobile)
          Expanded(child: searchField)
        else
          SizedBox(width: 300, child: searchField),
        if (isMobile)
          const SizedBox(width: 16)
        else
          const Spacer(),
        if (!isMobile) ...[
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ToggleButtons(
              isSelected: [isListView, !isListView],
              onPressed: (index) {
                ref.read(isStaffListViewProvider.notifier).setMode(index == 0);
              },
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              selectedColor: Theme.of(context).colorScheme.primary,
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              children: const [
                Icon(LucideIcons.list, size: 20),
                Icon(LucideIcons.layoutGrid, size: 20),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => showStaffDialog(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('NAME', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('ROLE', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('SHIFT', style: _headerStyle(context))),
          Expanded(flex: 3, child: Text('CONTACT', style: _headerStyle(context))),
          const SizedBox(width: 48), // Space for actions
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      letterSpacing: 1,
    );
  }
}

Color _getRoleColor(String role) {
  final lRole = role.toLowerCase();
  if (lRole.contains('manager')) return Colors.purple;
  if (lRole.contains('front desk') || lRole.contains('reception')) return Colors.blue;
  if (lRole.contains('clean') || lRole.contains('maintenance')) return Colors.orange;
  return Colors.green;
}

class _StaffCard extends ConsumerWidget {
  final Staff staff;

  const _StaffCard({required this.staff});

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: ClipOval(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: staff.imageUrl != null && staff.imageUrl!.isNotEmpty
                        ? Image.network(staff.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Center(
                              child: Text(
                                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 100, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIdProof(BuildContext context) {
    if (staff.idProofUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.network(
                        staff.idProofUrl!, 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                           return Container(
                             width: 300,
                             height: 300,
                             color: Theme.of(context).colorScheme.surface,
                             padding: const EdgeInsets.all(24),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(LucideIcons.fileText, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                 const SizedBox(height: 16),
                                 Text('Document Preview Not Available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center),
                                 const SizedBox(height: 8),
                                 Text('Please use the download button to view this file.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12), textAlign: TextAlign.center),
                               ]
                             )
                           );
                        }
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(LucideIcons.download, color: Colors.white, size: 20),
                      onPressed: () async {
                        final url = Uri.parse(staff.idProofUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      tooltip: 'Download',
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _getRoleColor(staff.role);

    return InkWell(
      onTap: () => showStaffDetailsDialog(context, ref, staff),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    roleColor.withOpacity(0.15),
                    roleColor.withOpacity(0.0),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          Column(
            children: [
              // Profile Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showFullImage(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: roleColor.withOpacity(0.1),
                          backgroundImage: staff.imageUrl != null && staff.imageUrl!.isNotEmpty ? NetworkImage(staff.imageUrl!) : null,
                          child: staff.imageUrl == null || staff.imageUrl!.isEmpty
                              ? Text(
                                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                                  style: TextStyle(color: roleColor, fontSize: 28, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (staff.phone.isNotEmpty)
                      Text(staff.phone, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (staff.email.isNotEmpty)
                      Text(staff.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        staff.role,
                        style: TextStyle(
                          fontSize: 12,
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Section
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.5), height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          staff.shift,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (staff.idProofUrl != null) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showIdProof(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.creditCard, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text('ID Proof', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => showStaffDialog(context, ref, staffToEdit: staff),
                            icon: const Icon(LucideIcons.edit2, size: 16),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => ref.read(staffProvider.notifier).removeStaff(staff.id),
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StaffTableRow extends ConsumerWidget {
  final Staff staff;

  const _StaffTableRow({required this.staff});

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: ClipOval(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: staff.imageUrl != null && staff.imageUrl!.isNotEmpty
                        ? Image.network(staff.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Center(
                              child: Text(
                                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 100, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIdProof(BuildContext context) {
    if (staff.idProofUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.network(
                        staff.idProofUrl!, 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                           return Container(
                             width: 300,
                             height: 300,
                             color: Theme.of(context).colorScheme.surface,
                             padding: const EdgeInsets.all(24),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(LucideIcons.fileText, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                 const SizedBox(height: 16),
                                 Text('Document Preview Not Available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center),
                                 const SizedBox(height: 8),
                                 Text('Please use the download button to view this file.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12), textAlign: TextAlign.center),
                               ]
                             )
                           );
                        }
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(LucideIcons.download, color: Colors.white, size: 20),
                      onPressed: () async {
                        final url = Uri.parse(staff.idProofUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      tooltip: 'Download',
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => showStaffDetailsDialog(context, ref, staff),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
        children: [
          // User Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: staff.imageUrl != null && staff.imageUrl!.isNotEmpty ? NetworkImage(staff.imageUrl!) : null,
                    child: staff.imageUrl == null || staff.imageUrl!.isEmpty
                        ? Text(
                            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    staff.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Role
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(staff.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getRoleColor(staff.role).withOpacity(0.2)),
                ),
                child: Text(
                  staff.role,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleColor(staff.role),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Shift
          Expanded(
            flex: 2,
            child: Text(
              staff.shift,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),

          // Contact
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (staff.phone.isNotEmpty) Text(staff.phone, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (staff.email.isNotEmpty) Text(staff.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (staff.idProofUrl != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showIdProof(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.creditCard, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('View ID Proof', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          SizedBox(
            width: 48,
            child: PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreHorizontal, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              color: Theme.of(context).colorScheme.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  showStaffDialog(context, ref, staffToEdit: staff);
                } else if (value == 'delete') {
                  ref.read(staffProvider.notifier).removeStaff(staff.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
void showStaffDetailsDialog(BuildContext context, WidgetRef ref, Staff staff) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with edit icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Staff Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      showStaffDialog(context, ref, staffToEdit: staff);
                    },
                    tooltip: 'Edit Staff',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Profile Image
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: staff.imageUrl != null && staff.imageUrl!.isNotEmpty ? NetworkImage(staff.imageUrl!) : null,
                child: staff.imageUrl == null || staff.imageUrl!.isEmpty
                    ? Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(staff.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(staff.email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 32),
              
              // Info grid
              Row(
                children: [
                  Expanded(child: _buildStaffInfoItem(context, LucideIcons.phone, 'Phone', staff.phone)),
                  Expanded(child: _buildStaffInfoItem(context, LucideIcons.briefcase, 'Role', staff.role)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildStaffInfoItem(context, LucideIcons.clock, 'Shift', staff.shift)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStaffInfoItem(context, LucideIcons.calendarDays, 'Date of Birth', staff.dob != null ? DateFormat('MMM d, yyyy').format(staff.dob!) : 'N/A')),
                ],
              ),
              if (staff.idProofUrl != null && staff.idProofUrl!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ID Proof', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.fileText, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('ID Proof Document', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.eye, size: 18),
                        tooltip: 'View',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 5.0,
                                    child: Image.network(
                                      staff.idProofUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(LucideIcons.fileWarning, size: 64, color: Colors.red),
                                          const SizedBox(height: 16),
                                          const Text('Image not available', style: TextStyle(color: Colors.white, fontSize: 16)),
                                          const SizedBox(height: 8),
                                          const Text('The temporary file is no longer in memory.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.download, size: 18),
                        tooltip: 'Download',
                        onPressed: () async {
                          final url = Uri.parse(staff.idProofUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not download file. The link may have expired.'), backgroundColor: Colors.red));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                        tooltip: 'Remove',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: const Text('Remove ID Proof?'),
                              content: const Text('Are you sure you want to remove this ID proof?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await ref.read(apiServiceProvider).deleteFile(staff.idProofUrl!);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Warning: Failed to delete file from cloud: $e'), backgroundColor: Colors.orange),
                                        );
                                      }
                                    }
                                    
                                    final updatedStaff = Staff(
                                      id: staff.id,
                                      name: staff.name,
                                      role: staff.role,
                                      shift: staff.shift,
                                      phone: staff.phone,
                                      email: staff.email,
                                      imageUrl: staff.imageUrl,
                                      idProofUrl: '', // Clear the ID proof
                                    );
                                    ref.read(staffProvider.notifier).updateStaff(updatedStaff);
                                    if (context.mounted) {
                                      Navigator.pop(ctx); // Close confirmation
                                      Navigator.pop(context); // Close details dialog
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Proof removed.'), backgroundColor: Colors.green));
                                    }
                                  },
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildStaffInfoItem(BuildContext context, IconData icon, String label, String value) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    ],
  );
}
