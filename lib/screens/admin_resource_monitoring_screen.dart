import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/resource_item.dart';
import '../services/resource_service.dart';

class AdminResourceMonitoringScreen extends StatefulWidget {
  const AdminResourceMonitoringScreen({super.key});

  @override
  State<AdminResourceMonitoringScreen> createState() =>
      _AdminResourceMonitoringScreenState();
}

class _AdminResourceMonitoringScreenState
    extends State<AdminResourceMonitoringScreen> {
  final ResourceService _resourceService = ResourceService();
  final TextEditingController _searchController = TextEditingController();
  String _category = ResourceTaxonomy.filterAll;
  _ResourceSort _sort = _ResourceSort.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResourceItem> _filter(List<ResourceItem> resources) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = resources.where((resource) {
      final matchesSearch =
          query.isEmpty ||
          resource.itemName.toLowerCase().contains(query) ||
          resource.itemCode.toLowerCase().contains(query) ||
          resource.itemType.toLowerCase().contains(query) ||
          resource.storageLocation.toLowerCase().contains(query);
      return matchesSearch &&
          (_category == ResourceTaxonomy.filterAll ||
              resource.mainCategory == _category);
    }).toList();
    filtered.sort((a, b) {
      switch (_sort) {
        case _ResourceSort.name:
          return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
        case _ResourceSort.availability:
          return _availabilityRatio(a).compareTo(_availabilityRatio(b));
        case _ResourceSort.quantity:
          return b.availableQuantity.compareTo(a.availableQuantity);
        case _ResourceSort.status:
          return _statusPriority(a).compareTo(_statusPriority(b));
      }
    });
    return filtered;
  }

  static double _availabilityRatio(ResourceItem resource) {
    if (resource.totalQuantity < 1) return 0;
    return resource.availableQuantity / resource.totalQuantity;
  }

  static int _statusPriority(ResourceItem resource) {
    if (resource.availableQuantity == 0) return 0;
    final status = resource.inventoryStatus.toLowerCase();
    if (status == 'damaged' ||
        status == 'under_repair' ||
        status == 'for_replacement' ||
        resource.damagedQuantity > 0) {
      return 1;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resource Monitoring'),
        actions: [
          IconButton(
            tooltip: 'Refresh resources',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<ResourceItem>>(
        stream: _resourceService.watchResources(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load learning resources.\n'
                '${ResourceService.friendlyErrorMessage(snapshot.error!)}',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resources = _filter(snapshot.data ?? const []);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonitoringHeader(
                total: snapshot.data?.length ?? 0,
                visible: resources.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search by name, code, type, or location',
                  leading: const Icon(Icons.search),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _category == ResourceTaxonomy.filterAll,
                      onTap: () => setState(
                        () => _category = ResourceTaxonomy.filterAll,
                      ),
                    ),
                    ...ResourceTaxonomy.mainCategories.map(
                      (category) => _CategoryChip(
                        label: category,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${resources.length} resource${resources.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<_ResourceSort>(
                        value: _sort,
                        icon: const Icon(Icons.sort_rounded, size: 20),
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: _ResourceSort.name,
                            child: Text('Name'),
                          ),
                          DropdownMenuItem(
                            value: _ResourceSort.availability,
                            child: Text('Availability %'),
                          ),
                          DropdownMenuItem(
                            value: _ResourceSort.quantity,
                            child: Text('Available quantity'),
                          ),
                          DropdownMenuItem(
                            value: _ResourceSort.status,
                            child: Text('Needs attention'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: resources.isEmpty
                    ? Center(
                        child: Text(
                          'No learning resources match your filters.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: resources.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _ResourceMonitorCard(
                          resource: resources[index],
                          onTap: () =>
                              _showResourceDetails(context, resources[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResourceDetails(BuildContext context, ResourceItem resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ResourceDetailsSheet(resource: resource),
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  const _MonitoringHeader({required this.total, required this.visible});

  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resource Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  visible == total
                      ? '$total resources being monitored'
                      : 'Showing $visible of $total resources',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceMonitorCard extends StatelessWidget {
  const _ResourceMonitorCard({required this.resource, required this.onTap});

  final ResourceItem resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stockRatio = resource.totalQuantity == 0
        ? 0.0
        : resource.availableQuantity / resource.totalQuantity;
    final needsAttention =
        resource.availableQuantity == 0 ||
        resource.inventoryStatus.toLowerCase() == 'damaged' ||
        resource.inventoryStatus.toLowerCase() == 'under_repair' ||
        resource.inventoryStatus.toLowerCase() == 'for_replacement' ||
        resource.damagedQuantity > 0;
    final statusColor = needsAttention ? colors.error : Colors.green.shade700;
    final status = resource.availableQuantity == 0
        ? 'Out of stock'
        : needsAttention
        ? 'Needs attention'
        : 'Available';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ResourceImage(resource: resource, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.itemName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${resource.itemCode} • ${resource.mainCategory}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Availability',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    '${resource.availableQuantity}/${resource.totalQuantity} available',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stockRatio.clamp(0.0, 1.0),
                  minHeight: 8,
                  color: statusColor,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              if (resource.storageLocation.isNotEmpty ||
                  resource.inventoryStatus.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (resource.storageLocation.isNotEmpty)
                      Text(
                        'Location: ${resource.storageLocation}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    if (resource.inventoryStatus.isNotEmpty)
                      Text(
                        'Status: ${resource.inventoryStatus}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceImage extends StatelessWidget {
  const _ResourceImage({required this.resource, this.size = 64});

  final ResourceItem resource;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = resource.imageUrl?.trim() ?? '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(resource.fallbackIcon, color: colors.onPrimaryContainer),
    );
    if (imageUrl.isEmpty) return fallback;
    late final Widget image;
    if (imageUrl.startsWith('data:image/')) {
      try {
        image = Image.memory(
          base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    } else if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      image = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

class _ResourceDetailsSheet extends StatelessWidget {
  const _ResourceDetailsSheet({required this.resource});

  final ResourceItem resource;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = resource.availableQuantity == 0
        ? 'Out of stock'
        : resource.inventoryStatus.isEmpty
        ? 'Available'
        : resource.inventoryStatus;
    final ratio = resource.totalQuantity == 0
        ? 0.0
        : resource.availableQuantity / resource.totalQuantity;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _ResourceImage(
                    resource: resource,
                    size: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                resource.itemName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resource.itemCode,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(label: resource.mainCategory),
                  _InfoPill(label: status),
                  if (resource.itemType.isNotEmpty)
                    _InfoPill(label: resource.itemType),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: 'Availability',
                value:
                    '${resource.availableQuantity}/${resource.totalQuantity} available',
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 9,
                  color: colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Maximum borrow limit',
                value: '${resource.maxBorrowLimit} item(s)',
              ),
              _DetailRow(
                label: 'Maximum borrow days',
                value: '${resource.maxBorrowDays} day(s)',
              ),
              if (resource.storageLocation.isNotEmpty)
                _DetailRow(
                  label: 'Storage location',
                  value: resource.storageLocation,
                ),
              if (resource.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resource.description,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

enum _ResourceSort { name, availability, quantity, status }
