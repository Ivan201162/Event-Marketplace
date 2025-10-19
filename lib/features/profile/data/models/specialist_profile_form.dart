/// Форма профиля специалиста
class SpecialistProfileForm {
  final String name;
  final String description;
  final List<String> categories;
  final List<String> skills;
  final Map<String, dynamic> pricing;
  final List<String> portfolioImages;
  final String? avatarUrl;

  const SpecialistProfileForm({
    required this.name,
    required this.description,
    required this.categories,
    required this.skills,
    required this.pricing,
    required this.portfolioImages,
    this.avatarUrl,
  });

  SpecialistProfileForm copyWith({
    String? name,
    String? description,
    List<String>? categories,
    List<String>? skills,
    Map<String, dynamic>? pricing,
    List<String>? portfolioImages,
    String? avatarUrl,
  }) {
    return SpecialistProfileForm(
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      skills: skills ?? this.skills,
      pricing: pricing ?? this.pricing,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categories': categories,
      'skills': skills,
      'pricing': pricing,
      'portfolioImages': portfolioImages,
      'avatarUrl': avatarUrl,
    };
  }

  factory SpecialistProfileForm.fromMap(Map<String, dynamic> map) {
    return SpecialistProfileForm(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      pricing: Map<String, dynamic>.from(map['pricing'] ?? {}),
      portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
      avatarUrl: map['avatarUrl'],
    );
  }
}
