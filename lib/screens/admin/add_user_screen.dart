import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/account_role.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final schoolIdController = TextEditingController();
  final emailController = TextEditingController();
  final orgDetailsController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final UserService _userService = UserService();

  AccountRole _selectedRole = AccountRole.student;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    schoolIdController.dispose();
    emailController.dispose();
    orgDetailsController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _userService.createUserAccount(
        fullName: fullNameController.text,
        schoolId: schoolIdController.text,
        email: emailController.text,
        role: _selectedRole,
        password: passwordController.text,
        departmentOrSection: orgDetailsController.text,
        isApproved: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User account created successfully')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      _showError(AuthService.friendlyErrorMessage(error));
    } catch (error) {
      _showError(AuthService.friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New User')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      controller: fullNameController,
                      label: 'Full Name *',
                      capitalization: TextCapitalization.words,
                      validator: (value) => _required(value, 'Full name'),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: schoolIdController,
                      label: 'School ID *',
                      validator: (value) => _required(value, 'School ID'),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: emailController,
                      label: 'Email Address *',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final required = _required(value, 'Email address');
                        if (required != null) return required;
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value!.trim())) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AccountRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'System Role *',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          const [
                                AccountRole.student,
                                AccountRole.teacher,
                                AccountRole.propertyCustodian,
                                AccountRole.ictCoordinator,
                              ]
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(_roleLabel(role)),
                                ),
                              )
                              .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() => _selectedRole = value!),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: orgDetailsController,
                      label: 'Grade/Section or Department (Optional)',
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: passwordController,
                      label: 'Password *',
                      obscureText: _obscurePassword,
                      helperText: 'Minimum 6 characters',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        final required = _required(value, 'Password');
                        if (required != null) return required;
                        return value!.length < 6
                            ? 'Password must be at least 6 characters.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: confirmPasswordController,
                      label: 'Confirm Password *',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        final required = _required(
                          value,
                          'Password confirmation',
                        );
                        if (required != null) return required;
                        return value != passwordController.text
                            ? 'Passwords do not match'
                            : null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscureText = false,
    String? helperText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;
}

String _roleLabel(AccountRole role) {
  switch (role) {
    case AccountRole.student:
      return 'Student';
    case AccountRole.teacher:
      return 'Teacher';
    case AccountRole.propertyCustodian:
      return 'Property Custodian';
    case AccountRole.ictCoordinator:
      return 'Admin (ICT Coordinator)';
  }
}
