import 'package:flutter/material.dart';

class CustodianReportsScreen extends StatefulWidget {
  const CustodianReportsScreen({super.key});

  @override
  State<CustodianReportsScreen> createState() => _CustodianReportsScreenState();
}

class _CustodianReportsScreenState extends State<CustodianReportsScreen> {
  String _selectedDateRange = 'This Month';

  final List<String> _dateRanges = [
    'Today',
    'This Week',
    'This Month',
    'Custom Range',
  ];

  // Sample analytics data
  final Map<String, dynamic> _analytics = {
    'totalBorrowTransactions': 156,
    'borrowTrend': '+12%',
    'overdueItems': 23,
    'damagedItems': 7,
    'mostRequestedResource': 'General Learning Resources',
    'inventoryUtilization': {
      'General Learning Resources': 0.78,
      'ICT Resources': 0.65,
      'TVL Resources': 0.45,
    },
    'returnRate': {'onTime': 0.82, 'overdue': 0.18},
  };

  void _exportReport(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating report...'),
              ],
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _dateRanges.map((range) {
                  final isSelected = _selectedDateRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(range),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDateRange = range;
                        });
                      },
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Summary cards stack on phones and tablets instead of squeezing
            // long labels into two narrow cards.
            LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 700;
                return GridView.count(
                  crossAxisCount: useSingleColumn ? 1 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: useSingleColumn ? 1.65 : 1.15,
                  children: [
                    _AnalyticsCard(
                      title: 'Total Borrow Transactions',
                      value: '${_analytics['totalBorrowTransactions']}',
                      subtitle: _analytics['borrowTrend'],
                      icon: Icons.swap_horiz,
                      iconColor: Colors.blue,
                    ),
                    _AnalyticsCard(
                      title: 'Overdue Items',
                      value: '${_analytics['overdueItems']}',
                      subtitle: 'Requires attention',
                      icon: Icons.warning,
                      iconColor: Colors.red,
                      isAlert: true,
                    ),
                    _AnalyticsCard(
                      title: 'Damaged / Flagged Items',
                      value: '${_analytics['damagedItems']}',
                      subtitle: 'Reported issues',
                      icon: Icons.report_problem,
                      iconColor: Colors.orange,
                    ),
                    _AnalyticsCard(
                      title: 'Most Requested Resource',
                      value: _analytics['mostRequestedResource'],
                      subtitle: 'Top category',
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Inventory Utilization Section
            Text(
              'Inventory Utilization',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProgressBar(
                      label: 'General Learning Resources',
                      percentage:
                          _analytics['inventoryUtilization']['General Learning Resources'],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(
                      label: 'ICT Resources',
                      percentage:
                          _analytics['inventoryUtilization']['ICT Resources'],
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(
                      label: 'TVL Resources',
                      percentage:
                          _analytics['inventoryUtilization']['TVL Resources'],
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Return Rate Status Section
            Text(
              'Return Rate Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ReturnRateIndicator(
                            label: 'On-Time Returns',
                            percentage: _analytics['returnRate']['onTime'],
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ReturnRateIndicator(
                            label: 'Overdue Returns',
                            percentage: _analytics['returnRate']['overdue'],
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _analytics['returnRate']['onTime'],
                        minHeight: 12,
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_analytics['returnRate']['onTime'] * 100).toInt()}% On-Time Return Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export buttons also stack on compact screens so their labels
            // always have enough room.
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 700
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _exportButton(colorScheme, 'CSV'),
                        const SizedBox(height: 12),
                        _exportButton(colorScheme, 'PDF'),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _exportButton(colorScheme, 'CSV')),
                        const SizedBox(width: 12),
                        Expanded(child: _exportButton(colorScheme, 'PDF')),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(ColorScheme colorScheme, String type) {
    final isPdf = type == 'PDF';
    final label = isPdf ? 'Generate PDF Report' : 'Export CSV / Excel';
    final icon = isPdf ? Icons.picture_as_pdf : Icons.download;
    final button = isPdf
        ? OutlinedButton.icon(
            onPressed: () => _exportReport(type),
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
            ),
          )
        : ElevatedButton.icon(
            onPressed: () => _exportReport(type),
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: colorScheme.primary,
            ),
          );
    return button;
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isAlert = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: isAlert
          ? Colors.red.withValues(alpha: 0.1)
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isAlert
              ? Colors.red.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Alert',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ReturnRateIndicator extends StatelessWidget {
  const _ReturnRateIndicator({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            percentage > 0.5 ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
