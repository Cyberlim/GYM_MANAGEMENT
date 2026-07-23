import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_owner_web/features/payments/providers/payments_provider.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/plans/providers/plans_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:go_router/go_router.dart';

Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  String _selectedFilter = 'All Time';
  DateTimeRange? _customDateRange;

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<PaymentRecord> _applyDateFilter(List<PaymentRecord> records) {
    if (_selectedFilter == 'All Time') return records;
    final now = DateTime.now();
    if (_selectedFilter == 'This Month') {
      return records.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    }
    if (_selectedFilter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return records.where((r) => r.date.isAfter(weekAgo) || _isSameDay(r.date, weekAgo)).toList();
    }
    if (_selectedFilter == 'Custom' && _customDateRange != null) {
      return records.where((r) {
        return (r.date.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) && 
               r.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)))) || _isSameDay(r.date, _customDateRange!.start) || _isSameDay(r.date, _customDateRange!.end);
      }).toList();
    }
    return records;
  }

  Widget _buildFilterDropdown() {
    return Row(
      children: [
        if (_selectedFilter == 'Custom') ...[
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _customDateRange?.start ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) {
                setState(() {
                  _customDateRange = DateTimeRange(start: d, end: _customDateRange?.end ?? d);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_customDateRange != null ? DateFormat('MMM dd').format(_customDateRange!.start) : 'Start', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.calendar, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('-'),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _customDateRange?.end ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) {
                setState(() {
                  _customDateRange = DateTimeRange(start: _customDateRange?.start ?? d, end: d);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_customDateRange != null ? DateFormat('MMM dd').format(_customDateRange!.end) : 'End', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.calendar, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: _selectedFilter,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(LucideIcons.chevronDown, size: 16),
            items: ['All Time', 'This Month', 'This Week', 'Custom'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue == 'Custom' && _customDateRange == null) {
                 setState(() {
                   _selectedFilter = 'Custom';
                   _customDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
                 });
              } else if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPaymentsAsync = ref.watch(paymentsProvider);
    final highlightId = GoRouterState.of(context).uri.queryParameters['highlightId'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: allPaymentsAsync.when(
        data: (allPayments) {
          final payments = _applyDateFilter(allPayments);
          final sortedPayments = List<PaymentRecord>.from(payments)..sort((a, b) => b.date.compareTo(a.date));
          final totalRevenue = payments.where((p) => p.status == 'Completed').fold(0.0, (sum, p) => sum + p.amount);
          final pendingRevenue = payments.where((p) => p.status == 'Pending').fold(0.0, (sum, p) => sum + p.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage transactions and revenue',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => showAddPaymentDialog(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 516),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(title: 'Total Revenue', amount: totalRevenue, icon: LucideIcons.dollarSign, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(title: 'Pending Payments', amount: pendingRevenue, icon: LucideIcons.clock, color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                _buildFilterDropdown(),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 900;
                final listWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth > 800 ? constraints.maxWidth : 800.0);
                
                Widget content = Column(
                  children: [
                    if (!isMobile) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 56), // Avatar placeholder
                            Expanded(
                              flex: 2,
                              child: Text('Member', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Method', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: Theme.of(context).dividerColor.withOpacity(0.2), height: 1),
                    ],
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: sortedPayments.length,
                      separatorBuilder: (context, index) => isMobile ? const SizedBox(height: 16) : Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      itemBuilder: (context, index) {
                        final payment = sortedPayments[index];
                        final isHighlighted = payment.id == highlightId;
                        return _TransactionRow(payment: payment, isHighlighted: isHighlighted);
                      },
                    ),
                  ],
                );

                if (isMobile) {
                  return content;
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(
                        width: listWidth,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                          ),
                          child: content,
                        ),
                    ),
                  );
                }
              }
            ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading payments: $err')),
    ),
    );
  }
}

void showAddPaymentDialog(BuildContext context, WidgetRef ref, {PaymentRecord? paymentToEdit}) {
    final members = ref.read(membersProvider).value ?? [];
    String? selectedMemberId = paymentToEdit?.memberId;
    String selectedMethod = paymentToEdit?.paymentMethod ?? 'Cash';
    String selectedStatus = paymentToEdit?.status ?? 'Completed';
    String selectedCurrency = '₹';
    final amountController = TextEditingController(text: paymentToEdit != null ? paymentToEdit.amount.toString() : '');
    DateTime selectedDate = paymentToEdit?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(paymentToEdit == null ? 'Add Payment' : 'Edit Payment', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('You can update this record for up to 2 days after creation.', style: TextStyle(fontSize: 12, color: Colors.blue))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (paymentToEdit == null)
                      DropdownMenu<String>(
                        initialSelection: selectedMemberId,
                        expandedInsets: EdgeInsets.zero,
                        enableFilter: true,
                        enableSearch: true,
                        hintText: 'Select or search member...',
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownMenuEntries: members.map((m) => DropdownMenuEntry(value: m.id, label: m.name)).toList(),
                        onSelected: (val) => setState(() => selectedMemberId = val),
                      )
                    else
                      TextField(
                        controller: TextEditingController(text: members.firstWhere((m) => m.id == selectedMemberId, orElse: () => members.first).name),
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCurrency,
                              items: ['₹', '\$'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) => setState(() => selectedCurrency = val ?? '₹'),
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              isDense: true,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => selectedDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                            const Icon(LucideIcons.calendar, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedMethod,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: ['Cash', 'Card', 'UPI'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                onChanged: (val) => setState(() => selectedMethod = val ?? 'Cash'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: ['Completed', 'Pending', 'Failed'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                onChanged: (val) => setState(() => selectedStatus = val ?? 'Completed'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (selectedStatus == 'Pending') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Since status is Pending, you can change or update this until 10 days only.', style: TextStyle(fontSize: 12, color: Colors.orange))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedMemberId != null && amountController.text.isNotEmpty) {
                            final newPayment = PaymentRecord(
                              id: paymentToEdit?.id ?? const Uuid().v4(),
                              memberId: selectedMemberId!,
                              amount: double.tryParse(amountController.text) ?? 0.0,
                              date: selectedDate,
                              paymentMethod: selectedMethod,
                              status: selectedStatus,
                            );
                            if (paymentToEdit == null) {
                              ref.read(paymentsProvider.notifier).addPayment(newPayment);
                            } else {
                              ref.read(paymentsProvider.notifier).updatePayment(newPayment);
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Payment', style: TextStyle(color: Colors.white)),
                      ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  final PaymentRecord payment;
  final bool isHighlighted;

  const _TransactionRow({required this.payment, this.isHighlighted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider).value ?? [];
    final member = members.isNotEmpty 
        ? members.firstWhere((m) => m.id == payment.memberId, orElse: () => Member(id: payment.memberId, name: 'Deleted Member', email: '', phone: '', membershipPlan: '', status: '', joinDate: DateTime.now(), expiryDate: DateTime.now(), totalCheckIns: 0))
        : Member(id: '0', name: 'Deleted Member', email: '', phone: '', membershipPlan: '', status: '', joinDate: DateTime.now(), expiryDate: DateTime.now(), totalCheckIns: 0);
    
    final plans = ref.watch(plansProvider).value ?? [];
    final plan = plans.isNotEmpty ? plans.firstWhere((p) => p.name == member.membershipPlan, orElse: () => plans.first) : null;
    final planColor = plan != null ? _hexToColor(plan.colorHex) : Theme.of(context).colorScheme.primary;

    Color statusColor;
    IconData statusIcon;
    switch (payment.status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
        break;
      default:
        statusColor = Colors.redAccent;
        statusIcon = LucideIcons.xCircle;
    }
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    member.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (DateTime.now().difference(payment.date).inDays <= (payment.status == 'Pending' ? 10 : 2))
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.moreVertical, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        showAddPaymentDialog(context, ref, paymentToEdit: payment);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            title: Text('Delete Payment', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            content: Text('Are you sure you want to delete this payment record?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(paymentsProvider.notifier).removePayment(payment.id);
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Payment')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Payment', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.membershipPlan,
                    style: TextStyle(
                      color: planColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(payment.date),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        payment.paymentMethod == 'Cash' ? LucideIcons.banknote : 
                        payment.paymentMethod == 'Card' ? LucideIcons.creditCard : LucideIcons.smartphone,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        payment.paymentMethod,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            payment.status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              member.name.substring(0, 1).toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.membershipPlan,
                  style: TextStyle(
                    color: planColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM dd, yyyy').format(payment.date),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    payment.paymentMethod == 'Cash' ? LucideIcons.banknote : 
                    payment.paymentMethod == 'Card' ? LucideIcons.creditCard : LucideIcons.smartphone,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      payment.paymentMethod,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            payment.status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (DateTime.now().difference(payment.date).inDays <= (payment.status == 'Pending' ? 10 : 2)) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.moreVertical, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        showAddPaymentDialog(context, ref, paymentToEdit: payment);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            title: Text('Delete Payment', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            content: Text('Are you sure you want to delete this payment record?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(paymentsProvider.notifier).removePayment(payment.id);
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Payment')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Payment', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
