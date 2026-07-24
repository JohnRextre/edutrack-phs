enum AccountRole { student, teacher, propertyCustodian, ictCoordinator }

extension AccountRoleLabel on AccountRole {
  String get label {
    switch (this) {
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

  bool get isBorrower =>
      this == AccountRole.student || this == AccountRole.teacher;
}
