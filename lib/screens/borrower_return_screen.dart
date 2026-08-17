import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';

/// Optional borrower flow to submit return details before custodian verification.
class BorrowerReturnScreen extends StatefulWidget {
  const BorrowerReturnScreen({super.key, required this.transaction});

  final BorrowTransaction transaction;

  @override
  State<BorrowerReturnScreen> createState() => _BorrowerReturnScreenState();
}

class _BorrowerReturnScreenState extends State<BorrowerReturnScreen> {
  final _remarksController = TextEditingController();
  final _borrowService = BorrowService();
  bool _photoAttached = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of the item first.'),
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await _borrowService.submitReturnRequest(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted for verification.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BorrowService.friendlyErrorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Return Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            transaction.resourceName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _ItemHeaderCard(transaction: transaction),
          const SizedBox(height: 20),
          _ReturnTimeline(borrowDate: transaction.borrowDate),
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
  const _ItemHeaderCard({required this.transaction});

  final BorrowTransaction transaction;

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
              child: ColoredBox(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Chip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text('Code: ${transaction.resourceCode}'),
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
                      transaction.resourceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${formatBorrowDate(transaction.expectedReturnDate)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      borrowDueLabel(transaction),
                      style: TextStyle(
                        color:
                            transaction.effectiveStatus ==
                                BorrowTransactionStatus.overdue
                            ? Colors.red.shade700
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              BorrowStatusBadge(transaction: transaction),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReturnTimeline extends StatelessWidget {
  const _ReturnTimeline({required this.borrowDate});

  final DateTime borrowDate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Return Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _TimelineStep(
            icon: Icons.check_circle,
            color: const Color(0xFF0B65B9),
            title: 'Borrowed',
            detail: formatBorrowDate(borrowDate),
            showLine: true,
          ),
          const _TimelineStep(
            icon: Icons.radio_button_checked,
            color: Color(0xFF0B65B9),
            title: 'Pending Verification',
            detail: 'Submit return details below',
            showLine: true,
          ),
          const _TimelineStep(
            icon: Icons.check_circle_outline,
            color: Color(0xFFB6B7BC),
            title: 'Return Approved',
            detail: 'Awaiting custodian review',
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
            'Please provide a photo of the item to verify its condition before returning it to the property custodian.',
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
