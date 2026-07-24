import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('User Management')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('John Rexter'),
          subtitle: Text('Student - Active'),
        ),
        ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Maria Santos'),
          subtitle: Text('Teacher - Active'),
        ),
      ],
    ),
  );
}
