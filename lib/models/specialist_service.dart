import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип цены услуги
enum ServicePriceType {
  fixed, // Фиксированная цена
  hourly, // Почасовая оплата
  daily, // Дневная оплата
  perPerson, // За человека
  perEvent, // За мероприятие
  custom, // Индивидуальная
}

/// Единица измерения цены
enum PriceUnit {
  rubles, // Рубли
  dollars, // Доллары
  euros, // Евро
}

/// Модель услуги специалиста
class SpecialistService {
  const SpecialistService({
    required this.id,
    required this.specialistId,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    this.originalPrice,
    this.discount,
    this.currency = PriceUnit.rubles,
    this.duration,
    this.minDuration,
    this.maxDuration,
    this.requirements = const [],
    this.includes = const [],
    this.excludes = const [],
    this.images = const [],
    this.videos = const [],
    this.tags = const [],
    this.category,
    this.subcategory,
    this.isActive = true,
    this.isPopular = false,
    this.isRecommended = false,
    this.bookingCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.lastBookedAt,
    this.avgBookingPrice,
    this.totalEarnings,
  });

  /// Создать из документа Firestore
  factory SpecialistService.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistService(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      priceType: ServicePriceType.values.firstWhere(
        (e) => e.name == data['priceType'],
        orElse: () => ServicePriceType.fixed,
      ),
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] as num).toDouble()
          : null,
      discount: data['discount'] as int?,
      currency: PriceUnit.values.firstWhere(
        (e) => e.name == data['currency'],
        orElse: () => PriceUnit.rubles,
      ),
      duration: data['duration'] as String?,
      minDuration: data['minDuration'] as int?,
      maxDuration: data['maxDuration'] as int?,
      requirements: List<String>.from(data['requirements'] ?? []),
      includes: List<String>.from(data['includes'] ?? []),
      excludes: List<String>.from(data['excludes'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] as String?,
      subcategory: data['subcategory'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isPopular: data['isPopular'] as bool? ?? false,
      isRecommended: data['isRecommended'] as bool? ?? false,
      bookingCount: data['bookingCount'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      lastBookedAt: data['lastBookedAt'] != null
          ? (data['lastBookedAt'] as Timestamp).toDate()
          : null,
      avgBookingPrice: data['avgBookingPrice'] != null
          ? (data['avgBookingPrice'] as num).toDouble()
          : null,
      totalEarnings: data['totalEarnings'] != null
          ? (data['totalEarnings'] as num).toDouble()
          : null,
    );
  }

  final String id;
  final String specialistId;
  final String name;
  final String description;
  final double price;
  final ServicePriceType priceType;
  final double? originalPrice;
  final int? discount;
  final PriceUnit currency;
  final String? duration;
  final int? minDuration;
  final int? maxDuration;
  final List<String> requirements;
  final List<String> includes;
  final List<String> excludes;
  final List<String> images;
  final List<String> videos;
  final List<String> tags;
  final String? category;
  final String? subcategory;
  final bool isActive;
  final bool isPopular;
  final bool isRecommended;
  final int bookingCount;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastBookedAt;
  final double? avgBookingPrice;
  final double? totalEarnings;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'name': name,
        'description': description,
        'price': price,
        'priceType': priceType.name,
        'originalPrice': originalPrice,
        'discount': discount,
        'currency': currency.name,
        'duration': duration,
        'minDuration': minDuration,
        'maxDuration': maxDuration,
        'requirements': requirements,
        'includes': includes,
        'excludes': excludes,
        'images': images,
        'videos': videos,
        'tags': tags,
        'category': category,
        'subcategory': subcategory,
        'isActive': isActive,
        'isPopular': isPopular,
        'isRecommended': isRecommended,
        'bookingCount': bookingCount,
        'rating': rating,
        'reviewCount': reviewCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'lastBookedAt': lastBookedAt != null ? Timestamp.fromDate(lastBookedAt!) : null,
        'avgBookingPrice': avgBookingPrice,
        'totalEarnings': totalEarnings,
      };

  /// Копировать с изменениями
  SpecialistService copyWith({
    String? id,
    String? specialistId,
    String? name,
    String? description,
    double? price,
    ServicePriceType? priceType,
    double? originalPrice,
    int? discount,
    PriceUnit? currency,
    String? duration,
    int? minDuration,
    int? maxDuration,
    List<String>? requirements,
    List<String>? includes,
    List<String>? excludes,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
    String? category,
    String? subcategory,
    bool? isActive,
    bool? isPopular,
    bool? isRecommended,
    int? bookingCount,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastBookedAt,
    double? avgBookingPrice,
    double? totalEarnings,
  }) =>
      SpecialistService(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        priceType: priceType ?? this.priceType,
        originalPrice: originalPrice ?? this.originalPrice,
        discount: discount ?? this.discount,
        currency: currency ?? this.currency,
        duration: duration ?? this.duration,
        minDuration: minDuration ?? this.minDuration,
        maxDuration: maxDuration ?? this.maxDuration,
        requirements: requirements ?? this.requirements,
        includes: includes ?? this.includes,
        excludes: excludes ?? this.excludes,
        images: images ?? this.images,
        videos: videos ?? this.videos,
        tags: tags ?? this.tags,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        isActive: isActive ?? this.isActive,
        isPopular: isPopular ?? this.isPopular,
        isRecommended: isRecommended ?? this.isRecommended,
        bookingCount: bookingCount ?? this.bookingCount,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastBookedAt: lastBookedAt ?? this.lastBookedAt,
        avgBookingPrice: avgBookingPrice ?? this.avgBookingPrice,
        totalEarnings: totalEarnings ?? this.totalEarnings,
      );

  /// Получить отформатированную цену
  String get formattedPrice {
    final currencySymbol = _getCurrencySymbol();
    return '$price $currencySymbol';
  }

  /// Получить отформатированную оригинальную цену
  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    final currencySymbol = _getCurrencySymbol();
    return '$originalPrice $currencySymbol';
  }

  /// Получить символ валюты
  String _getCurrencySymbol() {
    switch (currency) {
      case PriceUnit.rubles:
        return '₽';
      case PriceUnit.dollars:
        return '\$';
      case PriceUnit.euros:
        return '€';
    }
  }

  /// Получить отображаемое название типа цены
  String get priceTypeDisplayName {
    switch (priceType) {
      case ServicePriceType.fixed:
        return 'Фиксированная цена';
      case ServicePriceType.hourly:
        return 'Почасовая оплата';
      case ServicePriceType.daily:
        return 'Дневная оплата';
      case ServicePriceType.perPerson:
        return 'За человека';
      case ServicePriceType.perEvent:
        return 'За мероприятие';
      case ServicePriceType.custom:
        return 'Индивидуальная';
    }
  }

  /// Получить отображаемое название единицы измерения
  String get currencyDisplayName {
    switch (currency) {
      case PriceUnit.rubles:
        return 'Рубли';
      case PriceUnit.dollars:
        return 'Доллары';
      case PriceUnit.euros:
        return 'Евро';
    }
  }

  /// Проверить, есть ли скидка
  bool get hasDiscount => discount != null && discount! > 0;

  /// Получить процент скидки
  double? get discountPercentage {
    if (originalPrice == null || discount == null) return null;
    return (discount! / originalPrice!) * 100;
  }

  /// Получить отформатированную скидку
  String? get formattedDiscount {
    if (discount == null) return null;
    final currencySymbol = _getCurrencySymbol();
    return '-$discount $currencySymbol';
  }

  /// Получить отформатированный процент скидки
  String? get formattedDiscountPercentage {
    final percentage = discountPercentage;
    if (percentage == null) return null;
    return '-${percentage.toStringAsFixed(0)}%';
  }

  /// Получить диапазон длительности
  String? get durationRange {
    if (minDuration == null && maxDuration == null) return duration;
    
    if (minDuration != null && maxDuration != null) {
      return '$minDuration-$maxDuration ч';
    } else if (minDuration != null) {
      return 'от $minDuration ч';
    } else if (maxDuration != null) {
      return 'до $maxDuration ч';
    }
    
    return duration;
  }

  /// Получить отформатированную статистику
  String get formattedStats {
    final stats = <String>[];
    
    if (bookingCount > 0) {
      stats.add('$bookingCount заказов');
    }
    
    if (rating > 0) {
      stats.add('${rating.toStringAsFixed(1)} ⭐');
    }
    
    if (totalEarnings != null && totalEarnings! > 0) {
      final currencySymbol = _getCurrencySymbol();
      stats.add('${totalEarnings!.toStringAsFixed(0)} $currencySymbol');
    }
    
    return stats.join(' • ');
  }

  /// Проверить, является ли услуга популярной
  bool get isPopularService => bookingCount > 10 && rating > 4.0;

  /// Проверить, является ли услуга рекомендуемой
  bool get isRecommendedService => rating > 4.5 && bookingCount > 5;

  /// Получить цвет статуса
  String get statusColor {
    if (!isActive) return 'red';
    if (isPopular) return 'green';
    if (isRecommended) return 'blue';
    return 'gray';
  }

  /// Получить текст статуса
  String get statusText {
    if (!isActive) return 'Неактивна';
    if (isPopular) return 'Популярная';
    if (isRecommended) return 'Рекомендуемая';
    return 'Активна';
  }
}

/// Расширение для ServicePriceType
extension ServicePriceTypeExtension on ServicePriceType {
  String get displayName {
    switch (this) {
      case ServicePriceType.fixed:
        return 'Фиксированная цена';
      case ServicePriceType.hourly:
        return 'Почасовая оплата';
      case ServicePriceType.daily:
        return 'Дневная оплата';
      case ServicePriceType.perPerson:
        return 'За человека';
      case ServicePriceType.perEvent:
        return 'За мероприятие';
      case ServicePriceType.custom:
        return 'Индивидуальная';
    }
  }

  String get description {
    switch (this) {
      case ServicePriceType.fixed:
        return 'Одна цена за всю услугу';
      case ServicePriceType.hourly:
        return 'Оплата за каждый час работы';
      case ServicePriceType.daily:
        return 'Оплата за каждый день работы';
      case ServicePriceType.perPerson:
        return 'Оплата за каждого участника';
      case ServicePriceType.perEvent:
        return 'Оплата за мероприятие';
      case ServicePriceType.custom:
        return 'Индивидуальная цена по договоренности';
    }
  }
}

/// Расширение для PriceUnit
extension PriceUnitExtension on PriceUnit {
  String get displayName {
    switch (this) {
      case PriceUnit.rubles:
        return 'Рубли (₽)';
      case PriceUnit.dollars:
        return 'Доллары (\$)';
      case PriceUnit.euros:
        return 'Евро (€)';
    }
  }

  String get symbol {
    switch (this) {
      case PriceUnit.rubles:
        return '₽';
      case PriceUnit.dollars:
        return '\$';
      case PriceUnit.euros:
        return '€';
    }
  }
}
