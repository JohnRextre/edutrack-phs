import 'package:flutter/material.dart';

class CustodianReportsScreen extends StatelessWidget {
  const CustodianReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _ReportCard(
          'Inventory',
          'Complete list of learning resources and stock levels',
        ),
        _ReportCard('Borrowing', 'Active loans and historical borrowing data'),
        _ReportCard(
          'Overdue Items',
          'Resources past their due date and penalties',
        ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(this.title, this.description);
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Excel'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
