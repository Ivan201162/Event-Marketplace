import 'package:equatable/equatable.dart';

/// Форма профиля специалиста
class SpecialistProfileForm extends Equatable {
  final String id;
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

  const SpecialistProfileForm({
    required this.id,
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
  });

  SpecialistProfileForm copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? category,
    String? description,
    String? experience,
    double? hourlyRate,
    List<String>? services,
    List<String>? portfolio,
    bool? isAvailable,
    String? avatarUrl,
  }) {
    return SpecialistProfileForm(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      category: category ?? this.category,
      description: description ?? this.description,
      experience: experience ?? this.experience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      services: services ?? this.services,
      portfolio: portfolio ?? this.portfolio,
      isAvailable: isAvailable ?? this.isAvailable,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
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
  ];
}
