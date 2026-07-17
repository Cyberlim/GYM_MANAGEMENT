import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

import '../../data/mock/mock_data.dart';

class PlansPage extends StatefulWidget {
  final bool showAddPlan;
  const PlansPage({super.key, this.showAddPlan = false});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String _billingCycle = 'monthly'; // 'monthly', 'quarterly', 'annual'
  final int _quarterlyDiscount = 10;
  final int _annualDiscount = 15;
  
  String _adjustPrice(String originalPrice) {
    if (_billingCycle == 'monthly') return originalPrice;
    
    final RegExp regex = RegExp(r'([\$₹]\s*)(\d+)');
    return originalPrice.replaceAllMapped(regex, (match) {
      String currency = match.group(1)!;
      int basePrice = int.parse(match.group(2)!);
      double factor = _billingCycle == 'annual' ? (100 - _annualDiscount) / 100 : (100 - _quarterlyDiscount) / 100;
      int newPrice = (basePrice * factor).round();
      return '$currency$newPrice';
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.showAddPlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreatePlanDialog();
      });
    }
  }
  List<Map<String, dynamic>> get _plans => MockData.plans;

  void _showEditPlanDialog(int index, Map<String, dynamic> plan) {
    final nameController = TextEditingController(text: plan['name']);
    
    String currentPrice = plan['price'].toString();
    String selectedCurrency = currentPrice.startsWith('₹') ? '₹' : '\$';
    String priceAmount = currentPrice.replaceAll('\$', '').replaceAll('₹', '');
    final priceController = TextEditingController(text: priceAmount);
    
    String currentDiscount = plan['discountPrice']?.toString() ?? '\$0';
    String discountAmount = currentDiscount.replaceAll('\$', '').replaceAll('₹', '');
    final discountController = TextEditingController(text: discountAmount);
    bool isDiscountActive = plan['isDiscountActive'] ?? false;
    
    final descController = TextEditingController(text: plan['description']);
    final featuresController = TextEditingController(text: (plan['features'] as List).join('\n'));
    bool isPopular = plan['isPopular'];
    bool isTrialActive = plan['isTrialActive'] ?? true;
    final trialDaysController = TextEditingController(text: (plan['trialDays'] ?? 7).toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Plan Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCurrency,
                                items: const [
                                  DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: TextStyle(fontSize: 14))),
                                  DropdownMenuItem(value: '₹', child: Text('INR (₹)', style: TextStyle(fontSize: 14))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedCurrency = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price Amount',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable Discount', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isDiscountActive,
                        onChanged: (val) => setDialogState(() => isDiscountActive = val),
                      ),
                      if (isDiscountActive) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(selectedCurrency, style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: discountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Discounted Price',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: featuresController,
                        decoration: InputDecoration(
                          labelText: 'Features (one per line)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Most Popular', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isPopular,
                        onChanged: (val) => setDialogState(() => isPopular = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable Free Trial', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isTrialActive,
                        onChanged: (val) => setDialogState(() => isTrialActive = val),
                      ),
                      if (isTrialActive) ...[
                        TextField(
                          controller: trialDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Trial Days',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _plans[index] = {
                        ...plan,
                        'name': nameController.text,
                        'price': '$selectedCurrency${priceController.text}',
                        'discountPrice': '$selectedCurrency${discountController.text}',
                        'isDiscountActive': isDiscountActive,
                        'description': descController.text,
                        'features': featuresController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                        'isPopular': isPopular,
                        'isTrialActive': isTrialActive,
                        'trialDays': int.tryParse(trialDaysController.text) ?? 7,
                      };
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    elevation: Theme.of(context).brightness == Brightness.dark ? 8 : 2,
                    shadowColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    String selectedCurrency = '\$';
    final priceController = TextEditingController();
    final discountController = TextEditingController();
    bool isDiscountActive = false;
    final descController = TextEditingController();
    final featuresController = TextEditingController();
    bool isPopular = false;
    bool isActive = true;
    bool isTrialActive = true;
    final trialDaysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Create New Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Plan Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCurrency,
                                items: const [
                                  DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: TextStyle(fontSize: 14))),
                                  DropdownMenuItem(value: '₹', child: Text('INR (₹)', style: TextStyle(fontSize: 14))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedCurrency = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price Amount',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable Discount', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isDiscountActive,
                        onChanged: (val) => setDialogState(() => isDiscountActive = val),
                      ),
                      if (isDiscountActive) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(selectedCurrency, style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: discountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Discounted Price',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: featuresController,
                        decoration: InputDecoration(
                          labelText: 'Features (one per line)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Most Popular', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isPopular,
                        onChanged: (val) => setDialogState(() => isPopular = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Active Status', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable Free Trial', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: AppTheme.primaryColor,
                        value: isTrialActive,
                        onChanged: (val) => setDialogState(() => isTrialActive = val),
                      ),
                      if (isTrialActive) ...[
                        TextField(
                          controller: trialDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Trial Days',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _plans.add({
                        'name': nameController.text.isEmpty ? 'New Plan' : nameController.text,
                        'price': priceController.text.isEmpty ? '${selectedCurrency}0' : '$selectedCurrency${priceController.text}',
                        'discountPrice': discountController.text.isEmpty ? '${selectedCurrency}0' : '$selectedCurrency${discountController.text}',
                        'isDiscountActive': isDiscountActive,
                        'description': descController.text.isEmpty ? 'Plan description' : descController.text,
                        'features': featuresController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                        'isPopular': isPopular,
                        'isActive': isActive,
                        'isTrialActive': isTrialActive,
                        'trialDays': int.tryParse(trialDaysController.text) ?? 7,
                      });
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    elevation: Theme.of(context).brightness == Brightness.dark ? 8 : 2,
                    shadowColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Create Plan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plans & Pricing', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Manage subscription tiers and pricing for gym owners.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreatePlanDialog,
                icon: Icon(LucideIcons.plus, size: 16),
                label: Text('Create Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, // Slate Teal
                  foregroundColor: Colors.white,
                  elevation: Theme.of(context).brightness == Brightness.dark ? 8 : 2,
                  shadowColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          // Billing Cycle Toggle
          Row(
            children: [
              const Text('Billing cycle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption('monthly', 'Monthly', LucideIcons.calendar),
                    _buildToggleOption('quarterly', 'Quarterly', LucideIcons.calendarDays),
                    _buildToggleOption('annual', 'Annually', LucideIcons.calendarRange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Plans Grid
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: _plans.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> plan = entry.value;
              return _buildPlanCard(index, plan);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String value, String label, IconData icon) {
    final isSelected = _billingCycle == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _billingCycle = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF222222) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(int index, Map<String, dynamic> plan) {
    final bool isPopular = plan['isPopular'];
    final bool isActive = plan['isActive'];
    final bool isDiscountActive = plan['isDiscountActive'] ?? false;
    final bool isTrialActive = plan['isTrialActive'] ?? true;
    final int trialDays = plan['trialDays'] ?? 7;
    
    // Dynamic theme assignment based on index
    Color primaryColor;
    Color lightColor;
    IconData icon;

    if (index == 0) {
      primaryColor = const Color(0xFF6366F1); // Indigo
      lightColor = const Color(0xFFEEF2FF);
      icon = LucideIcons.dumbbell;
    } else if (index == 1) {
      primaryColor = const Color(0xFF16A34A); // Green
      lightColor = const Color(0xFFDCFCE7);
      icon = LucideIcons.crown;
    } else if (index == 2) {
      primaryColor = const Color(0xFFD97706); // Orange
      lightColor = const Color(0xFFFEF3C7);
      icon = LucideIcons.gem;
    } else {
      primaryColor = const Color(0xFF64748B); // Slate
      lightColor = const Color(0xFFF1F5F9);
      icon = LucideIcons.layoutGrid;
    }

    final String adjustedPrice = _adjustPrice(plan['price']);
    final String adjustedDiscountPrice = plan['discountPrice'] != null ? _adjustPrice(plan['discountPrice']) : adjustedPrice;

    // Calculate dynamic billing subtext
    String billingSubtext = 'Billed every month';
    if (_billingCycle == 'quarterly') {
      int baseAmount = int.tryParse(adjustedPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int discAmount = int.tryParse(adjustedDiscountPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      String curr = plan['price'].toString().replaceAll(RegExp(r'[0-9\s]'), '');
      if (curr.isEmpty) curr = '₹';
      billingSubtext = 'Billed every 3 months (${curr}${isDiscountActive ? discAmount * 3 : baseAmount * 3} total)';
    } else if (_billingCycle == 'annual') {
      int baseAmount = int.tryParse(adjustedPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int discAmount = int.tryParse(adjustedDiscountPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      String curr = plan['price'].toString().replaceAll(RegExp(r'[0-9\s]'), '');
      if (curr.isEmpty) curr = '₹';
      billingSubtext = 'Billed annually (${curr}${isDiscountActive ? discAmount * 12 : baseAmount * 12} total)';
    }

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? primaryColor : Theme.of(context).dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? primaryColor.withOpacity(0.15) : Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
                  padding: EdgeInsets.only(left: 32, right: 32, top: isPopular ? 24 : 0, bottom: 24),
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
                                    Expanded(child: Text(plan['name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold))),
                                    if (!isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                                        child: Text('Inactive', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(plan['description'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, height: 1.4)),
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
                          const Text('/month', style: TextStyle(color: Color(0xFF6366F1), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (isDiscountActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(adjustedPrice, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(billingSubtext, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                      
                      const SizedBox(height: 24),
                      // Trial Pill
                      if (isTrialActive) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.checkCircle2, size: 14, color: primaryColor),
                              const SizedBox(width: 8),
                              Text('$trialDays Days Free Trial', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else
                        const SizedBox(height: 8),
                      
                      // Features
                      ...List<String>.from(plan['features']).map((f) => Padding(
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
                                Expanded(child: Text(f, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                
                // Footer Actions (Edit / Active Toggle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
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
                              setState(() {
                                _plans[index]['isActive'] = val;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditPlanDialog(index, plan),
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
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
