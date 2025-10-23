import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialist.dart';

// Временные определения для совместимости
enum TaxType { individual, legal }

class PriceRange {
  const PriceRange({required this.min, required this.max});
  final double min;
  final double max;
}

/// Расширенная модель специалиста для интеллектуального поиска
class SmartSpecialist {
  const SmartSpecialist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.bio,
    required this.category,
    this.categories = const [],
    this.subcategories = const [],
    required this.experienceLevel,
    required this.yearsOfExperience,
    required this.hourlyRate,
    required this.price,
    this.priceFrom,
    this.priceTo,
    this.minBookingHours,
    this.maxBookingHours,
    this.serviceAreas = const [],
    this.languages = const [],
    this.equipment = const [],
    this.services = const [],
    this.portfolio = const [],
    this.portfolioImages = const [],
    this.portfolioVideos = const [],
    this.portfolioItems = const [],
    this.reviews = const [],
    this.avgRating = 0.0,
    this.workingHours = const {},
    this.location,
    this.city,
    this.contactInfo,
    this.businessInfo,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl,
    this.photoUrl,
    this.experience,
    this.availableDates = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
    this.metadata,
    this.avatarUrl,
    this.avatar,
    this.specialization,
    this.phone,
    this.profileImageUrl,
    this.coverImageUrl,
    this.socialLinks = const {},
    this.certifications = const [],
    this.awards = const [],
    this.insurance = false,
    this.travelRadius,
    this.busyDates = const [],
    this.firstName,
    this.lastName,
    this.totalReviews,
    this.priceRange,
    this.responseTime,
    this.completionRate,
    this.cancellationRate,
    this.averageResponseTime,
    this.totalBookings,
    this.totalEarnings,
    this.isOnline,
    this.isPremium,
    this.premiumExpiresAt,
    this.email,
    this.lastPriceUpdateAt,
    this.avgPriceByService,
    this.taxType,
    this.contacts = const {},
    this.servicesWithPrices = const {},
    this.priceRangeString,
    // Новые поля для интеллектуального поиска
    this.styles = const [],
    this.keywords = const [],
    this.reputationScore = 0,
    this.compatibilityScore = 0.0,
    this.searchTags = const [],
    this.eventTypes = const [],
    this.specializations = const [],
    this.workingStyle = const {},
    this.personalityTraits = const [],
    this.availabilityPattern = const {},
    this.clientPreferences = const {},
    this.performanceMetrics = const {},
    this.recommendationFactors = const {},
  });

  /// Создать из Map
  factory SmartSpecialist.fromMap(Map<String, dynamic> data) => SmartSpecialist(
        id: data['id'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        phone: data['phone'] as String?,
        description: data['description'] as String?,
        bio: data['bio'] as String?,
        category: SpecialistCategory.values.firstWhere(
          (e) => e.name == (data['category'] as String?),
          orElse: () => SpecialistCategory.other,
        ),
        categories: (data['categories'] as List<dynamic>?)
                ?.map(
                  (e) => SpecialistCategory.values.firstWhere(
                    (cat) => cat.name == e,
                    orElse: () => SpecialistCategory.other,
                  ),
                )
                .toList() ??
            [],
        subcategories:
            (data['subcategories'] as List<dynamic>?)?.cast<String>() ?? [],
        experienceLevel: ExperienceLevel.values.firstWhere(
          (e) => e.name == data['experienceLevel'],
          orElse: () => ExperienceLevel.beginner,
        ),
        yearsOfExperience: data['yearsOfExperience'] as int? ?? 0,
        hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        priceFrom: (data['priceFrom'] as num?)?.toDouble(),
        priceTo: (data['priceTo'] as num?)?.toDouble(),
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: data['reviewCount'] as int? ?? 0,
        imageUrl: data['imageUrl'] as String?,
        photoUrl: data['photoUrl'] as String?,
        experience: data['experience'] as String?,
        availableDates: (data['availableDates'] as List<dynamic>? ?? [])
            .map(
              (e) => e is String
                  ? DateTime.tryParse(e)
                  : e is Timestamp
                      ? e.toDate()
                      : null,
            )
            .where((e) => e != null)
            .cast<DateTime>()
            .toList(),
        priceRangeString: data['priceRangeString'] as String?,
        location: data['location'] as String?,
        city: data['city'] as String?,
        isAvailable: data['isAvailable'] as bool? ?? true,
        isVerified: data['isVerified'] as bool? ?? false,
        portfolioImages:
            List<String>.from(data['portfolioImages'] as List<dynamic>? ?? []),
        portfolioVideos:
            List<String>.from(data['portfolioVideos'] as List<dynamic>? ?? []),
        portfolioItems: (data['portfolioItems'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        reviews: (data['reviews'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
        services: List<String>.from(data['services'] as List<dynamic>? ?? []),
        equipment: List<String>.from(data['equipment'] as List<dynamic>? ?? []),
        languages: List<String>.from(data['languages'] as List<dynamic>? ?? []),
        workingHours: Map<String, String>.from(
            data['workingHours'] as Map<dynamic, dynamic>? ?? {}),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt'].toString()))
            : DateTime.now(),
        lastActiveAt: data['lastActiveAt'] != null
            ? (data['lastActiveAt'] is Timestamp
                ? (data['lastActiveAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['lastActiveAt'].toString()))
            : null,
        profileImageUrl: data['profileImageUrl'] as String?,
        coverImageUrl: data['coverImageUrl'] as String?,
        socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
        certifications: List<String>.from(data['certifications'] ?? []),
        awards: List<String>.from(data['awards'] ?? []),
        insurance: data['insurance'] as bool? ?? false,
        travelRadius: data['travelRadius'] as int? ?? 0,
        responseTime: data['responseTime']?.toString(),
        completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
        cancellationRate: (data['cancellationRate'] as num?)?.toDouble() ?? 0.0,
        averageResponseTime: data['averageResponseTime']?.toString(),
        totalBookings: data['totalBookings'] as int? ?? 0,
        totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        isOnline: data['isOnline'] as bool? ?? false,
        isPremium: data['isPremium'] as bool? ?? false,
        premiumExpiresAt: data['premiumExpiresAt'] != null
            ? (data['premiumExpiresAt'] is Timestamp
                ? (data['premiumExpiresAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['premiumExpiresAt'].toString()))
            : null,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        avatar: data['avatar'],
        specialization: data['specialization'],
        avgPriceByService: data['avgPriceByService'] != null
            ? Map<String, double>.from(data['avgPriceByService'])
            : null,
        busyDates: (data['busyDates'] as List<dynamic>?)
                ?.map((e) => e is Timestamp
                    ? e.toDate()
                    : DateTime.tryParse(e.toString()))
                .where((e) => e != null)
                .cast<DateTime>()
                .toList() ??
            [],
        taxType: data['taxType'] != null
            ? TaxType.values.firstWhere(
                (e) => e.name == data['taxType'],
                orElse: () => TaxType.individual,
              )
            : null,
        firstName: data['firstName'],
        lastName: data['lastName'],
        totalReviews: data['totalReviews'],
        priceRange: data['priceRange'] != null
            ? PriceRange(
                min: (data['priceRange']['min'] as num?)?.toDouble(),
                max: (data['priceRange']['max'] as num?)?.toDouble(),
              )
            : null,
        contacts: data['contacts'] != null
            ? Map<String, String>.from(data['contacts'])
            : const {},
        servicesWithPrices: data['servicesWithPrices'] != null
            ? Map<String, double>.from(data['servicesWithPrices'])
            : const {},
        priceRangeString: data['priceRangeString'] as String?,
        // Новые поля для интеллектуального поиска
        styles: List<String>.from(data['styles'] ?? []),
        keywords: List<String>.from(data['keywords'] ?? []),
        reputationScore: data['reputationScore'] as int? ?? 0,
        compatibilityScore:
            (data['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
        searchTags: List<String>.from(data['searchTags'] ?? []),
        eventTypes: List<String>.from(data['eventTypes'] ?? []),
        specializations: List<String>.from(data['specializations'] ?? []),
        workingStyle: Map<String, dynamic>.from(data['workingStyle'] ?? {}),
        personalityTraits: List<String>.from(data['personalityTraits'] ?? []),
        availabilityPattern:
            Map<String, dynamic>.from(data['availabilityPattern'] ?? {}),
        clientPreferences:
            Map<String, dynamic>.from(data['clientPreferences'] ?? {}),
        performanceMetrics:
            Map<String, dynamic>.from(data['performanceMetrics'] ?? {}),
        recommendationFactors:
            Map<String, dynamic>.from(data['recommendationFactors'] ?? {}),
      );

  /// Создать из документа Firestore
  factory SmartSpecialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SmartSpecialist.fromMap({'id': doc.id, ...data});
  }

  /// Создать из обычного Specialist
  factory SmartSpecialist.fromSpecialist(Specialist specialist) =>
      SmartSpecialist(
        id: specialist.id,
        userId: specialist.userId,
        name: specialist.name,
        description: specialist.description,
        bio: specialist.bio,
        category: specialist.category,
        categories: specialist.categories,
        subcategories: specialist.subcategories,
        experienceLevel: specialist.experienceLevel,
        yearsOfExperience: specialist.yearsOfExperience,
        hourlyRate: specialist.hourlyRate,
        price: specialist.price,
        priceFrom: specialist.price,
        priceTo: specialist.price,
        minBookingHours: specialist.minBookingHours,
        maxBookingHours: specialist.maxBookingHours,
        serviceAreas: specialist.serviceAreas,
        languages: specialist.languages,
        equipment: specialist.equipment,
        services: specialist.services,
        portfolio: specialist.portfolio,
        portfolioImages: specialist.portfolioImages,
        portfolioVideos: specialist.portfolioVideos,
        portfolioItems: specialist.portfolioItems,
        reviews: specialist.reviews,
        avgRating: specialist.avgRating,
        workingHours: specialist.workingHours,
        location: specialist.location,
        city: specialist.city,
        contactInfo: specialist.contactInfo,
        businessInfo: specialist.businessInfo,
        isAvailable: specialist.isAvailable,
        isVerified: specialist.isVerified,
        rating: specialist.rating,
        reviewCount: specialist.reviewCount,
        imageUrl: specialist.imageUrl,
        photoUrl: specialist.photoUrl,
        experience: specialist.experience,
        availableDates: specialist.availableDates,
        createdAt: specialist.createdAt,
        updatedAt: specialist.updatedAt,
        lastActiveAt: specialist.lastActiveAt,
        metadata: specialist.metadata,
        avatarUrl: specialist.avatarUrl,
        avatar: specialist.avatar,
        specialization: specialist.specialization,
        phone: specialist.phone,
        profileImageUrl: specialist.profileImageUrl,
        coverImageUrl: specialist.coverImageUrl,
        socialLinks: specialist.socialLinks,
        certifications: specialist.certifications,
        awards: specialist.awards,
        insurance: specialist.insurance,
        travelRadius: specialist.travelRadius,
        busyDates: specialist.busyDates,
        firstName: specialist.firstName,
        lastName: specialist.lastName,
        totalReviews: specialist.totalReviews,
        priceRange: specialist.priceRange,
        responseTime: specialist.responseTime,
        completionRate: specialist.completionRate,
        cancellationRate: specialist.cancellationRate,
        averageResponseTime: specialist.averageResponseTime,
        totalBookings: specialist.totalBookings,
        totalEarnings: specialist.totalEarnings,
        isOnline: specialist.isOnline,
        isPremium: specialist.isPremium,
        premiumExpiresAt: specialist.premiumExpiresAt,
        email: specialist.email,
        lastPriceUpdateAt: specialist.lastPriceUpdateAt,
        avgPriceByService: specialist.avgPriceByService,
        taxType: specialist.taxType,
        contacts: specialist.contacts,
        servicesWithPrices: specialist.servicesWithPrices,
        priceRangeString: specialist.priceRangeString,
        // Новые поля для интеллектуального поиска
        styles: _generateStyles(specialist),
        keywords: _generateKeywords(specialist),
        reputationScore: _calculateReputationScore(specialist),
        searchTags: _generateSearchTags(specialist),
        eventTypes: _generateEventTypes(specialist),
        specializations: _generateSpecializations(specialist),
        workingStyle: _generateWorkingStyle(specialist),
        personalityTraits: _generatePersonalityTraits(specialist),
        availabilityPattern: _generateAvailabilityPattern(specialist),
        clientPreferences: _generateClientPreferences(specialist),
        performanceMetrics: _generatePerformanceMetrics(specialist),
        recommendationFactors: _generateRecommendationFactors(specialist),
      );

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? bio;
  final SpecialistCategory category;
  final List<SpecialistCategory> categories;
  final List<String> subcategories;
  final ExperienceLevel experienceLevel;
  final int yearsOfExperience;
  final double hourlyRate;
  final double price;
  final double? priceFrom;
  final double? priceTo;
  final double? minBookingHours;
  final double? maxBookingHours;
  final List<String> serviceAreas;
  final List<String> languages;
  final List<String> equipment;
  final List<String> services;
  final List<String> portfolio;
  final List<String> portfolioImages;
  final List<String> portfolioVideos;
  final List<Map<String, dynamic>> portfolioItems;
  final List<Map<String, dynamic>> reviews;
  final double avgRating;
  final Map<String, String> workingHours;
  final String? location;
  final String? city;
  final Map<String, dynamic>? contactInfo;
  final Map<String, dynamic>? businessInfo;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final String? photoUrl;
  final String? experience;
  final List<DateTime> availableDates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? metadata;
  final String? avatarUrl;
  final String? avatar;
  final String? specialization;
  final String? phone;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final Map<String, String> socialLinks;
  final List<String> certifications;
  final List<String> awards;
  final bool insurance;
  final int? travelRadius;
  final List<DateTime> busyDates;
  final String? firstName;
  final String? lastName;
  final int? totalReviews;
  final PriceRange? priceRange;
  final String? responseTime;
  final double? completionRate;
  final double? cancellationRate;
  final String? averageResponseTime;
  final int? totalBookings;
  final double? totalEarnings;
  final bool? isOnline;
  final bool? isPremium;
  final DateTime? premiumExpiresAt;
  final String? email;
  final DateTime? lastPriceUpdateAt;
  final Map<String, double>? avgPriceByService;
  final TaxType? taxType;
  final Map<String, String> contacts;
  final Map<String, double> servicesWithPrices;
  final String? priceRangeString;

  // Новые поля для интеллектуального поиска
  final List<String> styles; // Стили работы (классика, юмор, интерактив и т.д.)
  final List<String> keywords; // Ключевые слова для поиска
  final int reputationScore; // Балл репутации (0-100)
  final double compatibilityScore; // Балл совместимости с пользователем
  final List<String> searchTags; // Теги для поиска
  final List<String> eventTypes; // Типы мероприятий
  final List<String> specializations; // Специализации
  final Map<String, dynamic> workingStyle; // Стиль работы
  final List<String> personalityTraits; // Черты характера
  final Map<String, dynamic> availabilityPattern; // Паттерн доступности
  final Map<String, dynamic> clientPreferences; // Предпочтения клиентов
  final Map<String, dynamic> performanceMetrics; // Метрики производительности
  final Map<String, dynamic> recommendationFactors; // Факторы рекомендаций

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'bio': bio,
        'category': category?.name ?? '',
        'categories': categories.map((e) => e.name).toList(),
        'subcategories': subcategories,
        'experienceLevel': experienceLevel.name,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'price': price,
        'priceFrom': priceFrom,
        'priceTo': priceTo,
        'minBookingHours': minBookingHours,
        'maxBookingHours': maxBookingHours,
        'serviceAreas': serviceAreas,
        'languages': languages,
        'equipment': equipment,
        'portfolio': portfolio,
        'portfolioItems': portfolioItems,
        'reviews': reviews,
        'avgRating': avgRating,
        'contactInfo': contactInfo,
        'businessInfo': businessInfo,
        'isAvailable': isAvailable,
        'isVerified': isVerified,
        'rating': rating,
        'reviewCount': reviewCount,
        'imageUrl': imageUrl,
        'photoUrl': photoUrl,
        'experience': experience,
        'availableDates':
            availableDates.map((date) => date.toIso8601String()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastActiveAt':
            lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
        'metadata': metadata,
        'avatarUrl': avatarUrl,
        'avatar': avatar,
        'specialization': specialization,
        'avgPriceByService': avgPriceByService,
        'busyDates': busyDates.map(Timestamp.fromDate).toList(),
        'taxType': taxType?.name,
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'totalReviews': totalReviews,
        'priceRange': priceRange != null
            ? {
                'min': priceRange!.min,
                'max': priceRange!.max,
              }
            : null,
        'contacts': contacts,
        'servicesWithPrices': servicesWithPrices,
        // Новые поля для интеллектуального поиска
        'styles': styles,
        'keywords': keywords,
        'reputationScore': reputationScore,
        'compatibilityScore': compatibilityScore,
        'searchTags': searchTags,
        'eventTypes': eventTypes,
        'specializations': specializations,
        'workingStyle': workingStyle,
        'personalityTraits': personalityTraits,
        'availabilityPattern': availabilityPattern,
        'clientPreferences': clientPreferences,
        'performanceMetrics': performanceMetrics,
        'recommendationFactors': recommendationFactors,
      };

  /// Получить полное имя
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name;
  }

  /// Получить отображаемое имя
  String get displayName => fullName;

  /// Получить URL фото
  String? get imageUrlValue => photoUrl ?? profileImageUrl ?? avatarUrl;

  /// Получить количество отзывов
  int get reviewsCount => totalReviews ?? reviewCount;

  /// Получить отображаемое название категории
  String get categoryDisplayName => category.displayName;

  /// Получить иконку для категории
  String get categoryIcon => category.icon;

  /// Получить диапазон цен
  String get priceRangeString {
    if (priceFrom != null && priceTo != null) {
      return '${priceFrom!.toStringAsFixed(0)} - ${priceTo!.toStringAsFixed(0)} ₽';
    }
    return '${price.toStringAsFixed(0)} ₽';
  }

  /// Проверить, доступен ли специалист в указанную дату
  bool isAvailableOnDate(DateTime date) {
    if (!isAvailable) return false;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return !busyDates.any(
      (busyDate) =>
          busyDate.year == normalizedDate.year &&
          busyDate.month == normalizedDate.month &&
          busyDate.day == normalizedDate.day,
    );
  }

  /// Проверить, занята ли дата
  bool isDateBusy(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return busyDates.any(
      (busyDate) =>
          busyDate.year == normalizedDate.year &&
          busyDate.month == normalizedDate.month &&
          busyDate.day == normalizedDate.day,
    );
  }

  /// Получить свободные даты в диапазоне
  List<DateTime> getAvailableDates(DateTime startDate, DateTime endDate) {
    final availableDates = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (!isDateBusy(current)) {
        availableDates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }

    return availableDates;
  }

  /// Вычислить совместимость с пользователем
  double calculateCompatibility(Map<String, dynamic> userPreferences) {
    var score = 0;

    // Совпадение стилей (40% веса)
    if (userPreferences.containsKey('preferredStyles')) {
      final userStyles = List<String>.from(userPreferences['preferredStyles']);
      final matchingStyles = styles.where(userStyles.contains).length;
      score += (matchingStyles / userStyles.length) * 0.4;
    }

    // Совпадение бюджета (30% веса)
    if (userPreferences.containsKey('preferredBudget')) {
      final userBudget = userPreferences['preferredBudget'] as double;
      if (priceFrom != null && priceTo != null) {
        if (userBudget >= priceFrom! && userBudget <= priceTo!) {
          score += 0.3;
        } else {
          final budgetDiff = (userBudget - price).abs() / userBudget;
          score += (1 - budgetDiff.clamp(0.0, 1.0)) * 0.3;
        }
      }
    }

    // Совпадение города (20% веса)
    if (userPreferences.containsKey('preferredCities')) {
      final userCities = List<String>.from(userPreferences['preferredCities']);
      if (city != null && userCities.contains(city)) {
        score += 0.2;
      }
    }

    // Рейтинг (10% веса)
    score += (rating / 5.0) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Генерация стилей на основе категории и опыта
  static List<String> _generateStyles(Specialist specialist) {
    final styles = <String>[];

    switch (specialist.category) {
      case SpecialistCategory.host:
        styles.addAll(['классика', 'юмор', 'интерактив']);
        break;
      case SpecialistCategory.photographer:
        styles.addAll(['классика', 'современный', 'художественный']);
        break;
      case SpecialistCategory.dj:
        styles.addAll(['электроника', 'поп', 'рок', 'классика']);
        break;
      case SpecialistCategory.musician:
        styles.addAll(['классика', 'джаз', 'рок', 'поп']);
        break;
      default:
        styles.add('классика');
    }

    // Добавляем стили на основе опыта
    if ((specialist.yearsOfExperience ?? 0) > 5) {
      styles.add('опытный');
    }
    if (specialist.rating > 4.5) {
      styles.add('премиум');
    }

    return styles;
  }

  /// Генерация ключевых слов для поиска
  static List<String> _generateKeywords(Specialist specialist) {
    final keywords = <String>[];

    // Добавляем название категории
    keywords.add(specialist.category?.displayName?.toLowerCase() ?? '');

    // Добавляем подкатегории
    keywords.addAll(specialist.subcategories.map((s) => s.toLowerCase()));

    // Добавляем услуги
    keywords.addAll(specialist.services.map((s) => s.toLowerCase()));

    // Добавляем город
    keywords.add(specialist.city.toLowerCase());

    // Добавляем оборудование
    keywords.addAll(specialist.equipment.map((e) => e.toLowerCase()));

    return keywords;
  }

  /// Вычисление балла репутации
  static int _calculateReputationScore(Specialist specialist) {
    var score = 0;

    // Базовый балл за рейтинг
    score += (specialist.rating * 10).round();

    // Бонус за количество отзывов
    if (specialist.reviewCount > 10) score += 10;
    if (specialist.reviewCount > 50) score += 10;
    if (specialist.reviewCount > 100) score += 10;

    // Бонус за верификацию
    if (specialist.isVerified) score += 15;

    // Бонус за опыт
    if (specialist.yearsOfExperience > 5) score += 10;
    if (specialist.yearsOfExperience > 10) score += 10;

    // Бонус за портфолио
    if (specialist.portfolioImages.isNotEmpty) score += 5;
    if (specialist.portfolioVideos.isNotEmpty) score += 5;

    return score.clamp(0, 100);
  }

  /// Генерация тегов для поиска
  static List<String> _generateSearchTags(Specialist specialist) {
    final tags = <String>[];

    tags.add(specialist.category.displayName);
    tags.addAll(specialist.subcategories);
    tags.addAll(specialist.services);

    tags.add(specialist.city);

    return tags;
  }

  /// Генерация типов мероприятий
  static List<String> _generateEventTypes(Specialist specialist) {
    final eventTypes = <String>[];

    switch (specialist.category) {
      case SpecialistCategory.host:
        eventTypes.addAll(['свадьба', 'корпоратив', 'день рождения', 'юбилей']);
        break;
      case SpecialistCategory.photographer:
        eventTypes
            .addAll(['свадьба', 'фотосессия', 'корпоратив', 'день рождения']);
        break;
      case SpecialistCategory.dj:
        eventTypes
            .addAll(['свадьба', 'корпоратив', 'день рождения', 'вечеринка']);
        break;
      default:
        eventTypes.add('мероприятие');
    }

    return eventTypes;
  }

  /// Генерация специализаций
  static List<String> _generateSpecializations(Specialist specialist) {
    final specializations = <String>[];

    specializations.add(specialist.category.displayName);
    specializations.addAll(specialist.subcategories);

    if (specialist.yearsOfExperience > 5) {
      specializations.add('опытный');
    }

    return specializations;
  }

  /// Генерация стиля работы
  static Map<String, dynamic> _generateWorkingStyle(Specialist specialist) => {
        'communication': specialist.rating > 4.5 ? 'отличная' : 'хорошая',
        'punctuality': specialist.completionRate ?? 0.9,
        'flexibility': specialist.yearsOfExperience > 3 ? 'высокая' : 'средняя',
        'creativity':
            specialist.portfolioImages.isNotEmpty ? 'высокая' : 'средняя',
      };

  /// Генерация черт характера
  static List<String> _generatePersonalityTraits(Specialist specialist) {
    final traits = <String>[];

    if (specialist.rating > 4.5) {
      traits.add('профессиональный');
    }
    if (specialist.isVerified) {
      traits.add('надежный');
    }
    if (specialist.yearsOfExperience > 5) {
      traits.add('опытный');
    }
    if (specialist.portfolioImages.isNotEmpty) {
      traits.add('креативный');
    }

    return traits;
  }

  /// Генерация паттерна доступности
  static Map<String, dynamic> _generateAvailabilityPattern(
          Specialist specialist) =>
      {
        'weekdays': specialist.workingHours.containsKey('weekdays'),
        'weekends': specialist.workingHours.containsKey('weekends'),
        'evenings': specialist.workingHours.containsKey('evenings'),
        'flexible': specialist.yearsOfExperience > 3,
      };

  /// Генерация предпочтений клиентов
  static Map<String, dynamic> _generateClientPreferences(
          Specialist specialist) =>
      {
        'budgetRange': specialist.price < 20000
            ? 'бюджетный'
            : specialist.price < 50000
                ? 'средний'
                : 'премиум',
        'eventSize':
            specialist.yearsOfExperience > 5 ? 'любой' : 'малый-средний',
        'style': specialist.rating > 4.5 ? 'премиум' : 'стандартный',
      };

  /// Генерация метрик производительности
  static Map<String, dynamic> _generatePerformanceMetrics(
          Specialist specialist) =>
      {
        'responseTime': specialist.responseTime ?? 'быстрый',
        'completionRate': specialist.completionRate ?? 0.95,
        'cancellationRate': specialist.cancellationRate ?? 0.05,
        'clientSatisfaction': specialist.rating,
      };

  /// Генерация факторов рекомендаций
  static Map<String, dynamic> _generateRecommendationFactors(
          Specialist specialist) =>
      {
        'popularity': specialist.reviewCount,
        'quality': specialist.rating,
        'experience': specialist.yearsOfExperience,
        'availability': specialist.isAvailable,
        'verification': specialist.isVerified,
      };
}
