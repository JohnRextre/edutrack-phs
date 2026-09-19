import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable attachment field allowing borrowers/users to capture, upload,
/// choose from sample presets, or link an image URL for return & appeal proofs.
class ProofImageAttachmentField extends StatelessWidget {
  const ProofImageAttachmentField({
    super.key,
    required this.imageUrl,
    required this.onImageChanged,
    this.title = 'Attach Proof Photo / Receipt',
    this.subtitle =
        'Tap to take a photo, upload from gallery, or choose a preset',
    this.showPresets = true,
  });

  final String? imageUrl;
  final ValueChanged<String?> onImageChanged;
  final String title;
  final String subtitle;
  final bool showPresets;

  static const List<(String label, String path, IconData icon)> _presets = [
    (
      'Good Condition Item',
      'lib/assets/borrowed_assets/Biology Microscope.png',
      Icons.check_circle_outline,
    ),
    (
      'Calculator Unit Proof',
      'lib/assets/borrowed_assets/Calculator.png',
      Icons.calculate_outlined,
    ),
    (
      'Device / Tech Item Proof',
      'lib/assets/borrowed_assets/Dell Laptop.png',
      Icons.laptop_chromebook,
    ),
  ];

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final ext = picked.name.toLowerCase();
      final mimeType = ext.endsWith('.png')
          ? 'image/png'
          : (ext.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      onImageChanged('data:$mimeType;base64,$base64String');
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Failed to pick image: $e', isError: true);
      }
    }
  }

  void _showPresetsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Sample Proof Asset'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _presets.map((preset) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    preset.$2,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(preset.$3),
                  ),
                ),
                title: Text(preset.$1),
                onTap: () {
                  Navigator.pop(dialogContext);
                  onImageChanged(preset.$2);
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

  void _showUrlDialog(BuildContext context) {
    final controller = TextEditingController(
      text:
          (imageUrl != null &&
              (imageUrl!.startsWith('http://') ||
                  imageUrl!.startsWith('https://')))
          ? imageUrl
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            labelText: 'Image Web Address',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext);
              if (text.isNotEmpty) {
                onImageChanged(text);
              }
            },
            child: const Text('Set Image'),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context) {
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
                  'Attach Proof of Return / Receipt',
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
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery / Files'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
                if (showPresets)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Choose from Sample Presets'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showPresetsDialog(context);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Enter Image URL Link'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showUrlDialog(context);
                  },
                ),
                if (imageUrl != null && imageUrl!.isNotEmpty)
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
                      onImageChanged(null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullscreenPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: const Text('Proof Image Preview'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              automaticallyImplyLeading: false,
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: _buildImage(context, url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    String url, {
    BoxFit fit = BoxFit.cover,
  }) {
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = (commaIdx != -1)
            ? trimmed.substring(commaIdx + 1)
            : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, _, _) => _buildErrorWidget(context),
        );
      } catch (_) {
        return _buildErrorWidget(context);
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: fit,
        errorBuilder: (_, _, _) => _buildErrorWidget(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    return Image.asset(
      trimmed,
      fit: fit,
      errorBuilder: (_, _, _) => _buildErrorWidget(context),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 6),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          color: colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _showFullscreenPreview(context, imageUrl!),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _buildImage(context, imageUrl!),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tap to Zoom',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Proof Attached',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Image ready for submission',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showImageSourcePicker(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onImageChanged(null),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                    tooltip: 'Remove Image',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showImageSourcePicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.primaryContainer.withValues(alpha: 0.15),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact or card preview for proof images in read-only / details screens.
class ProofImageDisplayCard extends StatelessWidget {
  const ProofImageDisplayCard({
    super.key,
    required this.imageUrl,
    this.title = 'Proof of Return',
    this.emptyMessage = 'No proof photo was attached for this return.',
  });

  final String? imageUrl;
  final String title;
  final String emptyMessage;

  void _showFullscreenPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              automaticallyImplyLeading: false,
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: _buildImage(context, url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    String url, {
    BoxFit fit = BoxFit.cover,
  }) {
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = (commaIdx != -1)
            ? trimmed.substring(commaIdx + 1)
            : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, _, _) => _buildErrorWidget(context),
        );
      } catch (_) {
        return _buildErrorWidget(context);
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: fit,
        errorBuilder: (_, _, _) => _buildErrorWidget(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    return Image.asset(
      trimmed,
      fit: fit,
      errorBuilder: (_, _, _) => _buildErrorWidget(context),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 6),
          Text(
            'Failed to load proof image',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmed = imageUrl?.trim() ?? '';

    if (trimmed.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 36,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _showFullscreenPreview(context, trimmed),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _buildImage(context, trimmed),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Tap to View Full Size',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
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
