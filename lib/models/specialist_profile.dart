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
        id: data['id'] ?? '',
        type: data['type'] ?? 'photo',
        url: data['url'] ?? '',
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
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать профиль из документа Firestore
  factory SpecialistProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistProfile(
      userId: doc.id,
      photoURL: data['photoURL'],
      bio: data['bio'],
      categories: (data['categories'] as List<dynamic>?)
              ?.map((e) => _parseCategory(e.toString()))
              .where((e) => e != null)
              .cast<SpecialistCategory>()
              .toList() ??
          [],
      experienceYears: data['experienceYears'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
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
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  final String userId;
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
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
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
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Копировать с изменениями
  SpecialistProfile copyWith({
    String? userId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SpecialistProfile(
        userId: userId ?? this.userId,
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
