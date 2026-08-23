import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lifecycle statuses stored in Firestore for a borrow transaction.
abstract final class BorrowTransactionStatus {
  static const String pending = 'pending';
  static const String borrowed = 'borrowed';
  static const String borrowRejected = 'borrow_rejected';
  static const String returnPending = 'return_pending';
  static const String returned = 'returned';
  static const String returnRejected = 'return_rejected';

  /// Derived only — not persisted when status is [borrowed] past due date.
  static const String overdue = 'overdue';

  /// Legacy alias kept for reading older Firestore documents.
  static const String legacyRejected = 'rejected';

  static const List<String> all = [
    pending,
    borrowed,
    borrowRejected,
    returnPending,
    returned,
    returnRejected,
  ];

  static const List<String> borrowRequestStatuses = [
    pending,
    borrowRejected,
    legacyRejected,
  ];

  static const List<String> returnRequestStatuses = [
    returnPending,
    returned,
    returnRejected,
  ];
}

/// Return proof types submitted when a borrower initiates a return.
abstract final class ReturnType {
  static const String goodCondition = 'good_condition';
  static const String paymentProof = 'payment_proof';
  static const String repairedProof = 'repaired_proof';
  static const String replacementProof = 'replacement_proof';

  static const List<String> all = [
    goodCondition,
    paymentProof,
    repairedProof,
    replacementProof,
  ];

  static const Map<String, String> labels = {
    goodCondition: 'Good Condition Return',
    paymentProof: 'Payment Proof Return - Official/Payment Receipt',
    repairedProof: 'Repaired Proof Return - Repaired Item Proof',
    replacementProof: 'Replacement Proof Return - Replaced Item Proof',
  };

  static String labelFor(String type) => labels[type] ?? type;
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
    this.returnSubmittedDate,
    required this.status,
    this.requestedQuantity = 1,
    this.purpose = '',
    this.rejectionReason,
    this.returnType,
    this.itemConditionNotes,
    this.overdueReason,
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
  final DateTime? returnSubmittedDate;

  /// Raw status from Firestore.
  final String status;

  /// Number of units requested / borrowed in this transaction.
  final int requestedQuantity;

  /// Optional reason provided by the borrower at request time.
  final String purpose;

  /// Optional reason provided by the custodian when rejecting a request/return.
  final String? rejectionReason;

  /// Return proof type selected by the borrower (e.g. good_condition).
  final String? returnType;

  /// Borrower's description of the item condition at return time.
  final String? itemConditionNotes;

  /// Required explanation when returning past the due date.
  final String? overdueReason;

  /// Derives `overdue` when still borrowed past the expected return date.
  String get effectiveStatus {
    if (status == BorrowTransactionStatus.borrowed &&
        expectedReturnDate.isBefore(DateTime.now())) {
      return BorrowTransactionStatus.overdue;
    }
    return status;
  }

  bool get isActiveBorrowing =>
      status == BorrowTransactionStatus.borrowed ||
      effectiveStatus == BorrowTransactionStatus.overdue;

  bool get isPending => status == BorrowTransactionStatus.pending;

  bool get isBorrowRejected =>
      status == BorrowTransactionStatus.borrowRejected ||
      status == BorrowTransactionStatus.legacyRejected;

  bool get isReturnPending => status == BorrowTransactionStatus.returnPending;

  bool get isReturnRejected =>
      status == BorrowTransactionStatus.returnRejected;

  String get statusLabel {
    switch (effectiveStatus) {
      case BorrowTransactionStatus.pending:
        return 'Pending Approval';
      case BorrowTransactionStatus.borrowed:
        return 'Borrowed';
      case BorrowTransactionStatus.overdue:
        return 'Overdue';
      case BorrowTransactionStatus.borrowRejected:
      case BorrowTransactionStatus.legacyRejected:
        return 'Rejected';
      case BorrowTransactionStatus.returnPending:
        return 'Pending Verification';
      case BorrowTransactionStatus.returned:
        return 'Returned';
      case BorrowTransactionStatus.returnRejected:
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
      case BorrowTransactionStatus.borrowRejected:
      case BorrowTransactionStatus.legacyRejected:
      case BorrowTransactionStatus.returnRejected:
        return Colors.red.shade700;
      case BorrowTransactionStatus.returnPending:
        return Colors.amber.shade800;
      case BorrowTransactionStatus.returned:
        return Colors.green;
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
      'returnSubmittedDate': returnSubmittedDate != null
          ? Timestamp.fromDate(returnSubmittedDate!)
          : null,
      'status': status,
      'requestedQuantity': requestedQuantity,
      'purpose': purpose,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (returnType != null) 'returnType': returnType,
      if (itemConditionNotes != null) 'itemConditionNotes': itemConditionNotes,
      if (overdueReason != null) 'overdueReason': overdueReason,
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
      returnSubmittedDate: _dateFrom(map['returnSubmittedDate']),
      status: _normalizeStatus(map['status']),
      requestedQuantity: _asInt(map['requestedQuantity'], fallback: 1),
      purpose: (map['purpose'] ?? '').toString(),
      rejectionReason: map['rejectionReason']?.toString(),
      returnType: map['returnType']?.toString(),
      itemConditionNotes: map['itemConditionNotes']?.toString(),
      overdueReason: map['overdueReason']?.toString(),
    );
  }

  factory BorrowTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BorrowTransaction.fromMap(doc.id, doc.data() ?? {});
  }

  static String _normalizeStatus(Object? value) {
    final raw = (value ?? BorrowTransactionStatus.pending).toString();
    if (raw == BorrowTransactionStatus.legacyRejected) {
      return BorrowTransactionStatus.borrowRejected;
    }
    return raw;
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

