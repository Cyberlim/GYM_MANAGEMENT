import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gym_owner_web/features/support/providers/support_provider.dart';

class SuperadminSupportView extends ConsumerStatefulWidget {
  const SuperadminSupportView({super.key});

  @override
  ConsumerState<SuperadminSupportView> createState() => _SuperadminSupportViewState();
}

class _SuperadminSupportViewState extends ConsumerState<SuperadminSupportView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleQueryParameters();
      _scrollToBottom();
    });
  }

  void _handleQueryParameters() {
    final messageId = GoRouterState.of(context).uri.queryParameters['messageId'];
    if (messageId != null) {
      ref.read(supportMessagesProvider.notifier).markAsRead(messageId);
      // Clean up the URL
      context.go('/support');
    } else {
      ref.read(supportMessagesProvider.notifier).markAllAsRead();
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

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      ref.read(supportMessagesProvider.notifier).sendMessage(content);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(supportMessagesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Icon(LucideIcons.lifeBuoy, size: 28, color: Theme.of(context).colorScheme.primary),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Superadmin Support',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Text(
                        'Chat directly with our support team',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: messagesState.when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return Center(
                              child: Text(
                                'No support history available.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.isSentByMe;

                              bool showDateDivider = false;
                              if (index == 0) {
                                showDateDivider = true;
                              } else {
                                final prevMsg = messages[index - 1];
                                final prevDate = DateTime(prevMsg.timestamp.year, prevMsg.timestamp.month, prevMsg.timestamp.day);
                                final currDate = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
                                showDateDivider = prevDate != currDate;
                              }

                              final messageBubble = Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      child: Icon(LucideIcons.headphones, size: 16, color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
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
                                          Text(
                                            msg.content,
                                            style: TextStyle(
                                              color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            msg.time,
                                            style: TextStyle(
                                              color: isMe ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMe) const SizedBox(width: 24),
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
                                          _formatDateDivider(msg.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: messageBubble,
                                    ),
                                  ],
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: messageBubble,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(child: Text('Error loading messages', style: TextStyle(color: Colors.redAccent))),
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(LucideIcons.send, color: Theme.of(context).colorScheme.onPrimary),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
