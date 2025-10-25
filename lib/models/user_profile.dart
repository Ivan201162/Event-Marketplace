/// Модель профиля пользователя
class UserProfile {
  final String id;
  final String displayName;
  final String username;
  final String email;
  final String? phone;
  final String bio;
  final String city;
  final String? website;
  final Map<String, String> socialLinks;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isPro;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int ideasCount;
  final int requestsCount;
  final bool isFollowing;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    this.phone,
    required this.bio,
    required this.city,
    this.website,
    required this.socialLinks,
    this.avatarUrl,
    this.coverUrl,
    required this.isPro,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.ideasCount,
    required this.requestsCount,
    required this.isFollowing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      bio: map['bio'] ?? '',
      city: map['city'] ?? '',
      website: map['website'],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      avatarUrl: map['avatarUrl'],
      coverUrl: map['coverUrl'],
      isPro: map['isPro'] ?? false,
      isVerified: map['isVerified'] ?? false,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      ideasCount: map['ideasCount'] ?? 0,
      requestsCount: map['requestsCount'] ?? 0,
      isFollowing: map['isFollowing'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
      'email': email,
      'phone': phone,
      'bio': bio,
      'city': city,
      'website': website,
      'socialLinks': socialLinks,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'isPro': isPro,
      'isVerified': isVerified,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'ideasCount': ideasCount,
      'requestsCount': requestsCount,
      'isFollowing': isFollowing,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? bio,
    String? city,
    String? website,
    Map<String, String>? socialLinks,
    String? avatarUrl,
    String? coverUrl,
    bool? isPro,
    bool? isVerified,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? ideasCount,
    int? requestsCount,
    bool? isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isPro: isPro ?? this.isPro,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      ideasCount: ideasCount ?? this.ideasCount,
      requestsCount: requestsCount ?? this.requestsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}