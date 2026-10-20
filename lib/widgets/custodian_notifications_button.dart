import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/custodian_notification_model.dart';
import '../services/custodian_notification_service.dart';

class CustodianNotificationsButton extends StatelessWidget {
  const CustodianNotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();
    final service = CustodianNotificationService();
    return StreamBuilder<List<CustodianNotification>>(
      stream: service.watchNotifications(userId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <CustodianNotification>[];
        final unread = notifications.where((item) => !item.isRead).length;
        return IconButton(
          tooltip: unread == 0
              ? 'Notifications'
              : '$unread unread notifications',
          onPressed: snapshot.hasError
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to load notifications: ${snapshot.error}',
                    ),
                  ),
                )
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
    CustodianNotificationService service,
    String userId,
    List<CustodianNotification> notifications,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.76,
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
                        'Custodian Notifications',
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
                    ? const Center(child: Text('You are all caught up'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _CustodianNotificationTile(
                            notification: notification,
                            onTap: () async {
                              if (!notification.isRead) {
                                await service.markAsRead(
                                  userId: userId,
                                  notificationId: notification.id,
                                );
                              }
                              if (!context.mounted || !sheetContext.mounted) {
                                return;
                              }
                              Navigator.pop(sheetContext);
                              Navigator.pushNamed(context, notification.route);
                            },
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
}

class _CustodianNotificationTile extends StatelessWidget {
  const _CustodianNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final CustodianNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: notification.isRead
          ? colors.surfaceContainerLow
          : colors.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(notification.icon, color: notification.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
