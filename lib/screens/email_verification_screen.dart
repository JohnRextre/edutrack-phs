import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.role,
    this.registeredFirstName,
    this.registeredLastName,
    this.registeredSchoolId,
  });

  final AccountRole role;
  final String? registeredFirstName;
  final String? registeredLastName;
  final String? registeredSchoolId;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _autoCheckTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final isVerified = await _authService.checkEmailVerified();
      if (isVerified && mounted) {
        _autoCheckTimer?.cancel();
        _cooldownTimer?.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _startCooldownTimer([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _manualCheck() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final isVerified = await _authService.checkEmailVerified();
      if (!mounted) return;

      if (isVerified) {
        _autoCheckTimer?.cancel();
        _cooldownTimer?.cancel();
        _navigateToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not yet verified. Please click the link sent to your inbox.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      _startCooldownTimer(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email resent! Please check your inbox and spam folder.',
          ),
          backgroundColor: Color(0xFF176B87),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _navigateToDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully! Welcome to EduTrack PHS.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(
      context,
    ).pushReplacementNamed('/dashboard', arguments: widget.role.name);
  }

  Future<void> _backToLogin() async {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
      arguments: {
        'email': email,
        'role': widget.role,
        'isPendingVerification': true,
      },
    );
  }

  Future<void> _cancelAndChangeAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Registration?'),
        content: Text(
          email.isNotEmpty
              ? 'Do you want to cancel the registration for $email?\n\nThis will remove this unverified account from the system so the email and School ID can be registered again with the correct details.'
              : 'Do you want to cancel this unverified registration so you can start over?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Waiting'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel & Change'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cancelling registration...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _authService.cancelUnverifiedRegistration();
    } catch (e) {
      debugPrint('Error cancelling unverified registration: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading indicator

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unverified registration cancelled. You can now register with the correct email.',
        ),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          initialFirstName: widget.registeredFirstName,
          initialLastName: widget.registeredLastName,
          initialSchoolId: widget.registeredSchoolId,
          initialRole: widget.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Icon Container ───────────────────────────────────
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 40,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Title & Description ──────────────────────────────
                      Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We have sent a verification link to:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please open your inbox (and check your spam or junk folder) and click the verification link to complete your registration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Waiting Indicator ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Checking verification automatically...',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Manual Check Button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isChecking ? null : _manualCheck,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isChecking
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            _isChecking
                                ? 'Checking...'
                                : "I've Verified My Email",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Resend Email Button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_cooldownSeconds > 0 || _isResending)
                              ? null
                              : _resendVerificationEmail,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isResending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: Text(
                            _cooldownSeconds > 0
                                ? 'Resend email in ${_cooldownSeconds}s'
                                : 'Resend Verification Email',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Back to Login ────────────────────────────────────
                      TextButton.icon(
                        onPressed: _backToLogin,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to Login'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Change Account / Cancel ──────────────────────────
                      TextButton.icon(
                        onPressed: _cancelAndChangeAccount,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colors.error,
                        ),
                        label: Text(
                          'Mistyped email? Cancel & Re-register',
                          style: TextStyle(color: colors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
