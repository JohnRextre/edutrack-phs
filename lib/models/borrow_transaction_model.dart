import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lifecycle statuses stored in Firestore for a borrow transaction.
abstract final class BorrowTransactionStatus {
  static const String pending = 'pending';
  static const String borrowed = 'borrowed';
  static const String returned = 'returned';
  static const String rejected = 'rejected';
  static const String overdue = 'overdue';

  static const List<String> all = [
    pending,
    borrowed,
    returned,
    rejected,
    overdue,
  ];
}

/// A single resource borrow request / checkout record in `borrow_transactions`.
class BorrowTransaction {
  const BorrowTransaction({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.resourceCode,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.borrowDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.requestedQuantity = 1,
  });

  final String id;
  final String resourceId;
  final String resourceName;
  final String resourceCode;
  final String userId;
  final String userName;

  /// Stored as lowercase: `student` or `teacher`.
  final String userRole;
  final DateTime borrowDate;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;

  /// Raw status from Firestore: pending | borrowed | returned | rejected.
  final String status;

  /// Number of units requested / borrowed in this transaction.
  final int requestedQuantity;

  /// Derives `overdue` when still borrowed past the expected return date.
  String get effectiveStatus {
    if (status == BorrowTransactionStatus.borrowed &&
        expectedReturnDate.isBefore(DateTime.now())) {
      return BorrowTransactionStatus.overdue;
    }
    return status;
  }

  bool get isActive =>
      status == BorrowTransactionStatus.borrowed ||
      effectiveStatus == BorrowTransactionStatus.overdue;

  bool get isPending => status == BorrowTransactionStatus.pending;

  String get statusLabel {
    switch (effectiveStatus) {
      case BorrowTransactionStatus.pending:
        return 'Pending Approval';
      case BorrowTransactionStatus.borrowed:
        return 'Borrowed';
      case BorrowTransactionStatus.overdue:
        return 'Overdue';
      case BorrowTransactionStatus.returned:
        return 'Returned';
      case BorrowTransactionStatus.rejected:
        return 'Rejected';
      default:
        return effectiveStatus;
    }
  }

  Color get statusColor {
    switch (effectiveStatus) {
      case BorrowTransactionStatus.pending:
        return Colors.orange;
      case BorrowTransactionStatus.borrowed:
        return Colors.blue;
      case BorrowTransactionStatus.overdue:
        return Colors.red;
      case BorrowTransactionStatus.returned:
        return Colors.green;
      case BorrowTransactionStatus.rejected:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'resourceName': resourceName,
      'resourceCode': resourceCode,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'actualReturnDate': actualReturnDate != null
          ? Timestamp.fromDate(actualReturnDate!)
          : null,
      'status': status,
      'requestedQuantity': requestedQuantity,
    };
  }

  factory BorrowTransaction.fromMap(String id, Map<String, dynamic> map) {
    return BorrowTransaction(
      id: id,
      resourceId: (map['resourceId'] ?? '').toString(),
      resourceName: (map['resourceName'] ?? '').toString(),
      resourceCode: (map['resourceCode'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      userRole: (map['userRole'] ?? 'student').toString(),
      borrowDate: _dateFrom(map['borrowDate']) ?? DateTime.now(),
      expectedReturnDate:
          _dateFrom(map['expectedReturnDate']) ?? DateTime.now(),
      actualReturnDate: _dateFrom(map['actualReturnDate']),
      status: (map['status'] ?? BorrowTransactionStatus.pending).toString(),
      requestedQuantity: _asInt(map['requestedQuantity'], fallback: 1),
    );
  }

  factory BorrowTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BorrowTransaction.fromMap(doc.id, doc.data() ?? {});
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
