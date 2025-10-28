import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель специалиста
class Specialist {

  const Specialist({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    required this.skills,
    required this.rating,
    required this.reviewCount,
    required this.pricing,
    required this.portfolioImages,
    required this.isAvailable, required this.createdAt, required this.updatedAt, this.avatarUrl,
  });

  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      skills: List<String>.from(data['skills'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      pricing: Map<String, dynamic>.from(data['pricing'] ?? {}),
      portfolioImages: List<String>.from(data['portfolioImages'] ?? []),
      avatarUrl: data['avatarUrl'],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String name;
  final String description;
  final List<String> categories;
  final List<String> skills;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> pricing;
  final List<String> portfolioImages;
  final String? avatarUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'categories': categories,
      'skills': skills,
      'rating': rating,
      'reviewCount': reviewCount,
      'pricing': pricing,
      'portfolioImages': portfolioImages,
      'avatarUrl': avatarUrl,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Specialist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? categories,
    List<String>? skills,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? pricing,
    List<String>? portfolioImages,
    String? avatarUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Specialist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      pricing: pricing ?? this.pricing,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
