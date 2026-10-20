import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/account_activity_model.dart';
import '../models/borrow_transaction_model.dart';
import 'admin_dashboard_service.dart';
import 'borrow_service.dart';

class AccountActivityService {
  AccountActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AccountActivity>> watchActivities(
    String userId, {
    bool custodianOnly = false,
  }) {
    late StreamController<List<AccountActivity>> controller;
    List<BorrowTransaction>? transactions;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? auditDocuments;
    final subscriptions = <StreamSubscription<dynamic>>[];

    void emit() {
      if (transactions == null || auditDocuments == null) return;
      final activities = <AccountActivity>[
        if (!custodianOnly) ...transactions!.map(_fromTransaction),
        ...auditDocuments!
            .where((document) => !custodianOnly || _isCustodianAction(document))
            .map(_fromAuditDocument),
      ]..sort((a, b) => b.date.compareTo(a.date));
      controller.add(activities);
    }

    controller = StreamController<List<AccountActivity>>(
      onListen: () {
        if (custodianOnly) {
          transactions = [];
        } else {
          subscriptions.add(
            _firestore
                .collection(BorrowService.collection)
                .where('userId', isEqualTo: userId)
                .snapshots()
                .listen((snapshot) {
                  transactions = snapshot.docs
                      .map(BorrowTransaction.fromFirestore)
                      .toList();
                  emit();
                }),
          );
        }
        subscriptions.add(
          _firestore
              .collection(AdminDashboardService.auditLogsCollection)
              .where('userId', isEqualTo: userId)
              .snapshots()
              .listen((snapshot) {
                auditDocuments = snapshot.docs;
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

  static bool _isCustodianAction(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final action = (document.data()['actionType'] ?? '').toString();
    return action == 'resource_added' ||
        action == 'resource_edited' ||
        action == 'resource_deleted' ||
        action == 'resource_quantity_deleted' ||
        action == 'account_created' ||
        action == 'password_changed' ||
        action == 'login' ||
        action == 'logout';
  }

  AccountActivity _fromTransaction(BorrowTransaction transaction) {
    final returned = transaction.status == BorrowTransactionStatus.returned;
    return AccountActivity(
      id: 'borrow_${transaction.id}',
      title: returned ? 'Returned an item' : transaction.statusLabel,
      description: '${transaction.resourceName} (${transaction.resourceCode})',
      date:
          transaction.actualReturnDate ??
          transaction.returnSubmittedDate ??
          transaction.borrowDate,
      kind: AccountActivityKind.borrowing,
      icon: returned
          ? Icons.assignment_return_outlined
          : Icons.inventory_2_outlined,
      color: transaction.statusColor,
      transaction: transaction,
    );
  }

  AccountActivity _fromAuditDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final action = (data['actionType'] ?? data['action'] ?? 'account_activity')
        .toString()
        .toLowerCase();
    final title = (data['title'] ?? _titleFor(action)).toString();
    return AccountActivity(
      id: 'account_${document.id}',
      title: title,
      description: (data['description'] ?? 'Account activity recorded.')
          .toString(),
      date:
          AccountActivity.dateFrom(data['timestamp'] ?? data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: AccountActivityKind.account,
      icon: _iconFor(action),
      color: _colorFor(action),
    );
  }

  static String _titleFor(String action) {
    if (action.contains('create') || action.contains('register')) {
      return 'Created an account';
    }
    if (action.contains('password')) return 'Changed password';
    if (action.contains('login') || action.contains('sign_in')) {
      return 'Logged in';
    }
    if (action.contains('logout') || action.contains('sign_out')) {
      return 'Logged out';
    }
    if (action == 'resource_added') return 'Added Learning Resource';
    if (action == 'resource_edited') return 'Changed Learning Resource';
    if (action == 'resource_deleted') return 'Deleted Learning Resource';
    if (action == 'resource_quantity_deleted') {
      return 'Deleted Learning Resource Quantity';
    }
    return 'Account activity';
  }

  static IconData _iconFor(String action) {
    if (action.contains('password')) return Icons.lock_reset_outlined;
    if (action.contains('login') || action.contains('sign_in')) {
      return Icons.login_outlined;
    }
    if (action.contains('logout') || action.contains('sign_out')) {
      return Icons.logout_outlined;
    }
    if (action.contains('create') || action.contains('register')) {
      return Icons.person_add_alt_1_outlined;
    }
    if (action.contains('resource_added')) return Icons.add_box_outlined;
    if (action.contains('resource_edited')) return Icons.edit_outlined;
    if (action.contains('resource_deleted') ||
        action.contains('quantity_deleted')) {
      return Icons.delete_outline;
    }
    return Icons.manage_accounts_outlined;
  }

  static Color _colorFor(String action) {
    if (action.contains('password')) return Colors.deepPurple;
    if (action.contains('login') || action.contains('sign_in')) {
      return Colors.green.shade700;
    }
    if (action.contains('logout') || action.contains('sign_out')) {
      return Colors.blueGrey;
    }
    if (action.contains('resource_deleted') ||
        action.contains('quantity_deleted')) {
      return Colors.red.shade700;
    }
    if (action.contains('resource_edited')) return Colors.orange.shade800;
    if (action.contains('resource_added')) return Colors.teal.shade700;
    return Colors.indigo;
  }
}
