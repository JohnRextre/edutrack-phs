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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance
                .collection(AuthService.usersCollection)
                .doc(user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage('Please sign in to view your profile.'),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage(
              'Unable to load your profile right now.',
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const _ProfileMessage('Profile information not found.'),
          );
        }

        final role = AuthService.roleFromString(_value(data['role']));
        final isBorrower =
            role.toLowerCase() == 'student' || role.toLowerCase() == 'teacher';

        return Scaffold(
          appBar: AppBar(title: Text(isBorrower ? 'Profile' : 'My Account')),
          body: _ProfileContent(
            data: data,
            authUser: user,
            onEditProfile: () => _showEditProfile(context, user, data),
          ),
          bottomNavigationBar: isBorrower
              ? const BorrowerNavigationBar(selectedIndex: 3)
              : null,
        );
      },
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
    final colors = Theme.of(context).colorScheme;
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
    final isAdmin =
        role.toLowerCase() == 'ict coordinator' ||
        role.toLowerCase() == 'admin';
    final isBorrower =
        role.toLowerCase() == 'student' || role.toLowerCase() == 'teacher';
    final sectionOrDepartment = isStudent
        ? _firstValue(data, ['gradeSection', 'section'])
        : _firstValue(data, ['department', 'departmentOrSection']);
    final identifier = _firstValue(data, ['schoolId', 'idNumber']);
    final email = _firstValue(data, ['email']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // User Banner
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.surfaceContainerHighest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .12),
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
                  backgroundColor: colors.primary,
                  child: Text(
                    _initials(displayName),
                    style: TextStyle(
                      color: colors.onPrimary,
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

        // Personal Details Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _DetailTile(
                icon: Icons.badge_outlined,
                title: isStudent
                    ? 'School ID / LRN'
                    : 'Employee ID / School ID',
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
              if (isStudent || sectionOrDepartment.isNotEmpty) ...[
                const Divider(height: 1),
                _DetailTile(
                  icon: Icons.school_outlined,
                  title: isStudent ? 'Section' : 'Department',
                  value: sectionOrDepartment.isEmpty
                      ? 'Not available'
                      : sectionOrDepartment,
                ),
              ],
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

        // Account Options Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (isBorrower) ...[
                ListTile(
                  leading: Icon(Icons.history, color: colors.primary),
                  title: const Text('Account Activities'),
                  subtitle: const Text(
                    'View borrowing and transaction history',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountActivitiesScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: Icon(Icons.lock_outline, color: colors.primary),
                title: const Text('Password & Security'),
                subtitle: const Text(
                  'Change password and manage account protection',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPasswordSecuritySheet(context),
              ),
            ],
          ),
        ),

        // Delete Account Section (Admin role excluded)
        if (!isAdmin) ...[
          const SizedBox(height: 16),
          _DeleteAccountCard(onDelete: () => _showDeleteAccountDialog(context)),
        ],
        const SizedBox(height: 24),

        // Log out button
        FilledButton.tonalIcon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showPasswordSecuritySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PasswordSecurityModal(authUser: authUser),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteAccountDialog(authUser: authUser, uid: authUser.uid),
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

/// Password & Security Bottom Sheet using system theme colors.
class _PasswordSecurityModal extends StatefulWidget {
  const _PasswordSecurityModal({required this.authUser});

  final User authUser;

  @override
  State<_PasswordSecurityModal> createState() => _PasswordSecurityModalState();
}

class _PasswordSecurityModalState extends State<_PasswordSecurityModal> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChanging = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  ({String label, double fraction, Color color}) _calculateStrength(
    String password,
    ColorScheme colors,
  ) {
    if (password.isEmpty) {
      return (
        label: 'Enter a password',
        fraction: 0.0,
        color: colors.onSurfaceVariant,
      );
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(
      r'[!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

    int criteria = 0;
    if (hasUppercase) criteria++;
    if (hasLowercase) criteria++;
    if (hasDigits) criteria++;
    if (hasSpecialCharacters) criteria++;

    if (password.length < 8 || criteria <= 2) {
      return (label: 'Weak', fraction: 0.33, color: colors.error);
    } else if (criteria == 3) {
      return (
        label: 'Medium',
        fraction: 0.66,
        color: Colors.amber[800] ?? Colors.orange,
      );
    } else {
      return (
        label: 'Strong',
        fraction: 1.0,
        color: Colors.green[700] ?? Colors.green,
      );
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password.')),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password.')),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 8 characters long.'),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password do not match.'),
        ),
      );
      return;
    }

    if (newPassword == currentPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password must be different from your current password.',
          ),
        ),
      );
      return;
    }

    setState(() => _isChanging = true);

    try {
      final email = widget.authUser.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'No email found for this user account.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await widget.authUser.reauthenticateWithCredential(credential);
      await widget.authUser.updatePassword(newPassword);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  InputDecoration _fieldDecoration(
    String hintText,
    bool isObscured,
    VoidCallback onToggle,
    ColorScheme colors,
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isObscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: colors.onSurfaceVariant,
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strength = _calculateStrength(_newPasswordController.text, colors);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACCOUNT PROTECTION',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Password & Security',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your password regularly to keep your account protected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Current Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: _fieldDecoration(
                  'Enter current password',
                  _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent),
                  colors,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'New Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() {}),
                decoration: _fieldDecoration(
                  'Enter new password',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                  colors,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password strength',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    strength.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: strength.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength.fraction,
                  minHeight: 5,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use at least 8 characters with uppercase, lowercase, number, and symbol.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _fieldDecoration(
                  'Confirm new password',
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                  colors,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _isChanging ? null : _handleChangePassword,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isChanging
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delete Account Card in the profile view using system theme colors.
class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
      ),
      color: colors.errorContainer.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERMANENT ACTION',
              style: TextStyle(
                color: colors.error,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Are you sure you want to delete this account? This action is irreversible.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete Account Confirmation Modal Dialog that handles keyboard insets cleanly without overflowing.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.authUser, required this.uid});

  final User authUser;
  final String uid;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      // 1. Delete Firestore user record
      await FirebaseFirestore.instance
          .collection(AuthService.usersCollection)
          .doc(widget.uid)
          .delete();

      // 2. Delete Firebase Auth account
      try {
        await widget.authUser.delete();
      } catch (_) {
        // If re-authentication is required, auth deletion might fail, but document is removed and user is signed out
      }

      // 3. Sign out and redirect
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canConfirm = _confirmController.text.trim() == 'Delete';

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERMANENT ACTION',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Delete Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you sure you want to delete this account? This action is irreversible.',
              style: TextStyle(fontSize: 13.5, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirmation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Type 'Delete' to confirm",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: colors.outlineVariant),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: canConfirm && !_isDeleting ? _handleDelete : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: _isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onError,
                          ),
                        )
                      : const Text(
                          'Delete Account',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    disabledBackgroundColor: colors.error.withValues(
                      alpha: 0.38,
                    ),
                    disabledForegroundColor: colors.onError.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  validator: _isStudent ? _required : null,
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
