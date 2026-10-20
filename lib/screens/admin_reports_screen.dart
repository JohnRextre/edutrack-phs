import 'package:flutter/material.dart';

import '../models/section_model.dart';
import '../services/admin_dashboard_service.dart';
import '../services/report_export_service.dart';
import '../services/section_service.dart';
import '../widgets/admin_notifications_button.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

enum _ReportSort { defaultOrder, alphabetical, highestValue }

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _searchController = TextEditingController();
  final _exportService = ReportExportService();
  _ReportSort _sort = _ReportSort.defaultOrder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final adminService = AdminDashboardService();
    final sectionService = SectionService();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('System Reports'),
        backgroundColor: colors.surface,
        actions: [const AdminNotificationsButton()],
      ),
      body: StreamBuilder<AdminDashboardMetrics>(
        stream: adminService.watchMetrics(),
        builder: (context, metricsSnapshot) {
          return StreamBuilder<List<SectionModel>>(
            stream: sectionService.watchAllSections(),
            builder: (context, sectionsSnapshot) {
              if (metricsSnapshot.hasError || sectionsSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load system report data.'),
                );
              }
              if (!metricsSnapshot.hasData || !sectionsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final metrics = metricsSnapshot.data!;
              final sections = sectionsSnapshot.data!;
              return _ReportBody(
                metrics: metrics,
                sections: sections,
                searchController: _searchController,
                sort: _sort,
                onSearchChanged: () => setState(() {}),
                onSortChanged: (value) => setState(() => _sort = value),
                onDownload: () => _exportService.downloadAdminReport(
                  metrics: metrics,
                  sections: sections,
                ),
                onPrint: () => _exportService.printAdminReport(
                  metrics: metrics,
                  sections: sections,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.metrics,
    required this.sections,
    required this.searchController,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onDownload,
    required this.onPrint,
  });

  final AdminDashboardMetrics metrics;
  final List<SectionModel> sections;
  final TextEditingController searchController;
  final _ReportSort sort;
  final VoidCallback onSearchChanged;
  final ValueChanged<_ReportSort> onSortChanged;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeSections = sections.where((section) => section.isActive).length;
    final sectionCapacity = sections.fold<int>(
      0,
      (total, section) => total + section.maxActiveBorrowQuantity,
    );
    final sectionUsage = sections.fold<int>(
      0,
      (total, section) => total + section.currentActiveBorrowQuantity,
    );
    final capacityRate = sectionCapacity == 0
        ? 0.0
        : (sectionUsage / sectionCapacity).clamp(0.0, 1.0);
    final query = searchController.text.trim().toLowerCase();
    bool matches(String value) =>
        query.isEmpty || value.toLowerCase().contains(query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _ReportToolbar(
          onLogs: () => Navigator.pushNamed(context, '/admin-logs'),
          searchController: searchController,
          sort: sort,
          onSearchChanged: onSearchChanged,
          onSortChanged: onSortChanged,
          onDownload: onDownload,
          onPrint: onPrint,
        ),
        const SizedBox(height: 18),
        _ReportTitle(
          title: 'System performance',
          subtitle: 'Live operational snapshot for the ICT Coordinator.',
        ),
        const SizedBox(height: 12),
        _KpiStrip(
          items: [
            _KpiData('Accounts', '${metrics.totalUsers}', Icons.people_outline),
            _KpiData('Sections', '${sections.length}', Icons.groups_outlined),
            _KpiData(
              'Borrowed',
              '${metrics.activeBorrowings}',
              Icons.swap_horiz_rounded,
            ),
            _KpiData(
              'Alerts',
              '${metrics.maintenanceItems}',
              Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (matches('account composition') ||
            matches('account') ||
            query.isEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final panels = [
                _AnalyticsPanel(
                  title: 'Account composition',
                  subtitle: 'Distribution by registered role',
                  icon: Icons.pie_chart_outline_rounded,
                  action: _ReportAction(
                    label: 'View accounts',
                    onTap: () => Navigator.pushNamed(context, '/admin-users'),
                  ),
                  child: _RoleBars(roles: metrics.usersByRole),
                ),
                _AnalyticsPanel(
                  title: 'Section capacity',
                  subtitle: 'Current usage versus configured limits',
                  icon: Icons.bar_chart_rounded,
                  action: _ReportAction(
                    label: 'View sections',
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin-sections'),
                  ),
                  child: _CapacityChart(
                    activeSections: activeSections,
                    totalSections: sections.length,
                    usage: sectionUsage,
                    capacity: sectionCapacity,
                    rate: capacityRate,
                  ),
                ),
              ];
              if (stacked) {
                return Column(
                  children: [panels[0], const SizedBox(height: 12), panels[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: panels[0]),
                  const SizedBox(width: 12),
                  Expanded(child: panels[1]),
                ],
              );
            },
          ),
        if (matches('section capacity') ||
            matches('section') ||
            query.isEmpty) ...[
          const SizedBox(height: 20),
          _ReportTitle(
            title: 'System health',
            subtitle: 'Signals that may need administrative attention.',
          ),
          const SizedBox(height: 12),
          _HealthList(
            metrics: metrics,
            sort: sort,
            onBorrowings: () =>
                Navigator.pushNamed(context, '/admin-borrowing-monitor'),
            onResources: () =>
                Navigator.pushNamed(context, '/admin-resource-monitoring'),
          ),
        ],
        if (matches('shortcut') ||
            matches('resource') ||
            matches('borrow') ||
            matches('audit') ||
            query.isEmpty) ...[
          const SizedBox(height: 20),
          _ReportTitle(
            title: 'Management shortcuts',
            subtitle: 'Open detailed records only when you need them.',
          ),
          const SizedBox(height: 10),
          _ShortcutRow(
            icon: Icons.inventory_2_outlined,
            label: 'Resource monitoring',
            detail: 'Inventory and maintenance details',
            onTap: () =>
                Navigator.pushNamed(context, '/admin-resource-monitoring'),
          ),
          _ShortcutRow(
            icon: Icons.swap_horizontal_circle_outlined,
            label: 'Borrowing monitor',
            detail: 'All borrowing and return records',
            onTap: () =>
                Navigator.pushNamed(context, '/admin-borrowing-monitor'),
          ),
          _ShortcutRow(
            icon: Icons.receipt_long_outlined,
            label: 'Audit logs',
            detail: 'Administrative actions and system events',
            onTap: () => Navigator.pushNamed(context, '/admin-logs'),
          ),
          const SizedBox(height: 8),
        ],
        if (query.isNotEmpty &&
            !matches('account') &&
            !matches('section') &&
            !matches('resource') &&
            !matches('borrow') &&
            !matches('audit'))
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No report sections match your search.')),
          ),
        if (query.isEmpty) const SizedBox(height: 8),
        Text(
          'Report data updates automatically from the system records.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.onLogs,
    required this.searchController,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onDownload,
    required this.onPrint,
  });

  final VoidCallback onLogs;
  final TextEditingController searchController;
  final _ReportSort sort;
  final VoidCallback onSearchChanged;
  final ValueChanged<_ReportSort> onSortChanged;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: onLogs,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Audit logs'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Export report',
            onSelected: (value) {
              if (value == 'download') onDownload();
              if (value == 'print') onPrint();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'download', child: Text('Download PDF')),
              PopupMenuItem(value: 'print', child: Text('Print report')),
            ],
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: searchController,
              hintText: 'Search report sections...',
              leading: const Icon(Icons.search),
              trailing: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged();
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (_) => onSearchChanged(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<_ReportSort>(
              value: sort,
              icon: const Icon(Icons.sort_rounded),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
              items: const [
                DropdownMenuItem(
                  value: _ReportSort.defaultOrder,
                  child: Text('Default'),
                ),
                DropdownMenuItem(
                  value: _ReportSort.alphabetical,
                  child: Text('A-Z'),
                ),
                DropdownMenuItem(
                  value: _ReportSort.highestValue,
                  child: Text('Highest'),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _ReportTitle extends StatelessWidget {
  const _ReportTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.items});

  final List<_KpiData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 520
          ? (constraints.maxWidth - 8) / 2
          : (constraints.maxWidth - 24) / 4;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final _ReportAction action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 9),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        child,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: action.onTap, child: Text(action.label)),
        ),
      ],
    ),
  );
}

class _ReportAction {
  const _ReportAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _RoleBars extends StatelessWidget {
  const _RoleBars({required this.roles});

  final Map<String, int> roles;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Students', roles['student'] ?? 0, Colors.blue),
      ('Teachers', roles['teacher'] ?? 0, Colors.teal),
      ('Custodians', roles['custodian'] ?? 0, Colors.deepPurple),
      ('Admins', roles['admin'] ?? 0, Colors.orange),
    ];
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.$2);
    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BarRow(
                label: entry.$1,
                value: entry.$2,
                ratio: total == 0 ? 0 : entry.$2 / total,
                color: entry.$3,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CapacityChart extends StatelessWidget {
  const _CapacityChart({
    required this.activeSections,
    required this.totalSections,
    required this.usage,
    required this.capacity,
    required this.rate,
  });

  final int activeSections;
  final int totalSections;
  final int usage;
  final int capacity;
  final double rate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'capacity used',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: rate,
          minHeight: 12,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '$usage of $capacity active borrow slots in use',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 3),
      Text(
        '$activeSections active of $totalSections total sections',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 78, child: Text(label)),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 9,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$value',
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _HealthList extends StatelessWidget {
  const _HealthList({
    required this.metrics,
    required this.sort,
    required this.onBorrowings,
    required this.onResources,
  });

  final AdminDashboardMetrics metrics;
  final _ReportSort sort;
  final VoidCallback onBorrowings;
  final VoidCallback onResources;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HealthData(
        icon: Icons.warning_amber_outlined,
        title: 'Resource condition',
        detail: '${metrics.maintenanceItems} resource(s) need attention',
        isAlert: metrics.maintenanceItems > 0,
        onTap: onResources,
      ),
      _HealthData(
        icon: Icons.swap_horiz_rounded,
        title: 'Borrowing activity',
        detail: '${metrics.activeBorrowings} item(s) currently borrowed',
        isAlert: false,
        onTap: onBorrowings,
      ),
    ];
    if (sort == _ReportSort.alphabetical) {
      items.sort((a, b) => a.title.compareTo(b.title));
    } else if (sort == _ReportSort.highestValue) {
      items.sort(
        (a, b) => b.isAlert.toString().compareTo(a.isAlert.toString()),
      );
    }
    return Column(
      children: items.map((item) => _HealthRow(data: item)).toList(),
    );
  }
}

class _HealthData {
  const _HealthData({
    required this.icon,
    required this.title,
    required this.detail,
    required this.isAlert,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool isAlert;
  final VoidCallback onTap;
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.data});

  final _HealthData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = data.isAlert ? Colors.orange : colors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: color, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  data.detail,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: data.onTap, child: const Text('View')),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
