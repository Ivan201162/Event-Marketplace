import 'package:cloud_firestore/cloud_firestore.dart';

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
  other, // Другое
}

/// Уровень опыта специалиста
enum ExperienceLevel {
  beginner, // Начинающий
  intermediate, // Средний
  advanced, // Продвинутый
  expert, // Эксперт
}

/// Расширение для получения названий категорий
extension SpecialistCategoryExtension on SpecialistCategory {
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
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

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
    this.workingHours = const {},
    this.location,
    this.contactInfo,
    this.businessInfo,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
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
    this.insurance,
    this.travelRadius,
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
    this.postsCount = 0,
    this.storiesCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.recentPosts = const [],
    this.activeStories = const [],
    this.isVerified = false,
    this.verificationBadge,
    this.socialStats,
  });

  /// Создать из Map
  factory Specialist.fromMap(Map<String, dynamic> data) => Specialist(
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
        pricePerHour: (data['pricePerHour'] as num?)?.toDouble(),
        location: data['location'] as String?,
        isAvailable: data['isAvailable'] as bool? ?? true,
        isVerified: data['isVerified'] as bool? ?? false,
        portfolioImages: List<String>.from(data['portfolioImages'] as List<dynamic>? ?? []),
        portfolioVideos: List<String>.from(data['portfolioVideos'] as List<dynamic>? ?? []),
        services: List<String>.from(data['services'] as List<dynamic>? ?? []),
        equipment: List<String>.from(data['equipment'] as List<dynamic>? ?? []),
        languages: List<String>.from(data['languages'] as List<dynamic>? ?? []),
        workingHours: Map<String, String>.from(data['workingHours'] as Map<dynamic, dynamic>? ?? {}),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        lastActiveAt: data['lastActiveAt'] != null
            ? (data['lastActiveAt'] as Timestamp).toDate()
            : null,
        profileImageUrl: data['profileImageUrl'] as String?,
        coverImageUrl: data['coverImageUrl'] as String?,
        socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
        certifications: List<String>.from(data['certifications'] ?? []),
        awards: List<String>.from(data['awards'] ?? []),
        insurance: data['insurance'] ?? false,
        travelRadius: data['travelRadius'] ?? 0,
        responseTime: data['responseTime'] ?? 0,
        completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
        cancellationRate: (data['cancellationRate'] as num?)?.toDouble() ?? 0.0,
        averageResponseTime: data['averageResponseTime'] ?? 0,
        totalBookings: data['totalBookings'] ?? 0,
        totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        isOnline: data['isOnline'] ?? false,
        isPremium: data['isPremium'] ?? false,
        premiumExpiresAt: data['premiumExpiresAt'] != null
            ? (data['premiumExpiresAt'] as Timestamp).toDate()
            : null,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        avatar: data['avatar'],
        specialization: data['specialization'],
        avgPriceByService: data['avgPriceByService'] != null 
            ? Map<String, double>.from(data['avgPriceByService'])
            : null,
        postsCount: data['postsCount'] as int? ?? 0,
        storiesCount: data['storiesCount'] as int? ?? 0,
        followersCount: data['followersCount'] as int? ?? 0,
        followingCount: data['followingCount'] as int? ?? 0,
        recentPosts: List<String>.from(data['recentPosts'] ?? []),
        activeStories: List<String>.from(data['activeStories'] ?? []),
        isVerified: data['isVerified'] as bool? ?? false,
        verificationBadge: data['verificationBadge'] as String?,
        socialStats: data['socialStats'] != null 
            ? Map<String, dynamic>.from(data['socialStats'])
            : null,
      );

  /// Создать из документа Firestore
  factory Specialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
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
      price: (data['price'] ?? 0.0).toDouble(), // Обязательная цена
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
      avatarUrl: data['avatarUrl'],
      avatar: data['avatar'],
      specialization: data['specialization'],
        avgPriceByService: data['avgPriceByService'] != null 
            ? Map<String, double>.from(data['avgPriceByService'])
            : null,
        postsCount: data['postsCount'] as int? ?? 0,
        storiesCount: data['storiesCount'] as int? ?? 0,
        followersCount: data['followersCount'] as int? ?? 0,
        followingCount: data['followingCount'] as int? ?? 0,
        recentPosts: List<String>.from(data['recentPosts'] ?? []),
        activeStories: List<String>.from(data['activeStories'] ?? []),
        isVerified: data['isVerified'] as bool? ?? false,
        verificationBadge: data['verificationBadge'] as String?,
        socialStats: data['socialStats'] != null 
            ? Map<String, dynamic>.from(data['socialStats'])
            : null,
    );
  }
  final String id;
  final String userId; // Связь с пользователем
  final String name;
  final String? description;
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
  final Map<String, String> workingHours; // Рабочие часы
  final String? location; // Местоположение
  final Map<String, dynamic>? contactInfo;
  final Map<String, dynamic>? businessInfo;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewCount;
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
  final String? insurance;
  final int? travelRadius;
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
  
  // Социальные функции
  final int postsCount;
  final int storiesCount;
  final int followersCount;
  final int followingCount;
  final List<String> recentPosts;
  final List<String> activeStories;
  final bool isVerified;
  final String? verificationBadge;
  final Map<String, dynamic>? socialStats;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
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
        'contactInfo': contactInfo,
        'businessInfo': businessInfo,
        'isAvailable': isAvailable,
        'isVerified': isVerified,
        'rating': rating,
        'reviewCount': reviewCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
        'avatarUrl': avatarUrl,
        'avatar': avatar,
        'specialization': specialization,
        'avgPriceByService': avgPriceByService,
        'postsCount': postsCount,
        'storiesCount': storiesCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'recentPosts': recentPosts,
        'activeStories': activeStories,
        'isVerified': isVerified,
        'verificationBadge': verificationBadge,
        'socialStats': socialStats,
      };

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
    double? price,
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
    String? avatarUrl,
    String? avatar,
    String? specialization,
    Map<String, double>? avgPriceByService,
    int? postsCount,
    int? storiesCount,
    int? followersCount,
    int? followingCount,
    List<String>? recentPosts,
    List<String>? activeStories,
    bool? isVerified,
    String? verificationBadge,
    Map<String, dynamic>? socialStats,
  }) =>
      Specialist(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description ?? this.description,
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
        postsCount: postsCount ?? this.postsCount,
        storiesCount: storiesCount ?? this.storiesCount,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        recentPosts: recentPosts ?? this.recentPosts,
        activeStories: activeStories ?? this.activeStories,
        isVerified: isVerified ?? this.isVerified,
        verificationBadge: verificationBadge ?? this.verificationBadge,
        socialStats: socialStats ?? this.socialStats,
      );

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
  }) =>
      SpecialistFilters(
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

  /// Проверить, применены ли фильтры
  bool get hasFilters =>
      searchQuery != null ||
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

  /// Сбросить все фильтры
  SpecialistFilters clear() => const SpecialistFilters();
}
