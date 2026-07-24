import 'package:flutter/material.dart';

class AdminSystemLogsScreen extends StatelessWidget {
  const AdminSystemLogsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('System Logs')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.login),
          title: Text('John Rexter logged in'),
          subtitle: Text('10 minutes ago'),
        ),
        ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Resource record updated'),
          subtitle: Text('Today, 09:45 AM'),
        ),
      ],
    ),
  );
}
