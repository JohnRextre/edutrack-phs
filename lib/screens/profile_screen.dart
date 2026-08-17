import 'package:flutter/material.dart';

import '../widgets/borrower_navigation_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 46)),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'John Rexter',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        const Center(child: Text('Student Account · Grade 11')),
        const SizedBox(height: 24),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('john@phs.edu'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.badge_outlined),
                title: Text('PHS Student ID'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Account Activities'),
                subtitle: const Text('View borrowing and transaction history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/activity'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/', (route) => false),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    ),
    bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 4),
  );
}
