import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'support_provider.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportProvider);
    final selectedTicketId = ref.watch(selectedTicketIdProvider);
    
    final selectedTicket = tickets.where((t) => t.id == selectedTicketId).firstOrNull;

    Widget buildTicketList(bool isMobile) {
      return Container(
        width: isMobile ? double.infinity : 350,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: isMobile ? null : Border(right: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Text('Support Tickets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Text('${tickets.where((t) => t.status != TicketStatus.resolved).length} Open', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final isSelected = ticket.id == selectedTicketId;
                  
                  return InkWell(
                    onTap: () => ref.read(selectedTicketIdProvider.notifier).setTicketId(ticket.id),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: isSelected && !isMobile ? AppTheme.accentColor.withValues(alpha: 0.05) : Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(ticket.gymName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              Text(
                                DateFormat('MMM d').format(ticket.messages.last.timestamp),
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ticket.issueType, style: TextStyle(color: AppTheme.accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            ticket.messages.last.message,
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        if (isMobile) {
          if (selectedTicket == null) {
            return buildTicketList(true);
          } else {
            return _ChatView(ticket: selectedTicket, isMobile: true);
          }
        }
        
        return Row(
          children: [
            buildTicketList(false),
            Expanded(
              child: selectedTicket == null 
                ? const Center(child: Text('Select a ticket to view details'))
                : _ChatView(ticket: selectedTicket, isMobile: false),
            ),
          ],
        );
      },
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final SupportTicket ticket;
  final bool isMobile;
  const _ChatView({required this.ticket, this.isMobile = false});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void didUpdateWidget(covariant _ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.id != widget.ticket.id || widget.ticket.messages.length != oldWidget.ticket.messages.length) {
      _markAsRead();
    }
  }

  void _markAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ticket.messages.any((m) => !m.isRead)) {
        ref.read(supportProvider.notifier).markTicketAsRead(widget.ticket.id);
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(supportProvider.notifier).sendMessage(widget.ticket.id, _messageController.text.trim());
    _messageController.clear();
  }

  void _updateStatus(TicketStatus newStatus) {
    ref.read(supportProvider.notifier).updateTicketStatus(widget.ticket.id, newStatus);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 32, vertical: widget.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              if (widget.isMobile) ...[
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => ref.read(selectedTicketIdProvider.notifier).setTicketId(null),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (widget.ticket.gymId != null) {
                      context.go('/gyms/${widget.ticket.gymId}');
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: widget.isMobile ? 20 : 24,
                          backgroundColor: AppTheme.accentColor,
                          child: Text(widget.ticket.gymOwnerName.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.ticket.gymOwnerName, style: TextStyle(fontSize: widget.isMobile ? 16 : 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text('${widget.ticket.gymName} • ${widget.ticket.issueType}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: widget.isMobile ? 12 : 14), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<TicketStatus>(
                initialValue: widget.ticket.status,
                onSelected: _updateStatus,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: TicketStatus.open, child: Text('Mark as Open')),
                  const PopupMenuItem(value: TicketStatus.inProgress, child: Text('Mark as In Progress')),
                  const PopupMenuItem(value: TicketStatus.resolved, child: Text('Mark as Resolved')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: TicketStatus.open, 
                    child: const Text('Clear Chat', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      ref.read(supportProvider.notifier).clearChat(widget.ticket.id);
                    },
                  ),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.ticket.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _getStatusColor(widget.ticket.status))),
                        if (!widget.isMobile) const SizedBox(width: 8),
                        if (!widget.isMobile) Text(_getStatusText(widget.ticket.status), style: TextStyle(color: _getStatusColor(widget.ticket.status), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: _getStatusColor(widget.ticket.status)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Chat Messages
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(widget.isMobile ? 16 : 32),
            itemCount: widget.ticket.messages.length,
            itemBuilder: (context, index) {
              final msg = widget.ticket.messages[index];
              bool showDivider = false;
              if (index == 0) {
                showDivider = true;
              } else {
                final prevMsg = widget.ticket.messages[index - 1];
                final msgDate = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
                final prevMsgDate = DateTime(prevMsg.timestamp.year, prevMsg.timestamp.month, prevMsg.timestamp.day);
                if (msgDate != prevMsgDate) {
                  showDivider = true;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDivider)
                    _buildDateDivider(context, msg.timestamp),
                  _buildMessageBubble(context, msg),
                ],
              );
            },
          ),
        ),
        
        // Chat Input
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _messageController,
                  label: '',
                  hint: 'Type your reply...',
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isMe = message.isFromAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).dividerColor,
              child: Text(message.senderName.substring(0, 1), style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.accentColor : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
                border: isMe ? null : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 28), // padding replacement for avatar
        ],
      ),
    );
  }

  Widget _buildDateDivider(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(msgDate).inDays;

    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Yesterday';
    } else if (difference < 7) {
      dateStr = DateFormat('EEEE').format(date);
    } else {
      dateStr = DateFormat('EEEE, MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return Colors.orange;
      case TicketStatus.inProgress: return Colors.blue;
      case TicketStatus.resolved: return Colors.green;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return 'Open';
      case TicketStatus.inProgress: return 'In Progress';
      case TicketStatus.resolved: return 'Resolved';
    }
  }
}
