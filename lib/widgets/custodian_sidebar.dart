import 'package:flutter/material.dart';

import 'admin_sidebar.dart';

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
      ('Dashboard', Icons.dashboard_rounded),
      ('Learning Resources', Icons.menu_book_rounded),
      ('Borrowed Inventory', Icons.inventory_2_rounded),
      ('Return Verification', Icons.assignment_turned_in_rounded),
      ('Reports', Icons.bar_chart_rounded),
      ('My Account', Icons.person_rounded),
    ];
    return SidebarFrame(
      portalTitle: 'Custodian Portal',
      portalSubtitle: 'Property & Inventory Management',
      defaultRoleLabel: 'Property Custodian',
      portalIcon: Icons.inventory_2_rounded,
      links: links,
      onNavigate: onNavigate,
      onSignOut: onSignOut,
    );
  }
}
