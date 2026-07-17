import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredMembersProvider);
    final isListView = ref.watch(isMemberListViewProvider);
    final highlightId = GoRouterState.of(context).uri.queryParameters['highlightId'];
    final action = GoRouterState.of(context).uri.queryParameters['action'];

    if (action == 'add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/members');
        showAddMemberDialog(context, ref);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, isListView),
          const SizedBox(height: 24),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
              data: (members) => members.isEmpty
                ? Center(
                    child: Text(
                      'No members found',
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
                        child: Column(
                          children: [
                            _buildTableHeaders(context),
                            Divider(color: Theme.of(context).dividerColor, height: 1),
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: members.length,
                                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  return _MemberRow(member: member, isHighlighted: member.id == highlightId);
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return _MemberCard(member: member, isHighlighted: member.id == highlightId);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isListView) {
    final statusFilter = ref.watch(filterStatusProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search members by name or email...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: statusFilter,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  icon: Icon(LucideIcons.chevronDown, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 16),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref.read(filterStatusProvider.notifier).updateFilter(newValue);
                    }
                  },
                  items: <String>['All', 'Active', 'Expiring Soon', 'Expired']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
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
                  ref.read(isMemberListViewProvider.notifier).setMode(index == 0);
                },
                borderRadius: BorderRadius.circular(11),
                fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                selectedColor: Theme.of(context).colorScheme.primary,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                children: const [
                  Icon(LucideIcons.list, size: 20),
                  Icon(LucideIcons.layoutGrid, size: 20),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => showAddMemberDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaders(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 48), // Space for Avatar
          Expanded(flex: 3, child: Text('NAME & EMAIL', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('PHONE', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('PLAN', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('STATUS', style: _headerStyle(context))),
          Expanded(flex: 2, child: Text('JOIN DATE', style: _headerStyle(context))),
          const SizedBox(width: 40), // Space for actions
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.1,
    );
  }

}

void showAddMemberDialog(BuildContext context, WidgetRef ref, {Member? memberToEdit}) {
    final nameController = TextEditingController(text: memberToEdit?.name ?? '');
    final emailController = TextEditingController(text: memberToEdit?.email ?? '');
    final phoneController = TextEditingController(text: memberToEdit?.phone ?? '');
    final addressController = TextEditingController(text: memberToEdit?.address ?? '');
    String selectedPlan = memberToEdit?.membershipPlan ?? 'Pro Annual';
    String selectedStatus = memberToEdit?.status ?? 'Active';
    DateTime selectedJoinDate = memberToEdit?.joinDate ?? DateTime.now();
    DateTime selectedExpiryDate = memberToEdit?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
    String? selectedTrainerId = memberToEdit?.trainerId;
    String? imageUrl = memberToEdit?.imageUrl;
    String? documentUrl = memberToEdit?.documentUrl;
    XFile? newImageFile;
    XFile? newDocumentFile;
    bool isUploading = false;
    final TransformationController transformController = TransformationController();
    final TransformationController docTransformController = TransformationController();
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(memberToEdit == null ? 'Add New Member' : 'Edit Member', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: SizedBox(
                width: 600,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  newImageFile = image;
                                  imageUrl = image.path;
                                  transformController.value = Matrix4.identity();
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
                              ),
                              child: ClipOval(
                                child: imageUrl == null
                                    ? Icon(LucideIcons.camera, size: 32, color: Theme.of(context).colorScheme.primary)
                                    : InteractiveViewer(
                                        transformationController: transformController,
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(LucideIcons.imageOff, color: Theme.of(context).colorScheme.error),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(imageUrl == null ? 'Upload Photo' : 'Drag/Pinch to Adjust', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nameController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(LucideIcons.user),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(LucideIcons.mail),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(LucideIcons.phone),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: addressController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(LucideIcons.mapPin),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPlan,
                            decoration: InputDecoration(
                              labelText: 'Membership Plan',
                              prefixIcon: const Icon(LucideIcons.creditCard),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['Basic Monthly', 'Pro Annual', 'Student', 'Gold Plan']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedPlan = val ?? 'Pro Annual'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(LucideIcons.activity),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['Active', 'Expiring Soon', 'Expired']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedStatus = val ?? 'Active'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final trainersAsync = ref.watch(trainersProvider);
                        return trainersAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const Text('Failed to load trainers'),
                          data: (trainers) {
                            return DropdownButtonFormField<String?>(
                              value: selectedTrainerId,
                              decoration: InputDecoration(
                                labelText: 'Assign Trainer (Optional)',
                                prefixIcon: const Icon(LucideIcons.users),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('No Trainer')),
                                ...trainers.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.name))),
                              ],
                              onChanged: (val) => setState(() => selectedTrainerId = val),
                            );
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedJoinDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => selectedJoinDate = date);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Join Date',
                                prefixIcon: const Icon(LucideIcons.calendar),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('${selectedJoinDate.year}-${selectedJoinDate.month.toString().padLeft(2, '0')}-${selectedJoinDate.day.toString().padLeft(2, '0')}'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedExpiryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => selectedExpiryDate = date);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                prefixIcon: const Icon(LucideIcons.calendarClock),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('${selectedExpiryDate.year}-${selectedExpiryDate.month.toString().padLeft(2, '0')}-${selectedExpiryDate.day.toString().padLeft(2, '0')}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Upload Aadhar / ID Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    // ID Document Picker
                    GestureDetector(
                      onTap: () async {
                        final XFile? docImage = await picker.pickImage(source: ImageSource.gallery);
                        if (docImage != null) {
                          setState(() {
                            newDocumentFile = docImage;
                            documentUrl = docImage.path;
                            docTransformController.value = Matrix4.identity();
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: documentUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.fileText, size: 32, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(height: 8),
                                  Text('Click to select file', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: InteractiveViewer(
                                      transformationController: docTransformController,
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 120,
                                        child: Image.network(
                                          documentUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Center(child: Icon(LucideIcons.imageOff, color: Theme.of(context).colorScheme.error)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                isUploading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                      setState(() => isUploading = true);
                      
                      try {
                        final api = ref.read(apiServiceProvider);
                        
                        if (newImageFile != null) {
                          final bytes = await newImageFile!.readAsBytes();
                          final uploadedUrl = await api.uploadFile(bytes, newImageFile!.name);
                          if (uploadedUrl != null) imageUrl = uploadedUrl;
                        }
                        
                        if (newDocumentFile != null) {
                          final bytes = await newDocumentFile!.readAsBytes();
                          final uploadedUrl = await api.uploadFile(bytes, newDocumentFile!.name);
                          if (uploadedUrl != null) documentUrl = uploadedUrl;
                        }
                        
                        final newMember = Member(
                          id: memberToEdit?.id ?? '',
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          membershipPlan: selectedPlan,
                          status: selectedStatus,
                          joinDate: selectedJoinDate,
                          expiryDate: selectedExpiryDate,
                          totalCheckIns: memberToEdit?.totalCheckIns ?? 0,
                          imageUrl: imageUrl,
                          address: addressController.text,
                          documentUrl: documentUrl,
                          trainerId: selectedTrainerId,
                        );
                        final isNew = memberToEdit == null;
                        if (isNew) {
                          await ref.read(membersProvider.notifier).addMember(newMember);
                        } else {
                          await ref.read(membersProvider.notifier).updateMember(newMember);
                        }
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isNew ? 'Member added successfully!' : 'Member updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isUploading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving member: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  child: Text(memberToEdit == null ? 'Save Member' : 'Update Member', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

void showMemberDetailsDialog(BuildContext context, WidgetRef ref, Member member) {
  showDialog(
    context: context,
    builder: (context) {
      final transformController = TransformationController();
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Member Details', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            IconButton(
              icon: Icon(LucideIcons.pencil, size: 20, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                Navigator.pop(context);
                showAddMemberDialog(context, ref, memberToEdit: member);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: GestureDetector(
                  onTap: () => showFullMemberImage(context, member),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                    child: member.imageUrl == null
                        ? Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(context, 'Name', member.name),
              _buildDetailRow(context, 'Email', member.email),
              _buildDetailRow(context, 'Phone', member.phone.isEmpty ? 'N/A' : member.phone),
              _buildDetailRow(context, 'Address', member.address.isEmpty ? 'N/A' : member.address),
              _buildDetailRow(
                context, 
                'Plan', 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(member.membershipPlan, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                )
              ),
              _buildDetailRow(
                context, 
                'Status', 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.status.toLowerCase() == 'active' 
                        ? Colors.green.withOpacity(0.1) 
                        : member.status.toLowerCase() == 'expired' 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: member.status.toLowerCase() == 'active' 
                          ? Colors.green 
                          : member.status.toLowerCase() == 'expired' 
                              ? Colors.red 
                              : Colors.orange,
                    ),
                  ),
                  child: Text(
                    member.status, 
                    style: TextStyle(
                      color: member.status.toLowerCase() == 'active' 
                          ? Colors.green 
                          : member.status.toLowerCase() == 'expired' 
                              ? Colors.red 
                              : Colors.orange,
                      fontSize: 13, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                )
              ),
              Consumer(
                builder: (context, ref, child) {
                  final trainers = ref.read(trainersProvider).value ?? [];
                  final trainerName = member.trainerId != null
                      ? trainers.firstWhere((t) => t.id == member.trainerId, orElse: () => Trainer(id: '', name: 'Unknown', specialization: '', assignedMembers: 0, rating: 0.0)).name
                      : 'None';
                  return _buildDetailRow(context, 'Trainer', trainerName == 'Unknown' && member.trainerId == null ? 'None' : trainerName);
                }
              ),
              _buildDetailRow(context, 'Join Date', DateFormat('MMM d, yyyy').format(member.joinDate)),
              _buildDetailRow(context, 'Expiry Date', DateFormat('MMM d, yyyy').format(member.expiryDate)),
              if (member.documentUrl != null && member.documentUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('ID Document', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: InkWell(
                    onTap: () => showMemberDetailsDialog(context, ref, member),
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      transformationController: transformController,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: Image.network(
                        member.documentUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(child: Icon(LucideIcons.imageOff, color: Theme.of(context).colorScheme.error)),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(BuildContext context, String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: value is Widget 
                ? value 
                : Text(value.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
          ),
        ),
      ],
    ),
  );
}

class _MemberRow extends ConsumerWidget {
  final Member member;
  final bool isHighlighted;

  const _MemberRow({required this.member, this.isHighlighted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showMemberDetailsDialog(context, ref, member),
          hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showFullMemberImage(context, member),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                  child: member.imageUrl == null
                      ? Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                    Text(member.email, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(member.phone, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
              ),
              Expanded(
                flex: 2,
                child: _buildPlanBadge(context, member.membershipPlan),
              ),
              Expanded(
                flex: 2,
                child: _buildStatusBadge(context, member.status),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('MMM dd, yyyy').format(member.joinDate),
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreVertical, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                color: Theme.of(context).colorScheme.surface,
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (val) {
                  if (val == 'edit') {
                    showAddMemberDialog(context, ref, memberToEdit: member);
                  } else if (val == 'delete') {
                    ref.read(membersProvider.notifier).removeMember(member.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPlanBadge(BuildContext context, String plan) {
    Color planColor;
    if (plan.contains('Gold') || plan.contains('Annual')) planColor = Colors.amber;
    else if (plan.contains('Pro')) planColor = Colors.purple;
    else if (plan.contains('Student') || plan.contains('Silver')) planColor = Colors.blueGrey;
    else planColor = Colors.blue;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: planColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: planColor.withOpacity(0.3)),
        ),
        child: Text(plan, style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color statusColor;
    if (status == 'Active') statusColor = Colors.green;
    else if (status == 'Expired') statusColor = Colors.red;
    else statusColor = Colors.orange;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final Member member;
  final bool isHighlighted;

  const _MemberCard({required this.member, this.isHighlighted = false});

  Widget _buildPlanBadge(BuildContext context, String plan) {
    Color planColor;
    if (plan.contains('Gold') || plan.contains('Annual')) planColor = Colors.amber;
    else if (plan.contains('Pro')) planColor = Colors.purple;
    else if (plan.contains('Student') || plan.contains('Silver')) planColor = Colors.blueGrey;
    else planColor = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: planColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: planColor.withOpacity(0.3)),
      ),
      child: Text(plan, style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color statusColor;
    if (status == 'Active') statusColor = Colors.green;
    else if (status == 'Expired') statusColor = Colors.red;
    else statusColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color planColor;
    if (member.membershipPlan.contains('Gold') || member.membershipPlan.contains('Annual')) planColor = Colors.amber;
    else if (member.membershipPlan.contains('Pro')) planColor = Colors.purple;
    else if (member.membershipPlan.contains('Student') || member.membershipPlan.contains('Silver')) planColor = Colors.blueGrey;
    else planColor = Colors.blue;

    return HoverZoomEffect(
      scale: 1.03,
      child: GestureDetector(
        onTap: () => showMemberDetailsDialog(context, ref, member),
        child: Container(
        decoration: BoxDecoration(
          color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Theme.of(context).dividerColor.withOpacity(0.3),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: planColor.withOpacity(0.08),
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
                      planColor.withOpacity(0.15),
                      planColor.withOpacity(0.0),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            Column(
              children: [
                // TOP SECTION
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => showFullMemberImage(context, member),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: planColor.withOpacity(0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: planColor.withOpacity(0.1),
                            backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                            child: member.imageUrl == null
                                ? Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: planColor, fontSize: 28, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        member.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.email,
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlanBadge(context, member.membershipPlan),
                          const SizedBox(width: 8),
                          _buildStatusBadge(context, member.status),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // BOTTOM SECTION
                const Spacer(),
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
                            'Join Date',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(member.joinDate),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ),
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
                              onPressed: () => showAddMemberDialog(context, ref, memberToEdit: member),
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
                              onPressed: () => ref.read(membersProvider.notifier).removeMember(member.id),
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
      ),
    );
  }
}

void showFullMemberImage(BuildContext context, Member member) {
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
            child: CircleAvatar(
              radius: 140,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
              child: member.imageUrl == null
                  ? Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 100, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
}
