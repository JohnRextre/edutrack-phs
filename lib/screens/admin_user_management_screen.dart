import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'admin/add_user_screen.dart';

enum UserRole {
  student('Student', Icons.school_outlined),
  teacher('Teacher', Icons.person_outlined),
  custodian('Property Custodian', Icons.verified_user_outlined),
  ictCoordinator('ICT Coordinator', Icons.admin_panel_settings_outlined);

  const UserRole(this.label, this.icon);
  final String label;
  final IconData icon;

  AccountRole get accountRole {
    switch (this) {
      case UserRole.student:
        return AccountRole.student;
      case UserRole.teacher:
        return AccountRole.teacher;
      case UserRole.custodian:
        return AccountRole.propertyCustodian;
      case UserRole.ictCoordinator:
        return AccountRole.ictCoordinator;
    }
  }

  static UserRole fromLabel(String? value) {
    final role = AuthService.roleFromString(value);
    switch (role) {
      case 'Teacher':
        return UserRole.teacher;
      case 'Property Custodian':
        return UserRole.custodian;
      case 'ICT Coordinator':
        return UserRole.ictCoordinator;
      case 'Student':
      default:
        return UserRole.student;
    }
  }
}

enum AccountStatus {
  active('Active', Colors.green),
  inactive('Inactive', Colors.grey),
  suspended('Suspended', Colors.red);

  const AccountStatus(this.label, this.color);
  final String label;
  final Color color;

  static AccountStatus fromLabel(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'inactive':
        return AccountStatus.inactive;
      case 'suspended':
        return AccountStatus.suspended;
      case 'active':
      default:
        return AccountStatus.active;
    }
  }
}

class UserAccount {
  const UserAccount({
    required this.uid,
    required this.schoolId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.department,
    this.statusReason,
    this.avatarColor,
  });

  final String uid;
  final String schoolId;
  final String fullName;
  final String email;
  final UserRole role;
  final AccountStatus status;
  final String department;
  final String? statusReason;
  final Color? avatarColor;

  /// Prefer school ID in list search; fall back to uid.
  String get displayId => schoolId.isNotEmpty ? schoolId : uid;

  factory UserAccount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final fullName = (data['fullName'] ?? data['name'] ?? '').toString();
    final schoolId = (data['schoolId'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final department =
        (data['departmentOrSection'] ??
                data['department'] ??
                data['section'] ??
                '')
            .toString();
    final uid = (data['uid'] ?? doc.id).toString();
    final statusReason = data['statusReason']?.toString();

    return UserAccount(
      uid: uid,
      schoolId: schoolId,
      fullName: fullName.isEmpty ? 'Unnamed User' : fullName,
      email: email,
      role: UserRole.fromLabel(data['role']?.toString()),
      status: AccountStatus.fromLabel(data['status']?.toString()),
      department: department.isEmpty ? '—' : department,
      statusReason: statusReason,
      avatarColor: _avatarColorFor(uid.isNotEmpty ? uid : fullName),
    );
  }
}

Color _avatarColorFor(String seed) {
  const palette = <Color>[
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
  ];
  if (seed.isEmpty) return palette.first;
  return palette[seed.hashCode.abs() % palette.length];
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length >= 2) {
    final first = parts[0][0];
    final second = parts[1][0];
    return '$first$second'.toUpperCase();
  }
  final single = parts[0];
  return single.substring(0, math.min(2, single.length)).toUpperCase();
}

bool _isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}

/// Roles that can be assigned from User Management (ICT Coordinator excluded).
const _assignableRoles = <UserRole>[
  UserRole.student,
  UserRole.teacher,
  UserRole.custodian,
];

bool _isIctCoordinator(UserAccount user) =>
    user.role == UserRole.ictCoordinator;

Widget _adminProtectionBanner(BuildContext context, {required String message}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.amber.shade200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
          ),
        ),
      ],
    ),
  );
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();

  UserRole? _selectedRoleFilter;
  AccountStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserAccount> _filterUsers(List<UserAccount> users) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    return users.where((user) {
      if (searchQuery.isNotEmpty) {
        final matchesSearch =
            user.fullName.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.schoolId.toLowerCase().contains(searchQuery) ||
            user.uid.toLowerCase().contains(searchQuery);
        if (!matchesSearch) return false;
      }

      if (_selectedRoleFilter != null && user.role != _selectedRoleFilter) {
        return false;
      }

      if (_statusFilter != null && user.status != _statusFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  /// Runs [action] after the current frame so popup routes can finish closing.
  void _afterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _disposeDialogControllers(List<TextEditingController> controllers) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  void _showAddUserModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddUserScreen()),
    );
  }

  /*
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final schoolIdController = TextEditingController();
    final emailController = TextEditingController();
    final departmentController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    UserRole selectedRole = UserRole.student;
    var isSubmitting = false;
    var obscurePassword = true;
    var obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> submit() async {
            if (isSubmitting) return;
            if (!formKey.currentState!.validate()) return;

            setModalState(() => isSubmitting = true);
            try {
              await _userService.createUser(
                fullName: nameController.text,
                schoolId: schoolIdController.text,
                email: emailController.text,
                role: selectedRole.accountRole,
                password: passwordController.text,
                departmentOrSection: departmentController.text,
              );

              if (!modalContext.mounted) return;
              final successMessage =
                  'User "${nameController.text.trim()}" created successfully!';
              Navigator.pop(modalContext);
              _showSnackBar(successMessage);
            } on FirebaseAuthException catch (error) {
              if (modalContext.mounted) {
                setModalState(() => isSubmitting = false);
              }
              _showSnackBar(
                AuthService.friendlyErrorMessage(error),
                isError: true,
              );
            } catch (error) {
              if (modalContext.mounted) {
                setModalState(() => isSubmitting = false);
              }
              _showSnackBar(
                AuthService.friendlyErrorMessage(error),
                isError: true,
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              margin: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: schoolIdController,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'School ID *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'School ID is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText: 'Email Address *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email address is required.';
                                }
                                if (!_isValidEmail(value)) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<UserRole>(
                              value: selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'System Role *',
                                border: OutlineInputBorder(),
                              ),
                              items: _assignableRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Icon(role.icon, size: 20),
                                      const SizedBox(width: 8),
                                      Text(role.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setModalState(() {
                                          selectedRole = value;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: departmentController,
                              enabled: !isSubmitting,
                              decoration: const InputDecoration(
                                labelText:
                                    'Grade/Section or Department (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              enabled: !isSubmitting,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                border: const OutlineInputBorder(),
                                helperText: 'Minimum 6 characters',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setModalState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: obscureConfirm,
                              enabled: !isSubmitting,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password *',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setModalState(() {
                                      obscureConfirm = !obscureConfirm;
                                    });
                                  },
                                  icon: Icon(
                                    obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm the password.';
                                }
                                if (value != passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'New accounts are created with Active status by default.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(modalContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : submit,
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create User'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _disposeDialogControllers([
        nameController,
        schoolIdController,
        emailController,
        departmentController,
        passwordController,
        confirmPasswordController,
      ]);
    });
  }
  */

  void _showEditUserDialog(UserAccount user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final schoolIdController = TextEditingController(text: user.schoolId);
    final emailController = TextEditingController(text: user.email);
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit User Details'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: schoolIdController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'School ID *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'School ID is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email address is required.';
                        }
                        if (!_isValidEmail(value)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          await _userService.updateUserDetails(
                            uid: user.uid,
                            fullName: nameController.text,
                            schoolId: schoolIdController.text,
                            email: emailController.text,
                          );
                          if (!dialogContext.mounted) return;
                          final successMessage =
                              'User "${nameController.text.trim()}" updated.';
                          Navigator.pop(dialogContext);
                          _showSnackBar(successMessage);
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                          _showSnackBar(
                            AuthService.friendlyErrorMessage(error),
                            isError: true,
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      _disposeDialogControllers([
        nameController,
        schoolIdController,
        emailController,
      ]);
    });
  }

  void _showChangeRoleDialog(UserAccount user) {
    final isProtectedAdmin = _isIctCoordinator(user);
    UserRole selectedRole = isProtectedAdmin
        ? user.role
        : (_assignableRoles.contains(user.role) ? user.role : UserRole.student);
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Role - ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isProtectedAdmin) ...[
                _adminProtectionBanner(
                  context,
                  message:
                      'ICT Coordinator (Admin) role cannot be changed. '
                      'Primary admin accounts are protected.',
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Current role: ${user.role.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'New Role',
                  border: OutlineInputBorder(),
                ),
                items: _assignableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(role.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(role.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: isProtectedAdmin || isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            if (!isProtectedAdmin)
              FilledButton(
                onPressed: isSaving || selectedRole == user.role
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await _userService.updateUserRole(
                            uid: user.uid,
                            role: selectedRole.accountRole,
                          );
                          if (!dialogContext.mounted) return;
                          final successMessage =
                              'Role changed to ${selectedRole.label} for ${user.fullName}.';
                          Navigator.pop(dialogContext);
                          _showSnackBar(successMessage);
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                          _showSnackBar(
                            AuthService.friendlyErrorMessage(error),
                            isError: true,
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Role'),
              ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(UserAccount user) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isSubmitting = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (isSubmitting) return;
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => isSubmitting = true);
            try {
              await _userService.resetUserPassword(
                email: user.email,
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );
              if (!dialogContext.mounted) return;
              final successMessage = 'Password updated for ${user.fullName}.';
              Navigator.pop(dialogContext);
              _showSnackBar(successMessage);
            } catch (error) {
              if (dialogContext.mounted) {
                setDialogState(() => isSubmitting = false);
              }
              _showSnackBar(
                AuthService.friendlyErrorMessage(error),
                isError: true,
              );
            }
          }

          return AlertDialog(
            title: Text('Reset Password - ${user.fullName}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the user\'s current password to verify the account, '
                      'then set a new password.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Current Password *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'New Password *',
                        border: const OutlineInputBorder(),
                        helperText: 'Minimum 6 characters',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required.';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm the new password.';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      _disposeDialogControllers([
        currentPasswordController,
        newPasswordController,
        confirmPasswordController,
      ]);
    });
  }

  void _showDeleteConfirmation(UserAccount user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.red[700],
          size: 48,
        ),
        title: const Text('Delete Account'),
        content: Text(
          'Deleting "${user.fullName}" from Authentication requires Firebase Admin privileges.\n\n'
          'You can set the account status to Inactive or Suspended instead to block access in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _afterFrame(() => _showUpdateStatusDialog(user));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Update Status Instead'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(UserAccount user) {
    final isProtectedAdmin = _isIctCoordinator(user);
    AccountStatus selectedStatus = user.status;
    final reasonController = TextEditingController(
      text: user.statusReason ?? '',
    );
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Account Status'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isProtectedAdmin) ...[
                    _adminProtectionBanner(
                      context,
                      message:
                          'ICT Coordinator (Admin) account status cannot be altered.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: user.status),
                  if (!isProtectedAdmin) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AccountStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Account Status',
                        border: OutlineInputBorder(),
                      ),
                      items: AccountStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => selectedStatus = value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      enabled: !isSaving,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Remarks (Optional)',
                        hintText:
                            'e.g., Graduated, Rule violation, Transferred',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: Text(isProtectedAdmin ? 'Close' : 'Cancel'),
              ),
              if (!isProtectedAdmin)
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await _userService.updateAccountStatus(
                              uid: user.uid,
                              status: selectedStatus.label,
                              statusReason: reasonController.text,
                            );
                            if (!dialogContext.mounted) return;
                            final successMessage =
                                'Account status updated to ${selectedStatus.label} for ${user.fullName}.';
                            Navigator.pop(dialogContext);
                            _showSnackBar(successMessage);
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                            _showSnackBar(
                              AuthService.friendlyErrorMessage(error),
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Status'),
                ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      _disposeDialogControllers([reasonController]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name, email, or School ID...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Users'),
                    selected: _selectedRoleFilter == null,
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Students'),
                    selected: _selectedRoleFilter == UserRole.student,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.student
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Teachers'),
                    selected: _selectedRoleFilter == UserRole.teacher,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.teacher
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Custodians'),
                    selected: _selectedRoleFilter == UserRole.custodian,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.custodian
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ICT Coordinators'),
                    selected: _selectedRoleFilter == UserRole.ictCoordinator,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoleFilter = selected
                            ? UserRole.ictCoordinator
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      _statusFilter == null
                          ? 'All Status'
                          : _statusFilter!.label,
                    ),
                    selected: _statusFilter != null,
                    onSelected: (selected) {
                      setState(() {
                        if (!selected) {
                          _statusFilter = null;
                          return;
                        }
                        // Cycle Active → Inactive → Suspended → clear
                        if (_statusFilter == null) {
                          _statusFilter = AccountStatus.active;
                        } else if (_statusFilter == AccountStatus.active) {
                          _statusFilter = AccountStatus.inactive;
                        } else if (_statusFilter == AccountStatus.inactive) {
                          _statusFilter = AccountStatus.suspended;
                        } else {
                          _statusFilter = null;
                        }
                      });
                    },
                    selectedColor:
                        _statusFilter?.color.withValues(alpha: 0.2) ??
                        Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: _statusFilter?.color ?? Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _userService.watchUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load users.\n${AuthService.friendlyErrorMessage(snapshot.error!)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data ?? const [];
                final allUsers = docs
                    .map(UserAccount.fromFirestore)
                    .toList(growable: false);
                final filteredUsers = _filterUsers(allUsers);

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No users found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserCard(
                        user: user,
                        onEdit: () =>
                            _afterFrame(() => _showEditUserDialog(user)),
                        onChangeRole: () =>
                            _afterFrame(() => _showChangeRoleDialog(user)),
                        onResetPassword: () =>
                            _afterFrame(() => _showResetPasswordDialog(user)),
                        onUpdateStatus: () =>
                            _afterFrame(() => _showUpdateStatusDialog(user)),
                        onDelete: () =>
                            _afterFrame(() => _showDeleteConfirmation(user)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserModal,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onChangeRole,
    required this.onResetPassword,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  final UserAccount user;
  final VoidCallback onEdit;
  final VoidCallback onChangeRole;
  final VoidCallback onResetPassword;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    user.avatarColor ?? colorScheme.primaryContainer,
                child: Text(
                  _initialsFor(user.fullName),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          user.role.icon,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${user.role.label} • ${user.department}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.displayId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email.isNotEmpty
                            ? '${user.displayId} · ${user.email}'
                            : user.displayId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(status: user.status),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'change_role':
                      onChangeRole();
                      break;
                    case 'reset_password':
                      onResetPassword();
                      break;
                    case 'update_status':
                      onUpdateStatus();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  final isProtectedAdmin = _isIctCoordinator(user);
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit User Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'change_role',
                      enabled: !isProtectedAdmin,
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: isProtectedAdmin
                                ? Theme.of(context).disabledColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Change Role / Permissions',
                            style: TextStyle(
                              color: isProtectedAdmin
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 20),
                          SizedBox(width: 8),
                          Text('Reset Password'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'update_status',
                      enabled: !isProtectedAdmin,
                      child: Row(
                        children: [
                          Icon(
                            Icons.manage_accounts_outlined,
                            size: 20,
                            color: isProtectedAdmin
                                ? Theme.of(context).disabledColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Update Account Status',
                            style: TextStyle(
                              color: isProtectedAdmin
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
