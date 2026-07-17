import 'package:flutter/material.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/charts_row.dart';
import 'widgets/lists_row.dart';
import 'widgets/bottom_actions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return dashboardState.when(
      data: (data) {
        if (data == null) {
          return const Center(child: Text("Failed to load dashboard data"));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatCardsRow(data: data),
              const SizedBox(height: 24),
              ChartsRow(data: data),
              const SizedBox(height: 24),
              ListsRow(data: data),
              const SizedBox(height: 24),
              const BottomActionsRow(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
