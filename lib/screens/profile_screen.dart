import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/borrower_navigation_bar.dart';
import 'account_activities_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const _ProfileMessage('Please sign in to view your profile.')
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(AuthService.usersCollection)
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _ProfileMessage(
                    'Unable to load your profile right now.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data?.data();
                if (data == null) {
                  return const _ProfileMessage(
                    'Profile information not found.',
                  );
                }
                return _ProfileContent(
                  data: data,
                  authUser: user,
                  onEditProfile: () => _showEditProfile(context, user, data),
                );
              },
            ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 4),
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    User user,
    Map<String, dynamic> data,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditProfileDialog(
          uid: user.uid,
          data: data,
          userService: _userService,
        ),
      ),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.data,
    required this.authUser,
    required this.onEditProfile,
  });

  final Map<String, dynamic> data;
  final User authUser;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final firstName = _value(data['firstName']);
    final lastName = _value(data['lastName']);
    final fullName = [
      firstName,
      lastName,
    ].where((name) => name.isNotEmpty).join(' ');
    final displayName = fullName.isEmpty
        ? authUser.displayName ?? 'User'
        : fullName;
    final role = AuthService.roleFromString(_value(data['role']));
    final isStudent = role.toLowerCase() == 'student';
    final sectionOrDepartment = isStudent
        ? _firstValue(data, ['gradeSection', 'section'])
        : _firstValue(data, ['department', 'departmentOrSection']);
    final identifier = _firstValue(data, ['schoolId', 'idNumber']);
    final email = _firstValue(data, ['email']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: .12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _initials(displayName),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(role),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Edit Profile',
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _DetailTile(
                icon: Icons.lock_outline,
                title: 'School ID / LRN',
                value: identifier.isEmpty ? 'Not available' : identifier,
              ),
              const Divider(height: 1),
              _DetailTile(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: email.isEmpty
                    ? authUser.email ?? 'Not available'
                    : email,
              ),
              const Divider(height: 1),
              _DetailTile(
                icon: Icons.school_outlined,
                title: isStudent ? 'Section' : 'Department',
                value: sectionOrDepartment.isEmpty
                    ? 'Not available'
                    : sectionOrDepartment,
              ),
              const Divider(height: 1),
              _DetailTile(
                icon: Icons.phone_outlined,
                title: 'Contact Number',
                value: _firstValue(data, ['phoneNumber']).isEmpty
                    ? 'Not available'
                    : _firstValue(data, ['phoneNumber']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Account Activities'),
                subtitle: const Text('View borrowing and transaction history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountActivitiesScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Security'),
                subtitle: const Text('Password and account security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSecurityDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security'),
        content: const Text(
          'To change your password, use the password reset option associated with your account email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.onSecondaryContainer),
      ),
      title: Text(title),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.uid,
    required this.data,
    required this.userService,
  });

  final String uid;
  final Map<String, dynamic> data;
  final UserService userService;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _sectionController;
  late final TextEditingController _phoneController;
  late final bool _isStudent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: _value(widget.data['firstName']),
    );
    _lastNameController = TextEditingController(
      text: _value(widget.data['lastName']),
    );
    final role = AuthService.roleFromString(_value(widget.data['role']));
    _isStudent = role.toLowerCase() == 'student';
    _sectionController = TextEditingController(
      text: _isStudent
          ? _firstValue(widget.data, ['gradeSection', 'section'])
          : _firstValue(widget.data, ['department', 'departmentOrSection']),
    );
    _phoneController = TextEditingController(
      text: _value(widget.data['phoneNumber']),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sectionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.userService.updateUserProfile(widget.uid, {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        _isStudent ? 'gradeSection' : 'department': _sectionController.text,
        'phoneNumber': _phoneController.text,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your personal details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  decoration: decoration('First Name', Icons.person_outline),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameController,
                  decoration: decoration('Last Name', Icons.person_outline),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sectionController,
                  decoration: decoration(
                    _isStudent ? 'Section / Grade' : 'Department',
                    Icons.school_outlined,
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: decoration(
                    'Contact Number',
                    Icons.phone_outlined,
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    return RegExp(r'^[+]?[0-9 ()-]{7,20}$').hasMatch(phone)
                        ? null
                        : 'Enter a valid phone number';
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

String _value(dynamic value) => value?.toString().trim() ?? '';

String _firstValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = _value(data[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _initials(String name) {
  final values = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (values.isEmpty) return '?';
  if (values.length == 1) return values.first.substring(0, 1).toUpperCase();
  return '${values.first.substring(0, 1)}${values.last.substring(0, 1)}'
      .toUpperCase();
}
