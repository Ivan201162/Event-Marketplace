import 'package:cloud_firestore/cloud_firestore.dart';

/// Категории специалистов
enum SpecialistCategory {
  photographer,    // Фотограф
  videographer,    // Видеограф
  dj,             // DJ
  host,           // Ведущий
  decorator,      // Декоратор
  musician,       // Музыкант
  caterer,        // Кейтеринг
  security,       // Охрана
  technician,     // Техник
  other,          // Другое
}

/// Уровень опыта специалиста
enum ExperienceLevel {
  beginner,       // Начинающий
  intermediate,   // Средний
  advanced,       // Продвинутый
  expert,         // Эксперт
}

/// Модель специалиста
class Specialist {
  final String id;
  final String userId; // Связь с пользователем
  final String name;
  final String? description;
  final SpecialistCategory category;
  final List<String> subcategories; // Подкатегории
  final ExperienceLevel experienceLevel;
  final int yearsOfExperience;
  final double hourlyRate;
  final double? minBookingHours;
  final double? maxBookingHours;
  final List<String> serviceAreas; // Географические области
  final List<String> languages; // Языки
  final List<String> equipment; // Оборудование
  final List<String> portfolio; // Ссылки на портфолио
  final Map<String, dynamic>? contactInfo;
  final Map<String, dynamic>? businessInfo;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Specialist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.category,
    this.subcategories = const [],
    required this.experienceLevel,
    required this.yearsOfExperience,
    required this.hourlyRate,
    this.minBookingHours,
    this.maxBookingHours,
    this.serviceAreas = const [],
    this.languages = const [],
    this.equipment = const [],
    this.portfolio = const [],
    this.contactInfo,
    this.businessInfo,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Specialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      category: _parseCategory(data['category']),
      subcategories: List<String>.from(data['subcategories'] ?? []),
      experienceLevel: _parseExperienceLevel(data['experienceLevel']),
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
      minBookingHours: data['minBookingHours']?.toDouble(),
      maxBookingHours: data['maxBookingHours']?.toDouble(),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      portfolio: List<String>.from(data['portfolio'] ?? []),
      contactInfo: data['contactInfo'],
      businessInfo: data['businessInfo'],
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      metadata: data['metadata'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'category': category.name,
      'subcategories': subcategories,
      'experienceLevel': experienceLevel.name,
      'yearsOfExperience': yearsOfExperience,
      'hourlyRate': hourlyRate,
      'minBookingHours': minBookingHours,
      'maxBookingHours': maxBookingHours,
      'serviceAreas': serviceAreas,
      'languages': languages,
      'equipment': equipment,
      'portfolio': portfolio,
      'contactInfo': contactInfo,
      'businessInfo': businessInfo,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Копировать с изменениями
  Specialist copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    SpecialistCategory? category,
    List<String>? subcategories,
    ExperienceLevel? experienceLevel,
    int? yearsOfExperience,
    double? hourlyRate,
    double? minBookingHours,
    double? maxBookingHours,
    List<String>? serviceAreas,
    List<String>? languages,
    List<String>? equipment,
    List<String>? portfolio,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? businessInfo,
    bool? isAvailable,
    bool? isVerified,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Specialist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategories: subcategories ?? this.subcategories,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      minBookingHours: minBookingHours ?? this.minBookingHours,
      maxBookingHours: maxBookingHours ?? this.maxBookingHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      languages: languages ?? this.languages,
      equipment: equipment ?? this.equipment,
      portfolio: portfolio ?? this.portfolio,
      contactInfo: contactInfo ?? this.contactInfo,
      businessInfo: businessInfo ?? this.businessInfo,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Получить отображаемое название категории
  String get categoryDisplayName {
    switch (category) {
      case SpecialistCategory.photographer:
        return 'Фотограф';
      case SpecialistCategory.videographer:
        return 'Видеограф';
      case SpecialistCategory.dj:
        return 'DJ';
      case SpecialistCategory.host:
        return 'Ведущий';
      case SpecialistCategory.decorator:
        return 'Декоратор';
      case SpecialistCategory.musician:
        return 'Музыкант';
      case SpecialistCategory.caterer:
        return 'Кейтеринг';
      case SpecialistCategory.security:
        return 'Охрана';
      case SpecialistCategory.technician:
        return 'Техник';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

  /// Получить отображаемый уровень опыта
  String get experienceLevelDisplayName {
    switch (experienceLevel) {
      case ExperienceLevel.beginner:
        return 'Начинающий';
      case ExperienceLevel.intermediate:
        return 'Средний';
      case ExperienceLevel.advanced:
        return 'Продвинутый';
      case ExperienceLevel.expert:
        return 'Эксперт';
    }
  }

  /// Получить диапазон цен
  String get priceRange {
    if (minBookingHours != null && maxBookingHours != null) {
      final minPrice = hourlyRate * minBookingHours!;
      final maxPrice = hourlyRate * maxBookingHours!;
      return '${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} ₽';
    }
    return '${hourlyRate.toStringAsFixed(0)} ₽/час';
  }

  /// Проверить, доступен ли специалист в указанную дату
  bool isAvailableOnDate(DateTime date) {
    if (!isAvailable) return false;
    // Здесь можно добавить логику проверки расписания
    return true;
  }

  /// Проверить, доступен ли специалист в указанную дату и время
  bool isAvailableOnDateTime(DateTime dateTime) {
    if (!isAvailable) return false;
    // Здесь можно добавить логику проверки расписания
    return true;
  }

  /// Получить иконку для категории
  String get categoryIcon {
    switch (category) {
      case SpecialistCategory.photographer:
        return '📸';
      case SpecialistCategory.videographer:
        return '🎥';
      case SpecialistCategory.dj:
        return '🎧';
      case SpecialistCategory.host:
        return '🎤';
      case SpecialistCategory.decorator:
        return '🎨';
      case SpecialistCategory.musician:
        return '🎵';
      case SpecialistCategory.caterer:
        return '🍽️';
      case SpecialistCategory.security:
        return '🛡️';
      case SpecialistCategory.technician:
        return '🔧';
      case SpecialistCategory.other:
        return '⭐';
    }
  }

  /// Парсинг категории из строки
  static SpecialistCategory _parseCategory(String? category) {
    switch (category) {
      case 'photographer':
        return SpecialistCategory.photographer;
      case 'videographer':
        return SpecialistCategory.videographer;
      case 'dj':
        return SpecialistCategory.dj;
      case 'host':
        return SpecialistCategory.host;
      case 'decorator':
        return SpecialistCategory.decorator;
      case 'musician':
        return SpecialistCategory.musician;
      case 'caterer':
        return SpecialistCategory.caterer;
      case 'security':
        return SpecialistCategory.security;
      case 'technician':
        return SpecialistCategory.technician;
      case 'other':
        return SpecialistCategory.other;
      default:
        return SpecialistCategory.other;
    }
  }

  /// Парсинг уровня опыта из строки
  static ExperienceLevel _parseExperienceLevel(String? level) {
    switch (level) {
      case 'beginner':
        return ExperienceLevel.beginner;
      case 'intermediate':
        return ExperienceLevel.intermediate;
      case 'advanced':
        return ExperienceLevel.advanced;
      case 'expert':
        return ExperienceLevel.expert;
      default:
        return ExperienceLevel.beginner;
    }
  }
}

/// Фильтры для поиска специалистов
class SpecialistFilters {
  final String? searchQuery;
  final SpecialistCategory? category;
  final List<String>? subcategories;
  final ExperienceLevel? minExperienceLevel;
  final double? maxHourlyRate;
  final double? minRating;
  final List<String>? serviceAreas;
  final List<String>? languages;
  final bool? isVerified;
  final bool? isAvailable;
  final DateTime? availableDate;
  final String? sortBy; // 'rating', 'price', 'experience', 'reviews'
  final bool sortAscending;

  const SpecialistFilters({
    this.searchQuery,
    this.category,
    this.subcategories,
    this.minExperienceLevel,
    this.maxHourlyRate,
    this.minRating,
    this.serviceAreas,
    this.languages,
    this.isVerified,
    this.isAvailable,
    this.availableDate,
    this.sortBy = 'rating',
    this.sortAscending = false,
  });

  /// Копировать с изменениями
  SpecialistFilters copyWith({
    String? searchQuery,
    SpecialistCategory? category,
    List<String>? subcategories,
    ExperienceLevel? minExperienceLevel,
    double? maxHourlyRate,
    double? minRating,
    List<String>? serviceAreas,
    List<String>? languages,
    bool? isVerified,
    bool? isAvailable,
    DateTime? availableDate,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SpecialistFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      subcategories: subcategories ?? this.subcategories,
      minExperienceLevel: minExperienceLevel ?? this.minExperienceLevel,
      maxHourlyRate: maxHourlyRate ?? this.maxHourlyRate,
      minRating: minRating ?? this.minRating,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      availableDate: availableDate ?? this.availableDate,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Проверить, применены ли фильтры
  bool get hasFilters {
    return searchQuery != null ||
        category != null ||
        subcategories != null ||
        minExperienceLevel != null ||
        maxHourlyRate != null ||
        minRating != null ||
        serviceAreas != null ||
        languages != null ||
        isVerified != null ||
        isAvailable != null ||
        availableDate != null;
  }

  /// Сбросить все фильтры
  SpecialistFilters clear() {
    return const SpecialistFilters();
  }
}