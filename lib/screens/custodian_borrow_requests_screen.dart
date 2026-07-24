import 'package:flutter/material.dart';

class CustodianBorrowRequestsScreen extends StatelessWidget {
  const CustodianBorrowRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Borrow Requests')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          title: Text('Juan Dela Cruz'),
          subtitle: Text('Advanced Physics Vol 2 - Pending'),
          trailing: Text('Approve'),
        ),
        ListTile(
          title: Text('Maria Reyes'),
          subtitle: Text('Microscope Set A - Pending'),
          trailing: Text('Approve'),
        ),
      ],
    ),
  );
}
