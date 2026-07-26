import 'package:flutter/material.dart';

class AdminSystemLogsScreen extends StatefulWidget {
  const AdminSystemLogsScreen({super.key});

  @override
  State<AdminSystemLogsScreen> createState() => _AdminSystemLogsScreenState();
}

class _AdminSystemLogsScreenState extends State<AdminSystemLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Logs';

  final List<Map<String, dynamic>> _logs = [
    {
      'id': 'LOG-001',
      'title': 'User Login',
      'actor': 'John Rexter',
      'asset': 'N/A',
      'timestamp': 'Today, 10:30 AM',
      'category': 'Authentication',
      'icon': Icons.login,
      'color': Colors.blue,
      'description': 'User successfully authenticated into the system',
    },
    {
      'id': 'LOG-002',
      'title': 'Resource Record Updated',
      'actor': 'Maria Santos',
      'asset': 'GLR-BIO-001',
      'timestamp': 'Today, 09:45 AM',
      'category': 'Inventory',
      'icon': Icons.inventory_2,
      'color': Colors.teal,
      'description': 'Updated resource details and availability status',
    },
    {
      'id': 'LOG-003',
      'title': 'Resource Borrowed',
      'actor': 'Pedro Reyes',
      'asset': 'ICT-LPT-015',
      'timestamp': 'Yesterday, 02:15 PM',
      'category': 'Borrowing',
      'icon': Icons.swap_horiz,
      'color': Colors.green,
      'description': 'Borrowed Laptop for Grade 11 STEM class',
    },
    {
      'id': 'LOG-004',
      'title': 'Account Created',
      'actor': 'Admin User',
      'asset': 'N/A',
      'timestamp': 'Yesterday, 11:20 AM',
      'category': 'User Mgmt',
      'icon': Icons.person_add,
      'color': Colors.purple,
      'description': 'Created new user account for Carlos Mendoza',
    },
    {
      'id': 'LOG-005',
      'title': 'Overdue Alert',
      'actor': 'System',
      'asset': 'TVL-EQP-003',
      'timestamp': '2 days ago',
      'category': 'Borrowing',
      'icon': Icons.warning,
      'color': Colors.orange,
      'description': 'Resource overdue by 3 days - sent notification',
    },
  ];

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs.where((log) {
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        final matchesSearch =
            log['actor'].toString().toLowerCase().contains(searchQuery) ||
            log['title'].toString().toLowerCase().contains(searchQuery) ||
            log['asset'].toString().toLowerCase().contains(searchQuery);
        if (!matchesSearch) return false;
      }

      if (_selectedFilter != 'All Logs') {
        if (log['category'] != _selectedFilter) return false;
      }

      return true;
    }).toList();
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('Log ID', log['id']),
                  const SizedBox(height: 12),
                  _DetailRow('Actor', log['actor']),
                  const SizedBox(height: 12),
                  _DetailRow('Timestamp', log['timestamp']),
                  const SizedBox(height: 12),
                  _DetailRow('Category', log['category']),
                  const SizedBox(height: 12),
                  const Text(
                    'Action Metadata',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by actor, action, or asset...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Logs',
                    isSelected: _selectedFilter == 'All Logs',
                    onSelected: () {
                      setState(() {
                        _selectedFilter = 'All Logs';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Authentication',
                    isSelected: _selectedFilter == 'Authentication',
                    onSelected: () {
                      setState(() {
                        _selectedFilter = 'Authentication';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Inventory',
                    isSelected: _selectedFilter == 'Inventory',
                    onSelected: () {
                      setState(() {
                        _selectedFilter = 'Inventory';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Borrowing',
                    isSelected: _selectedFilter == 'Borrowing',
                    onSelected: () {
                      setState(() {
                        _selectedFilter = 'Borrowing';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'User Mgmt',
                    isSelected: _selectedFilter == 'User Mgmt',
                    onSelected: () {
                      setState(() {
                        _selectedFilter = 'User Mgmt';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Logs List
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No logs found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 0,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showLogDetail(log),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: log['color'].withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      log['icon'],
                                      color: log['color'],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Log Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['title'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Actor: ${log['actor']} • Asset: ${log['asset']}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Timestamp
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      log['timestamp'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
