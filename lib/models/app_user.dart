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
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? city;
  final String? status;
  final String? avatarUrl;
  final String? displayName;
  final String? photoURL;
  final UserType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final Map<String, dynamic>? preferences;
  final List<String> favoriteSpecialists;
  final String? bio;
  final String? description;
  final double? hourlyRate;
  final String? specialistType;

  // Pro account fields
  final bool isProAccount;
  final String? proCategory; // Ведущий, Диджей, Фотограф и т.д.
  final bool isVerified;
  final List<String> socialLinks; // Ссылки на соцсети
  final String? website;
  final Map<String, String> ctaButtons; // CTA кнопки для Pro аккаунтов
  final int followersCount;
  final int followingCount;
  final int postsCount;

  /// Get user ID (alias for uid)
  String get id => uid;

  const AppUser({
    required this.uid,
    required this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.city,
    this.status,
    this.avatarUrl,
    this.type = UserType.physical,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.preferences,
    this.favoriteSpecialists = const [],
    this.displayName,
    this.photoURL,
    this.bio,
    this.description,
    this.hourlyRate,
    this.specialistType,
    this.isProAccount = false,
    this.proCategory,
    this.isVerified = false,
    this.socialLinks = const [],
    this.website,
    this.ctaButtons = const {},
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      phone: data['phone'],
      city: data['city'],
      status: data['status'],
      avatarUrl: data['avatarUrl'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      type: UserType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => UserType.physical,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      preferences: data['preferences'] as Map<String, dynamic>?,
      favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] ?? []),
      bio: data['bio'],
      description: data['description'],
      hourlyRate: data['hourlyRate']?.toDouble(),
      specialistType: data['specialistType'],
      isProAccount: data['isProAccount'] ?? false,
      proCategory: data['proCategory'],
      isVerified: data['isVerified'] ?? false,
      socialLinks: List<String>.from(data['socialLinks'] ?? []),
      website: data['website'],
      ctaButtons: Map<String, String>.from(data['ctaButtons'] ?? {}),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
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
      'bio': bio,
      'description': description,
      'hourlyRate': hourlyRate,
      'specialistType': specialistType,
      'isProAccount': isProAccount,
      'proCategory': proCategory,
      'isVerified': isVerified,
      'socialLinks': socialLinks,
      'website': website,
      'ctaButtons': ctaButtons,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? name,
    String? firstName,
    String? lastName,
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
    String? bio,
    String? description,
    double? hourlyRate,
    String? specialistType,
    bool isProAccount = false,
    String? proCategory,
    bool isVerified = false,
    List<String> socialLinks = const [],
    String? website,
    Map<String, String> ctaButtons = const {},
    int followingCount = 0,
    int postsCount = 0,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
      bio: bio ?? this.bio,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      specialistType: specialistType ?? this.specialistType,
      isProAccount: isProAccount,
      proCategory: proCategory ?? this.proCategory,
      isVerified: isVerified,
      socialLinks: socialLinks,
      website: website ?? this.website,
      ctaButtons: ctaButtons,
      followingCount: followingCount,
      postsCount: postsCount,
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
        firstName,
        lastName,
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
        bio,
        description,
        hourlyRate,
        specialistType,
        isProAccount,
        proCategory,
        isVerified,
        socialLinks,
        website,
        ctaButtons,
        followersCount,
        followingCount,
        postsCount,
      ];

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, city: $city, type: $type)';
  }
}
