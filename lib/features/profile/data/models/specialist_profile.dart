import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель профиля специалиста для форм
class SpecialistProfileForm {
  SpecialistProfileForm({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.description,
    required this.location,
    required this.categories,
    required this.yearsOfExperience,
    required this.hourlyRate,
    required this.servicesWithPrices,
    required this.contacts,
    this.imageUrl,
    this.coverUrl,
    this.isAvailable = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создание из Map (из Firestore)
  factory SpecialistProfileForm.fromMap(Map<String, dynamic> map) =>
      SpecialistProfileForm(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        bio: map['bio'] ?? '',
        description: map['description'] ?? '',
        location: map['location'] ?? '',
        categories: List<String>.from(map['categories'] ?? []),
        yearsOfExperience: map['yearsOfExperience'] ?? 0,
        hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
        servicesWithPrices: Map<String, double>.from(
          (map['servicesWithPrices'] ?? {}).map(
            (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
          ),
        ),
        contacts: Map<String, String>.from(map['contacts'] ?? {}),
        imageUrl: map['imageUrl'],
        coverUrl: map['coverUrl'],
        isAvailable: map['isAvailable'] ?? true,
        isVerified: map['isVerified'] ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String description;
  final String location;
  final List<String> categories;
  final int yearsOfExperience;
  final double hourlyRate;
  final Map<String, double> servicesWithPrices;
  final Map<String, String> contacts;
  final String? imageUrl;
  final String? coverUrl;
  final bool isAvailable;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        'description': description,
        'location': location,
        'categories': categories,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'servicesWithPrices': servicesWithPrices,
        'contacts': contacts,
        'imageUrl': imageUrl ?? '',
        'coverUrl': coverUrl ?? '',
        'isAvailable': isAvailable,
        'isVerified': isVerified,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создание копии с изменениями
  SpecialistProfileForm copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? description,
    String? location,
    List<String>? categories,
    int? yearsOfExperience,
    double? hourlyRate,
    Map<String, double>? servicesWithPrices,
    Map<String, String>? contacts,
    String? imageUrl,
    String? coverUrl,
    bool? isAvailable,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SpecialistProfileForm(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        description: description ?? this.description,
        location: location ?? this.location,
        categories: categories ?? this.categories,
        yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        servicesWithPrices: servicesWithPrices ?? this.servicesWithPrices,
        contacts: contacts ?? this.contacts,
        imageUrl: imageUrl ?? this.imageUrl,
        coverUrl: coverUrl ?? this.coverUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        isVerified: isVerified ?? this.isVerified,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Валидация формы
  Map<String, String> validate() {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Имя обязательно для заполнения';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Имя должно содержать минимум 2 символа';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'Email обязателен';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim())) {
      errors['email'] = 'Введите корректный email';
    }

    if (phone.trim().isEmpty) {
      errors['phone'] = 'Телефон обязателен';
    } else {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanPhone.length < 10) {
        errors['phone'] = 'Введите корректный номер телефона';
      }
    }

    if (bio.trim().isEmpty) {
      errors['bio'] = 'Описание обязательно для заполнения';
    } else if (bio.trim().length < 10) {
      errors['bio'] = 'Описание должно содержать минимум 10 символов';
    }

    if (description.trim().isEmpty) {
      errors['description'] = 'Краткое описание обязательно';
    } else if (description.trim().length < 5) {
      errors['description'] =
          'Краткое описание должно содержать минимум 5 символов';
    }

    if (location.trim().isEmpty) {
      errors['location'] = 'Местоположение обязательно';
    }

    if (categories.isEmpty) {
      errors['categories'] = 'Выберите хотя бы одну категорию';
    }

    if (yearsOfExperience < 0) {
      errors['yearsOfExperience'] = 'Опыт не может быть отрицательным';
    }

    if (hourlyRate <= 0) {
      errors['hourlyRate'] = 'Почасовая ставка должна быть больше 0';
    }

    return errors;
  }

  /// Проверка валидности формы
  bool get isValid => validate().isEmpty;
}
