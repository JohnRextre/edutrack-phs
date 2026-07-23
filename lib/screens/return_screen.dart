import 'package:flutter/material.dart';

class ReturnScreen extends StatelessWidget {
  const ReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Return Item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Return verification',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Add photos so the resource team can confirm its condition.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.tertiaryContainer,
                        child: const Icon(Icons.laptop_mac_outlined),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Laptop Dell Latitude',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('PHS-LPT-042'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pending Verification',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 38,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload return verification photos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take or select clear photos of the item',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Choose photos'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
