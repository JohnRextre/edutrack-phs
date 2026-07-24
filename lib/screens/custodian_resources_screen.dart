import 'package:flutter/material.dart';

class CustodianResourcesScreen extends StatelessWidget {
  const CustodianResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Learning Resources'),
      actions: [
        IconButton(
          tooltip: 'Add Learning Resource',
          onPressed: () {},
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _ResourceRow(title: 'Biology Microscope', code: 'SCI-MIC-001'),
        _ResourceRow(title: 'Laptop Dell Latitude', code: 'PHS-LPT-042'),
        _ResourceRow(title: 'Science Textbook Vol 2', code: 'SCI-TXT-002'),
      ],
    ),
  );
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.title, required this.code});
  final String title;
  final String code;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(title),
      subtitle: Text(code),
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            tooltip: 'Edit resource',
            onPressed: () {},
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete resource',
            onPressed: () {},
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    ),
  );
}
