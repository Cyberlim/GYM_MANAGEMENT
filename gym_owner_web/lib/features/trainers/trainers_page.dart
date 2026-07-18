import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class TrainersPage extends ConsumerWidget {
  const TrainersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainersAsync = ref.watch(filteredTrainersProvider);
    final isListView = ref.watch(isTrainerListViewProvider);
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
          _buildHeader(context, ref, isListView),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isListView) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
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
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
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
            ElevatedButton.icon(
              onPressed: () => showTrainerDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Trainer'),
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
  final ImagePicker picker = ImagePicker();

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
                          setState(() {
                            pickedImagePath = image.path;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        backgroundImage: pickedImagePath != null ? NetworkImage(pickedImagePath!) : null,
                        child: pickedImagePath == null 
                            ? Icon(LucideIcons.camera, color: Theme.of(context).colorScheme.primary)
                            : null,
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
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: 'Email Address'),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Certificates', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...pickedCertificates.map((cert) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: NetworkImage(cert), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => pickedCertificates.remove(cert)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                        GestureDetector(
                          onTap: () async {
                            final XFile? cert = await picker.pickImage(source: ImageSource.gallery);
                            if (cert != null) {
                              setState(() => pickedCertificates.add(cert.path));
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.upload, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ),
                      ],
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
                    child: trainer.imageUrl != null
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
                            backgroundImage: trainer.imageUrl != null ? NetworkImage(trainer.imageUrl!) : null,
                            child: trainer.imageUrl == null
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
        onTap: () => context.push('/trainer-details/${trainer.id}'),
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
                      backgroundImage: trainer.imageUrl != null ? NetworkImage(trainer.imageUrl!) : null,
                      child: trainer.imageUrl == null
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
