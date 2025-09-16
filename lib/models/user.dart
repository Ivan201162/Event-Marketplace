import 'package:cloud_firestore/cloud_firestore.dart';

/// Роли пользователей в системе
enum UserRole {
  customer, // Заказчик
  specialist, // Исполнитель/специалист
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
      case UserRole.guest:
        return 'Гость';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

/// Модель пользователя
class AppUser {
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
  });

  /// Создать пользователя из документа Firestore
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
  }) {
    return AppUser(
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
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
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
    };
  }

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
  }) {
    return AppUser(
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
    );
  }

  /// Получить отображаемое имя
  String get displayNameOrEmail => displayName ?? email.split('@').first;

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
  static UserRole _parseUserRole(dynamic roleData) {
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
  String toString() {
    return 'AppUser(id: $id, email: $email, role: $role, displayName: $displayName)';
  }
}
