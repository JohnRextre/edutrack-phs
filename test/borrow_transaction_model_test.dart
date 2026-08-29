import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutrack_phs/models/borrow_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BorrowTransaction required return type', () {
    test('parses and serializes corrective return guidance', () {
      final generated = BorrowTransaction.fromMap('tx-1', {
        'resourceId': 'res-1',
        'resourceName': 'Laptop',
        'resourceCode': 'LAP-01',
        'userId': 'user-1',
        'userName': 'Alice Student',
        'userRole': 'student',
        'borrowDate': Timestamp.fromDate(DateTime(2024, 1, 10, 9, 0)),
        'expectedReturnDate': Timestamp.fromDate(DateTime(2024, 1, 17, 9, 0)),
        'status': BorrowTransactionStatus.returnRejected,
        'rejectionReason': 'Missing proof of payment.',
        'requiredReturnType': 'Payment',
      });

      expect(generated.requiredReturnType, 'Payment');
      expect(generated.toMap()['requiredReturnType'], 'Payment');
      expect(generated.rejectionReason, 'Missing proof of payment.');
    });

    test(
      'tracks all active student borrow statuses that block duplicate requests',
      () {
        expect(
          BorrowTransactionStatus.studentActiveBorrowStatuses,
          containsAll([
            BorrowTransactionStatus.pending,
            BorrowTransactionStatus.borrowed,
            BorrowTransactionStatus.returnPending,
            BorrowTransactionStatus.returnRejected,
          ]),
        );
        expect(
          BorrowTransactionStatus.studentActiveBorrowStatuses,
          isNot(contains(BorrowTransactionStatus.returned)),
        );
        expect(
          BorrowTransactionStatus.studentActiveBorrowStatuses,
          isNot(contains(BorrowTransactionStatus.borrowRejected)),
        );
      },
    );
  });
}
