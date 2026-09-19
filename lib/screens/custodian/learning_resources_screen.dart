import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/resource_item.dart';
import '../../services/qr_service.dart';
import '../../services/resource_service.dart';
import 'add_edit_resource_screen.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ResourceService _resourceService = ResourceService();

  bool _isGridView = false;
  String _selectedMainCategory = ResourceTaxonomy.filterAll;
  String _selectedSubCategory = ResourceTaxonomy.filterAll;
  String _selectedItemType = ResourceTaxonomy.filterAll;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResourceItem> _filterResources(List<ResourceItem> resources) {
    final query = _searchController.text.trim().toLowerCase();

    return resources.where((item) {
      if (query.isNotEmpty) {
        final matchesSearch =
            item.itemName.toLowerCase().contains(query) ||
            item.itemCode.toLowerCase().contains(query) ||
            item.storageLocation.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      final matchesMain =
          _selectedMainCategory == ResourceTaxonomy.filterAll ||
          item.mainCategory == _selectedMainCategory;

      final matchesSub =
          _selectedSubCategory == ResourceTaxonomy.filterAll ||
          item.subCategory == _selectedSubCategory;

      final matchesType =
          _selectedItemType == ResourceTaxonomy.filterAll ||
          item.itemType == _selectedItemType;

      return matchesMain && matchesSub && matchesType;
    }).toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _openAddEditScreen([ResourceItem? resource]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditResourceScreen(resource: resource),
      ),
    );

    if (saved == true && mounted) {
      _showSnackBar(
        resource == null
            ? 'Resource saved successfully.'
            : 'Resource "${resource.itemName}" updated successfully.',
      );
    }
  }

  Future<void> _showQrCode(ResourceItem resource) async {
    final qrPayload = QrService.buildResourcePayload(
      itemCode: resource.itemCode,
      itemName: resource.itemName,
      mainCategory: resource.mainCategory,
      subCategory: resource.subCategory,
      storageLocation: resource.storageLocation,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await QrService.generateQrCode(qrPayload);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!result.success) {
      _showSnackBar(result.message, isError: true);
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resource QR Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                resource.itemName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Code: ${resource.itemCode}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (resource.storageLocation.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Location: ${resource.storageLocation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Image.network(
                result.imageUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Failed to load QR image.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.statusLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ResourceItem resource) {
    _DeleteOption selectedOption = resource.availableQuantity > 0
        ? _DeleteOption.quantity
        : _DeleteOption.all;
    int deleteQty = resource.availableQuantity > 0 ? 1 : 0;
    final qtyController = TextEditingController(
      text: deleteQty > 0 ? '$deleteQty' : '0',
    );
    bool isProcessing = false;
    String? customError;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final hasAvailable = resource.availableQuantity > 0;

            void updateQty(int newQty) {
              final clamped = newQty.clamp(1, resource.availableQuantity);
              setDialogState(() {
                deleteQty = clamped;
                qtyController.text = '$clamped';
                customError = null;
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Delete Resource'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resource Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource.itemName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Code: ${resource.itemCode} • ${resource.subCategory}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (resource.storageLocation.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      resource.storageLocation,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _QuantityBadge(
                                  label: 'Available',
                                  count: resource.availableQuantity,
                                  color: resource.isAvailable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                _QuantityBadge(
                                  label: 'Total',
                                  count: resource.totalQuantity,
                                  color: Colors.blue.shade700,
                                ),
                                if (resource.borrowedQuantity > 0)
                                  _QuantityBadge(
                                    label: 'Borrowed',
                                    count: resource.borrowedQuantity,
                                    color: Colors.orange.shade800,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selection: Delete Quantity vs Delete All Item
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<_DeleteOption>(
                          segments: const [
                            ButtonSegment<_DeleteOption>(
                              value: _DeleteOption.quantity,
                              label: Text('Delete Quantity'),
                              icon: Icon(Icons.remove_circle_outline, size: 18),
                            ),
                            ButtonSegment<_DeleteOption>(
                              value: _DeleteOption.all,
                              label: Text('Delete All Item'),
                              icon: Icon(
                                Icons.delete_forever_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                          selected: {selectedOption},
                          onSelectionChanged: (newSelection) {
                            setDialogState(() {
                              selectedOption = newSelection.first;
                              customError = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (selectedOption == _DeleteOption.quantity) ...[
                        if (!hasAvailable) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber.shade900,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No items available in stock to delete. All items are currently borrowed.',
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Quantity to Delete:',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: deleteQty > 1
                                    ? () => updateQty(deleteQty - 1)
                                    : null,
                                icon: const Icon(Icons.remove),
                                tooltip: 'Decrease',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: qtyController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    border: const OutlineInputBorder(),
                                    errorText: customError,
                                  ),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val.trim());
                                    if (parsed != null &&
                                        parsed >= 1 &&
                                        parsed <= resource.availableQuantity) {
                                      setDialogState(() {
                                        deleteQty = parsed;
                                        customError = null;
                                      });
                                    } else if (parsed != null &&
                                        parsed > resource.availableQuantity) {
                                      setDialogState(() {
                                        customError =
                                            'Max is ${resource.availableQuantity}';
                                      });
                                    } else {
                                      setDialogState(() {
                                        customError = 'Invalid quantity';
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed:
                                    deleteQty < resource.availableQuantity
                                    ? () => updateQty(deleteQty + 1)
                                    : null,
                                icon: const Icon(Icons.add),
                                tooltip: 'Increase',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quick selection chips
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('1 item'),
                                onPressed: () => updateQty(1),
                              ),
                              if (resource.availableQuantity >= 5)
                                ActionChip(
                                  label: const Text('5 items'),
                                  onPressed: () => updateQty(5),
                                ),
                              if (resource.availableQuantity > 1)
                                ActionChip(
                                  label: Text(
                                    'All Available (${resource.availableQuantity})',
                                  ),
                                  onPressed: () =>
                                      updateQty(resource.availableQuantity),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Calculation preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summary After Deletion:',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• New Available: ${resource.availableQuantity - deleteQty}',
                                  style: textTheme.bodySmall,
                                ),
                                Text(
                                  '• New Total: ${resource.totalQuantity - deleteQty}',
                                  style: textTheme.bodySmall,
                                ),
                                if (resource.totalQuantity - deleteQty <= 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'ℹ️ Total quantity will reach 0; the resource item will be removed from inventory.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        // Delete All Item view
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Permanently delete "${resource.itemName}"?',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This will delete all ${resource.totalQuantity} item(s) and completely remove this resource from the system catalog.',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12,
                                ),
                              ),
                              if (resource.borrowedQuantity > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '⚠️ Notice: ${resource.borrowedQuantity} item(s) are currently marked as borrowed.',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed:
                      isProcessing ||
                          (selectedOption == _DeleteOption.quantity &&
                              (!hasAvailable ||
                                  deleteQty <= 0 ||
                                  deleteQty > resource.availableQuantity ||
                                  customError != null))
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          try {
                            if (selectedOption == _DeleteOption.quantity) {
                              await _resourceService.deleteQuantity(
                                id: resource.id,
                                quantityToDelete: deleteQty,
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (!mounted) return;
                              _showSnackBar(
                                'Successfully deleted $deleteQty item(s) from "${resource.itemName}".',
                              );
                            } else {
                              await _resourceService.deleteResource(
                                resource.id,
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (!mounted) return;
                              _showSnackBar(
                                'Resource "${resource.itemName}" deleted completely.',
                              );
                            }
                          } catch (error) {
                            setDialogState(() => isProcessing = false);
                            if (!mounted) return;
                            _showSnackBar(
                              ResourceService.friendlyErrorMessage(error),
                              isError: true,
                            );
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          selectedOption == _DeleteOption.quantity
                              ? 'Delete $deleteQty Item${deleteQty > 1 ? 's' : ''}'
                              : 'Delete All Item',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = ResourceTaxonomy.filterSubCategories(
      _selectedMainCategory,
    );
    final itemTypes = ResourceTaxonomy.filterItemTypes(
      mainCategory: _selectedMainCategory,
      subCategory: _selectedSubCategory,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Resources')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name, code, or description...',
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
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ResourceItem>>(
              stream: _resourceService.watchResources(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Unable to load resources.\n'
                        '${ResourceService.friendlyErrorMessage(snapshot.error!)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allResources = snapshot.data ?? const [];
                final filteredResources = _filterResources(allResources);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Resource Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MainCategoryChip(
                            label: 'All',
                            icon: Icons.apps_outlined,
                            selected:
                                _selectedMainCategory ==
                                ResourceTaxonomy.filterAll,
                            onSelected: () {
                              setState(() {
                                _selectedMainCategory =
                                    ResourceTaxonomy.filterAll;
                                _selectedSubCategory =
                                    ResourceTaxonomy.filterAll;
                                _selectedItemType = ResourceTaxonomy.filterAll;
                              });
                            },
                          ),
                          _MainCategoryChip(
                            label: ResourceTaxonomy.mainCategoryGeneralLearning,
                            icon: Icons.menu_book_outlined,
                            selected:
                                _selectedMainCategory ==
                                ResourceTaxonomy.mainCategoryGeneralLearning,
                            onSelected: () {
                              setState(() {
                                _selectedMainCategory = ResourceTaxonomy
                                    .mainCategoryGeneralLearning;
                                _selectedSubCategory =
                                    ResourceTaxonomy.filterAll;
                                _selectedItemType = ResourceTaxonomy.filterAll;
                              });
                            },
                          ),
                          _MainCategoryChip(
                            label: ResourceTaxonomy.mainCategoryIct,
                            icon: Icons.computer_outlined,
                            selected:
                                _selectedMainCategory ==
                                ResourceTaxonomy.mainCategoryIct,
                            onSelected: () {
                              setState(() {
                                _selectedMainCategory =
                                    ResourceTaxonomy.mainCategoryIct;
                                _selectedSubCategory =
                                    ResourceTaxonomy.filterAll;
                                _selectedItemType = ResourceTaxonomy.filterAll;
                              });
                            },
                          ),
                          _MainCategoryChip(
                            label: ResourceTaxonomy.mainCategoryTvl,
                            icon: Icons.engineering_outlined,
                            selected:
                                _selectedMainCategory ==
                                ResourceTaxonomy.mainCategoryTvl,
                            onSelected: () {
                              setState(() {
                                _selectedMainCategory =
                                    ResourceTaxonomy.mainCategoryTvl;
                                _selectedSubCategory =
                                    ResourceTaxonomy.filterAll;
                                _selectedItemType = ResourceTaxonomy.filterAll;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_selectedMainCategory !=
                        ResourceTaxonomy.filterAll) ...[
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
                          children: subCategories.map((subCategory) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(subCategory),
                                selected: _selectedSubCategory == subCategory,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSubCategory = subCategory;
                                    _selectedItemType =
                                        ResourceTaxonomy.filterAll;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (_selectedMainCategory != ResourceTaxonomy.filterAll &&
                        _selectedSubCategory != ResourceTaxonomy.filterAll) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Item Type',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: itemTypes.map((itemType) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  itemType,
                                  style: TextStyle(
                                    fontSize: itemType.length > 22 ? 11 : null,
                                  ),
                                ),
                                selected: _selectedItemType == itemType,
                                onSelected: (_) {
                                  setState(() => _selectedItemType = itemType);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inventory (${filteredResources.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.view_list_rounded,
                                  color: !_isGridView
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'List View',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  if (_isGridView) {
                                    setState(() => _isGridView = false);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  color: _isGridView
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'Grid View',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  if (!_isGridView) {
                                    setState(() => _isGridView = true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filteredResources.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No resources found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
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
                              childAspectRatio: 0.62,
                            ),
                        itemBuilder: (context, index) {
                          final resource = filteredResources[index];
                          return _InventoryGridCard(
                            resource: resource,
                            onEdit: () => _openAddEditScreen(resource),
                            onQr: () => _showQrCode(resource),
                            onDelete: () => _confirmDelete(resource),
                          );
                        },
                      )
                    else
                      ...filteredResources.map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InventoryCard(
                            resource: resource,
                            onEdit: () => _openAddEditScreen(resource),
                            onQr: () => _showQrCode(resource),
                            onDelete: () => _confirmDelete(resource),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditScreen(),
        icon: const Icon(Icons.add),
        label: const Text('Add New Resource'),
      ),
    );
  }
}

Widget _buildResourceImage({
  required String? imageUrl,
  required IconData fallbackIcon,
  required ColorScheme colorScheme,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return Icon(
      fallbackIcon,
      size: (height != null && height < 70) ? 30 : 36,
      color: colorScheme.onSecondaryContainer,
    );
  }

  final trimmed = imageUrl.trim();
  if (trimmed.startsWith('data:image')) {
    try {
      final base64Data = trimmed.contains(',')
          ? trimmed.split(',').last
          : trimmed;
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Icon(
          fallbackIcon,
          size: 32,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    } catch (_) {
      return Icon(
        fallbackIcon,
        size: 32,
        color: colorScheme.onSecondaryContainer,
      );
    }
  } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) =>
          Icon(fallbackIcon, size: 32, color: colorScheme.onSecondaryContainer),
    );
  } else {
    return Image.asset(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) =>
          Icon(fallbackIcon, size: 32, color: colorScheme.onSecondaryContainer),
    );
  }
}

class _MainCategoryChip extends StatelessWidget {
  const _MainCategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.resource,
    required this.onEdit,
    required this.onQr,
    required this.onDelete,
  });

  final ResourceItem resource;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildResourceImage(
                imageUrl: resource.imageUrl,
                fallbackIcon: resource.fallbackIcon,
                colorScheme: colorScheme,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.itemName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.itemCode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (resource.storageLocation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            resource.storageLocation,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          resource.subCategory,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: colorScheme.primaryContainer,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        label: Text(
                          '${resource.maxBorrowDays}d limit',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onQr,
                  icon: const Icon(Icons.qr_code_2_outlined),
                  tooltip: 'Generate QR',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryGridCard extends StatelessWidget {
  const _InventoryGridCard({
    required this.resource,
    required this.onEdit,
    required this.onQr,
    required this.onDelete,
  });

  final ResourceItem resource;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with status & duration badges
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 110,
                color: colorScheme.secondaryContainer,
                child: _buildResourceImage(
                  imageUrl: resource.imageUrl,
                  fallbackIcon: resource.fallbackIcon,
                  colorScheme: colorScheme,
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: resource.isAvailable
                        ? Colors.green.shade700.withValues(alpha: 0.9)
                        : Colors.red.shade700.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${resource.availableQuantity}/${resource.totalQuantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (resource.maxBorrowDays > 0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${resource.maxBorrowDays}d limit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.itemName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resource.itemCode,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (resource.storageLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            resource.storageLocation,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Compact action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        tooltip: 'Edit',
                        onPressed: onEdit,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(Icons.qr_code_2_outlined, size: 17),
                        tooltip: 'Generate QR',
                        onPressed: onQr,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 17,
                        ),
                        tooltip: 'Delete',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DeleteOption { quantity, all }

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
