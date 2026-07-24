import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/api_service.dart';
import 'package:user_app/core/auth_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  void _showPaymentDetailsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enter $_selectedPaymentMethod Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedPaymentMethod == 'UPI')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Enter UPI ID (e.g. name@bank)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(LucideIcons.atSign),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('OR Pay with installed apps', style: TextStyle(color: Colors.grey))),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMockAppIcon('GPay', Colors.blue),
                        _buildMockAppIcon('PhonePe', Colors.purple),
                        _buildMockAppIcon('Paytm', Colors.lightBlue),
                      ],
                    ),
                  ],
                )
              else if (_selectedPaymentMethod == 'Card')
                Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(LucideIcons.user),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(LucideIcons.creditCard),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Expiry (MM/YY)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else if (_selectedPaymentMethod == 'Net Banking')
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Bank',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank']
                      .map((bank) => DropdownMenuItem(value: bank, child: Text(bank)))
                      .toList(),
                  onChanged: (val) {},
                )
              else if (_selectedPaymentMethod == 'Wallets')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Wallets on device:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMockAppIcon('Paytm', Colors.lightBlue),
                        _buildMockAppIcon('PhonePe', Colors.purple),
                        _buildMockAppIcon('Amazon Pay', Colors.orange),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMockAppIcon(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(Icons.account_balance_wallet, color: color),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    
    try {
      // Simulate network/payment gateway delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Call actual backend API
      await ref.read(apiProvider).purchasePlan(widget.plan['_id']);
      
      // Reload profile to get new expiry date
      await ref.read(authProvider.notifier).checkAuth();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Payment Successful! Subscribed to ${widget.plan['name']}'), backgroundColor: Colors.green),
      );
      
      // Navigate back to dashboard
      router.go('/dashboard');
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = widget.plan['discountPrice'] != null && widget.plan['discountPrice'] > 0 
        ? widget.plan['discountPrice'] 
        : widget.plan['price'];
    final currency = widget.plan['currencySymbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.plan['name'], style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                      Text('$currency$price', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                      Text(widget.plan['duration'] ?? '1 Month', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$currency$price', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Payment Options
            const Text('Payment Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildPaymentOption('UPI', 'UPI', Icons.account_balance_wallet),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildPaymentOption('Card', 'VISA', Icons.credit_card),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildPaymentOption('Net Banking', 'Bank', Icons.account_balance),
                  Divider(height: 1, color: theme.dividerColor),
                  _buildPaymentOption('Wallets', 'Wallet', Icons.wallet),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _selectedPaymentMethod == null ? null : _showPaymentDetailsPopup,
                icon: _isLoading ? const SizedBox() : const Icon(LucideIcons.lock, size: 18),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay $currency$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.lock, size: 14, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Secure Payment', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String trailingText, IconData trailingIcon) {
    final isSelected = _selectedPaymentMethod == title;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = title);
        _showPaymentDetailsPopup();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (trailingText == 'VISA')
              const Row(
                children: [
                  Text('VISA', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  SizedBox(width: 4),
                  Icon(Icons.circle, color: Colors.red, size: 12),
                  Icon(Icons.circle, color: Colors.orange, size: 12),
                ],
              )
            else if (title == 'UPI')
              const Text('UPI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))
            else
              Icon(trailingIcon, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
