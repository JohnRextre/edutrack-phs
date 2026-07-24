import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
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
      ('User Management', Icons.people_outline),
      ('System Logs', Icons.security_outlined),
      ('Reports', Icons.bar_chart_outlined),
    ];
    return ColoredBox(
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
                  const Expanded(
                    child: Text(
                      'EduTrack PHS\nICT Admin Portal',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
