import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/resource_item.dart';
import '../../services/qr_service.dart';
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
  late final TextEditingController _storageLocationController;
  late final TextEditingController _totalQtyController;
  late final TextEditingController _availableQtyController;
  late final TextEditingController _maxBorrowLimitController;
  late final TextEditingController _maxBorrowDaysController;
  late final TextEditingController _descriptionController;

  late String _mainCategory;
  late String _subCategory;
  late String _itemType;
  String? _imageUrl;
  var _isSubmitting = false;
  var _syncAvailableWithTotal = true;
  var _hasGeneratedQr = false;

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    _nameController = TextEditingController(text: resource?.itemName ?? '');
    _codeController = TextEditingController(text: resource?.itemCode ?? '');
    _storageLocationController = TextEditingController(
      text: resource?.storageLocation ?? '',
    );
    _totalQtyController = TextEditingController(
      text: (resource?.totalQuantity ?? 1).toString(),
    );
    _availableQtyController = TextEditingController(
      text: (resource?.availableQuantity ?? 1).toString(),
    );
    _maxBorrowLimitController = TextEditingController(
      text: (resource?.maxBorrowLimit ?? ResourceItem.defaultMaxBorrowLimit)
          .toString(),
    );
    _maxBorrowDaysController = TextEditingController(
      text: (resource?.maxBorrowDays ?? ResourceItem.defaultMaxBorrowDays)
          .toString(),
    );
    _descriptionController = TextEditingController(
      text: resource?.description ?? '',
    );

    _mainCategory =
        resource?.mainCategory ?? ResourceTaxonomy.mainCategoryGeneralLearning;
    final subOptions = ResourceTaxonomy.subCategoriesFor(_mainCategory);
    _subCategory =
        resource?.subCategory ??
        (subOptions.isNotEmpty ? subOptions.first : '');
    final typeOptions = ResourceTaxonomy.itemTypesForSubCategory(_subCategory);
    _itemType =
        resource?.itemType ?? (typeOptions.isNotEmpty ? typeOptions.first : '');
    _imageUrl = resource?.imageUrl;
    _syncAvailableWithTotal = !widget.isEdit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _storageLocationController.dispose();
    _totalQtyController.dispose();
    _availableQtyController.dispose();
    _maxBorrowLimitController.dispose();
    _maxBorrowDaysController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final ext = picked.name.toLowerCase();
      final mimeType = ext.endsWith('.png')
          ? 'image/png'
          : (ext.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      setState(() {
        _imageUrl = 'data:$mimeType;base64,$base64String';
      });
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _showPresetImagesDialog() {
    const presets = [
      (
        'Biology Microscope',
        'lib/assets/borrowed_assets/Biology Microscope.png',
        Icons.biotech,
      ),
      (
        'Scientific Calculator',
        'lib/assets/borrowed_assets/Calculator.png',
        Icons.calculate,
      ),
      (
        'Laptop / Tech Device',
        'lib/assets/borrowed_assets/Dell Laptop.png',
        Icons.laptop_chromebook,
      ),
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Sample Preset Asset'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: presets.map((preset) {
              return ListTile(
                leading: Image.asset(
                  preset.$2,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(preset.$3),
                ),
                title: Text(preset.$1),
                onTap: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _imageUrl = preset.$2;
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlCtrl = TextEditingController(
      text:
          (_imageUrl != null &&
              (_imageUrl!.startsWith('http://') ||
                  _imageUrl!.startsWith('https://')))
          ? _imageUrl
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            labelText: 'Image Web Address',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = urlCtrl.text.trim();
              Navigator.pop(dialogContext);
              if (text.isNotEmpty) {
                setState(() {
                  _imageUrl = text;
                });
              }
            },
            child: const Text('Set Image'),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Attach Resource Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery / Files'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Choose from Sample Presets'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPresetImagesDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Enter Image URL Link'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showUrlInputDialog();
                  },
                ),
                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                    ),
                    title: Text(
                      'Remove Image',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _imageUrl = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetQrGeneratedState() {
    if (_hasGeneratedQr) {
      setState(() => _hasGeneratedQr = false);
    }
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
      _hasGeneratedQr = false;
    });
  }

  void _onSubCategoryChanged(String? value) {
    if (value == null) return;
    final typeOptions = ResourceTaxonomy.itemTypesForSubCategory(value);
    setState(() {
      _subCategory = value;
      _itemType = typeOptions.isNotEmpty ? typeOptions.first : '';
      _hasGeneratedQr = false;
    });
  }

  void _onTotalQuantityChanged(String value) {
    if (!_syncAvailableWithTotal) return;
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      _availableQtyController.text = parsed.toString();
      final maxLimit = int.tryParse(_maxBorrowLimitController.text.trim());
      if (maxLimit == null || maxLimit > parsed) {
        _maxBorrowLimitController.text = parsed.toString();
      }
    }
  }

  Future<void> _generateQrCode() async {
    final itemCode = _codeController.text.trim();
    if (itemCode.isEmpty) {
      _showSnackBar('Please enter an Item Code first.', isError: true);
      return;
    }

    final qrPayload = QrService.buildResourcePayload(
      itemCode: itemCode,
      itemName: _nameController.text,
      mainCategory: _mainCategory,
      subCategory: _subCategory,
      storageLocation: _storageLocationController.text,
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

    setState(() => _hasGeneratedQr = true);

    final itemName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Unnamed Resource';

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
                itemName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Code: $itemCode',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final totalQty = int.parse(_totalQtyController.text.trim());
    final availableQty = int.parse(_availableQtyController.text.trim());
    final maxBorrowLimit = int.parse(_maxBorrowLimitController.text.trim());
    final maxBorrowDays =
        int.tryParse(_maxBorrowDaysController.text.trim()) ??
        ResourceItem.defaultMaxBorrowDays;
    final imageToSave = _imageUrl != null && _imageUrl!.trim().isNotEmpty
        ? _imageUrl!.trim()
        : null;

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
          maxBorrowLimit: maxBorrowLimit,
          maxBorrowDays: maxBorrowDays,
          storageLocation: _storageLocationController.text,
          description: _descriptionController.text,
          imageUrl: imageToSave,
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
          maxBorrowLimit: maxBorrowLimit,
          maxBorrowDays: maxBorrowDays,
          storageLocation: _storageLocationController.text,
          description: _descriptionController.text,
          imageUrl: imageToSave,
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
    final subCategories = ResourceTaxonomy.subCategoriesFor(_mainCategory);
    final itemTypes = ResourceTaxonomy.itemTypesForSubCategory(_subCategory);
    final canGenerateQr =
        _codeController.text.trim().isNotEmpty &&
        !_isSubmitting &&
        !_hasGeneratedQr;

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
            _ImageAttachmentField(
              imageUrl: _imageUrl,
              fallbackIcon: ResourceTaxonomy.iconForMainCategory(_mainCategory),
              onTap: _isSubmitting ? () {} : _showImageSourcePicker,
              onRemove: _isSubmitting
                  ? () {}
                  : () => setState(() => _imageUrl = null),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                _resetQrGeneratedState();
                setState(() {});
              },
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
              onChanged: (_) {
                _resetQrGeneratedState();
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item code is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: canGenerateQr ? _generateQrCode : null,
                icon: Icon(
                  _hasGeneratedQr
                      ? Icons.check_circle_outline
                      : Icons.qr_code_2_outlined,
                ),
                label: Text(
                  _hasGeneratedQr ? 'QR Code Generated' : 'Generate QR Code',
                ),
              ),
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
              controller: _storageLocationController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Storage Location / Room',
                hintText: 'e.g., Room 123, Science Lab Cabinet A, ICT Hub',
                helperText: 'Physical room or location where item is stored',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
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
              controller: _maxBorrowLimitController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Max Borrow Limit (for Teachers) *',
                border: OutlineInputBorder(),
                helperText:
                    'Maximum quantity a teacher can request per transaction',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                final total = int.tryParse(_totalQtyController.text.trim());
                if (parsed == null || parsed < 1) {
                  return 'Enter a valid max borrow limit (1 or more).';
                }
                if (total != null && parsed > total) {
                  return 'Max borrow limit cannot exceed total quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxBorrowDaysController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Max Borrow Duration (Days) *',
                hintText: 'Default: 7 (1 week)',
                helperText:
                    'Maximum number of days a borrower can keep this item',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a valid duration (at least 1 day).';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('1 Day'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _maxBorrowDaysController.text = '1');
                        },
                ),
                ActionChip(
                  label: const Text('3 Days'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _maxBorrowDaysController.text = '3');
                        },
                ),
                ActionChip(
                  label: const Text('7 Days (1 Week)'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _maxBorrowDaysController.text = '7');
                        },
                ),
                ActionChip(
                  label: const Text('14 Days (2 Weeks)'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _maxBorrowDaysController.text = '14');
                        },
                ),
                ActionChip(
                  label: const Text('30 Days (1 Month)'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _maxBorrowDaysController.text = '30');
                        },
                ),
              ],
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

class _ImageAttachmentField extends StatelessWidget {
  const _ImageAttachmentField({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
    required this.onRemove,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  Widget _buildImageWidget(BuildContext context, String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, _, _) => _buildFallback(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    }
  }

  Widget _buildFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 180,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(fallbackIcon, size: 54, color: colorScheme.outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWidget(context, imageUrl!),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Change Image',
                      onPressed: onTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      tooltip: 'Remove Image',
                      onPressed: onRemove,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Image Attached',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Attach or Upload Item Image',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Camera, Gallery, URL, or Presets',
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
    final validValue = items.contains(value) ? value : null;
    return DropdownButtonFormField<T>(
      key: ValueKey(validValue),
      isExpanded: true,
      initialValue: validValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
