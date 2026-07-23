import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
class TrainersPage extends ConsumerWidget {
  const TrainersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainersAsync = ref.watch(filteredTrainersProvider);
    final isListViewSetting = ref.watch(isTrainerListViewProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isListView = isMobile ? false : isListViewSetting;
    final action = GoRouterState.of(context).uri.queryParameters['action'];

    if (action == 'add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/trainers');
        showTrainerDialog(context, ref);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trainers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your gym trainers',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeader(context, ref, isListViewSetting, isMobile),
          const SizedBox(height: 24),
          Expanded(
            child: trainersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
              data: (trainers) => trainers.isEmpty
                ? Center(
                    child: Text(
                      'No trainers found',
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
                                        itemCount: trainers.length,
                                        separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                                        itemBuilder: (context, index) {
                                          return _TrainerTableRow(trainer: trainers[index]);
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
                          mainAxisExtent: 320,
                        ),
                        itemCount: trainers.length,
                        itemBuilder: (context, index) {
                          return _TrainerCard(trainer: trainers[index]);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('NAME', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('SPECIALIZATION', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('EXPERIENCE & RATING', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('CONTACT', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isListView, bool isMobile) {
    final searchField = TextField(
      onChanged: (value) => ref.read(trainerSearchQueryProvider.notifier).updateQuery(value),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search trainers...',
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
                ref.read(isTrainerListViewProvider.notifier).setMode(index == 0);
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
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => showTrainerDialog(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Trainer'),
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
}

void showTrainerDialog(BuildContext context, WidgetRef ref, {Trainer? trainerToEdit}) {
  final nameController = TextEditingController(text: trainerToEdit?.name ?? '');
  final specController = TextEditingController(text: trainerToEdit?.specialization ?? '');
  final emailController = TextEditingController(text: trainerToEdit?.email ?? '');
  final phoneController = TextEditingController(text: trainerToEdit?.phone ?? '');
  final experienceController = TextEditingController(text: trainerToEdit?.experienceYears.toString() ?? '');
  final aboutController = TextEditingController(text: trainerToEdit?.about ?? '');
  double rating = trainerToEdit?.rating ?? 5.0;
  String? pickedImagePath = trainerToEdit?.imageUrl;
  List<String> pickedCertificates = List.from(trainerToEdit?.certificates ?? []);
  DateTime? selectedDob = trainerToEdit?.dob;
  final ImagePicker picker = ImagePicker();
  bool isUploadingProfile = false;
  bool isUploadingCert = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(trainerToEdit == null ? 'Add New Trainer' : 'Edit Trainer', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: SizedBox(
              width: 400,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            backgroundImage: pickedImagePath != null ? NetworkImage(pickedImagePath!) : null,
                            child: pickedImagePath == null 
                                ? Icon(LucideIcons.camera, color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                          if (isUploadingProfile)
                            const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Upload Photo', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Specialization (e.g. Yoga, Crossfit)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: const InputDecoration(labelText: 'Email Address'),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: experienceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: const InputDecoration(labelText: 'Years Experience'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aboutController,
                      maxLines: 3,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'About / Biography', alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    // Certificates Uploader
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Certificates', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        TextButton.icon(
                          onPressed: () async {
                            final XFile? cert = await picker.pickImage(source: ImageSource.gallery);
                            if (cert != null) {
                              setState(() => isUploadingCert = true);
                              try {
                                final bytes = await cert.readAsBytes();
                                final url = await ref.read(apiServiceProvider).uploadFile(bytes, cert.name);
                                if (url != null) {
                                  setState(() => pickedCertificates.add(url));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
                              } finally {
                                setState(() => isUploadingCert = false);
                              }
                            }
                          },
                          icon: isUploadingCert 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(LucideIcons.upload, size: 16, color: Theme.of(context).colorScheme.primary),
                          label: Text(isUploadingCert ? 'Uploading...' : 'Upload', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (pickedCertificates.isEmpty)
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
                      Column(
                        children: pickedCertificates.map((cert) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
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
                                    image: DecorationImage(image: NetworkImage(cert), fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Certificate', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                                              child: Image.network(cert, fit: BoxFit.contain),
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
                                IconButton(
                                  icon: const Icon(LucideIcons.download, size: 18),
                                  tooltip: 'Download',
                                  onPressed: () async {
                                    final url = Uri.parse(cert);
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
                                        title: const Text('Remove Certificate?'),
                                        content: const Text('Are you sure you want to remove this certificate?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                await ref.read(apiServiceProvider).deleteFile(cert);
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Warning: Failed to delete file from cloud: $e'), backgroundColor: Colors.orange),
                                                  );
                                                }
                                              }
                                              setState(() => pickedCertificates.remove(cert));
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
                        )).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Initial Rating:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        Expanded(
                          child: Slider(
                            value: rating,
                            min: 1,
                            max: 5,
                            divisions: 40,
                            label: rating.toStringAsFixed(1),
                            onChanged: (val) => setState(() => rating = val),
                          ),
                        ),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    )
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
                    if (nameController.text.isNotEmpty && specController.text.isNotEmpty) {
                      final newTrainer = Trainer(
                        id: trainerToEdit?.id ?? '',
                        name: nameController.text,
                        specialization: specController.text,
                        assignedMembers: trainerToEdit?.assignedMembers ?? 0,
                        rating: rating,
                        dob: selectedDob,
                        imageUrl: pickedImagePath,
                        email: emailController.text,
                        phone: phoneController.text,
                        experienceYears: int.tryParse(experienceController.text) ?? 0,
                        about: aboutController.text,
                        certificates: pickedCertificates,
                      );
                      final isNew = trainerToEdit == null;
                      if (isNew) {
                        ref.read(trainersProvider.notifier).addTrainer(newTrainer);
                      } else {
                        ref.read(trainersProvider.notifier).updateTrainer(newTrainer);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNew ? 'Trainer added successfully!' : 'Trainer updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  child: Text(trainerToEdit == null ? 'Save Trainer' : 'Update Trainer', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

Color _getSpecializationColor(String specialization) {
  final lSpec = specialization.toLowerCase();
  if (lSpec.contains('yoga') || lSpec.contains('pilates') || lSpec.contains('flexibility')) return Colors.purple;
  if (lSpec.contains('cardio') || lSpec.contains('endurance') || lSpec.contains('hiit')) return Colors.orange;
  if (lSpec.contains('strength') || lSpec.contains('bodybuilding') || lSpec.contains('weights')) return Colors.red;
  if (lSpec.contains('crossfit') || lSpec.contains('functional')) return Colors.blue;
  if (lSpec.contains('nutrition') || lSpec.contains('diet')) return Colors.green;
  return Colors.teal;
}

class _TrainerCard extends ConsumerWidget {
  final Trainer trainer;

  const _TrainerCard({required this.trainer});

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
                    child: trainer.imageUrl != null && trainer.imageUrl!.isNotEmpty
                        ? Image.network(trainer.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Center(
                              child: Text(
                                trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specColor = _getSpecializationColor(trainer.specialization);

    return HoverZoomEffect(
      scale: 1.03,
      child: InkWell(
        onTap: () => showTrainerDetailsDialog(context, ref, trainer),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: specColor.withOpacity(0.08),
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
                      specColor.withOpacity(0.15),
                      specColor.withOpacity(0.0),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            Column(
              children: [
                // Top Section (Rating)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            trainer.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Profile Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showFullImage(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: specColor.withOpacity(0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: specColor.withOpacity(0.1),
                            backgroundImage: trainer.imageUrl != null && trainer.imageUrl!.isNotEmpty ? NetworkImage(trainer.imageUrl!) : null,
                            child: trainer.imageUrl == null || trainer.imageUrl!.isEmpty
                                ? Text(
                                    trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: specColor, fontSize: 28, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        trainer.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: specColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: specColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          trainer.specialization,
                          style: TextStyle(
                            fontSize: 12,
                            color: specColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Members',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${trainer.assignedMembers}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
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
                              onPressed: () => showTrainerDialog(context, ref, trainerToEdit: trainer),
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
                              onPressed: () => ref.read(trainersProvider.notifier).removeTrainer(trainer.id),
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

class _TrainerTableRow extends ConsumerWidget {
  final Trainer trainer;

  const _TrainerTableRow({required this.trainer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HoverZoomEffect(
      scale: 1.01,
      child: InkWell(
        onTap: () => showTrainerDetailsDialog(context, ref, trainer),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // NAME & AVATAR
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: trainer.imageUrl != null && trainer.imageUrl!.isNotEmpty ? NetworkImage(trainer.imageUrl!) : null,
                      child: trainer.imageUrl == null || trainer.imageUrl!.isEmpty
                          ? Text(
                              trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          trainer.name,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              
              // SPECIALIZATION
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSpecializationColor(trainer.specialization).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getSpecializationColor(trainer.specialization).withOpacity(0.2)),
                    ),
                    child: Text(
                      trainer.specialization,
                      style: TextStyle(
                        fontSize: 12, 
                        color: _getSpecializationColor(trainer.specialization),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // EXPERIENCE & RATING
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trainer.experienceYears} Years Exp.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(trainer.rating.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // CONTACT & ACTIONS
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trainer.phone.isNotEmpty)
                            Text(trainer.phone, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (trainer.email.isNotEmpty)
                            Text(trainer.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => showTrainerDialog(context, ref, trainerToEdit: trainer),
                          icon: const Icon(LucideIcons.edit2, size: 18),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          onPressed: () => ref.read(trainersProvider.notifier).removeTrainer(trainer.id),
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showTrainerDetailsDialog(BuildContext context, WidgetRef ref, Trainer trainer) {
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
                  Text('Trainer Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      showTrainerDialog(context, ref, trainerToEdit: trainer);
                    },
                    tooltip: 'Edit Trainer',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Profile Image
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: trainer.imageUrl != null && trainer.imageUrl!.isNotEmpty ? NetworkImage(trainer.imageUrl!) : null,
                child: trainer.imageUrl == null || trainer.imageUrl!.isEmpty
                    ? Icon(LucideIcons.user, size: 40, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(trainer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(trainer.email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 32),
              
              // Info grid
              Row(
                children: [
                  Expanded(child: _buildTrainerInfoItem(context, LucideIcons.phone, 'Phone', trainer.phone)),
                  Expanded(child: _buildTrainerInfoItem(context, LucideIcons.star, 'Rating', '${trainer.rating}')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildTrainerInfoItem(context, LucideIcons.award, 'Specialization', trainer.specialization)),
                  Expanded(child: _buildTrainerInfoItem(context, LucideIcons.clock, 'Experience', '${trainer.experienceYears} Years')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildTrainerInfoItem(context, LucideIcons.calendarDays, 'Date of Birth', trainer.dob != null ? DateFormat('MMM d, yyyy').format(trainer.dob!) : 'N/A')),
                  const Expanded(child: SizedBox()),
                ],
              ),
              if (trainer.certificates.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Certificates', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                ),
                const SizedBox(height: 12),
                Column(
                  children: trainer.certificates.map((certUrl) {
                    if (certUrl.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
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
                              child: Text('Certificate', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                                          child: Image.network(
                                            certUrl,
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
                            IconButton(
                              icon: const Icon(LucideIcons.download, size: 18),
                              tooltip: 'Download',
                              onPressed: () async {
                                final url = Uri.parse(certUrl);
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
                                    title: const Text('Remove Certificate?'),
                                    content: const Text('Are you sure you want to remove this certificate?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await ref.read(apiServiceProvider).deleteFile(certUrl);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Warning: Failed to delete file from cloud: $e'), backgroundColor: Colors.orange),
                                              );
                                            }
                                          }
                                          
                                          final updatedCertificates = List<String>.from(trainer.certificates)..remove(certUrl);
                                          final updatedTrainer = Trainer(
                                            id: trainer.id,
                                            name: trainer.name,
                                            specialization: trainer.specialization,
                                            assignedMembers: trainer.assignedMembers,
                                            rating: trainer.rating,
                                            imageUrl: trainer.imageUrl,
                                            email: trainer.email,
                                            phone: trainer.phone,
                                            experienceYears: trainer.experienceYears,
                                            about: trainer.about,
                                            certificates: updatedCertificates,
                                          );
                                          ref.read(trainersProvider.notifier).updateTrainer(updatedTrainer);
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate removed.'), backgroundColor: Colors.green));
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
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildTrainerInfoItem(BuildContext context, IconData icon, String label, String value) {
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
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}
