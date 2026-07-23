import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import '../../../core/providers/dashboard_provider.dart';

class StatCardData {
  final String title;
  final String value;
  final String percentage;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color trendColor;

  const StatCardData({
    required this.title,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.trendColor,
  });
}

class StatCardsRow extends StatelessWidget {
  final DashboardData data;
  
  const StatCardsRow({super.key, required this.data});

  List<StatCardData> _buildStatCards() {
    return [
      StatCardData(
        title: 'Total Members',
        value: data.totalMembers.toString(),
        percentage: 'Current total',
        icon: LucideIcons.users,
        iconColor: Colors.purple,
        iconBgColor: Colors.purple.shade50,
        trendColor: Colors.grey,
      ),
      StatCardData(
        title: 'Active Members',
        value: data.activeMembers.toString(),
        percentage: 'Currently active',
        icon: LucideIcons.dumbbell,
        iconColor: Colors.green,
        iconBgColor: Colors.green.shade50,
        trendColor: Colors.grey,
      ),
      StatCardData(
        title: 'Trainers',
        value: data.totalTrainers.toString(),
        percentage: 'Total staff',
        icon: LucideIcons.userPlus,
        iconColor: Colors.orange,
        iconBgColor: Colors.orange.shade50,
        trendColor: Colors.grey,
      ),
      StatCardData(
        title: 'Monthly Revenue',
        value: '₹${data.monthlyRevenue.toStringAsFixed(0)}',
        percentage: 'This month',
        icon: LucideIcons.dollarSign,
        iconColor: Colors.green.shade700,
        iconBgColor: Colors.green.shade50,
        trendColor: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final statCards = _buildStatCards();
        int crossAxisCount;
        if (constraints.maxWidth < 320) {
          crossAxisCount = 1; // Only 1 column for extremely small screens
        } else if (constraints.maxWidth < 800) {
          crossAxisCount = 2; // Pair (2 columns) for mobile and small tablets
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = statCards.length;
        }

        final double spacing = 16.0;
        final double availableWidth = constraints.maxWidth - (spacing * (crossAxisCount - 1));
        // Subtract a tiny amount to prevent precision issues causing early wrapping
        final double itemWidth = (availableWidth / crossAxisCount) - 0.1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: statCards.map((cardData) {
            return _buildStatCard(
              context: context,
              data: cardData,
              width: itemWidth,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required StatCardData data,
    required double width,
  }) {
    return HoverZoomEffect(
      scale: 1.02,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.percentage,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: data.trendColor,
            ),
          ),
        ],
      ),
    ),
  );
}
}
