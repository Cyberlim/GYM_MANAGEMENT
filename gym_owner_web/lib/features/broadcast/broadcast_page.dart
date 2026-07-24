import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';
import 'package:gym_owner_web/features/broadcast/providers/broadcast_provider.dart';
import 'package:intl/intl.dart';

class BroadcastPage extends ConsumerStatefulWidget {
  const BroadcastPage({super.key});

  @override
  ConsumerState<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends ConsumerState<BroadcastPage> {
  String? _selectedBroadcastId;
  bool _isCreatingNew = false;
  
  // form state
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  Set<String> _selectedMemberIds = {};
  bool _selectAll = true;
  bool _isSending = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      setState(() => _error = 'Please fill out both subject and message.');
      return;
    }

    if (!_selectAll && _selectedMemberIds.isEmpty) {
      setState(() => _error = 'Please select at least one member or choose "Send to all active members".');
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
      _success = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/notifications/broadcast', {
        'subject': subject,
        'message': message,
        if (!_selectAll) 'memberIds': _selectedMemberIds.toList(),
      });

      setState(() {
        _success = 'Broadcast sent successfully.';
        _subjectController.clear();
        _messageController.clear();
        _selectAll = true;
        _selectedMemberIds.clear();
        _isCreatingNew = false;
      });
      ref.invalidate(broadcastsProvider);
    } catch (e) {
      setState(() => _error = 'Failed to send broadcast: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showDetailsOrNew() {
    setState(() {});
  }

  void _backToList() {
    setState(() {
      _selectedBroadcastId = null;
      _isCreatingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          // Single pane view for mobile/tablet
          final showDetails = _isCreatingNew || _selectedBroadcastId != null;
          return showDetails ? _buildRightPane(isMobile: true) : _buildBroadcastList(isMobile: true);
        }

        // Two pane view for desktop
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: _buildBroadcastList(isMobile: false),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: _buildRightPane(isMobile: false),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBroadcastList({required bool isMobile}) {
    final broadcastsAsync = ref.watch(broadcastsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Broadcasts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isCreatingNew = true;
                    _selectedBroadcastId = null;
                    _error = null;
                    _success = null;
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: broadcastsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: theme.colorScheme.error))),
            data: (broadcasts) {
              if (broadcasts.isEmpty) {
                return const Center(child: Text('No broadcasts sent yet.', style: TextStyle(color: Colors.grey)));
              }
              return ListView.separated(
                itemCount: broadcasts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final b = broadcasts[index];
                  final isSelected = _selectedBroadcastId == b.id && !_isCreatingNew;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    title: Text(
                      b.subject,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(b.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedBroadcastId = b.id;
                        _isCreatingNew = false;
                        _error = null;
                        _success = null;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRightPane({required bool isMobile}) {
    if (_isCreatingNew) {
      return _buildNewBroadcastForm(isMobile: isMobile);
    }
    
    if (_selectedBroadcastId != null) {
      return _buildBroadcastDetails(_selectedBroadcastId!, isMobile: isMobile);
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.radio, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Select a broadcast to view details', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNewBroadcastForm({required bool isMobile}) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: _backToList,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          const Text('Send New Broadcast', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Send a notification to all active gym members', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                ],
              ),
            ),

          if (_success != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                ],
              ),
            ),

          const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              hintText: 'e.g. Gym closure on holidays',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Enter your broadcast message here...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMemberSelection(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendBroadcast,
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.send, size: 18),
              label: Text(_isSending ? 'Sending...' : 'Send Broadcast'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelection() {
    final membersAsync = ref.watch(membersProvider);
    return membersAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error loading members: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
      data: (members) {
        final activeMembers = members.where((m) => m.status == 'Active').toList();
        if (activeMembers.isEmpty) return const Text('No active members available.');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Send to all active members', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _selectAll,
              onChanged: (val) {
                setState(() {
                  _selectAll = val ?? true;
                  if (_selectAll) _selectedMemberIds.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_selectAll) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeMembers.length,
                  itemBuilder: (context, index) {
                    final member = activeMembers[index];
                    final isSelected = _selectedMemberIds.contains(member.id);
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                            child: member.imageUrl == null ? Text(member.name.substring(0, 1).toUpperCase()) : null,
                          ),
                          const SizedBox(width: 12),
                          Text(member.name),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedMemberIds.add(member.id);
                          } else {
                            _selectedMemberIds.remove(member.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ]
          ],
        );
      },
    );
  }

  Widget _buildBroadcastDetails(String id, {required bool isMobile}) {
    final detailsAsync = ref.watch(broadcastDetailsProvider(id));
    final theme = Theme.of(context);

    return detailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: theme.colorScheme.error))),
      data: (details) {
        final b = details.broadcast;
        final receipts = details.receipts;
        
        final readCount = receipts.where((r) => r.isRead).length;
        final totalCount = receipts.length;
        final readPercent = totalCount == 0 ? 0 : (readCount / totalCount * 100).round();

        return Column(
          children: [
            // Details Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: _backToList,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  Text(b.subject, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Sent on ${DateFormat('MMMM d, yyyy • h:mm a').format(b.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(b.message, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ),
                ],
              ),
            ),
            
            // Receipts List
            Expanded(
              child: receipts.isEmpty
                ? const Center(child: Text('No recipients found.', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: receipts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      final member = receipt.member;
                      final name = member['name'] ?? 'Unknown Member';
                      final profilePic = member['imageUrl'];
                      
                      return ListTile(
                        tileColor: receipt.isRead ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.02),
                        leading: CircleAvatar(
                          backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                          child: profilePic == null ? Text(name.substring(0, 1).toUpperCase()) : null,
                        ),
                        title: Text(name, style: TextStyle(
                          color: receipt.isRead ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: receipt.isRead ? FontWeight.w500 : FontWeight.normal,
                        )),
                        trailing: receipt.isRead
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.checkCheck, color: Colors.green, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Seen', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(receipt.readAt!),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.eyeOff, color: Colors.grey[400], size: 16),
                                  const SizedBox(width: 4),
                                  Text('Not seen', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}
