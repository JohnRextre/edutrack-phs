import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_role.dart';

/// Firestore user profile stored in the `users` collection.
class UserModel {
  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.schoolId,
    required this.role,
    this.departmentOrSection = '',
    this.status = 'Active',
    this.createdAt,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String schoolId;
  final String role;
  final String departmentOrSection;
  final String status;
  final DateTime? createdAt;

  /// Backward-compatible display name for screens still expecting `fullName`.
  String get fullName => '$firstName $lastName'.trim();

  AccountRole get accountRole {
    final normalized = role.trim().toLowerCase();
    switch (normalized) {
      case 'teacher':
        return AccountRole.teacher;
      case 'property custodian':
      case 'property_custodian':
        return AccountRole.propertyCustodian;
      case 'ict coordinator':
      case 'admin':
        return AccountRole.ictCoordinator;
      case 'student':
      default:
        return AccountRole.student;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'schoolId': schoolId,
      'role': role,
      'departmentOrSection': departmentOrSection,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final firstName = (map['firstName'] ?? '').toString().trim();
    final lastName = (map['lastName'] ?? '').toString().trim();
    final legacyFullName = (map['fullName'] ?? map['name'] ?? '').toString().trim();

    final resolvedFirstName = firstName.isNotEmpty
        ? firstName
        : _splitLegacyFullName(legacyFullName).$1;
    final resolvedLastName = lastName.isNotEmpty
        ? lastName
        : _splitLegacyFullName(legacyFullName).$2;

    final createdAtValue = map['createdAt'];
    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    }

    return UserModel(
      uid: (id ?? map['uid'] ?? '').toString(),
      firstName: resolvedFirstName,
      lastName: resolvedLastName,
      email: (map['email'] ?? '').toString(),
      schoolId: (map['schoolId'] ?? '').toString(),
      role: (map['role'] ?? AccountRole.student.label).toString(),
      departmentOrSection: (map['departmentOrSection'] ?? '').toString(),
      status: (map['status'] ?? 'Active').toString(),
      createdAt: createdAt,
    );
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? schoolId,
    String? role,
    String? departmentOrSection,
    String? status,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      departmentOrSection: departmentOrSection ?? this.departmentOrSection,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static (String, String) _splitLegacyFullName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }
}
