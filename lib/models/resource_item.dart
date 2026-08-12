import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.itemName,
    required this.itemCode,
    required this.mainCategory,
    required this.subCategory,
    required this.itemType,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.description,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String itemName;
  final String itemCode;
  final String mainCategory;
  final String subCategory;
  final String itemType;
  final int totalQuantity;
  final int availableQuantity;
  final String description;
  final String? imageUrl;
  final DateTime? createdAt;

  /// Legacy aliases used by borrower screens.
  String get name => itemName;
  String get code => itemCode;
  String get assetPath => imageUrl ?? '';
  int get borrowedQuantity =>
      (totalQuantity - availableQuantity).clamp(0, totalQuantity);

  bool get isAvailable => availableQuantity > 0;

  IconData get fallbackIcon => ResourceTaxonomy.iconForMainCategory(mainCategory);

  factory ResourceItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtValue = data['createdAt'];
    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    }

    return ResourceItem(
      id: doc.id,
      itemName: (data['itemName'] ?? data['name'] ?? '').toString(),
      itemCode: (data['itemCode'] ?? data['code'] ?? '').toString(),
      mainCategory: ResourceTaxonomy.normalizeMainCategory(
        data['mainCategory']?.toString(),
      ),
      subCategory: (data['subCategory'] ?? '').toString(),
      itemType: (data['itemType'] ?? '').toString(),
      totalQuantity: _asInt(data['totalQuantity'], fallback: 1),
      availableQuantity: _asInt(data['availableQuantity'], fallback: 1),
      description: (data['description'] ?? '').toString(),
      imageUrl: data['imageUrl']?.toString(),
      createdAt: createdAt,
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

/// Category taxonomy and lookup helpers for filters and forms.
class ResourceTaxonomy {
  ResourceTaxonomy._();

  static const String filterAll = 'All';

  static const String mainCategoryGeneralLearning = 'General Learning';
  static const String mainCategoryIct = 'ICT';
  static const String mainCategoryTvl = 'TVL';

  static const List<String> mainCategories = [
    mainCategoryGeneralLearning,
    mainCategoryIct,
    mainCategoryTvl,
  ];

  // Sub-Categories for General Learning
  static const String generalLearning = 'General Learning';
  static const String scienceLab = 'Science Lab';
  static const String mathematics = 'Mathematics';
  static const String audioVisual = 'Audio-Visual';
  static const String sports = 'Sports';
  static const String artsDesign = 'Arts & Design';

  // Sub-Categories for ICT
  static const String generalInfrastructure = 'General & Infrastructure';
  static const String vocationalTechnicalTools = 'Vocational & Technical Tools';

  // Sub-Categories for TVL
  static const String homeEconomics = 'Home Economics';
  static const String industrialArts = 'Industrial Arts';
  static const String agriFisheryArts = 'Agri-Fishery Arts';

  static String normalizeMainCategory(String? value) {
    final normalized = (value ?? '').trim();
    switch (normalized.toLowerCase()) {
      case 'general learning':
      case 'general learning resources':
        return mainCategoryGeneralLearning;
      case 'ict':
      case 'ict resources':
        return mainCategoryIct;
      case 'tvl':
      case 'tvl resources':
        return mainCategoryTvl;
      default:
        return normalized.isEmpty ? mainCategoryGeneralLearning : normalized;
    }
  }

  static IconData iconForMainCategory(String mainCategory) {
    switch (normalizeMainCategory(mainCategory)) {
      case mainCategoryIct:
        return Icons.computer_outlined;
      case mainCategoryTvl:
        return Icons.engineering_outlined;
      case mainCategoryGeneralLearning:
      default:
        return Icons.menu_book_outlined;
    }
  }

  static List<String> subCategoriesFor(String mainCategory) {
    switch (normalizeMainCategory(mainCategory)) {
      case mainCategoryGeneralLearning:
        return const [
          generalLearning,
          scienceLab,
          mathematics,
          audioVisual,
          sports,
          artsDesign,
        ];
      case mainCategoryIct:
        return const [generalInfrastructure, vocationalTechnicalTools];
      case mainCategoryTvl:
        return const [homeEconomics, industrialArts, agriFisheryArts];
      default:
        return const [];
    }
  }

  static List<String> filterSubCategories(String mainCategory) {
    if (mainCategory == filterAll) {
      return [
        filterAll,
        generalLearning,
        scienceLab,
        mathematics,
        audioVisual,
        sports,
        artsDesign,
        generalInfrastructure,
        vocationalTechnicalTools,
        homeEconomics,
        industrialArts,
        agriFisheryArts,
      ];
    }
    return [filterAll, ...subCategoriesFor(mainCategory)];
  }

  static List<String> itemTypesForSubCategory(String subCategory) {
    switch (subCategory) {
      case generalLearning:
        return generalLearningItemTypes;
      case scienceLab:
        return scienceLabItemTypes;
      case mathematics:
        return mathematicsItemTypes;
      case audioVisual:
        return audioVisualItemTypes;
      case sports:
        return sportsItemTypes;
      case artsDesign:
        return artsDesignItemTypes;
      case generalInfrastructure:
        return generalInfrastructureItemTypes;
      case vocationalTechnicalTools:
        return vocationalTechnicalItemTypes;
      case homeEconomics:
        return homeEconomicsItemTypes;
      case industrialArts:
        return industrialArtsItemTypes;
      case agriFisheryArts:
        return agriFisheryArtsItemTypes;
      default:
        return const [];
    }
  }

  static List<String> filterItemTypes({
    required String mainCategory,
    required String subCategory,
  }) {
    if (subCategory != filterAll) {
      return [filterAll, ...itemTypesForSubCategory(subCategory)];
    }

    if (mainCategory == filterAll) {
      return [
        filterAll,
        ...generalLearningItemTypes,
        ...scienceLabItemTypes,
        ...mathematicsItemTypes,
        ...audioVisualItemTypes,
        ...sportsItemTypes,
        ...artsDesignItemTypes,
        ...generalInfrastructureItemTypes,
        ...vocationalTechnicalItemTypes,
        ...homeEconomicsItemTypes,
        ...industrialArtsItemTypes,
        ...agriFisheryArtsItemTypes,
      ];
    }

    final subCats = subCategoriesFor(mainCategory);
    final types = <String>{};
    for (final sub in subCats) {
      types.addAll(itemTypesForSubCategory(sub));
    }
    return [filterAll, ...types];
  }
}

// Legacy sub-category aliases for existing screens.
const String generalLearning = ResourceTaxonomy.generalLearning;
const String scienceLab = ResourceTaxonomy.scienceLab;
const String mathematics = ResourceTaxonomy.mathematics;
const String audioVisual = ResourceTaxonomy.audioVisual;
const String sports = ResourceTaxonomy.sports;
const String artsDesign = ResourceTaxonomy.artsDesign;
const String generalInfrastructure = ResourceTaxonomy.generalInfrastructure;
const String vocationalTechnicalTools = ResourceTaxonomy.vocationalTechnicalTools;
const String homeEconomics = ResourceTaxonomy.homeEconomics;
const String industrialArts = ResourceTaxonomy.industrialArts;
const String agriFisheryArts = ResourceTaxonomy.agriFisheryArts;

// Legacy aliases for borrower screens.
const String generalLearningResources = ResourceTaxonomy.mainCategoryGeneralLearning;
const String ictResources = ResourceTaxonomy.mainCategoryIct;
const String tvlResources = ResourceTaxonomy.mainCategoryTvl;

const List<String> generalLearningItemTypes = [
  'Textbooks',
  'Library Books',
  'Reference Books',
  "Teacher's Guides",
  'Self-Learning Modules',
  'Workbooks',
  'Flashcards & Reading Charts',
  'Diagnostic Test Booklets',
];

const List<String> scienceLabItemTypes = [
  'Biology Equipment',
  'Chemistry Equipment',
  'Physics Equipment',
  'Laboratory Glassware',
  'Safety Equipment',
  'Chemical Storage Cabinets',
  'Anatomical Models & 3D Molecular Charts',
  'Fire Extinguishers & First Aid Kits',
];

const List<String> mathematicsItemTypes = [
  'Scientific Calculators',
  'Geometry Sets',
  'Measuring Instruments',
  'Mathematical Manipulatives',
  'Large Blackboard Demonstration Tools',
];

const List<String> audioVisualItemTypes = [
  'Television',
  'Speakers',
  'Microphones',
  'Cameras',
  'Audio Equipment & Consoles',
];

const List<String> sportsItemTypes = [
  'Balls',
  'Training Gear',
  'Fitness Equipment',
  'Protective Equipment',
  'Officiating Gear',
  'Field Marking Equipment',
  'Sports First Aid & Rehabilitation Kits',
];

const List<String> artsDesignItemTypes = [
  'Musical Instruments',
  'Painting Materials',
  'Drawing Materials',
  'Digital Art Tools',
  'Drafting Tables & Lightboxes',
  'Artwork Drying Racks',
];

const List<String> generalInfrastructureItemTypes = [
  'Desktop Computers',
  'Laptops',
  'Tablets',
  'Printers',
  'Projectors',
  'Interactive Displays',
  'Networking Devices',
  'UPS',
  'Server Racks & Managed Switches',
];

const List<String> vocationalTechnicalItemTypes = [
  'Networking Tools',
  'Computer Hardware Kits',
  'Electronics Kits',
];

const List<String> homeEconomicsItemTypes = [
  'Sewing Machines',
  'Cooking Equipment',
  'Baking Equipment',
  'Kitchen Utensils',
  'Large Kitchen Appliances',
  'Dining Ware',
  'Housekeeping & Caregiving Equipment',
];

const List<String> industrialArtsItemTypes = [
  'Carpentry Tools',
  'Electrical Tools',
  'Welding Equipment',
  'Plumbing Tools',
  'Heavy Power Tools',
  'Automotive Diagnostic Tools',
  'Workshop PPE',
];

const List<String> agriFisheryArtsItemTypes = [
  'Gardening Tools',
  'Farming Equipment',
  'Aquaculture Equipment',
  'Water Testing Kits',
  'Post-Harvest Processing Tools',
  'Agricultural Safety Wear',
];

List<String> getItemTypesForSubCategory(String subCategory) {
  return ResourceTaxonomy.itemTypesForSubCategory(subCategory);
}
