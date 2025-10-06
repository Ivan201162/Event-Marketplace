import 'package:cloud_firestore/cloud_firestore.dart';

/// Категории специалистов
enum SpecialistCategory {
  host, // Ведущий
  photographer, // Фотограф
  animator, // Аниматор
  dj, // Диджей
  decorator, // Оформитель
  catering, // Кейтеринг
  cleaning, // Клининг
  equipment, // Аренда свет/звук
  clothing, // Платья/костюмы
  fireShow, // Фаер-шоу
  fireworks, // Салюты
  lightShow, // Световые шоу
  florist, // Флорист
  coverBand, // Кавер-группа
  teamBuilding, // Тимбилдинг
}

/// Портфолио элемент
class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.type,
    required this.url,
    this.title,
    this.description,
    required this.createdAt,
  });

  factory PortfolioItem.fromMap(Map<String, dynamic> data) => PortfolioItem(
        id: data['id'] as String? ?? '',
        type: data['type'] as String? ?? 'photo',
        url: data['url'] as String? ?? '',
        title: data['title'],
        description: data['description'],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
  final String id;
  final String type; // 'photo', 'video', 'document'
  final String url;
  final String? title;
  final String? description;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'url': url,
        'title': title,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Профиль специалиста
class SpecialistProfile {
  const SpecialistProfile({
    required this.userId,
    this.name,
    this.photoURL,
    this.bio,
    this.categories = const [],
    this.experienceYears = 0,
    this.hourlyRate = 0.0,
    this.phoneNumber,
    this.location,
    this.socialLinks = const {},
    this.portfolio = const [],
    this.services = const [],
    this.workingHours,
    this.preferences,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.availability = const {},
    this.languages = const [],
    this.equipment = const [],
    this.insurance = false,
    this.licenses = const [],
    this.certifications = const [],
    this.awards = const [],
    this.testimonials = const [],
    this.email,
    this.website,
    this.instagram,
    this.vk,
    this.telegram,
    this.whatsapp,
    this.skype,
    this.zoom,
    this.portfolioVideos = const [],
    this.gallery = const [],
    this.reviews = const [],
    this.bookings = const [],
    this.earnings = const {},
    this.performance = const {},
    this.verification = const {},
    this.badges = const [],
    this.achievements = const [],
    this.analytics = const {},
    this.settings = const {},
    this.notifications = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать профиль из документа Firestore
  factory SpecialistProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistProfile(
      userId: doc.id,
      name: data['name'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      categories: (data['categories'] as List<dynamic>?)
              ?.map((e) => _parseCategory(e.toString()))
              .where((e) => e != null)
              .cast<SpecialistCategory>()
              .toList() ??
          [],
      experienceYears: data['experienceYears'] as int? ?? 0,
      hourlyRate: (data['hourlyRate'] as num? ?? 0.0).toDouble(),
      phoneNumber: data['phoneNumber'],
      location: data['location'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      portfolio: (data['portfolio'] as List<dynamic>?)
              ?.map((e) => PortfolioItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      services: List<String>.from(data['services'] ?? []),
      workingHours: data['workingHours'],
      preferences: data['preferences'],
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? true,
      availability: Map<String, dynamic>.from(data['availability'] ?? {}),
      languages: List<String>.from(data['languages'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      insurance: data['insurance'] as bool? ?? false,
      licenses: List<String>.from(data['licenses'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      awards: List<String>.from(data['awards'] ?? []),
      testimonials: List<String>.from(data['testimonials'] ?? []),
      email: data['email'],
      website: data['website'],
      instagram: data['instagram'],
      vk: data['vk'],
      telegram: data['telegram'],
      whatsapp: data['whatsapp'],
      skype: data['skype'],
      zoom: data['zoom'],
      portfolioVideos: List<String>.from(data['portfolioVideos'] ?? []),
      gallery: List<String>.from(data['gallery'] ?? []),
      reviews: List<dynamic>.from(data['reviews'] ?? []),
      bookings: List<dynamic>.from(data['bookings'] ?? []),
      earnings: Map<String, dynamic>.from(data['earnings'] ?? {}),
      performance: Map<String, dynamic>.from(data['performance'] ?? {}),
      verification: Map<String, dynamic>.from(data['verification'] ?? {}),
      badges: List<dynamic>.from(data['badges'] ?? []),
      achievements: List<dynamic>.from(data['achievements'] ?? []),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      notifications: Map<String, dynamic>.from(data['notifications'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Геттер для совместимости с avatarUrl
  String? get avatarUrl => photoURL;

  /// Геттер для специализации
  String get specialization =>
      categories.isNotEmpty ? categories.first.name : '';

  /// Геттер для id (совместимость)
  String get id => userId;
  final String userId;
  final String? name;
  final String? photoURL;
  final String? bio;
  final List<SpecialistCategory> categories;
  final int experienceYears;
  final double hourlyRate;
  final String? phoneNumber;
  final String? location;
  final Map<String, String> socialLinks; // 'vk', 'instagram', 'telegram', etc.
  final List<PortfolioItem> portfolio;
  final List<String> services;
  final Map<String, dynamic>? workingHours;
  final Map<String, dynamic>? preferences;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final Map<String, dynamic> availability;
  final List<String> languages;
  final List<String> equipment;
  final bool insurance;
  final List<String> licenses;
  final List<String> certifications;
  final List<String> awards;
  final List<String> testimonials;
  final String? email;
  final String? website;
  final String? instagram;
  final String? vk;
  final String? telegram;
  final String? whatsapp;
  final String? skype;
  final String? zoom;
  final List<String> portfolioVideos;
  final List<String> gallery;
  final List<dynamic> reviews;
  final List<dynamic> bookings;
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> verification;
  final List<dynamic> badges;
  final List<dynamic> achievements;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> notifications;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'photoURL': photoURL,
        'bio': bio,
        'categories': categories.map((e) => e.name).toList(),
        'experienceYears': experienceYears,
        'hourlyRate': hourlyRate,
        'phoneNumber': phoneNumber,
        'location': location,
        'socialLinks': socialLinks,
        'portfolio': portfolio.map((e) => e.toMap()).toList(),
        'services': services,
        'workingHours': workingHours,
        'preferences': preferences,
        'rating': rating,
        'reviewCount': reviewCount,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
        'availability': availability,
        'languages': languages,
        'equipment': equipment,
        'insurance': insurance,
        'licenses': licenses,
        'certifications': certifications,
        'awards': awards,
        'testimonials': testimonials,
        'email': email,
        'website': website,
        'instagram': instagram,
        'vk': vk,
        'telegram': telegram,
        'whatsapp': whatsapp,
        'skype': skype,
        'zoom': zoom,
        'portfolioVideos': portfolioVideos,
        'gallery': gallery,
        'reviews': reviews,
        'bookings': bookings,
        'earnings': earnings,
        'performance': performance,
        'verification': verification,
        'badges': badges,
        'achievements': achievements,
        'analytics': analytics,
        'settings': settings,
        'notifications': notifications,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Копировать с изменениями
  SpecialistProfile copyWith({
    String? userId,
    String? name,
    String? photoURL,
    String? bio,
    List<SpecialistCategory>? categories,
    int? experienceYears,
    double? hourlyRate,
    String? phoneNumber,
    String? location,
    Map<String, String>? socialLinks,
    List<PortfolioItem>? portfolio,
    List<String>? services,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? preferences,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isAvailable,
    Map<String, dynamic>? availability,
    List<String>? languages,
    List<String>? equipment,
    bool? insurance,
    List<String>? licenses,
    List<String>? certifications,
    List<String>? awards,
    List<String>? testimonials,
    String? email,
    String? website,
    String? instagram,
    String? vk,
    String? telegram,
    String? whatsapp,
    String? skype,
    String? zoom,
    List<String>? portfolioVideos,
    List<String>? gallery,
    List<dynamic>? reviews,
    List<dynamic>? bookings,
    Map<String, dynamic>? earnings,
    Map<String, dynamic>? performance,
    Map<String, dynamic>? verification,
    List<dynamic>? badges,
    List<dynamic>? achievements,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SpecialistProfile(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        photoURL: photoURL ?? this.photoURL,
        bio: bio ?? this.bio,
        categories: categories ?? this.categories,
        experienceYears: experienceYears ?? this.experienceYears,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        location: location ?? this.location,
        socialLinks: socialLinks ?? this.socialLinks,
        portfolio: portfolio ?? this.portfolio,
        services: services ?? this.services,
        workingHours: workingHours ?? this.workingHours,
        preferences: preferences ?? this.preferences,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        isVerified: isVerified ?? this.isVerified,
        isAvailable: isAvailable ?? this.isAvailable,
        availability: availability ?? this.availability,
        languages: languages ?? this.languages,
        equipment: equipment ?? this.equipment,
        insurance: insurance ?? this.insurance,
        licenses: licenses ?? this.licenses,
        certifications: certifications ?? this.certifications,
        awards: awards ?? this.awards,
        testimonials: testimonials ?? this.testimonials,
        email: email ?? this.email,
        website: website ?? this.website,
        instagram: instagram ?? this.instagram,
        vk: vk ?? this.vk,
        telegram: telegram ?? this.telegram,
        whatsapp: whatsapp ?? this.whatsapp,
        skype: skype ?? this.skype,
        zoom: zoom ?? this.zoom,
        portfolioVideos: portfolioVideos ?? this.portfolioVideos,
        gallery: gallery ?? this.gallery,
        reviews: reviews ?? this.reviews,
        bookings: bookings ?? this.bookings,
        earnings: earnings ?? this.earnings,
        performance: performance ?? this.performance,
        verification: verification ?? this.verification,
        badges: badges ?? this.badges,
        achievements: achievements ?? this.achievements,
        analytics: analytics ?? this.analytics,
        settings: settings ?? this.settings,
        notifications: notifications ?? this.notifications,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить русские названия категорий
  List<String> get categoryDisplayNames => categories.map((category) {
        switch (category) {
          case SpecialistCategory.host:
            return 'Ведущий';
          case SpecialistCategory.photographer:
            return 'Фотограф';
          case SpecialistCategory.animator:
            return 'Аниматор';
          case SpecialistCategory.dj:
            return 'Диджей';
          case SpecialistCategory.decorator:
            return 'Оформитель';
          case SpecialistCategory.catering:
            return 'Кейтеринг';
          case SpecialistCategory.cleaning:
            return 'Клининг';
          case SpecialistCategory.equipment:
            return 'Аренда свет/звук';
          case SpecialistCategory.clothing:
            return 'Платья/костюмы';
          case SpecialistCategory.fireShow:
            return 'Фаер-шоу';
          case SpecialistCategory.fireworks:
            return 'Салюты';
          case SpecialistCategory.lightShow:
            return 'Световые шоу';
          case SpecialistCategory.florist:
            return 'Флорист';
          case SpecialistCategory.coverBand:
            return 'Кавер-группа';
          case SpecialistCategory.teamBuilding:
            return 'Тимбилдинг';
        }
      }).toList();

  /// Получить основную категорию
  String get primaryCategory {
    if (categories.isEmpty) return 'Специалист';
    return categoryDisplayNames.first;
  }

  /// Проверить, есть ли портфолио
  bool get hasPortfolio => portfolio.isNotEmpty;

  /// Получить фото из портфолио
  List<PortfolioItem> get photos =>
      portfolio.where((item) => item.type == 'photo').toList();

  /// Получить видео из портфолио
  List<PortfolioItem> get videos =>
      portfolio.where((item) => item.type == 'video').toList();

  /// Получить документы из портфолио
  List<PortfolioItem> get documents =>
      portfolio.where((item) => item.type == 'document').toList();

  /// Получить отображаемое имя специалиста
  String get displayName => name ?? 'Специалист';

  /// Проверить, доступен ли специалист
  bool get isCurrentlyAvailable => isAvailable && !_isCurrentlyBusy();

  /// Проверить, занят ли специалист сейчас
  bool _isCurrentlyBusy() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Проверяем занятые даты
    if (availability.containsKey('busyDates')) {
      final busyDates = availability['busyDates'] as List<dynamic>? ?? [];
      for (final date in busyDates) {
        if (date is String) {
          final busyDate = DateTime.tryParse(date);
          if (busyDate != null &&
              busyDate.year == today.year &&
              busyDate.month == today.month &&
              busyDate.day == today.day) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Получить список занятых дат
  List<DateTime> get busyDates {
    final dates = <DateTime>[];
    if (availability.containsKey('busyDates')) {
      final busyDates = availability['busyDates'] as List<dynamic>? ?? [];
      for (final date in busyDates) {
        if (date is String) {
          final parsedDate = DateTime.tryParse(date);
          if (parsedDate != null) {
            dates.add(parsedDate);
          }
        }
      }
    }
    return dates;
  }

  /// Добавить занятую дату
  SpecialistProfile addBusyDate(DateTime date) {
    final newBusyDates = List<DateTime>.from(busyDates)..add(date);
    final newAvailability = Map<String, dynamic>.from(availability);
    newAvailability['busyDates'] =
        newBusyDates.map((d) => d.toIso8601String()).toList();

    return copyWith(
      availability: newAvailability,
      updatedAt: DateTime.now(),
    );
  }

  /// Удалить занятую дату
  SpecialistProfile removeBusyDate(DateTime date) {
    final newBusyDates = busyDates
        .where(
          (d) => !(d.year == date.year &&
              d.month == date.month &&
              d.day == date.day),
        )
        .toList();
    final newAvailability = Map<String, dynamic>.from(availability);
    newAvailability['busyDates'] =
        newBusyDates.map((d) => d.toIso8601String()).toList();

    return copyWith(
      availability: newAvailability,
      updatedAt: DateTime.now(),
    );
  }

  /// Получить средний рейтинг
  double get averageRating => rating;

  /// Получить количество отзывов
  int get totalReviews => reviewCount;

  /// Проверить, есть ли сертификаты
  bool get hasCertifications => certifications.isNotEmpty;

  /// Проверить, есть ли награды
  bool get hasAwards => awards.isNotEmpty;

  /// Получить список языков
  String get languagesString => languages.join(', ');

  /// Получить список оборудования
  String get equipmentString => equipment.join(', ');

  /// Получить социальные сети
  Map<String, String> get allSocialLinks => {
        if (instagram != null) 'instagram': instagram!,
        if (vk != null) 'vk': vk!,
        if (telegram != null) 'telegram': telegram!,
        if (whatsapp != null) 'whatsapp': whatsapp!,
        if (skype != null) 'skype': skype!,
        if (zoom != null) 'zoom': zoom!,
        if (website != null) 'website': website!,
        ...socialLinks,
      };

  /// Парсинг категории из строки
  static SpecialistCategory? _parseCategory(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'host':
        return SpecialistCategory.host;
      case 'photographer':
        return SpecialistCategory.photographer;
      case 'animator':
        return SpecialistCategory.animator;
      case 'dj':
        return SpecialistCategory.dj;
      case 'decorator':
        return SpecialistCategory.decorator;
      case 'catering':
        return SpecialistCategory.catering;
      case 'cleaning':
        return SpecialistCategory.cleaning;
      case 'equipment':
        return SpecialistCategory.equipment;
      case 'clothing':
        return SpecialistCategory.clothing;
      case 'fireshow':
        return SpecialistCategory.fireShow;
      case 'fireworks':
        return SpecialistCategory.fireworks;
      case 'lightshow':
        return SpecialistCategory.lightShow;
      case 'florist':
        return SpecialistCategory.florist;
      case 'coverband':
        return SpecialistCategory.coverBand;
      case 'teambuilding':
        return SpecialistCategory.teamBuilding;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'SpecialistProfile(userId: $userId, categories: $categories, rating: $rating)';
}
