import 'package:flutter/material.dart';

import '../../models/resource_item.dart';
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

  void _confirmDelete(ResourceItem resource) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
          'Are you sure you want to delete "${resource.itemName}"? '
          'This will remove it from the catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _resourceService.deleteResource(resource.id);
                if (!mounted) return;
                _showSnackBar('${resource.itemName} deleted successfully.');
              } catch (error) {
                _showSnackBar(
                  ResourceService.friendlyErrorMessage(error),
                  isError: true,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subCategories =
        ResourceTaxonomy.filterSubCategories(_selectedMainCategory);
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
                                _selectedMainCategory =
                                    ResourceTaxonomy.mainCategoryGeneralLearning;
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
                    const SizedBox(height: 20),
                    Text(
                      'Sub-Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                                  _selectedItemType = ResourceTaxonomy.filterAll;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedSubCategory != ResourceTaxonomy.filterAll) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Item Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                    Text(
                      'Inventory (${filteredResources.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    else
                      ...filteredResources.map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InventoryCard(
                            resource: resource,
                            onEdit: () => _openAddEditScreen(resource),
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
    required this.onDelete,
  });

  final ResourceItem resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage =
        resource.imageUrl != null && resource.imageUrl!.trim().isNotEmpty;

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
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        resource.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          resource.fallbackIcon,
                          size: 32,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    )
                  : Icon(
                      resource.fallbackIcon,
                      size: 32,
                      color: colorScheme.onSecondaryContainer,
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
