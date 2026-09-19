import 'package:flutter/material.dart';

class BorrowerNavigationBar extends StatelessWidget {
  const BorrowerNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    '/dashboard',
    '/resources',
    '/my-borrowings',
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
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'My Borrowings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
