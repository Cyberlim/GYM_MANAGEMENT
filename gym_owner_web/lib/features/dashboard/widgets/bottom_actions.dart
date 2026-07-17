import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:go_router/go_router.dart';

class BottomActionsRow extends StatelessWidget {
  const BottomActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildActionButton(
            context: context,
            icon: LucideIcons.userPlus,
            label: 'Add Member',
            color: Colors.purple,
            route: '/members?action=add',
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context: context,
            icon: LucideIcons.checkSquare,
            label: 'Mark Attendance',
            color: Colors.green,
            route: '/attendance',
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context: context,
            icon: LucideIcons.banknote,
            label: 'Collect Payment',
            color: Colors.orange,
            route: '/payments',
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context: context,
            icon: LucideIcons.userPlus,
            label: 'Add Trainer',
            color: Colors.blue,
            route: '/trainers?action=add',
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context: context,
            icon: LucideIcons.calendarPlus,
            label: 'Create Plan',
            color: Colors.purple,
            route: '/plans?action=add',
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context: context,
            icon: LucideIcons.bellRing,
            label: 'Send Notification',
            color: Colors.orange,
            route: '/notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return HoverZoomEffect(
      scale: 1.05,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
