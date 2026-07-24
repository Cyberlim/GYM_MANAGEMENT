import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/features/plans/providers/plans_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final membersAsync = ref.watch(filteredMembersProvider);
    final isListViewSetting = ref.watch(isMemberListViewProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isListView = isMobile ? false : isListViewSetting;
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
          Text(
            'Members',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your gym members',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeader(context, ref, isListViewSetting, isMobile),
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
                          mainAxisExtent: 360,
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isListView, bool isMobile) {
    final statusFilter = ref.watch(filterStatusProvider);

    final searchField = TextField(
      autofocus: isMobile,
      controller: _searchController,
      onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search members...',
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
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isMobile)
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: IconButton(
                  icon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: Text('Search Members', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        content: SizedBox(width: 300, child: searchField),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          )
                        ],
                      )
                    );
                  },
                ),
              )
            else
              SizedBox(
                width: 300,
                child: searchField,
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
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
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!isMobile)
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
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => showAddMemberDialog(context, ref),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
    DateTime? selectedDob = memberToEdit?.dob;
    String? selectedTrainerId = memberToEdit?.trainerId;
    String? imageUrl = memberToEdit?.imageUrl;
    String? documentUrl = memberToEdit?.documentUrl;
    XFile? newImageFile;
    XFile? newDocumentFile;
    bool isUploading = false;
    bool isUploadingDoc = false;
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 450;
                      
                      Widget buildResponsiveRow(Widget child1, Widget child2) {
                        if (isMobile) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              child1,
                              const SizedBox(height: 16),
                              child2,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: child1),
                            const SizedBox(width: 16),
                            Expanded(child: child2),
                          ],
                        );
                      }

                      return Column(
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
                    buildResponsiveRow(
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(LucideIcons.user),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      TextFormField(
                        controller: emailController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(LucideIcons.mail),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildResponsiveRow(
                      TextFormField(
                        controller: phoneController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(LucideIcons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      InkWell(
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
                          decoration: InputDecoration(
                            labelText: 'Date of Birth (Required)',
                            prefixIcon: const Icon(LucideIcons.calendarDays),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(selectedDob != null ? '${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}' : 'Select Date', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(LucideIcons.mapPin),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildResponsiveRow(
                      Consumer(
                        builder: (context, ref, child) {
                          final plansAsync = ref.watch(plansProvider);
                          return plansAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const Text('Failed to load plans'),
                            data: (plans) {
                              final planNames = plans.map((p) => p.name).toList();
                              // Ensure the selected plan is in the list to avoid assertion errors
                              if (selectedPlan.isNotEmpty && !planNames.contains(selectedPlan)) {
                                planNames.add(selectedPlan);
                              }
                              
                              return DropdownButtonFormField<String>(
                                value: selectedPlan.isEmpty && planNames.isNotEmpty ? planNames.first : (selectedPlan.isEmpty ? null : selectedPlan),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Membership Plan',
                                  prefixIcon: const Icon(LucideIcons.creditCard),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: planNames
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) => setState(() => selectedPlan = val ?? ''),
                              );
                            },
                          );
                        }
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(LucideIcons.activity),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ['Active', 'Expiring Soon', 'Expired']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedStatus = val ?? 'Active'),
                      ),
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
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Assign Trainer (Optional)',
                                prefixIcon: const Icon(LucideIcons.users),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('No Trainer', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ...trainers.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => selectedTrainerId = val),
                            );
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    buildResponsiveRow(
                      InkWell(
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
                          child: Text('${selectedJoinDate.year}-${selectedJoinDate.month.toString().padLeft(2, '0')}-${selectedJoinDate.day.toString().padLeft(2, '0')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      InkWell(
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
                          child: Text('${selectedExpiryDate.year}-${selectedExpiryDate.month.toString().padLeft(2, '0')}-${selectedExpiryDate.day.toString().padLeft(2, '0')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ID Document Uploader
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID Document', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        TextButton.icon(
                          onPressed: () async {
                            final XFile? doc = await picker.pickImage(source: ImageSource.gallery);
                            if (doc != null) {
                              setState(() => isUploadingDoc = true);
                              try {
                                setState(() {
                                  newDocumentFile = doc;
                                  documentUrl = doc.path;
                                  docTransformController.value = Matrix4.identity();
                                });
                              } finally {
                                setState(() => isUploadingDoc = false);
                              }
                            }
                          },
                          icon: isUploadingDoc 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(LucideIcons.upload, size: 16, color: Theme.of(context).colorScheme.primary),
                          label: Text(isUploadingDoc ? 'Uploading...' : 'Upload', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (documentUrl == null)
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
                                  documentUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.imageOff)),
                                ),
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('ID Document', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                                          minScale: 1.0, maxScale: 5.0,
                                          child: Image.network(documentUrl!, fit: BoxFit.contain),
                                        ),
                                        Positioned(
                                          top: 16, right: 16,
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
                            if (newDocumentFile == null && documentUrl!.startsWith('http'))
                              IconButton(
                                icon: const Icon(LucideIcons.download, size: 18),
                                tooltip: 'Download',
                                onPressed: () async {
                                  final url = Uri.parse(documentUrl!);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () => setState(() {
                                documentUrl = null;
                                newDocumentFile = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
                },
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
                    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && selectedDob != null) {
                      setState(() => isUploading = true);
                      
                      try {
                        final api = ref.read(apiServiceProvider);
                        
                        if (newImageFile != null) {
                          final bytes = await newImageFile!.readAsBytes();
                          final uploadedUrl = await api.uploadFile(bytes, newImageFile!.name);
                          if (uploadedUrl != null) {
                            // Delete old image if updating
                            if (memberToEdit != null && memberToEdit.imageUrl != null && memberToEdit.imageUrl!.startsWith('http') && !memberToEdit.imageUrl!.contains('unsplash.com')) {
                              try { await api.deleteFile(memberToEdit.imageUrl!); } catch (e) { debugPrint('Failed to delete old image: $e'); }
                            }
                            imageUrl = uploadedUrl;
                          }
                        }
                        
                        if (newDocumentFile != null) {
                          final bytes = await newDocumentFile!.readAsBytes();
                          final uploadedUrl = await api.uploadFile(bytes, newDocumentFile!.name);
                          if (uploadedUrl != null) {
                            // Delete old document if updating
                            if (memberToEdit != null && memberToEdit.documentUrl != null && memberToEdit.documentUrl!.startsWith('http')) {
                              try { await api.deleteFile(memberToEdit.documentUrl!); } catch (e) { debugPrint('Failed to delete old document: $e'); }
                            }
                            documentUrl = uploadedUrl;
                          }
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
                          dob: selectedDob,
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields including Date of Birth.'), backgroundColor: Colors.orange),
                      );
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
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with edit icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Member Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    IconButton(
                      icon: const Icon(LucideIcons.edit3, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        showAddMemberDialog(context, ref, memberToEdit: member);
                      },
                      tooltip: 'Edit Member',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Profile Image
                GestureDetector(
                  onTap: () => showFullMemberImage(context, member),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty ? NetworkImage(member.imageUrl!) : null,
                    child: member.imageUrl == null || member.imageUrl!.isEmpty
                        ? Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(member.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                // Info grid
                Row(
                  children: [
                    Expanded(child: _buildMemberInfoItem(context, LucideIcons.mail, 'Email', Text(member.email, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMemberInfoItem(context, LucideIcons.phone, 'Phone', Text(member.phone.isEmpty ? 'N/A' : member.phone, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildMemberInfoItem(
                      context, 
                      LucideIcons.calendarDays, 
                      'Date of Birth', 
                      Text(member.dob != null ? DateFormat('MMM d, yyyy').format(member.dob!) : 'N/A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMemberInfoItem(context, LucideIcons.mapPin, 'Address', Text(member.address.isEmpty ? 'N/A' : member.address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Consumer(
                      builder: (context, ref, child) {
                        final trainers = ref.read(trainersProvider).value ?? [];
                        final trainerName = member.trainerId != null
                            ? trainers.firstWhere((t) => t.id == member.trainerId, orElse: () => Trainer(id: '', name: 'Unknown', specialization: '', assignedMembers: 0, rating: 0.0)).name
                            : 'None';
                        return _buildMemberInfoItem(context, LucideIcons.user, 'Trainer', Text(trainerName == 'Unknown' && member.trainerId == null ? 'None' : trainerName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)));
                      }
                    )),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildMemberInfoItem(
                      context, 
                      LucideIcons.creditCard, 
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
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMemberInfoItem(
                      context, 
                      LucideIcons.activity, 
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
                    )),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildMemberInfoItem(context, LucideIcons.calendar, 'Join Date', Text(DateFormat('MMM d, yyyy').format(member.joinDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMemberInfoItem(context, LucideIcons.calendarClock, 'Expiry Date', Text(DateFormat('MMM d, yyyy').format(member.expiryDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)))),
                  ],
                ),
                if (member.documentUrl != null && member.documentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ID Document', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              member.documentUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.imageOff)),
                            ),
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('ID Document', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                                      minScale: 1.0, maxScale: 5.0,
                                      child: Image.network(member.documentUrl!, fit: BoxFit.contain),
                                    ),
                                    Positioned(
                                      top: 16, right: 16,
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
                        if (member.documentUrl!.startsWith('http'))
                          IconButton(
                            icon: const Icon(LucideIcons.download, size: 18),
                            tooltip: 'Download',
                            onPressed: () async {
                              final url = Uri.parse(member.documentUrl!);
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
                                title: const Text('Remove ID Document?'),
                                content: const Text('Are you sure you want to remove this ID document?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref.read(apiServiceProvider).deleteFile(member.documentUrl!);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Warning: Failed to delete file from cloud: $e'), backgroundColor: Colors.orange),
                                          );
                                        }
                                      }

                                      final updatedMember = Member(
                                        id: member.id,
                                        name: member.name,
                                        email: member.email,
                                        phone: member.phone,
                                        membershipPlan: member.membershipPlan,
                                        status: member.status,
                                        joinDate: member.joinDate,
                                        expiryDate: member.expiryDate,
                                        totalCheckIns: member.totalCheckIns,
                                        imageUrl: member.imageUrl,
                                        address: member.address,
                                        trainerId: member.trainerId,
                                        documentUrl: '', // Clear the document
                                      );
                                      ref.read(membersProvider.notifier).updateMember(updatedMember);
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
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
        ),
      );
    },
  );
}

Widget _buildMemberInfoItem(BuildContext context, IconData icon, String label, Widget valueWidget) {
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
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            valueWidget,
          ],
        ),
      ),
    ],
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
                  backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty ? NetworkImage(member.imageUrl!) : null,
                  child: member.imageUrl == null || member.imageUrl!.isEmpty
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
                            backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty ? NetworkImage(member.imageUrl!) : null,
                            child: member.imageUrl == null || member.imageUrl!.isEmpty
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.email,
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildPlanBadge(context, member.membershipPlan),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Date',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(member.joinDate),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
              backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty ? NetworkImage(member.imageUrl!) : null,
              child: member.imageUrl == null || member.imageUrl!.isEmpty
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
