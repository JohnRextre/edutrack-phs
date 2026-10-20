import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrower_notification_model.dart';
import '../services/borrower_notification_service.dart';

class BorrowerNotificationsButton extends StatelessWidget {
  const BorrowerNotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();
    final service = BorrowerNotificationService();

    return StreamBuilder<List<BorrowerNotification>>(
      stream: service.watchNotifications(userId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <BorrowerNotification>[];
        final unread = notifications.where((item) => !item.isRead).length;
        return IconButton(
          tooltip: unread == 0
              ? 'Notifications'
              : '$unread unread notifications',
          onPressed: snapshot.hasError
              ? () => _showError(context, snapshot.error!)
              : () =>
                    _showNotifications(context, service, userId, notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(
    BuildContext context,
    BorrowerNotificationService service,
    String userId,
    List<BorrowerNotification> notifications,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * .76,
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 14, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Theme.of(sheetContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: notifications.any((item) => !item.isRead)
                          ? () async {
                              await service.markAllAsRead(
                                userId: userId,
                                notificationIds: notifications
                                    .where((item) => !item.isRead)
                                    .map((item) => item.id),
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            }
                          : null,
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(sheetContext).colorScheme.outlineVariant,
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(child: Text('No notifications yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _BorrowerNotificationTile(
                            notification: notification,
                            onTap: () => _openNotification(
                              context,
                              sheetContext,
                              service,
                              userId,
                              notification,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    BuildContext sheetContext,
    BorrowerNotificationService service,
    String userId,
    BorrowerNotification notification,
  ) async {
    await service.markAsRead(userId: userId, notificationId: notification.id);
    if (!context.mounted) return;
    Navigator.pop(sheetContext);
    if (notification.route != null) {
      Navigator.pushNamed(context, notification.route!);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load notifications: $error')),
    );
  }
}

class _BorrowerNotificationTile extends StatelessWidget {
  const _BorrowerNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final BorrowerNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: notification.isRead
          ? colors.surfaceContainerLow
          : colors.primaryContainer.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: notification.color.withValues(alpha: .14),
                child: Icon(notification.icon, color: notification.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                CircleAvatar(radius: 4, backgroundColor: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
