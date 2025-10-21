import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User type enumeration
enum UserType {
  physical('Физ. лицо'),
  selfEmployed('Самозанятый'),
  individual('ИП'),
  studio('Студия');

  const UserType(this.displayName);
  final String displayName;

  /// Get description for user type
  String get description {
    switch (this) {
      case UserType.physical:
        return 'Физическое лицо';
      case UserType.selfEmployed:
        return 'Самозанятый';
      case UserType.individual:
        return 'Индивидуальный предприниматель';
      case UserType.studio:
        return 'Студия';
    }
  }
}

/// App user model
class AppUser extends Equatable {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? city;
  final String? status;
  final String? avatarUrl;
  final String? displayName;
  final String? photoURL;
  final int followersCount;
  final UserType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final Map<String, dynamic>? preferences;
  final List<String> favoriteSpecialists;

  const AppUser({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    this.city,
    this.status,
    this.avatarUrl,
    this.followersCount = 0,
    this.type = UserType.physical,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.preferences,
    this.favoriteSpecialists = const [],
    this.displayName,
    this.photoURL,
  });

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      city: data['city'],
      status: data['status'],
      avatarUrl: data['avatarUrl'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      followersCount: data['followersCount'] ?? 0,
      type: UserType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => UserType.physical,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      preferences: data['preferences'] as Map<String, dynamic>?,
      favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] ?? []),
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'status': status,
      'avatarUrl': avatarUrl,
      'displayName': displayName,
      'photoURL': photoURL,
      'followersCount': followersCount,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isOnline': isOnline,
      'preferences': preferences,
      'favoriteSpecialists': favoriteSpecialists,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? status,
    String? avatarUrl,
    String? displayName,
    String? photoURL,
    int? followersCount,
    UserType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    Map<String, dynamic>? preferences,
    List<String>? favoriteSpecialists,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      followersCount: followersCount ?? this.followersCount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
      favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
    );
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty && city != null && city!.isNotEmpty;
  }

  /// Get display name for user type
  String get typeDisplayName => type.displayName;

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    phone,
    city,
    status,
    avatarUrl,
    followersCount,
    type,
    createdAt,
    updatedAt,
    isOnline,
    preferences,
    favoriteSpecialists,
  ];

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, city: $city, type: $type)';
  }
}
