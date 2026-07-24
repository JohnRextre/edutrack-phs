import 'package:flutter/material.dart';

class CustodianDashboardScreen extends StatelessWidget {
  const CustodianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        _PageHeader(onExport: () {}),
        const SizedBox(height: 22),
        const _SummaryGrid(),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return const Column(
                children: [
                  _RecentBorrowRequests(),
                  SizedBox(height: 16),
                  _BorrowingInsights(),
                ],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _RecentBorrowRequests()),
                SizedBox(width: 16),
                Expanded(flex: 2, child: _BorrowingInsights()),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return const Column(
                children: [
                  _RecentReturnVerification(),
                  SizedBox(height: 16),
                  _CategoryAndAddResource(),
                ],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _RecentReturnVerification()),
                SizedBox(width: 16),
                Expanded(flex: 2, child: _CategoryAndAddResource()),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onExport});
  final VoidCallback onExport;

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
              'Property Custodian Summary - October 2023',
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
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000 ? 5 : 2;
      return GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 5 ? 1.55 : 1.65,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _SummaryCard(
            'Total Resources',
            '12,450',
            Icons.inventory_2_outlined,
            primary: true,
          ),
          _SummaryCard('Available', '9,820', Icons.check_circle_outline),
          _SummaryCard('Borrowed', '2,415', Icons.book_outlined),
          _SummaryCard(
            'Pending Requests',
            '45',
            Icons.pending_actions_outlined,
          ),
          _SummaryCard(
            'Pending Returns',
            '12',
            Icons.assignment_return_outlined,
          ),
          _SummaryCard('Overdue', '128', Icons.warning_amber_outlined),
          _SummaryCard('Damaged', '42', Icons.broken_image_outlined),
          _SummaryCard('Lost', '15', Icons.search_off_outlined),
        ],
      );
    },
  );
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: primary ? colors.onPrimary : colors.primary),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: primary ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
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
  const _Panel({required this.title, required this.child, this.actionLabel});
  final String title;
  final Widget child;
  final String? actionLabel;

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
                TextButton(onPressed: () {}, child: Text(actionLabel!)),
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
  const _RecentBorrowRequests();

  @override
  Widget build(BuildContext context) => const _Panel(
    title: 'Recent Borrow Requests',
    actionLabel: 'View All',
    child: Column(
      children: [
        _RequestRow(
          'JD',
          'Juan Dela Cruz',
          'Science Textbook Vol 2',
          'Oct 24, 2023',
          'Pending',
        ),
        Divider(height: 22),
        _RequestRow(
          'MS',
          'Maria Santos',
          'Microscope Kit #04',
          'Oct 25, 2023',
          'Pending',
        ),
        Divider(height: 22),
        _RequestRow(
          'PR',
          'Pedro Reyes',
          'Noli Me Tangere',
          'Oct 26, 2023',
          'Reviewed',
        ),
      ],
    ),
  );
}

class _RequestRow extends StatelessWidget {
  const _RequestRow(
    this.initials,
    this.borrower,
    this.resource,
    this.date,
    this.status,
  );
  final String initials;
  final String borrower;
  final String resource;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(initials, style: Theme.of(context).textTheme.labelSmall),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: Text(
          borrower,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      Expanded(flex: 2, child: Text(resource)),
      Expanded(child: Text(date)),
      _StatusPill(status),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reviewed = status == 'Reviewed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: reviewed
            ? colors.surfaceContainerHighest
            : colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _BorrowingInsights extends StatelessWidget {
  const _BorrowingInsights();

  @override
  Widget build(BuildContext context) => const _Panel(
    title: 'Monthly Borrowing Stats',
    child: Column(
      children: [
        SizedBox(height: 120, child: _MiniBars()),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Most Borrowed Categories',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 12),
        _ProgressLine('Textbooks', '45%', 0.45),
        _ProgressLine('Lab Equipment', '30%', 0.30),
        _ProgressLine('Modules', '15%', 0.15),
        _ProgressLine('Tablets/Tech', '10%', 0.10),
      ],
    ),
  );
}

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [_Bar(42), _Bar(70), _Bar(32), _Bar(88), _Bar(102)],
  );
}

class _Bar extends StatelessWidget {
  const _Bar(this.height);
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: height,
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
  const _RecentReturnVerification();

  @override
  Widget build(BuildContext context) => const _Panel(
    title: 'Recent Return Verification',
    actionLabel: 'View All',
    child: Column(
      children: [
        _ReturnRow(
          Icons.laptop_outlined,
          'Tablet - DepEd 001',
          'Ana Garcia (Gr 11)',
          'Good',
          true,
        ),
        SizedBox(height: 10),
        _ReturnRow(
          Icons.menu_book_outlined,
          'Math 10 Module 3',
          'Luis Torres (Gr 10)',
          'Torn Cover',
          false,
        ),
      ],
    ),
  );
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow(
    this.icon,
    this.resource,
    this.borrower,
    this.condition,
    this.canVerify,
  );
  final IconData icon;
  final String resource;
  final String borrower;
  final String condition;
  final bool canVerify;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(borrower, style: Theme.of(context).textTheme.bodySmall),
              Text(
                'Condition: $condition',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: canVerify ? () {} : null,
          child: Text(canVerify ? 'Verify Return' : 'Assess Damage'),
        ),
      ],
    ),
  );
}

class _CategoryAndAddResource extends StatelessWidget {
  const _CategoryAndAddResource();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _Panel(
        title: 'Most Borrowed Categories',
        child: Column(
          children: [
            _ProgressLine('Textbooks', '45%', 0.45),
            _ProgressLine('Lab Equipment', '30%', 0.30),
            _ProgressLine('Modules', '15%', 0.15),
            _ProgressLine('Tablets/Tech', '10%', 0.10),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Card(
        color: Theme.of(context).colorScheme.primary,
        child: InkWell(
          onTap: () {},
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
