import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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
      ('Dashboard', Icons.dashboard_rounded),
      ('User Management', Icons.people_alt_rounded),
      ('System Logs', Icons.security_rounded),
      ('Reports', Icons.bar_chart_rounded),
      ('My Account', Icons.person_rounded),
    ];
    return SidebarFrame(
      portalTitle: 'ICT Admin Portal',
      portalSubtitle: 'Administrator Dashboard',
      defaultRoleLabel: 'ICT Coordinator',
      portalIcon: Icons.admin_panel_settings_rounded,
      links: links,
      onNavigate: onNavigate,
      onSignOut: onSignOut,
    );
  }
}

class SidebarFrame extends StatelessWidget {
  const SidebarFrame({
    super.key,
    required this.portalTitle,
    required this.portalSubtitle,
    required this.defaultRoleLabel,
    required this.portalIcon,
    required this.links,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String portalTitle;
  final String portalSubtitle;
  final String defaultRoleLabel;
  final IconData portalIcon;
  final List<(String, IconData)> links;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authUser = FirebaseAuth.instance.currentUser;

    return Material(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. App Header Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer.withValues(alpha: 0.8),
                      colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, const Color(0xFF176B87)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(portalIcon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EduTrack PHS',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            portalTitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. User Profile Card with Live Firestore Stream
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: authUser == null
                    ? null
                    : FirebaseFirestore.instance
                          .collection(AuthService.usersCollection)
                          .doc(authUser.uid)
                          .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};
                  final rawPhoto =
                      data['photoUrl'] ?? data['photoURL'] ?? data['avatarUrl'];
                  final photoUrl =
                      (rawPhoto != null && rawPhoto.toString().isNotEmpty)
                      ? rawPhoto.toString()
                      : authUser?.photoURL;
                  final firstName = (data['firstName'] ?? '').toString().trim();
                  final lastName = (data['lastName'] ?? '').toString().trim();
                  final legacyName = (data['fullName'] ?? data['name'] ?? '')
                      .toString()
                      .trim();
                  final resolvedName = [
                    firstName,
                    lastName,
                  ].where((s) => s.isNotEmpty).join(' ');
                  final displayName = resolvedName.isNotEmpty
                      ? resolvedName
                      : (legacyName.isNotEmpty
                            ? legacyName
                            : (authUser?.displayName ?? 'User Profile'));
                  final email = (data['email'] ?? authUser?.email ?? '')
                      .toString();
                  final roleStr = (data['role'] ?? defaultRoleLabel).toString();

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onNavigate('My Account'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildSidebarAvatar(
                              photoUrl,
                              displayName,
                              colors,
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      roleStr,
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Navigation Header Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              // 3. Navigation List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: links.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        link.$2,
                        size: 22,
                        color: colors.onSurfaceVariant,
                      ),
                      title: Text(
                        link.$1,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.outlineVariant,
                      ),
                      onTap: () => onNavigate(link.$1),
                    );
                  },
                ),
              ),

              // 4. Footer Section (Sign Out & Info)
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: colors.errorContainer.withValues(alpha: 0.15),
                leading: Icon(
                  Icons.logout_rounded,
                  color: colors.error,
                  size: 20,
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                onTap: onSignOut,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'EduTrack PHS • v1.0.0',
                  style: TextStyle(
                    color: colors.outline,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSidebarAvatar(
    String? photoUrl,
    String displayName,
    ColorScheme colors, {
    double radius = 22,
  }) {
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      final url = photoUrl.trim();
      if (url.startsWith('data:image')) {
        try {
          final commaIndex = url.indexOf(',');
          final base64Part = commaIndex != -1
              ? url.substring(commaIndex + 1)
              : url;
          final bytes = base64Decode(base64Part);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _initialsAvatar(displayName, colors, radius),
            ),
          );
        } catch (_) {
          return _initialsAvatar(displayName, colors, radius);
        }
      } else if (url.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _initialsAvatar(displayName, colors, radius),
          ),
        );
      }
    }
    return _initialsAvatar(displayName, colors, radius);
  }

  static Widget _initialsAvatar(
    String displayName,
    ColorScheme colors,
    double radius,
  ) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      child: Text(
        _getInitials(displayName),
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.bold),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
