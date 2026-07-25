import 'package:flutter/material.dart';

class BorrowerNavigationBar extends StatelessWidget {
  const BorrowerNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    '/dashboard',
    '/resources',
    '/my-borrowings',
    '/my-requests',
    '/activity',
    '/profile',
  ];

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      _routes[index],
      (route) => false,
      arguments: index == 0 ? 'student' : null,
    );
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) => _navigate(context, index),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.search),
        label: 'Resources',
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_outline),
        selectedIcon: Icon(Icons.bookmark),
        label: 'My Borrowings',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'My Requests',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Activity',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  );
}
