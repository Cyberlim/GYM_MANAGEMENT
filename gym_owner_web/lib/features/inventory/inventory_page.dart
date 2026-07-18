import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_owner_web/features/inventory/providers/inventory_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:go_router/go_router.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredInventoryProvider);
    final allInventoryAsync = ref.watch(inventoryProvider);
    final currentFilter = ref.watch(inventoryFilterProvider);
    final highlightId = GoRouterState.of(context).uri.queryParameters['highlightId'];
    
    // Calculate dashboard metrics
    final totalItems = allInventoryAsync.maybeWhen(data: (items) => items.fold(0, (sum, item) => sum + item.quantity), orElse: () => 0);
    final totalValue = allInventoryAsync.maybeWhen(data: (items) => items.fold(0.0, (sum, item) => sum + (item.purchasePrice * item.quantity)), orElse: () => 0.0);
    final lowStockCount = allInventoryAsync.maybeWhen(data: (items) => items.where((item) => item.status == 'Low Stock' || item.status == 'Out of Stock').length, orElse: () => 0);
    final expiredCount = allInventoryAsync.maybeWhen(data: (items) => items.where((item) => item.status == 'Expired').length, orElse: () => 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
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
                        'Inventory Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track equipment, supplements, and merchandise',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddInventoryDialog(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add Item'),
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
            const SizedBox(height: 32),

            // Dashboard Cards
            Consumer(
              builder: (context, ref, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Total Items',
                              value: totalItems.toString(),
                              icon: LucideIcons.packageOpen,
                              color: Colors.blue,
                              isSelected: currentFilter.status == 'All',
                              onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Total Value',
                              value: '₹${NumberFormat('#,##0.00').format(totalValue)}',
                              icon: LucideIcons.indianRupee,
                              color: Colors.green,
                              isSelected: false,
                              onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Low Stock',
                              value: lowStockCount.toString(),
                              icon: LucideIcons.alertTriangle,
                              color: Colors.orange,
                              isSelected: currentFilter.status == 'Low Stock',
                              onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('Low Stock'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Expired',
                              value: expiredCount.toString(),
                              icon: LucideIcons.alertOctagon,
                              color: Colors.red,
                              isSelected: currentFilter.status == 'Expired',
                              onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('Expired'),
                            ),
                          ),
                        ],
                      );
                    }

                    final isMobile = constraints.maxWidth < 500;
                    final cardWidth = isMobile ? (constraints.maxWidth - 16) / 2 : 200.0;
                    
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Items',
                            value: totalItems.toString(),
                            icon: LucideIcons.packageOpen,
                            color: Colors.blue,
                            isSelected: currentFilter.status == 'All',
                            onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('All'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Total Value',
                            value: '₹${NumberFormat('#,##0.00').format(totalValue)}',
                            icon: LucideIcons.indianRupee,
                            color: Colors.green,
                            isSelected: false, // Total Value isn't really a filter, but we could make it 'All'
                            onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('All'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Low Stock',
                            value: lowStockCount.toString(),
                            icon: LucideIcons.alertTriangle,
                            color: Colors.orange,
                            isSelected: currentFilter.status == 'Low Stock',
                            onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('Low Stock'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Expired',
                            value: expiredCount.toString(),
                            icon: LucideIcons.alertOctagon,
                            color: Colors.red,
                            isSelected: currentFilter.status == 'Expired',
                            onTap: () => ref.read(inventoryFilterProvider.notifier).setStatus('Expired'),
                          ),
                        ),
                      ],
                    );
                  }
                );
              },
            ),
            const SizedBox(height: 32),

            // Search Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                final searchField = TextField(
                  onChanged: (value) => ref.read(inventorySearchQueryProvider.notifier).updateQuery(value),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                );

                return Row(
                  children: [
                    isDesktop ? SizedBox(width: 300, child: searchField) : Expanded(child: searchField),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentFilter.category,
                          icon: const Icon(LucideIcons.filter, size: 16),
                          hint: const Text('Category'),
                          items: ['All', 'Supplements', 'Merchandise', 'Beverages', 'Accessories', 'Snacks', 'Other']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type == 'All' ? 'All Categories' : type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(inventoryFilterProvider.notifier).setCategory(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 24),

            // Inventory List
            LayoutBuilder(
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
                      child: inventoryAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text('Error: $error')),
                        ),
                        data: (inventory) => inventory.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: Text('No inventory items found.')),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: inventory.length,
                                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.2), height: 1),
                                itemBuilder: (context, index) {
                                  final item = inventory[index];
                                  final isHighlighted = item.id == highlightId;
                                  return _InventoryRow(item: item, isHighlighted: isHighlighted);
                                },
                              ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInventoryDialog(BuildContext context, WidgetRef ref, [InventoryItem? itemToEdit]) {
    showDialog(
      context: context,
      builder: (context) => _AddInventoryDialog(itemToEdit: itemToEdit),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(0.1) 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? color.withOpacity(0.5) 
                  : Theme.of(context).dividerColor.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 200;
              
              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }

              return Row(
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
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InventoryRow extends ConsumerWidget {
  final InventoryItem item;
  final bool isHighlighted;

  const _InventoryRow({required this.item, this.isHighlighted = false});

  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'Good':
        return Colors.green;
      case 'Needs Repair':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Supplements':
      case 'Nutrition':
        return LucideIcons.flaskConical;
      case 'Beverages':
        return LucideIcons.coffee;
      case 'Merchandise':
        return LucideIcons.shirt;
      case 'Cleaning Supplies':
        return LucideIcons.sprayCan;
      case 'Office Supplies':
        return LucideIcons.paperclip;
      case 'Accessories':
        return LucideIcons.dumbbell;
      case 'Snacks':
        return LucideIcons.apple;
      default:
        return LucideIcons.packageOpen;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(item.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _InventoryDetailsDialog(item: item),
          );
        },
        child: Container(
          color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(item.category), color: Theme.of(context).colorScheme.primary),
              ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quantity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('${item.quantity} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Purchase Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('₹${item.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expiry Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(item.expiryDate != null ? DateFormat('MMM dd, yyyy').format(item.expiryDate!) : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withOpacity(0.2) : statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: statusColor.withOpacity(0.5)) : null,
                ),
                child: Text(
                  item.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? statusColor.shade300 : statusColor.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            onSelected: (value) {
              if (value == 'edit') {
                final parent = context.findAncestorStateOfType<ConsumerState<InventoryPage>>();
                if (parent == null) {
                  // Alternative if context doesn't find the state, since InventoryPage is ConsumerWidget, not Stateful.
                  showDialog(
                    context: context,
                    builder: (context) => _AddInventoryDialog(itemToEdit: item),
                  );
                }
              } else if (value == 'delete') {
                ref.read(inventoryProvider.notifier).removeItem(item.id);
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
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _AddInventoryDialog extends ConsumerStatefulWidget {
  final InventoryItem? itemToEdit;

  const _AddInventoryDialog({this.itemToEdit});

  @override
  ConsumerState<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends ConsumerState<_AddInventoryDialog> {
  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final supplierController = TextEditingController();
  final minStockController = TextEditingController();
  
  String selectedCategory = 'Supplements';
  String selectedUnit = 'Piece';
  DateTime? purchaseDate;
  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      itemNameController.text = widget.itemToEdit!.itemName;
      quantityController.text = widget.itemToEdit!.quantity.toString();
      purchasePriceController.text = widget.itemToEdit!.purchasePrice.toString();
      sellingPriceController.text = widget.itemToEdit!.sellingPrice?.toString() ?? '';
      supplierController.text = widget.itemToEdit!.supplier ?? '';
      minStockController.text = widget.itemToEdit!.minimumStock?.toString() ?? '';
      selectedCategory = widget.itemToEdit!.category;
      selectedUnit = widget.itemToEdit!.unit;
      purchaseDate = widget.itemToEdit!.purchaseDate;
      expiryDate = widget.itemToEdit!.expiryDate;
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    supplierController.dispose();
    minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.itemToEdit == null ? 'Add Inventory Item' : 'Edit Inventory Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                prefixIcon: const Icon(LucideIcons.type),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(LucideIcons.tag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Supplements', 'Beverages', 'Merchandise', 'Cleaning Supplies', 'Office Supplies', 'Accessories', 'Nutrition', 'Snacks', 'Miscellaneous']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      prefixIcon: const Icon(LucideIcons.box),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Box', 'Bottle', 'Piece']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(LucideIcons.hash),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minimum Stock',
                      prefixIcon: const Icon(LucideIcons.alertTriangle),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: purchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Purchase Price / Unit',
                      prefixIcon: const Icon(LucideIcons.indianRupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: sellingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Selling Price / Unit (Optional)',
                      prefixIcon: const Icon(LucideIcons.indianRupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: purchaseDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => purchaseDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Purchase Date (Optional)',
                        prefixIcon: const Icon(LucideIcons.calendar),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(purchaseDate != null ? '${purchaseDate!.day}/${purchaseDate!.month}/${purchaseDate!.year}' : 'Select Date'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: expiryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => expiryDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        prefixIcon: const Icon(LucideIcons.calendarClock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(expiryDate != null ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}' : 'Select Date'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (itemNameController.text.isNotEmpty && quantityController.text.isNotEmpty && purchasePriceController.text.isNotEmpty) {
                    final newItem = InventoryItem(
                      id: widget.itemToEdit?.id ?? const Uuid().v4(),
                      itemName: itemNameController.text,
                      category: selectedCategory,
                      quantity: int.tryParse(quantityController.text) ?? 0,
                      unit: selectedUnit,
                      purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                      sellingPrice: double.tryParse(sellingPriceController.text),
                      supplier: supplierController.text.isEmpty ? null : supplierController.text,
                      minimumStock: int.tryParse(minStockController.text),
                      purchaseDate: purchaseDate,
                      expiryDate: expiryDate,
                    );
                    if (widget.itemToEdit == null) {
                      ref.read(inventoryProvider.notifier).addItem(newItem);
                    } else {
                      ref.read(inventoryProvider.notifier).updateItem(newItem);
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.itemToEdit == null ? 'Add Item' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDetailsDialog extends StatelessWidget {
  final InventoryItem item;
  
  const _InventoryDetailsDialog({required this.item});
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow('Item Name', item.itemName),
            _DetailRow('Category', item.category),
            _DetailRow('Quantity', '${item.quantity} ${item.unit}'),
            _DetailRow('Status', item.status),
            _DetailRow('Purchase Price', '₹${item.purchasePrice.toStringAsFixed(2)}'),
            if (item.sellingPrice != null) _DetailRow('Selling Price', '₹${item.sellingPrice!.toStringAsFixed(2)}'),
            if (item.supplier != null && item.supplier!.isNotEmpty) _DetailRow('Supplier', item.supplier!),
            if (item.purchaseDate != null) _DetailRow('Purchase Date', DateFormat('MMM dd, yyyy').format(item.purchaseDate!)),
            if (item.expiryDate != null) _DetailRow('Expiry Date', DateFormat('MMM dd, yyyy').format(item.expiryDate!)),
            if (item.minimumStock != null) _DetailRow('Minimum Stock', '${item.minimumStock}'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
