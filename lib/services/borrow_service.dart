import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import 'resource_service.dart';

/// Real-time metric counts for the student/teacher dashboard.
class BorrowerDashboardMetrics {
  const BorrowerDashboardMetrics({
    required this.borrowedCount,
    required this.pendingBorrowCount,
    required this.pendingReturnCount,
    required this.overdueCount,
  });

  final int borrowedCount;
  final int pendingBorrowCount;
  final int pendingReturnCount;
  final int overdueCount;

  static const BorrowerDashboardMetrics empty = BorrowerDashboardMetrics(
    borrowedCount: 0,
    pendingBorrowCount: 0,
    pendingReturnCount: 0,
    overdueCount: 0,
  );
}

/// Firestore operations for the `borrow_transactions` collection.
class BorrowService {
  BorrowService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'borrow_transactions';

  /// Stored on auto-rejected borrow requests whose scheduled dates passed.
  static const String borrowRequestExpiredReason =
      "Expired: Property Custodian didn't take action before the requested "
      'return date.';

  /// Shorter copy shown to borrowers in cards and detail views.
  static const String borrowRequestExpiredDisplayReason =
      "Property Custodian didn't take action in time.";

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

    if (role == 'student') {
      final hasActiveBorrow = await hasActiveStudentBorrowForResource(
        userId: userId,
        resourceId: resourceId,
      );
      if (hasActiveBorrow) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'active-student-borrow-exists',
          message:
              'You currently have an active request or borrowed instance of this item. Please return your existing item before borrowing it again.',
        );
      }
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
    final available = _asInt(resourceData['availableQuantity'], fallback: 0);
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

  /// Whether a pending borrow request can no longer be approved.
  static bool isPendingBorrowRequestExpired({
    required DateTime borrowDate,
    required DateTime expectedReturnDate,
  }) {
    final today = _dateOnly(DateTime.now());
    final borrowDay = _dateOnly(borrowDate);
    final returnDay = _dateOnly(expectedReturnDate);
    return !today.isBefore(returnDay) || today.isAfter(borrowDay);
  }

  static bool isPendingBorrowTransactionExpired(BorrowTransaction transaction) {
    return transaction.isPending &&
        isPendingBorrowRequestExpired(
          borrowDate: transaction.borrowDate,
          expectedReturnDate: transaction.expectedReturnDate,
        );
  }

  static bool isExpiredBorrowRejection(BorrowTransaction transaction) {
    return transaction.isBorrowRejected &&
        (transaction.rejectionReason?.startsWith('Expired:') ?? false);
  }

  /// Approves a pending request and decrements resource stock.
  ///
  /// Uses a [WriteBatch] instead of [FirebaseFirestore.runTransaction] because
  /// Firestore transactions are unreliable on Windows desktop.
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

    final txnRef = _transactions.doc(trimmedTxnId);
    final resourceRef = _resourceRef(trimmedResourceId);

    final txnSnap = await txnRef.get();
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

    final borrowDate = _dateFrom(txnData['borrowDate']);
    final expectedReturnDate = _dateFrom(txnData['expectedReturnDate']);
    if (borrowDate != null &&
        expectedReturnDate != null &&
        isPendingBorrowRequestExpired(
          borrowDate: borrowDate,
          expectedReturnDate: expectedReturnDate,
        )) {
      await txnRef.update({
        'status': BorrowTransactionStatus.borrowRejected,
        'rejectionReason': borrowRequestExpiredReason,
      });
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'borrow-expired',
        message:
            'This borrow request has expired because the scheduled date has passed.',
      );
    }

    final resourceSnap = await resourceRef.get();
    if (!resourceSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'resource-not-found',
        message: 'The resource no longer exists.',
      );
    }

    final available = _asInt(
      resourceSnap.data()?['availableQuantity'],
      fallback: 0,
    );
    final requestedQuantity = _asInt(txnData['requestedQuantity'], fallback: 1);
    if (available < requestedQuantity) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'out-of-stock',
        message: 'Only $available item${available == 1 ? '' : 's'} available.',
      );
    }

    final batch = _firestore.batch();
    batch.update(resourceRef, {
      'availableQuantity': available - requestedQuantity,
    });
    batch.update(txnRef, {
      'status': BorrowTransactionStatus.borrowed,
      'approvedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
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
    final isOverdue =
        expectedReturn != null && DateTime.now().isAfter(expectedReturn);
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
      'requiredReturnType': FieldValue.delete(),
    });
  }

  /// Re-submits a rejected return for custodian review.
  Future<void> resubmitReturnRequest(String transactionId) =>
      submitReturnRequest(transactionId);

  /// Resubmits a rejected return using the borrower's chosen appeal remedy.
  Future<void> resubmitReturnAppeal({
    required String transactionId,
    required String appealType,
    required String appealNotes,
  }) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final trimmedAppealType = appealType.trim();
    if (![
      ReturnType.paymentProof,
      ReturnType.repairedProof,
      ReturnType.replacementProof,
    ].contains(trimmedAppealType)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-appeal-type',
        message: 'Please select a valid appeal type.',
      );
    }

    final trimmedNotes = appealNotes.trim();
    if (trimmedNotes.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-appeal-notes',
        message: 'Please provide details about your appeal resolution.',
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

    if (txnSnap.data()?['status'] != BorrowTransactionStatus.returnRejected) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'This return can only be appealed while it is rejected.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.returnPending,
      'returnType': trimmedAppealType,
      'itemConditionNotes': trimmedNotes,
      'returnSubmittedDate': FieldValue.serverTimestamp(),
    });
  }

  /// Atomically verifies a return and restores stock.
  Future<void> returnResource(String transactionId, String resourceId) =>
      verifyReturn(transactionId, resourceId);

  /// Verifies a return and restores stock.
  ///
  /// Uses a [WriteBatch] instead of [FirebaseFirestore.runTransaction] because
  /// Firestore transactions are unreliable on Windows desktop.
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

    final txnRef = _transactions.doc(trimmedTxnId);
    final resourceRef = _resourceRef(trimmedResourceId);

    final txnSnap = await txnRef.get();
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

    final resourceSnap = await resourceRef.get();
    if (!resourceSnap.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'resource-not-found',
        message: 'The resource no longer exists.',
      );
    }

    final available = _asInt(
      resourceSnap.data()?['availableQuantity'],
      fallback: 0,
    );
    final total = _asInt(resourceSnap.data()?['totalQuantity'], fallback: 1);
    final requestedQuantity = _asInt(txnData['requestedQuantity'], fallback: 1);

    final batch = _firestore.batch();
    batch.update(resourceRef, {
      'availableQuantity': (available + requestedQuantity).clamp(0, total),
    });
    batch.update(txnRef, {
      'status': BorrowTransactionStatus.returned,
      'actualReturnDate': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Custodian rejects a pending return request.
  Future<void> rejectReturn(
    String transactionId, {
    required String rejectionReason,
    required String requiredReturnType,
  }) async {
    final trimmedTxnId = transactionId.trim();
    if (trimmedTxnId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Transaction id is missing.',
      );
    }

    final reason = rejectionReason.trim();
    final requiredType = requiredReturnType.trim();
    if (reason.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-rejection-reason',
        message: 'Please provide a reason for rejecting this return.',
      );
    }
    if (requiredType.isEmpty ||
        !ReturnType.correctiveReturnTypeOptions.contains(requiredType)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-required-return-type',
        message: 'Please select a valid corrective return type.',
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
      'rejectionReason': reason,
      'requiredReturnType': requiredType,
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

  /// Marks a stale pending borrow request as auto-rejected without changing inventory.
  Future<void> expireBorrowRequest(String transactionId) async {
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

    final txnData = txnSnap.data()!;
    if (txnData['status'] != BorrowTransactionStatus.pending) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-status',
        message: 'Only pending requests can be marked expired.',
      );
    }

    final borrowDate = _dateFrom(txnData['borrowDate']);
    final expectedReturnDate = _dateFrom(txnData['expectedReturnDate']);
    if (borrowDate == null ||
        expectedReturnDate == null ||
        !isPendingBorrowRequestExpired(
          borrowDate: borrowDate,
          expectedReturnDate: expectedReturnDate,
        )) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'borrow-not-expired',
        message: 'This borrow request has not expired yet.',
      );
    }

    await txnRef.update({
      'status': BorrowTransactionStatus.borrowRejected,
      'rejectionReason': borrowRequestExpiredReason,
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

  /// Active pending borrow requests for the My Requests → Borrow tab.
  Stream<List<BorrowTransaction>> watchBorrowRequests(String userId) {
    return getStudentBorrowHistory(userId).map(
      (transactions) => transactions
          .where(
            (transaction) =>
                transaction.status == BorrowTransactionStatus.pending,
          )
          .toList(),
    );
  }

  /// Active return processes for the My Requests → Return tab.
  Stream<List<BorrowTransaction>> watchReturnRequests(String userId) {
    return getStudentBorrowHistory(userId).map(
      (transactions) => transactions
          .where(
            (transaction) =>
                transaction.status == BorrowTransactionStatus.returnPending ||
                transaction.status == BorrowTransactionStatus.returnRejected,
          )
          .toList(),
    );
  }

  /// Historical and finalized transactions for Account Activities.
  Stream<List<BorrowTransaction>> watchAccountActivities(String userId) {
    final trimmedUserId = userId.trim();
    return _transactions
        .where('userId', isEqualTo: trimmedUserId)
        .where(
          'status',
          whereIn: [
            BorrowTransactionStatus.returned,
            BorrowTransactionStatus.borrowRejected,
          ],
        )
        .snapshots()
        .map(_mapAndSortTransactions);
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

  /// Live dashboard counts for the authenticated borrower.
  Stream<BorrowerDashboardMetrics> watchBorrowerMetrics(String userId) {
    return getStudentBorrowHistory(userId).map(_metricsFromTransactions);
  }

  /// Active borrowings ordered by nearest due date first.
  Stream<List<BorrowTransaction>> watchDueSoonBorrowings(String userId) {
    return watchActiveBorrowings(userId).map((transactions) {
      final sorted = List<BorrowTransaction>.from(transactions)
        ..sort((a, b) => a.expectedReturnDate.compareTo(b.expectedReturnDate));
      return sorted;
    });
  }

  /// Recent completed borrow transactions for dashboard history.
  Stream<List<BorrowTransaction>> watchRecentBorrowingHistory(
    String userId, {
    int limit = 5,
  }) {
    return getStudentBorrowHistory(userId).map((transactions) {
      final completed =
          transactions
              .where(
                (transaction) =>
                    transaction.status == BorrowTransactionStatus.returned ||
                    transaction.isBorrowRejected,
              )
              .toList()
            ..sort(
              (a, b) => _historySortDate(b).compareTo(_historySortDate(a)),
            );
      return completed.take(limit).toList();
    });
  }

  /// Human-readable due label for dashboard list rows.
  static String dueSoonLabel(DateTime expectedReturnDate) {
    final today = _dateOnly(DateTime.now());
    final dueDay = _dateOnly(expectedReturnDate);
    final diffDays = dueDay.difference(today).inDays;

    if (diffDays < 0) {
      final overdueDays = today.difference(dueDay).inDays;
      return 'Overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}';
    }
    if (diffDays == 0) return 'Due today';
    if (diffDays == 1) return 'Due tomorrow';
    return 'Due in $diffDays days';
  }

  /// Whether an active borrowing is past its due date.
  static bool isOverdueBorrowing(BorrowTransaction transaction) {
    return transaction.status == BorrowTransactionStatus.borrowed &&
        _dateOnly(
          transaction.expectedReturnDate,
        ).isBefore(_dateOnly(DateTime.now()));
  }

  /// Subtitle for borrowing history rows on the dashboard.
  static String historySubtitle(BorrowTransaction transaction) {
    if (transaction.status == BorrowTransactionStatus.returned) {
      final date =
          transaction.actualReturnDate ?? transaction.returnSubmittedDate;
      if (date != null) {
        return 'Returned - ${_formatDisplayDate(date)}';
      }
      return 'Returned';
    }
    return 'Rejected - ${_formatDisplayDate(transaction.borrowDate)}';
  }

  static String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static BorrowerDashboardMetrics _metricsFromTransactions(
    List<BorrowTransaction> transactions,
  ) {
    var borrowedCount = 0;
    var pendingBorrowCount = 0;
    var pendingReturnCount = 0;
    var overdueCount = 0;

    for (final transaction in transactions) {
      switch (transaction.status) {
        case BorrowTransactionStatus.borrowed:
          borrowedCount++;
          if (isOverdueBorrowing(transaction)) overdueCount++;
          break;
        case BorrowTransactionStatus.pending:
          pendingBorrowCount++;
          break;
        case BorrowTransactionStatus.returnPending:
          pendingReturnCount++;
          break;
      }
    }

    return BorrowerDashboardMetrics(
      borrowedCount: borrowedCount,
      pendingBorrowCount: pendingBorrowCount,
      pendingReturnCount: pendingReturnCount,
      overdueCount: overdueCount,
    );
  }

  static DateTime _historySortDate(BorrowTransaction transaction) {
    return transaction.actualReturnDate ??
        transaction.returnSubmittedDate ??
        transaction.borrowDate;
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

  /// Whether the user already has an active student borrow for this resource.
  Future<bool> hasActiveStudentBorrowForResource({
    required String userId,
    required String resourceId,
  }) async {
    final snapshot = await _transactions
        .where('userId', isEqualTo: userId.trim())
        .where('resourceId', isEqualTo: resourceId.trim())
        .where(
          'status',
          whereIn: BorrowTransactionStatus.studentActiveBorrowStatuses,
        )
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
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
        case 'borrow-expired':
        case 'borrow-not-expired':
          return error.message ?? 'Unable to process the borrow request.';
        default:
          return error.message ??
              'Unable to complete the borrow operation. Please try again.';
      }
    }
    return error.toString();
  }
}
