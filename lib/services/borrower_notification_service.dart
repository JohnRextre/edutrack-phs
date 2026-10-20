import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/borrower_notification_model.dart';
import '../models/section_model.dart';

class BorrowerNotificationService {
  BorrowerNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<BorrowerNotification>> watchNotifications(String userId) {
    late StreamController<List<BorrowerNotification>> controller;
    QuerySnapshot<Map<String, dynamic>>? transactionsSnapshot;
    QuerySnapshot<Map<String, dynamic>>? readsSnapshot;
    DocumentSnapshot<Map<String, dynamic>>? userSnapshot;
    QuerySnapshot<Map<String, dynamic>>? sectionsSnapshot;
    final subscriptions = <StreamSubscription<dynamic>>[];

    void emit() {
      if (transactionsSnapshot == null ||
          readsSnapshot == null ||
          userSnapshot == null ||
          sectionsSnapshot == null) {
        return;
      }
      final readIds = readsSnapshot!.docs.map((doc) => doc.id).toSet();
      final notifications = transactionsSnapshot!.docs
          .map(BorrowTransaction.fromFirestore)
          .expand(_notificationsFor)
          .followedBy(
            _sectionNotifications(userSnapshot!, sectionsSnapshot!.docs),
          )
          .map(
            (notification) => notification.copyWith(
              isRead: readIds.contains(notification.id),
            ),
          )
          .toList();
      notifications.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      controller.add(notifications.take(50).toList());
    }

    controller = StreamController<List<BorrowerNotification>>(
      onListen: () {
        subscriptions.add(
          _firestore
              .collection('borrow_transactions')
              .where('userId', isEqualTo: userId.trim())
              .snapshots()
              .listen((snapshot) {
                transactionsSnapshot = snapshot;
                emit();
              }),
        );
        subscriptions.add(
          _firestore.collection('users').doc(userId).snapshots().listen((
            snapshot,
          ) {
            userSnapshot = snapshot;
            emit();
          }),
        );
        subscriptions.add(
          _firestore.collection('sections').snapshots().listen((snapshot) {
            sectionsSnapshot = snapshot;
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
    for (final id in notificationIds) {
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notification_reads')
            .doc(id),
        {'readAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  Iterable<BorrowerNotification> _notificationsFor(BorrowTransaction tx) {
    final notifications = <BorrowerNotification>[];
    final route = '/my-borrowings';
    final now = DateTime.now();

    if (tx.status == BorrowTransactionStatus.borrowed ||
        tx.effectiveStatus == BorrowTransactionStatus.overdue) {
      if (tx.effectiveStatus == BorrowTransactionStatus.overdue) {
        notifications.add(
          BorrowerNotification(
            id: 'borrower_overdue_${tx.id}',
            title: 'Item is overdue',
            message:
                '${tx.resourceName} was due on ${_date(tx.expectedReturnDate)}.',
            type: BorrowerNotificationType.due,
            createdAt: tx.expectedReturnDate,
            route: route,
          ),
        );
      } else if (tx.expectedReturnDate.difference(now).inHours >= 0 &&
          tx.expectedReturnDate.difference(now).inDays <= 2) {
        notifications.add(
          BorrowerNotification(
            id: 'borrower_due_${tx.id}',
            title: 'Return due soon',
            message:
                '${tx.resourceName} is due on ${_date(tx.expectedReturnDate)}.',
            type: BorrowerNotificationType.due,
            createdAt: tx.expectedReturnDate,
            route: route,
          ),
        );
      }
    }
    if (tx.status == BorrowTransactionStatus.returnPending) {
      notifications.add(
        BorrowerNotification(
          id: 'borrower_return_pending_${tx.id}',
          title: 'Return submitted',
          message: '${tx.resourceName} is waiting for return verification.',
          type: BorrowerNotificationType.returnUpdate,
          createdAt: tx.returnSubmittedDate ?? tx.borrowDate,
          route: route,
        ),
      );
    }
    if (tx.status == BorrowTransactionStatus.returned) {
      notifications.add(
        BorrowerNotification(
          id: 'borrower_returned_${tx.id}',
          title: 'Return confirmed',
          message: '${tx.resourceName} has been marked as returned.',
          type: BorrowerNotificationType.returnUpdate,
          createdAt: tx.actualReturnDate ?? tx.borrowDate,
          route: route,
        ),
      );
    }
    if (tx.isReturnRejected) {
      notifications.add(
        BorrowerNotification(
          id: 'borrower_return_rejected_${tx.id}',
          title: 'Return needs correction',
          message: '${tx.resourceName} needs an updated return submission.',
          type: BorrowerNotificationType.rejected,
          createdAt: tx.returnSubmittedDate ?? tx.borrowDate,
          route: '/my-borrowings',
        ),
      );
    }
    return notifications;
  }

  Iterable<BorrowerNotification> _sectionNotifications(
    DocumentSnapshot<Map<String, dynamic>> user,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final sectionId = user.data()?['sectionId']?.toString().trim() ?? '';
    if (sectionId.isEmpty) return const [];
    QueryDocumentSnapshot<Map<String, dynamic>>? sectionDocument;
    for (final document in documents) {
      if (document.id == sectionId) {
        sectionDocument = document;
        break;
      }
    }
    if (sectionDocument == null) return const [];

    final section = SectionModel.fromFirestore(sectionDocument);
    if (section.isActive && !section.isDeleted) return const [];
    final deleted = section.isDeleted;
    final reason = section.inactiveReason.trim();
    final state = deleted ? 'deleted' : 'inactive';
    final message = reason.isEmpty
        ? 'Your section, ${section.displayName}, is $state. Please contact the administrator.'
        : 'Your section, ${section.displayName}, is $state. Reason: $reason';
    final data = sectionDocument.data();
    return [
      BorrowerNotification(
        id: 'borrower_section_${section.id}_$state',
        title: deleted
            ? 'Your section was deleted'
            : 'Your section is inactive',
        message: message,
        type: BorrowerNotificationType.section,
        createdAt: BorrowerNotification.dateFrom(
          data['updatedAt'] ?? data['createdAt'],
        ),
        route: '/profile',
      ),
    ];
  }

  String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
}
