import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/admin_notification_model.dart';
import '../services/admin_notification_service.dart';

class AdminNotificationsButton extends StatelessWidget {
  const AdminNotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final service = AdminNotificationService();
    return StreamBuilder<List<AdminNotification>>(
      stream: service.watchNotifications(userId),
      builder: (context, snapshot) {
        final unreadCount =
            snapshot.data
                ?.where((notification) => !notification.isRead)
                .length ??
            0;
        return IconButton(
          tooltip: unreadCount == 0
              ? 'Notifications'
              : '$unreadCount unread notifications',
          onPressed: snapshot.hasError
              ? () => _showError(context, snapshot.error!)
              : () => _showNotifications(
                  context,
                  service,
                  userId,
                  snapshot.data ?? const [],
                ),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(
    BuildContext context,
    AdminNotificationService service,
    String userId,
    List<AdminNotification> notifications,
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Notifications',
                            style: Theme.of(sheetContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${notifications.where((item) => !item.isRead).length} unread updates',
                            style: TextStyle(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: notifications.any((item) => !item.isRead)
                          ? () async {
                              try {
                                await service.markAllAsRead(
                                  userId: userId,
                                  notificationIds: notifications
                                      .where((item) => !item.isRead)
                                      .map((item) => item.id),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  _showError(sheetContext, error);
                                }
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
                    ? _EmptyNotifications()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _NotificationTile(
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
    AdminNotificationService service,
    String userId,
    AdminNotification notification,
  ) async {
    try {
      if (!notification.isRead) {
        await service.markAsRead(
          userId: userId,
          notificationId: notification.id,
        );
      }
      if (!context.mounted) return;
      Navigator.pop(sheetContext);
      if (notification.route != null) {
        Navigator.pushNamed(context, notification.route!);
      }
    } catch (error) {
      if (sheetContext.mounted) _showError(sheetContext, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load notifications: $error')),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AdminNotification notification;
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(notification.icon, color: notification.color),
              ),
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
                    const SizedBox(height: 8),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime? date) {
    if (date == null) return 'Time unavailable';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 12),
        const Text(
          'You are all caught up',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'New system updates will appear here.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
