import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/section_model.dart';

class SectionService {
  SectionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'sections';

  CollectionReference<Map<String, dynamic>> get _sections =>
      _firestore.collection(collection);

  Stream<List<SectionModel>> watchActiveSections() {
    return _sections.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(SectionModel.fromFirestore)
              .where((section) => section.isActive)
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName)),
    );
  }

  Stream<List<SectionModel>> watchAllSections() {
    return _sections.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(SectionModel.fromFirestore).toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName)),
    );
  }

  Future<void> saveSection({
    String? id,
    required String name,
    required String gradeLevel,
    required int maxActiveBorrowQuantity,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    final trimmedGrade = gradeLevel.trim();
    final gradeNumber = int.tryParse(trimmedGrade);
    if (trimmedName.isEmpty || maxActiveBorrowQuantity < 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-section',
        message: 'Enter a section name and a limit greater than zero.',
      );
    }
    if (gradeNumber == null || gradeNumber < 1 || gradeNumber > 12) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-grade-level',
        message: 'Grade level must be a whole number from 1 to 12.',
      );
    }
    final ref = id == null || id.trim().isEmpty
        ? _sections.doc()
        : _sections.doc(id.trim());
    await ref.set({
      'name': trimmedName,
      'gradeLevel': trimmedGrade,
      'maxActiveBorrowQuantity': maxActiveBorrowQuantity,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setSectionStatus({
    required String id,
    required bool isActive,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (!isActive && trimmedReason.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-status-reason',
        message: 'Please provide a reason for setting the section inactive.',
      );
    }
    final sectionId = id.trim();
    final sectionSnap = await _sections.doc(sectionId).get();
    final sectionData = sectionSnap.data() ?? {};
    final sectionName = [sectionData['gradeLevel'], sectionData['name']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' - ');
    final assignedTeachers = _assignedTeachers(sectionData);
    final users = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    batch.update(_sections.doc(sectionId), {
      'isActive': isActive,
      'isDeleted': false,
      'inactiveReason': isActive ? '' : trimmedReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!isActive) {
      for (final user in users.docs) {
        final data = user.data();
        final assignedIds = data['assignedSectionIds'] is Iterable
            ? (data['assignedSectionIds'] as Iterable)
                  .map((value) => value.toString())
                  .toList()
            : <String>[];
        final affected =
            data['sectionId']?.toString() == sectionId ||
            assignedIds.contains(sectionId) ||
            assignedTeachers.any(
              (teacher) => teacher['id']?.toString() == user.id,
            );
        if (!affected) continue;
        batch.update(user.reference, {
          'sectionStatusNotices': FieldValue.arrayUnion([
            {
              'sectionId': sectionId,
              'sectionName': sectionName,
              'status': 'Inactive',
              'reason': trimmedReason,
              'createdAt': Timestamp.now(),
            },
          ]),
        });
      }
    }
    await batch.commit();
  }

  Future<void> deleteSection({
    required String id,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-status-reason',
        message: 'Please provide a reason for deleting the section.',
      );
    }
    final sectionRef = _sections.doc(id.trim());
    final sectionSnap = await sectionRef.get();
    final sectionData = sectionSnap.data() ?? {};
    final sectionName = [sectionData['gradeLevel'], sectionData['name']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' - ');
    final assignedTeachers = _assignedTeachers(sectionData);
    final users = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    batch.update(sectionRef, {
      'isActive': false,
      'isDeleted': true,
      'inactiveReason': trimmedReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final user in users.docs) {
      final data = user.data();
      final assignedIds = data['assignedSectionIds'] is Iterable
          ? (data['assignedSectionIds'] as Iterable)
                .map((value) => value.toString())
                .toList()
          : <String>[];
      final isStudent = data['sectionId']?.toString() == id.trim();
      final isTeacher =
          assignedIds.contains(id.trim()) ||
          assignedTeachers.any(
            (teacher) => teacher['id']?.toString() == user.id,
          );
      if (!isStudent && !isTeacher) continue;
      batch.update(user.reference, {
        'sectionStatusNotices': FieldValue.arrayUnion([
          {
            'sectionId': id.trim(),
            'sectionName': sectionName,
            'status': 'Deleted',
            'reason': trimmedReason,
            'createdAt': Timestamp.now(),
          },
        ]),
      });
    }
    await batch.commit();
  }

  List<Map<String, dynamic>> _assignedTeachers(Map<String, dynamic>? data) {
    final value = data?['assignedTeachers'];
    if (value is! Iterable) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> assignTeacher({
    required String sectionId,
    required String teacherId,
    required String teacherName,
  }) async {
    final sectionRef = _sections.doc(sectionId.trim());
    final teacherRef = _firestore.collection('users').doc(teacherId.trim());
    final sectionSnap = await sectionRef.get();
    final sectionData = sectionSnap.data();
    if (sectionData == null ||
        sectionData['isActive'] == false ||
        sectionData['isDeleted'] == true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'inactive-section',
        message: 'This section is inactive and cannot receive a teacher.',
      );
    }
    final teachers = _assignedTeachers(sectionSnap.data());
    if (teachers.any((teacher) => teacher['id'] == teacherId.trim())) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'teacher-already-assigned',
        message: 'This teacher is already assigned to the section.',
      );
    }
    final assignment = {'id': teacherId.trim(), 'name': teacherName.trim()};
    final batch = _firestore.batch();
    batch.update(sectionRef, {
      'assignedTeachers': [...teachers, assignment],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(teacherRef, {
      'assignedSectionIds': FieldValue.arrayUnion([sectionId.trim()]),
    });
    await batch.commit();
  }

  Future<void> removeTeacher({
    required String sectionId,
    required String sectionName,
    required String teacherId,
    required String reason,
  }) async {
    final sectionRef = _sections.doc(sectionId.trim());
    final teacherRef = _firestore.collection('users').doc(teacherId.trim());
    final sectionSnap = await sectionRef.get();
    final teachers = _assignedTeachers(sectionSnap.data())
      ..removeWhere((teacher) => teacher['id'] == teacherId);
    final batch = _firestore.batch();
    batch.update(sectionRef, {
      'assignedTeachers': teachers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(teacherRef, {
      'assignedSectionIds': FieldValue.arrayRemove([sectionId.trim()]),
      'sectionRemovalNotices': FieldValue.arrayUnion([
        {
          'sectionId': sectionId.trim(),
          'sectionName': sectionName.trim(),
          'reason': reason.trim(),
          'createdAt': Timestamp.now(),
        },
      ]),
    });
    await batch.commit();
  }

  Future<void> leaveSection({
    required String sectionId,
    required String teacherId,
  }) async {
    final sectionRef = _sections.doc(sectionId.trim());
    final teacherRef = _firestore.collection('users').doc(teacherId.trim());
    final sectionSnap = await sectionRef.get();
    final teachers = _assignedTeachers(sectionSnap.data())
      ..removeWhere((teacher) => teacher['id'] == teacherId);
    final batch = _firestore.batch();
    batch.update(sectionRef, {
      'assignedTeachers': teachers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(teacherRef, {
      'assignedSectionIds': FieldValue.arrayRemove([sectionId.trim()]),
    });
    await batch.commit();
  }
}
