import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/account_role.dart';
import '../../models/resource_item.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_service.dart';

class BorrowRequestScreen extends StatefulWidget {
  const BorrowRequestScreen({super.key, required this.resource});

  final ResourceModel resource;

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _borrowService = BorrowService();
  final _purposeController = TextEditingController();

  late DateTime _borrowDate;
  DateTime? _expectedReturnDate;
  int _requestedQuantity = 1;
  bool _isSubmitting = false;

  String? _userId;
  String? _userName;
  String? _userRole;
  bool _loadingUser = true;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  ResourceModel get resource => widget.resource;

  bool get _isTeacher => _userRole == 'teacher';

  int get _maxQuantity {
    final cap = resource.maxBorrowLimit;
    final available = resource.availableQuantity;
    return cap < available ? cap : available;
  }

  @override
  void initState() {
    super.initState();
    _borrowDate = DateUtils.dateOnly(DateTime.now());
    _loadBorrower();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrower() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingUser = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection(AuthService.usersCollection)
        .doc(user.uid)
        .get();
    final role = AuthService.accountRoleFromFirestoreValue(doc.data()?['role']);

    if (!mounted) return;
    setState(() {
      _loadingUser = false;
      if (role.isBorrower) {
        _userId = user.uid;
        _userName = (doc.data()?['fullName'] ?? 'Unknown User').toString();
        _userRole = role == AccountRole.teacher ? 'teacher' : 'student';
        if (!_isTeacher) {
          _requestedQuantity = 1;
        }
      }
    });
  }

  String _formatPickerDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    return '$weekday, ${_months[date.month - 1]} ${date.day}';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _maxReturnDate =>
      _dateOnly(_borrowDate).add(const Duration(days: 7));

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _pickBorrowDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _borrowDate.isBefore(today) ? today : _borrowDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Select borrow date',
    );
    if (selected == null || !mounted) return;

    setState(() {
      _borrowDate = _dateOnly(selected);
      if (_expectedReturnDate != null) {
        final returnDay = _dateOnly(_expectedReturnDate!);
        if (returnDay.isBefore(_borrowDate) ||
            returnDay.isAfter(_maxReturnDate)) {
          _expectedReturnDate = null;
        }
      }
    });
  }

  Future<void> _pickReturnDate() async {
    final borrowDay = _dateOnly(_borrowDate);
    final selected = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? borrowDay.add(const Duration(days: 7)),
      firstDate: borrowDay,
      lastDate: _maxReturnDate,
      helpText: 'Select return date',
    );
    if (selected == null || !mounted) return;

    setState(() => _expectedReturnDate = _dateOnly(selected));
  }

  String? _validateReturnDate(DateTime? value) {
    if (value == null) return 'Please select a return date.';
    final returnDay = _dateOnly(value);
    final borrowDay = _dateOnly(_borrowDate);
    if (returnDay.isBefore(borrowDay)) {
      return 'Return date cannot be before the borrow date.';
    }
    if (returnDay.isAfter(_maxReturnDate)) {
      return 'Maximum borrow duration is 1 week (7 days).';
    }
    return null;
  }

  void _incrementQuantity() {
    if (_requestedQuantity < _maxQuantity) {
      setState(() => _requestedQuantity++);
    }
  }

  void _decrementQuantity() {
    if (_requestedQuantity > 1) {
      setState(() => _requestedQuantity--);
    }
  }

  Future<void> _submit() async {
    if (_userId == null || _userName == null || _userRole == null) {
      _showSnackBar('Please sign in to submit a borrow request.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final returnDate = _expectedReturnDate;
    final returnError = _validateReturnDate(returnDate);
    if (returnError != null) {
      _showSnackBar(returnError, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _borrowService.requestBorrow(
        resourceId: resource.id,
        resourceName: resource.itemName,
        resourceCode: resource.itemCode,
        userId: _userId!,
        userName: _userName!,
        userRole: _userRole!,
        borrowDate: _borrowDate,
        expectedReturnDate: returnDate!,
        requestedQuantity: _requestedQuantity,
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
      );

      if (!mounted) return;
      _showSnackBar('Borrow request submitted successfully.');
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/my-requests');
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request')),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Please sign in as a student or teacher to request a borrow.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ResourceOverviewCard(resource: resource),
                          const SizedBox(height: 24),
                          Text(
                            'Request Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DateField(
                            label: 'Borrow Date',
                            value: _formatPickerDate(_borrowDate),
                            onTap: _pickBorrowDate,
                          ),
                          const SizedBox(height: 16),
                          _DateField(
                            label: 'Return / Due Date',
                            value: _expectedReturnDate == null
                                ? 'Select date'
                                : _formatPickerDate(_expectedReturnDate!),
                            onTap: _pickReturnDate,
                            errorText: _validateReturnDate(_expectedReturnDate),
                          ),
                          const SizedBox(height: 16),
                          _QuantityField(
                            isTeacher: _isTeacher,
                            quantity: _requestedQuantity,
                            maxQuantity: _maxQuantity,
                            maxBorrowLimit: resource.maxBorrowLimit,
                            onIncrement: _incrementQuantity,
                            onDecrement: _decrementQuantity,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _purposeController,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Purpose of Borrowing (Optional)',
                              hintText:
                                  'e.g., For Science Class experiment / Group project',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            _isSubmitting
                                ? 'Submitting...'
                                : 'Submit Borrow Request',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResourceOverviewCard extends StatelessWidget {
  const _ResourceOverviewCard({required this.resource});

  final ResourceModel resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResourceImage(resource: resource, height: 180),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.itemName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: 'Code: ${resource.itemCode}',
                      icon: Icons.qr_code_2_outlined,
                    ),
                    _InfoChip(
                      label: resource.mainCategory,
                      icon: Icons.category_outlined,
                    ),
                    _InfoChip(
                      label: resource.subCategory,
                      icon: Icons.folder_outlined,
                    ),
                    if (resource.itemType.isNotEmpty)
                      _InfoChip(
                        label: resource.itemType,
                        icon: Icons.place_outlined,
                      ),
                  ],
                ),
                if (resource.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    resource.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: resource.isAvailable
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        resource.isAvailable
                            ? Icons.inventory_2_outlined
                            : Icons.block_outlined,
                        size: 20,
                        color: resource.isAvailable
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Available: ${resource.availableQuantity} / Total: ${resource.totalQuantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: resource.isAvailable
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceImage extends StatelessWidget {
  const _ResourceImage({required this.resource, required this.height});

  final ResourceModel resource;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = resource.imageUrl?.trim() ?? '';

    Widget fallback() {
      return Container(
        height: height,
        color: colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          resource.fallbackIcon,
          size: 64,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }

    if (imageUrl.isEmpty) return fallback();

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            color: colorScheme.secondaryContainer,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, exception, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, exception, stackTrace) => fallback(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          errorText: errorText,
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _QuantityField extends StatelessWidget {
  const _QuantityField({
    required this.isTeacher,
    required this.quantity,
    required this.maxQuantity,
    required this.maxBorrowLimit,
    required this.onIncrement,
    required this.onDecrement,
  });

  final bool isTeacher;
  final int quantity;
  final int maxQuantity;
  final int maxBorrowLimit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Quantity',
        border: const OutlineInputBorder(),
        helperText: isTeacher
            ? 'Teachers may request up to $maxBorrowLimit per transaction'
            : 'Students are limited to 1 item per request',
      ),
      child: isTeacher
          ? Row(
              children: [
                IconButton.outlined(
                  onPressed: quantity > 1 ? onDecrement : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.outlined(
                  onPressed: quantity < maxQuantity ? onIncrement : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          : Text(
              '1',
              style: Theme.of(context).textTheme.titleLarge,
            ),
    );
  }
}
