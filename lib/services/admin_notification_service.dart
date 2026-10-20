import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification_model.dart';
import '../models/resource_item.dart';
import 'admin_dashboard_service.dart';

class AdminNotificationService {
  AdminNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AdminNotification>> watchNotifications(String userId) {
    late StreamController<List<AdminNotification>> controller;
    final snapshots = <String, QuerySnapshot<Map<String, dynamic>>?>{
      'resources': null,
      'sections': null,
      'audit': null,
      'reads': null,
    };
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (snapshots.values.any((snapshot) => snapshot == null)) return;
      final readIds = snapshots['reads']!.docs.map((doc) => doc.id).toSet();
      final notifications =
          <AdminNotification>[
            ..._resourceNotifications(snapshots['resources']!.docs),
            ..._sectionNotifications(snapshots['sections']!.docs),
            ..._auditNotifications(snapshots['audit']!.docs),
          ].map((notification) {
            return notification.copyWith(
              isRead: readIds.contains(notification.id),
            );
          }).toList();
      notifications.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      controller.add(notifications.take(50).toList());
    }

    void listen(String key, Query<Map<String, dynamic>> query) {
      subscriptions.add(
        query.snapshots().listen((snapshot) {
          snapshots[key] = snapshot;
          emit();
        }),
      );
    }

    controller = StreamController<List<AdminNotification>>(
      onListen: () {
        listen(
          'resources',
          _firestore.collection(AdminDashboardService.resourcesCollection),
        );
        listen('sections', _firestore.collection('sections'));
        listen(
          'audit',
          _firestore
              .collection(AdminDashboardService.auditLogsCollection)
              .orderBy('timestamp', descending: true)
              .limit(30),
        );
        listen(
          'reads',
          _firestore
              .collection('users')
              .doc(userId)
              .collection('notification_reads'),
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notification_reads')
        .doc(notificationId)
        .set({'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAllAsRead({
    required String userId,
    required Iterable<String> notificationIds,
  }) async {
    final batch = _firestore.batch();
    for (final notificationId in notificationIds) {
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notification_reads')
            .doc(notificationId),
        {'readAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  List<AdminNotification> _sectionNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final notifications = <AdminNotification>[];
    for (final document in documents) {
      final data = document.data();
      final limit = _asInt(data['maxActiveBorrowQuantity']);
      final current = _asInt(data['currentActiveBorrowQuantity']);
      if (limit < 1 || current < limit * 0.8) continue;

      final sectionName = [data['gradeLevel'], data['name']]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .join(' - ');
      final reachedLimit = current >= limit;
      notifications.add(
        AdminNotification(
          id: 'section_capacity_${document.id}_${reachedLimit ? 'full' : 'near'}',
          title: reachedLimit
              ? 'Section borrowing limit reached'
              : 'Section nearing borrowing limit',
          message: reachedLimit
              ? '$sectionName has reached its maximum active borrow limit ($current/$limit).'
              : '$sectionName is near its maximum active borrow limit ($current/$limit).',
          type: AdminNotificationType.system,
          createdAt: AdminNotification.dateFrom(
            data['updatedAt'] ?? data['createdAt'],
          ),
          route: '/admin-sections',
        ),
      );
    }
    return notifications;
  }

  List<AdminNotification> _resourceNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents
        .map(ResourceItem.fromFirestore)
        .where((resource) {
          final category = resource.mainCategory.toLowerCase();
          return (category == 'ict' || category == 'ict equipment') &&
              (resource.availableQuantity == 0 ||
                  resource.inventoryStatus.toLowerCase() == 'damaged' ||
                  resource.inventoryStatus.toLowerCase() == 'under_repair' ||
                  resource.inventoryStatus.toLowerCase() == 'for_replacement' ||
                  resource.damagedQuantity > 0);
        })
        .map((resource) {
          final unavailable = resource.availableQuantity == 0;
          return AdminNotification(
            id: 'inventory_${resource.id}',
            title: unavailable
                ? 'ICT item out of stock'
                : 'ICT maintenance alert',
            message: unavailable
                ? '${resource.itemName} (${resource.itemCode}) has no available units.'
                : '${resource.itemName} (${resource.itemCode}) needs inventory attention.',
            type: AdminNotificationType.inventory,
            createdAt: resource.createdAt,
            route: '/custodian-resources',
          );
        })
        .toList();
  }

  List<AdminNotification> _auditNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents
        .where((document) {
          final data = document.data();
          final category = (data['category'] ?? data['actionType'] ?? '')
              .toString()
              .toLowerCase();
          return category.contains('auth') ||
              category.contains('security') ||
              category.contains('role') ||
              category.contains('account') ||
              category.contains('system');
        })
        .map((document) {
          final data = document.data();
          return AdminNotification(
            id: 'audit_${document.id}',
            title: (data['title'] ?? data['action'] ?? 'System security event')
                .toString(),
            message:
                (data['description'] ??
                        data['action'] ??
                        'Review the audit log.')
                    .toString(),
            type: AdminNotificationType.security,
            createdAt: AdminNotification.dateFrom(
              data['timestamp'] ?? data['createdAt'],
            ),
            route: '/admin-logs',
          );
        })
        .toList();
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
