import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edutrack_phs/services/auth_service.dart';

void main() {
  group('AuthService role helpers', () {
    test('normalizes stored role names to AccountRole values', () {
      expect(AuthService.roleFromString('Student'), equals('Student'));
      expect(
        AuthService.roleFromString('Property Custodian'),
        equals('Property Custodian'),
      );
      expect(
        AuthService.roleFromString('ICT Coordinator'),
        equals('ICT Coordinator'),
      );
      expect(AuthService.roleFromString('teacher'), equals('Teacher'));
    });

    test('standardizes login error messages', () {
      expect(
        AuthService.friendlyErrorMessage(
          FirebaseAuthException(
            code: 'role-mismatch',
            message:
                'Account not registered as Student. Please check your Account Type or Credentials.',
          ),
        ),
        'Account not registered as Student. Please check your Account Type or Credentials.',
      );
      expect(
        AuthService.friendlyErrorMessage(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'Incorrect password. Please try again.',
      );
      expect(
        AuthService.friendlyErrorMessage(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        'No account found with this School ID or Email.',
      );
      expect(
        AuthService.friendlyErrorMessage(
          FirebaseAuthException(code: 'account-not-approved'),
        ),
        'Your account is pending registration approval by the Admin.',
      );
    });

    test('admin setup flag is read as boolean', () {
      expect(
        AuthService.isAdminSetupComplete({'isAdminSetupComplete': true}),
        isTrue,
      );
      expect(
        AuthService.isAdminSetupComplete({'isAdminSetupComplete': false}),
        isFalse,
      );
    });
  });
}
