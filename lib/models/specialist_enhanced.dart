import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенная модель специалиста с рейтингами и категориями
class SpecialistEnhanced {
  final String id;
  final String name;
  final String specialization;
  final String city;
  final String region;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final int totalOrders;
  final int successfulOrders;
  final List<String> categories;
  final List<String> languages;
  final Map<String, dynamic> pricing;
  final List<String> availableDates;
  final List<String> imageUrls;
  final bool isVerified;
  final bool isTopWeek;
  final bool isNewcomer;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> location;
  final Map<String, dynamic> socialLinks;
  final List<String> skills;
  final String experience;
  final String education;
  final List<Review> reviews;
  final Map<String, dynamic> stats;

  const SpecialistEnhanced({
    required this.id,
    required this.name,
    required this.specialization,
    required this.city,
    required this.region,
    this.avatarUrl,
    this.bio,
    required this.rating,
    required this.totalOrders,
    required this.successfulOrders,
    required this.categories,
    required this.languages,
    required this.pricing,
    required this.availableDates,
    required this.imageUrls,
    required this.isVerified,
    required this.isTopWeek,
    required this.isNewcomer,
    required this.createdAt,
    required this.lastActive,
    required this.location,
    required this.socialLinks,
    required this.skills,
    required this.experience,
    required this.education,
    required this.reviews,
    required this.stats,
  });

  factory SpecialistEnhanced.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialistEnhanced(
      id: doc.id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      city: data['city'] ?? '',
      region: data['region'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      successfulOrders: data['successfulOrders'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      pricing: Map<String, dynamic>.from(data['pricing'] ?? {}),
      availableDates: List<String>.from(data['availableDates'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isVerified: data['isVerified'] ?? false,
      isTopWeek: data['isTopWeek'] ?? false,
      isNewcomer: data['isNewcomer'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      location: Map<String, dynamic>.from(data['location'] ?? {}),
      socialLinks: Map<String, dynamic>.from(data['socialLinks'] ?? {}),
      skills: List<String>.from(data['skills'] ?? []),
      experience: data['experience'] ?? '',
      education: data['education'] ?? '',
      reviews: (data['reviews'] as List<dynamic>? ?? [])
          .map((review) => Review.fromMap(review))
          .toList(),
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialization': specialization,
      'city': city,
      'region': region,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'rating': rating,
      'totalOrders': totalOrders,
      'successfulOrders': successfulOrders,
      'categories': categories,
      'languages': languages,
      'pricing': pricing,
      'availableDates': availableDates,
      'imageUrls': imageUrls,
      'isVerified': isVerified,
      'isTopWeek': isTopWeek,
      'isNewcomer': isNewcomer,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'location': location,
      'socialLinks': socialLinks,
      'skills': skills,
      'experience': experience,
      'education': education,
      'reviews': reviews.map((review) => review.toMap()).toList(),
      'stats': stats,
    };
  }

  /// Получить успешность в процентах
  double get successRate {
    if (totalOrders == 0) return 0.0;
    return (successfulOrders / totalOrders) * 100;
  }

  /// Получить минимальную цену
  double get minPrice {
    if (pricing.isEmpty) return 0.0;
    final prices = pricing.values.whereType<double>().toList();
    if (prices.isEmpty) return 0.0;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  /// Получить максимальную цену
  double get maxPrice {
    if (pricing.isEmpty) return 0.0;
    final prices = pricing.values.whereType<double>().toList();
    if (prices.isEmpty) return 0.0;
    return prices.reduce((a, b) => a > b ? a : b);
  }

  /// Проверить, активен ли специалист
  bool get isActive {
    final now = DateTime.now();
    final daysSinceLastActive = now.difference(lastActive).inDays;
    return daysSinceLastActive <= 7;
  }

  /// Получить бейджи для отображения
  List<SpecialistBadge> get badges {
    final badges = <SpecialistBadge>[];

    if (isTopWeek) badges.add(SpecialistBadge.topWeek);
    if (isVerified) badges.add(SpecialistBadge.verified);
    if (isNewcomer) badges.add(SpecialistBadge.newcomer);
    if (rating >= 4.8) badges.add(SpecialistBadge.highRating);
    if (successRate >= 95) badges.add(SpecialistBadge.reliable);
    if (totalOrders >= 100) badges.add(SpecialistBadge.experienced);

    return badges;
  }

  /// Копировать с изменениями
  SpecialistEnhanced copyWith({
    String? id,
    String? name,
    String? specialization,
    String? city,
    String? region,
    String? avatarUrl,
    String? bio,
    double? rating,
    int? totalOrders,
    int? successfulOrders,
    List<String>? categories,
    List<String>? languages,
    Map<String, dynamic>? pricing,
    List<String>? availableDates,
    List<String>? imageUrls,
    bool? isVerified,
    bool? isTopWeek,
    bool? isNewcomer,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? location,
    Map<String, dynamic>? socialLinks,
    List<String>? skills,
    String? experience,
    String? education,
    List<Review>? reviews,
    Map<String, dynamic>? stats,
  }) {
    return SpecialistEnhanced(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      city: city ?? this.city,
      region: region ?? this.region,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      successfulOrders: successfulOrders ?? this.successfulOrders,
      categories: categories ?? this.categories,
      languages: languages ?? this.languages,
      pricing: pricing ?? this.pricing,
      availableDates: availableDates ?? this.availableDates,
      imageUrls: imageUrls ?? this.imageUrls,
      isVerified: isVerified ?? this.isVerified,
      isTopWeek: isTopWeek ?? this.isTopWeek,
      isNewcomer: isNewcomer ?? this.isNewcomer,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      location: location ?? this.location,
      socialLinks: socialLinks ?? this.socialLinks,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      reviews: reviews ?? this.reviews,
      stats: stats ?? this.stats,
    );
  }
}

/// Модель отзыва
class Review {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.images,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'images': images,
    };
  }
}

/// Бейджи специалистов
enum SpecialistBadge {
  topWeek('🏆', 'ТОП недели', 0xFFD97706),
  verified('✅', 'Проверенный', 0xFF10B981),
  newcomer('🌱', 'Новичок', 0xFF3B82F6),
  highRating('⭐', 'Высокий рейтинг', 0xFFF59E0B),
  reliable('🛡️', 'Надежный', 0xFF8B5CF6),
  experienced('🎯', 'Опытный', 0xFFEF4444);

  const SpecialistBadge(this.emoji, this.label, this.color);

  final String emoji;
  final String label;
  final int color;
}

/// Категории специалистов
enum SpecialistCategory {
  host('🎤', 'Ведущие', 'Ведущие мероприятий'),
  photographer('📸', 'Фотографы', 'Фото и видеосъемка'),
  catering('🥂', 'Кейтеринг', 'Питание и напитки'),
  decor('🎨', 'Декор', 'Оформление и дизайн'),
  music('🎵', 'Музыка', 'Музыканты и DJ'),
  security('🛡️', 'Охрана', 'Безопасность'),
  transport('🚗', 'Транспорт', 'Логистика и перевозки'),
  technical('⚙️', 'Техника', 'Аудио, видео, свет'),
  entertainment('🎪', 'Развлечения', 'Аниматоры и артисты'),
  beauty('💄', 'Красота', 'Визажисты и стилисты');

  const SpecialistCategory(this.emoji, this.name, this.description);

  final String emoji;
  final String name;
  final String description;
}

/// Фильтры поиска
class SearchFilters {
  final String? city;
  final String? region;
  final List<String> categories;
  final double? minRating;
  final double? maxRating;
  final double? minPrice;
  final double? maxPrice;
  final List<String> availableDates;
  final double? radiusKm;
  final List<String> languages;
  final bool? isVerified;
  final bool? isTopWeek;
  final bool? isNewcomer;
  final String? experience;
  final String? sortBy;

  const SearchFilters({
    this.city,
    this.region,
    this.categories = const [],
    this.minRating,
    this.maxRating,
    this.minPrice,
    this.maxPrice,
    this.availableDates = const [],
    this.radiusKm,
    this.languages = const [],
    this.isVerified,
    this.isTopWeek,
    this.isNewcomer,
    this.experience,
    this.sortBy,
  });

  SearchFilters copyWith({
    String? city,
    String? region,
    List<String>? categories,
    double? minRating,
    double? maxRating,
    double? minPrice,
    double? maxPrice,
    List<String>? availableDates,
    double? radiusKm,
    List<String>? languages,
    bool? isVerified,
    bool? isTopWeek,
    bool? isNewcomer,
    String? experience,
    String? sortBy,
  }) {
    return SearchFilters(
      city: city ?? this.city,
      region: region ?? this.region,
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      availableDates: availableDates ?? this.availableDates,
      radiusKm: radiusKm ?? this.radiusKm,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      isTopWeek: isTopWeek ?? this.isTopWeek,
      isNewcomer: isNewcomer ?? this.isNewcomer,
      experience: experience ?? this.experience,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Проверить, есть ли активные фильтры
  bool get hasActiveFilters {
    return city != null ||
        region != null ||
        categories.isNotEmpty ||
        minRating != null ||
        maxRating != null ||
        minPrice != null ||
        maxPrice != null ||
        availableDates.isNotEmpty ||
        radiusKm != null ||
        languages.isNotEmpty ||
        isVerified != null ||
        isTopWeek != null ||
        isNewcomer != null ||
        experience != null ||
        sortBy != null;
  }

  /// Сбросить все фильтры
  SearchFilters clear() {
    return const SearchFilters();
  }
}
