import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/resource_service.dart';
import '../widgets/borrower_navigation_bar.dart';
import 'student/borrow_request_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ResourceService _resourceService = ResourceService();
  final BorrowService _borrowService = BorrowService();
  final TextEditingController _searchController = TextEditingController();

  // Tier 1: Main Category Selection
  String _selectedMainCategory = 'All';

  String _selectedSubCategory = 'All';
  String _selectedItemType = 'All';

  // Availability Filter
  String _selectedAvailability = 'All';

  // Sorting Option
  String _selectedSortOption = 'Name (A-Z)';

  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter and sort resources
  List<ResourceItem> _getFilteredResources(List<ResourceItem> allResources) {
    List<ResourceItem> filtered = allResources.where((item) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);

      // Tier 1 filter
      final matchesMainCategory =
          _selectedMainCategory == 'All' ||
          item.mainCategory == _selectedMainCategory;

      final matchesSubCategory =
          _selectedSubCategory == 'All' ||
          item.subCategory == _selectedSubCategory;
      final matchesItemType =
          _selectedItemType == 'All' || item.itemType == _selectedItemType;

      // Availability filter
      final matchesAvailability =
          _selectedAvailability == 'All' ||
          (_selectedAvailability == 'Available Only' && item.isAvailable) ||
          (_selectedAvailability == 'On Loan / Borrowed' && !item.isAvailable);

      return matchesSearch &&
          matchesMainCategory &&
          matchesSubCategory &&
          matchesItemType &&
          matchesAvailability;
    }).toList();

    // Sort resources
    switch (_selectedSortOption) {
      case 'Name (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Most Popular / Borrowed':
      case 'Most Borrowed':
        // For demo purposes, we'll just keep the original order
        // In a real app, this would sort by borrow count
        break;
      case 'Recently Added':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
    }

    return filtered;
  }

  void _openFilterModal() {
    var availability = _selectedAvailability;
    var sort = _selectedSortOption;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter Resources',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          availability = 'All';
                          sort = 'Name (A-Z)';
                        }),
                        child: const Text('Reset All'),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Availability',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Available Only'].map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        selected: availability == option,
                        onSelected: (_) =>
                            setModalState(() => availability = option),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              'Name (A-Z)',
                              'Most Popular / Borrowed',
                              'Recently Added',
                            ]
                            .map(
                              (option) => ChoiceChip(
                                label: Text(option),
                                selected: sort == option,
                                onSelected: (_) =>
                                    setModalState(() => sort = option),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedAvailability = availability;
                        _selectedSortOption = sort;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<({String userId, String userName, String userRole})?>
  _currentBorrower() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection(AuthService.usersCollection)
        .doc(user.uid)
        .get();
    final role = AuthService.accountRoleFromFirestoreValue(doc.data()?['role']);
    if (!role.isBorrower) return null;

    return (
      userId: user.uid,
      userName: (doc.data()?['fullName'] ?? 'Unknown User').toString(),
      userRole: role == AccountRole.teacher ? 'teacher' : 'student',
    );
  }

  Future<void> _openBorrowRequest(ResourceItem resource) async {
    final borrower = await _currentBorrower();
    if (borrower == null) {
      if (mounted) {
        _showSnackBar('Please sign in to request a borrow.', isError: true);
      }
      return;
    }

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BorrowRequestScreen(resource: resource),
      ),
    );
  }

  void _borrowResource(ResourceItem resource, bool blocked) {
    if (blocked) {
      _showSnackBar('You already have an active borrow request for this item.');
      return;
    }
    _openBorrowRequest(resource);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Resources')),
      body: userId == null
          ? const Center(child: Text('Please sign in to browse resources.'))
          : StreamBuilder<List<BorrowTransaction>>(
              stream: _borrowService.getStudentBorrowHistory(userId),
              builder: (context, borrowSnapshot) {
                final pendingResourceIds = (borrowSnapshot.data ?? const [])
                    .where((transaction) => transaction.isPending)
                    .map((transaction) => transaction.resourceId)
                    .toSet();

                final activeResourceIds = (borrowSnapshot.data ?? const [])
                    .where(
                      (transaction) =>
                          transaction.userRole.toLowerCase() == 'student' &&
                          BorrowTransactionStatus.studentActiveBorrowStatuses
                              .contains(transaction.status),
                    )
                    .map((transaction) => transaction.resourceId)
                    .toSet();

                return StreamBuilder<List<ResourceItem>>(
                  stream: _resourceService.watchResources(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load resources.\n'
                          '${ResourceService.friendlyErrorMessage(snapshot.error!)}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredResources = _getFilteredResources(
                      snapshot.data ?? const [],
                    );

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        SearchBar(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          hintText: 'Search resources',
                          leading: const Icon(Icons.search),
                          trailing: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                            IconButton(
                              tooltip: 'Filter resources',
                              onPressed: _openFilterModal,
                              icon: const Icon(Icons.tune),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Resource Category',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                [
                                  ('All', 'All', Icons.apps_outlined),
                                  (
                                    generalLearningResources,
                                    'General Learning',
                                    Icons.menu_book_outlined,
                                  ),
                                  (
                                    ictResources,
                                    'ICT',
                                    Icons.computer_outlined,
                                  ),
                                  (
                                    tvlResources,
                                    'TVL',
                                    Icons.engineering_outlined,
                                  ),
                                ].map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(category.$3, size: 18),
                                      label: Text(category.$2),
                                      selected:
                                          _selectedMainCategory == category.$1,
                                      onSelected: (_) => setState(() {
                                        _selectedMainCategory = category.$1;
                                        _selectedSubCategory = 'All';
                                        _selectedItemType = 'All';
                                      }),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sub-Category',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                {
                                      'All',
                                      ...ResourceTaxonomy.filterSubCategories(
                                        _selectedMainCategory,
                                      ),
                                    }
                                    .map(
                                      (subCategory) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: FilterChip(
                                          label: Text(subCategory),
                                          selected:
                                              _selectedSubCategory ==
                                              subCategory,
                                          onSelected: (_) => setState(() {
                                            _selectedSubCategory = subCategory;
                                            _selectedItemType = 'All';
                                          }),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedSubCategory != 'All') ...[
                          Text(
                            'Item Type',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                        'All',
                                        ...getItemTypesForSubCategory(
                                          _selectedSubCategory,
                                        ),
                                      ]
                                      .map(
                                        (itemType) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: FilterChip(
                                            label: Text(itemType),
                                            selected:
                                                _selectedItemType == itemType,
                                            onSelected: (_) => setState(
                                              () =>
                                                  _selectedItemType = itemType,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Available resources',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              tooltip: _isGridView ? 'List view' : 'Grid view',
                              onPressed: () =>
                                  setState(() => _isGridView = !_isGridView),
                              icon: Icon(
                                _isGridView
                                    ? Icons.view_list_outlined
                                    : Icons.grid_view_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (filteredResources.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No resources found for the selected category.',
                            ),
                          )
                        else if (_isGridView)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredResources.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: .72,
                                ),
                            itemBuilder: (context, index) {
                              final resource = filteredResources[index];
                              return _ResourceGridCard(
                                resource: resource,
                                pending: pendingResourceIds.contains(
                                  resource.id,
                                ),
                                blocked: activeResourceIds.contains(
                                  resource.id,
                                ),
                                onBorrow: () => _borrowResource(
                                  resource,
                                  activeResourceIds.contains(resource.id),
                                ),
                              );
                            },
                          )
                        else
                          ...filteredResources.map(
                            (resource) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ResourceCard(
                                resource: resource,
                                pending: pendingResourceIds.contains(
                                  resource.id,
                                ),
                                blocked: activeResourceIds.contains(
                                  resource.id,
                                ),
                                onBorrow: () => _borrowResource(
                                  resource,
                                  activeResourceIds.contains(resource.id),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 1),
    );
  }
}

class _ResourceGridCard extends StatelessWidget {
  const _ResourceGridCard({
    required this.resource,
    required this.pending,
    required this.blocked,
    required this.onBorrow,
  });

  final ResourceItem resource;
  final bool pending;
  final bool blocked;
  final VoidCallback onBorrow;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: _ResourceImage(resource: resource, height: 110),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  resource.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  resource.isAvailable
                      ? '${resource.availableQuantity} Available'
                      : 'Out of Stock',
                  style: TextStyle(
                    color: resource.isAvailable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (blocked || pending || !resource.isAvailable)
                        ? null
                        : onBorrow,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    child: Text(
                      blocked
                          ? 'Already Borrowed'
                          : pending
                          ? 'Pending'
                          : resource.isAvailable
                          ? 'Request Borrow'
                          : 'Unavailable',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.pending,
    required this.blocked,
    required this.onBorrow,
  });
  final ResourceItem resource;
  final bool pending;
  final bool blocked;
  final VoidCallback onBorrow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final availabilityLabel = resource.isAvailable
        ? '${resource.availableQuantity} Available'
        : 'Out of Stock';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: _ResourceImage(resource: resource, height: 190),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resource.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Chip(
                  label: Text(
                    availabilityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: TextStyle(
                    color: resource.isAvailable
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: resource.isAvailable
                      ? Colors.green.withValues(alpha: .12)
                      : Colors.red.withValues(alpha: .12),
                  side: BorderSide.none,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (blocked || pending || !resource.isAvailable)
                        ? null
                        : onBorrow,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      blocked
                          ? 'Already Borrowed'
                          : pending
                          ? 'Pending'
                          : resource.isAvailable
                          ? 'Request Borrow'
                          : 'Unavailable',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceImage extends StatelessWidget {
  const _ResourceImage({required this.resource, required this.height});
  final ResourceItem resource;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resource.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          resource.fallbackIcon,
          size: 64,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, exception, stackTrace) => Container(
          height: height,
          color: Theme.of(context).colorScheme.secondaryContainer,
          alignment: Alignment.center,
          child: Icon(
            resource.fallbackIcon,
            size: 64,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      );
    }

    return Image.asset(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, exception, stackTrace) => Container(
        height: height,
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          resource.fallbackIcon,
          size: 64,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
