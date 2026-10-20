import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BorrowerNotificationType { due, returnUpdate, rejected, section }

class BorrowerNotification {
  const BorrowerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.route,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final BorrowerNotificationType type;
  final DateTime? createdAt;
  final String? route;
  final bool isRead;

  BorrowerNotification copyWith({bool? isRead}) {
    return BorrowerNotification(
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
      case BorrowerNotificationType.due:
        return Icons.schedule_outlined;
      case BorrowerNotificationType.returnUpdate:
        return Icons.assignment_return_outlined;
      case BorrowerNotificationType.rejected:
        return Icons.info_outline;
      case BorrowerNotificationType.section:
        return Icons.groups_outlined;
    }
  }

  Color get color {
    switch (type) {
      case BorrowerNotificationType.due:
        return Colors.orange.shade800;
      case BorrowerNotificationType.returnUpdate:
        return Colors.teal;
      case BorrowerNotificationType.rejected:
        return Colors.red;
      case BorrowerNotificationType.section:
        return Colors.deepPurple;
    }
  }

  static DateTime? dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
