import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/auth_provider.dart';

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  final res = await api.get('/notifications');
  return res as List<dynamic>;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllAsRead(WidgetRef ref) async {
    try {
      await ref.read(apiProvider).put('/notifications/read-all', {});
      ref.invalidate(notificationsProvider);
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  Future<void> _markAsRead(WidgetRef ref, String id) async {
    try {
      await ref.read(apiProvider).put('/notifications/$id/read', {});
      ref.invalidate(notificationsProvider);
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(ref),
          )
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellRing, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                width: double.infinity,
                color: Colors.orange.withValues(alpha: 0.1),
                child: const Text(
                  'Note: Notifications are automatically deleted after 2 days.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] == true;
              final type = notification['type'] ?? 'system';

              IconData icon;
              Color iconColor;

              switch (type) {
                case 'broadcast':
                  icon = LucideIcons.radio;
                  iconColor = Colors.orange;
                  break;
                case 'system':
                  icon = LucideIcons.info;
                  iconColor = Colors.blue;
                  break;
                case 'payment':
                  icon = LucideIcons.creditCard;
                  iconColor = Colors.green;
                  break;
                default:
                  icon = LucideIcons.bell;
                  iconColor = theme.colorScheme.primary;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isRead ? theme.colorScheme.surface : theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead 
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      notification['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: !isRead 
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(ref, notification['_id']);
                    }

                    if (type == 'support') {
                      context.push('/support');
                      return;
                    }

                    if (type == 'payment' || 
                        (notification['title'] ?? '').toString().toLowerCase().contains('plan') ||
                        (notification['message'] ?? '').toString().toLowerCase().contains('plan')) {
                      context.go('/dashboard');
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(icon, color: iconColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(child: Text(notification['title'] ?? 'Notification')),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Text(notification['message'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  },
),
    );
  }
}
