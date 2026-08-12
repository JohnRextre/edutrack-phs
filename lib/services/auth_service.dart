import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/account_role.dart';

class AuthService {
  AuthService();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String configDocumentPath = 'system_settings/config';

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase config is expected to be added in the Android/iOS/web setup.
    }
  }

  static bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  static String roleFromString(String? roleName) {
    final normalized = (roleName ?? '').trim();
    if (normalized.isEmpty) return 'Student';

    final key = normalized.toLowerCase();
    switch (key) {
      case 'student':
        return 'Student';
      case 'teacher':
        return 'Teacher';
      case 'property custodian':
      case 'property_custodian':
      case 'propertycustodian':
        return 'Property Custodian';
      case 'ict coordinator':
      case 'admin':
      case 'ict_coordinator':
        return 'ICT Coordinator';
      default:
        return normalized;
    }
  }

  static bool isAdminSetupComplete(Map<String, dynamic>? data) =>
      data?['isAdminSetupComplete'] == true;

  static AccountRole accountRoleFromFirestoreValue(dynamic value) {
    final roleName = roleFromString(value?.toString());
    switch (roleName) {
      case 'Student':
        return AccountRole.student;
      case 'Teacher':
        return AccountRole.teacher;
      case 'Property Custodian':
        return AccountRole.propertyCustodian;
      case 'ICT Coordinator':
        return AccountRole.ictCoordinator;
      default:
        return AccountRole.student;
    }
  }

  static String firestoreRoleLabel(AccountRole role) {
    switch (role) {
      case AccountRole.student:
        return 'Student';
      case AccountRole.teacher:
        return 'Teacher';
      case AccountRole.propertyCustodian:
        return 'Property Custodian';
      case AccountRole.ictCoordinator:
        return 'ICT Coordinator';
    }
  }

  Future<bool> checkAdminExists() async {
    try {
      final configSnapshot = await _firestore.doc(configDocumentPath).get();
      if (configSnapshot.exists &&
          isAdminSetupComplete(configSnapshot.data())) {
        return true;
      }

      final adminQuery = await _firestore
          .collection(usersCollection)
          .where('role', isEqualTo: 'ICT Coordinator')
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        await _firestore.doc(configDocumentPath).set({
          'isAdminSetupComplete': true,
        }, SetOptions(merge: true));
        return true;
      }

      return false;
    } on FirebaseException {
      return false;
    }
  }

  Future<UserCredential> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String schoolId,
    required AccountRole role,
    bool isInitialAdmin = false,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final trimmedSchoolId = schoolId.trim();

    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-name',
        message: 'Please enter your full name.',
      );
    }
    if (trimmedSchoolId.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-school-id',
        message: 'Please enter your school ID.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
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

      await _firestore.collection(usersCollection).doc(user.uid).set({
        'uid': user.uid,
        'schoolId': trimmedSchoolId,
        'fullName': trimmedName,
        'email': trimmedEmail,
        'role': firestoreRoleLabel(role),
        'departmentOrSection': '',
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isInitialAdmin || role == AccountRole.ictCoordinator) {
        await _firestore.doc(configDocumentPath).set({
          'isAdminSetupComplete': true,
        }, SetOptions(merge: true));
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (error) {
      if (error is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to complete registration at the moment.',
      );
    }
  }

  Future<User> signInWithAccount({
    required String email,
    required String password,
    required AccountRole selectedRole,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter your email or school ID.',
      );
    }

    final resolvedEmail = await _resolveLoginEmail(trimmedEmail);
    final credential = await _auth.signInWithEmailAndPassword(
      email: resolvedEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Unable to log in. Please try again.',
      );
    }

    final profile = await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .get();
    final firestoreRole = profile.data()?['role'];
    final storedRole = accountRoleFromFirestoreValue(firestoreRole);

    if (storedRole != selectedRole) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message:
            'This account is not registered as a ${selectedRole.label}. Please select the correct account type.',
      );
    }

    return user;
  }

  Future<AccountRole> fetchCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No active session was found.',
      );
    }

    final profile = await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .get();
    final roleName = profile.data()?['role'];
    return accountRoleFromFirestoreValue(roleName);
  }

  Future<String> _resolveLoginEmail(String identifier) async {
    if (identifier.contains('@')) {
      return identifier;
    }

    final querySnapshot = await _firestore
        .collection(usersCollection)
        .where('schoolId', isEqualTo: identifier)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user was found for this School ID.',
      );
    }

    final email = querySnapshot.docs.first.data()['email']?.toString();
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No email was found for this account.',
      );
    }

    return email;
  }

  static String friendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'This password is too weak. Please choose a stronger password.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password. Please try again.';
        case 'role-mismatch':
          return error.message ??
              'The selected account type does not match this user.';
        case 'invalid-name':
        case 'invalid-school-id':
          return error.message ?? 'Please complete all required fields.';
        case 'firebase-unavailable':
          return error.message ??
              'Firebase is not configured. Please try again later.';
        case 'admin-protected':
          return error.message ??
              'This admin account is protected and cannot be modified.';
        case 'network-request-failed':
          return 'A network problem prevented the request. Please try again.';
        case 'requires-recent-login':
          return 'Please re-enter the current password and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'admin-protected') {
        return error.message ??
            'This admin account is protected and cannot be modified.';
      }
      return error.message ?? 'A Firebase error occurred.';
    }

    return error.toString();
  }
}
