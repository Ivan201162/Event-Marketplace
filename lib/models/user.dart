import 'package:cloud_firestore/cloud_firestore.dart';

/// Семейный статус
enum MaritalStatus {
  single, // Холост/не замужем
  married, // Женат/замужем
  divorced, // Разведен/разведена
  widowed, // Вдовец/вдова
  inRelationship, // В отношениях
}

/// Расширение для MaritalStatus
extension MaritalStatusExtension on MaritalStatus {
  String get displayName {
    switch (this) {
      case MaritalStatus.single:
        return 'Холост/не замужем';
      case MaritalStatus.married:
        return 'Женат/замужем';
      case MaritalStatus.divorced:
        return 'Разведен/разведена';
      case MaritalStatus.widowed:
        return 'Вдовец/вдова';
      case MaritalStatus.inRelationship:
        return 'В отношениях';
    }
  }
}

/// Роли пользователей в системе
enum UserRole {
  customer, // Заказчик
  specialist, // Исполнитель/специалист
  organizer, // Организатор
  moderator, // Модератор
  guest, // Гость
  admin, // Администратор
}

/// Расширение для UserRole
extension UserRoleExtension on UserRole {
  /// Получить отображаемое имя роли
  String get roleDisplayName {
    switch (this) {
      case UserRole.customer:
        return 'Клиент';
      case UserRole.specialist:
        return 'Специалист';
      case UserRole.organizer:
        return 'Организатор';
      case UserRole.moderator:
        return 'Модератор';
      case UserRole.guest:
        return 'Гость';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

/// Модель пользователя
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.socialProvider,
    this.socialId,
    this.additionalData,
    this.maritalStatus,
    this.weddingDate,
    this.partnerName,
    this.anniversaryRemindersEnabled = false,
  });

  /// Создать пользователя из документа Firestore
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      role: _parseUserRole(data['role']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      socialProvider: data['socialProvider'],
      socialId: data['socialId'],
      additionalData: data['additionalData'],
      maritalStatus: data['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (e) => e.name == data['maritalStatus'],
              orElse: () => MaritalStatus.single,
            )
          : null,
      weddingDate: data['weddingDate'] != null
          ? (data['weddingDate'] as Timestamp).toDate()
          : null,
      partnerName: data['partnerName'],
      anniversaryRemindersEnabled: data['anniversaryRemindersEnabled'] ?? false,
    );
  }

  /// Создать пользователя из Firebase User
  factory AppUser.fromFirebaseUser(
    String uid,
    String email, {
    String? displayName,
    String? photoURL,
    UserRole role = UserRole.customer,
    String? socialProvider,
    String? socialId,
  }) =>
      AppUser(
        id: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        socialProvider: socialProvider,
        socialId: socialId,
      );
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? socialProvider; // 'google', 'vk', 'email'
  final String? socialId; // ID в социальной сети
  final Map<String, dynamic>? additionalData;

  // Семейная информация
  final MaritalStatus? maritalStatus;
  final DateTime? weddingDate;
  final String? partnerName;
  final bool anniversaryRemindersEnabled;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'isActive': isActive,
        'socialProvider': socialProvider,
        'socialId': socialId,
        'additionalData': additionalData,
        'maritalStatus': maritalStatus?.name,
        'weddingDate':
            weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
        'partnerName': partnerName,
        'anniversaryRemindersEnabled': anniversaryRemindersEnabled,
      };

  /// Копировать с изменениями
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? socialProvider,
    String? socialId,
    Map<String, dynamic>? additionalData,
    MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    String? partnerName,
    bool? anniversaryRemindersEnabled,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoURL: photoURL ?? this.photoURL,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        isActive: isActive ?? this.isActive,
        socialProvider: socialProvider ?? this.socialProvider,
        socialId: socialId ?? this.socialId,
        additionalData: additionalData ?? this.additionalData,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        weddingDate: weddingDate ?? this.weddingDate,
        partnerName: partnerName ?? this.partnerName,
        anniversaryRemindersEnabled:
            anniversaryRemindersEnabled ?? this.anniversaryRemindersEnabled,
      );

  /// Получить отображаемое имя
  String get displayNameOrEmail => displayName ?? email.split('@').first;

  /// Геттер для совместимости с кодом, использующим uid
  String get uid => id;

  /// Геттер для совместимости с кодом, использующим name
  String get name => displayName ?? email.split('@').first;

  /// Геттер для совместимости с кодом, использующим photoUrl
  String? get photoUrl => photoURL;

  /// Геттер для совместимости с кодом, использующим lastLogin
  DateTime? get lastLogin => lastLoginAt;

  /// Геттер для проверки заблокированности пользователя
  bool get isBanned => !isActive;

  /// Геттер для причины блокировки
  String? get banReason => additionalData?['banReason'] as String?;

  /// Геттер для биографии пользователя
  String? get bio => additionalData?['bio'] as String?;

  /// Геттер для проверки верификации
  bool get isVerified => additionalData?['isVerified'] as bool? ?? false;

  /// Геттер для специализаций
  List<String> get specialties =>
      List<String>.from(additionalData?['specialties'] ?? []);

  /// Геттер для специализации (строка)
  String? get specialization => additionalData?['specialization'] as String?;

  /// Геттер для телефона
  String? get phone => additionalData?['phone'] as String?;

  /// Геттер для аватара (алиас для photoURL)
  String? get avatar => photoURL;

  /// Проверить, является ли пользователь специалистом
  bool get isSpecialist => role == UserRole.specialist;

  /// Проверить, является ли пользователь заказчиком
  bool get isCustomer => role == UserRole.customer;

  /// Проверить, является ли пользователь гостем
  bool get isGuest => role == UserRole.guest;

  /// Проверить, является ли пользователь администратором
  bool get isAdmin => role == UserRole.admin;

  /// Получить русское название роли
  String get roleDisplayName {
    switch (role) {
      case UserRole.customer:
        return 'Заказчик';
      case UserRole.specialist:
        return 'Специалист';
      case UserRole.guest:
        return 'Гость';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  /// Парсинг роли из строки
  static UserRole _parseUserRole(roleData) {
    if (roleData == null) return UserRole.customer;

    final roleString = roleData.toString().toLowerCase();
    switch (roleString) {
      case 'specialist':
        return UserRole.specialist;
      case 'guest':
        return UserRole.guest;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, role: $role, displayName: $displayName)';
}
