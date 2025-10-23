import 'package:cloud_firestore/cloud_firestore.dart';

/// Профиль организатора мероприятий
class OrganizerProfile {
  const OrganizerProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.logoUrl,
    this.phone,
    this.email,
    this.website,
    this.location,
    this.categories = const [],
    this.pastEvents = const [],
    this.teamMembers = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    this.experienceYears = 0,
    this.specializations = const [],
    this.portfolioImages = const [],
    this.portfolioVideos = const [],
    this.socialLinks = const {},
    this.workingHours,
    this.responseTime,
    this.minBudget,
    this.maxBudget,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать профиль из документа Firestore
  factory OrganizerProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return OrganizerProfile(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      logoUrl: data['logoUrl'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      location: data['location'] as String?,
      categories: List<String>.from(data['categories'] as List<dynamic>? ?? []),
      pastEvents: List<String>.from(data['pastEvents'] as List<dynamic>? ?? []),
      teamMembers:
          List<String>.from(data['teamMembers'] as List<dynamic>? ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      experienceYears: data['experienceYears'] as int? ?? 0,
      specializations:
          List<String>.from(data['specializations'] as List<dynamic>? ?? []),
      portfolioImages:
          List<String>.from(data['portfolioImages'] as List<dynamic>? ?? []),
      portfolioVideos:
          List<String>.from(data['portfolioVideos'] as List<dynamic>? ?? []),
      socialLinks: Map<String, String>.from(
          data['socialLinks'] as Map<dynamic, dynamic>? ?? {}),
      workingHours: data['workingHours'] as Map<String, dynamic>?,
      responseTime: data['responseTime'] as String?,
      minBudget: (data['minBudget'] as num?)?.toDouble(),
      maxBudget: (data['maxBudget'] as num?)?.toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? phone;
  final String? email;
  final String? website;
  final String? location;
  final List<String> categories;
  final List<String> pastEvents;
  final List<String> teamMembers;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final int experienceYears;
  final List<String> specializations;
  final List<String> portfolioImages;
  final List<String> portfolioVideos;
  final Map<String, String> socialLinks;
  final Map<String, dynamic>? workingHours;
  final String? responseTime;
  final double? minBudget;
  final double? maxBudget;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'phone': phone,
        'email': email,
        'website': website,
        'location': location,
        'categories': categories,
        'pastEvents': pastEvents,
        'teamMembers': teamMembers,
        'rating': rating,
        'reviewCount': reviewCount,
        'isVerified': isVerified,
        'isActive': isActive,
        'experienceYears': experienceYears,
        'specializations': specializations,
        'portfolioImages': portfolioImages,
        'portfolioVideos': portfolioVideos,
        'socialLinks': socialLinks,
        'workingHours': workingHours,
        'responseTime': responseTime,
        'minBudget': minBudget,
        'maxBudget': maxBudget,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  OrganizerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? logoUrl,
    String? phone,
    String? email,
    String? website,
    String? location,
    List<String>? categories,
    List<String>? pastEvents,
    List<String>? teamMembers,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isActive,
    int? experienceYears,
    List<String>? specializations,
    List<String>? portfolioImages,
    List<String>? portfolioVideos,
    Map<String, String>? socialLinks,
    Map<String, dynamic>? workingHours,
    String? responseTime,
    double? minBudget,
    double? maxBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      OrganizerProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description ?? this.description,
        logoUrl: logoUrl ?? this.logoUrl,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        location: location ?? this.location,
        categories: categories ?? this.categories,
        pastEvents: pastEvents ?? this.pastEvents,
        teamMembers: teamMembers ?? this.teamMembers,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        experienceYears: experienceYears ?? this.experienceYears,
        specializations: specializations ?? this.specializations,
        portfolioImages: portfolioImages ?? this.portfolioImages,
        portfolioVideos: portfolioVideos ?? this.portfolioVideos,
        socialLinks: socialLinks ?? this.socialLinks,
        workingHours: workingHours ?? this.workingHours,
        responseTime: responseTime ?? this.responseTime,
        minBudget: minBudget ?? this.minBudget,
        maxBudget: maxBudget ?? this.maxBudget,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить отображаемое имя
  String get displayName => name.isNotEmpty ? name : 'Организатор';

  /// Получить краткое описание
  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return 'Организатор мероприятий';
    }
    if (description!.length <= 100) {
      return description!;
    }
    return '${description!.substring(0, 100)}...';
  }

  /// Получить форматированный рейтинг
  String get formattedRating => rating.toStringAsFixed(1);

  /// Получить форматированный бюджет
  String get formattedBudget {
    if (minBudget == null && maxBudget == null) {
      return 'По договоренности';
    }
    if (minBudget != null && maxBudget != null) {
      return '${minBudget!.toStringAsFixed(0)} - ${maxBudget!.toStringAsFixed(0)} ₽';
    }
    if (minBudget != null) {
      return 'от ${minBudget!.toStringAsFixed(0)} ₽';
    }
    return 'до ${maxBudget!.toStringAsFixed(0)} ₽';
  }

  /// Получить опыт работы в текстовом формате
  String get experienceText {
    if (experienceYears == 0) {
      return 'Новичок';
    }
    if (experienceYears == 1) {
      return '1 год опыта';
    }
    if (experienceYears < 5) {
      return '$experienceYears года опыта';
    }
    return '$experienceYears лет опыта';
  }

  /// Проверить, есть ли портфолио
  bool get hasPortfolio =>
      portfolioImages.isNotEmpty || portfolioVideos.isNotEmpty;

  /// Получить количество проектов
  int get projectCount => pastEvents.length;

  /// Проверить, верифицирован ли организатор
  bool get isVerifiedOrganizer => isVerified;

  /// Получить статус активности
  String get statusText => isActive ? 'Активен' : 'Неактивен';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizerProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrganizerProfile(id: $id, name: $name, rating: $rating)';
}

/// Категории мероприятий для организаторов
enum EventCategory {
  wedding, // Свадьбы
  corporate, // Корпоративы
  birthday, // Дни рождения
  anniversary, // Юбилеи
  conference, // Конференции
  exhibition, // Выставки
  festival, // Фестивали
  concert, // Концерты
  party, // Вечеринки
  graduation, // Выпускные
  holiday, // Праздники
  other, // Другое
}

/// Расширение для EventCategory
extension EventCategoryExtension on EventCategory {
  String get displayName {
    switch (this) {
      case EventCategory.wedding:
        return 'Свадьбы';
      case EventCategory.corporate:
        return 'Корпоративы';
      case EventCategory.birthday:
        return 'Дни рождения';
      case EventCategory.anniversary:
        return 'Юбилеи';
      case EventCategory.conference:
        return 'Конференции';
      case EventCategory.exhibition:
        return 'Выставки';
      case EventCategory.festival:
        return 'Фестивали';
      case EventCategory.concert:
        return 'Концерты';
      case EventCategory.party:
        return 'Вечеринки';
      case EventCategory.graduation:
        return 'Выпускные';
      case EventCategory.holiday:
        return 'Праздники';
      case EventCategory.other:
        return 'Другое';
    }
  }

  String get icon {
    switch (this) {
      case EventCategory.wedding:
        return '💒';
      case EventCategory.corporate:
        return '🏢';
      case EventCategory.birthday:
        return '🎂';
      case EventCategory.anniversary:
        return '🎊';
      case EventCategory.conference:
        return '🎤';
      case EventCategory.exhibition:
        return '🎨';
      case EventCategory.festival:
        return '🎪';
      case EventCategory.concert:
        return '🎵';
      case EventCategory.party:
        return '🎉';
      case EventCategory.graduation:
        return '🎓';
      case EventCategory.holiday:
        return '🎄';
      case EventCategory.other:
        return '📅';
    }
  }
}
