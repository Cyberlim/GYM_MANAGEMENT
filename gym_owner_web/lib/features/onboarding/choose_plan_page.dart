import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChoosePlanPage extends StatefulWidget {
  const ChoosePlanPage({super.key});

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  String _billingCycle = 'monthly'; // 'monthly', 'quarterly', 'annually'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.zap, size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    const Text('UPGRADE PLAN', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose the perfect plan for your gym',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 40, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upgrade your subscription to unlock premium features and scale your business.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Billing Cycle Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption('monthly', 'Monthly', LucideIcons.calendar),
                    _buildToggleOption('quarterly', 'Quarterly', LucideIcons.calendarDays),
                    _buildToggleOption('annually', 'Annually', LucideIcons.calendarRange),
                  ],
                ),
              ),
              const SizedBox(height: 64),

              // Plan Cards (Horizontally Scrollable)
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlanCard(
                            context: context,
                            title: 'Basic',
                            subtitle: 'Perfect for small gyms getting started',
                            icon: LucideIcons.dumbbell,
                            primaryColor: const Color(0xFF6366F1), // Indigo/Purple
                            lightColor: const Color(0xFFEEF2FF),
                            basePrice: 999,
                            features: [
                              'Up to 200 Members',
                              'Up to 5 Trainers',
                              '1 Branch',
                              'Reception & Attendance',
                              'Payment Management',
                              'Basic Reports',
                              'Email Support',
                            ],
                            isPopular: false,
                          ),
                          const SizedBox(width: 24),
                          _buildPlanCard(
                            context: context,
                            title: 'Pro',
                            subtitle: 'Best for growing gyms and fitness centers',
                            icon: LucideIcons.crown,
                            primaryColor: const Color(0xFF16A34A), // Green
                            lightColor: const Color(0xFFDCFCE7),
                            basePrice: 2499,
                            originalPrice: 2997,
                            savePercent: 17,
                            features: [
                              'Up to 1,000 Members',
                              'Up to 20 Trainers',
                              '5 Branches',
                              'Everything in Basic',
                              'Inventory Management',
                              'Advanced Reports',
                              'Priority Support',
                              'SMS & Email Notifications',
                            ],
                            isPopular: true,
                          ),
                          const SizedBox(width: 24),
                          _buildPlanCard(
                            context: context,
                            title: 'Enterprise',
                            subtitle: 'For large gyms and multi-branch chains',
                            icon: LucideIcons.gem,
                            primaryColor: const Color(0xFFD97706), // Orange
                            lightColor: const Color(0xFFFEF3C7),
                            basePrice: 3999,
                            originalPrice: 4999,
                            savePercent: 20,
                            features: [
                              'Unlimited Members',
                              'Unlimited Trainers',
                              'Unlimited Branches',
                              'Everything in Pro',
                              'Advanced Analytics',
                              'Custom Roles & Permissions',
                              'API Access',
                              'Dedicated Support',
                            ],
                            isPopular: false,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String value, String label, IconData icon) {
    final isSelected = _billingCycle == value;
    return GestureDetector(
      onTap: () => setState(() => _billingCycle = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color lightColor,
    required int basePrice,
    int? originalPrice,
    int? savePercent,
    required List<String> features,
    required bool isPopular,
  }) {
    // Dynamic price adjustment based on billing cycle
    int displayPrice = basePrice;
    int? displayOriginalPrice = originalPrice;
    String billingSubtext = 'Billed every month';

    if (_billingCycle == 'quarterly') {
      displayPrice = (basePrice * 0.9).round();
      if (originalPrice != null) displayOriginalPrice = (originalPrice * 0.9).round();
      billingSubtext = 'Billed every 3 months (₹${displayPrice * 3} total)';
    } else if (_billingCycle == 'annually') {
      displayPrice = (basePrice * 0.85).round();
      if (originalPrice != null) displayOriginalPrice = (originalPrice * 0.85).round();
      billingSubtext = 'Billed annually (₹${displayPrice * 12} total)';
    }

    // Format numbers with commas
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? primaryColor : Colors.grey.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Wave Effect (Placeholder using gradient)
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.08),
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPopular)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: primaryColor,
                    child: const Text(
                      'Most Popular',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(height: 32),

                Padding(
                  padding: EdgeInsets.only(left: 32, right: 32, top: isPopular ? 24 : 0, bottom: 32),
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
                                Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4)),
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
                          Text('₹${formatCurrency(displayPrice)}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(width: 4),
                          const Text('/month', style: TextStyle(color: Color(0xFF6366F1), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (displayOriginalPrice != null && savePercent != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text('₹${formatCurrency(displayOriginalPrice)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 12),
                              Text('Save $savePercent%', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(billingSubtext, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      
                      const SizedBox(height: 32),
                        
                      // Features
                      ...features.map((f) => Padding(
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
                                Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          )),
                      
                      const SizedBox(height: 32),
                      // Action Button
                      ElevatedButton(
                        onPressed: () => context.go('/payment?plan=${title.toLowerCase()}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight, size: 18),
                          ],
                        ),
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
