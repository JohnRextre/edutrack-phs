import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/account_role.dart';
import 'auth_service.dart';

/// Firestore-backed user management for the Admin module.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _secondaryAppName = 'EduTrackSecondaryAuth';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AuthService.usersCollection);

  /// Live stream of all users in the `users` collection.
  /// Sorted client-side so documents missing `fullName` still appear.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final nameA = (a.data()['fullName'] ?? '').toString().toLowerCase();
        final nameB = (b.data()['fullName'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      return docs;
    });
  }

  /// Creates a Firebase Auth account and writes a Firestore profile.
  ///
  /// Uses a secondary Firebase Auth instance so the admin session is preserved.
  Future<void> createUserAccount({
    required String fullName,
    required String schoolId,
    required String email,
    required AccountRole role,
    required String password,
    String? departmentOrSection,
    bool isApproved = true,
  }) {
    return createUser(
      fullName: fullName,
      schoolId: schoolId,
      email: email,
      role: role,
      password: password,
      departmentOrSection: departmentOrSection,
      isApproved: isApproved,
    );
  }

  Future<void> createUser({
    required String fullName,
    required String schoolId,
    required String email,
    required AccountRole role,
    required String password,
    String? departmentOrSection,
    bool isApproved = true,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedSchoolId = schoolId.trim();
    final trimmedEmail = email.trim();
    final trimmedDepartment = departmentOrSection?.trim() ?? '';

    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-name',
        message: 'Please enter the full name.',
      );
    }
    if (trimmedSchoolId.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-school-id',
        message: 'Please enter the school ID.',
      );
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 6 characters.',
      );
    }
    if (!AuthService.isFirebaseAvailable) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not configured. Please try again later.',
      );
    }

    final secondaryAuth = await _secondaryAuth();
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Unable to create the user account.',
        );
      }

      await _users.doc(user.uid).set({
        'uid': user.uid,
        'fullName': trimmedName,
        'schoolId': trimmedSchoolId,
        'email': trimmedEmail,
        'role': AuthService.firestoreRoleLabel(role),
        'departmentOrSection': trimmedDepartment,
        'status': 'Active',
        'isApproved': isApproved,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (role == AccountRole.ictCoordinator) {
        await _firestore.doc(AuthService.configDocumentPath).set({
          'isAdminSetupComplete': true,
        }, SetOptions(merge: true));
      }
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {
        // Best-effort cleanup of the secondary session.
      }
    }
  }

  /// Returns true when the Firestore user document is an ICT Coordinator.
  Future<bool> isIctCoordinator(String uid) async {
    final snapshot = await _users.doc(uid.trim()).get();
    if (!snapshot.exists) return false;
    final role = AuthService.roleFromString(
      snapshot.data()?['role']?.toString(),
    );
    return role == 'ICT Coordinator';
  }

  /// Updates account status fields on a user document.
  /// ICT Coordinator (admin) accounts cannot be deactivated or status-changed.
  Future<void> updateAccountStatus({
    required String uid,
    required String status,
    String? statusReason,
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-uid',
        message: 'User id is missing.',
      );
    }

    if (await isIctCoordinator(trimmedUid)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'admin-protected',
        message: 'ICT Coordinator (Admin) account status cannot be altered.',
      );
    }

    final normalizedStatus = _normalizeStatus(status);
    final reason = statusReason?.trim() ?? '';

    await _users.doc(trimmedUid).update({
      'status': normalizedStatus,
      'statusReason': reason,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates basic profile fields for an existing user (no role/department).
  Future<void> updateUserDetails({
    required String uid,
    required String fullName,
    required String schoolId,
    required String email,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedSchoolId = schoolId.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-name',
        message: 'Please enter the full name.',
      );
    }
    if (trimmedSchoolId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-school-id',
        message: 'Please enter the school ID.',
      );
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    await _users.doc(uid).update({
      'fullName': trimmedName,
      'schoolId': trimmedSchoolId,
      'email': trimmedEmail,
    });
  }

  /// Updates editable profile fields while preserving read-only account data.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-uid',
        message: 'User id is missing.',
      );
    }

    final updates = <String, dynamic>{};
    for (final key in ['firstName', 'lastName', 'gradeSection', 'department']) {
      if (data.containsKey(key)) {
        final value = data[key]?.toString().trim() ?? '';
        if (value.isEmpty && key != 'department') {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'invalid-profile',
            message: 'Please complete all required profile fields.',
          );
        }
        updates[key] = value;
      }
    }
    if (data.containsKey('phoneNumber')) {
      updates['phoneNumber'] = data['phoneNumber']?.toString().trim() ?? '';
    }
    if (updates.isEmpty) return;
    updates['updatedAt'] = Timestamp.now();
    await _users.doc(trimmedUid).update(updates);
  }

  /// Updates only the system role.
  /// ICT Coordinator roles are protected and cannot be assigned or removed here.
  Future<void> updateUserRole({
    required String uid,
    required AccountRole role,
  }) async {
    if (role == AccountRole.ictCoordinator) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'admin-protected',
        message:
            'The ICT Coordinator role cannot be assigned from User Management.',
      );
    }

    if (await isIctCoordinator(uid)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'admin-protected',
        message: 'ICT Coordinator (Admin) role cannot be changed.',
      );
    }

    await _users.doc(uid).update({
      'role': AuthService.firestoreRoleLabel(role),
    });
  }

  /// Changes a user's password after verifying their current password.
  ///
  /// Uses a secondary Auth instance so the admin session stays signed in.
  Future<void> resetUserPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'This user does not have a valid email address.',
      );
    }
    if (currentPassword.isEmpty) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Please enter the current password.',
      );
    }
    if (newPassword.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'New password must be at least 6 characters.',
      );
    }
    if (newPassword == currentPassword) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'New password must be different from the current password.',
      );
    }

    if (!AuthService.isFirebaseAvailable) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not configured. Please try again later.',
      );
    }

    final secondaryAuth = await _secondaryAuth();
    try {
      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: currentPassword,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Unable to verify this account.',
        );
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential' ||
          error.code == 'INVALID_LOGIN_CREDENTIALS') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Current password is incorrect.',
        );
      }
      rethrow;
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {
        // Best-effort cleanup of the secondary session.
      }
    }
  }

  static String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      default:
        return status.trim().isEmpty ? 'Active' : status.trim();
    }
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    FirebaseApp app;
    try {
      app = Firebase.app(_secondaryAppName);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }
}
