import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/resource_item.dart';
import '../../services/resource_service.dart';

class AddEditResourceScreen extends StatefulWidget {
  const AddEditResourceScreen({super.key, this.resource});

  final ResourceItem? resource;

  bool get isEdit => resource != null;

  @override
  State<AddEditResourceScreen> createState() => _AddEditResourceScreenState();
}

class _AddEditResourceScreenState extends State<AddEditResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resourceService = ResourceService();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _totalQtyController;
  late final TextEditingController _availableQtyController;
  late final TextEditingController _descriptionController;

  late String _mainCategory;
  late String _subCategory;
  late String _itemType;
  var _isSubmitting = false;
  var _syncAvailableWithTotal = true;

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    _nameController = TextEditingController(text: resource?.itemName ?? '');
    _codeController = TextEditingController(text: resource?.itemCode ?? '');
    _totalQtyController = TextEditingController(
      text: (resource?.totalQuantity ?? 1).toString(),
    );
    _availableQtyController = TextEditingController(
      text: (resource?.availableQuantity ?? 1).toString(),
    );
    _descriptionController = TextEditingController(
      text: resource?.description ?? '',
    );

    _mainCategory = resource?.mainCategory ??
        ResourceTaxonomy.mainCategoryGeneralLearning;
    final subOptions = ResourceTaxonomy.subCategoriesFor(_mainCategory);
    _subCategory = resource?.subCategory ??
        (subOptions.isNotEmpty ? subOptions.first : '');
    final typeOptions = ResourceTaxonomy.itemTypesForSubCategory(_subCategory);
    _itemType = resource?.itemType ??
        (typeOptions.isNotEmpty ? typeOptions.first : '');
    _syncAvailableWithTotal = !widget.isEdit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _totalQtyController.dispose();
    _availableQtyController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  void _onMainCategoryChanged(String? value) {
    if (value == null) return;
    final subOptions = ResourceTaxonomy.subCategoriesFor(value);
    final typeOptions = subOptions.isNotEmpty
        ? ResourceTaxonomy.itemTypesForSubCategory(subOptions.first)
        : <String>[];
    setState(() {
      _mainCategory = value;
      _subCategory = subOptions.isNotEmpty ? subOptions.first : '';
      _itemType = typeOptions.isNotEmpty ? typeOptions.first : '';
    });
  }

  void _onSubCategoryChanged(String? value) {
    if (value == null) return;
    final typeOptions = ResourceTaxonomy.itemTypesForSubCategory(value);
    setState(() {
      _subCategory = value;
      _itemType = typeOptions.isNotEmpty ? typeOptions.first : '';
    });
  }

  void _onTotalQuantityChanged(String value) {
    if (!_syncAvailableWithTotal) return;
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      _availableQtyController.text = parsed.toString();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final totalQty = int.parse(_totalQtyController.text.trim());
    final availableQty = int.parse(_availableQtyController.text.trim());

    setState(() => _isSubmitting = true);
    try {
      if (widget.isEdit) {
        await _resourceService.updateResource(
          id: widget.resource!.id,
          itemName: _nameController.text,
          itemCode: _codeController.text,
          mainCategory: _mainCategory,
          subCategory: _subCategory,
          itemType: _itemType,
          totalQuantity: totalQty,
          availableQuantity: availableQty,
          description: _descriptionController.text,
          imageUrl: widget.resource!.imageUrl,
        );
      } else {
        await _resourceService.createResource(
          itemName: _nameController.text,
          itemCode: _codeController.text,
          mainCategory: _mainCategory,
          subCategory: _subCategory,
          itemType: _itemType,
          totalQuantity: totalQty,
          availableQuantity: availableQty,
          description: _descriptionController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      _showSnackBar(ResourceService.friendlyErrorMessage(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subCategories = ResourceTaxonomy.subCategoriesFor(_mainCategory);
    final itemTypes = ResourceTaxonomy.itemTypesForSubCategory(_subCategory);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: Text(widget.isEdit ? 'Edit Resource' : 'Add New Resource'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _ImageAttachmentPlaceholder(colorScheme: colorScheme),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Item Code / Asset Tag *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item code is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _ResourceDropdownField<String>(
              label: 'Main Category *',
              value: _mainCategory,
              items: ResourceTaxonomy.mainCategories,
              enabled: !_isSubmitting,
              onChanged: _onMainCategoryChanged,
            ),
            const SizedBox(height: 16),
            _ResourceDropdownField<String>(
              label: 'Sub-Category *',
              value: subCategories.contains(_subCategory) ? _subCategory : null,
              items: subCategories,
              enabled: !_isSubmitting && subCategories.isNotEmpty,
              onChanged: _onSubCategoryChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sub-category is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _ResourceDropdownField<String>(
              label: 'Item Type *',
              value: itemTypes.contains(_itemType) ? _itemType : null,
              items: itemTypes,
              enabled: !_isSubmitting && itemTypes.isNotEmpty,
              onChanged: (value) {
                if (value != null) setState(() => _itemType = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Item type is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalQtyController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total Quantity *',
                border: OutlineInputBorder(),
              ),
              onChanged: _onTotalQuantityChanged,
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a valid total quantity (1 or more).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _availableQtyController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Available Quantity *',
                border: OutlineInputBorder(),
                helperText: 'Defaults to total quantity for new items',
              ),
              onChanged: (_) {
                if (_syncAvailableWithTotal) {
                  _syncAvailableWithTotal = false;
                }
              },
              validator: (value) {
                final available = int.tryParse(value?.trim() ?? '');
                final total = int.tryParse(_totalQtyController.text.trim());
                if (available == null || available < 0) {
                  return 'Enter a valid available quantity.';
                }
                if (total != null && available > total) {
                  return 'Available quantity cannot exceed total quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description / Specifications',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Resource'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageAttachmentPlaceholder extends StatelessWidget {
  const _ImageAttachmentPlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to attach image',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Image upload coming soon',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceDropdownField<T> extends StatelessWidget {
  const _ResourceDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
