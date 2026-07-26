import 'package:flutter/material.dart';

class ResourceItem {
  const ResourceItem({
    required this.name,
    required this.code,
    required this.mainCategory,
    required this.subCategory,
    required this.itemType,
    required this.description,
    required this.assetPath,
    required this.fallbackIcon,
    this.totalQuantity = 1,
    this.availableQuantity = 1,
    this.borrowedQuantity = 0,
  });

  final String name;
  final String code;
  final String mainCategory;
  final String subCategory;
  final String itemType;
  final String description;
  final String assetPath;
  final IconData fallbackIcon;
  final int totalQuantity;
  final int availableQuantity;
  final int borrowedQuantity;

  bool get isAvailable => availableQuantity > 0;
}

// Main Categories
const String generalLearningResources = 'General Learning Resources';
const String ictResources = 'ICT Resources';
const String tvlResources = 'TVL Resources';

// Sub-Categories for General Learning Resources
const String generalLearning = 'General Learning';
const String scienceLab = 'Science Lab';
const String mathematics = 'Mathematics';
const String audioVisual = 'Audio-Visual';
const String sports = 'Sports';
const String artsDesign = 'Arts & Design';

// Sub-Categories for ICT Resources
const String generalInfrastructure = 'General & Infrastructure';
const String vocationalTechnicalTools = 'Vocational & Technical Tools';

// Sub-Categories for TVL Resources
const String homeEconomics = 'Home Economics';
const String industrialArts = 'Industrial Arts';
const String agriFisheryArts = 'Agri-Fishery Arts';

// Tier 3: Item Types for General Learning Resources
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

// Tier 3: Item Types for ICT Resources
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

// Tier 3: Item Types for TVL Resources
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

// Helper function to get item types based on sub-category
List<String> getItemTypesForSubCategory(String subCategory) {
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
      return [];
  }
}

// Resource items data
List<ResourceItem> allResourceItems = [
  // Biology Microscope (General Learning Resources -> Science Laboratory)
  ResourceItem(
    name: 'Biology Microscope',
    code: 'GLR-BIO-001',
    mainCategory: generalLearningResources,
    subCategory: scienceLab,
    itemType: 'Biology Equipment',
    description: 'High-quality biological microscope for laboratory use.',
    assetPath: 'lib/assets/borrowed_assets/Biology Microscope.png',
    fallbackIcon: Icons.biotech_outlined,
    totalQuantity: 10,
    availableQuantity: 7,
    borrowedQuantity: 3,
  ),

  // Dell Laptop (ICT Resources -> General & Infrastructure Equipment)
  ResourceItem(
    name: 'Dell Laptop',
    code: 'ICT-LPT-001',
    mainCategory: ictResources,
    subCategory: generalInfrastructure,
    itemType: 'Laptops',
    description: 'Dell laptop computer for student and teacher use.',
    assetPath: 'lib/assets/borrowed_assets/Dell Laptop.png',
    fallbackIcon: Icons.laptop_mac_outlined,
    totalQuantity: 15,
    availableQuantity: 12,
    borrowedQuantity: 3,
  ),
];
