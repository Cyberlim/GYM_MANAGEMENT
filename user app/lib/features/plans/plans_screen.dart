import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/auth_provider.dart';

final plansProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiProvider).getPlans();
});

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  void _purchasePlan(BuildContext context, WidgetRef ref, dynamic plan) {
    context.push('/payment', extra: plan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buy Plan')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No plans available right now.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Choose the plan\nthat\'s right for you', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Icon(LucideIcons.dumbbell, size: 48, color: const Color(0xFF6C5CE7).withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 24),
                ...plans.map((plan) {
                  return _buildPlanCard(context, ref, plan, theme);
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String text, bool active, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6C5CE7) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: active ? null : Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildFeatureRow(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(LucideIcons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, dynamic plan, ThemeData theme) {
    final bool isPopular = plan['name']?.toString().toLowerCase().contains('gold') ?? false;
    
    String formattedCode = (plan['colorHex']?.toString() ?? '#6C5CE7').replaceAll('#', '');
    if (formattedCode.length == 6) {
      formattedCode = 'FF$formattedCode';
    }
    Color primaryColor = Color(int.tryParse(formattedCode, radix: 16) ?? 0xFF6C5CE7);
    IconData icon = LucideIcons.dumbbell;

    final double price = (plan['price'] as num?)?.toDouble() ?? 0.0;
    final double? discountPrice = (plan['discountPrice'] as num?)?.toDouble();
    final bool isDiscountActive = discountPrice != null && discountPrice > 0;
    final String currencySymbol = plan['currencySymbol']?.toString() ?? '₹';
    final String planName = plan['name']?.toString() ?? 'Plan';

    final String adjustedPrice = '$currencySymbol${price.toStringAsFixed(0)}';
    final String adjustedDiscountPrice = isDiscountActive ? '$currencySymbol${discountPrice.toStringAsFixed(0)}' : adjustedPrice;
    final String durationText = plan['duration']?.toString() ?? 'Month';

    String billingSubtext = 'Billed every ${durationText.toLowerCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? primaryColor : theme.dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? primaryColor.withOpacity(0.15) : theme.shadowColor.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Wave Effect
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.15),
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 0, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, size: 28, color: primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(planName, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Pricing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(isDiscountActive ? adjustedDiscountPrice : adjustedPrice, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(width: 4),
                          Text('/${durationText.toLowerCase()}', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (isDiscountActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(adjustedPrice, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(billingSubtext, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                      
                      const SizedBox(height: 24),
                      
                      // Features
                      if (plan['features'] != null && (plan['features'] as List).isNotEmpty)
                        ...(plan['features'] as List).map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(f.toString(), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            )).toList()
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('No features listed', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        )
                      ],
                    ],
                  ),
                ),
                
                // Footer Action (Choose Plan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.02),
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _purchasePlan(context, ref, plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isPopular ? 4 : 0,
                      ),
                      child: const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
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
