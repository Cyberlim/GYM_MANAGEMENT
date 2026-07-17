import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/trainers/trainers_page.dart';
import 'package:go_router/go_router.dart';

class TrainerDetailsPage extends ConsumerWidget {
  final String trainerId;
  const TrainerDetailsPage({super.key, required this.trainerId});

  void _showFullImage(BuildContext context, dynamic trainer) {
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
    final trainersAsync = ref.watch(trainersProvider);
    final membersAsync = ref.watch(membersProvider);

    return trainersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      data: (trainers) {
        if (trainers.isEmpty) {
          return const Center(child: Text('No trainers found.'));
        }
        final trainer = trainers.firstWhere(
          (t) => t.id == trainerId,
          orElse: () => trainers.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Back Button
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 24, bottom: 16),
          child: TextButton.icon(
            onPressed: () => context.pop(),
            icon: Icon(LucideIcons.arrowLeft, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            label: Text('Back to Trainers', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
        ),
        
        // Profile Header Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Huge Profile Picture
                GestureDetector(
                  onTap: () => _showFullImage(context, trainer),
                  child: Container(
                    width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: trainer.imageUrl != null 
                        ? DecorationImage(image: NetworkImage(trainer.imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: trainer.imageUrl == null
                      ? Center(
                          child: Text(
                            trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 60, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                ),
                const SizedBox(width: 32),
                
                // Trainer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trainer.name,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  showTrainerDialog(context, ref, trainerToEdit: trainer);
                                },
                                icon: const Icon(LucideIcons.edit3, size: 16),
                                label: const Text('Edit Profile'),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trainer.specialization,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(LucideIcons.mail, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Text(trainer.email.isNotEmpty ? trainer.email : 'No email provided', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(width: 24),
                          Icon(LucideIcons.phone, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Text(trainer.phone.isNotEmpty ? trainer.phone : 'No phone provided', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Row(
                        children: [
                          _buildStatColumn(context, 'Rating', '${trainer.rating} / 5.0', LucideIcons.star, Colors.amber),
                          const SizedBox(width: 48),
                          _buildStatColumn(context, 'Assigned Members', '${trainer.assignedMembers}', LucideIcons.users, Colors.blue),
                          const SizedBox(width: 48),
                          _buildStatColumn(context, 'Experience', '${trainer.experienceYears} Years', LucideIcons.award, Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // About Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About ${trainer.name.split(' ')[0]}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 16),
                Text(
                  trainer.about.isNotEmpty ? trainer.about : 'No biography provided.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                Text('Certifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12),
                trainer.certificates.isEmpty
                    ? Text('No certificates uploaded.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: trainer.certificates.map((cert) => Container(
                          width: 120,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                            image: DecorationImage(
                              image: NetworkImage(cert),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )).toList(),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Assigned Members Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 16),
                membersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error loading members: $err'),
                  data: (members) {
                    final assignedMembers = members.where((m) => m.trainerId == trainerId).toList();
                    if (assignedMembers.isEmpty) {
                      return Text('No members assigned.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignedMembers.length,
                      separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor),
                      itemBuilder: (context, index) {
                        final member = assignedMembers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: member.imageUrl == null ? Icon(LucideIcons.user, color: Theme.of(context).colorScheme.primary) : null,
                          ),
                          title: Text(member.name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(member.membershipPlan, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (member.phone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(LucideIcons.phone, size: 18),
                                  onPressed: () {},
                                  tooltip: member.phone,
                                ),
                              IconButton(
                                icon: const Icon(LucideIcons.mail, size: 18),
                                onPressed: () {},
                                tooltip: member.email,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
      },
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ],
    );
  }

}
