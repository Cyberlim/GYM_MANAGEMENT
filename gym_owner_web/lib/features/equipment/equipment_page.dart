import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_owner_web/features/equipment/providers/equipment_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:go_router/go_router.dart';

class EquipmentPage extends ConsumerWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(filteredEquipmentProvider);
    final allEquipmentAsync = ref.watch(equipmentProvider);
    final currentFilter = ref.watch(equipmentFilterProvider);
    final highlightId = GoRouterState.of(context).uri.queryParameters['highlightId'];
    
    // Calculate dashboard metrics
    final totalMachines = allEquipmentAsync.maybeWhen(data: (items) => items.length, orElse: () => 0);
    final activeCount = allEquipmentAsync.maybeWhen(data: (items) => items.where((e) => e.status == 'Active').length, orElse: () => 0);
    final maintenanceCount = allEquipmentAsync.maybeWhen(data: (items) => items.where((e) => e.status == 'Under Maintenance').length, orElse: () => 0);
    final brokenCount = allEquipmentAsync.maybeWhen(data: (items) => items.where((e) => e.status == 'Under Repair').length, orElse: () => 0);

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
                        'Equipment Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track machines, weights, and maintenance schedules',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEquipmentDialog(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add Equipment'),
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
                              title: 'Total Machines',
                              value: totalMachines.toString(),
                              icon: LucideIcons.dumbbell,
                              color: Colors.blue,
                              isSelected: currentFilter.status == 'All',
                              onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Active',
                              value: activeCount.toString(),
                              icon: LucideIcons.checkCircle,
                              color: Colors.green,
                              isSelected: currentFilter.status == 'Active',
                              onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Active'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Under Maintenance',
                              value: maintenanceCount.toString(),
                              icon: LucideIcons.wrench,
                              color: Colors.orange,
                              isSelected: currentFilter.status == 'Under Maintenance',
                              onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Under Maintenance'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Under Repair',
                              value: brokenCount.toString(),
                              icon: LucideIcons.alertOctagon,
                              color: Colors.red,
                              isSelected: currentFilter.status == 'Under Repair',
                              onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Under Repair'),
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
                            title: 'Total Machines',
                            value: totalMachines.toString(),
                            icon: LucideIcons.dumbbell,
                            color: Colors.blue,
                            isSelected: currentFilter.status == 'All',
                            onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('All'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Active',
                            value: activeCount.toString(),
                            icon: LucideIcons.checkCircle,
                            color: Colors.green,
                            isSelected: currentFilter.status == 'Active',
                            onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Active'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Under Maintenance',
                            value: maintenanceCount.toString(),
                            icon: LucideIcons.wrench,
                            color: Colors.orange,
                            isSelected: currentFilter.status == 'Under Maintenance',
                            onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Under Maintenance'),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _DashboardCard(
                            title: 'Under Repair',
                            value: brokenCount.toString(),
                            icon: LucideIcons.alertOctagon,
                            color: Colors.red,
                            isSelected: currentFilter.status == 'Under Repair',
                            onTap: () => ref.read(equipmentFilterProvider.notifier).setStatus('Under Repair'),
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
                  onChanged: (value) => ref.read(equipmentSearchQueryProvider.notifier).updateQuery(value),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search equipment or zone...',
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
                          value: currentFilter.equipmentType,
                          icon: const Icon(LucideIcons.filter, size: 16),
                          hint: const Text('Type'),
                          items: ['All', 'Cardio', 'Strength', 'Free Weights', 'Functional Training', 'Accessories', 'Recovery Equipment', 'Custom']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type == 'All' ? 'All Types' : type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(equipmentFilterProvider.notifier).setType(val);
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

            // Equipment List
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
                      child: equipmentAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text('Error: $error')),
                        ),
                        data: (equipment) => equipment.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: Text('No equipment found.')),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: equipment.length,
                                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.2), height: 1),
                                itemBuilder: (context, index) {
                                  final item = equipment[index];
                                  final isHighlighted = item.id == highlightId;
                                  return _EquipmentRow(item: item, isHighlighted: isHighlighted);
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
}
void _showAddEquipmentDialog(BuildContext context, WidgetRef ref, [Equipment? itemToEdit]) {
  showDialog(
    context: context,
    builder: (context) => _AddEquipmentDialog(itemToEdit: itemToEdit),
  );
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

class _EquipmentRow extends ConsumerWidget {
  final Equipment item;
  final bool isHighlighted;

  const _EquipmentRow({required this.item, this.isHighlighted = false});

  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Under Maintenance':
        return Colors.orange;
      case 'Out of Order':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Cardio':
        return LucideIcons.activity;
      case 'Strength':
        return LucideIcons.armchair;
      case 'Free Weights':
        return LucideIcons.dumbbell;
      case 'Functional Training':
        return LucideIcons.flame;
      case 'Accessories':
        return LucideIcons.boxes;
      case 'Recovery Equipment':
        return LucideIcons.heartPulse;
      default:
        return LucideIcons.settings;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(item.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            child: Icon(_getTypeIcon(item.equipmentType), color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.machineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(item.equipmentType, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Brand', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(item.brand, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                _showAddEquipmentDialog(context, ref, item);
              } else if (value == 'delete') {
                ref.read(equipmentProvider.notifier).removeEquipment(item.id);
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
    );
  }
}

class _AddEquipmentDialog extends ConsumerStatefulWidget {
  final Equipment? itemToEdit;

  const _AddEquipmentDialog({this.itemToEdit});

  @override
  ConsumerState<_AddEquipmentDialog> createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends ConsumerState<_AddEquipmentDialog> {
  final nameController = TextEditingController();
  final zoneController = TextEditingController();
  final brandController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final supplierController = TextEditingController();
  final serialNumberController = TextEditingController();
  final notesController = TextEditingController();
  final customTypeController = TextEditingController();
  
  final List<String> standardTypes = ['Cardio', 'Strength', 'Free Weights', 'Functional Training', 'Accessories', 'Recovery Equipment', 'Custom'];
  String selectedType = 'Cardio';
  String selectedStatus = 'Active';
  DateTime purchaseDate = DateTime.now();
  DateTime? warrantyExpiry;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      nameController.text = widget.itemToEdit!.machineName;
      zoneController.text = widget.itemToEdit!.location;
      brandController.text = widget.itemToEdit!.brand;
      purchasePriceController.text = widget.itemToEdit!.purchasePrice.toString();
      supplierController.text = widget.itemToEdit!.supplier ?? '';
      serialNumberController.text = widget.itemToEdit!.serialNumber ?? '';
      notesController.text = widget.itemToEdit!.notes ?? '';
      
      if (standardTypes.contains(widget.itemToEdit!.equipmentType)) {
        selectedType = widget.itemToEdit!.equipmentType;
      } else {
        selectedType = 'Custom';
        customTypeController.text = widget.itemToEdit!.equipmentType;
      }
      selectedStatus = widget.itemToEdit!.status;
      purchaseDate = widget.itemToEdit!.purchaseDate;
      warrantyExpiry = widget.itemToEdit!.warrantyExpiry;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    zoneController.dispose();
    brandController.dispose();
    purchasePriceController.dispose();
    supplierController.dispose();
    serialNumberController.dispose();
    notesController.dispose();
    customTypeController.dispose();
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
                  widget.itemToEdit == null ? 'Add Equipment' : 'Edit Equipment',
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
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Machine Name',
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
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      prefixIcon: const Icon(LucideIcons.tag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: standardTypes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(LucideIcons.activity),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Active', 'Under Maintenance', 'Under Repair', 'Damaged', 'Retired']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStatus = val);
                    },
                  ),
                ),
              ],
            ),
            if (selectedType == 'Custom') ...[
              const SizedBox(height: 24),
              TextField(
                controller: customTypeController,
                decoration: InputDecoration(
                  labelText: 'Custom Equipment Type',
                  prefixIcon: const Icon(LucideIcons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: const Icon(LucideIcons.award),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: purchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Purchase Price',
                      prefixIcon: const Icon(LucideIcons.indianRupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: zoneController,
              decoration: InputDecoration(
                labelText: 'Location / Zone (e.g. Cardio Section)',
                prefixIcon: const Icon(LucideIcons.mapPin),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && zoneController.text.isNotEmpty && brandController.text.isNotEmpty && purchasePriceController.text.isNotEmpty) {
                    final newItem = Equipment(
                      id: widget.itemToEdit?.id ?? const Uuid().v4(),
                      machineName: nameController.text,
                      equipmentType: selectedType == 'Custom' ? customTypeController.text : selectedType,
                      brand: brandController.text,
                      purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                      status: selectedStatus,
                      location: zoneController.text,
                      purchaseDate: purchaseDate,
                      warrantyExpiry: warrantyExpiry,
                      supplier: supplierController.text.isEmpty ? null : supplierController.text,
                      serialNumber: serialNumberController.text.isEmpty ? null : serialNumberController.text,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );
                    if (widget.itemToEdit == null) {
                      ref.read(equipmentProvider.notifier).addEquipment(newItem);
                    } else {
                      ref.read(equipmentProvider.notifier).updateEquipment(newItem);
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.itemToEdit == null ? 'Add Machine' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
