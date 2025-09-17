import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель фотостудии
class PhotoStudio {
  final String id;
  final String name;
  final String description;
  final String location;
  final String address;
  final double latitude;
  final double longitude;
  final List<StudioOption> studioOptions;
  final List<String> availableDates;
  final List<String> photos;
  final double? rating;
  final int? reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhotoStudio({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.studioOptions,
    required this.availableDates,
    required this.photos,
    this.rating,
    this.reviewCount,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory PhotoStudio.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoStudio(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      studioOptions: (data['studioOptions'] as List<dynamic>?)
              ?.map((option) =>
                  StudioOption.fromMap(option as Map<String, dynamic>))
              .toList() ??
          [],
      availableDates: List<String>.from(data['availableDates'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory PhotoStudio.fromMap(Map<String, dynamic> data) {
    return PhotoStudio(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      studioOptions: (data['studioOptions'] as List<dynamic>?)
              ?.map((option) =>
                  StudioOption.fromMap(option as Map<String, dynamic>))
              .toList() ??
          [],
      availableDates: List<String>.from(data['availableDates'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'studioOptions': studioOptions.map((option) => option.toMap()).toList(),
      'availableDates': availableDates,
      'photos': photos,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Создать копию с изменениями
  PhotoStudio copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    List<StudioOption>? studioOptions,
    List<String>? availableDates,
    List<String>? photos,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhotoStudio(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      studioOptions: studioOptions ?? this.studioOptions,
      availableDates: availableDates ?? this.availableDates,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получить минимальную цену за час
  double? get minPricePerHour {
    if (studioOptions.isEmpty) return null;
    return studioOptions
        .map((option) => option.pricePerHour)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Получить максимальную цену за час
  double? get maxPricePerHour {
    if (studioOptions.isEmpty) return null;
    return studioOptions
        .map((option) => option.pricePerHour)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Получить диапазон цен
  String? get priceRange {
    final min = minPricePerHour;
    final max = maxPricePerHour;

    if (min == null || max == null) return null;

    if (min == max) {
      return '${min.toStringAsFixed(0)} ₽/час';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ₽/час';
  }

  /// Получить количество доступных дат
  int get availableDatesCount => availableDates.length;

  /// Получить количество фотографий
  int get photosCount => photos.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoStudio &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.location == location &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.studioOptions == studioOptions &&
        other.availableDates == availableDates &&
        other.photos == photos &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      location,
      address,
      latitude,
      longitude,
      studioOptions,
      availableDates,
      photos,
      rating,
      reviewCount,
      isActive,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'PhotoStudio(id: $id, name: $name, location: $location)';
  }
}

/// Опция студии
class StudioOption {
  final String id;
  final String name;
  final String description;
  final double pricePerHour;
  final List<String> photos;
  final Map<String, dynamic>? specifications;

  const StudioOption({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.photos,
    this.specifications,
  });

  /// Создать из Map
  factory StudioOption.fromMap(Map<String, dynamic> data) {
    return StudioOption(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pricePerHour: (data['pricePerHour'] as num).toDouble(),
      photos: List<String>.from(data['photos'] ?? []),
      specifications: data['specifications'] != null
          ? Map<String, dynamic>.from(data['specifications'])
          : null,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerHour': pricePerHour,
      'photos': photos,
      'specifications': specifications,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudioOption &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.pricePerHour == pricePerHour &&
        other.photos == photos &&
        other.specifications == specifications;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      pricePerHour,
      photos,
      specifications,
    );
  }

  @override
  String toString() {
    return 'StudioOption(id: $id, name: $name, pricePerHour: $pricePerHour)';
  }
}

/// Бронирование фотостудии
class StudioBooking {
  final String id;
  final String studioId;
  final String customerId;
  final String? photographerId;
  final String optionId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudioBooking({
    required this.id,
    required this.studioId,
    required this.customerId,
    this.photographerId,
    required this.optionId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory StudioBooking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudioBooking(
      id: doc.id,
      studioId: data['studioId'] ?? '',
      customerId: data['customerId'] ?? '',
      photographerId: data['photographerId'],
      optionId: data['optionId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory StudioBooking.fromMap(Map<String, dynamic> data) {
    return StudioBooking(
      id: data['id'] ?? '',
      studioId: data['studioId'] ?? '',
      customerId: data['customerId'] ?? '',
      photographerId: data['photographerId'],
      optionId: data['optionId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'studioId': studioId,
      'customerId': customerId,
      'photographerId': photographerId,
      'optionId': optionId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Получить продолжительность в часах
  double get durationInHours {
    return endTime.difference(startTime).inHours.toDouble();
  }

  /// Проверить, активно ли бронирование
  bool get isActive {
    return status == 'confirmed' || status == 'in_progress';
  }

  /// Проверить, завершено ли бронирование
  bool get isCompleted {
    return status == 'completed';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudioBooking &&
        other.id == id &&
        other.studioId == studioId &&
        other.customerId == customerId &&
        other.photographerId == photographerId &&
        other.optionId == optionId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.totalPrice == totalPrice &&
        other.status == status &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      studioId,
      customerId,
      photographerId,
      optionId,
      startTime,
      endTime,
      totalPrice,
      status,
      notes,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudioBooking(id: $id, studioId: $studioId, status: $status)';
  }
}
