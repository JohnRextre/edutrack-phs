import 'package:cloud_firestore/cloud_firestore.dart';

class SectionModel {
  const SectionModel({
    required this.id,
    required this.name,
    required this.maxActiveBorrowQuantity,
    this.currentActiveBorrowQuantity = 0,
    this.assignedTeachers = const [],
    this.gradeLevel = '',
    this.isActive = true,
    this.isDeleted = false,
    this.inactiveReason = '',
  });

  final String id;
  final String name;
  final int maxActiveBorrowQuantity;
  final int currentActiveBorrowQuantity;
  final List<Map<String, dynamic>> assignedTeachers;
  final String gradeLevel;
  final bool isActive;
  final bool isDeleted;
  final String inactiveReason;

  String get displayName =>
      gradeLevel.trim().isEmpty ? name : '$gradeLevel - $name';

  factory SectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawLimit = data['maxActiveBorrowQuantity'];
    final rawCurrent = data['currentActiveBorrowQuantity'];
    return SectionModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      gradeLevel: (data['gradeLevel'] ?? '').toString(),
      maxActiveBorrowQuantity: rawLimit is num
          ? rawLimit.toInt()
          : int.tryParse(rawLimit?.toString() ?? '') ?? 0,
      currentActiveBorrowQuantity: rawCurrent is num
          ? rawCurrent.toInt()
          : int.tryParse(rawCurrent?.toString() ?? '') ?? 0,
      assignedTeachers: (data['assignedTeachers'] is Iterable)
          ? (data['assignedTeachers'] as Iterable)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
      isActive: data['isActive'] != false,
      isDeleted: data['isDeleted'] == true,
      inactiveReason: (data['inactiveReason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'gradeLevel': gradeLevel.trim(),
    'maxActiveBorrowQuantity': maxActiveBorrowQuantity,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
