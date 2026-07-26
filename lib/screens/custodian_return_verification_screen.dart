import 'package:flutter/material.dart';

enum ConditionStatus {
  good('Good Condition', Colors.green),
  damaged('Damaged', Colors.red),
  underReview('Under Review', Colors.orange);

  const ConditionStatus(this.label, this.color);
  final String label;
  final Color color;
}

class ReturnVerificationItem {
  const ReturnVerificationItem({
    required this.id,
    required this.itemTitle,
    required this.assetTag,
    required this.imagePath,
    required this.fallbackIcon,
    required this.borrowerName,
    required this.borrowerRole,
    required this.returnTimestamp,
    required this.borrowDuration,
    required this.conditionStatus,
    this.returnPhotoPath,
    this.borrowerNotes,
    this.custodianRemarks,
  });

  final String id;
  final String itemTitle;
  final String assetTag;
  final String imagePath;
  final IconData fallbackIcon;
  final String borrowerName;
  final String borrowerRole;
  final DateTime returnTimestamp;
  final String borrowDuration;
  final ConditionStatus conditionStatus;
  final String? returnPhotoPath;
  final String? borrowerNotes;
  final String? custodianRemarks;
}

class CustodianReturnVerificationScreen extends StatefulWidget {
  const CustodianReturnVerificationScreen({super.key});

  @override
  State<CustodianReturnVerificationScreen> createState() =>
      _CustodianReturnVerificationScreenState();
}

class _CustodianReturnVerificationScreenState
    extends State<CustodianReturnVerificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  ConditionStatus? _selectedFilter;

  // Sample data - in real app, this would come from a database/service
  final List<ReturnVerificationItem> _allVerifications = [
    ReturnVerificationItem(
      id: 'VER-001',
      itemTitle: 'Physics: Principles & Problems',
      assetTag: 'GLR-PHY-001',
      imagePath: 'lib/assets/borrowed_assets/Physics Book.png',
      fallbackIcon: Icons.menu_book_outlined,
      borrowerName: 'Maria Santos',
      borrowerRole: 'Student - Grade 11 STEM',
      returnTimestamp: DateTime.now(),
      borrowDuration: '7 days',
      conditionStatus: ConditionStatus.damaged,
      returnPhotoPath: 'lib/assets/borrowed_assets/return_photo_1.jpg',
      borrowerNotes: 'Damaged cover - back page slightly torn.',
    ),
    ReturnVerificationItem(
      id: 'VER-002',
      itemTitle: 'Lenovo Laptop',
      assetTag: 'ICT-LPT-042',
      imagePath: 'lib/assets/borrowed_assets/Laptop.png',
      fallbackIcon: Icons.laptop_mac_outlined,
      borrowerName: 'Juan Dela Cruz',
      borrowerRole: 'Student - Grade 12 ABM',
      returnTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      borrowDuration: '14 days',
      conditionStatus: ConditionStatus.good,
      returnPhotoPath: 'lib/assets/borrowed_assets/return_photo_2.jpg',
      borrowerNotes: 'Item returned in excellent condition.',
    ),
    ReturnVerificationItem(
      id: 'VER-003',
      itemTitle: 'Biology Microscope',
      assetTag: 'SCI-MIC-001',
      imagePath: 'lib/assets/borrowed_assets/Biology Microscope.png',
      fallbackIcon: Icons.biotech_outlined,
      borrowerName: 'Pedro Reyes',
      borrowerRole: 'Teacher - Science Dept',
      returnTimestamp: DateTime.now().subtract(const Duration(days: 1)),
      borrowDuration: '30 days',
      conditionStatus: ConditionStatus.underReview,
      returnPhotoPath: 'lib/assets/borrowed_assets/return_photo_3.jpg',
      borrowerNotes: 'Minor scratch on lens, needs inspection.',
    ),
  ];

  List<ReturnVerificationItem> get _filteredVerifications {
    return _allVerifications.where((item) {
      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        final matchesSearch =
            item.itemTitle.toLowerCase().contains(searchQuery) ||
            item.borrowerName.toLowerCase().contains(searchQuery);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_selectedFilter != null) {
        return item.conditionStatus == _selectedFilter;
      }

      return true;
    }).toList();
  }

  void _openInspectionModal(ReturnVerificationItem item) {
    final remarksController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          margin: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Return Verification - ${item.itemTitle}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Borrower Details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.borrowerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.borrowerRole,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Borrow Duration: ${item.borrowDuration}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo Proof Preview
                      const Text(
                        'Return Photo Proof',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: item.returnPhotoPath != null
                            ? Image.asset(
                                item.returnPhotoPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Photo not available'),
                                        ],
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.no_photography, size: 48),
                                    SizedBox(height: 8),
                                    Text('No photo uploaded'),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Borrower Notes
                      const Text(
                        'Borrower Condition Notes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.borrowerNotes ?? 'No notes provided.',
                          style: TextStyle(
                            color: item.borrowerNotes == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custodian Inspection Remarks
                      TextField(
                        controller: remarksController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Custodian Inspection Remarks',
                          hintText:
                              'Enter your official inspection notes here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDamageReportDialog(item, remarksController.text);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject / Flag Damage'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Return verified and inventory updated.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fact_check),
                        label: const Text('Approve Return'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDamageReportDialog(ReturnVerificationItem item, String remarks) {
    final damageController = TextEditingController(text: remarks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Damage / Reject Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report issues for ${item.itemTitle}:'),
            const SizedBox(height: 16),
            TextField(
              controller: damageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Damage / Issue Description *',
                hintText: 'Describe the damage or missing accessories...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (damageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please describe the damage or issue.'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Return flagged. Borrower will be notified for damage assessment.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return 'Today, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredVerifications = _filteredVerifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Return Verification')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by borrower or item name...',
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
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Good Condition'),
                    selected: _selectedFilter == ConditionStatus.good,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected
                            ? ConditionStatus.good
                            : null;
                      });
                    },
                    selectedColor: ConditionStatus.good.color.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: ConditionStatus.good.color,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Flagged / Damaged'),
                    selected:
                        _selectedFilter == ConditionStatus.damaged ||
                        _selectedFilter == ConditionStatus.underReview,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected
                            ? ConditionStatus.damaged
                            : null;
                      });
                    },
                    selectedColor: ConditionStatus.damaged.color.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: ConditionStatus.damaged.color,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Verifications List
          Expanded(
            child: filteredVerifications.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No verifications found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredVerifications.length,
                    itemBuilder: (context, index) {
                      final item = filteredVerifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VerificationCard(
                          item: item,
                          onVerify: () => _openInspectionModal(item),
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

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.item, required this.onVerify});

  final ReturnVerificationItem item;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, exception, stackTrace) => Icon(
                    item.fallbackIcon,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.assetTag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.borrowerName,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(item.returnTimestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Condition Badge and Action Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.conditionStatus.color.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.conditionStatus.label,
                          style: TextStyle(
                            color: item.conditionStatus.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.fact_check, size: 18),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return 'Today, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
