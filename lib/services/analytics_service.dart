import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';

enum AnalyticsDatePreset { thisWeek, thisMonth, thisSemester, custom }

class AnalyticsDateRange {
  const AnalyticsDateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  bool contains(DateTime value) {
    final normalized = _dateOnly(value);
    return !normalized.isBefore(_dateOnly(start)) &&
        !normalized.isAfter(_dateOnly(end));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class ResourceBorrowRank {
  const ResourceBorrowRank({
    required this.resourceId,
    required this.resourceName,
    required this.borrowCount,
    required this.availableQuantity,
    required this.stockLabel,
  });

  final String resourceId;
  final String resourceName;
  final int borrowCount;
  final int availableQuantity;
  final String stockLabel;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.range,
    required this.totalBorrowings,
    required this.onTimeReturnRate,
    required this.overdueRate,
    required this.activeBorrowers,
    required this.resolutionBreakdown,
    required this.categoryDistribution,
    required this.topResources,
    required this.damagedOrReplacedCount,
  });

  final AnalyticsDateRange range;
  final int totalBorrowings;
  final double onTimeReturnRate;
  final double overdueRate;
  final int activeBorrowers;
  final Map<String, int> resolutionBreakdown;
  final Map<String, double> categoryDistribution;
  final List<ResourceBorrowRank> topResources;
  final int damagedOrReplacedCount;

  static final AnalyticsSummary empty = AnalyticsSummary(
    range: AnalyticsDateRange(
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: DateTime.fromMillisecondsSinceEpoch(0),
      label: 'No Data',
    ),
    totalBorrowings: 0,
    onTimeReturnRate: 0,
    overdueRate: 0,
    activeBorrowers: 0,
    resolutionBreakdown: <String, int>{},
    categoryDistribution: <String, double>{},
    topResources: <ResourceBorrowRank>[],
    damagedOrReplacedCount: 0,
  );

  bool get isEmpty => totalBorrowings == 0 && categoryDistribution.isEmpty;
}

class AnalyticsService {
  AnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String borrowTransactionsCollection = 'borrow_transactions';
  static const String resourcesCollection = 'resources';

  Stream<AnalyticsSummary> watchSummary({
    AnalyticsDatePreset preset = AnalyticsDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return _firestore
        .collection(borrowTransactionsCollection)
        .snapshots()
        .asyncMap(
          (_) => fetchSummary(
            preset: preset,
            customStart: customStart,
            customEnd: customEnd,
          ),
        );
  }

  Future<AnalyticsSummary> fetchSummary({
    AnalyticsDatePreset preset = AnalyticsDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final range = resolveDateRange(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
    );

    final transactionSnap = await _firestore
        .collection(borrowTransactionsCollection)
        .get();

    final resourceSnap = await _firestore.collection(resourcesCollection).get();

    final resourceMap = <String, ResourceItem>{
      for (final doc in resourceSnap.docs)
        doc.id: ResourceItem.fromMap(doc.id, doc.data()),
    };

    final transactions = transactionSnap.docs
        .map((doc) => BorrowTransaction.fromMap(doc.id, doc.data()))
        .where((transaction) => range.contains(transaction.borrowDate))
        .toList();

    final approvedTransactions = transactions
        .where(_isApprovedBorrowTransaction)
        .toList();

    final activeBorrowers = <String>{
      for (final transaction in transactions)
        if (_isActiveBorrowerStatus(transaction.status)) transaction.userId,
    }.length;

    final returnBreakdown = <String, int>{
      'Good Condition': 0,
      'Payment Proof': 0,
      'Repaired': 0,
      'Replacement': 0,
    };

    final categoryCounts = <String, int>{};
    final topResourceCounts = <String, int>{};
    final topResourceNames = <String, String>{};
    final topResourceAvailability = <String, int>{};

    for (final transaction in approvedTransactions) {
      final resource = resourceMap[transaction.resourceId];
      final category = (resource?.mainCategory ?? 'Uncategorized').trim();
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      final resourceName = (resource?.itemName ?? transaction.resourceName)
          .trim();
      topResourceCounts[transaction.resourceId] =
          (topResourceCounts[transaction.resourceId] ?? 0) + 1;
      topResourceNames[transaction.resourceId] = resourceName.isEmpty
          ? transaction.resourceName
          : resourceName;
      topResourceAvailability[transaction.resourceId] =
          resource?.availableQuantity ?? 0;

      final normalizedReturnType = _normalizeReturnType(transaction.returnType);
      if (normalizedReturnType != null) {
        returnBreakdown[normalizedReturnType] =
            (returnBreakdown[normalizedReturnType] ?? 0) + 1;
      }
    }

    final onTimeCount = approvedTransactions.where((transaction) {
      if (transaction.actualReturnDate == null &&
          transaction.returnSubmittedDate == null) {
        return false;
      }
      final observedDate =
          transaction.actualReturnDate ??
          transaction.returnSubmittedDate ??
          transaction.expectedReturnDate;
      return !observedDate.isAfter(transaction.expectedReturnDate);
    }).length;

    final lateCount = approvedTransactions.where((transaction) {
      final observedDate =
          transaction.actualReturnDate ?? transaction.returnSubmittedDate;
      if (observedDate == null) return false;
      return observedDate.isAfter(transaction.expectedReturnDate);
    }).length;

    final categoryTotal = categoryCounts.values.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    final categoryDistribution = <String, double>{
      for (final entry in categoryCounts.entries)
        entry.key: categoryTotal == 0
            ? 0.0
            : (entry.value / categoryTotal).toDouble(),
    }..removeWhere((key, value) => value == 0);

    final topResources = topResourceCounts.entries.map((entry) {
      final resourceId = entry.key;
      final borrowCount = entry.value;
      final available = topResourceAvailability[resourceId] ?? 0;
      final stockLabel = available > 0 ? 'In Stock' : 'Out of Stock';
      return ResourceBorrowRank(
        resourceId: resourceId,
        resourceName: topResourceNames[resourceId] ?? 'Unknown Resource',
        borrowCount: borrowCount,
        availableQuantity: available,
        stockLabel: stockLabel,
      );
    }).toList()..sort((a, b) => b.borrowCount.compareTo(a.borrowCount));

    final repairedCount = returnBreakdown['Repaired'] ?? 0;
    final replacementCount = returnBreakdown['Replacement'] ?? 0;

    final totalReturnedItems = approvedTransactions.where((transaction) {
      return transaction.status == BorrowTransactionStatus.returned ||
          transaction.actualReturnDate != null ||
          transaction.returnSubmittedDate != null;
    }).length;

    final onTimeRate = totalReturnedItems == 0
        ? 0.0
        : ((onTimeCount / totalReturnedItems) * 100).toDouble();
    final overdueRate = totalReturnedItems == 0
        ? 0.0
        : ((lateCount / totalReturnedItems) * 100).toDouble();

    return AnalyticsSummary(
      range: range,
      totalBorrowings: approvedTransactions.length,
      onTimeReturnRate: onTimeRate,
      overdueRate: overdueRate,
      activeBorrowers: activeBorrowers,
      resolutionBreakdown: returnBreakdown,
      categoryDistribution: categoryDistribution,
      topResources: topResources.take(5).toList(),
      damagedOrReplacedCount: repairedCount + replacementCount,
    );
  }

  static AnalyticsDateRange resolveDateRange({
    AnalyticsDatePreset preset = AnalyticsDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    switch (preset) {
      case AnalyticsDatePreset.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return AnalyticsDateRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(end.year, end.month, end.day, 23, 59, 59),
          label: 'This Week',
        );
      case AnalyticsDatePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return AnalyticsDateRange(start: start, end: end, label: 'This Month');
      case AnalyticsDatePreset.thisSemester:
        final semesterStart = now.month >= 6
            ? DateTime(now.year, 6, 1)
            : DateTime(now.year, 1, 1);
        final semesterEnd = now.month >= 6
            ? DateTime(now.year, 12, 31, 23, 59, 59)
            : DateTime(now.year, 6, 30, 23, 59, 59);
        return AnalyticsDateRange(
          start: semesterStart,
          end: semesterEnd,
          label: 'This Semester',
        );
      case AnalyticsDatePreset.custom:
        final effectiveStart =
            customStart ?? now.subtract(const Duration(days: 30));
        final effectiveEnd = customEnd ?? now;
        return AnalyticsDateRange(
          start: DateTime(
            effectiveStart.year,
            effectiveStart.month,
            effectiveStart.day,
          ),
          end: DateTime(
            effectiveEnd.year,
            effectiveEnd.month,
            effectiveEnd.day,
            23,
            59,
            59,
          ),
          label: 'Custom Range',
        );
    }
  }

  static double safePercentage(num value, num total) {
    if (total == 0) return 0.0;
    return ((value / total) * 100).toDouble();
  }

  static bool _isApprovedBorrowTransaction(BorrowTransaction transaction) {
    return transaction.status == BorrowTransactionStatus.borrowed ||
        transaction.status == BorrowTransactionStatus.returnPending ||
        transaction.status == BorrowTransactionStatus.returnRejected ||
        transaction.status == BorrowTransactionStatus.returned ||
        transaction.status == BorrowTransactionStatus.overdue;
  }

  static bool _isActiveBorrowerStatus(String status) {
    return status == BorrowTransactionStatus.pending ||
        status == BorrowTransactionStatus.borrowed ||
        status == BorrowTransactionStatus.overdue ||
        status == BorrowTransactionStatus.returnPending ||
        status == BorrowTransactionStatus.returnRejected;
  }

  static String? _normalizeReturnType(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    switch (normalized) {
      case ReturnType.goodCondition:
        return 'Good Condition';
      case ReturnType.paymentProof:
        return 'Payment Proof';
      case ReturnType.repairedProof:
        return 'Repaired';
      case ReturnType.replacementProof:
        return 'Replacement';
      default:
        return null;
    }
  }
}
