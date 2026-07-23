import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:gym_owner_web/features/plans/providers/plans_provider.dart';
import 'package:gym_owner_web/shared/widgets/hover_zoom_effect.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansState = ref.watch(plansProvider);
    final action = GoRouterState.of(context).uri.queryParameters['action'];

    if (action == 'add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/plans');
        showPlanDialog(context, ref);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Membership Plans',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your gym subscription tiers',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => showPlanDialog(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: plansState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (plans) => LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 700) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 1100) {
                    crossAxisCount = 2;
                  }

                  if (plans.isEmpty) {
                    return Center(
                      child: Text('No plans added yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 580,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return _PlanCard(plan: plan);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final MembershipPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPopular = false;
    final bool isActive = plan.isActive;
    final bool isDiscountActive = plan.discountPrice != null && plan.discountPrice! > 0;
    
    String formattedCode = plan.colorHex.replaceAll('#', '');
    if (formattedCode.length == 6) {
      formattedCode = 'FF$formattedCode';
    }
    Color primaryColor = Color(int.parse(formattedCode, radix: 16));
    IconData icon = LucideIcons.dumbbell;

    final String adjustedPrice = '${plan.currencySymbol}${plan.price.toStringAsFixed(0)}';
    final String adjustedDiscountPrice = isDiscountActive ? '${plan.currencySymbol}${plan.discountPrice!.toStringAsFixed(0)}' : adjustedPrice;

    String billingSubtext = 'Billed every ${plan.duration.toLowerCase()}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? primaryColor : Theme.of(context).dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? primaryColor.withOpacity(0.15) : Theme.of(context).shadowColor.withOpacity(0.05),
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
                                    Expanded(child: Text(plan.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold))),
                                    if (!isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                                        child: const Text('Inactive', style: TextStyle(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                      )
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
                          Text(isDiscountActive ? adjustedDiscountPrice : adjustedPrice, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(width: 4),
                          Text('/${plan.duration.toLowerCase()}', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (isDiscountActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(adjustedPrice, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(billingSubtext, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                      
                      const SizedBox(height: 24),
                      
                      // Features
                      ...plan.features.map((f) => Padding(
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
                                Expanded(child: Text(f, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                
                const Spacer(),

                // Footer Actions (Edit / Delete / Toggle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: primaryColor,
                            onChanged: (val) {
                              final updatedPlan = MembershipPlan(
                                id: plan.id,
                                name: plan.name,
                                price: plan.price,
                                discountPrice: plan.discountPrice,
                                duration: plan.duration,
                                features: plan.features,
                                colorHex: plan.colorHex,
                                currencySymbol: plan.currencySymbol,
                                isActive: val,
                              );
                              ref.read(plansProvider.notifier).updatePlan(updatedPlan);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => showPlanDialog(context, ref, planToEdit: plan),
                            icon: const Icon(LucideIcons.pencil, size: 16),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          IconButton(
                            onPressed: () => ref.read(plansProvider.notifier).removePlan(plan.id),
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            color: Colors.redAccent,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showPlanDialog(BuildContext context, WidgetRef ref, {MembershipPlan? planToEdit}) {
  final nameController = TextEditingController(text: planToEdit?.name ?? '');
  final priceController = TextEditingController(text: planToEdit?.price.toString() ?? '');
  final discountPriceController = TextEditingController(text: planToEdit?.discountPrice?.toString() ?? '');
  final durationController = TextEditingController(text: planToEdit?.duration ?? '');
  final featuresController = TextEditingController(text: planToEdit?.features.join('\n') ?? '');
  
  String selectedColorHex = planToEdit?.colorHex ?? '#CFFF50';
  String selectedCurrency = planToEdit?.currencySymbol ?? '₹';
  bool isActive = planToEdit?.isActive ?? true;
  
  final List<String> colorOptions = [
    '#CFFF50', '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5',
    '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A',
    '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#607D8B'
  ];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        planToEdit == null ? 'Add New Plan' : 'Edit Plan',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(context, 'Plan Name', nameController),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(context, 'Price', priceController, isNumber: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(context, 'Discount Price (Optional)', discountPriceController, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Currency', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                                    const SizedBox(height: 8),
                                    SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(value: '₹', label: Text('₹ INR')),
                                        ButtonSegment(value: '\$', label: Text('\$ USD')),
                                      ],
                                      selected: {selectedCurrency},
                                      onSelectionChanged: (val) => setState(() => selectedCurrency = val.first),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Theme.of(context).colorScheme.primary.withOpacity(0.2);
                                          }
                                          return Colors.transparent;
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(context, 'Duration (e.g. 1 Month)', durationController)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                                    const SizedBox(height: 8),
                                    SwitchListTile(
                                      title: Text(isActive ? 'Active Plan' : 'Inactive Plan', style: const TextStyle(fontSize: 14)),
                                      value: isActive,
                                      onChanged: (val) => setState(() => isActive = val),
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(context, 'Features (One per line)', featuresController, maxLines: 5),
                          const SizedBox(height: 16),
                          Text('Plan Theme Color', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: colorOptions.map((hex) {
                              final isSelected = selectedColorHex.toUpperCase() == hex.toUpperCase();
                              return GestureDetector(
                                onTap: () => setState(() => selectedColorHex = hex),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16)),
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16)).withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                                    ] : null,
                                  ),
                                  child: isSelected ? const Icon(LucideIcons.check, size: 20, color: Colors.white) : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                            final features = featuresController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
                            final newPlan = MembershipPlan(
                              id: planToEdit?.id ?? '',
                              name: nameController.text,
                              price: double.tryParse(priceController.text) ?? 0.0,
                              discountPrice: double.tryParse(discountPriceController.text),
                              duration: durationController.text,
                              features: features,
                              colorHex: selectedColorHex,
                              currencySymbol: selectedCurrency,
                              isActive: isActive,
                            );

                            final isNew = planToEdit == null;
                            if (isNew) {
                              ref.read(plansProvider.notifier).addPlan(newPlan);
                            } else {
                              ref.read(plansProvider.notifier).updatePlan(newPlan);
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isNew ? 'Plan added successfully!' : 'Plan updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: Text(planToEdit == null ? 'Save Plan' : 'Update Plan', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}
