import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import 'auth_service.dart';
import 'borrow_service.dart';
import 'resource_service.dart';

/// Aggregated metric counts for the Property Custodian dashboard.
class DashboardMetrics {
  const DashboardMetrics({
    required this.totalResources,
    required this.available,
    required this.borrowed,
    required this.pendingRequests,
    required this.pendingReturns,
    required this.overdue,
    required this.damaged,
    required this.lost,
  });

  final int totalResources;
  final int available;
  final int borrowed;
  final int pendingRequests;
  final int pendingReturns;
  final int overdue;
  final int damaged;
  final int lost;

  static const DashboardMetrics empty = DashboardMetrics(
    totalResources: 0,
    available: 0,
    borrowed: 0,
    pendingRequests: 0,
    pendingReturns: 0,
    overdue: 0,
    damaged: 0,
    lost: 0,
  );
}

/// Category share used for dashboard progress bars.
class CategoryStat {
  const CategoryStat({
    required this.label,
    required this.percentage,
    required this.count,
  });

  final String label;
  final double percentage;
  final int count;

  String get percentageLabel => '${(percentage * 100).round()}%';
}

/// Real-time Firestore aggregations for the Property Custodian dashboard.
class DashboardService {
  DashboardService({
    FirebaseFirestore? firestore,
    ResourceService? resourceService,
    BorrowService? borrowService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _resourceService = resourceService ?? ResourceService(),
        _borrowService = borrowService ?? BorrowService();

  final FirebaseFirestore _firestore;
  final ResourceService _resourceService;
  final BorrowService _borrowService;

  static const List<String> categoryLabels = [
    'Textbooks',
    'Lab Equipment',
    'Modules',
    'Tablets/Tech',
  ];

  /// Live summary metrics derived from `resources` and `borrow_transactions`.
  Stream<DashboardMetrics> watchMetrics() {
    return _combineLatest(
      _resourceService.watchResources(),
      _watchAllTransactions(),
      _computeMetrics,
    );
  }

  /// Top [limit] pending borrow requests, newest first.
  Stream<List<BorrowTransaction>> watchRecentPendingRequests({int limit = 3}) {
    return _borrowService.getPendingRequests().map(
          (requests) => requests.take(limit).toList(growable: false),
        );
  }

  /// Live map of user id → department/section for borrower subtitles.
  Stream<Map<String, String>> watchUserSections() {
    return _firestore.collection(AuthService.usersCollection).snapshots().map(
      (snapshot) {
        return {
          for (final doc in snapshot.docs)
            doc.id: (doc.data()['departmentOrSection'] ?? '').toString(),
        };
      },
    );
  }

  /// Top [limit] return requests awaiting verification, newest first.
  Stream<List<BorrowTransaction>> watchRecentPendingReturns({int limit = 3}) {
    return _borrowService.watchPendingReturnRequests().map((requests) {
      final sorted = List<BorrowTransaction>.from(requests)
        ..sort((a, b) {
          final aDate = a.returnSubmittedDate ?? a.borrowDate;
          final bDate = b.returnSubmittedDate ?? b.borrowDate;
          return bDate.compareTo(aDate);
        });
      return sorted.take(limit).toList(growable: false);
    });
  }

  /// Percentage breakdown of borrow history by display category.
  Stream<List<CategoryStat>> watchCategoryBreakdown() {
    return _combineLatest(
      _resourceService.watchResources(),
      _watchAllTransactions(),
      _computeCategoryBreakdown,
    );
  }

  /// Borrow counts for the last [months] calendar months (oldest → newest).
  Stream<List<int>> watchMonthlyBorrowCounts({int months = 5}) {
    return _watchAllTransactions().map(
      (transactions) => _computeMonthlyCounts(transactions, months),
    );
  }

  Stream<List<BorrowTransaction>> _watchAllTransactions() {
    return _firestore.collection(BorrowService.collection).snapshots().map(
      (snapshot) {
        final items =
            snapshot.docs.map(BorrowTransaction.fromFirestore).toList();
        items.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
        return items;
      },
    );
  }

  DashboardMetrics _computeMetrics(
    List<ResourceItem> resources,
    List<BorrowTransaction> transactions,
  ) {
    final totalResources = resources.fold<int>(
      0,
      (total, item) => total + item.totalQuantity,
    );
    final available = resources.fold<int>(
      0,
      (total, item) => total + item.availableQuantity,
    );
    final damaged = _countDamaged(resources);
    final lost = _countLost(resources);

    var borrowed = 0;
    var pendingRequests = 0;
    var pendingReturns = 0;
    var overdue = 0;

    final now = DateTime.now();
    for (final transaction in transactions) {
      if (transaction.status == BorrowTransactionStatus.borrowed) {
        borrowed++;
        if (transaction.expectedReturnDate.isBefore(now)) {
          overdue++;
        }
      } else if (transaction.status == BorrowTransactionStatus.pending) {
        pendingRequests++;
      } else if (transaction.status == BorrowTransactionStatus.returnPending) {
        pendingReturns++;
      }
    }

    return DashboardMetrics(
      totalResources: totalResources,
      available: available,
      borrowed: borrowed,
      pendingRequests: pendingRequests,
      pendingReturns: pendingReturns,
      overdue: overdue,
      damaged: damaged,
      lost: lost,
    );
  }

  int _countDamaged(List<ResourceItem> resources) {
    var count = 0;
    for (final resource in resources) {
      if (resource.damagedQuantity > 0) {
        count += resource.damagedQuantity;
        continue;
      }
      if (_statusIndicates(resource, const ['damaged', 'repair'])) {
        count++;
      }
    }
    return count;
  }

  int _countLost(List<ResourceItem> resources) {
    var count = 0;
    for (final resource in resources) {
      if (resource.lostQuantity > 0) {
        count += resource.lostQuantity;
        continue;
      }
      if (_statusIndicates(resource, const ['lost', 'missing'])) {
        count++;
      }
    }
    return count;
  }

  bool _statusIndicates(ResourceItem resource, List<String> keywords) {
    final values = [
      resource.condition,
      resource.inventoryStatus,
    ].map((value) => value.toLowerCase()).where((value) => value.isNotEmpty);

    for (final value in values) {
      if (keywords.any(value.contains)) return true;
    }
    return false;
  }

  List<CategoryStat> _computeCategoryBreakdown(
    List<ResourceItem> resources,
    List<BorrowTransaction> transactions,
  ) {
    final resourceById = {for (final item in resources) item.id: item};
    final counts = {
      for (final label in categoryLabels) label: 0,
    };

    for (final transaction in transactions) {
      if (!_countsTowardBorrowHistory(transaction.status)) continue;
      final bucket = _categoryBucket(
        resourceById[transaction.resourceId],
        transaction,
      );
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (acc, value) => acc + value);
    if (total == 0) {
      return categoryLabels
          .map((label) => CategoryStat(label: label, percentage: 0, count: 0))
          .toList(growable: false);
    }

    return categoryLabels
        .map(
          (label) => CategoryStat(
            label: label,
            percentage: counts[label]! / total,
            count: counts[label]!,
          ),
        )
        .toList(growable: false);
  }

  List<int> _computeMonthlyCounts(
    List<BorrowTransaction> transactions,
    int months,
  ) {
    if (months <= 0) return const [];

    final now = DateTime.now();
    final counts = List<int>.filled(months, 0);

    for (var index = 0; index < months; index++) {
      final monthOffset = months - 1 - index;
      final monthAnchor = DateTime(now.year, now.month - monthOffset, 1);
      final monthStart = DateTime(monthAnchor.year, monthAnchor.month, 1);
      final monthEnd = DateTime(
        monthAnchor.year,
        monthAnchor.month + 1,
        0,
        23,
        59,
        59,
        999,
      );

      counts[index] = transactions.where((transaction) {
        if (!_countsTowardBorrowHistory(transaction.status)) return false;
        final borrowDate = transaction.borrowDate;
        return !borrowDate.isBefore(monthStart) &&
            !borrowDate.isAfter(monthEnd);
      }).length;
    }

    return counts;
  }

  bool _countsTowardBorrowHistory(String status) {
    return status == BorrowTransactionStatus.borrowed ||
        status == BorrowTransactionStatus.returned ||
        status == BorrowTransactionStatus.returnPending ||
        status == BorrowTransactionStatus.returnRejected;
  }

  String _categoryBucket(ResourceItem? resource, BorrowTransaction transaction) {
    if (resource != null) {
      final mainCategory =
          ResourceTaxonomy.normalizeMainCategory(resource.mainCategory);
      final itemType = resource.itemType.toLowerCase();
      final subCategory = resource.subCategory.toLowerCase();

      if (mainCategory == ResourceTaxonomy.mainCategoryIct ||
          itemType.contains('laptop') ||
          itemType.contains('tablet') ||
          itemType.contains('computer') ||
          itemType.contains('projector') ||
          itemType.contains('printer')) {
        return 'Tablets/Tech';
      }

      if (itemType.contains('module') || itemType.contains('workbook')) {
        return 'Modules';
      }

      if (subCategory.contains('science') ||
          subCategory.contains('lab') ||
          itemType.contains('equipment') ||
          itemType.contains('laboratory') ||
          itemType.contains('microscope') ||
          itemType.contains('glassware')) {
        return 'Lab Equipment';
      }

      if (itemType.contains('textbook') ||
          itemType.contains('book') ||
          itemType.contains('guide') ||
          mainCategory == ResourceTaxonomy.mainCategoryGeneralLearning) {
        return 'Textbooks';
      }
    }

    final name = transaction.resourceName.toLowerCase();
    if (name.contains('tablet') ||
        name.contains('laptop') ||
        name.contains('computer')) {
      return 'Tablets/Tech';
    }
    if (name.contains('module')) return 'Modules';
    if (name.contains('microscope') ||
        name.contains('lab') ||
        name.contains('equipment')) {
      return 'Lab Equipment';
    }

    return 'Textbooks';
  }

  Stream<R> _combineLatest<A, B, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    R Function(A, B) combiner,
  ) {
    late StreamSubscription<A> subscriptionA;
    late StreamSubscription<B> subscriptionB;
    A? latestA;
    B? latestB;
    var isClosed = false;

    final controller = StreamController<R>.broadcast(
      onListen: () {},
      onCancel: () async {
        isClosed = true;
        await subscriptionA.cancel();
        await subscriptionB.cancel();
      },
    );

    void emitIfReady() {
      if (isClosed || latestA == null || latestB == null) return;
      controller.add(combiner(latestA as A, latestB as B));
    }

    subscriptionA = streamA.listen(
      (value) {
        latestA = value;
        emitIfReady();
      },
      onError: controller.addError,
    );

    subscriptionB = streamB.listen(
      (value) {
        latestB = value;
        emitIfReady();
      },
      onError: controller.addError,
    );

    return controller.stream;
  }

  static String formatCount(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;

    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[index]);
    }
    return buffer.toString();
  }

  static String formatDisplayDate(DateTime date) {
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

  static String initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String borrowerSubtitle(
    BorrowTransaction transaction, {
    String? section,
  }) {
    final role = transaction.userRole.trim().toLowerCase();
    final roleLabel = role.isEmpty
        ? 'Borrower'
        : '${role[0].toUpperCase()}${role.substring(1)}';
    final sectionLabel = section?.trim();
    if (sectionLabel != null && sectionLabel.isNotEmpty) {
      return '${transaction.userName} · $sectionLabel ($roleLabel)';
    }
    return '${transaction.userName} ($roleLabel)';
  }

  static String conditionNotes(BorrowTransaction transaction) {
    final itemCondition = transaction.itemConditionNotes?.trim() ?? '';
    if (itemCondition.isNotEmpty) return itemCondition;
    final purpose = transaction.purpose.trim();
    if (purpose.isNotEmpty) return purpose;
    return 'Not reported';
  }

  static String returnTypeLabel(BorrowTransaction transaction) {
    final type = transaction.returnType?.trim();
    if (type == null || type.isEmpty) return 'Not specified';
    return ReturnType.labelFor(type);
  }

  static String summarySubtitle() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return 'Property Custodian Summary - ${months[now.month - 1]} ${now.year}';
  }
}
