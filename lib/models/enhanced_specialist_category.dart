import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенные категории специалистов
enum EnhancedSpecialistCategory {
  // Существующие категории
  photography,
  videography,
  music,
  catering,
  decoration,
  
  // Новые категории
  fireShow,        // Фаер-шоу
  florist,         // Флористы
  contentCreator,  // Контент-мейкеры
  photoStudio,     // Фотостудии
  dj,              // DJ
  animator,        // Аниматоры
  makeupArtist,    // Визажисты
  stylist,         // Стилисты
  security,        // Охрана
  transport,       // Транспорт
  equipment,       // Оборудование
  entertainment,   // Развлечения
  wellness,        // Wellness
  education,       // Образование
  business,        // Бизнес-услуги
}

/// Модель расширенной категории специалиста
class EnhancedSpecialistCategoryModel {
  const EnhancedSpecialistCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
    this.subcategories = const [],
    this.averagePriceRange,
    this.popularTags = const [],
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String displayName;
  final String description;
  final String icon;
  final String color;
  final List<String> subcategories;
  final PriceRange? averagePriceRange;
  final List<String> popularTags;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Создать из документа Firestore
  factory EnhancedSpecialistCategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EnhancedSpecialistCategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? '',
      color: data['color'] as String? ?? '',
      subcategories: List<String>.from(data['subcategories'] ?? []),
      averagePriceRange: data['averagePriceRange'] != null
          ? PriceRange.fromMap(data['averagePriceRange'] as Map<String, dynamic>)
          : null,
      popularTags: List<String>.from(data['popularTags'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'displayName': displayName,
    'description': description,
    'icon': icon,
    'color': color,
    'subcategories': subcategories,
    'averagePriceRange': averagePriceRange?.toMap(),
    'popularTags': popularTags,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Получить русское название категории
  String get russianName {
    switch (name.toLowerCase()) {
      case 'photography':
        return 'Фотография';
      case 'videography':
        return 'Видеосъемка';
      case 'music':
        return 'Музыка';
      case 'catering':
        return 'Кейтеринг';
      case 'decoration':
        return 'Декор';
      case 'fireshow':
        return 'Фаер-шоу';
      case 'florist':
        return 'Флористы';
      case 'contentcreator':
        return 'Контент-мейкеры';
      case 'photostudio':
        return 'Фотостудии';
      case 'dj':
        return 'DJ';
      case 'animator':
        return 'Аниматоры';
      case 'makeupartist':
        return 'Визажисты';
      case 'stylist':
        return 'Стилисты';
      case 'security':
        return 'Охрана';
      case 'transport':
        return 'Транспорт';
      case 'equipment':
        return 'Оборудование';
      case 'entertainment':
        return 'Развлечения';
      case 'wellness':
        return 'Wellness';
      case 'education':
        return 'Образование';
      case 'business':
        return 'Бизнес-услуги';
      default:
        return displayName;
    }
  }
}

/// Диапазон цен
class PriceRange {
  const PriceRange({
    required this.min,
    required this.max,
    required this.currency,
  });

  final double min;
  final double max;
  final String currency;

  /// Создать из Map
  factory PriceRange.fromMap(Map<String, dynamic> data) => PriceRange(
    min: (data['min'] as num).toDouble(),
    max: (data['max'] as num).toDouble(),
    currency: data['currency'] as String? ?? 'RUB',
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'min': min,
    'max': max,
    'currency': currency,
  };

  /// Получить среднюю цену
  double get average => (min + max) / 2;

  /// Проверить, попадает ли цена в диапазон
  bool contains(double price) => price >= min && price <= max;
}
