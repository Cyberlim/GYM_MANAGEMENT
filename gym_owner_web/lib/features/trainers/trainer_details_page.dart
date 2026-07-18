import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/features/trainers/providers/trainers_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/trainers/trainers_page.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
class TrainerDetailsPage extends ConsumerWidget {
  final String trainerId;
  const TrainerDetailsPage({super.key, required this.trainerId});

  void _showDocumentPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

        final isMobile = MediaQuery.of(context).size.width < 800;

        return SingleChildScrollView(
          child: Column(
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
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
                SizedBox(width: 32, height: 24),
                
                // Trainer Details
                Builder(builder: (context) {
                  final details = Column(
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: isMobile ? WrapAlignment.center : WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          Text(
                            trainer.name,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            textAlign: isMobile ? TextAlign.center : TextAlign.left,
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showTrainerDialog(context, ref, trainerToEdit: trainer);
                            },
                            icon: const Icon(LucideIcons.edit3, size: 16),
                            label: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      Wrap(
                        alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.mail, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 8),
                              Text(trainer.email.isNotEmpty ? trainer.email : 'No email provided', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.phone, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 8),
                              Text(trainer.phone.isNotEmpty ? trainer.phone : 'No phone provided', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Wrap(
                        alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                        spacing: 32,
                        runSpacing: 24,
                        children: [
                          _buildStatColumn(context, 'Rating', '${trainer.rating} / 5.0', LucideIcons.star, Colors.amber),
                          _buildStatColumn(context, 'Assigned Members', '${trainer.assignedMembers}', LucideIcons.users, Colors.blue),
                          _buildStatColumn(context, 'Experience', '${trainer.experienceYears} Years', LucideIcons.award, Colors.purple),
                        ],
                      ),
                    ],
                  );

                  return isMobile ? details : Expanded(child: details);
                }),
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
                        spacing: 16,
                        runSpacing: 16,
                        children: trainer.certificates.map((cert) {
                          return Container(
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(cert),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text('Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Tooltip(
                                      message: 'Preview',
                                      child: InkWell(
                                        onTap: () => _showDocumentPreview(context, cert),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(LucideIcons.eye, size: 18, color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Download',
                                      child: InkWell(
                                        onTap: () async {
                                          final url = Uri.parse(cert);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(LucideIcons.download, size: 18, color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
    ));
      },
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
