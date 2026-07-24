import 'package:flutter/material.dart';

import '../models/account_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _passwordController = TextEditingController();
  AccountRole _selectedRole = AccountRole.student;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
        arguments: _selectedRole.name,
      );
    }
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
                          onPressed: () {},
                          child: const Text('Back to Portal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel('Select Campus:'),
                    DropdownButtonFormField<String>(
                      initialValue: 'NU Baliwag',
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'NU Baliwag',
                          child: Text('NU Baliwag'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 18),
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
                      controller: _schoolIdController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'School ID / Email',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your School ID or Email'
                          : null,
                    ),
                    const SizedBox(height: 14),
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
                      validator: (value) => value == null || value.isEmpty
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
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _login,
                        child: const Text('Login with EduTrack'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {},
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
