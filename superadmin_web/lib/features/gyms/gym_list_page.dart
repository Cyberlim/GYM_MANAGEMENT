import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/highlighted_text.dart';
import '../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/superadmin_provider.dart';

class GymListPage extends ConsumerStatefulWidget {
  final String? initialPlan;
  final bool showBackButton;
  
  const GymListPage({super.key, this.initialPlan, this.showBackButton = false});

  @override
  ConsumerState<GymListPage> createState() => _GymListPageState();
}

class _GymListPageState extends ConsumerState<GymListPage> {
  String _searchQuery = '';
  String _selectedPlan = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null) {
      _selectedPlan = widget.initialPlan!;
    }
  }



  void _showAddGymOwnerDialog() {
    final gymNameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final locationController = TextEditingController();
    final emailController = TextEditingController();
    String selectedPlan = 'Basic';
    String selectedStatus = 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Gym Owner', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: gymNameController,
                        decoration: InputDecoration(labelText: 'Gym Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ownerNameController,
                        decoration: InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(labelText: 'Location (City, State)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPlan,
                        decoration: InputDecoration(labelText: 'Subscription Plan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: ['Basic', 'Pro', 'Enterprise'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setDialogState(() => selectedPlan = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(labelText: 'Account Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: ['Active', 'Pending', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setDialogState(() => selectedStatus = v!),
                      ),
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
                    final newGym = {
                      'initials': gymNameController.text.isNotEmpty 
                          ? (gymNameController.text.length > 1 ? gymNameController.text.substring(0, 2) : gymNameController.text).toUpperCase() 
                          : 'G',
                      'gymName': gymNameController.text.isEmpty ? 'New Gym' : gymNameController.text,
                      'ownerName': ownerNameController.text.isEmpty ? 'New Owner' : ownerNameController.text,
                      'location': locationController.text.isEmpty ? 'Unknown' : locationController.text,
                      'email': emailController.text.isEmpty ? 'email@example.com' : emailController.text,
                      'plan': selectedPlan,
                      'status': selectedStatus,
                      'revenue': '\$0',
                    };
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding gyms to database is not implemented yet.')));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Add Owner'),
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
    final gymsAsync = ref.watch(superadminGymsProvider);

    return gymsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading gyms: $err')),
      data: (gyms) {
        final query = _searchQuery.toLowerCase();
        final filteredGyms = gyms.where((gym) {
          if (_selectedPlan != 'All' && gym['plan'] != _selectedPlan) return false;
          if (_selectedStatus != 'All' && gym['status'] != _selectedStatus) return false;
          
          if (query.isEmpty) return true;
          final gymName = gym['gymName'].toString().toLowerCase();
          final ownerName = gym['ownerName'].toString().toLowerCase();
          
          final gymMatches = gymName.split(' ').any((word) => word.startsWith(query));
          final ownerMatches = ownerName.split(' ').any((word) => word.startsWith(query));
          return gymMatches || ownerMatches;
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1000;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showBackButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => context.pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.arrowLeft, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Back to Subscriptions', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                    ),
                  // Header Row
                  Row(
                    children: [
                      if (!widget.showBackButton && context.canPop()) ...[
                        IconButton(
                          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.showBackButton ? '${widget.initialPlan ?? 'Plan'} Subscribers' : 'Gym Owners',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.showBackButton 
                        ? 'View all gym owners currently subscribed to this plan.'
                        : 'Manage and monitor all gym accounts across the platform.',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              ),
            ),
            if (!isMobile)
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Matches main layout background
                toolbarHeight: 80, // Action bar + padding
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Action Bar
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
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  decoration: InputDecoration(
                                    hintText: 'Search gyms or owners...',
                                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                                    prefixIcon: Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildDropdown('Status', _selectedStatus, ['All', 'Active', 'Pending', 'Suspended'], (val) => setState(() => _selectedStatus = val!)),
                              if (!widget.showBackButton) ...[
                                const SizedBox(width: 12),
                                _buildDropdown('Plan', _selectedPlan, ['All', 'Basic', 'Pro', 'Enterprise'], (val) => setState(() => _selectedPlan = val!)),
                              ],
                            ],
                          ),
                          if (!widget.showBackButton)
                            ElevatedButton.icon(
                              onPressed: _showAddGymOwnerDialog,
                              icon: Icon(LucideIcons.plus, size: 16),
                              label: Text('Add Gym Owner', style: TextStyle(fontWeight: FontWeight.bold)),
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
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 300,
                            height: 40,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search gyms or owners...',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                                prefixIcon: Icon(LucideIcons.search, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                ),
                              ),
                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                          _buildDropdown('Status', _selectedStatus, ['All', 'Active', 'Pending', 'Suspended'], (val) => setState(() => _selectedStatus = val!)),
                          if (!widget.showBackButton)
                            _buildDropdown('Plan', _selectedPlan, ['All', 'Basic', 'Pro', 'Enterprise'], (val) => setState(() => _selectedPlan = val!)),
                        ],
                      ),
                      if (!widget.showBackButton)
                        ElevatedButton.icon(
                          onPressed: _showAddGymOwnerDialog,
                          icon: Icon(LucideIcons.plus, size: 16),
                          label: Text('Add Gym Owner', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ),

            // TABLE DESKTOP
            if (!isMobile) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                        left: BorderSide(color: Colors.grey.withOpacity(0.1)),
                        right: BorderSide(color: Colors.grey.withOpacity(0.1)),
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('GYM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5))),
                        Expanded(flex: 3, child: Text('OWNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5))),
                        Expanded(flex: 1, child: Center(child: Text('PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5)))),
                        Expanded(flex: 1, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5)))),
                        Expanded(flex: 2, child: Align(alignment: Alignment.center, child: Text('REVENUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5)))),
                        SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.5), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              ),
              if (filteredGyms.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      border: Border(
                        left: BorderSide(color: Theme.of(context).dividerColor!),
                        right: BorderSide(color: Theme.of(context).dividerColor!),
                        bottom: BorderSide(color: Theme.of(context).dividerColor!),
                      ),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: const Center(child: Text('No gyms found matching your search.', style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final gym = filteredGyms[index];
                      final isLast = index == filteredGyms.length - 1;
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: isLast ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : null,
                          border: Border(
                            left: BorderSide(color: Colors.grey.withOpacity(0.1)),
                            right: BorderSide(color: Colors.grey.withOpacity(0.1)),
                            bottom: isLast ? BorderSide(color: Colors.grey.withOpacity(0.1)) : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTableRow(
                              context, 
                              gym['id'].toString(),
                              gym['initials'] ?? 'G', 
                              gym['gymName'] ?? 'Unknown', 
                              gym['location'] ?? 'Unknown', 
                              gym['ownerName'] ?? 'Unknown', 
                              gym['email'] ?? 'Unknown', 
                              gym['plan'] ?? 'Basic', 
                              gym['status'] ?? 'Pending', 
                              gym['revenue'] ?? '0', 
                              _searchQuery,
                            ),
                            if (!isLast) Divider(height: 1),
                          ],
                        ),
                      );
                    },
                    childCount: filteredGyms.length,
                  ),
                ),
            ] else ...[
              // MOBILE CARDS
              if (filteredGyms.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    child: const Center(child: Text('No gyms found matching your search.', style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final gym = filteredGyms[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _buildMobileCard(context, gym),
                      );
                    },
                    childCount: filteredGyms.length,
                  ),
                ),
            ]
          ],
        );
      },
    );
      },
    );
  }


  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('$label: $value', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
          icon: Icon(LucideIcons.chevronDown, size: 16),
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          onChanged: onChanged,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, String id, String initials, String gymName, String location, String ownerName, String email, String plan, String status, String revenue, String searchQuery, {Color? avatarColor, Color? avatarText}) {
    Color planBg;
    Color planText;
    final normalizedPlan = plan.replaceAll(' Plan', '').toLowerCase();
    if (normalizedPlan == 'pro') {
      planBg = const Color(0xFFD3E2FF);
      planText = const Color(0xFF0055FF);
    } else if (normalizedPlan == 'enterprise') {
      planBg = const Color(0xFFE0E7FF);
      planText = const Color(0xFF4338CA);
    } else if (normalizedPlan == 'basic') {
      planBg = const Color(0xFFF3E8FF);
      planText = const Color(0xFF7E22CE);
    } else {
      final palettes = [
        [const Color(0xFFFEF3C7), const Color(0xFFB45309)], // Amber
        [const Color(0xFFD1FAE5), const Color(0xFF047857)], // Emerald
        [const Color(0xFFFFE4E6), const Color(0xFFBE123C)], // Rose
        [const Color(0xFFE0F2FE), const Color(0xFF0369A1)], // Sky
        [const Color(0xFFFCE7F3), const Color(0xFFBE185D)], // Pink
      ];
      final hash = plan.hashCode.abs();
      final palette = palettes[hash % palettes.length];
      planBg = palette[0];
      planText = palette[1];
    }

    Color statusColor;
    Color statusBg;
    if (status == 'Active') {
      statusColor = Colors.green;
      statusBg = Colors.green.withOpacity(0.1);
    } else if (status == 'Pending') {
      statusColor = Colors.orange;
      statusBg = Colors.orange.withOpacity(0.1);
    } else {
      statusColor = Colors.red;
      statusBg = Colors.red.withOpacity(0.1);
    }

    return InkWell(
      onTap: () {
        context.go('/gyms/${Uri.encodeComponent(id)}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedText(text: gymName, query: searchQuery, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(location, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    child: Icon(LucideIcons.user, size: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedText(text: ownerName, query: searchQuery, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      Text(email, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: planBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(plan, style: TextStyle(color: planText, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(revenue, style: TextStyle(fontFamily: 'Courier', fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
              ),
            ),
            const SizedBox(width: 80, child: Align(alignment: Alignment.center, child: Icon(LucideIcons.moreHorizontal, size: 20))),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(String label, {bool isOutlined = false, bool isActive = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: label.length > 2 ? 12 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0055FF) : Theme.of(context).colorScheme.surface,
        border: Border.all(color: isActive ? const Color(0xFF0055FF) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  Widget _buildMobileCard(BuildContext context, Map<String, dynamic> gym) {
    Color planBg;
    Color planText;
    final plan = gym['plan'] ?? 'Basic';
    final normalizedPlan = plan.replaceAll(' Plan', '').toLowerCase();
    if (normalizedPlan == 'pro') {
      planBg = const Color(0xFFD3E2FF);
      planText = const Color(0xFF0055FF);
    } else if (normalizedPlan == 'enterprise') {
      planBg = const Color(0xFFE0E7FF);
      planText = const Color(0xFF4338CA);
    } else if (normalizedPlan == 'basic') {
      planBg = const Color(0xFFF3E8FF);
      planText = const Color(0xFF7E22CE);
    } else {
      planBg = const Color(0xFFFEF3C7);
      planText = const Color(0xFFB45309);
    }

    final status = gym['status'] ?? 'Pending';
    Color statusColor = status == 'Active' ? Colors.green : (status == 'Pending' ? Colors.orange : Colors.red);

    return InkWell(
      onTap: () {
        context.go('/gyms/${Uri.encodeComponent(gym['id'].toString())}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(gym['initials'] ?? 'G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gym['gymName'] ?? 'Unknown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(gym['ownerName'] ?? 'Unknown', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: planBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(plan, style: TextStyle(fontSize: 12, color: planText, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 4),
                    Text(gym['revenue'] ?? '0', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                        const SizedBox(width: 6),
                        Text(status, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
