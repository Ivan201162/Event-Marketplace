import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/price_range.dart';
import 'package:flutter/material.dart';

/// Модель фотостудии
class PhotoStudio {
  const PhotoStudio({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.ownerId,
    required this.createdAt,
    this.avatarUrl,
    this.coverImageUrl,
    this.images = const [],
    this.amenities = const [],
    this.pricing = const {},
    this.workingHours = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.isVerified = false,
    this.location = const {},
    this.metadata = const {},
    this.priceRange,
    this.photosCount = 0,
    this.studioOptions = const [],
    this.photos = const [],
  });

  /// Создать из документа Firestore
  factory PhotoStudio.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PhotoStudio(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl']?.toString(),
      coverImageUrl: data['coverImageUrl']?.toString(),
      images: (data['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      amenities: (data['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pricing: Map<String, dynamic>.from(data['pricing'] as Map? ?? {}),
      workingHours:
          Map<String, dynamic>.from(data['workingHours'] as Map? ?? {}),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      isVerified: data['isVerified'] == true,
      location: Map<String, dynamic>.from(data['location'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory PhotoStudio.fromMap(Map<String, dynamic> data) => PhotoStudio(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        address: data['address']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        ownerId: data['ownerId']?.toString() ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        avatarUrl: data['avatarUrl']?.toString(),
        coverImageUrl: data['coverImageUrl']?.toString(),
        images: (data['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        amenities: (data['amenities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        pricing: data['pricing'] != null
            ? Map<String, dynamic>.from(data['pricing'] as Map)
            : {},
        workingHours: data['workingHours'] != null
            ? Map<String, dynamic>.from(data['workingHours'] as Map)
            : {},
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
        isActive: data['isActive'] == true,
        isVerified: data['isVerified'] == true,
        location: data['location'] != null
            ? Map<String, dynamic>.from(data['location'] as Map)
            : {},
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'] as Map)
            : {},
        priceRange: data['priceRange'] != null
            ? PriceRange.fromMap(Map<String, dynamic>.from(data['priceRange']))
            : null,
        photosCount: (data['photosCount'] as num?)?.toInt() ?? 0,
        studioOptions: (data['studioOptions'] as List<dynamic>?)
                ?.map((e) => StudioOption.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        photos: (data['photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  final String id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String ownerId;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? coverImageUrl;
  final List<String> images;
  final List<String> amenities;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> workingHours;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final bool isVerified;
  final Map<String, dynamic> location;
  final Map<String, dynamic> metadata;
  final PriceRange? priceRange;
  final int photosCount;
  final List<StudioOption> studioOptions;
  final List<String> photos;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
        'ownerId': ownerId,
        'createdAt': Timestamp.fromDate(createdAt),
        'avatarUrl': avatarUrl,
        'coverImageUrl': coverImageUrl,
        'images': images,
        'amenities': amenities,
        'pricing': pricing,
        'workingHours': workingHours,
        'rating': rating,
        'reviewCount': reviewCount,
        'isActive': isActive,
        'isVerified': isVerified,
        'location': location,
        'metadata': metadata,
        'priceRange': priceRange?.toMap(),
        'photosCount': photosCount,
        'studioOptions': studioOptions.map((e) => e.toMap()).toList(),
        'photos': photos,
      };

  /// Создать копию с изменениями
  PhotoStudio copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? ownerId,
    DateTime? createdAt,
    String? avatarUrl,
    String? coverImageUrl,
    List<String>? images,
    List<String>? amenities,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? workingHours,
    double? rating,
    int? reviewCount,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? location,
    Map<String, dynamic>? metadata,
    PriceRange? priceRange,
    int? photosCount,
    List<StudioOption>? studioOptions,
    List<String>? photos,
  }) =>
      PhotoStudio(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        ownerId: ownerId ?? this.ownerId,
        createdAt: createdAt ?? this.createdAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        images: images ?? this.images,
        amenities: amenities ?? this.amenities,
        pricing: pricing ?? this.pricing,
        workingHours: workingHours ?? this.workingHours,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        isActive: isActive ?? this.isActive,
        isVerified: isVerified ?? this.isVerified,
        location: location ?? this.location,
        metadata: metadata ?? this.metadata,
        priceRange: priceRange ?? this.priceRange,
        photosCount: photosCount ?? this.photosCount,
        studioOptions: studioOptions ?? this.studioOptions,
        photos: photos ?? this.photos,
      );

  /// Получить цену за час
  double? get hourlyRate {
    final rate = pricing['hourlyRate'];
    if (rate is num) return rate.toDouble();
    return null;
  }

  /// Получить цену за день
  double? get dailyRate {
    final rate = pricing['dailyRate'];
    if (rate is num) return rate.toDouble();
    return null;
  }

  /// Получить цену за пакет
  double? getPackageRate(String packageName) {
    final rate = pricing['packages']?[packageName];
    if (rate is num) return rate.toDouble();
    return null;
  }

  /// Получить рабочие часы для дня
  Map<String, String>? getWorkingHoursForDay(String day) {
    final hours = workingHours[day];
    if (hours is Map) {
      return Map<String, String>.from(hours);
    }
    return null;
  }

  /// Проверить, работает ли студия в указанное время
  bool isWorkingAt(DateTime dateTime) {
    final day = _getDayName(dateTime.weekday);
    final hours = getWorkingHoursForDay(day);
    if (hours == null) return false;

    final openTime = hours['open'];
    final closeTime = hours['close'];
    if (openTime == null || closeTime == null) return false;

    final now = TimeOfDay.fromDateTime(dateTime);
    final open = _parseTimeOfDay(openTime);
    final close = _parseTimeOfDay(closeTime);

    return _isTimeBetween(now, open, close);
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  /// Получить отформатированную цену
  String getFormattedHourlyRate() {
    final rate = hourlyRate;
    if (rate == null) return 'Цена не указана';
    return '${rate.toStringAsFixed(0)} ₽/час';
  }

  String getFormattedDailyRate() {
    final rate = dailyRate;
    if (rate == null) return 'Цена не указана';
    return '${rate.toStringAsFixed(0)} ₽/день';
  }

  /// Получить количество изображений
  int get imageCount => images.length;

  /// Проверить, есть ли изображения
  bool get hasImages => images.isNotEmpty;

  /// Получить количество удобств
  int get amenityCount => amenities.length;

  /// Проверить, есть ли удобства
  bool get hasAmenities => amenities.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoStudio && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PhotoStudio(id: $id, name: $name, rating: $rating)';
}

/// Модель для создания фотостудии
class CreatePhotoStudio {
  const CreatePhotoStudio({
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.ownerId,
    this.avatarUrl,
    this.coverImageUrl,
    this.images = const [],
    this.amenities = const [],
    this.pricing = const {},
    this.workingHours = const {},
    this.location = const {},
    this.metadata = const {},
  });

  final String name;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String ownerId;
  final String? avatarUrl;
  final String? coverImageUrl;
  final List<String> images;
  final List<String> amenities;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> workingHours;
  final Map<String, dynamic> location;
  final Map<String, dynamic> metadata;

  bool get isValid =>
      name.isNotEmpty &&
      description.isNotEmpty &&
      address.isNotEmpty &&
      phone.isNotEmpty &&
      email.isNotEmpty &&
      ownerId.isNotEmpty;

  List<String> get validationErrors {
    final errors = <String>[];
    if (name.isEmpty) errors.add('Название обязательно');
    if (description.isEmpty) errors.add('Описание обязательно');
    if (address.isEmpty) errors.add('Адрес обязателен');
    if (phone.isEmpty) errors.add('Телефон обязателен');
    if (email.isEmpty) errors.add('Email обязателен');
    if (ownerId.isEmpty) errors.add('ID владельца обязателен');
    return errors;
  }
}

/// Модель бронирования фотостудии
class PhotoStudioBooking {
  const PhotoStudioBooking({
    required this.id,
    required this.studioId,
    required this.customerId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.notes,
    this.packageName,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory PhotoStudioBooking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PhotoStudioBooking(
      id: doc.id,
      studioId: data['studioId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: data['status']?.toString() ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      customerName: data['customerName']?.toString(),
      customerPhone: data['customerPhone']?.toString(),
      customerEmail: data['customerEmail']?.toString(),
      notes: data['notes']?.toString(),
      packageName: data['packageName']?.toString(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  final String id;
  final String studioId;
  final String customerId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? notes;
  final String? packageName;
  final Map<String, dynamic> metadata;

  /// Получить продолжительность в часах
  double get durationInHours =>
      endTime.difference(startTime).inHours.toDouble();

  /// Получить отформатированную продолжительность
  String get formattedDuration {
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hoursч $minutesм';
    } else if (hours > 0) {
      return '$hoursч';
    } else {
      return '$minutesм';
    }
  }

  /// Получить отформатированную цену
  String get formattedPrice => '${totalPrice.toStringAsFixed(0)} ₽';

  /// Проверить, является ли бронирование активным
  bool get isActive => status == 'confirmed' || status == 'pending';

  /// Проверить, является ли бронирование завершенным
  bool get isCompleted => status == 'completed';

  /// Проверить, является ли бронирование отмененным
  bool get isCancelled => status == 'cancelled';

  /// Создать копию с изменениями
  PhotoStudioBooking copyWith({
    String? id,
    String? studioId,
    String? customerId,
    DateTime? startTime,
    DateTime? endTime,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? packageName,
    Map<String, dynamic>? metadata,
  }) =>
      PhotoStudioBooking(
        id: id ?? this.id,
        studioId: studioId ?? this.studioId,
        customerId: customerId ?? this.customerId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        customerEmail: customerEmail ?? this.customerEmail,
        notes: notes ?? this.notes,
        packageName: packageName ?? this.packageName,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoStudioBooking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PhotoStudioBooking(id: $id, studioId: $studioId, status: $status)';
}

/// Опция студии
class StudioOption {
  const StudioOption({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isAvailable = true,
  });

  factory StudioOption.fromMap(Map<String, dynamic> data) => StudioOption(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        isAvailable: data['isAvailable'] == true,
      );

  final String id;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'isAvailable': isAvailable,
      };

  @override
  String toString() => 'StudioOption(id: $id, name: $name, price: $price)';
}
