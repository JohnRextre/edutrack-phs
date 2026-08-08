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
