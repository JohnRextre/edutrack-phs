import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AccountActivityKind { borrowing, account }

class AccountActivity {
  const AccountActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.kind,
    required this.icon,
    required this.color,
    this.transaction,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final AccountActivityKind kind;
  final IconData icon;
  final Color color;
  final dynamic transaction;

  static DateTime? dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
