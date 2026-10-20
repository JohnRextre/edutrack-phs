import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/admin_notification_model.dart';
import '../models/borrow_transaction_model.dart';
import '../services/admin_dashboard_service.dart';

enum _LogSort { newest, oldest, action, actor, category }

class AdminSystemLogsScreen extends StatefulWidget {
  const AdminSystemLogsScreen({super.key});

  @override
  State<AdminSystemLogsScreen> createState() => _AdminSystemLogsScreenState();
}

class _AdminSystemLogsScreenState extends State<AdminSystemLogsScreen> {
  final _searchController = TextEditingController();
  _LogSort _sort = _LogSort.newest;
  String _category = 'All Logs';
  int _limit = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AdminDashboardService.auditLogsCollection)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load system logs: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              final actorNames = <String, String>{};
              for (final user in usersSnapshot.data?.docs ?? const []) {
                final data = user.data();
                final name = [data['firstName'], data['lastName']]
                    .where(
                      (value) =>
                          value != null && value.toString().trim().isNotEmpty,
                    )
                    .join(' ')
                    .trim();
                actorNames[user.id] = name.isNotEmpty
                    ? name
                    : (data['fullName'] ?? data['email'] ?? '').toString();
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(BorrowTransactionStatusCollection.name)
                    .snapshots(),
                builder: (context, transactionsSnapshot) {
                  final logs = <_LogEntry>[
                    ...snapshot.data?.docs.map(
                          (doc) => _LogEntry.fromDocument(doc, actorNames),
                        ) ??
                        const <_LogEntry>[],
                    ...transactionsSnapshot.data?.docs.map(
                          (doc) => _LogEntry.fromTransaction(
                            BorrowTransaction.fromFirestore(doc),
                          ),
                        ) ??
                        const <_LogEntry>[],
                  ];
                  return _buildContent(context, logs);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<_LogEntry> logs) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = logs.where((log) {
      if (_category != 'All Logs' && log.category != _category) return false;
      if (query.isEmpty) return true;
      return '${log.actor} ${log.title} ${log.asset} ${log.description}'
          .toLowerCase()
          .contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _LogSort.newest:
          return _compareDates(b, a);
        case _LogSort.oldest:
          return _compareDates(a, b);
        case _LogSort.action:
          final result = a.title.compareTo(b.title);
          return result == 0 ? _compareDates(b, a) : result;
        case _LogSort.actor:
          final result = a.actor.toLowerCase().compareTo(b.actor.toLowerCase());
          return result == 0 ? _compareDates(b, a) : result;
        case _LogSort.category:
          final result = a.category.toLowerCase().compareTo(
            b.category.toLowerCase(),
          );
          return result == 0 ? _compareDates(b, a) : result;
      }
    });

    final visible = _limit == 0 ? filtered : filtered.take(_limit).toList();
    const categories = [
      'All Logs',
      'Borrowing',
      'Returns',
      'Inventory',
      'Authentication',
      'User Mgmt',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search logs',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 0),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return FilterChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sort = DropdownButtonFormField<_LogSort>(
                initialValue: _sort,
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: _LogSort.newest,
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: _LogSort.oldest,
                    child: Text('Oldest First'),
                  ),
                  DropdownMenuItem(
                    value: _LogSort.action,
                    child: Text('By Action'),
                  ),
                  DropdownMenuItem(
                    value: _LogSort.actor,
                    child: Text('By Actor'),
                  ),
                  DropdownMenuItem(
                    value: _LogSort.category,
                    child: Text('By Category'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              );
              final show = DropdownButtonFormField<int>(
                initialValue: _limit,
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Show',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 logs')),
                  DropdownMenuItem(value: 25, child: Text('25 logs')),
                  DropdownMenuItem(value: 50, child: Text('50 logs')),
                  DropdownMenuItem(value: 0, child: Text('All logs')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _limit = value);
                },
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [sort, const SizedBox(height: 8), show],
                );
              }

              return Row(
                children: [
                  Expanded(child: sort),
                  const SizedBox(width: 8),
                  Expanded(child: show),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No system logs found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _LogTile(
                    log: visible[index],
                    onTap: () => _showLogDetail(visible[index]),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Showing ${visible.length} of ${filtered.length} logs'),
        ),
      ],
    );
  }

  int _compareDates(_LogEntry first, _LogEntry second) {
    final result = first.date.compareTo(second.date);
    return result == 0 ? first.id.compareTo(second.id) : result;
  }

  void _showLogDetail(_LogEntry log) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _DetailRow('Log ID', log.id),
            _DetailRow('Actor', log.actor),
            _DetailRow('Action', log.title),
            _DetailRow('Category', log.category),
            _DetailRow('Time', _formatDate(log.date)),
            const SizedBox(height: 8),
            Text(log.description),
          ],
        ),
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry({
    required this.id,
    required this.title,
    required this.actor,
    required this.asset,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
  });

  final String id;
  final String title;
  final String actor;
  final String asset;
  final String category;
  final String description;
  final DateTime date;
  final String type;

  factory _LogEntry.fromTransaction(BorrowTransaction transaction) {
    final isReturn =
        transaction.status == BorrowTransactionStatus.returned ||
        transaction.status == BorrowTransactionStatus.returnPending ||
        transaction.status == BorrowTransactionStatus.returnRejected;
    final type = isReturn ? 'return_${transaction.status}' : 'borrow_created';
    final title = switch (transaction.status) {
      BorrowTransactionStatus.returned => 'Return Accepted',
      BorrowTransactionStatus.returnPending => 'Return Submitted',
      BorrowTransactionStatus.returnRejected => 'Return Rejected',
      _ => 'Item Borrowed',
    };
    final date =
        transaction.actualReturnDate ??
        transaction.returnSubmittedDate ??
        transaction.borrowDate;
    return _LogEntry(
      id: 'transaction_${transaction.id}_$type',
      title: title,
      actor: transaction.userName,
      asset: transaction.resourceCode,
      category: isReturn ? 'Returns' : 'Borrowing',
      description: '${transaction.resourceName} (${transaction.resourceCode})',
      date: date,
      type: type,
    );
  }

  factory _LogEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, String> actorNames,
  ) {
    final data = document.data();
    final type = (data['actionType'] ?? data['action'] ?? 'activity')
        .toString();
    final category = _categoryFor(type, data['category']);
    return _LogEntry(
      id: document.id,
      title: (data['title'] ?? _titleFor(type)).toString(),
      actor: _actorName(data, actorNames),
      asset: (data['asset'] ?? data['resourceCode'] ?? 'N/A').toString(),
      category: category,
      description: _readableDescription(data),
      date:
          AdminNotification.dateFrom(data['timestamp'] ?? data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: type,
    );
  }

  static String _actorName(
    Map<String, dynamic> data,
    Map<String, String> actorNames,
  ) {
    final stored = (data['actorName'] ?? data['userName'] ?? '')
        .toString()
        .trim();
    if (stored.isNotEmpty && !_looksLikeId(stored)) return stored;
    final actorId = (data['actorId'] ?? data['userId'] ?? '').toString();
    return actorNames[actorId] ??
        (stored.isNotEmpty && !_looksLikeId(stored) ? stored : 'System');
  }

  static bool _looksLikeId(String value) =>
      value.length > 16 && !value.contains('@') && !value.contains(' ');

  static String _readableDescription(Map<String, dynamic> data) {
    final description =
        (data['description'] ?? data['action'] ?? 'Activity recorded.')
            .toString();
    final resourceName = data['resourceName']?.toString().trim();
    final resourceCode = data['resourceCode']?.toString().trim();
    if (resourceName != null && resourceName.isNotEmpty) {
      return resourceCode == null || resourceCode.isEmpty
          ? resourceName
          : '$resourceName ($resourceCode)';
    }
    return description.replaceAll(
      RegExp(r'("[A-Za-z0-9_-]{15,}")'),
      'the resource',
    );
  }

  static String _categoryFor(String type, Object? stored) {
    final value = stored?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    if (type.contains('login') ||
        type.contains('logout') ||
        type.contains('password')) {
      return 'Authentication';
    }
    if (type.contains('resource')) return 'Inventory';
    if (type.contains('return')) return 'Returns';
    if (type.contains('borrow') || type.contains('overdue')) {
      return 'Borrowing';
    }
    if (type.contains('account') || type.contains('user')) return 'User Mgmt';
    return 'Other';
  }

  static String _titleFor(String type) {
    if (type == 'login') return 'User Login';
    if (type == 'logout') return 'User Logout';
    if (type == 'account_created') return 'Account Created';
    if (type == 'password_changed') return 'Password Changed';
    if (type == 'resource_added') return 'Learning Resource Added';
    if (type == 'resource_edited') return 'Learning Resource Changed';
    if (type == 'resource_deleted' || type == 'resource_quantity_deleted') {
      return 'Learning Resource Deleted';
    }
    return 'System Activity';
  }
}

abstract final class BorrowTransactionStatusCollection {
  static const name = 'borrow_transactions';
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.onTap});

  final _LogEntry log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(log.type);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(_iconFor(log.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.actor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      log.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(log.date),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

IconData _iconFor(String type) {
  if (type.contains('login')) return Icons.login;
  if (type.contains('logout')) return Icons.logout;
  if (type.contains('password')) return Icons.lock_reset;
  if (type.contains('resource')) return Icons.inventory_2_outlined;
  if (type.contains('borrow') || type.contains('return')) {
    return Icons.swap_horiz;
  }
  if (type.contains('account') || type.contains('user')) {
    return Icons.person_add_alt_1;
  }
  return Icons.info_outline;
}

Color _colorFor(String type) {
  if (type.contains('password') || type.contains('delete')) return Colors.red;
  if (type.contains('login')) return Colors.green;
  if (type.contains('resource')) return Colors.teal;
  if (type.contains('borrow') || type.contains('return')) return Colors.indigo;
  return Colors.blueGrey;
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
