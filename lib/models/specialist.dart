import 'package:cloud_firestore/cloud_firestore.dart';

import 'price_range.dart';
import 'tax_info.dart';

/// Категории специалистов
enum SpecialistCategory {
  // Основные категории
  photographer, // Фотограф
  videographer, // Видеограф
  dj, // DJ
  host, // Ведущий
  decorator, // Декоратор
  musician, // Музыкант
  caterer, // Кейтеринг
  security, // Охрана
  technician, // Техник

  // Расширенные категории
  animator, // Аниматор
  florist, // Флорист
  lighting, // Световое оформление
  sound, // Звуковое оборудование
  costume, // Платья/костюмы
  fireShow, // Фаер-шоу
  fireworks, // Салюты
  lightShow, // Световые шоу
  coverBand, // Кавер-группы
  teamBuilding, // Тимбилдинги
  cleaning, // Клининг
  rental, // Аренда оборудования
  makeup, // Визажист
  hairstylist, // Парикмахер
  stylist, // Стилист
  choreographer, // Хореограф
  dance, // Танцы
  magic, // Фокусы/иллюзионист
  clown, // Клоун
  balloon, // Аэродизайн
  cake, // Торты/кондитер
  transport, // Транспорт
  venue, // Площадки
  studio, // Фотостудия
  other, // Другое
}

/// Уровень опыта специалиста
enum ExperienceLevel {
  beginner, // Начинающий
  intermediate, // Средний
  advanced, // Продвинутый
  expert, // Эксперт
}

/// Расширение для SpecialistCategory
extension SpecialistCategoryExtension on SpecialistCategory {
  /// Получить название категории
  String get displayName {
    switch (this) {
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
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.lighting:
        return 'Световое оформление';
      case SpecialistCategory.sound:
        return 'Звуковое оборудование';
      case SpecialistCategory.costume:
        return 'Платья/костюмы';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световые шоу';
      case SpecialistCategory.coverBand:
        return 'Кавер-группы';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинги';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.rental:
        return 'Аренда оборудования';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.hairstylist:
        return 'Парикмахер';
      case SpecialistCategory.stylist:
        return 'Стилист';
      case SpecialistCategory.choreographer:
        return 'Хореограф';
      case SpecialistCategory.dance:
        return 'Танцы';
      case SpecialistCategory.magic:
        return 'Фокусы/иллюзионист';
      case SpecialistCategory.clown:
        return 'Клоун';
      case SpecialistCategory.balloon:
        return 'Аэродизайн';
      case SpecialistCategory.cake:
        return 'Торты/кондитер';
      case SpecialistCategory.transport:
        return 'Транспорт';
      case SpecialistCategory.venue:
        return 'Площадки';
      case SpecialistCategory.studio:
        return 'Фотостудия';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

  /// Проверить, не пустая ли категория
  bool get isNotEmpty => this != SpecialistCategory.other;

  String get icon {
    switch (this) {
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
      case SpecialistCategory.animator:
        return '🎭';
      case SpecialistCategory.florist:
        return '🌸';
      case SpecialistCategory.lighting:
        return '💡';
      case SpecialistCategory.sound:
        return '🔊';
      case SpecialistCategory.costume:
        return '👗';
      case SpecialistCategory.fireShow:
        return '🔥';
      case SpecialistCategory.fireworks:
        return '🎆';
      case SpecialistCategory.lightShow:
        return '✨';
      case SpecialistCategory.coverBand:
        return '🎸';
      case SpecialistCategory.teamBuilding:
        return '🤝';
      case SpecialistCategory.cleaning:
        return '🧹';
      case SpecialistCategory.rental:
        return '📦';
      case SpecialistCategory.makeup:
        return '💄';
      case SpecialistCategory.hairstylist:
        return '💇';
      case SpecialistCategory.stylist:
        return '👔';
      case SpecialistCategory.choreographer:
        return '💃';
      case SpecialistCategory.dance:
        return '🕺';
      case SpecialistCategory.magic:
        return '🎩';
      case SpecialistCategory.clown:
        return '🤡';
      case SpecialistCategory.balloon:
        return '🎈';
      case SpecialistCategory.cake:
        return '🎂';
      case SpecialistCategory.transport:
        return '🚗';
      case SpecialistCategory.venue:
        return '🏢';
      case SpecialistCategory.studio:
        return '📸';
      case SpecialistCategory.other:
        return '⭐';
    }
  }
}

/// Расширение для получения названий уровней опыта
extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
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
}

/// Модель специалиста
class Specialist {
  const Specialist({
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
    required this.price, // Обязательное поле цены
    this.pricePerHour,
    this.minBookingHours,
    this.maxBookingHours,
    this.min,
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
    this.contactInfo,
    this.businessInfo,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl,
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
    this.busyDates = const [], // Занятые даты
    // Дополнительные поля для совместимости
    this.firstName,
    this.lastName,
    this.city,
    this.photoUrl,
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
    this.avgPriceByService, // Средняя цена по услугам
    this.taxType, // Тип налогообложения
    // Новые поля для Instagram/ВК-стиля профиля
    this.contacts = const {}, // Контакты (телефон, email, соцсети)
    this.servicesWithPrices = const {}, // Услуги с ценами (название -> цена)
  });

  /// Создать из Map
  factory Specialist.fromMap(Map<String, dynamic> data) {
    // Безопасное преобразование данных
    return Specialist(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      description: data['description'] as String?,
      category: SpecialistCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String?),
        orElse: () => SpecialistCategory.other,
      ),
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0, // Обязательная цена
      yearsOfExperience: data['yearsOfExperience'] as int? ?? 0,
      categories: (data['categories'] as List<dynamic>?)
              ?.map(
                (e) => SpecialistCategory.values.firstWhere(
                  (cat) => cat.name == e,
                  orElse: () => SpecialistCategory.other,
                ),
              )
              .toList() ??
          [],
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == data['experienceLevel'],
        orElse: () => ExperienceLevel.beginner,
      ),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
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
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble(),
      location: data['location'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
      portfolioImages: List<String>.from(data['portfolioImages'] as List<dynamic>? ?? []),
      portfolioVideos: List<String>.from(data['portfolioVideos'] as List<dynamic>? ?? []),
      portfolioItems: (data['portfolioItems'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      reviews:
          (data['reviews'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ??
              [],
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
      services: List<String>.from(data['services'] as List<dynamic>? ?? []),
      equipment: List<String>.from(data['equipment'] as List<dynamic>? ?? []),
      languages: List<String>.from(data['languages'] as List<dynamic>? ?? []),
      workingHours: Map<String, String>.from(
        data['workingHours'] as Map<dynamic, dynamic>? ?? {},
      ),
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
              ?.map(
                (e) => e is Timestamp ? e.toDate() : DateTime.tryParse(e.toString()),
              )
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
      // Дополнительные поля
      firstName: data['firstName'],
      lastName: data['lastName'],
      city: data['city'],
      photoUrl: data['photoUrl'],
      totalReviews: data['totalReviews'],
      priceRange: data['priceRange'] != null
          ? PriceRange.fromMap(Map<String, dynamic>.from(data['priceRange']))
          : null,
      // Новые поля для Instagram/ВК-стиля профиля
      contacts: data['contacts'] != null ? Map<String, String>.from(data['contacts']) : const {},
      servicesWithPrices: data['servicesWithPrices'] != null
          ? Map<String, double>.from(data['servicesWithPrices'])
          : const {},
    );
  }

  /// Создать из документа Firestore
  factory Specialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'],
      bio: data['bio'],
      category: _parseCategory(data['category']),
      subcategories: List<String>.from(data['subcategories'] ?? []),
      experienceLevel: _parseExperienceLevel(data['experienceLevel']),
      yearsOfExperience: data['yearsOfExperience'] as int? ?? 0,
      hourlyRate: (data['hourlyRate'] as num? ?? 0.0).toDouble(),
      price: (data['price'] as num? ?? 0.0).toDouble(), // Обязательная цена
      minBookingHours: data['minBookingHours']?.toDouble(),
      maxBookingHours: data['maxBookingHours']?.toDouble(),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      portfolio: List<String>.from(data['portfolio'] ?? []),
      contactInfo: data['contactInfo'],
      businessInfo: data['businessInfo'],
      isAvailable: data['isAvailable'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] as int? ?? 0,
      createdAt:
          data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      metadata: data['metadata'],
      avatarUrl: data['avatarUrl'],
      avatar: data['avatar'],
      specialization: data['specialization'],
      avgPriceByService: data['avgPriceByService'] != null
          ? Map<String, double>.from(data['avgPriceByService'])
          : null,
      busyDates:
          (data['busyDates'] as List<dynamic>?)?.map((e) => (e as Timestamp).toDate()).toList() ??
              [],
      taxType: data['taxType'] != null
          ? TaxType.values.firstWhere(
              (e) => e.name == data['taxType'],
              orElse: () => TaxType.individual,
            )
          : null,
      // Дополнительные поля
      firstName: data['firstName'],
      lastName: data['lastName'],
      city: data['city'],
      photoUrl: data['photoUrl'],
      totalReviews: data['totalReviews'],
      priceRange: data['priceRange'] != null
          ? PriceRange.fromMap(Map<String, dynamic>.from(data['priceRange']))
          : null,
      // Новые поля для Instagram/ВК-стиля профиля
      contacts: data['contacts'] != null ? Map<String, String>.from(data['contacts']) : const {},
      servicesWithPrices: data['servicesWithPrices'] != null
          ? Map<String, double>.from(data['servicesWithPrices'])
          : const {},
    );
  }

  /// Создать из документа Firestore
  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return Specialist.fromMap({
      'id': doc.id,
      ...safeData,
    });
  }

  final String id;
  final String userId; // Связь с пользователем
  final String name;
  final String? description;
  final String? bio;
  final SpecialistCategory category;
  final List<SpecialistCategory> categories; // Категории
  final List<String> subcategories; // Подкатегории
  final ExperienceLevel experienceLevel;
  final int yearsOfExperience;
  final double hourlyRate;
  final double price; // Обязательная цена услуги
  final double? pricePerHour;
  final double? minBookingHours;
  final double? maxBookingHours;
  final double? min; // Минимальная цена
  final List<String> serviceAreas; // Географические области
  final List<String> languages; // Языки
  final List<String> equipment; // Оборудование
  final List<String> services; // Услуги
  final List<String> portfolio; // Ссылки на портфолио
  final List<String> portfolioImages; // Изображения портфолио
  final List<String> portfolioVideos; // Видео портфолио
  final List<Map<String, dynamic>> portfolioItems; // Расширенное портфолио с описаниями
  final List<Map<String, dynamic>> reviews; // Отзывы клиентов
  final double avgRating; // Средний рейтинг
  final Map<String, String> workingHours; // Рабочие часы
  final String? location; // Местоположение
  final Map<String, dynamic>? contactInfo;
  final Map<String, dynamic>? businessInfo;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
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
  final List<DateTime> busyDates; // Занятые даты
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
  final Map<String, double>? avgPriceByService; // Средняя цена по услугам
  final TaxType? taxType; // Тип налогообложения

  // Новые поля для Instagram/ВК-стиля профиля
  final Map<String, String> contacts; // Контакты (телефон, email, соцсети)
  final Map<String, double> servicesWithPrices; // Услуги с ценами (название -> цена)

  // Дополнительные поля для совместимости
  final String? firstName;
  final String? lastName;
  final String? city;
  final String? photoUrl;
  final int? totalReviews;
  final PriceRange? priceRange;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'bio': bio,
        'category': category.name,
        'subcategories': subcategories,
        'experienceLevel': experienceLevel.name,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'price': price, // Обязательная цена
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
        'experience': experience,
        'availableDates': availableDates.map((date) => date.toIso8601String()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
        'avatarUrl': avatarUrl,
        'avatar': avatar,
        'specialization': specialization,
        'avgPriceByService': avgPriceByService,
        'busyDates': busyDates.map(Timestamp.fromDate).toList(),
        'taxType': taxType?.name,
        // Дополнительные поля
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'photoUrl': photoUrl,
        'totalReviews': totalReviews,
        'priceRange': priceRange?.toMap(),
        // Новые поля для Instagram/ВК-стиля профиля
        'contacts': contacts,
        'servicesWithPrices': servicesWithPrices,
      };

  /// Копировать с изменениями
  Specialist copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? bio,
    SpecialistCategory? category,
    List<String>? subcategories,
    ExperienceLevel? experienceLevel,
    int? yearsOfExperience,
    double? hourlyRate,
    double? price,
    double? minBookingHours,
    double? maxBookingHours,
    List<String>? serviceAreas,
    List<String>? languages,
    List<String>? equipment,
    List<String>? portfolio,
    List<Map<String, dynamic>>? portfolioItems,
    List<Map<String, dynamic>>? reviews,
    double? avgRating,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? businessInfo,
    bool? isAvailable,
    bool? isVerified,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? avatarUrl,
    String? avatar,
    String? specialization,
    Map<String, double>? avgPriceByService,
    List<DateTime>? busyDates,
    List<DateTime>? availableDates,
    TaxType? taxType,
    String? firstName,
    String? lastName,
    String? city,
    String? photoUrl,
    int? totalReviews,
    PriceRange? priceRange,
    // Новые поля для Instagram/ВК-стиля профиля
    Map<String, String>? contacts,
    Map<String, double>? servicesWithPrices,
  }) =>
      Specialist(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description ?? this.description,
        bio: bio ?? this.bio,
        category: category ?? this.category,
        subcategories: subcategories ?? this.subcategories,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        price: price ?? this.price,
        minBookingHours: minBookingHours ?? this.minBookingHours,
        maxBookingHours: maxBookingHours ?? this.maxBookingHours,
        serviceAreas: serviceAreas ?? this.serviceAreas,
        languages: languages ?? this.languages,
        equipment: equipment ?? this.equipment,
        portfolio: portfolio ?? this.portfolio,
        portfolioItems: portfolioItems ?? this.portfolioItems,
        reviews: reviews ?? this.reviews,
        avgRating: avgRating ?? this.avgRating,
        contactInfo: contactInfo ?? this.contactInfo,
        businessInfo: businessInfo ?? this.businessInfo,
        isAvailable: isAvailable ?? this.isAvailable,
        isVerified: isVerified ?? this.isVerified,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatar: avatar ?? this.avatar,
        specialization: specialization ?? this.specialization,
        avgPriceByService: avgPriceByService ?? this.avgPriceByService,
        busyDates: busyDates ?? this.busyDates,
        availableDates: availableDates ?? this.availableDates,
        taxType: taxType ?? this.taxType,
        // Дополнительные поля
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        city: city ?? this.city,
        photoUrl: photoUrl ?? this.photoUrl,
        totalReviews: totalReviews ?? this.totalReviews,
        priceRange: priceRange ?? this.priceRange,
        // Новые поля для Instagram/ВК-стиля профиля
        contacts: contacts ?? this.contacts,
        servicesWithPrices: servicesWithPrices ?? this.servicesWithPrices,
      );

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
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.lighting:
        return 'Световое оформление';
      case SpecialistCategory.sound:
        return 'Звуковое оборудование';
      case SpecialistCategory.costume:
        return 'Платья/костюмы';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световые шоу';
      case SpecialistCategory.coverBand:
        return 'Кавер-группы';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинги';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.rental:
        return 'Аренда оборудования';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.hairstylist:
        return 'Парикмахер';
      case SpecialistCategory.stylist:
        return 'Стилист';
      case SpecialistCategory.choreographer:
        return 'Хореограф';
      case SpecialistCategory.dance:
        return 'Танцы';
      case SpecialistCategory.magic:
        return 'Фокусы/иллюзионист';
      case SpecialistCategory.clown:
        return 'Клоун';
      case SpecialistCategory.balloon:
        return 'Аэродизайн';
      case SpecialistCategory.cake:
        return 'Торты/кондитер';
      case SpecialistCategory.transport:
        return 'Транспорт';
      case SpecialistCategory.venue:
        return 'Площадки';
      case SpecialistCategory.studio:
        return 'Фотостудия';
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
  String get priceRangeString {
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
    // Проверяем, не занята ли дата
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return !busyDates.any(
      (busyDate) =>
          busyDate.year == date.year && busyDate.month == date.month && busyDate.day == date.day,
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
      case SpecialistCategory.animator:
        return '🎭';
      case SpecialistCategory.florist:
        return '🌸';
      case SpecialistCategory.lighting:
        return '💡';
      case SpecialistCategory.sound:
        return '🔊';
      case SpecialistCategory.costume:
        return '👗';
      case SpecialistCategory.fireShow:
        return '🔥';
      case SpecialistCategory.fireworks:
        return '🎆';
      case SpecialistCategory.lightShow:
        return '✨';
      case SpecialistCategory.coverBand:
        return '🎸';
      case SpecialistCategory.teamBuilding:
        return '🤝';
      case SpecialistCategory.cleaning:
        return '🧹';
      case SpecialistCategory.rental:
        return '📦';
      case SpecialistCategory.makeup:
        return '💄';
      case SpecialistCategory.hairstylist:
        return '💇';
      case SpecialistCategory.stylist:
        return '👔';
      case SpecialistCategory.choreographer:
        return '💃';
      case SpecialistCategory.dance:
        return '🕺';
      case SpecialistCategory.magic:
        return '🎩';
      case SpecialistCategory.clown:
        return '🤡';
      case SpecialistCategory.balloon:
        return '🎈';
      case SpecialistCategory.cake:
        return '🎂';
      case SpecialistCategory.transport:
        return '🚗';
      case SpecialistCategory.venue:
        return '🏢';
      case SpecialistCategory.studio:
        return '📸';
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
      case 'studio':
        return SpecialistCategory.studio;
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
