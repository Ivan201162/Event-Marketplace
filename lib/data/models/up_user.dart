import 'package:flutter/foundation.dart';

/// Типизированная модель пользователя для Firestore
@immutable
class UpUser {
  // customer|specialist|guest

  const UpUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role, this.phone,
    this.avatarUrl,
  });

  factory UpUser.fromMap(Map<String, dynamic> map) => UpUser(
        uid: (map['uid'] ?? map['id'] ?? '') as String,
        name: (map['name'] ?? map['displayName'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        phone: map['phone'] as String?,
        avatarUrl: map['avatarUrl'] ?? map['photoURL'] as String?,
        role: (map['role'] ?? 'customer') as String,
      );

  /// Создать из Firebase User
  factory UpUser.fromFirebaseUser(
    String uid,
    String email, {
    String? displayName,
    String? photoURL,
    String role = 'customer',
  }) =>
      UpUser(
        uid: uid,
        name: displayName ?? email.split('@').first,
        email: email,
        avatarUrl: photoURL,
        role: role,
      );
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'role': role,
      };

  /// Копировать с изменениями
  UpUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
  }) =>
      UpUser(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UpUser(uid: $uid, name: $name, email: $email, role: $role)';
}
