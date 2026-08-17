import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/account_role.dart';
import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/resource_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrower_navigation_bar.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ResourceService _resourceService = ResourceService();
  final BorrowService _borrowService = BorrowService();

  // Tier 1: Main Category Selection
  String _selectedMainCategory = 'All';

  // Tier 2: Sub-Category Selection
  String _selectedSubCategory = 'All';

  // Tier 3: Item Type Filter
  String _selectedItemType = 'All';

  // Availability Filter
  String _selectedAvailability = 'All';

  // Sorting Option
  String _selectedSortOption = 'Name (A-Z)';

  // Get sub-categories based on selected main category
  List<String> _getSubCategories(String mainCategory) {
    if (mainCategory == 'All') {
      // Return all sub-categories from all main categories
      return [
        'All',
        generalLearning,
        scienceLab,
        mathematics,
        audioVisual,
        sports,
        artsDesign,
        generalInfrastructure,
        vocationalTechnicalTools,
        homeEconomics,
        industrialArts,
        agriFisheryArts,
      ];
    }

    switch (mainCategory) {
      case generalLearningResources:
        return [
          'All',
          generalLearning,
          scienceLab,
          mathematics,
          audioVisual,
          sports,
          artsDesign,
        ];
      case ictResources:
        return ['All', generalInfrastructure, vocationalTechnicalTools];
      case tvlResources:
        return ['All', homeEconomics, industrialArts, agriFisheryArts];
      default:
        return ['All'];
    }
  }

  // Get item types based on selected sub-category
  List<String> _getItemTypes(String subCategory) {
    if (subCategory == 'All') {
      // Return all item types for the current main category
      if (_selectedMainCategory == 'All') {
        // Return all item types from all categories
        return [
          'All',
          ...generalLearningItemTypes,
          ...scienceLabItemTypes,
          ...mathematicsItemTypes,
          ...audioVisualItemTypes,
          ...sportsItemTypes,
          ...artsDesignItemTypes,
          ...generalInfrastructureItemTypes,
          ...vocationalTechnicalItemTypes,
          ...homeEconomicsItemTypes,
          ...industrialArtsItemTypes,
          ...agriFisheryArtsItemTypes,
        ];
      }

      switch (_selectedMainCategory) {
        case generalLearningResources:
          return [
            'All',
            ...generalLearningItemTypes,
            ...scienceLabItemTypes,
            ...mathematicsItemTypes,
            ...audioVisualItemTypes,
            ...sportsItemTypes,
            ...artsDesignItemTypes,
          ];
        case ictResources:
          return [
            'All',
            ...generalInfrastructureItemTypes,
            ...vocationalTechnicalItemTypes,
          ];
        case tvlResources:
          return [
            'All',
            ...homeEconomicsItemTypes,
            ...industrialArtsItemTypes,
            ...agriFisheryArtsItemTypes,
          ];
        default:
          return ['All'];
      }
    }
    return ['All', ...getItemTypesForSubCategory(subCategory)];
  }

  // Filter and sort resources
  List<ResourceItem> _getFilteredResources(List<ResourceItem> allResources) {
    List<ResourceItem> filtered = allResources.where((item) {
      // Tier 1 filter
      final matchesMainCategory =
          _selectedMainCategory == 'All' ||
          item.mainCategory == _selectedMainCategory;

      // Tier 2 filter
      final matchesSubCategory =
          _selectedSubCategory == 'All' ||
          item.subCategory == _selectedSubCategory;

      // Tier 3 filter
      final matchesItemType =
          _selectedItemType == 'All' || item.itemType == _selectedItemType;

      // Availability filter
      final matchesAvailability =
          _selectedAvailability == 'All' ||
          (_selectedAvailability == 'Available Only' && item.isAvailable) ||
          (_selectedAvailability == 'On Loan / Borrowed' && !item.isAvailable);

      return matchesMainCategory &&
          matchesSubCategory &&
          matchesItemType &&
          matchesAvailability;
    }).toList();

    // Sort resources
    switch (_selectedSortOption) {
      case 'Name (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Availability Filter
                        Text(
                          'Availability',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children:
                              ['All', 'Available Only', 'On Loan / Borrowed']
                                  .map(
                                    (option) => FilterChip(
                                      label: Text(option),
                                      selected: _selectedAvailability == option,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          _selectedAvailability = option;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),

                        // Tier 3: Item Type Filter (Horizontal Scrollable)
                        Text(
                          'Item Type',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _getItemTypes(_selectedSubCategory)
                                .map(
                                  (itemType) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        itemType,
                                        style: TextStyle(
                                          fontSize: itemType.length > 20
                                              ? 11
                                              : null,
                                        ),
                                      ),
                                      selected: _selectedItemType == itemType,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          _selectedItemType = itemType;
                                        });
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sorting Options
                        Text(
                          'Sort By',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children:
                              ['Name (A-Z)', 'Most Borrowed', 'Recently Added']
                                  .map(
                                    (option) => FilterChip(
                                      label: Text(option),
                                      selected: _selectedSortOption == option,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          _selectedSortOption = option;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Apply Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ),
              ],
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

    final result = await showDialog<_BorrowRequestResult>(
      context: context,
      builder: (dialogContext) => _BorrowRequestDialog(
        resource: resource,
        isTeacher: borrower.userRole == 'teacher',
        onValidationError: _showSnackBar,
      ),
    );

    if (result == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _borrowService.requestBorrow(
        resourceId: resource.id,
        resourceName: resource.name,
        resourceCode: resource.code,
        userId: borrower.userId,
        userName: borrower.userName,
        userRole: borrower.userRole,
        expectedReturnDate: result.expectedReturnDate,
        requestedQuantity: result.requestedQuantity,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          '${resource.name} request submitted successfully'
          '${result.requestedQuantity > 1 ? ' (${result.requestedQuantity} items)' : ''}.',
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = _getSubCategories(_selectedMainCategory);
    final itemTypes = _getItemTypes(_selectedSubCategory);

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
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final filteredResources =
                        _getFilteredResources(snapshot.data ?? const []);

                    return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SearchBar(
            hintText: 'Search resources',
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(
                onPressed: _openFilterModal,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tier 1: Main Category Selection
          Text(
            'Resource Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'All',
                label: Text('All'),
                icon: Icon(Icons.apps_outlined),
              ),
              ButtonSegment(
                value: generalLearningResources,
                label: Text('General Learning'),
                icon: Icon(Icons.menu_book_outlined),
              ),
              ButtonSegment(
                value: ictResources,
                label: Text('ICT'),
                icon: Icon(Icons.computer_outlined),
              ),
              ButtonSegment(
                value: tvlResources,
                label: Text('TVL'),
                icon: Icon(Icons.engineering_outlined),
              ),
            ],
            selected: {_selectedMainCategory},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedMainCategory = newSelection.first;
                _selectedSubCategory =
                    'All'; // Reset sub-category on main category change
                _selectedItemType =
                    'All'; // Reset item type on main category change
              });
            },
          ),
          const SizedBox(height: 20),

          // Tier 2: Sub-Category Filter Chips
          Text(
            'Sub-Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subCategories
                  .map(
                    (subCategory) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(subCategory),
                        selected: _selectedSubCategory == subCategory,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSubCategory = subCategory;
                            _selectedItemType =
                                'All'; // Reset item type when sub-category changes
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tier 3: Item Type Filter Chips
          if (_selectedSubCategory != 'All') ...[
            Text(
              'Item Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: itemTypes
                    .map(
                      (itemType) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            itemType,
                            style: TextStyle(
                              fontSize: itemType.length > 20 ? 11 : null,
                            ),
                          ),
                          selected: _selectedItemType == itemType,
                          onSelected: (selected) {
                            setState(() {
                              _selectedItemType = itemType;
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Available Resources
          Text(
            'Available resources',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (filteredResources.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No resources found for the selected category.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...filteredResources.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ResourceCard(
                  resource: resource,
                  pending: pendingResourceIds.contains(resource.id),
                  onBorrow: () => _openBorrowRequest(resource),
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

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.pending,
    required this.onBorrow,
  });
  final ResourceItem resource;
  final bool pending;
  final VoidCallback onBorrow;

  @override
  Widget build(BuildContext context) => Card(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(resource.subCategory),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ),
                  Chip(
                    label: Text(
                      resource.isAvailable
                          ? '${resource.availableQuantity} Available'
                          : 'Out of Stock',
                    ),
                    backgroundColor: resource.isAvailable
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                resource.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (pending || !resource.isAvailable)
                      ? null
                      : onBorrow,
                  icon: Icon(
                    pending
                        ? Icons.pending_actions
                        : resource.isAvailable
                        ? Icons.add_shopping_cart_outlined
                        : Icons.block_outlined,
                  ),
                  label: Text(
                    pending
                        ? 'Pending Request'
                        : resource.isAvailable
                        ? 'Request Borrow'
                        : 'Unavailable',
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

class _BorrowRequestResult {
  const _BorrowRequestResult({
    required this.expectedReturnDate,
    required this.requestedQuantity,
  });

  final DateTime expectedReturnDate;
  final int requestedQuantity;
}

class _BorrowRequestDialog extends StatefulWidget {
  const _BorrowRequestDialog({
    required this.resource,
    required this.isTeacher,
    required this.onValidationError,
  });

  final ResourceItem resource;
  final bool isTeacher;
  final void Function(String message, {bool isError}) onValidationError;

  @override
  State<_BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<_BorrowRequestDialog> {
  late final TextEditingController _quantityController;
  DateTime? _expectedReturnDate;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int? _parseRequestedQuantity() {
    return int.tryParse(_quantityController.text.trim());
  }

  bool _validateQuantity({required bool showSnackBarOnError}) {
    final quantity = _parseRequestedQuantity();
    if (quantity == null || quantity < 1) {
      _quantityError = 'Enter a valid quantity (1 or more).';
      return false;
    }
    if (!widget.isTeacher && quantity != 1) {
      _quantityError = 'Students can only borrow 1 item at a time.';
      return false;
    }
    if (quantity > widget.resource.maxBorrowLimit) {
      _quantityError =
          'Exceeds the maximum limit set by the Property Custodian (Max: ${widget.resource.maxBorrowLimit})';
      if (showSnackBarOnError) {
        widget.onValidationError(_quantityError!, isError: true);
      }
      return false;
    }
    if (quantity > widget.resource.availableQuantity) {
      _quantityError =
          'Only ${widget.resource.availableQuantity} item${widget.resource.availableQuantity == 1 ? '' : 's'} available.';
      if (showSnackBarOnError) {
        widget.onValidationError(_quantityError!, isError: true);
      }
      return false;
    }
    _quantityError = null;
    return true;
  }

  Future<void> _pickReturnDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _expectedReturnDate = selected);
    }
  }

  void _submit() {
    if (_expectedReturnDate == null) return;
    if (!_validateQuantity(showSnackBarOnError: true)) {
      setState(() {});
      return;
    }

    Navigator.pop(
      context,
      _BorrowRequestResult(
        expectedReturnDate: _expectedReturnDate!,
        requestedQuantity: _parseRequestedQuantity() ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;

    return AlertDialog(
      title: const Text('Request Borrow'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text('Code: ${resource.code}'),
            Text('Available: ${resource.availableQuantity}'),
            if (widget.isTeacher)
              Text('Max borrow limit: ${resource.maxBorrowLimit}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              enabled: widget.isTeacher,
              readOnly: !widget.isTeacher,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: const OutlineInputBorder(),
                helperText: widget.isTeacher
                    ? 'Teachers may request up to ${resource.maxBorrowLimit} per transaction'
                    : 'Students are limited to 1 item per request',
                errorText: _quantityError,
              ),
              onChanged: widget.isTeacher
                  ? (_) {
                      _validateQuantity(showSnackBarOnError: false);
                      setState(() {});
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickReturnDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expected Return Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _expectedReturnDate == null
                      ? 'Select date'
                      : formatBorrowDate(_expectedReturnDate!),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _expectedReturnDate == null ? null : _submit,
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}

