import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AdminNotificationType { approval, borrowing, inventory, security, system }

class AdminNotification {
  const AdminNotification({
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
  final AdminNotificationType type;
  final DateTime? createdAt;
  final String? route;
  final bool isRead;

  AdminNotification copyWith({bool? isRead}) {
    return AdminNotification(
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
      case AdminNotificationType.approval:
        return Icons.person_add_alt_1_outlined;
      case AdminNotificationType.borrowing:
        return Icons.swap_horiz_outlined;
      case AdminNotificationType.inventory:
        return Icons.inventory_2_outlined;
      case AdminNotificationType.security:
        return Icons.security_outlined;
      case AdminNotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case AdminNotificationType.approval:
        return Colors.deepOrange;
      case AdminNotificationType.borrowing:
        return Colors.indigo;
      case AdminNotificationType.inventory:
        return Colors.teal;
      case AdminNotificationType.security:
        return Colors.red;
      case AdminNotificationType.system:
        return Colors.blueGrey;
    }
  }

  static DateTime? dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
