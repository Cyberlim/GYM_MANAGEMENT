import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gym_owner_web/features/notifications/providers/notifications_provider.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

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
                      const Text(
                        'Notifications',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay updated on important events',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(notificationsProvider.notifier).markAllAsRead();
                      },
                      icon: const Icon(LucideIcons.checkCheck, size: 16),
                      label: const Text('Mark All as Read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Note: Notifications are automatically deleted after 2 days.', style: TextStyle(color: Colors.orange, fontSize: 13)),
                ],
              ),
            ),
            if (notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(64.0),
                  child: Column(
                    children: [
                      Icon(LucideIcons.bellOff, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(notification: notification);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case 'Payment':
        iconColor = Colors.red;
        iconData = LucideIcons.creditCard;
        break;
      case 'Inventory':
        iconColor = Colors.orange;
        iconData = LucideIcons.package;
        break;
      case 'Maintenance':
        iconColor = Colors.blue;
        iconData = LucideIcons.wrench;
        break;
      case 'System':
      default:
        iconColor = Colors.green;
        iconData = LucideIcons.info;
        break;
    }

    if (notification.isRead) {
      iconColor = iconColor.withOpacity(0.5);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? Theme.of(context).dividerColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
        boxShadow: notification.isRead ? [] : [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(notification.id);
          }
          if (notification.targetRoute != null) {
            context.go(notification.targetRoute!);
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(iconData, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(notification.title)),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(
                    notification.message,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                  color: notification.isRead 
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              timeago.format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            notification.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(notification.isRead ? 0.5 : 0.8),
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical, size: 20),
          onSelected: (value) {
            if (value == 'read') {
              ref.read(notificationsProvider.notifier).markAsRead(notification.id);
            } else if (value == 'delete') {
              ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (!notification.isRead)
              const PopupMenuItem<String>(
                value: 'read',
                child: Row(
                  children: [
                    Icon(LucideIcons.check, size: 18),
                    SizedBox(width: 8),
                    Text('Mark as Read'),
                  ],
                ),
              ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
