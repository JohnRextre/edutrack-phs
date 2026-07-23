import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        child: const Icon(Icons.biotech_outlined),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Biology Microscope',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('SCI-MIC-001'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Text('Available now')),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Borrow'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
