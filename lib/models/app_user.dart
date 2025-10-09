import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель пользователя приложения
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    this.city,
    this.region,
    this.avatarUrl,
    this.role = 'customer',
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    this.metadata = const {},
  });

  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final String? city;
  final String? region;
  final String? avatarUrl;
  final String role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  /// Создать пользователя из Map
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? data['displayName'] ?? 'Без имени',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      city: data['city'],
      region: data['region'],
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'customer',
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      createdAt: _parseTs(data['createdAt']),
      updatedAt: _parseTs(data['updatedAt']),
      lastLoginAt: _parseTs(data['lastLoginAt']),
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать пользователя из DocumentSnapshot
  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap({...data, 'uid': doc.id});
  }

  /// Парсинг Timestamp
  static DateTime? _parseTs(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'metadata': metadata,
    };

    if (phoneNumber?.trim().isNotEmpty == true) {
      map['phoneNumber'] = phoneNumber;
    }
    if (photoUrl?.trim().isNotEmpty == true) {
      map['photoUrl'] = photoUrl;
    }
    if (city?.trim().isNotEmpty == true) {
      map['city'] = city;
    }
    if (region?.trim().isNotEmpty == true) {
      map['region'] = region;
    }
    if (avatarUrl?.trim().isNotEmpty == true) {
      map['avatarUrl'] = avatarUrl;
    }
    if (createdAt != null) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    if (updatedAt != null) {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }
    if (lastLoginAt != null) {
      map['lastLoginAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Создать копию с изменениями
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? city,
    String? region,
    String? avatarUrl,
    String? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      city: city ?? this.city,
      region: region ?? this.region,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'AppUser{uid: $uid, name: $name, email: $email, role: $role}';
  }
}

