import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Specialist model for event professionals
class Specialist extends Equatable {
  final String id;
  final String name;
  final String specialization;
  final String city;
  final double rating;
  final int pricePerHour;
  final String? avatarUrl;
  final List<String> portfolio;
  final String? description;
  final List<String> services;
  final bool isAvailable;
  final int completedEvents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? contactInfo;
  final List<String> languages;
  final String? experience;

  const Specialist({
    required this.id,
    required this.name,
    required this.specialization,
    required this.city,
    required this.rating,
    required this.pricePerHour,
    this.avatarUrl,
    this.portfolio = const [],
    this.description,
    this.services = const [],
    this.isAvailable = true,
    this.completedEvents = 0,
    required this.createdAt,
    required this.updatedAt,
    this.contactInfo,
    this.languages = const ['Русский'],
    this.experience,
  });

  /// Create Specialist from Firestore document
  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      city: data['city'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      pricePerHour: data['pricePerHour'] ?? 0,
      avatarUrl: data['avatarUrl'],
      portfolio: List<String>.from(data['portfolio'] ?? []),
      description: data['description'],
      services: List<String>.from(data['services'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      completedEvents: data['completedEvents'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      contactInfo: data['contactInfo'] as Map<String, dynamic>?,
      languages: List<String>.from(data['languages'] ?? ['Русский']),
      experience: data['experience'],
    );
  }

  /// Convert Specialist to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialization': specialization,
      'city': city,
      'rating': rating,
      'pricePerHour': pricePerHour,
      'avatarUrl': avatarUrl,
      'portfolio': portfolio,
      'description': description,
      'services': services,
      'isAvailable': isAvailable,
      'completedEvents': completedEvents,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'contactInfo': contactInfo,
      'languages': languages,
      'experience': experience,
    };
  }

  /// Create a copy with updated fields
  Specialist copyWith({
    String? id,
    String? name,
    String? specialization,
    String? city,
    double? rating,
    int? pricePerHour,
    String? avatarUrl,
    List<String>? portfolio,
    String? description,
    List<String>? services,
    bool? isAvailable,
    int? completedEvents,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? contactInfo,
    List<String>? languages,
    String? experience,
  }) {
    return Specialist(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolio: portfolio ?? this.portfolio,
      description: description ?? this.description,
      services: services ?? this.services,
      isAvailable: isAvailable ?? this.isAvailable,
      completedEvents: completedEvents ?? this.completedEvents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactInfo: contactInfo ?? this.contactInfo,
      languages: languages ?? this.languages,
      experience: experience ?? this.experience,
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

  @override
  List<Object?> get props => [
        id,
        name,
        specialization,
        city,
        rating,
        pricePerHour,
        avatarUrl,
        portfolio,
        description,
        services,
        isAvailable,
        completedEvents,
        createdAt,
        updatedAt,
        contactInfo,
        languages,
        experience,
      ];

  @override
  String toString() {
    return 'Specialist(id: $id, name: $name, specialization: $specialization, city: $city, rating: $rating)';
  }
}
