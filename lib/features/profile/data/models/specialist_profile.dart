import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Модель профиля специалиста
class SpecialistProfile extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String category;
  final String description;
  final String experience;
  final double hourlyRate;
  final List<String> services;
  final List<String> portfolio;
  final bool isAvailable;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpecialistProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.category,
    required this.description,
    required this.experience,
    required this.hourlyRate,
    required this.services,
    required this.portfolio,
    required this.isAvailable,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory SpecialistProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      experience: data['experience'] ?? '',
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
      services: List<String>.from(data['services'] ?? []),
      portfolio: List<String>.from(data['portfolio'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'category': category,
      'description': description,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'services': services,
      'portfolio': portfolio,
      'isAvailable': isAvailable,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    email,
    phone,
    city,
    category,
    description,
    experience,
    hourlyRate,
    services,
    portfolio,
    isAvailable,
    avatarUrl,
    createdAt,
    updatedAt,
  ];
}
