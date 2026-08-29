import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/return_verification_details.dart';
import 'custodian/add_edit_resource_screen.dart';
import 'custodian/borrow_request_details_screen.dart';
import 'custodian/return_verification_details_screen.dart';

class CustodianDashboardScreen extends StatefulWidget {
  const CustodianDashboardScreen({super.key});

  @override
  State<CustodianDashboardScreen> createState() =>
      _CustodianDashboardScreenState();
}

class _CustodianDashboardScreenState extends State<CustodianDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final BorrowService _borrowService = BorrowService();
  bool _isProcessing = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Action completed successfully.');
      }
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(BorrowService.friendlyErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _exportReport(DashboardMetrics metrics) {
    final summary =
        'Total: ${DashboardService.formatCount(metrics.totalResources)} | '
        'Available: ${DashboardService.formatCount(metrics.available)} | '
        'Borrowed: ${DashboardService.formatCount(metrics.borrowed)} | '
        'Pending: ${DashboardService.formatCount(metrics.pendingRequests)} | '
        'Returns: ${DashboardService.formatCount(metrics.pendingReturns)} | '
        'Overdue: ${DashboardService.formatCount(metrics.overdue)}';
    _showSnackBar('Report summary — $summary');
  }

  Future<void> _openReturnDetails(
    BorrowTransaction transaction, {
    String? section,
  }) async {
    final result = await ReturnVerificationDetailsScreen.open(
      context,
      transaction: transaction,
      borrowerSection: section,
    );
    if (!mounted || result == null) return;

    _showReturnResultSnackBar(result);
  }

  void _showReturnResultSnackBar(bool accepted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnackBar(
        accepted ? 'Return accepted and stock restored.' : 'Return rejected.',
      );
    });
  }

  void _verifyReturn(BorrowTransaction transaction, {String? section}) {
    _openReturnDetails(transaction, section: section);
  }

  void _assessDamage(BorrowTransaction transaction) {
    final notesController = TextEditingController(
      text: DashboardService.conditionNotes(transaction),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assess Damage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.resourceName} — ${transaction.userName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Condition notes',
                hintText: 'Describe damage or item condition',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Full verification is available on the Return Verification screen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, '/custodian-return-verification');
            },
            child: const Text('Open Verification'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runWithLoading(
                () => _borrowService.rejectReturn(
                  transaction.id,
                  rejectionReason: notesController.text.trim().isEmpty
                      ? 'Damage assessment required.'
                      : notesController.text.trim(),
                  requiredReturnType:
                      ReturnType.correctiveReturnTypeOptions.first,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Return'),
          ),
        ],
      ),
    ).whenComplete(notesController.dispose);
  }

  Future<void> _openAddResource() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditResourceScreen()),
    );
    if (saved == true && mounted) {
      _showSnackBar('Resource saved successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        StreamBuilder<DashboardMetrics>(
          stream: _dashboardService.watchMetrics(),
          builder: (context, snapshot) {
            final metrics = snapshot.data ?? DashboardMetrics.empty;
            return _PageHeader(
              subtitle: DashboardService.summarySubtitle(),
              onExport: snapshot.hasData ? () => _exportReport(metrics) : null,
            );
          },
        ),
        const SizedBox(height: 22),
        _SummaryGrid(dashboardService: _dashboardService),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  _RecentBorrowRequests(dashboardService: _dashboardService),
                  const SizedBox(height: 16),
                  _BorrowingInsights(dashboardService: _dashboardService),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _RecentBorrowRequests(
                    dashboardService: _dashboardService,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _BorrowingInsights(
                    dashboardService: _dashboardService,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  _RecentReturnVerification(
                    dashboardService: _dashboardService,
                    onVerifyReturn: _verifyReturn,
                    onAssessDamage: _assessDamage,
                  ),
                  const SizedBox(height: 16),
                  _CategoryAndAddResource(
                    dashboardService: _dashboardService,
                    onAddResource: _openAddResource,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _RecentReturnVerification(
                    dashboardService: _dashboardService,
                    onVerifyReturn: _verifyReturn,
                    onAssessDamage: _assessDamage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _CategoryAndAddResource(
                    dashboardService: _dashboardService,
                    onAddResource: _openAddResource,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.subtitle, required this.onExport});

  final String subtitle;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: onExport,
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Export Report'),
      ),
    ],
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.dashboardService});

  final DashboardService dashboardService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DashboardMetrics>(
      stream: dashboardService.watchMetrics(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StreamError(message: snapshot.error.toString());
        }

        final metrics = snapshot.data ?? DashboardMetrics.empty;
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000 ? 5 : 2;
            final isCompact = constraints.maxWidth < 760;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 5 ? 1.55 : (isCompact ? 1.1 : 1.65),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryCard(
                  'Total Resources',
                  loading
                      ? '—'
                      : DashboardService.formatCount(metrics.totalResources),
                  Icons.inventory_2_outlined,
                  primary: true,
                ),
                _SummaryCard(
                  'Available',
                  loading
                      ? '—'
                      : DashboardService.formatCount(metrics.available),
                  Icons.check_circle_outline,
                ),
                _SummaryCard(
                  'Borrowed',
                  loading
                      ? '—'
                      : DashboardService.formatCount(metrics.borrowed),
                  Icons.book_outlined,
                ),
                _SummaryCard(
                  'Pending Requests',
                  loading
                      ? '—'
                      : DashboardService.formatCount(metrics.pendingRequests),
                  Icons.pending_actions_outlined,
                ),
                _SummaryCard(
                  'Pending Returns',
                  loading
                      ? '—'
                      : DashboardService.formatCount(metrics.pendingReturns),
                  Icons.assignment_return_outlined,
                ),
                _SummaryCard(
                  'Overdue',
                  loading ? '—' : DashboardService.formatCount(metrics.overdue),
                  Icons.warning_amber_outlined,
                ),
                _SummaryCard(
                  'Damaged',
                  loading ? '—' : DashboardService.formatCount(metrics.damaged),
                  Icons.broken_image_outlined,
                ),
                _SummaryCard(
                  'Lost',
                  loading ? '—' : DashboardService.formatCount(metrics.lost),
                  Icons.search_off_outlined,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.icon, {this.primary = false});

  final String label;
  final String value;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: primary ? colors.primary : colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary ? colors.onPrimary : colors.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: primary ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _RecentBorrowRequests extends StatelessWidget {
  const _RecentBorrowRequests({required this.dashboardService});

  final DashboardService dashboardService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BorrowTransaction>>(
      stream: dashboardService.watchRecentPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Panel(
            title: 'Recent Borrow Requests',
            child: _StreamError(message: snapshot.error.toString()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _Panel(
            title: 'Recent Borrow Requests',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final requests = snapshot.data ?? const [];
        return _Panel(
          title: 'Recent Borrow Requests',
          actionLabel: 'View All',
          onAction: () =>
              Navigator.pushNamed(context, '/custodian-borrow-requests'),
          child: requests.isEmpty
              ? const _EmptyPanelMessage('No pending borrow requests.')
              : Column(
                  children: [
                    for (var index = 0; index < requests.length; index++) ...[
                      if (index > 0) const Divider(height: 22),
                      _RequestRow(transaction: requests[index]),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final section = transaction.userRole == 'teacher' ? 'Teacher' : 'Student';
    return InkWell(
      onTap: () => BorrowRequestDetailsScreen.open(
        context,
        transaction: transaction,
        borrowerSection: section,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                DashboardService.initialsFromName(transaction.userName),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Text(
                transaction.userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(flex: 2, child: Text(transaction.resourceName)),
            Expanded(
              child: Text(
                DashboardService.formatDisplayDate(transaction.borrowDate),
              ),
            ),
            const _StatusPill('Pending'),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _BorrowingInsights extends StatelessWidget {
  const _BorrowingInsights({required this.dashboardService});

  final DashboardService dashboardService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryStat>>(
      stream: dashboardService.watchCategoryBreakdown(),
      builder: (context, categorySnapshot) {
        return StreamBuilder<List<int>>(
          stream: dashboardService.watchMonthlyBorrowCounts(),
          builder: (context, monthlySnapshot) {
            if (categorySnapshot.hasError || monthlySnapshot.hasError) {
              return _Panel(
                title: 'Monthly Borrowing Stats',
                child: _StreamError(
                  message: (categorySnapshot.error ?? monthlySnapshot.error)
                      .toString(),
                ),
              );
            }

            final loading =
                (categorySnapshot.connectionState == ConnectionState.waiting &&
                    !categorySnapshot.hasData) ||
                (monthlySnapshot.connectionState == ConnectionState.waiting &&
                    !monthlySnapshot.hasData);

            if (loading) {
              return const _Panel(
                title: 'Monthly Borrowing Stats',
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final categories = categorySnapshot.data ?? const <CategoryStat>[];
            final monthlyCounts = monthlySnapshot.data ?? const <int>[];

            return _Panel(
              title: 'Monthly Borrowing Stats',
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: _MiniBars(counts: monthlyCounts),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Most Borrowed Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (categories.every((item) => item.count == 0))
                    const _EmptyPanelMessage(
                      'No borrow history yet for category breakdown.',
                    )
                  else
                    for (final category in categories)
                      _ProgressLine(
                        category.label,
                        category.percentageLabel,
                        category.percentage,
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(child: Text('No monthly data yet.'));
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    const maxHeight = 102.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final count in counts)
          _Bar(maxCount == 0 ? 8 : (count / maxCount) * maxHeight),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.height);

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: height.clamp(8, 102),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.label, this.value, this.progress);

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress, minHeight: 6),
      ],
    ),
  );
}

class _RecentReturnVerification extends StatelessWidget {
  const _RecentReturnVerification({
    required this.dashboardService,
    required this.onVerifyReturn,
    required this.onAssessDamage,
  });

  final DashboardService dashboardService;
  final void Function(BorrowTransaction transaction, {String? section})
  onVerifyReturn;
  final ValueChanged<BorrowTransaction> onAssessDamage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: dashboardService.watchUserSections(),
      builder: (context, sectionSnapshot) {
        final sections = sectionSnapshot.data ?? const {};

        return StreamBuilder<List<BorrowTransaction>>(
          stream: dashboardService.watchRecentPendingReturns(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Panel(
                title: 'Recent Return Verification',
                child: _StreamError(message: snapshot.error.toString()),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _Panel(
                title: 'Recent Return Verification',
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final returns = snapshot.data ?? const [];
            return _Panel(
              title: 'Recent Return Verification',
              actionLabel: 'View All',
              onAction: () => Navigator.pushNamed(
                context,
                '/custodian-return-verification',
              ),
              child: returns.isEmpty
                  ? const _EmptyPanelMessage(
                      'No returns awaiting verification.',
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < returns.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 10),
                          _ReturnRow(
                            transaction: returns[index],
                            section: sections[returns[index].userId],
                            onVerifyReturn: () => onVerifyReturn(
                              returns[index],
                              section: sections[returns[index].userId],
                            ),
                            onAssessDamage: () =>
                                onAssessDamage(returns[index]),
                          ),
                        ],
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({
    required this.transaction,
    required this.section,
    required this.onVerifyReturn,
    required this.onAssessDamage,
  });

  final BorrowTransaction transaction;
  final String? section;
  final VoidCallback onVerifyReturn;
  final VoidCallback onAssessDamage;

  @override
  Widget build(BuildContext context) {
    final overdue = isReturnOverdue(transaction);
    final conditionNotes = DashboardService.conditionNotes(transaction);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onVerifyReturn,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.assignment_return_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.resourceName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DashboardService.borrowerSubtitle(
                        transaction,
                        section: section,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ReturnTypeBadge(
                          returnType: transaction.returnType,
                          compact: true,
                        ),
                        if (overdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Overdue',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Condition: $conditionNotes',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: onVerifyReturn,
                    child: const Text('Verify Return'),
                  ),
                  TextButton(
                    onPressed: onAssessDamage,
                    child: const Text('Assess Damage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryAndAddResource extends StatelessWidget {
  const _CategoryAndAddResource({
    required this.dashboardService,
    required this.onAddResource,
  });

  final DashboardService dashboardService;
  final VoidCallback onAddResource;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<List<CategoryStat>>(
          stream: dashboardService.watchCategoryBreakdown(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Panel(
                title: 'Most Borrowed Categories',
                child: _StreamError(message: snapshot.error.toString()),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _Panel(
                title: 'Most Borrowed Categories',
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final categories = snapshot.data ?? const <CategoryStat>[];
            return _Panel(
              title: 'Most Borrowed Categories',
              child: categories.every((item) => item.count == 0)
                  ? const _EmptyPanelMessage('No borrow history yet.')
                  : Column(
                      children: [
                        for (final category in categories)
                          _ProgressLine(
                            category.label,
                            category.percentageLabel,
                            category.percentage,
                          ),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 14),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: InkWell(
            onTap: onAddResource,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Resource',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Register a new item to the inventory',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _StreamError extends StatelessWidget {
  const _StreamError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
