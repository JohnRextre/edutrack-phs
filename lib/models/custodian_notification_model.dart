import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CustodianNotificationType {
  lowStock,
  outOfStock,
  lateReturn,
  returnPending,
  resubmittedReturn,
  payment,
  repaired,
  replacement,
}

class CustodianNotification {
  const CustodianNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.route,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final CustodianNotificationType type;
  final DateTime? createdAt;
  final String route;
  final bool isRead;

  CustodianNotification copyWith({bool? isRead}) {
    return CustodianNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      route: route,
      isRead: isRead ?? this.isRead,
    );
  }

  IconData get icon {
    switch (type) {
      case CustodianNotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case CustodianNotificationType.outOfStock:
        return Icons.inventory_outlined;
      case CustodianNotificationType.lateReturn:
        return Icons.schedule_outlined;
      case CustodianNotificationType.returnPending:
        return Icons.assignment_return_outlined;
      case CustodianNotificationType.resubmittedReturn:
        return Icons.replay_outlined;
      case CustodianNotificationType.payment:
        return Icons.receipt_long_outlined;
      case CustodianNotificationType.repaired:
        return Icons.build_outlined;
      case CustodianNotificationType.replacement:
        return Icons.swap_horiz_outlined;
    }
  }

  Color get color {
    switch (type) {
      case CustodianNotificationType.lowStock:
        return Colors.orange.shade800;
      case CustodianNotificationType.outOfStock:
        return Colors.red.shade700;
      case CustodianNotificationType.lateReturn:
        return Colors.deepOrange;
      case CustodianNotificationType.returnPending:
        return Colors.indigo;
      case CustodianNotificationType.resubmittedReturn:
        return Colors.deepPurple;
      case CustodianNotificationType.payment:
        return Colors.teal.shade700;
      case CustodianNotificationType.repaired:
        return Colors.green.shade700;
      case CustodianNotificationType.replacement:
        return Colors.blue.shade700;
    }
  }

  static DateTime? dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
