import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import 'resource_service.dart';

/// Firestore operations for the `borrow_transactions` collection.
class BorrowService {
  BorrowService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'borrow_transactions';

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection(collection);

  DocumentReference<Map<String, dynamic>> _resourceRef(String resourceId) =>
      _firestore.collection(ResourceService.collection).doc(resourceId);

  /// Creates a pending borrow request for a student or teacher.
  Future<String> requestBorrow({
    required String resourceId,
    required String resourceName,
    required String resourceCode,
    required String userId,
    required String userName,
    required String userRole,
    required DateTime borrowDate,
    required DateTime expectedReturnDate,
    required int requestedQuantity,
    String? purpose,
  }) async {
    final role = userRole.trim().toLowerCase();
    final quantity = requestedQuantity;

    if (role == 'student' && quantity != 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-quantity',
        message: 'Students can only borrow 1 item at a time.',
      );
    }

    final resourceSnap = await _resourceRef(resourceId.trim()).get();
    if (!resourceSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'resource-not-found',
        message: 'The resource no longer exists.',
      );
    }

    final resourceData = resourceSnap.data()!;
    final available =
        _asInt(resourceData['availableQuantity'], fallback: 0);
    final maxBorrowLimit = _asInt(
      resourceData['maxBorrowLimit'],
      fallback: ResourceItem.defaultMaxBorrowLimit,
    );

    if (quantity < 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-quantity',
        message: 'Requested quantity must be at least 1.',
      );
    }
    if (quantity > maxBorrowLimit) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'exceeds-max-limit',
        message:
            'Exceeds the maximum limit set by the Property Custodian (Max: $maxBorrowLimit)',
      );
    }
    if (quantity > available) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'out-of-stock',
        message: 'Only $available item${available == 1 ? '' : 's'} available.',
      );
    }

    _validateBorrowRequest(
      resourceId: resourceId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      borrowDate: borrowDate,
      expectedReturnDate: expectedReturnDate,
    );

    final docRef = await _transactions.add({
      'resourceId': resourceId.trim(),
      'resourceName': resourceName.trim(),
      'resourceCode': resourceCode.trim(),
      'userId': userId.trim(),
      'userName': userName.trim(),
      'userRole': role,
      'requestedQuantity': quantity,
      'borrowDate': Timestamp.fromDate(_dateOnly(borrowDate)),
      'expectedReturnDate': Timestamp.fromDate(_dateOnly(expectedReturnDate)),
      'actualReturnDate': null,
      'returnSubmittedDate': null,
      'purpose': purpose?.trim() ?? '',
      'status': BorrowTransactionStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Atomically approves a pending request and decrements resource stock.
  Future<void> approveBorrow(String transactionId, String resourceId) async {
    final trimmedTxnId = transactionId.trim();
    final trimmedResourceId = resourceId.trim();

    if (trimmedTxnId.isEmpty || trimmedResourceId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction or resource id is missing.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final txnRef = _transactions.doc(trimmedTxnId);
      final resourceRef = _resourceRef(trimmedResourceId);

      final txnSnap = await transaction.get(txnRef);
      if (!txnSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'transaction-not-found',
          message: 'Borrow request was not found.',
        );
      }

      final txnData = txnSnap.data()!;
      if (txnData['status'] != BorrowTransactionStatus.pending) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-status',
          message: 'This request has already been processed.',
        );
      }

      final resourceSnap = await transaction.get(resourceRef);
      if (!resourceSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-not-found',
          message: 'The resource no longer exists.',
        );
      }

      final available =
          _asInt(resourceSnap.data()?['availableQuantity'], fallback: 0);
      final requestedQuantity = _asInt(
        txnData['requestedQuantity'],
        fallback: 1,
      );
      if (available < requestedQuantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'out-of-stock',
          message:
              'Only $available item${available == 1 ? '' : 's'} available.',
        );
      }

      transaction.update(resourceRef, {
        'availableQuantity': available - requestedQuantity,
      });
      transaction.update(txnRef, {
        'status': BorrowTransactionStatus.borrowed,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Student/teacher initiates a return with proof type and condition details.
  Future<void> submitReturn({
    required String transactionId,
    required String returnType,
    required String itemConditionNotes,
    String? overdueReason,
  }) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final trimmedReturnType = returnType.trim();
    if (!ReturnType.all.contains(trimmedReturnType)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-return-type',
        message: 'Please select a valid return type.',
      );
    }

    final trimmedCondition = itemConditionNotes.trim();
    if (trimmedCondition.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-condition',
        message: 'Item condition details are required.',
      );
    }

    final txnRef = _transactions.doc(trimmedTxnId);
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'transaction-not-found',
        message: 'Borrow record was not found.',
      );
    }

    final txnData = txnSnap.data()!;
    final status = txnData['status']?.toString();
    if (status != BorrowTransactionStatus.borrowed &&
        status != BorrowTransactionStatus.returnRejected) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'This item cannot be submitted for return right now.',
      );
    }

    final expectedReturn = _dateFrom(txnData['expectedReturnDate']);
    final isOverdue = expectedReturn != null &&
        DateTime.now().isAfter(expectedReturn);
    final trimmedOverdueReason = overdueReason?.trim();

    if (isOverdue &&
        (trimmedOverdueReason == null || trimmedOverdueReason.isEmpty)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-overdue-reason',
        message: 'Please provide a reason for the overdue return.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.returnPending,
      'returnType': trimmedReturnType,
      'itemConditionNotes': trimmedCondition,
      'returnSubmittedDate': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
      if (isOverdue && trimmedOverdueReason != null)
        'overdueReason': trimmedOverdueReason
      else
        'overdueReason': FieldValue.delete(),
    });
  }

  /// Student/teacher initiates a return — moves item to custodian verification queue.
  Future<void> submitReturnRequest(String transactionId) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final txnRef = _transactions.doc(trimmedTxnId);
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'transaction-not-found',
        message: 'Borrow record was not found.',
      );
    }

    final status = txnSnap.data()?['status']?.toString();
    if (status != BorrowTransactionStatus.borrowed &&
        status != BorrowTransactionStatus.returnRejected) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'This item cannot be submitted for return right now.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.returnPending,
      'returnSubmittedDate': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
    });
  }

  /// Re-submits a rejected return for custodian review.
  Future<void> resubmitReturnRequest(String transactionId) =>
      submitReturnRequest(transactionId);

  /// Atomically verifies a return and restores stock.
  Future<void> returnResource(String transactionId, String resourceId) =>
      verifyReturn(transactionId, resourceId);

  /// Atomically verifies a return and restores stock.
  Future<void> verifyReturn(String transactionId, String resourceId) async {
    final trimmedTxnId = transactionId.trim();
    final trimmedResourceId = resourceId.trim();

    if (trimmedTxnId.isEmpty || trimmedResourceId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction or resource id is missing.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final txnRef = _transactions.doc(trimmedTxnId);
      final resourceRef = _resourceRef(trimmedResourceId);

      final txnSnap = await transaction.get(txnRef);
      if (!txnSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'transaction-not-found',
          message: 'Return request was not found.',
        );
      }

      final txnData = txnSnap.data()!;
      if (txnData['status'] != BorrowTransactionStatus.returnPending) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-status',
          message: 'Only pending return requests can be verified.',
        );
      }

      final resourceSnap = await transaction.get(resourceRef);
      if (!resourceSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-not-found',
          message: 'The resource no longer exists.',
        );
      }

      final available =
          _asInt(resourceSnap.data()?['availableQuantity'], fallback: 0);
      final total = _asInt(resourceSnap.data()?['totalQuantity'], fallback: 1);
      final requestedQuantity = _asInt(
        txnData['requestedQuantity'],
        fallback: 1,
      );

      transaction.update(resourceRef, {
        'availableQuantity':
            (available + requestedQuantity).clamp(0, total),
      });
      transaction.update(txnRef, {
        'status': BorrowTransactionStatus.returned,
        'actualReturnDate': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Custodian rejects a pending return request.
  Future<void> rejectReturn(
    String transactionId, {
    String? rejectionReason,
  }) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final txnRef = _transactions.doc(trimmedTxnId);
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'transaction-not-found',
        message: 'Return request was not found.',
      );
    }

    if (txnSnap.data()?['status'] != BorrowTransactionStatus.returnPending) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'Only pending return requests can be rejected.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.returnRejected,
      if (rejectionReason?.trim().isNotEmpty ?? false)
        'rejectionReason': rejectionReason!.trim(),
    });
  }

  /// Rejects a pending borrow request without changing inventory.
  Future<void> rejectBorrow(
    String transactionId, {
    String? rejectionReason,
  }) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final txnRef = _transactions.doc(trimmedTxnId);
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'transaction-not-found',
        message: 'Borrow request was not found.',
      );
    }

    if (txnSnap.data()?['status'] != BorrowTransactionStatus.pending) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'Only pending requests can be rejected.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.borrowRejected,
      if (rejectionReason?.trim().isNotEmpty ?? false)
        'rejectionReason': rejectionReason!.trim(),
    });
  }

  /// All borrow transactions for a user, newest first.
  Stream<List<BorrowTransaction>> getStudentBorrowHistory(String userId) {
    final trimmedUserId = userId.trim();
    return _transactions
        .where('userId', isEqualTo: trimmedUserId)
        .snapshots()
        .map(_mapAndSortTransactions);
  }

  /// Pending and rejected borrow requests for the My Requests → Borrow tab.
  Stream<List<BorrowTransaction>> watchBorrowRequests(String userId) {
    return getStudentBorrowHistory(userId).map(
      (transactions) => transactions
          .where(
            (transaction) =>
                BorrowTransactionStatus.borrowRequestStatuses
                    .contains(transaction.status) ||
                transaction.isPending ||
                transaction.isBorrowRejected,
          )
          .toList(),
    );
  }

  /// Return lifecycle transactions for the My Requests → Return tab.
  Stream<List<BorrowTransaction>> watchReturnRequests(String userId) {
    return getStudentBorrowHistory(userId).map(
      (transactions) => transactions
          .where(
            (transaction) =>
                BorrowTransactionStatus.returnRequestStatuses
                    .contains(transaction.status),
          )
          .toList(),
    );
  }

  /// Active borrowings for a user (status = borrowed).
  Stream<List<BorrowTransaction>> watchActiveBorrowings(String userId) {
    final trimmedUserId = userId.trim();
    return _transactions
        .where('userId', isEqualTo: trimmedUserId)
        .where('status', isEqualTo: BorrowTransactionStatus.borrowed)
        .snapshots()
        .map(_mapAndSortTransactions);
  }

  /// Pending requests for custodian approval.
  Stream<List<BorrowTransaction>> getPendingRequests() {
    return _transactions
        .where('status', isEqualTo: BorrowTransactionStatus.pending)
        .snapshots()
        .map(_mapAndSortTransactions);
  }

  /// Return requests awaiting custodian verification.
  Stream<List<BorrowTransaction>> watchPendingReturnRequests() {
    return _transactions
        .where('status', isEqualTo: BorrowTransactionStatus.returnPending)
        .snapshots()
        .map(_mapAndSortTransactions);
  }

  /// Finds a pending return by resource asset code (for QR lookup).
  Future<BorrowTransaction?> findPendingReturnByResourceCode(
    String resourceCode,
  ) async {
    final normalized = resourceCode.trim();
    if (normalized.isEmpty) return null;

    final snapshot = await _transactions
        .where('resourceCode', isEqualTo: normalized)
        .where('status', isEqualTo: BorrowTransactionStatus.returnPending)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return BorrowTransaction.fromFirestore(snapshot.docs.first);
  }

  /// Whether the user already has a pending request for this resource.
  Future<bool> hasPendingRequest(String userId, String resourceId) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId.trim())
        .where('resourceId', isEqualTo: resourceId.trim())
        .where('status', isEqualTo: BorrowTransactionStatus.pending)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  List<BorrowTransaction> _mapAndSortTransactions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs.map(BorrowTransaction.fromFirestore).toList();
    items.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
    return items;
  }

  void _validateBorrowRequest({
    required String resourceId,
    required String userId,
    required String userName,
    required String userRole,
    required DateTime borrowDate,
    required DateTime expectedReturnDate,
  }) {
    if (resourceId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-resource',
        message: 'Resource id is required.',
      );
    }
    if (userId.trim().isEmpty || userName.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-user',
        message: 'User information is missing.',
      );
    }
    final role = userRole.trim().toLowerCase();
    if (role != 'student' && role != 'teacher') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-role',
        message: 'Only students and teachers can request borrows.',
      );
    }
    final today = _dateOnly(DateTime.now());
    final borrowDay = _dateOnly(borrowDate);
    final returnDay = _dateOnly(expectedReturnDate);

    if (borrowDay.isBefore(today)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-date',
        message: 'Borrow date cannot be in the past.',
      );
    }
    if (returnDay.isBefore(borrowDay)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-date',
        message: 'Return date cannot be before the borrow date.',
      );
    }
    final maxReturnDay = borrowDay.add(const Duration(days: 7));
    if (returnDay.isAfter(maxReturnDay)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-date',
        message: 'Maximum borrow duration is 1 week (7 days).',
      );
    }
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String friendlyErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'out-of-stock':
          return error.message ?? 'This item is currently out of stock.';
        case 'exceeds-max-limit':
        case 'invalid-quantity':
          return error.message ?? 'Invalid borrow quantity.';
        case 'invalid-status':
        case 'transaction-not-found':
        case 'resource-not-found':
        case 'invalid-date':
        case 'invalid-user':
        case 'invalid-role':
        case 'invalid-return-type':
        case 'invalid-condition':
        case 'missing-overdue-reason':
          return error.message ?? 'Unable to process the borrow request.';
        default:
          return error.message ??
              'Unable to complete the borrow operation. Please try again.';
      }
    }
    return error.toString();
  }
}

