import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/superadmin_provider.dart';

class PersonDetailsPage extends ConsumerWidget {
  final String gymId;
  final String personId;
  final String role;

  const PersonDetailsPage({
    super.key,
    required this.gymId,
    required this.personId,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decodedGymName = Uri.decodeComponent(gymId);
    final fallbackName = Uri.decodeComponent(GoRouterState.of(context).uri.queryParameters['name'] ?? personId);
    
    final personDetailsAsync = ref.watch(superadminPersonDetailsProvider('$role:$personId'));

    return personDetailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
      data: (person) {
        final isStaff = role != 'Member';
        final status = person['status'] ?? 'Active';
        final statusBg = status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
        final statusText = status == 'Active' ? Colors.green : Colors.red;
        
        final name = person['name'] ?? fallbackName;
        final email = person['email'] ?? 'N/A';
        final phone = person['phone'] ?? 'N/A';
        final address = person['address'] ?? 'N/A';
        final joinDate = person['joinDate'] != null ? DateTime.tryParse(person['joinDate']) : null;
        final joinDateStr = joinDate != null ? '${_getMonth(joinDate.month)} ${joinDate.day}, ${joinDate.year}' : 'Unknown';
        
        final membershipPlan = person['membershipPlan'] ?? 'N/A';
        final totalVisits = person['totalCheckIns']?.toString() ?? '0';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.arrowLeft),
                    onPressed: () => context.go('/gyms/${Uri.encodeComponent(decodedGymName)}'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$role Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        final imageUrl = person['imageUrl'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(imageUrl, fit: BoxFit.contain),
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
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 3),
                        ),
                        child: person['imageUrl'] != null && person['imageUrl'].isNotEmpty
                          ? ClipOval(child: Image.network(person['imageUrl'], fit: BoxFit.cover))
                          : Icon(LucideIcons.user, size: 48, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.mail, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(email, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(width: 24),
                              Icon(LucideIcons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(phone, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                                child: Text(status, style: TextStyle(color: statusText, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 24),

          // Lower Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 24),
                          _buildInfoRow(LucideIcons.calendar, 'Joined', joinDateStr),
                          const Divider(height: 32),
                          _buildInfoRow(LucideIcons.mapPin, 'Address', address),
                          const Divider(height: 32),
                          if (!isStaff) ...[
                            _buildInfoRow(LucideIcons.creditCard, 'Membership Plan', membershipPlan),
                            const Divider(height: 32),
                            _buildInfoRow(LucideIcons.activity, 'Total Visits', totalVisits),
                          ] else ...[
                            _buildInfoRow(LucideIcons.clock, 'Shift Hours', 'Morning (6AM - 2PM)'),
                            const Divider(height: 32),
                            _buildInfoRow(LucideIcons.award, 'Specialty', 'Strength & Conditioning'),
                          ],
                        ],
                      ),
                    ),
                    if (person['documentUrl'] != null && person['documentUrl'].toString().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  scaleEnabled: true,
                                  child: Image.network(
                                    person['documentUrl'],
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
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Activity Feed
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 24),
                      if (isStaff) ...[
                        _buildActivityItem('Taught HIIT Class', 'Today, 8:00 AM', LucideIcons.activity),
                        _buildActivityItem('Clocked In', 'Today, 6:00 AM', LucideIcons.clock),
                        _buildActivityItem('Added new training program', 'Yesterday', LucideIcons.fileText),
                        _buildActivityItem('Completed safety certification', 'Last Week', LucideIcons.checkCircle),
                      ] else ...[
                        _buildActivityItem('Gym Check-in', 'Today, 5:30 PM', LucideIcons.logIn),
                        _buildActivityItem('Attended Yoga Class', 'Yesterday', LucideIcons.activity),
                        _buildActivityItem('Purchased Protein Shake', 'Sept 20, 2024', LucideIcons.shoppingCart),
                        _buildActivityItem('Membership Renewed', 'Sept 1, 2024', LucideIcons.creditCard),
                      ]
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
      },
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildActivityItem(String activity, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
