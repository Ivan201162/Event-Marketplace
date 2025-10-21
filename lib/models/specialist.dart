import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'common_types.dart';

/// Specialist model for event professionals
class Specialist extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String specialization;
  final String city;
  final double rating;
  final int pricePerHour;
  final String? avatarUrl;
  final String? imageUrl;
  final List<String> portfolio;
  final String? description;
  final String? bio;
  final List<String> services;
  final bool isAvailable;
  final bool isVerified;
  final int completedEvents;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? contactInfo;
  final Map<String, dynamic>? contacts;
  final List<String> languages;
  final String? experience;
  final SpecialistCategory? category;
  final ExperienceLevel? experienceLevel;
  final int? yearsOfExperience;
  final double? hourlyRate;
  final double? price;
  final String? location;
  final List<String>? subcategories;
  final int? minBookingHours;
  final int? maxBookingHours;
  final List<String>? serviceAreas;
  final List<String>? equipment;
  final Map<String, double>? servicesWithPrices;
  final List<DateTime>? availableDates;
  final List<DateTime>? busyDates;
  final String? displayName;
  final String? imageUrlValue;
  final String? categoryDisplayName;
  final String? priceRangeString;
  final int? totalReviews;
  final int? totalBookings;
  final double? avgRating;
  final List<String>? categories;

  const Specialist({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.city,
    required this.rating,
    required this.pricePerHour,
    this.avatarUrl,
    this.imageUrl,
    this.portfolio = const [],
    this.description,
    this.bio,
    this.services = const [],
    this.isAvailable = true,
    this.isVerified = false,
    this.completedEvents = 0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.contactInfo,
    this.contacts,
    this.languages = const ['Русский'],
    this.experience,
    this.category,
    this.experienceLevel,
    this.yearsOfExperience,
    this.hourlyRate,
    this.price,
    this.location,
    this.subcategories,
    this.minBookingHours,
    this.maxBookingHours,
    this.serviceAreas,
    this.equipment,
    this.servicesWithPrices,
    this.availableDates,
    this.busyDates,
    this.displayName,
    this.imageUrlValue,
    this.categoryDisplayName,
    this.priceRangeString,
    this.totalReviews,
    this.totalBookings,
    this.avgRating,
    this.categories,
  });

  /// Create Specialist from Firestore document
  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      city: data['city'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      pricePerHour: data['pricePerHour'] ?? 0,
      avatarUrl: data['avatarUrl'],
      imageUrl: data['imageUrl'],
      portfolio: List<String>.from(data['portfolio'] ?? []),
      description: data['description'],
      bio: data['bio'],
      services: List<String>.from(data['services'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      completedEvents: data['completedEvents'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      contactInfo: data['contactInfo'] as Map<String, dynamic>?,
      contacts: data['contacts'] as Map<String, dynamic>?,
      languages: List<String>.from(data['languages'] ?? ['Русский']),
      experience: data['experience'],
      category: data['category'] != null
          ? SpecialistCategory.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => SpecialistCategory.host,
            )
          : null,
      experienceLevel: data['experienceLevel'] != null
          ? ExperienceLevel.values.firstWhere(
              (e) => e.name == data['experienceLevel'],
              orElse: () => ExperienceLevel.beginner,
            )
          : null,
      yearsOfExperience: data['yearsOfExperience'],
      hourlyRate: data['hourlyRate']?.toDouble(),
      price: data['price']?.toDouble(),
      location: data['location'],
      subcategories: data['subcategories'] != null
          ? List<String>.from(data['subcategories'])
          : null,
      minBookingHours: data['minBookingHours'],
      maxBookingHours: data['maxBookingHours'],
      serviceAreas: data['serviceAreas'] != null ? List<String>.from(data['serviceAreas']) : null,
      equipment: data['equipment'] != null ? List<String>.from(data['equipment']) : null,
      servicesWithPrices: data['servicesWithPrices'] != null
          ? Map<String, double>.from(data['servicesWithPrices'])
          : null,
      availableDates: data['availableDates'] != null
          ? (data['availableDates'] as List).map((e) => (e as Timestamp).toDate()).toList()
          : null,
      busyDates: data['busyDates'] != null
          ? (data['busyDates'] as List).map((e) => (e as Timestamp).toDate()).toList()
          : null,
      displayName: data['displayName'] ?? data['name'],
      imageUrlValue: data['imageUrlValue'] ?? data['imageUrl'] ?? data['avatarUrl'],
      categoryDisplayName: data['categoryDisplayName'] ?? data['specialization'],
      priceRangeString: data['priceRangeString'] ?? '${data['pricePerHour'] ?? 0} ₽/час',
      totalReviews: data['totalReviews'] ?? data['reviewCount'] ?? 0,
      totalBookings: data['totalBookings'] ?? data['completedEvents'] ?? 0,
      avgRating: data['avgRating']?.toDouble() ?? data['rating']?.toDouble() ?? 0.0,
      categories: data['categories'] != null
          ? List<String>.from(data['categories'])
          : [data['specialization'] ?? ''],
    );
  }

  /// Convert Specialist to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'specialization': specialization,
      'city': city,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'avatarUrl': avatarUrl,
      'imageUrl': imageUrl,
      'portfolio': portfolio,
      'description': description,
      'bio': bio,
      'services': services,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'completedEvents': completedEvents,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'contactInfo': contactInfo,
      'contacts': contacts,
      'languages': languages,
      'experience': experience,
      'category': category?.name,
      'experienceLevel': experienceLevel?.name,
      'yearsOfExperience': yearsOfExperience,
      'hourlyRate': hourlyRate,
      'price': price,
      'location': location,
      'subcategories': subcategories,
      'minBookingHours': minBookingHours,
      'maxBookingHours': maxBookingHours,
      'serviceAreas': serviceAreas,
      'equipment': equipment,
      'servicesWithPrices': servicesWithPrices,
      'availableDates': availableDates?.map((e) => Timestamp.fromDate(e)).toList(),
      'busyDates': busyDates?.map((e) => Timestamp.fromDate(e)).toList(),
      'displayName': displayName,
      'imageUrlValue': imageUrlValue,
      'categoryDisplayName': categoryDisplayName,
      'priceRangeString': priceRangeString,
      'totalReviews': totalReviews,
      'totalBookings': totalBookings,
      'avgRating': avgRating,
      'categories': categories,
    };
  }

  /// Convert Specialist to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'specialization': specialization,
      'city': city,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'avatarUrl': avatarUrl,
      'imageUrl': imageUrl,
      'portfolio': portfolio,
      'description': description,
      'bio': bio,
      'services': services,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'completedEvents': completedEvents,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'contactInfo': contactInfo,
      'contacts': contacts,
      'languages': languages,
      'experience': experience,
      'category': category?.name,
      'experienceLevel': experienceLevel?.name,
      'yearsOfExperience': yearsOfExperience,
      'hourlyRate': hourlyRate,
      'price': price,
      'location': location,
      'subcategories': subcategories,
      'minBookingHours': minBookingHours,
      'maxBookingHours': maxBookingHours,
      'serviceAreas': serviceAreas,
      'equipment': equipment,
      'servicesWithPrices': servicesWithPrices,
      'availableDates': availableDates,
      'busyDates': busyDates,
      'displayName': displayName,
      'imageUrlValue': imageUrlValue,
      'categoryDisplayName': categoryDisplayName,
      'priceRangeString': priceRangeString,
      'totalReviews': totalReviews,
      'totalBookings': totalBookings,
      'avgRating': avgRating,
      'categories': categories,
    };
  }

  factory Specialist.fromMap(Map<String, dynamic> data) {
    return Specialist(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      city: data['city'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      pricePerHour: data['pricePerHour'] ?? 0,
      avatarUrl: data['avatarUrl'],
      imageUrl: data['imageUrl'],
      portfolio: List<String>.from(data['portfolio'] ?? []),
      description: data['description'],
      bio: data['bio'],
      services: List<String>.from(data['services'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      completedEvents: data['completedEvents'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'] is DateTime ? data['createdAt'] : DateTime.now(),
      updatedAt: data['updatedAt'] is DateTime ? data['updatedAt'] : DateTime.now(),
      contactInfo: data['contactInfo'] as Map<String, dynamic>?,
      contacts: data['contacts'] as Map<String, dynamic>?,
      languages: List<String>.from(data['languages'] ?? ['Русский']),
      experience: data['experience'],
      category: data['category'] != null
          ? SpecialistCategory.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => SpecialistCategory.host,
            )
          : null,
      experienceLevel: data['experienceLevel'] != null
          ? ExperienceLevel.values.firstWhere(
              (e) => e.name == data['experienceLevel'],
              orElse: () => ExperienceLevel.beginner,
            )
          : null,
      yearsOfExperience: data['yearsOfExperience'],
      hourlyRate: data['hourlyRate']?.toDouble(),
      price: data['price']?.toDouble(),
      location: data['location'],
      subcategories: data['subcategories'] != null
          ? List<String>.from(data['subcategories'])
          : null,
      minBookingHours: data['minBookingHours'],
      maxBookingHours: data['maxBookingHours'],
      serviceAreas: data['serviceAreas'] != null ? List<String>.from(data['serviceAreas']) : null,
      equipment: data['equipment'] != null ? List<String>.from(data['equipment']) : null,
      servicesWithPrices: data['servicesWithPrices'] != null
          ? Map<String, double>.from(data['servicesWithPrices'])
          : null,
      availableDates: data['availableDates'] != null
          ? List<DateTime>.from(data['availableDates'])
          : null,
      busyDates: data['busyDates'] != null ? List<DateTime>.from(data['busyDates']) : null,
      displayName: data['displayName'] ?? data['name'],
      imageUrlValue: data['imageUrlValue'] ?? data['imageUrl'] ?? data['avatarUrl'],
      categoryDisplayName: data['categoryDisplayName'] ?? data['specialization'],
      priceRangeString: data['priceRangeString'] ?? '${data['pricePerHour'] ?? 0} ₽/час',
      totalReviews: data['totalReviews'] ?? data['reviewCount'] ?? 0,
      totalBookings: data['totalBookings'] ?? data['completedEvents'] ?? 0,
      avgRating: data['avgRating']?.toDouble() ?? data['rating']?.toDouble() ?? 0.0,
      categories: data['categories'] != null
          ? List<String>.from(data['categories'])
          : [data['specialization'] ?? ''],
    );
  }

  /// Create a copy with updated fields
  Specialist copyWith({
    String? id,
    String? userId,
    String? name,
    String? specialization,
    String? city,
    double? rating,
    int? pricePerHour,
    String? avatarUrl,
    String? imageUrl,
    List<String>? portfolio,
    String? description,
    String? bio,
    List<String>? services,
    bool? isAvailable,
    bool? isVerified,
    int? completedEvents,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? contacts,
    List<String>? languages,
    String? experience,
    SpecialistCategory? category,
    ExperienceLevel? experienceLevel,
    int? yearsOfExperience,
    double? hourlyRate,
    double? price,
    String? location,
    List<String>? subcategories,
    int? minBookingHours,
    int? maxBookingHours,
    List<String>? serviceAreas,
    List<String>? equipment,
    Map<String, double>? servicesWithPrices,
    List<DateTime>? availableDates,
    List<DateTime>? busyDates,
    String? displayName,
    String? imageUrlValue,
    String? categoryDisplayName,
    String? priceRangeString,
    int? totalReviews,
    int? totalBookings,
    double? avgRating,
    List<String>? categories,
  }) {
    return Specialist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      portfolio: portfolio ?? this.portfolio,
      description: description ?? this.description,
      bio: bio ?? this.bio,
      services: services ?? this.services,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      completedEvents: completedEvents ?? this.completedEvents,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactInfo: contactInfo ?? this.contactInfo,
      contacts: contacts ?? this.contacts,
      languages: languages ?? this.languages,
      experience: experience ?? this.experience,
      category: category ?? this.category,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      price: price ?? this.price,
      location: location ?? this.location,
      subcategories: subcategories ?? this.subcategories,
      minBookingHours: minBookingHours ?? this.minBookingHours,
      maxBookingHours: maxBookingHours ?? this.maxBookingHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      equipment: equipment ?? this.equipment,
      servicesWithPrices: servicesWithPrices ?? this.servicesWithPrices,
      availableDates: availableDates ?? this.availableDates,
      busyDates: busyDates ?? this.busyDates,
      displayName: displayName ?? this.displayName,
      imageUrlValue: imageUrlValue ?? this.imageUrlValue,
      categoryDisplayName: categoryDisplayName ?? this.categoryDisplayName,
      priceRangeString: priceRangeString ?? this.priceRangeString,
      totalReviews: totalReviews ?? this.totalReviews,
      totalBookings: totalBookings ?? this.totalBookings,
      avgRating: avgRating ?? this.avgRating,
      categories: categories ?? this.categories,
    );
  }

  /// Get formatted price string
  String get formattedPrice => '$pricePerHour ₽/час';

  /// Get rating stars string
  String get ratingStars => '⭐ ${rating.toStringAsFixed(1)}';

  /// Get experience string
  String get experienceText => experience ?? 'Опыт не указан';

  /// Check if specialist has portfolio
  bool get hasPortfolio => portfolio.isNotEmpty;

  /// Get first portfolio image
  String? get firstPortfolioImage => portfolio.isNotEmpty ? portfolio.first : null;

  /// Check if specialist is available on specific date
  bool isAvailableOnDate(DateTime date) {
    if (availableDates == null) return true;
    return availableDates!.any(
      (availableDate) =>
          availableDate.year == date.year &&
          availableDate.month == date.month &&
          availableDate.day == date.day,
    );
  }

  /// Check if specialist is busy on specific date
  bool isDateBusy(DateTime date) {
    if (busyDates == null) return false;
    return busyDates!.any(
      (busyDate) =>
          busyDate.year == date.year && busyDate.month == date.month && busyDate.day == date.day,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    specialization,
    city,
    rating,
    pricePerHour,
    avatarUrl,
    imageUrl,
    portfolio,
    description,
    bio,
    services,
    isAvailable,
    isVerified,
    completedEvents,
    reviewCount,
    createdAt,
    updatedAt,
    contactInfo,
    contacts,
    languages,
    experience,
    category,
    experienceLevel,
    yearsOfExperience,
    hourlyRate,
    price,
    location,
    subcategories,
    minBookingHours,
    maxBookingHours,
    serviceAreas,
    equipment,
    servicesWithPrices,
    availableDates,
    busyDates,
    displayName,
    imageUrlValue,
    categoryDisplayName,
    priceRangeString,
    totalReviews,
    totalBookings,
    avgRating,
    categories,
  ];

  /// Get formatted price per hour
  String get formattedPricePerHour => '$pricePerHour ₽/час';

  /// Get display name for category

  /// Create Specialist from Firestore document
  factory Specialist.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    data['id'] = doc.id; // Add the document ID to the data
    return Specialist.fromMap(data);
  }

  @override
  String toString() {
    return 'Specialist(id: $id, name: $name, specialization: $specialization, city: $city, rating: $rating)';
  }
}
