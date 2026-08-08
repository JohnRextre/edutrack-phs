import 'package:flutter/material.dart';

class CustodianSidebar extends StatelessWidget {
  const CustodianSidebar({
    super.key,
    required this.onNavigate,
    required this.onSignOut,
  });

  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    const links = [
      ('Dashboard', Icons.dashboard_outlined),
      ('Learning Resources', Icons.menu_book_outlined),
      ('Borrow Requests', Icons.pending_actions_outlined),
      ('Return Verification', Icons.assignment_turned_in_outlined),
      ('Reports', Icons.bar_chart_outlined),
    ];
    return _SidebarFrame(
      title: 'Custodian Portal',
      links: links,
      onNavigate: onNavigate,
      onSignOut: onSignOut,
    );
  }
}

class _SidebarFrame extends StatelessWidget {
  const _SidebarFrame({
    required this.title,
    required this.links,
    required this.onNavigate,
    required this.onSignOut,
  });
  final String title;
  final List<(String, IconData)> links;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Text('ET'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'EduTrack PHS\n$title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: links
                    .map(
                      (link) => ListTile(
                        leading: Icon(link.$2),
                        title: Text(link.$1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => onNavigate(link.$1),
                      ),
                    )
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    ),
  );
}
