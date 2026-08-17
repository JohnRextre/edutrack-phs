import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resource_item.dart';

/// Firestore-backed CRUD for the `resources` collection.
class ResourceService {
  ResourceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'resources';

  CollectionReference<Map<String, dynamic>> get _resources =>
      _firestore.collection(collection);

  /// Live stream of all resources, sorted by name client-side.
  Stream<List<ResourceItem>> watchResources() {
    return _resources.snapshots().map((snapshot) {
      final items = snapshot.docs.map(ResourceItem.fromFirestore).toList();
      items.sort(
        (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
      );
      return items;
    });
  }

  Future<void> createResource({
    required String itemName,
    required String itemCode,
    required String mainCategory,
    required String subCategory,
    required String itemType,
    required int totalQuantity,
    required int availableQuantity,
    required int maxBorrowLimit,
    required String description,
    String? imageUrl,
  }) async {
    final trimmedName = itemName.trim();
    final trimmedCode = itemCode.trim();

    _validateResourceFields(
      itemName: trimmedName,
      itemCode: trimmedCode,
      mainCategory: mainCategory,
      subCategory: subCategory,
      itemType: itemType,
      totalQuantity: totalQuantity,
      availableQuantity: availableQuantity,
      maxBorrowLimit: maxBorrowLimit,
    );

    if (await itemCodeExists(trimmedCode)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'duplicate-item-code',
        message: 'An item with Asset Code "$trimmedCode" already exists.',
      );
    }

    await _resources.add({
      'itemName': trimmedName,
      'itemCode': trimmedCode,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'itemType': itemType,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'maxBorrowLimit': maxBorrowLimit,
      'description': description.trim(),
      'imageUrl': imageUrl?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateResource({
    required String id,
    required String itemName,
    required String itemCode,
    required String mainCategory,
    required String subCategory,
    required String itemType,
    required int totalQuantity,
    required int availableQuantity,
    required int maxBorrowLimit,
    required String description,
    String? imageUrl,
  }) async {
    final trimmedId = id.trim();
    final trimmedName = itemName.trim();
    final trimmedCode = itemCode.trim();

    if (trimmedId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Resource id is missing.',
      );
    }

    _validateResourceFields(
      itemName: trimmedName,
      itemCode: trimmedCode,
      mainCategory: mainCategory,
      subCategory: subCategory,
      itemType: itemType,
      totalQuantity: totalQuantity,
      availableQuantity: availableQuantity,
      maxBorrowLimit: maxBorrowLimit,
    );

    if (await itemCodeExists(trimmedCode, excludeId: trimmedId)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'duplicate-item-code',
        message: 'An item with Asset Code "$trimmedCode" already exists.',
      );
    }

    await _resources.doc(trimmedId).update({
      'itemName': trimmedName,
      'itemCode': trimmedCode,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'itemType': itemType,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'maxBorrowLimit': maxBorrowLimit,
      'description': description.trim(),
      'imageUrl': imageUrl?.trim() ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResource(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-id',
        message: 'Resource id is missing.',
      );
    }
    await _resources.doc(trimmedId).delete();
  }

  Future<ResourceItem?> getResourceById(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return null;

    final doc = await _resources.doc(trimmedId).get();
    if (!doc.exists) return null;
    return ResourceItem.fromMap(doc.id, doc.data()!);
  }

  Future<bool> itemCodeExists(String itemCode, {String? excludeId}) async {
    final normalized = itemCode.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final snapshot = await _resources
        .where('itemCode', isEqualTo: itemCode.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;
    if (excludeId != null && snapshot.docs.first.id == excludeId) {
      return false;
    }
    return true;
  }

  static String friendlyErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'duplicate-item-code':
        case 'invalid-name':
        case 'invalid-code':
        case 'invalid-category':
        case 'invalid-quantity':
          return error.message ?? 'Please check the resource details.';
        default:
          return error.message ?? 'Unable to save the resource. Please try again.';
      }
    }
    return error.toString();
  }

  void _validateResourceFields({
    required String itemName,
    required String itemCode,
    required String mainCategory,
    required String subCategory,
    required String itemType,
    required int totalQuantity,
    required int availableQuantity,
    required int maxBorrowLimit,
  }) {
    if (itemName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-name',
        message: 'Item name is required.',
      );
    }
    if (itemCode.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-code',
        message: 'Item code / asset tag is required.',
      );
    }
    if (!ResourceTaxonomy.mainCategories.contains(mainCategory)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-category',
        message: 'Please select a valid main category.',
      );
    }
    if (subCategory.isEmpty || itemType.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-category',
        message: 'Please select a sub-category and item type.',
      );
    }
    if (totalQuantity < 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-quantity',
        message: 'Total quantity must be at least 1.',
      );
    }
    if (availableQuantity < 0 || availableQuantity > totalQuantity) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-quantity',
        message: 'Available quantity must be between 0 and total quantity.',
      );
    }
    if (maxBorrowLimit < 1 || maxBorrowLimit > totalQuantity) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-quantity',
        message:
            'Max borrow limit must be greater than 0 and not exceed total quantity.',
      );
    }
  }
}
