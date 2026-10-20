import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_activity_model.dart';
import '../models/borrow_transaction_model.dart';
import '../services/account_activity_service.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';

enum _ActivityFilter {
  all,
  borrowed,
  returned,
  rejected,
  login,
  logout,
  accountCreated,
  passwordChanged,
  resourceAdded,
  resourceChanged,
  resourceDeleted,
}

class AccountActivitiesScreen extends StatefulWidget {
  const AccountActivitiesScreen({super.key, this.custodianOnly = false});

  final bool custodianOnly;

  @override
  State<AccountActivitiesScreen> createState() =>
      _AccountActivitiesScreenState();
}

class _AccountActivitiesScreenState extends State<AccountActivitiesScreen> {
  final _searchController = TextEditingController();
  final _activityService = AccountActivityService();
  _ActivityFilter _filter = _ActivityFilter.all;
  int _limit = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Account Activities')),
      body: userId == null
          ? const Center(
              child: Text('Please sign in to view your activity history.'),
            )
          : StreamBuilder<List<AccountActivity>>(
              stream: _activityService.watchActivities(
                userId,
                custodianOnly: widget.custodianOnly,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      BorrowService.friendlyErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildContent(context, snapshot.data ?? const []);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, List<AccountActivity> raw) {
    final query = _searchController.text.trim().toLowerCase();
    final matching = raw.where((activity) {
      if (!_matchesFilter(activity)) return false;
      if (query.isEmpty) return true;
      return activity.title.toLowerCase().contains(query) ||
          activity.description.toLowerCase().contains(query);
    }).toList();

    matching.sort((a, b) => b.date.compareTo(a.date));

    final visible = _limit == 0 ? matching : matching.take(_limit).toList();
    final hasMore = matching.length > visible.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.custodianOnly
                    ? 'Custodian Account Activities'
                    : 'Account Activity & History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search activity or item',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<_ActivityFilter>(
                      initialValue: _filter,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Activity Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: _ActivityFilter.all,
                          child: Text('All Activities'),
                        ),
                        if (!widget.custodianOnly)
                          DropdownMenuItem(
                            value: _ActivityFilter.borrowed,
                            child: Text('Borrowed'),
                          ),
                        if (!widget.custodianOnly)
                          DropdownMenuItem(
                            value: _ActivityFilter.returned,
                            child: Text('Return'),
                          ),
                        if (!widget.custodianOnly)
                          DropdownMenuItem(
                            value: _ActivityFilter.rejected,
                            child: Text('Rejected'),
                          ),
                        DropdownMenuItem(
                          value: _ActivityFilter.login,
                          child: Text('Login'),
                        ),
                        DropdownMenuItem(
                          value: _ActivityFilter.logout,
                          child: Text('Logout'),
                        ),
                        DropdownMenuItem(
                          value: _ActivityFilter.accountCreated,
                          child: Text('Created Account'),
                        ),
                        DropdownMenuItem(
                          value: _ActivityFilter.passwordChanged,
                          child: Text('Changed Password'),
                        ),
                        if (widget.custodianOnly)
                          const DropdownMenuItem(
                            value: _ActivityFilter.resourceAdded,
                            child: Text('Added'),
                          ),
                        if (widget.custodianOnly)
                          const DropdownMenuItem(
                            value: _ActivityFilter.resourceChanged,
                            child: Text('Changed'),
                          ),
                        if (widget.custodianOnly)
                          const DropdownMenuItem(
                            value: _ActivityFilter.resourceDeleted,
                            child: Text('Deleted'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _filter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _limit,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Display',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10 items')),
                        DropdownMenuItem(value: 25, child: Text('25 items')),
                        DropdownMenuItem(value: 50, child: Text('50 items')),
                        DropdownMenuItem(value: 0, child: Text('Show All')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _limit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      query.isEmpty
                          ? 'No activity records found.'
                          : 'No activity records found matching your search.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(activity: visible[index]),
                  ),
                ),
        ),
        if (hasMore)
          TextButton.icon(
            onPressed: () => setState(() {
              if (_limit == 10) {
                _limit = 25;
              } else if (_limit == 25) {
                _limit = 50;
              } else {
                _limit = 0;
              }
            }),
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More Activities'),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Showing ${visible.length} of ${matching.length} activities',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(AccountActivity activity) {
    switch (_filter) {
      case _ActivityFilter.all:
        return true;
      case _ActivityFilter.borrowed:
        return activity.kind == AccountActivityKind.borrowing &&
            activity.transaction is BorrowTransaction &&
            (activity.transaction as BorrowTransaction).status ==
                BorrowTransactionStatus.borrowed;
      case _ActivityFilter.returned:
        return activity.kind == AccountActivityKind.borrowing &&
            (activity.title.toLowerCase().contains('return') ||
                activity.title.toLowerCase().contains('verification'));
      case _ActivityFilter.rejected:
        return activity.title.toLowerCase().contains('reject');
      case _ActivityFilter.login:
        return _hasAccountAction(activity, 'login');
      case _ActivityFilter.logout:
        return _hasAccountAction(activity, 'logout');
      case _ActivityFilter.accountCreated:
        return _hasAccountAction(activity, 'created');
      case _ActivityFilter.passwordChanged:
        return _hasAccountAction(activity, 'password');
      case _ActivityFilter.resourceAdded:
        return _hasResourceAction(activity, 'resource_added');
      case _ActivityFilter.resourceChanged:
        return _hasResourceAction(activity, 'resource_edited');
      case _ActivityFilter.resourceDeleted:
        return _hasResourceAction(activity, 'resource_deleted') ||
            _hasResourceAction(activity, 'quantity_deleted');
    }
  }

  bool _hasAccountAction(AccountActivity activity, String keyword) {
    if (activity.kind != AccountActivityKind.account) return false;
    final text = '${activity.title} ${activity.description}'.toLowerCase();
    return text.contains(keyword);
  }

  bool _hasResourceAction(AccountActivity activity, String keyword) {
    if (activity.kind != AccountActivityKind.account) return false;
    final title = activity.title.toLowerCase();
    switch (keyword) {
      case 'resource_added':
        return title.contains('added learning resource');
      case 'resource_edited':
        return title.contains('changed learning resource');
      case 'resource_deleted':
      case 'quantity_deleted':
        return title.contains('deleted learning resource');
      default:
        return false;
    }
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final AccountActivity activity;

  @override
  Widget build(BuildContext context) {
    final transaction = activity.transaction as BorrowTransaction?;
    final reason = transaction?.isExpiredBorrowRejection == true
        ? BorrowService.borrowRequestExpiredDisplayReason
        : transaction?.rejectionReason?.trim();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: transaction == null
            ? null
            : () => BorrowTransactionDetailsModal.show(
                context,
                transaction: transaction,
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(activity.icon, color: activity.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (transaction != null)
                          BorrowStatusBadge(
                            transaction: transaction,
                            compact: true,
                          ),
                        Text(
                          activity.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatBorrowDate(activity.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(
                          color: activity.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
