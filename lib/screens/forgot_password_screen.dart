import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// A streamlined, elegant screen for the "Forgot Password" flow.
///
/// Sends a secure password reset link directly to the user's email.
class ForgotPasswordScreen extends StatefulWidget {
  /// Pre-fills the email field if typed in the login screen.
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _authService = AuthService();

  bool _isSending = false;
  bool _emailSent = false;
  String _sentToEmail = '';

  // 60-second cooldown for resending
  static const int _cooldownSeconds = 60;
  int _secondsLeft = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendResetLink({bool isResend = false}) async {
    if (!isResend) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isSending = true);

    try {
      final email = _emailController.text.trim();
      await _authService.sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _emailSent = true;
        _sentToEmail = email;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _emailSent
                    ? _EmailSentSuccessView(
                        key: const ValueKey('success_view'),
                        email: _sentToEmail,
                        secondsLeft: _secondsLeft,
                        isSending: _isSending,
                        onResend: _secondsLeft > 0 || _isSending
                            ? null
                            : () => _sendResetLink(isResend: true),
                        onBackToLogin: () => Navigator.pop(context),
                      )
                    : _EmailRequestView(
                        key: const ValueKey('form_view'),
                        formKey: _formKey,
                        emailController: _emailController,
                        isSending: _isSending,
                        onSend: () => _sendResetLink(),
                        onCancel: () => Navigator.pop(context),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Clean Email Request View ──────────────────────────────────────────

class _EmailRequestView extends StatelessWidget {
  const _EmailRequestView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isSending,
    required this.onSend,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Icon Badge
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primaryContainer,
                  colors.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 42,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title & Description
        Text(
          'Forgot your password?',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 23,
            color: colors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Enter the email address linked to your EduTrack account and we\'ll send you a password reset link.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Email Input Field
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registered Email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => isSending ? null : onSend(),
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Please enter your email address.';
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. user@edutrack.ph',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: colors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Informational card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'After clicking Send, check your inbox for the reset email. Simply tap the link to choose a new password.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Send Button
        FilledButton.icon(
          onPressed: isSending ? null : onSend,
          icon: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(isSending ? 'Sending Link...' : 'Send Reset Link'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Back to Login Button
        OutlinedButton(
          onPressed: isSending ? null : onCancel,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}

// ─── Step 2: Email Sent Confirmation View ──────────────────────────────────────

class _EmailSentSuccessView extends StatelessWidget {
  const _EmailSentSuccessView({
    super.key,
    required this.email,
    required this.secondsLeft,
    required this.isSending,
    required this.onResend,
    required this.onBackToLogin,
  });

  final String email;
  final int secondsLeft;
  final bool isSending;
  final VoidCallback? onResend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canResend = onResend != null && !isSending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon badge
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 46,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Check Your Inbox!',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 23,
            color: colors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a password reset link to:',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Email pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              email,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Instruction steps card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              _StepRow(
                icon: Icons.open_in_new_rounded,
                iconColor: colors.primary,
                title: 'Click the link in the email',
                subtitle:
                    'Open the message from EduTrack and click the link to set your new password.',
              ),
              const SizedBox(height: 12),
              _StepRow(
                icon: Icons.timer_outlined,
                iconColor: Colors.orange.shade700,
                title: 'Link expires in 1 hour',
                subtitle:
                    'For your security, the reset link is valid for 60 minutes.',
              ),
              const SizedBox(height: 12),
              _StepRow(
                icon: Icons.folder_special_outlined,
                iconColor: colors.onSurfaceVariant,
                title: 'Check Spam or Promotions folder',
                subtitle:
                    'If you don\'t see the email, it may have arrived in your Spam folder.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Back to login button
        FilledButton.icon(
          onPressed: onBackToLogin,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Back to Login'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resend button
        OutlinedButton.icon(
          onPressed: canResend ? onResend : null,
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            secondsLeft > 0
                ? 'Resend Link (${secondsLeft}s)'
                : isSending
                ? 'Resending...'
                : 'Resend Reset Email',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
