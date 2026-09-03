import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../services/auth_service.dart';
import 'initial_admin_setup_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  AccountRole _selectedRole = AccountRole.student;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _loginError;
  String? _errorField;
  Timer? _loginErrorTimer;

  @override
  void dispose() {
    _loginErrorTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _hasSubmitted = true);
    if (_identifierController.text.trim().isEmpty) {
      _formKey.currentState!.validate();
      _scheduleValidationClear();
      return;
    }
    if (_passwordController.text.isEmpty) {
      _formKey.currentState!.validate();
      _scheduleValidationClear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithAccount(
        email: _identifierController.text,
        password: _passwordController.text,
        selectedRole: _selectedRole,
      );

      if (!mounted) return;
      if (user.uid.isNotEmpty) {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: _selectedRole.name,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _setLoginError(error);
    } catch (error) {
      if (!mounted) return;
      _setLoginError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setLoginError(Object error) {
    final code = error is FirebaseAuthException ? error.code : null;
    _loginErrorTimer?.cancel();
    setState(() {
      _loginError = AuthService.friendlyErrorMessage(error);
      _errorField = switch (code) {
        'wrong-password' || 'invalid-credential' => 'password',
        'user-not-found' ||
        'role-mismatch' ||
        'account-not-approved' => 'identifier',
        _ => null,
      };
    });
    _loginErrorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _loginError = null;
        _errorField = null;
        _hasSubmitted = false;
      });
      _formKey.currentState?.validate();
    });
  }

  void _clearLoginError() {
    _loginErrorTimer?.cancel();
    if (_loginError == null && _errorField == null && !_hasSubmitted) return;
    setState(() {
      _loginError = null;
      _errorField = null;
      _hasSubmitted = false;
    });
    _formKey.currentState?.validate();
  }

  void _scheduleValidationClear() {
    _loginErrorTimer?.cancel();
    _loginErrorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _hasSubmitted = false);
      _formKey.currentState?.validate();
    });
  }

  Future<void> _openRegistrationFlow() async {
    try {
      final adminExists = await _authService.checkAdminExists();
      if (!mounted) return;

      final route = adminExists
          ? const RegisterScreen()
          : const InitialAdminSetupScreen();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => route));
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(AuthService.friendlyErrorMessage(error));
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
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
                        width: 112,
                        height: 112,
                        errorBuilder: (_, _, _) => CircleAvatar(
                          radius: 48,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.school_outlined,
                            size: 52,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false),
                          child: const Text('Back to Homepage'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel('Select Account Type:'),
                    DropdownButtonFormField<AccountRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: AccountRole.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(
                                role == AccountRole.ictCoordinator
                                    ? 'Admin (ICT Coordinator)'
                                    : role.label,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (role) {
                        if (role != null) setState(() => _selectedRole = role);
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _clearLoginError(),
                      decoration: InputDecoration(
                        labelText: 'School ID / Email',
                        prefixIcon: Icon(Icons.badge_outlined),
                        enabledBorder: _fieldBorder(
                          _hasSubmitted && _errorField == 'identifier',
                        ),
                        focusedBorder: _fieldBorder(
                          _hasSubmitted && _errorField == 'identifier',
                        ),
                        errorBorder: _fieldBorder(true),
                        focusedErrorBorder: _fieldBorder(true),
                      ),
                      validator: (value) =>
                          _hasSubmitted &&
                              (value == null || value.trim().isEmpty)
                          ? 'Enter your School ID or Email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => _clearLoginError(),
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
                        enabledBorder: _fieldBorder(
                          _hasSubmitted && _errorField == 'password',
                        ),
                        focusedBorder: _fieldBorder(
                          _hasSubmitted && _errorField == 'password',
                        ),
                        errorBorder: _fieldBorder(true),
                        focusedErrorBorder: _fieldBorder(true),
                      ),
                      validator: (value) =>
                          _hasSubmitted && (value == null || value.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, size: 19, color: colors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If you are a student or an employee, login with your EduTrack account.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_loginError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _loginError!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Login with EduTrack PHS'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _openRegistrationFlow,
                          child: const Text('Create an account'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password'),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Need help?'),
                      ),
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

  OutlineInputBorder _fieldBorder(bool invalid) => OutlineInputBorder(
    borderSide: BorderSide(
      color: invalid ? Colors.red.shade400 : Colors.grey.shade500,
      width: invalid ? 1.5 : 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
