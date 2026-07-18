import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_web/features/expenses/providers/expenses_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  String _selectedFilter = 'All Time';
  DateTimeRange? _customDateRange;

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<ExpenseRecord> _applyDateFilter(List<ExpenseRecord> records) {
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
    final allExpensesAsync = ref.watch(expensesProvider);
    final highlightId = GoRouterState.of(context).uri.queryParameters['highlightId'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: allExpensesAsync.when(
        data: (allExpenses) {
          final expenses = _applyDateFilter(allExpenses);
          final sortedExpenses = List<ExpenseRecord>.from(expenses)..sort((a, b) => b.date.compareTo(a.date));
          final totalExpenses = expenses.where((e) => e.status == 'Paid').fold(0.0, (sum, e) => sum + e.amount);
          final pendingExpenses = expenses.where((e) => e.status == 'Pending').fold(0.0, (sum, e) => sum + e.amount);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage outgoing costs and overheads',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Total Expenses', amount: totalExpenses, icon: LucideIcons.trendingDown, color: Colors.redAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Pending Bills', amount: pendingExpenses, icon: LucideIcons.clock, color: Colors.orange)),
                    ],
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: 250, child: _StatCard(title: 'Total Expenses', amount: totalExpenses, icon: LucideIcons.trendingDown, color: Colors.redAccent)),
                    SizedBox(width: 250, child: _StatCard(title: 'Pending Bills', amount: pendingExpenses, icon: LucideIcons.clock, color: Colors.orange)),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final listWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
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
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
                              child: Row(
                                children: [
                                  const SizedBox(width: 56), // Icon placeholder
                                  Expanded(
                                    flex: 2,
                                    child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
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
                            Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: sortedExpenses.length,
                                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                                itemBuilder: (context, index) {
                                  final expense = sortedExpenses[index];
                                  final isHighlighted = expense.id == highlightId;
                                  return _ExpenseRow(expense: expense, isHighlighted: isHighlighted);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, stack) => Center(child: Text('Error loading expenses: $err')),
      ),
    );
  }
}

void _showAddExpenseDialog(BuildContext context, WidgetRef ref, [ExpenseRecord? expenseToEdit]) {
    String selectedCategory = expenseToEdit?.category ?? 'Rent';
    String selectedStatus = expenseToEdit?.status ?? 'Paid';
    String selectedCurrency = '₹';
    final titleController = TextEditingController(text: expenseToEdit?.title ?? '');
    final amountController = TextEditingController(text: expenseToEdit?.amount.toString() ?? '');
    DateTime selectedDate = expenseToEdit?.date ?? DateTime.now();

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
                        Text(expenseToEdit == null ? 'Add Expense' : 'Edit Expense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Electric Bill',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: ['Rent', 'Equipment', 'Salary', 'Utilities', 'Marketing'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => selectedCategory = val ?? 'Rent'),
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
                                items: ['Paid', 'Pending'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => selectedStatus = val ?? 'Paid'),
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
                          if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                            final newExpense = ExpenseRecord(
                              id: expenseToEdit?.id ?? const Uuid().v4(),
                              title: titleController.text,
                              amount: double.tryParse(amountController.text) ?? 0.0,
                              date: selectedDate,
                              category: selectedCategory,
                              status: selectedStatus,
                            );
                            if (expenseToEdit == null) {
                              ref.read(expensesProvider.notifier).addExpense(newExpense);
                            } else {
                              ref.read(expensesProvider.notifier).updateExpense(newExpense);
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Expense', style: TextStyle(color: Colors.white)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
              const SizedBox(height: 4),
              Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  final ExpenseRecord expense;
  final bool isHighlighted;

  const _ExpenseRow({required this.expense, this.isHighlighted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    IconData categoryIcon;
    Color categoryColor;

    switch (expense.category) {
      case 'Rent':
        categoryIcon = LucideIcons.home;
        categoryColor = Colors.blue;
        break;
      case 'Equipment':
        categoryIcon = LucideIcons.dumbbell;
        categoryColor = Colors.purple;
        break;
      case 'Salary':
        categoryIcon = LucideIcons.users;
        categoryColor = Colors.teal;
        break;
      case 'Utilities':
        categoryIcon = LucideIcons.zap;
        categoryColor = Colors.amber;
        break;
      case 'Marketing':
        categoryIcon = LucideIcons.megaphone;
        categoryColor = Colors.pink;
        break;
      default:
        categoryIcon = LucideIcons.tag;
        categoryColor = Colors.grey;
    }

    Color statusColor = expense.status == 'Paid' ? Colors.green : Colors.orange;
    IconData statusIcon = expense.status == 'Paid' ? LucideIcons.checkCircle2 : LucideIcons.clock;

    return Container(
      color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  expense.category,
                  style: TextStyle(
                    color: categoryColor,
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
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
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
                            expense.status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (DateTime.now().difference(expense.date).inDays <= (expense.status == 'Pending' ? 10 : 2))
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddExpenseDialog(context, ref, expense);
                } else if (value == 'delete') {
                  ref.read(expensesProvider.notifier).removeExpense(expense.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.edit2, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
