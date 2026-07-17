import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/highlighted_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';

class FinancePage extends StatefulWidget {
  final int initialTabIndex;
  const FinancePage({super.key, this.initialTabIndex = 0});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header and Tabs
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Finance & Billing', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Manage payments, invoices, and platform transactions.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Payments'),
                    Tab(text: 'Invoices'),
                    Tab(text: 'Transactions'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _PaymentsView(),
              _InvoicesView(),
              _TransactionsView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAYMENTS VIEW
// ============================================================================
class _PaymentsView extends ConsumerStatefulWidget {
  const _PaymentsView();
  @override
  ConsumerState<_PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<_PaymentsView> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return ref.watch(superadminFinanceProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (financeData) {
        final query = _searchQuery.toLowerCase();
        final payments = financeData['recentPayments'] as List<dynamic>? ?? [];
        final filteredPayments = payments.where((payment) {
          if (_selectedStatus != 'All' && payment['status'] != _selectedStatus) return false;
          if (query.isEmpty) return true;
          final gymName = payment['gymName'].toString().toLowerCase();
          final id = payment['id'].toString().toLowerCase();
          return gymName.contains(query) || id.contains(query);
        }).toList();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, 'Search payments...', ['All', 'Completed', 'Failed', 'Refunded'], (val) => setState(() => _selectedStatus = val), (val) => setState(() => _searchQuery = val), _selectedStatus),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: Container(
              decoration: _tableHeaderDecoration(context),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('PAYMENT ID', style: _headerStyle(context))),
                  Expanded(flex: 3, child: Text('GYM NAME', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('PLAN', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('DATE', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('STATUS', style: _headerStyle(context))),
                ],
              ),
            ),
          ),
        ),
        if (filteredPayments.isEmpty)
          _buildEmptyState(context)
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final payment = filteredPayments[index];
                final isLast = index == filteredPayments.length - 1;
                return Container(
                  decoration: _tableRowDecoration(context, isLast),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: HighlightedText(text: payment['id'].toString(), query: _searchQuery, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF4F46E5)))),
                      Expanded(flex: 3, child: HighlightedText(text: payment['gymName'].toString(), query: _searchQuery, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text(payment['plan'] ?? 'Basic', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(flex: 2, child: Text('\$${payment['amount']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text(payment['date'] ?? '', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildStatusBadge(payment['status'].toString()),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: filteredPayments.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
    },
    );
  }
}

// ============================================================================
// INVOICES VIEW
// ============================================================================
class _InvoicesView extends ConsumerStatefulWidget {
  const _InvoicesView();
  @override
  ConsumerState<_InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends ConsumerState<_InvoicesView> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return ref.watch(superadminFinanceProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (financeData) {
        final query = _searchQuery.toLowerCase();
        final invoices = financeData['invoices'] as List<dynamic>? ?? [];
        final filteredInvoices = invoices.where((invoice) {
          if (_selectedStatus != 'All' && invoice['status'] != _selectedStatus) return false;
          if (query.isEmpty) return true;
          final gymName = invoice['gymName'].toString().toLowerCase();
          final id = invoice['id'].toString().toLowerCase();
          return gymName.contains(query) || id.contains(query);
        }).toList();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, 'Search invoices...', ['All', 'Paid', 'Pending', 'Overdue'], (val) => setState(() => _selectedStatus = val), (val) => setState(() => _searchQuery = val), _selectedStatus),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: Container(
              decoration: _tableHeaderDecoration(context),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('INVOICE ID', style: _headerStyle(context))),
                  Expanded(flex: 3, child: Text('GYM', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('ISSUE DATE', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('DUE DATE', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('STATUS', style: _headerStyle(context))),
                  Expanded(flex: 1, child: SizedBox()), // Actions
                ],
              ),
            ),
          ),
        ),
        if (filteredInvoices.isEmpty)
          _buildEmptyState(context)
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final invoice = filteredInvoices[index];
                final isLast = index == filteredInvoices.length - 1;
                return Container(
                  decoration: _tableRowDecoration(context, isLast),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(invoice['id'].toString(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invoice['gymName'].toString(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(invoice['ownerName'].toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text('\$${invoice['amount']}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(flex: 2, child: Text(invoice['issueDate']?.toString() ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(flex: 2, child: Text(invoice['dueDate']?.toString() ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildStatusBadge(invoice['status'].toString()),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(LucideIcons.download, size: 20, color: AppTheme.primaryColor),
                            onPressed: () {},
                            tooltip: 'Download PDF',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: filteredInvoices.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
      },
    );
  }
}

// ============================================================================
// TRANSACTIONS VIEW
// ============================================================================
class _TransactionsView extends ConsumerStatefulWidget {
  const _TransactionsView();
  @override
  ConsumerState<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<_TransactionsView> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return ref.watch(superadminFinanceProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (financeData) {
        final query = _searchQuery.toLowerCase();
        final transactions = financeData['transactions'] as List<dynamic>? ?? [];
        final filteredTransactions = transactions.where((trx) {
          if (_selectedStatus != 'All' && trx['status'] != _selectedStatus) return false;
          if (query.isEmpty) return true;
          final gymName = trx['gymName'].toString().toLowerCase();
          final id = trx['id'].toString().toLowerCase();
          return gymName.contains(query) || id.contains(query);
        }).toList();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, 'Search transactions...', ['All', 'Success', 'Pending', 'Failed'], (val) => setState(() => _selectedStatus = val), (val) => setState(() => _searchQuery = val), _selectedStatus),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: Container(
              decoration: _tableHeaderDecoration(context),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('TRANSACTION ID', style: _headerStyle(context))),
                  Expanded(flex: 3, child: Text('GYM', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('DATE', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('METHOD', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('TYPE', style: _headerStyle(context))),
                  Expanded(flex: 2, child: Text('STATUS', style: _headerStyle(context))),
                ],
              ),
            ),
          ),
        ),
        if (filteredTransactions.isEmpty)
          _buildEmptyState(context)
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final trx = filteredTransactions[index];
                final isLast = index == filteredTransactions.length - 1;
                return Container(
                  decoration: _tableRowDecoration(context, isLast),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(trx['id'].toString(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(flex: 3, child: Text(trx['gymName'].toString(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${trx['type'] == 'Refund' ? '-' : ''}\$${trx['amount']}', 
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: trx['type'] == 'Refund' ? Colors.red : Theme.of(context).colorScheme.onSurface)
                        ),
                      ),
                      Expanded(flex: 2, child: Text(trx['date'] ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(trx['paymentMethod'] == 'Credit Card' ? LucideIcons.creditCard : LucideIcons.building, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(trx['paymentMethod'].toString(), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(trx['type'].toString(), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildStatusBadge(trx['status'].toString()),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: filteredTransactions.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
      },
    );
  }
}

// ============================================================================
// SHARED WIDGETS & HELPERS
// ============================================================================

TextStyle _headerStyle(BuildContext context) => TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 12, letterSpacing: 0.5);

BoxDecoration _tableHeaderDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).scaffoldBackgroundColor, // Light background to highlight header
    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
    border: Border(
      top: BorderSide(color: Colors.grey.withOpacity(0.1)),
      left: BorderSide(color: Colors.grey.withOpacity(0.1)),
      right: BorderSide(color: Colors.grey.withOpacity(0.1)),
      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
    ),
  );
}

BoxDecoration _tableRowDecoration(BuildContext context, bool isLast) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border(
      bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.1)),
      left: BorderSide(color: Colors.grey.withOpacity(0.1)),
      right: BorderSide(color: Colors.grey.withOpacity(0.1)),
    ),
    borderRadius: isLast ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : null,
  );
}

Widget _buildSliverAppBar(BuildContext context, String searchHint, List<String> statusOptions, Function(String) onStatusChanged, Function(String) onSearchChanged, String selectedStatus) {
  return SliverAppBar(
    floating: true,
    snap: true,
    automaticallyImplyLeading: false,
    elevation: 0,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    toolbarHeight: 80,
    flexibleSpace: FlexibleSpaceBar(
      background: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 300,
                      height: 40,
                      child: TextField(
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                        ),
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(6)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          hint: Text('Status: $selectedStatus', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                          icon: Icon(LucideIcons.chevronDown, size: 16),
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                          onChanged: (val) { if (val != null) onStatusChanged(val); },
                          items: statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(LucideIcons.download, size: 16),
                  label: Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

Widget _buildEmptyState(BuildContext context) {
  return SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor), right: BorderSide(color: Theme.of(context).dividerColor), bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.all(32.0),
      child: const Center(child: Text('No results found.', style: TextStyle(color: Colors.grey))),
    ),
  );
}

Widget _buildStatusBadge(String status) {
  Color color;
  switch (status) {
    case 'Completed':
    case 'Success':
    case 'Paid':
      color = Colors.green;
      break;
    case 'Pending':
      color = Colors.orange;
      break;
    case 'Failed':
    case 'Overdue':
      color = Colors.red;
      break;
    case 'Refunded':
      color = Colors.grey;
      break;
    default:
      color = Colors.grey;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 48.0});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
