import 'package:cloud_firestore/cloud_firestore.dart';

import 'enhanced_specialist_category.dart';

/// Расширенная модель специалиста
class EnhancedSpecialist {
  const EnhancedSpecialist({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.categories,
    required this.location,
    required this.rating,
    required this.reviewsCount,
    required this.isActive,
    required this.createdAt,
    this.avatarUrl,
    this.description,
    this.bio,
    this.experience,
    this.languages = const [],
    this.portfolio = const [],
    this.services = const [],
    this.pricing = const {},
    this.availability = const {},
    this.discounts = const {},
    this.socialLinks = const {},
    this.verificationStatus = VerificationStatus.pending,
    this.isVerified = false,
    this.isPremium = false,
    this.responseTime,
    this.completionRate,
    this.cancellationRate,
    this.averageOrderValue,
    this.totalOrders,
    this.lastActiveAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final List<EnhancedSpecialistCategory> categories;
  final String location;
  final double rating;
  final int reviewsCount;
  final bool isActive;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? description;
  final String? bio;
  final int? experience;
  final List<String> languages;
  final List<PortfolioItem> portfolio;
  final List<SpecialistService> services;
  final Map<String, PricingTier> pricing;
  final Map<String, AvailabilitySlot> availability;
  final Map<String, Discount> discounts;
  final Map<String, String> socialLinks;
  final VerificationStatus verificationStatus;
  final bool isVerified;
  final bool isPremium;
  final Duration? responseTime;
  final double? completionRate;
  final double? cancellationRate;
  final double? averageOrderValue;
  final int? totalOrders;
  final DateTime? lastActiveAt;
  final DateTime? updatedAt;

  /// Создать из документа Firestore
  factory EnhancedSpecialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EnhancedSpecialist(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      categories: (data['categories'] as List<dynamic>?)
          ?.map((cat) => EnhancedSpecialistCategory.values.firstWhere(
                (e) => e.name == cat,
                orElse: () => EnhancedSpecialistCategory.photography,
              ))
          .toList() ?? [],
      location: data['location'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: data['reviewsCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'] as String?,
      description: data['description'] as String?,
      bio: data['bio'] as String?,
      experience: data['experience'] as int?,
      languages: List<String>.from(data['languages'] ?? []),
      portfolio: (data['portfolio'] as List<dynamic>?)
          ?.map((item) => PortfolioItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      services: (data['services'] as List<dynamic>?)
          ?.map((service) => SpecialistService.fromMap(service as Map<String, dynamic>))
          .toList() ?? [],
      pricing: (data['pricing'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, PricingTier.fromMap(value as Map<String, dynamic>)),
      ) ?? {},
      availability: (data['availability'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, AvailabilitySlot.fromMap(value as Map<String, dynamic>)),
      ) ?? {},
      discounts: (data['discounts'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, Discount.fromMap(value as Map<String, dynamic>)),
      ) ?? {},
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      isVerified: data['isVerified'] as bool? ?? false,
      isPremium: data['isPremium'] as bool? ?? false,
      responseTime: data['responseTime'] != null
          ? Duration(milliseconds: data['responseTime'] as int)
          : null,
      completionRate: (data['completionRate'] as num?)?.toDouble(),
      cancellationRate: (data['cancellationRate'] as num?)?.toDouble(),
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble(),
      totalOrders: data['totalOrders'] as int?,
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'categories': categories.map((cat) => cat.name).toList(),
    'location': location,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'avatarUrl': avatarUrl,
    'description': description,
    'bio': bio,
    'experience': experience,
    'languages': languages,
    'portfolio': portfolio.map((item) => item.toMap()).toList(),
    'services': services.map((service) => service.toMap()).toList(),
    'pricing': pricing.map((key, value) => MapEntry(key, value.toMap())),
    'availability': availability.map((key, value) => MapEntry(key, value.toMap())),
    'discounts': discounts.map((key, value) => MapEntry(key, value.toMap())),
    'socialLinks': socialLinks,
    'verificationStatus': verificationStatus.name,
    'isVerified': isVerified,
    'isPremium': isPremium,
    'responseTime': responseTime?.inMilliseconds,
    'completionRate': completionRate,
    'cancellationRate': cancellationRate,
    'averageOrderValue': averageOrderValue,
    'totalOrders': totalOrders,
    'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Получить минимальную цену
  double get minPrice {
    if (pricing.isEmpty) return 0.0;
    return pricing.values.map((tier) => tier.price).reduce((a, b) => a < b ? a : b);
  }

  /// Получить максимальную цену
  double get maxPrice {
    if (pricing.isEmpty) return 0.0;
    return pricing.values.map((tier) => tier.price).reduce((a, b) => a > b ? a : b);
  }

  /// Проверить доступность на дату
  bool isAvailableOn(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return availability.containsKey(dateKey) && availability[dateKey]!.isAvailable;
  }

  /// Получить активные скидки
  List<Discount> get activeDiscounts {
    final now = DateTime.now();
    return discounts.values.where((discount) => 
        discount.isActive && 
        (discount.validUntil == null || discount.validUntil!.isAfter(now))
    ).toList();
  }
}

/// Статус верификации
enum VerificationStatus {
  pending,
  verified,
  rejected,
  suspended,
}

/// Элемент портфолио
class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.category,
    this.tags = const [],
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String mediaUrl;
  final MediaType mediaType;
  final String category;
  final List<String> tags;
  final DateTime? createdAt;

  /// Создать из Map
  factory PortfolioItem.fromMap(Map<String, dynamic> data) => PortfolioItem(
    id: data['id'] as String? ?? '',
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    mediaUrl: data['mediaUrl'] as String? ?? '',
    mediaType: MediaType.values.firstWhere(
      (type) => type.name == data['mediaType'],
      orElse: () => MediaType.image,
    ),
    category: data['category'] as String? ?? '',
    tags: List<String>.from(data['tags'] ?? []),
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType.name,
    'category': category,
    'tags': tags,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };
}

/// Тип медиа
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// Услуга специалиста
class SpecialistService {
  const SpecialistService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    this.features = const [],
    this.requirements = const [],
    this.isPopular = false,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final Duration duration;
  final String category;
  final List<String> features;
  final List<String> requirements;
  final bool isPopular;

  /// Создать из Map
  factory SpecialistService.fromMap(Map<String, dynamic> data) => SpecialistService(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    description: data['description'] as String? ?? '',
    price: (data['price'] as num).toDouble(),
    duration: Duration(minutes: data['duration'] as int? ?? 60),
    category: data['category'] as String? ?? '',
    features: List<String>.from(data['features'] ?? []),
    requirements: List<String>.from(data['requirements'] ?? []),
    isPopular: data['isPopular'] as bool? ?? false,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'duration': duration.inMinutes,
    'category': category,
    'features': features,
    'requirements': requirements,
    'isPopular': isPopular,
  };
}

/// Тарифный план
class PricingTier {
  const PricingTier({
    required this.name,
    required this.price,
    required this.description,
    this.features = const [],
    this.isPopular = false,
  });

  final String name;
  final double price;
  final String description;
  final List<String> features;
  final bool isPopular;

  /// Создать из Map
  factory PricingTier.fromMap(Map<String, dynamic> data) => PricingTier(
    name: data['name'] as String? ?? '',
    price: (data['price'] as num).toDouble(),
    description: data['description'] as String? ?? '',
    features: List<String>.from(data['features'] ?? []),
    isPopular: data['isPopular'] as bool? ?? false,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'description': description,
    'features': features,
    'isPopular': isPopular,
  };
}

/// Слот доступности
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.date,
    required this.isAvailable,
    this.timeSlots = const [],
    this.notes,
  });

  final DateTime date;
  final bool isAvailable;
  final List<TimeSlot> timeSlots;
  final String? notes;

  /// Создать из Map
  factory AvailabilitySlot.fromMap(Map<String, dynamic> data) => AvailabilitySlot(
    date: (data['date'] as Timestamp).toDate(),
    isAvailable: data['isAvailable'] as bool? ?? false,
    timeSlots: (data['timeSlots'] as List<dynamic>?)
        ?.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
        .toList() ?? [],
    notes: data['notes'] as String?,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'isAvailable': isAvailable,
    'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
    'notes': notes,
  };
}

/// Временной слот
class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.price,
  });

  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final double? price;

  /// Создать из Map
  factory TimeSlot.fromMap(Map<String, dynamic> data) => TimeSlot(
    startTime: (data['startTime'] as Timestamp).toDate(),
    endTime: (data['endTime'] as Timestamp).toDate(),
    isAvailable: data['isAvailable'] as bool? ?? false,
    price: (data['price'] as num?)?.toDouble(),
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'isAvailable': isAvailable,
    'price': price,
  };
}

/// Скидка
class Discount {
  const Discount({
    required this.id,
    required this.name,
    required this.discountType,
    required this.value,
    required this.isActive,
    this.validFrom,
    this.validUntil,
    this.minOrderValue,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount = 0,
  });

  final String id;
  final String name;
  final DiscountType discountType;
  final double value;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;

  /// Создать из Map
  factory Discount.fromMap(Map<String, dynamic> data) => Discount(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    discountType: DiscountType.values.firstWhere(
      (type) => type.name == data['discountType'],
      orElse: () => DiscountType.percentage,
    ),
    value: (data['value'] as num).toDouble(),
    isActive: data['isActive'] as bool? ?? false,
    validFrom: data['validFrom'] != null
        ? (data['validFrom'] as Timestamp).toDate()
        : null,
    validUntil: data['validUntil'] != null
        ? (data['validUntil'] as Timestamp).toDate()
        : null,
    minOrderValue: (data['minOrderValue'] as num?)?.toDouble(),
    maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
    usageLimit: data['usageLimit'] as int?,
    usedCount: data['usedCount'] as int? ?? 0,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'discountType': discountType.name,
    'value': value,
    'isActive': isActive,
    'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
    'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
    'minOrderValue': minOrderValue,
    'maxDiscountAmount': maxDiscountAmount,
    'usageLimit': usageLimit,
    'usedCount': usedCount,
  };
}

/// Тип скидки
enum DiscountType {
  percentage,
  fixed,
}
