class Specialist {
  final String id;
  final String name;
  final String email;
  final String category;
  final String city;
  final double rating;
  final int reviewCount;
  final double pricePerHour;
  final String description;
  final List<String> services;
  final List<String> portfolio;
  final bool isAvailable;
  final DateTime createdAt;

  Specialist({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.description,
    required this.services,
    required this.portfolio,
    this.isAvailable = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'category': category,
      'city': city,
      'rating': rating,
      'reviewCount': reviewCount,
      'pricePerHour': pricePerHour,
      'description': description,
      'services': services,
      'portfolio': portfolio,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Specialist.fromMap(String id, Map<String, dynamic> map) {
    return Specialist(
      id: id,
      name: map['name'],
      email: map['email'],
      category: map['category'],
      city: map['city'],
      rating: map['rating'],
      reviewCount: map['reviewCount'],
      pricePerHour: map['pricePerHour'],
      description: map['description'],
      services: List<String>.from(map['services']),
      portfolio: List<String>.from(map['portfolio']),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }


  // Копирует объект с новыми данными
  Specialist copyWith({
    String? id,
    String? name,
    String? email,
    String? category,
    String? city,
    double? rating,
    int? reviewCount,
    double? pricePerHour,
    String? description,
    List<String>? services,
    List<String>? portfolio,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Specialist(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      category: category ?? this.category,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      description: description ?? this.description,
      services: services ?? this.services,
      portfolio: portfolio ?? this.portfolio,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
