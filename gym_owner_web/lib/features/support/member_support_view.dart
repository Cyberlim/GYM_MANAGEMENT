import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:gym_owner_web/features/support/providers/member_support_provider.dart';
import 'package:gym_owner_web/data/services/socket_service.dart';

class MemberSupportView extends ConsumerStatefulWidget {
  const MemberSupportView({super.key});

  @override
  ConsumerState<MemberSupportView> createState() => _MemberSupportViewState();
}

class _MemberSupportViewState extends ConsumerState<MemberSupportView> {
  String? _selectedMemberId;
  String? _selectedMemberName;

  void _backToList() {
    setState(() {
      _selectedMemberId = null;
      _selectedMemberName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return _MemberList(
            selectedId: _selectedMemberId,
            onSelect: (id, name) {
              ref.read(memberMessagesProvider.notifier).loadMessages(id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('Chat with $name'),
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      elevation: 0,
                    ),
                    body: _MemberChatArea(
                      memberId: id,
                      memberName: name,
                    ),
                  ),
                ),
              );
            },
          );
        }

        return Row(
          children: [
            // Member List
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
          ),
          child: _MemberList(
            selectedId: _selectedMemberId,
            onSelect: (id, name) {
              setState(() {
                _selectedMemberId = id;
                _selectedMemberName = name;
              });
              ref.read(memberMessagesProvider.notifier).loadMessages(id);
            },
          ),
        ),
        // Chat Area
        Expanded(
          child: _selectedMemberId == null
              ? Center(
                  child: Text('Select a member to view their support messages.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))))
              : _MemberChatArea(
                  memberId: _selectedMemberId!,
                  memberName: _selectedMemberName!,
                ),
        ),
      ],
    );
      },
    );
  }
}

class _MemberList extends ConsumerWidget {
  final String? selectedId;
  final Function(String, String) onSelect;

  const _MemberList({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(memberChatsProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No members have messaged yet.', textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ),
          );
        }
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final id = member['_id'];
            final isSelected = id == selectedId;
            return ListTile(
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                backgroundImage: member['imageUrl'] != null ? NetworkImage(member['imageUrl']) : null,
                child: member['imageUrl'] == null ? const Icon(LucideIcons.user, size: 20) : null,
              ),
              title: Text(member['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(member['email'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => onSelect(id, member['name'] ?? 'Unknown'),
            );
          },
        );
      },
    );
  }
}

class _MemberChatArea extends ConsumerStatefulWidget {
  final String memberId;
  final String memberName;

  const _MemberChatArea({required this.memberId, required this.memberName});

  @override
  ConsumerState<_MemberChatArea> createState() => _MemberChatAreaState();
}

class _MemberChatAreaState extends ConsumerState<_MemberChatArea> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    SocketService().onNewMemberSupportMessage = _handleNewMessage;
  }

  @override
  void dispose() {
    SocketService().onNewMemberSupportMessage = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNewMessage(dynamic data) {
    if (data is Map<String, dynamic> || data != null) {
      final msgData = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);
      ref.read(memberMessagesProvider.notifier).receiveMessage(msgData);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(msgDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref.read(memberMessagesProvider.notifier).sendMessage(widget.memberId, content);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(memberMessagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat with ${widget.memberName}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Resolve member issues directly. Note: Messages are automatically deleted after 1 month.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
        ),
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (messages) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              if (messages.isEmpty) {
                return Center(
                    child: Text('No messages.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))));
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderRole'] == 'gym_owner';
                  final time = msg['createdAt'] != null ? DateFormat('hh:mm a').format(DateTime.parse(msg['createdAt']).toLocal()) : '';
                  final msgDate = msg['createdAt'] != null ? DateTime.parse(msg['createdAt']).toLocal() : DateTime.now();

                  bool showDateDivider = false;
                  if (index == 0) {
                    showDateDivider = true;
                  } else {
                    final prevMsg = messages[index - 1];
                    final prevDateStr = prevMsg['createdAt'];
                    final prevDate = prevDateStr != null ? DateTime.parse(prevDateStr).toLocal() : DateTime.now();
                    final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
                    final currDay = DateTime(msgDate.year, msgDate.month, msgDate.day);
                    showDateDivider = prevDay != currDay;
                  }

                  final messageBubble = Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg['message'] ?? '',
                                  style: TextStyle(color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(time,
                                  style: TextStyle(
                                      color: isMe ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  if (showDateDivider) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDateDivider(msgDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        messageBubble,
                      ],
                    );
                  }

                  return messageBubble;
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
