import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
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
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _loginError;
  String? _errorField;
  Timer? _loginErrorTimer;
  bool _didCheckArguments = false;
  String? _pendingVerificationEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCheckArguments) {
      _didCheckArguments = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final email = args['email'] as String?;
        if (email != null && email.isNotEmpty) {
          _identifierController.text = email;
          _pendingVerificationEmail = email;
        }
      } else if (args is String && args.contains('@')) {
        _identifierController.text = args;
        _pendingVerificationEmail = args;
      }
    }
  }

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
      );

      if (!mounted) return;
      final role = await _authService.fetchCurrentUserRole();
      if (!mounted) return;
      if (!user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(role: role),
          ),
        );
        return;
      }

      if (user.uid.isNotEmpty) {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: role.name,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1280;
          final form = Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 44 : 24,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'lib/assets/edutrack_logo/EduTrack_Rectangle_Logo-NoBackground.png',
                        height: 42,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF176B87),
                          size: 42,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Back to homepage',
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 38,
                      height: 1.1,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to your EduTrack workspace.',
                    style: TextStyle(color: Color(0xFF627D98), height: 1.5),
                  ),
                  if (_pendingVerificationEmail != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Email verification pending: $_pendingVerificationEmail',
                        style: const TextStyle(
                          color: Color(0xFF176B87),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Admin and Property Custodian access',
                        style: TextStyle(
                          color: Color(0xFF486581),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _clearLoginError(),
                    decoration: const InputDecoration(
                      labelText: 'School ID or Email',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) =>
                        _hasSubmitted && (value == null || value.trim().isEmpty)
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
                    ),
                    validator: (value) =>
                        _hasSubmitted && (value == null || value.isEmpty)
                        ? 'Enter your password'
                        : null,
                  ),
                  if (_loginError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _loginError!,
                        style: const TextStyle(
                          color: Color(0xFF9B2C2C),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF102A43),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _showNeedHelpSheet,
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    label: const Text('Need help signing in'),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openRegistrationFlow,
                      child: const Text('Create an account'),
                    ),
                  ],
                ],
              ),
            ),
          );

          if (!wide) {
            return SafeArea(
              child: Center(child: SingleChildScrollView(child: form)),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'lib/assets/web/campus.jpg',
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x22102A43), Color(0xB0102A43)],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 38,
                          right: 38,
                          bottom: 38,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EduTrack PHS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  height: 1.05,
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'One workspace for resources, borrowing,\nand responsible school operations.',
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 9, child: Center(child: form)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openForgotPassword() {
    final prefill = _identifierController.text.contains('@')
        ? _identifierController.text.trim()
        : '';
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: prefill),
      ),
    );
  }

  void _showNeedHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'EduTrack PHS Assistance & FAQs',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                // Content List
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const _HelpAccordion(
                        icon: Icons.login_rounded,
                        title: 'How do I log in to my account?',
                        content:
                            '1. Select your correct account type (Student, Teacher, Property Custodian, or ICT Coordinator).\n\n'
                            '2. Sign in using either your assigned School ID (LRN / Employee ID) or your registered Email Address along with your password.',
                      ),
                      const SizedBox(height: 12),
                      const _HelpAccordion(
                        icon: Icons.mark_email_unread_outlined,
                        title: "I haven't received my verification email",
                        content:
                            '1. Check your Spam, Junk, or Promotions folder in your email inbox.\n\n'
                            '2. If you mistyped your email during registration, click "Mistyped email? Cancel & Re-register" to fix it using the same School ID.\n\n'
                            '3. For legacy accounts, you can verify your email anytime through your Profile screen ("Verify My Account").',
                      ),
                      const SizedBox(height: 12),
                      _HelpAccordion(
                        icon: Icons.lock_reset_rounded,
                        title: 'Forgot or lost your password?',
                        content:
                            'Tap the button below or "Forgot password" on the login screen. Enter your registered email address to receive a secure password reset link.',
                        actionLabel: 'Reset Password Now',
                        onAction: () {
                          Navigator.pop(sheetContext);
                          _openForgotPassword();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact School Support Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.support_agent_rounded,
                                  color: colors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'School IT Support Office',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SupportContactRow(
                              icon: Icons.location_on_outlined,
                              text: 'ICT Coordinator Office / Room 205',
                              colors: colors,
                            ),
                            const SizedBox(height: 6),
                            _SupportContactRow(
                              icon: Icons.email_outlined,
                              text: 'mendozajohnrexter@gmail.com',
                              colors: colors,
                            ),
                            const SizedBox(height: 6),
                            _SupportContactRow(
                              icon: Icons.access_time_rounded,
                              text: 'Mon - Fri | 7:30 AM - 5:00 PM',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpAccordion extends StatelessWidget {
  const _HelpAccordion({
    required this.icon,
    required this.title,
    required this.content,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String content;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tileColor = colors.surfaceContainerHighest.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: tileColor,
              collapsedBackgroundColor: tileColor,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 18),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: onAction,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(actionLabel!),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  final IconData icon;
  final String text;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
