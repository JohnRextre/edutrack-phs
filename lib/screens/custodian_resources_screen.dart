import 'package:flutter/material.dart';

import '../models/resource_item.dart';

class CustodianResourcesScreen extends StatefulWidget {
  const CustodianResourcesScreen({super.key});

  @override
  State<CustodianResourcesScreen> createState() =>
      _CustodianResourcesScreenState();
}

class _CustodianResourcesScreenState extends State<CustodianResourcesScreen> {
  // Tier 1: Main Category Selection
  String _selectedMainCategory = 'All';

  // Tier 2: Sub-Category Selection
  String _selectedSubCategory = 'All';

  // Tier 3: Item Type Filter
  String _selectedItemType = 'All';

  // Get sub-categories based on selected main category
  List<String> _getSubCategories(String mainCategory) {
    if (mainCategory == 'All') {
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
      if (_selectedMainCategory == 'All') {
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

  // Filter resources
  List<ResourceItem> _getFilteredResources() {
    return allResourceItems.where((item) {
      final matchesMainCategory =
          _selectedMainCategory == 'All' ||
          item.mainCategory == _selectedMainCategory;

      final matchesSubCategory =
          _selectedSubCategory == 'All' ||
          item.subCategory == _selectedSubCategory;

      final matchesItemType =
          _selectedItemType == 'All' || item.itemType == _selectedItemType;

      return matchesMainCategory && matchesSubCategory && matchesItemType;
    }).toList();
  }

  void _openAddEditModal([ResourceItem? resource]) {
    final isEdit = resource != null;
    final nameController = TextEditingController(text: resource?.name ?? '');
    final codeController = TextEditingController(text: resource?.code ?? '');
    final descController = TextEditingController(
      text: resource?.description ?? '',
    );
    String selectedMainCat = resource?.mainCategory ?? 'All';
    String selectedSubCat = resource?.subCategory ?? 'All';
    String selectedItemType = resource?.itemType ?? 'All';
    int totalQty = resource?.totalQuantity ?? 1;
    int availableQty = resource?.availableQuantity ?? 1;

    // Store original values for edit mode comparison
    final originalCode = resource?.code ?? '';
    final originalName = resource?.name ?? '';
    final originalMainCat = resource?.mainCategory ?? 'All';
    final originalSubCat = resource?.subCategory ?? 'All';
    final originalItemType = resource?.itemType ?? 'All';
    final originalTotalQty = resource?.totalQuantity ?? 1;
    final originalAvailableQty = resource?.availableQuantity ?? 1;
    final originalDesc = resource?.description ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    Text(
                      isEdit ? 'Edit Resource' : 'Add New Resource',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Item Code
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Item Code / Asset Tag',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedMainCat,
                        decoration: const InputDecoration(
                          labelText: 'Main Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                            value: generalLearningResources,
                            child: Text('General Learning'),
                          ),
                          DropdownMenuItem(
                            value: ictResources,
                            child: Text('ICT'),
                          ),
                          DropdownMenuItem(
                            value: tvlResources,
                            child: Text('TVL'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedMainCat = value;
                              selectedSubCat = 'All';
                              selectedItemType = 'All';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sub-Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedSubCat,
                        decoration: const InputDecoration(
                          labelText: 'Sub-Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _getSubCategories(selectedMainCat)
                            .map(
                              (subCat) => DropdownMenuItem(
                                value: subCat,
                                child: Text(subCat),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedSubCat = value;
                              selectedItemType = 'All';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Item Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedItemType,
                        decoration: const InputDecoration(
                          labelText: 'Item Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _getItemTypes(selectedSubCat)
                            .map(
                              (itemType) => DropdownMenuItem(
                                value: itemType,
                                child: Text(itemType),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedItemType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Total Quantity
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Total Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: totalQty.toString())
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: totalQty.toString().length,
                                ),
                              ),
                        onChanged: (value) {
                          totalQty = int.tryParse(value) ?? 1;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Available Quantity
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Available Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: availableQty.toString())
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: availableQty.toString().length,
                                ),
                              ),
                        onChanged: (value) {
                          availableQty = int.tryParse(value) ?? 0;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description / Specifications',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Save Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (isEdit) {
                        // Check if any changes were made
                        final hasChanges =
                            codeController.text.trim() != originalCode ||
                            nameController.text.trim() != originalName ||
                            selectedMainCat != originalMainCat ||
                            selectedSubCat != originalSubCat ||
                            selectedItemType != originalItemType ||
                            totalQty != originalTotalQty ||
                            availableQty != originalAvailableQty ||
                            descController.text.trim() != originalDesc;

                        if (!hasChanges) {
                          // No changes made
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No changes were made to this resource.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Update existing resource
                        final index = allResourceItems.indexOf(resource);
                        if (index != -1) {
                          allResourceItems[index] = ResourceItem(
                            name: nameController.text.trim(),
                            code: codeController.text.trim(),
                            mainCategory: selectedMainCat,
                            subCategory: selectedSubCat,
                            itemType: selectedItemType,
                            description: descController.text.trim(),
                            assetPath: resource.assetPath,
                            fallbackIcon: resource.fallbackIcon,
                            totalQuantity: totalQty,
                            availableQuantity: availableQty,
                            borrowedQuantity: resource.borrowedQuantity,
                          );
                        }

                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Resource "${nameController.text.trim()}" updated successfully!',
                            ),
                          ),
                        );
                      } else {
                        // Check for duplicate item code (case-insensitive)
                        final enteredCode = codeController.text.trim();
                        final isDuplicate = allResourceItems.any(
                          (item) =>
                              item.code.toLowerCase() ==
                              enteredCode.toLowerCase(),
                        );

                        if (isDuplicate) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: An item with Asset Code "$enteredCode" already exists.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Add new resource
                        final newResource = ResourceItem(
                          name: nameController.text.trim(),
                          code: enteredCode,
                          mainCategory: selectedMainCat,
                          subCategory: selectedSubCat,
                          itemType: selectedItemType,
                          description: descController.text.trim(),
                          assetPath:
                              'lib/assets/borrowed_assets/placeholder.png',
                          fallbackIcon: Icons.inventory_2_outlined,
                          totalQuantity: totalQty,
                          availableQuantity: availableQty,
                          borrowedQuantity: 0,
                        );

                        allResourceItems.add(newResource);
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Resource "${nameController.text.trim()}" added successfully!',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isEdit ? 'Update Resource' : 'Add New Resource',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteResource(ResourceItem resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
          'Are you sure you want to delete "${resource.name}"? This will remove it from the catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${resource.name} deleted successfully'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredResources = _getFilteredResources();
    final subCategories = _getSubCategories(_selectedMainCategory);
    final itemTypes = _getItemTypes(_selectedSubCategory);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Resources')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search Bar
          SearchBar(
            hintText: 'Search resources',
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
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
                _selectedSubCategory = 'All';
                _selectedItemType = 'All';
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
                            _selectedItemType = 'All';
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

          // Inventory Cards
          Text(
            'Inventory',
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
                  'No resources found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...filteredResources.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _InventoryCard(
                  resource: resource,
                  onEdit: () => _openAddEditModal(resource),
                  onDelete: () => _deleteResource(resource),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        icon: const Icon(Icons.add),
        label: const Text('Add New Resource'),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.resource,
    required this.onEdit,
    required this.onDelete,
  });

  final ResourceItem resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              resource.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, exception, stackTrace) => Icon(
                resource.fallbackIcon,
                size: 40,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Resource Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  resource.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        resource.subCategory,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(
                        '${resource.availableQuantity}/${resource.totalQuantity}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: resource.isAvailable
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
