import 'package:flutter_test/flutter_test.dart';
import 'package:edutrack_phs/models/resource_item.dart';

void main() {
  group('ResourceItem model tests', () {
    test('serializes and deserializes storageLocation properly', () {
      final item = ResourceItem(
        id: 'res-1',
        itemName: 'Microscope',
        itemCode: 'SCI-001',
        mainCategory: ResourceTaxonomy.mainCategoryGeneralLearning,
        subCategory: ResourceTaxonomy.scienceLab,
        itemType: 'Biology Equipment',
        totalQuantity: 10,
        availableQuantity: 8,
        maxBorrowLimit: 2,
        storageLocation: 'Room 123 - Cabinet B',
        description: 'High precision microscope',
      );

      final map = item.toMap();
      expect(map['storageLocation'], 'Room 123 - Cabinet B');
      expect(map['itemName'], 'Microscope');

      final fromMapItem = ResourceItem.fromMap('res-1', map);
      expect(fromMapItem.storageLocation, 'Room 123 - Cabinet B');
      expect(fromMapItem.itemName, 'Microscope');
      expect(fromMapItem.availableQuantity, 8);
    });

    test('supports fallback for location key', () {
      final legacyMap = {
        'itemName': 'Laptop',
        'itemCode': 'ICT-001',
        'mainCategory': 'ICT',
        'subCategory': 'General & Infrastructure',
        'itemType': 'Laptops',
        'quantity': 5,
        'location': 'ICT Hub Room 204',
      };

      final item = ResourceItem.fromMap('res-2', legacyMap);
      expect(item.storageLocation, 'ICT Hub Room 204');
      expect(item.maxBorrowDays, 7);
      expect(item.totalQuantity, 5);
      expect(item.availableQuantity, 5);
    });

    test('serializes and deserializes custom maxBorrowDays properly', () {
      final item = ResourceItem(
        id: 'res-3',
        itemName: 'Projector',
        itemCode: 'ICT-002',
        mainCategory: ResourceTaxonomy.mainCategoryIct,
        subCategory: ResourceTaxonomy.generalInfrastructure,
        itemType: 'Projectors',
        totalQuantity: 3,
        availableQuantity: 3,
        maxBorrowLimit: 1,
        maxBorrowDays: 3,
        storageLocation: 'AV Room',
        description: 'HDMI Projector',
      );

      final map = item.toMap();
      expect(map['maxBorrowDays'], 3);

      final fromMapItem = ResourceItem.fromMap('res-3', map);
      expect(fromMapItem.maxBorrowDays, 3);
      expect(fromMapItem.storageLocation, 'AV Room');
    });
  });
}
