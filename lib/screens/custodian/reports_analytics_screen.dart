import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/report_export_service.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ReportExportService _reportExportService = ReportExportService();

  AnalyticsDatePreset _selectedPreset = AnalyticsDatePreset.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isExporting = false;

  Stream<AnalyticsSummary> _watchSummary() => _analyticsService.watchSummary(
    preset: _selectedPreset,
    customStart: _customStart,
    customEnd: _customEnd,
  );

  Future<void> _pickCustomRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: _customStart ?? today.subtract(const Duration(days: 30)),
        end: _customEnd ?? today,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _customStart = picked.start;
      _customEnd = picked.end;
      _selectedPreset = AnalyticsDatePreset.custom;
    });
  }

  Future<void> _exportReport(String format) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final summary = await _analyticsService.fetchSummary(
        preset: _selectedPreset,
        customStart: _customStart,
        customEnd: _customEnd,
      );
      await _reportExportService.exportSummary(
        summary: summary,
        format: format,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported as $format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to export report: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        actions: [
          PopupMenuButton<String>(
            onSelected: _exportReport,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'CSV', child: Text('Export CSV')),
              PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
          ),
        ],
      ),
      body: StreamBuilder<AnalyticsSummary>(
        stream: _watchSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load analytics data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final summary = snapshot.data ?? AnalyticsSummary.empty;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportHeader(
                    rangeLabel: _selectedPreset == AnalyticsDatePreset.custom
                        ? 'Custom date range'
                        : _presetLabel(_selectedPreset),
                    onRefresh: () => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  _DateRangeSelector(
                    selected: _selectedPreset,
                    onPresetChanged: (preset) {
                      setState(() {
                        _selectedPreset = preset;
                        if (preset != AnalyticsDatePreset.custom) {
                          _customStart = null;
                          _customEnd = null;
                        }
                      });
                    },
                    onCustomRangeTap: _pickCustomRange,
                  ),
                  const SizedBox(height: 20),
                  if (summary.isEmpty)
                    _EmptyStateCard(
                      message:
                          'No borrow activity was found for the selected range.',
                    )
                  else ...[
                    _KpiStrip(
                      items: [
                        _KpiData(
                          'Borrowed',
                          '${summary.totalBorrowings}',
                          Icons.swap_horiz_rounded,
                          Colors.blue,
                        ),
                        _KpiData(
                          'Active borrowers',
                          '${summary.activeBorrowers}',
                          Icons.people_outline_rounded,
                          Colors.indigo,
                        ),
                        _KpiData(
                          'On-time returns',
                          '${summary.onTimeReturnRate.toStringAsFixed(1)}%',
                          Icons.check_circle_outline_rounded,
                          Colors.green,
                        ),
                        _KpiData(
                          'Late returns',
                          '${summary.overdueRate.toStringAsFixed(1)}%',
                          Icons.warning_amber_rounded,
                          Colors.orange,
                        ),
                        _KpiData(
                          'Damaged / replaced',
                          '${summary.damagedOrReplacedCount}',
                          Icons.build_circle_outlined,
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Operational analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final categoryPanel = _AnalyticsPanel(
                          title: 'Category share',
                          subtitle: 'Borrowing demand by resource type',
                          icon: Icons.pie_chart_outline_rounded,
                          child: _CategoryBreakdownCard(
                            distribution: summary.categoryDistribution,
                          ),
                        );
                        final returnPanel = _AnalyticsPanel(
                          title: 'Return outcomes',
                          subtitle: 'How issued items were resolved',
                          icon: Icons.assignment_turned_in_outlined,
                          child: _ReturnTypeBreakdownCard(
                            breakdown: summary.resolutionBreakdown,
                          ),
                        );
                        if (constraints.maxWidth < 760) {
                          return Column(
                            children: [
                              categoryPanel,
                              const SizedBox(height: 12),
                              returnPanel,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: categoryPanel),
                            const SizedBox(width: 12),
                            Expanded(child: returnPanel),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Most requested resources',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TopResourcesCard(resources: summary.topResources),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.selected,
    required this.onPresetChanged,
    required this.onCustomRangeTap,
  });

  final AnalyticsDatePreset selected;
  final ValueChanged<AnalyticsDatePreset> onPresetChanged;
  final VoidCallback onCustomRangeTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = Theme.of(context).colorScheme.primaryContainer;
    final ranges = [
      AnalyticsDatePreset.thisWeek,
      AnalyticsDatePreset.thisMonth,
      AnalyticsDatePreset.thisSemester,
      AnalyticsDatePreset.custom,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final range in ranges)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_label(range)),
                    selected: selected == range,
                    onSelected: (_) => onPresetChanged(range),
                    selectedColor: chipColor,
                  ),
                ),
              TextButton.icon(
                onPressed: onCustomRangeTap,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Custom range'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(AnalyticsDatePreset range) {
    switch (range) {
      case AnalyticsDatePreset.thisWeek:
        return 'This Week';
      case AnalyticsDatePreset.thisMonth:
        return 'This Month';
      case AnalyticsDatePreset.thisSemester:
        return 'This Semester';
      case AnalyticsDatePreset.custom:
        return 'Custom';
    }
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.rangeLabel, required this.onRefresh});

  final String rangeLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borrowing performance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Live custodian view  •  $rangeLabel',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh report',
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              foregroundColor: colors.primary,
              backgroundColor: colors.surface.withValues(alpha: 0.7),
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.items});

  final List<_KpiData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          SizedBox(
            width: 178,
            child: _MetricCard(
              label: item.label,
              value: item.value,
              icon: item.icon,
              color: item.color,
            ),
          ),
      ],
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

String _presetLabel(AnalyticsDatePreset preset) {
  switch (preset) {
    case AnalyticsDatePreset.thisWeek:
      return 'This week';
    case AnalyticsDatePreset.thisMonth:
      return 'This month';
    case AnalyticsDatePreset.thisSemester:
      return 'This semester';
    case AnalyticsDatePreset.custom:
      return 'Custom date range';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.distribution});

  final Map<String, double> distribution;

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No category data available.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: entry.value.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colorForCategory(entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String category) {
    final palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return palette[category.hashCode.abs() % palette.length];
  }
}

class _ReturnTypeBreakdownCard extends StatelessWidget {
  const _ReturnTypeBreakdownCard({required this.breakdown});

  final Map<String, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.isEmpty
              ? const [Text('No return-type data available.')]
              : [
                  for (final entry in entries)
                    if (entry.value > 0)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: Text(entry.value.toString()),
                      ),
                ],
        ),
      ),
    );
  }
}

class _TopResourcesCard extends StatelessWidget {
  const _TopResourcesCard({required this.resources});

  final List<ResourceBorrowRank> resources;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: resources.isEmpty
            ? const Text('No resource data available.')
            : Column(
                children: [
                  for (var i = 0; i < resources.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '#${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(resources[i].resourceName),
                                Text(
                                  '${resources[i].borrowCount} borrow(s)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: resources[i].availableQuantity > 0
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              resources[i].stockLabel,
                              style: TextStyle(
                                color: resources[i].availableQuantity > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
