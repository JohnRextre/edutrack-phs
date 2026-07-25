import 'package:flutter/material.dart';

import 'my_borrowings_screen.dart';

class BorrowerReturnScreen extends StatefulWidget {
  const BorrowerReturnScreen({super.key, required this.item});
  final BorrowedItem item;

  @override
  State<BorrowerReturnScreen> createState() => _BorrowerReturnScreenState();
}

class _BorrowerReturnScreenState extends State<BorrowerReturnScreen> {
  final _remarksController = TextEditingController();
  bool _photoAttached = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of the item first.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Return request submitted for verification.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Return Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            item.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _ItemHeaderCard(item: item),
          const SizedBox(height: 20),
          const _ReturnTimeline(),
          const SizedBox(height: 20),
          _InitiateReturnCard(
            remarksController: _remarksController,
            photoAttached: _photoAttached,
            onPhotoTap: () => setState(() => _photoAttached = true),
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _ItemHeaderCard extends StatelessWidget {
  const _ItemHeaderCard({required this.item});
  final BorrowedItem item;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 176,
              width: double.infinity,
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    item.fallbackIcon,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Chip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text('ID: ${item.assetTag}'),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.location),
                  ],
                ),
              ),
              DueStatus(status: item.dueStatus),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReturnTimeline extends StatelessWidget {
  const _ReturnTimeline();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Return Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Divider(height: 24),
          _TimelineStep(
            icon: Icons.check_circle,
            color: Color(0xFF0B65B9),
            title: 'Borrowed',
            detail: 'Oct 12, 2023 - 08:30 AM',
            showLine: true,
          ),
          _TimelineStep(
            icon: Icons.radio_button_checked,
            color: Color(0xFF0B65B9),
            title: 'Pending Verification',
            detail: 'Submit return details below',
            showLine: true,
          ),
          _TimelineStep(
            icon: Icons.check_circle_outline,
            color: Color(0xFFB6B7BC),
            title: 'Return Approved',
            detail: 'Awaiting admin review',
            showLine: false,
          ),
        ],
      ),
    ),
  );
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.showLine,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool showLine;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Icon(icon, color: color),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: .35),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: color == const Color(0xFFB6B7BC)
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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

class _InitiateReturnCard extends StatelessWidget {
  const _InitiateReturnCard({
    required this.remarksController,
    required this.photoAttached,
    required this.onPhotoTap,
    required this.onCancel,
    required this.onSubmit,
  });
  final TextEditingController remarksController;
  final bool photoAttached;
  final VoidCallback onPhotoTap;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Initiate Return',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide a photo of the item to verify its condition before returning it to the IT office.',
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onPhotoTap,
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      child: Icon(
                        photoAttached
                            ? Icons.check
                            : Icons.add_a_photo_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      photoAttached ? 'Photo Attached' : 'Upload Photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tap to capture or select from gallery'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: remarksController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Remarks / Condition Notes (Optional)',
              hintText: 'e.g., Working perfectly, minor scratch on lid...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 36),
          Row(
            children: [
              OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Return Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(12);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final path = Path()..addRRect(rect);
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (double distance = 0; distance < metric.length; distance += 8) {
      canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
