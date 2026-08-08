import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  AccountRole _selectedRole = AccountRole.student;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.registerUser(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        schoolId: _schoolIdController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      final user = credential.user;
      if (user == null) {
        _showSnackBar('Account creation failed. Please try again.');
        return;
      }

      final route = MaterialPageRoute(
        builder: (_) => DashboardScreen(role: _selectedRole),
      );
      Navigator.of(context).pushReplacement(route);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showSnackBar(AuthService.friendlyErrorMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(AuthService.friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'lib/assets/edutrack_logo/EduTrack_Square_Logo.png',
                        width: 96,
                        height: 96,
                        errorBuilder: (_, _, _) => CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.person_add_alt_1_outlined,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Join EduTrack PHS',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    DropdownButtonFormField<AccountRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AccountRole.student,
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: AccountRole.teacher,
                          child: Text('Teacher'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your full name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _schoolIdController,
                      decoration: const InputDecoration(
                        labelText: 'School ID',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your school ID.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address.';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a password.';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Re-enter your password.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Login'),
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
}
