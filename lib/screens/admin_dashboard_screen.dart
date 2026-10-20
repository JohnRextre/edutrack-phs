import 'package:flutter/material.dart';

import '../models/section_model.dart';
import '../services/admin_dashboard_service.dart';
import '../services/report_export_service.dart';
import '../services/section_service.dart';
import '../widgets/admin_notifications_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardService _service = AdminDashboardService();
  final ReportExportService _reportService = ReportExportService();
  final SectionService _sectionService = SectionService();

  void _open(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminDashboardMetrics>(
      stream: _service.watchMetrics(),
      builder: (context, metricsSnapshot) {
        final metrics = metricsSnapshot.data;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onRegister: () => _open('/admin-users'),
                onAuditReport: metrics == null
                    ? null
                    : () => _exportAuditReport(metrics),
                onSections: () => _open('/admin-sections'),
                onUsers: () => _open('/admin-users'),
              ),
              const SizedBox(height: 16),
              const _AccessBanner(),
              const SizedBox(height: 24),
              if (metricsSnapshot.hasError)
                const _ErrorState(message: 'Unable to load system metrics.')
              else if (metrics == null)
                const _LoadingState(),
              if (metrics != null) ...[
                _MetricsGrid(
                  metrics: metrics,
                  onUsers: () => _open('/admin-users'),
                  onAssets: () => _open('/custodian-resources'),
                  onMaintenance: () => _open('/admin-logs'),
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Section Borrowing Capacity',
                  actionLabel: 'Manage Sections',
                  onAction: () => _open('/admin-sections'),
                ),
                const SizedBox(height: 10),
                _SectionCapacityPreview(service: _sectionService),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'System Audit Logs',
                  actionLabel: 'View Full Audit Trail',
                  onAction: () => _open('/admin-logs'),
                ),
                const SizedBox(height: 10),
                _AuditPreview(service: _service),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportAuditReport(AdminDashboardMetrics metrics) async {
    try {
      await _reportService.exportSystemReport(metrics: metrics);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System audit report is ready to share.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to export audit report: $error')),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onRegister,
    required this.onAuditReport,
    required this.onSections,
    required this.onUsers,
  });
  final VoidCallback onRegister;
  final VoidCallback? onAuditReport;
  final VoidCallback onSections;
  final VoidCallback onUsers;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: Text(
          'ICT Coordinator Dashboard',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        tooltip: 'Register new user or custodian',
        onPressed: onRegister,
        icon: const Icon(Icons.person_add_alt_1_outlined),
      ),
      const AdminNotificationsButton(),
      PopupMenuButton<String>(
        tooltip: 'System controls',
        onSelected: (value) {
          if (value == 'audit') onAuditReport?.call();
          if (value == 'sections') onSections();
          if (value == 'users') onUsers();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'audit', child: Text('System Audit Report')),
          PopupMenuItem(value: 'sections', child: Text('Manage Sections')),
          PopupMenuItem(
            value: 'users',
            child: Text('Manage Users & Custodians'),
          ),
        ],
      ),
    ],
  );
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'System configuration, audit logs, and account management rights are available here. Inventory and borrowing metrics are view-only.',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.metrics,
    required this.onUsers,
    required this.onAssets,
    required this.onMaintenance,
  });

  final AdminDashboardMetrics metrics;
  final VoidCallback onUsers;
  final VoidCallback onAssets;
  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: columns == 4 ? 1.05 : 1.25,
        children: [
          _MetricCard(
            title: 'Total Users & Roles',
            value: metrics.totalUsers.toString(),
            detail: _roleSummary(metrics.usersByRole),
            icon: Icons.people_alt_outlined,
            color: Colors.blue,
            onTap: onUsers,
          ),
          _MetricCard(
            title: 'ICT Assets Overview',
            value: metrics.ictAssets.toString(),
            detail: 'ICT equipment records',
            icon: Icons.devices_other_outlined,
            color: Colors.teal,
            onTap: onAssets,
          ),
          _MetricCard(
            title: 'Maintenance Alerts',
            value: metrics.maintenanceItems.toString(),
            detail: '${metrics.activeBorrowings} active borrowings',
            icon: Icons.build_outlined,
            color: Colors.red,
            onTap: onMaintenance,
          ),
        ],
      );
    },
  );

  String _roleSummary(Map<String, int> roles) =>
      'S ${roles['student'] ?? 0} · T ${roles['teacher'] ?? 0} · C ${roles['custodian'] ?? 0} · A ${roles['admin'] ?? 0}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCapacityPreview extends StatelessWidget {
  const _SectionCapacityPreview({required this.service});

  final SectionService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SectionModel>>(
      stream: service.watchActiveSections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return const _ErrorState(message: 'Unable to load section capacity.');
        }

        final sections = [...snapshot.data ?? const <SectionModel>[]]
          ..sort((a, b) => _capacityRatio(b).compareTo(_capacityRatio(a)));
        final visibleSections = sections.take(5).toList();
        if (visibleSections.isEmpty) {
          return const _EmptyState(message: 'No active sections found.');
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: visibleSections
                .map((section) => _SectionCapacityTile(section: section))
                .toList(),
          ),
        );
      },
    );
  }

  static double _capacityRatio(SectionModel section) {
    if (section.maxActiveBorrowQuantity < 1) return 0;
    return section.currentActiveBorrowQuantity /
        section.maxActiveBorrowQuantity;
  }
}

class _SectionCapacityTile extends StatelessWidget {
  const _SectionCapacityTile({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final limit = section.maxActiveBorrowQuantity;
    final current = section.currentActiveBorrowQuantity;
    final ratio = limit < 1 ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isFull = current >= limit && limit > 0;
    final isNearLimit = ratio >= 0.8;
    final statusColor = isFull
        ? colors.error
        : isNearLimit
        ? Colors.orange.shade700
        : colors.primary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.12),
        child: Icon(Icons.groups_outlined, color: statusColor),
      ),
      title: Text(
        section.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: colors.surfaceContainerHighest,
            color: statusColor,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$current/$limit',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
          ),
          Text(
            isFull
                ? 'Full'
                : isNearLimit
                ? 'Near limit'
                : 'Available',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AuditPreview extends StatelessWidget {
  const _AuditPreview({required this.service});
  final AdminDashboardService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AdminAuditEvent>>(
    stream: service.watchAuditEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return const _ErrorState(message: 'Unable to load audit events.');
      }
      final events = snapshot.data ?? const <AdminAuditEvent>[];
      if (events.isEmpty) {
        return const _EmptyState(
          message: 'No audit events have been recorded yet.',
        );
      }
      return Card(
        child: Column(
          children: events
              .map(
                (event) => ListTile(
                  leading: Icon(_iconFor(event.icon)),
                  title: Text(event.description),
                  subtitle: Text(
                    '${event.actorName} · ${_dateLabel(event.timestamp)}',
                  ),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(child: Text(message)),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
  );
}

String _dateLabel(DateTime? date) => date == null
    ? 'Date unavailable'
    : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

IconData _iconFor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('login')) {
    return Icons.login;
  }
  if (normalized.contains('account') || normalized.contains('user')) {
    return Icons.person_add_outlined;
  }
  if (normalized.contains('inventory')) {
    return Icons.inventory_2_outlined;
  }
  if (normalized.contains('request')) {
    return Icons.assignment_outlined;
  }
  return Icons.history;
}
