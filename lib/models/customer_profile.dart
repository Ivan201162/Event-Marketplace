import 'package:cloud_firestore/cloud_firestore.dart';

/// Семейный статус заказчика
enum MaritalStatus {
  single,      // Холост/не замужем
  married,     // Женат/замужем
  divorced,    // Разведен/разведена
  widowed,     // Вдовец/вдова
  inRelationship, // В отношениях
}

/// Модель профиля заказчика
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.location,
    this.birthDate,
    this.maritalStatus,
    this.familyMembers = const [],
    this.importantDates = const [],
    this.preferences = const {},
    this.isVerified = false,
    this.registrationDate,
    this.lastActiveAt,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.favoriteSpecialists = const [],
    this.blockedSpecialists = const [],
    this.notificationSettings = const {},
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final DateTime? birthDate;
  final MaritalStatus? maritalStatus;
  final List<FamilyMember> familyMembers;
  final List<ImportantDate> importantDates;
  final Map<String, dynamic> preferences;
  final bool isVerified;
  final DateTime? registrationDate;
  final DateTime? lastActiveAt;
  final int totalOrders;
  final double totalSpent;
  final List<String> favoriteSpecialists;
  final List<String> blockedSpecialists;
  final Map<String, bool> notificationSettings;

  /// Создать из документа Firestore
  factory CustomerProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CustomerProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      maritalStatus: data['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (status) => status.name == data['maritalStatus'],
              orElse: () => MaritalStatus.single,
            )
          : null,
      familyMembers: (data['familyMembers'] as List<dynamic>?)
          ?.map((member) => FamilyMember.fromMap(member as Map<String, dynamic>))
          .toList() ?? [],
      importantDates: (data['importantDates'] as List<dynamic>?)
          ?.map((date) => ImportantDate.fromMap(date as Map<String, dynamic>))
          .toList() ?? [],
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      isVerified: data['isVerified'] as bool? ?? false,
      registrationDate: data['registrationDate'] != null
          ? (data['registrationDate'] as Timestamp).toDate()
          : null,
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      totalOrders: data['totalOrders'] as int? ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] ?? []),
      blockedSpecialists: List<String>.from(data['blockedSpecialists'] ?? []),
      notificationSettings: Map<String, bool>.from(data['notificationSettings'] ?? {}),
    );
  }

  /// Создать из Map
  factory CustomerProfile.fromMap(Map<String, dynamic> data) => CustomerProfile(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    email: data['email'] as String? ?? '',
    phone: data['phone'] as String?,
    avatarUrl: data['avatarUrl'] as String?,
    bio: data['bio'] as String?,
    location: data['location'] as String?,
    birthDate: data['birthDate'] is Timestamp 
        ? (data['birthDate'] as Timestamp).toDate()
        : data['birthDate'] != null 
            ? DateTime.parse(data['birthDate'] as String)
            : null,
    maritalStatus: data['maritalStatus'] != null
        ? MaritalStatus.values.firstWhere(
            (status) => status.name == data['maritalStatus'],
            orElse: () => MaritalStatus.single,
          )
        : null,
    familyMembers: (data['familyMembers'] as List<dynamic>?)
        ?.map((member) => FamilyMember.fromMap(member as Map<String, dynamic>))
        .toList() ?? [],
    importantDates: (data['importantDates'] as List<dynamic>?)
        ?.map((date) => ImportantDate.fromMap(date as Map<String, dynamic>))
        .toList() ?? [],
    preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    isVerified: data['isVerified'] as bool? ?? false,
    registrationDate: data['registrationDate'] is Timestamp
        ? (data['registrationDate'] as Timestamp).toDate()
        : data['registrationDate'] != null
            ? DateTime.parse(data['registrationDate'] as String)
            : null,
    lastActiveAt: data['lastActiveAt'] is Timestamp
        ? (data['lastActiveAt'] as Timestamp).toDate()
        : data['lastActiveAt'] != null
            ? DateTime.parse(data['lastActiveAt'] as String)
            : null,
    totalOrders: data['totalOrders'] as int? ?? 0,
    totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
    favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] ?? []),
    blockedSpecialists: List<String>.from(data['blockedSpecialists'] ?? []),
    notificationSettings: Map<String, bool>.from(data['notificationSettings'] ?? {}),
  );

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'location': location,
    'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'maritalStatus': maritalStatus?.name,
    'familyMembers': familyMembers.map((member) => member.toMap()).toList(),
    'importantDates': importantDates.map((date) => date.toMap()).toList(),
    'preferences': preferences,
    'isVerified': isVerified,
    'registrationDate': registrationDate != null ? Timestamp.fromDate(registrationDate!) : null,
    'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    'totalOrders': totalOrders,
    'totalSpent': totalSpent,
    'favoriteSpecialists': favoriteSpecialists,
    'blockedSpecialists': blockedSpecialists,
    'notificationSettings': notificationSettings,
  };

  /// Копировать с изменениями
  CustomerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? location,
    DateTime? birthDate,
    MaritalStatus? maritalStatus,
    List<FamilyMember>? familyMembers,
    List<ImportantDate>? importantDates,
    Map<String, dynamic>? preferences,
    bool? isVerified,
    DateTime? registrationDate,
    DateTime? lastActiveAt,
    int? totalOrders,
    double? totalSpent,
    List<String>? favoriteSpecialists,
    List<String>? blockedSpecialists,
    Map<String, bool>? notificationSettings,
  }) =>
      CustomerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        birthDate: birthDate ?? this.birthDate,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        familyMembers: familyMembers ?? this.familyMembers,
        importantDates: importantDates ?? this.importantDates,
        preferences: preferences ?? this.preferences,
        isVerified: isVerified ?? this.isVerified,
        registrationDate: registrationDate ?? this.registrationDate,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        totalOrders: totalOrders ?? this.totalOrders,
        totalSpent: totalSpent ?? this.totalSpent,
        favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
        blockedSpecialists: blockedSpecialists ?? this.blockedSpecialists,
        notificationSettings: notificationSettings ?? this.notificationSettings,
      );

  /// Получить возраст
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Проверить, является ли пользователь активным
  bool get isActive {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    return now.difference(lastActiveAt!).inDays < 7;
  }
}

/// Член семьи
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    this.avatarUrl,
    this.notes,
  });

  final String id;
  final String name;
  final String relationship; // 'spouse', 'child', 'parent', etc.
  final DateTime? birthDate;
  final String? avatarUrl;
  final String? notes;

  /// Создать из Map
  factory FamilyMember.fromMap(Map<String, dynamic> data) => FamilyMember(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    relationship: data['relationship'] as String? ?? '',
    birthDate: data['birthDate'] is Timestamp 
        ? (data['birthDate'] as Timestamp).toDate()
        : data['birthDate'] != null 
            ? DateTime.parse(data['birthDate'] as String)
            : null,
    avatarUrl: data['avatarUrl'] as String?,
    notes: data['notes'] as String?,
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'avatarUrl': avatarUrl,
    'notes': notes,
  };

  /// Получить возраст
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}

/// Важная дата
class ImportantDate {
  const ImportantDate({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    this.isRecurring = false,
    this.reminderDays = 7,
    this.category = 'personal',
  });

  final String id;
  final String title;
  final DateTime date;
  final String? description;
  final bool isRecurring;
  final int reminderDays;
  final String category; // 'personal', 'family', 'anniversary', etc.

  /// Создать из Map
  factory ImportantDate.fromMap(Map<String, dynamic> data) => ImportantDate(
    id: data['id'] as String? ?? '',
    title: data['title'] as String? ?? '',
    date: data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate()
        : DateTime.parse(data['date'] as String),
    description: data['description'] as String?,
    isRecurring: data['isRecurring'] as bool? ?? false,
    reminderDays: data['reminderDays'] as int? ?? 7,
    category: data['category'] as String? ?? 'personal',
  );

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': Timestamp.fromDate(date),
    'description': description,
    'isRecurring': isRecurring,
    'reminderDays': reminderDays,
    'category': category,
  };

  /// Проверить, скоро ли наступает дата
  bool get isUpcoming {
    final now = DateTime.now();
    final daysUntil = date.difference(now).inDays;
    return daysUntil >= 0 && daysUntil <= reminderDays;
  }

  /// Получить количество дней до даты
  int get daysUntil {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }
}