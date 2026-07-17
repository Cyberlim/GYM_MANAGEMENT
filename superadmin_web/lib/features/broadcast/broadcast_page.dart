import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import 'broadcast_provider.dart';

class BroadcastPage extends ConsumerStatefulWidget {
  const BroadcastPage({super.key});

  @override
  ConsumerState<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends ConsumerState<BroadcastPage> with SingleTickerProviderStateMixin {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  
  bool _selectAll = true;
  Set<String> _selectedGymIds = {};
  List<GymOwnerSelection> _allGymOwners = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  List<GymOwnerSelection> get _filteredGymOwners {
    if (_searchController.text.isEmpty) return _allGymOwners;
    final q = _searchController.text.toLowerCase();
    return _allGymOwners.where((g) => g.ownerName.toLowerCase().contains(q) || g.gymName.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final owners = await ref.read(broadcastProvider.notifier).fetchGymOwners();
    setState(() {
      _allGymOwners = owners;
      _selectedGymIds = owners.map((g) => g.id).toSet();
      _isLoading = false;
    });
  }

  void _selectAllGyms() {
    setState(() {
      _selectedGymIds = _allGymOwners.map((g) => g.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedGymIds.clear();
    });
  }

  Future<void> _handleSend() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a subject and message')));
      return;
    }
    if (_selectedGymIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one recipient')));
      return;
    }
    
    final success = await ref.read(broadcastProvider.notifier).sendBroadcast(
      _subjectController.text,
      _messageController.text,
      _selectedGymIds.toList()
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Broadcast sent to ${_selectedGymIds.length} recipients successfully!'),
        backgroundColor: Colors.green,
      ));
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectAll = true;
        _selectAllGyms();
      });
      _tabController.animateTo(1); // switch to history tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send broadcast')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Text('Broadcast Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Compose'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(),
          const _BroadcastHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildComposeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildComposeSection(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildRecipientsSection(),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildComposeSection(),
              const SizedBox(height: 24),
              _buildRecipientsSection(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildComposeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compose Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 24),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. New Feature Update: Advanced Analytics',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(LucideIcons.type, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _messageController,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: 'Message Body',
              hintText: 'Type your broadcast message here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSend,
              icon: const Icon(LucideIcons.send, size: 18),
              label: const Text('Send Broadcast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: Theme.of(context).brightness == Brightness.dark ? 8 : 2,
                shadowColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.primaryColor.withValues(alpha: 0.6) : null,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recipients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_selectedGymIds.length} Selected', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Select All Gym Owners', style: TextStyle(fontWeight: FontWeight.bold)),
            value: _selectAll,
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                _selectAll = val ?? false;
                if (_selectAll) {
                  _selectAllGyms();
                } else {
                  _clearSelection();
                }
              });
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search gym owners...',
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400, // Fixed height for scrollable list
            child: ListView.builder(
              itemCount: _filteredGymOwners.length,
              itemBuilder: (context, index) {
                final gym = _filteredGymOwners[index];
                final isSelected = _selectedGymIds.contains(gym.id);
                return CheckboxListTile(
                  title: Text(gym.ownerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(gym.gymName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  value: isSelected,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedGymIds.add(gym.id);
                      } else {
                        _selectedGymIds.remove(gym.id);
                      }
                      _selectAll = _selectedGymIds.length == _allGymOwners.length;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastHistoryTab extends ConsumerStatefulWidget {
  const _BroadcastHistoryTab();

  @override
  ConsumerState<_BroadcastHistoryTab> createState() => _BroadcastHistoryTabState();
}

class _BroadcastHistoryTabState extends ConsumerState<_BroadcastHistoryTab> {
  List<BroadcastHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ref.read(broadcastProvider.notifier).fetchBroadcastHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  void _showStatusDialog(BroadcastHistoryItem item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final statusList = await ref.read(broadcastProvider.notifier).fetchBroadcastStatus(item.id);
    
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status: ${item.subject}'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: statusList.length,
            itemBuilder: (context, index) {
              final status = statusList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: status.isRead ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  child: Icon(
                    status.isRead ? LucideIcons.checkCheck : LucideIcons.clock,
                    color: status.isRead ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                ),
                title: Text(status.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(status.gymName),
                trailing: Text(
                  status.isRead ? 'Seen' : 'Unseen',
                  style: TextStyle(
                    color: status.isRead ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const Center(child: Text('No broadcast messages sent yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Sent on: ${item.sentAt.toLocal().toString().split('.')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Recipients: ${item.recipients.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => _showStatusDialog(item),
                icon: const Icon(LucideIcons.barChart, size: 16),
                label: const Text('View Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
