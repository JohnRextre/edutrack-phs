import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/account_role.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String configDocumentPath = 'system_settings/config';

  static Future<void> initialize() async {
    try {
      if (kIsWeb && DefaultFirebaseOptions.web.appId.isEmpty) {
        throw FirebaseAuthException(
          code: 'firebase-unavailable',
          message:
              'Missing FIREBASE_WEB_APP_ID. Register a Web App in Firebase and run with --dart-define=FIREBASE_WEB_APP_ID=1:...:web:....',
        );
      }
      await Firebase.initializeApp(
        options: kIsWeb ? DefaultFirebaseOptions.web : null,
      );
    } on FirebaseException catch (error) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase could not be initialized: ${error.message}',
      );
    }
  }

  static bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  static Future<void> signOut() => _auth.signOut();

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

  Future<bool> isSchoolIdRegistered(String schoolId) async {
    final trimmedSchoolId = schoolId.trim();
    if (trimmedSchoolId.isEmpty) return false;

    final snapshot = await _firestore
        .collection(usersCollection)
        .where('schoolId', isEqualTo: trimmedSchoolId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<UserCredential> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String schoolId,
    required AccountRole role,
    bool isInitialAdmin = false,
  }) async {
    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    final trimmedEmail = email.trim();
    final trimmedSchoolId = schoolId.trim();

    if (trimmedFirstName.isEmpty || trimmedLastName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-name',
        message: 'Please enter your first and last name.',
      );
    }
    if (trimmedSchoolId.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-school-id',
        message: 'Please enter your school ID.',
      );
    }
    if (trimmedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter your email address.',
      );
    }

    if (await isSchoolIdRegistered(trimmedSchoolId)) {
      throw FirebaseAuthException(
        code: 'school-id-already-in-use',
        message: 'School ID / Employee ID is already registered.',
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

      final profile = UserModel(
        uid: user.uid,
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
        email: trimmedEmail,
        schoolId: trimmedSchoolId,
        role: AuthService.firestoreRoleLabel(role),
      );

      await _firestore.collection(usersCollection).doc(user.uid).set({
        ...profile.toMap(),
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

    final account = await _resolveLoginAccount(trimmedEmail);
    final profileData = account.data();
    final status = profileData['status']?.toString().trim().toLowerCase();
    if (profileData['isApproved'] == false ||
        status == 'pending' ||
        status == 'pending_approval') {
      throw FirebaseAuthException(
        code: 'account-not-approved',
        message: 'Your account is pending registration approval by the Admin.',
      );
    }

    final storedRole = accountRoleFromFirestoreValue(profileData['role']);
    if (storedRole != selectedRole) {
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message:
            'Account not registered as ${selectedRole.label}. Please check your Account Type or Credentials.',
      );
    }

    final resolvedEmail = profileData['email']?.toString().trim();
    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found with this School ID or Email.',
      );
    }

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

  /// Live profile stream for the signed-in user.
  static Stream<UserModel?> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection(usersCollection).doc(user.uid).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      },
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> _resolveLoginAccount(
    String identifier,
  ) async {
    final field = identifier.contains('@') ? 'email' : 'schoolId';
    final querySnapshot = await _firestore
        .collection(usersCollection)
        .where(field, isEqualTo: identifier)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found with this School ID or Email.',
      );
    }
    return querySnapshot.docs.first;
  }

  static String friendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'This password is too weak. Please choose a stronger password.';
        case 'email-already-in-use':
          return 'This email address is already registered.';
        case 'school-id-already-in-use':
          return 'School ID / Employee ID is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password. Please try again.';
        case 'user-not-found':
          return 'No account found with this School ID or Email.';
        case 'account-not-approved':
          return 'Your account is pending registration approval by the Admin.';
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
