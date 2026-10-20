import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/custodian_notification_model.dart';
import '../models/resource_item.dart';
import 'admin_dashboard_service.dart';

class CustodianNotificationService {
  CustodianNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CustodianNotification>> watchNotifications(String userId) {
    late StreamController<List<CustodianNotification>> controller;
    QuerySnapshot<Map<String, dynamic>>? resourcesSnapshot;
    QuerySnapshot<Map<String, dynamic>>? transactionsSnapshot;
    QuerySnapshot<Map<String, dynamic>>? readsSnapshot;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (resourcesSnapshot == null ||
          transactionsSnapshot == null ||
          readsSnapshot == null) {
        return;
      }
      final readIds = readsSnapshot!.docs.map((doc) => doc.id).toSet();
      final notifications =
          <CustodianNotification>[
            ..._resourceNotifications(resourcesSnapshot!.docs),
            ..._transactionNotifications(transactionsSnapshot!.docs),
          ].map((notification) {
            return notification.copyWith(
              isRead: readIds.contains(notification.id),
            );
          }).toList();
      notifications.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      controller.add(notifications.take(50).toList());
    }

    controller = StreamController<List<CustodianNotification>>(
      onListen: () {
        subscriptions.add(
          _firestore
              .collection(AdminDashboardService.resourcesCollection)
              .snapshots()
              .listen((snapshot) {
                resourcesSnapshot = snapshot;
                emit();
              }),
        );
        subscriptions.add(
          _firestore
              .collection(BorrowServiceCollection.name)
              .snapshots()
              .listen((snapshot) {
                transactionsSnapshot = snapshot;
                emit();
              }),
        );
        subscriptions.add(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('notification_reads')
              .snapshots()
              .listen((snapshot) {
                readsSnapshot = snapshot;
                emit();
              }),
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
    return _reads(
      userId,
    ).doc(notificationId).set({'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAllAsRead({
    required String userId,
    required Iterable<String> notificationIds,
  }) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      batch.set(_reads(userId).doc(id), {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _reads(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('notification_reads');

  List<CustodianNotification> _resourceNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.map(ResourceItem.fromFirestore).expand((resource) {
      final notifications = <CustodianNotification>[];
      final available = resource.availableQuantity;
      final lowStockLimit = (resource.totalQuantity * 0.2).ceil().clamp(
        1,
        resource.totalQuantity,
      );
      final date = resource.createdAt;
      if (available == 0) {
        notifications.add(
          CustodianNotification(
            id: 'custodian_stock_out_${resource.id}',
            title: 'Out of stock',
            message:
                '${resource.itemName} (${resource.itemCode}) has no available units.',
            type: CustodianNotificationType.outOfStock,
            createdAt: date,
            route: '/custodian-resources',
          ),
        );
      } else if (available <= lowStockLimit) {
        notifications.add(
          CustodianNotification(
            id: 'custodian_stock_low_${resource.id}',
            title: 'Low stock',
            message:
                '${resource.itemName} has only $available unit${available == 1 ? '' : 's'} available.',
            type: CustodianNotificationType.lowStock,
            createdAt: date,
            route: '/custodian-resources',
          ),
        );
      }
      return notifications;
    }).toList();
  }

  List<CustodianNotification> _transactionNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.map(BorrowTransaction.fromFirestore).expand((tx) {
      final notifications = <CustodianNotification>[];
      final route = '/custodian-return-verification';
      if (tx.effectiveStatus == BorrowTransactionStatus.overdue) {
        notifications.add(
          CustodianNotification(
            id: 'custodian_late_return_${tx.id}',
            title: 'Late return',
            message:
                '${tx.resourceName} borrowed by ${tx.userName} is overdue.',
            type: CustodianNotificationType.lateReturn,
            createdAt: tx.expectedReturnDate,
            route: route,
          ),
        );
      }
      if (tx.status == BorrowTransactionStatus.returnPending) {
        final type = tx.returnType;
        final notificationType = switch (type) {
          ReturnType.paymentProof => CustodianNotificationType.payment,
          ReturnType.repairedProof => CustodianNotificationType.repaired,
          ReturnType.replacementProof => CustodianNotificationType.replacement,
          _ => CustodianNotificationType.returnPending,
        };
        final resubmitted =
            notificationType != CustodianNotificationType.returnPending;
        notifications.add(
          CustodianNotification(
            id: 'custodian_return_${tx.id}_${type ?? 'pending'}',
            title: resubmitted
                ? 'Resubmitted return'
                : 'Return for verification',
            message: resubmitted
                ? '${tx.resourceName} was resubmitted with ${ReturnType.labelFor(type!)}.'
                : '${tx.resourceName} was submitted by ${tx.userName} for verification.',
            type: resubmitted
                ? CustodianNotificationType.resubmittedReturn
                : notificationType,
            createdAt: tx.returnSubmittedDate ?? tx.borrowDate,
            route: route,
          ),
        );
      }
      return notifications;
    }).toList();
  }
}

abstract final class BorrowServiceCollection {
  static const name = 'borrow_transactions';
}
