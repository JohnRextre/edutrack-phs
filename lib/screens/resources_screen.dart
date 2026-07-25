import 'package:flutter/material.dart';

import '../widgets/borrower_navigation_bar.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final Map<String, bool> _pendingRequests = {};

  Future<void> _openBorrowRequest(_Resource resource) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _BorrowRequestScreen(resource: resource),
      ),
    );

    if (submitted == true && mounted) {
      setState(() => _pendingRequests[resource.code] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${resource.name} request submitted successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = [
      const _Resource(
        name: 'Biology Microscope',
        code: 'SCI-MIC-001',
        category: 'Science Lab - Grade 11',
        tags: ['Grade 11', 'Science Lab'],
        description:
            'Standard compound microscope with 10×-40× objective lenses. Essential for STEM biology activities.',
        assetPath: 'lib/assets/borrowed_assets/Biology Microscope.png',
        fallbackIcon: Icons.biotech_outlined,
      ),
      const _Resource(
        name: 'Laptop Dell Latitude',
        code: 'PHS-LPT-042',
        category: 'ICT - Device',
        tags: ['ICT', 'Device'],
        description:
            'Standard issue student laptop for ICT and programming classes. Includes required learning software.',
        assetPath: 'lib/assets/borrowed_assets/Dell Laptop.png',
        fallbackIcon: Icons.laptop_mac_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Resources')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SearchBar(
            hintText: 'Search resources',
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Grade 11'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(label: const Text('Science Lab'), onSelected: (_) {}),
              FilterChip(label: const Text('Computer Lab'), onSelected: (_) {}),
              FilterChip(label: const Text('Mathematics'), onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Available resources',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ResourceCard(
                resource: resource,
                pending: _pendingRequests[resource.code] ?? false,
                onBorrow: () => _openBorrowRequest(resource),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 1),
    );
  }
}

class _BorrowRequestScreen extends StatefulWidget {
  const _BorrowRequestScreen({required this.resource});

  final _Resource resource;

  @override
  State<_BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<_BorrowRequestScreen> {
  late DateTime _borrowDate;
  DateTime? _returnDate;
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _borrowDate = DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isReturnDate}) async {
    final current = isReturnDate ? (_returnDate ?? _borrowDate) : _borrowDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: _borrowDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        if (isReturnDate) {
          _returnDate = selected;
        } else {
          _borrowDate = selected;
          if (_returnDate != null && _returnDate!.isBefore(selected)) {
            _returnDate = null;
          }
        }
      });
    }
  }

  void _submit() {
    if (_returnDate == null || _purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide a return date and purpose of borrowing.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _dateLabel(DateTime? date) => date == null
      ? 'Select date'
      : MaterialLocalizations.of(context).formatMediumDate(date);

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResourceImage(resource: resource, height: 176),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Code: ${resource.code}')),
                            Chip(label: Text(resource.category)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(resource.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Request Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Borrow Date',
              value: _dateLabel(_borrowDate),
              onTap: () => _pickDate(isReturnDate: false),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Return Date / Due Date',
              value: _dateLabel(_returnDate),
              onTap: () => _pickDate(isReturnDate: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Purpose of Borrowing',
                hintText: 'e.g., Research for Science Fair / STEM Class',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send),
          label: const Text('Submit Borrow Request'),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.pending,
    required this.onBorrow,
  });
  final _Resource resource;
  final bool pending;
  final VoidCallback onBorrow;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: _ResourceImage(resource: resource, height: 190),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: resource.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                resource.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: pending ? null : onBorrow,
                  icon: Icon(
                    pending
                        ? Icons.pending_actions
                        : Icons.add_shopping_cart_outlined,
                  ),
                  label: Text(pending ? 'Pending Request' : 'Borrow'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResourceImage extends StatelessWidget {
  const _ResourceImage({required this.resource, required this.height});
  final _Resource resource;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    resource.assetPath,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => Container(
      height: height,
      color: Theme.of(context).colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        resource.fallbackIcon,
        size: 64,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(value),
    ),
  );
}

class _Resource {
  const _Resource({
    required this.name,
    required this.code,
    required this.category,
    required this.tags,
    required this.description,
    required this.assetPath,
    required this.fallbackIcon,
  });
  final String name;
  final String code;
  final String category;
  final List<String> tags;
  final String description;
  final String assetPath;
  final IconData fallbackIcon;
}
