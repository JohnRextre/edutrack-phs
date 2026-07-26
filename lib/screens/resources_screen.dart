import 'package:flutter/material.dart';

import '../models/resource_item.dart';
import '../widgets/borrower_navigation_bar.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final Map<String, bool> _pendingRequests = {};

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
  List<ResourceItem> _getFilteredResources() {
    List<ResourceItem> filtered = allResourceItems.where((item) {
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
        // For demo purposes, we'll reverse the list
        filtered = filtered.reversed.toList();
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

  Future<void> _openBorrowRequest(ResourceItem resource) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _BorrowRequestScreen(resource: resource),
      ),
    );

    if (submitted == true && mounted) {
      setState(() => _pendingRequests[resource.code] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${resource.name} request submitted successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredResources = _getFilteredResources();
    final subCategories = _getSubCategories(_selectedMainCategory);
    final itemTypes = _getItemTypes(_selectedSubCategory);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Resources')),
      body: ListView(
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
                  pending: _pendingRequests[resource.code] ?? false,
                  onBorrow: () => _openBorrowRequest(resource),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 1),
    );
  }
}

class _BorrowRequestScreen extends StatefulWidget {
  const _BorrowRequestScreen({required this.resource});

  final ResourceItem resource;

  @override
  State<_BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<_BorrowRequestScreen> {
  late DateTime _borrowDate;
  DateTime? _returnDate;
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _borrowDate = DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isReturnDate}) async {
    final current = isReturnDate ? (_returnDate ?? _borrowDate) : _borrowDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: _borrowDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        if (isReturnDate) {
          _returnDate = selected;
        } else {
          _borrowDate = selected;
          if (_returnDate != null && _returnDate!.isBefore(selected)) {
            _returnDate = null;
          }
        }
      });
    }
  }

  void _submit() {
    if (_returnDate == null || _purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide a return date and purpose of borrowing.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _dateLabel(DateTime? date) => date == null
      ? 'Select date'
      : MaterialLocalizations.of(context).formatMediumDate(date);

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResourceImage(resource: resource, height: 176),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Code: ${resource.code}')),
                            Chip(label: Text(resource.subCategory)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(resource.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Request Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Borrow Date',
              value: _dateLabel(_borrowDate),
              onTap: () => _pickDate(isReturnDate: false),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Return Date / Due Date',
              value: _dateLabel(_returnDate),
              onTap: () => _pickDate(isReturnDate: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Purpose of Borrowing',
                hintText: 'e.g., Research for Science Fair / STEM Class',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send),
          label: const Text('Submit Borrow Request'),
        ),
      ),
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
                        ? 'Borrow'
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
  Widget build(BuildContext context) => Image.asset(
    resource.assetPath,
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(value),
    ),
  );
}
