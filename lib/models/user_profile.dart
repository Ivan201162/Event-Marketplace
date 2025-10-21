import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user.dart';

/// Модель цены услуги
class ServicePrice extends Equatable {
  const ServicePrice({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'RUB',
    this.duration,
    this.isActive = true,
  });

  factory ServicePrice.fromMap(Map<String, dynamic> map) => ServicePrice(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    price: (map['price'] ?? 0.0).toDouble(),
    currency: map['currency'] ?? 'RUB',
    duration: map['duration'],
    isActive: map['isActive'] ?? true,
  );
  final String id;
  final String name;
  final String description;
  final double price;
  final String? currency;
  final int? duration; // в минутах
  final bool isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'currency': currency,
    'duration': duration,
    'isActive': isActive,
  };

  ServicePrice copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? duration,
    bool? isActive,
  }) => ServicePrice(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    duration: duration ?? this.duration,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [id, name, description, price, currency, duration, isActive];
}

/// Модель поста пользователя
class UserPost extends Equatable {
  const UserPost({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.videoUrl,
    required this.caption,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
    this.isVideo = false,
    this.thumbnailUrl,
  });

  factory UserPost.fromMap(Map<String, dynamic> map) => UserPost(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    imageUrl: map['imageUrl'],
    videoUrl: map['videoUrl'],
    caption: map['caption'] ?? '',
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    likes: map['likes'] ?? 0,
    comments: map['comments'] ?? 0,
    likedBy: List<String>.from(map['likedBy'] ?? []),
    isVideo: map['isVideo'] ?? false,
    thumbnailUrl: map['thumbnailUrl'],
  );
  final String id;
  final String userId;
  final String? imageUrl;
  final String? videoUrl;
  final String caption;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> likedBy;
  final bool isVideo;
  final String? thumbnailUrl;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'caption': caption,
    'timestamp': Timestamp.fromDate(timestamp),
    'likes': likes,
    'comments': comments,
    'likedBy': likedBy,
    'isVideo': isVideo,
    'thumbnailUrl': thumbnailUrl,
  };

  UserPost copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? videoUrl,
    String? caption,
    DateTime? timestamp,
    int? likes,
    int? comments,
    List<String>? likedBy,
    bool? isVideo,
    String? thumbnailUrl,
  }) => UserPost(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    imageUrl: imageUrl ?? this.imageUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    caption: caption ?? this.caption,
    timestamp: timestamp ?? this.timestamp,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    likedBy: likedBy ?? this.likedBy,
    isVideo: isVideo ?? this.isVideo,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    imageUrl,
    videoUrl,
    caption,
    timestamp,
    likes,
    comments,
    likedBy,
    isVideo,
    thumbnailUrl,
  ];
}

/// Модель сторис пользователя
class UserStory extends Equatable {
  const UserStory({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.videoUrl,
    this.caption,
    required this.timestamp,
    required this.expiresAt,
    this.isVideo = false,
    this.thumbnailUrl,
    this.viewedBy = const [],
  });

  factory UserStory.fromMap(Map<String, dynamic> map) => UserStory(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    imageUrl: map['imageUrl'],
    videoUrl: map['videoUrl'],
    caption: map['caption'],
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt:
        (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
    isVideo: map['isVideo'] ?? false,
    thumbnailUrl: map['thumbnailUrl'],
    viewedBy: List<String>.from(map['viewedBy'] ?? []),
  );
  final String id;
  final String userId;
  final String? imageUrl;
  final String? videoUrl;
  final String? caption;
  final DateTime timestamp;
  final DateTime expiresAt;
  final bool isVideo;
  final String? thumbnailUrl;
  final List<String> viewedBy;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'caption': caption,
    'timestamp': Timestamp.fromDate(timestamp),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'isVideo': isVideo,
    'thumbnailUrl': thumbnailUrl,
    'viewedBy': viewedBy,
  };

  UserStory copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? videoUrl,
    String? caption,
    DateTime? timestamp,
    DateTime? expiresAt,
    bool? isVideo,
    String? thumbnailUrl,
    List<String>? viewedBy,
  }) => UserStory(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    imageUrl: imageUrl ?? this.imageUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    caption: caption ?? this.caption,
    timestamp: timestamp ?? this.timestamp,
    expiresAt: expiresAt ?? this.expiresAt,
    isVideo: isVideo ?? this.isVideo,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    viewedBy: viewedBy ?? this.viewedBy,
  );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
    id,
    userId,
    imageUrl,
    videoUrl,
    caption,
    timestamp,
    expiresAt,
    isVideo,
    thumbnailUrl,
    viewedBy,
  ];
}

/// Модель отзыва
class UserReview extends Equatable {
  const UserReview({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    this.customerAvatarUrl,
    required this.rating,
    required this.comment,
    required this.timestamp,
    this.bookingId,
  });

  factory UserReview.fromMap(Map<String, dynamic> map) => UserReview(
    id: map['id'] ?? '',
    specialistId: map['specialistId'] ?? '',
    customerId: map['customerId'] ?? '',
    customerName: map['customerName'] ?? '',
    customerAvatarUrl: map['customerAvatarUrl'],
    rating: (map['rating'] ?? 0.0).toDouble(),
    comment: map['comment'] ?? '',
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    bookingId: map['bookingId'],
  );
  final String id;
  final String specialistId;
  final String customerId;
  final String customerName;
  final String? customerAvatarUrl;
  final double rating;
  final String comment;
  final DateTime timestamp;
  final String? bookingId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'specialistId': specialistId,
    'customerId': customerId,
    'customerName': customerName,
    'customerAvatarUrl': customerAvatarUrl,
    'rating': rating,
    'comment': comment,
    'timestamp': Timestamp.fromDate(timestamp),
    'bookingId': bookingId,
  };

  UserReview copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    String? customerName,
    String? customerAvatarUrl,
    double? rating,
    String? comment,
    DateTime? timestamp,
    String? bookingId,
  }) => UserReview(
    id: id ?? this.id,
    specialistId: specialistId ?? this.specialistId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    timestamp: timestamp ?? this.timestamp,
    bookingId: bookingId ?? this.bookingId,
  );

  @override
  List<Object?> get props => [
    id,
    specialistId,
    customerId,
    customerName,
    customerAvatarUrl,
    rating,
    comment,
    timestamp,
    bookingId,
  ];
}

/// Расширенная модель профиля пользователя в стиле Instagram/VK
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.city = '',
    this.photos = const [],
    this.videos = const [],
    this.stories = const [],
    this.services = const [],
    this.rating = 0.0,
    this.followers = 0,
    this.following = 0,
    this.phone = '',
    this.email = '',
    this.favoriteSpecialists = const [],
    this.recentBookings = const [],
    this.isVerified = false,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
    this.additionalData = const {},
  });

  /// Создать профиль из документа Firestore
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserProfile.fromMap(data, doc.id);
  }

  /// Создать профиль из Map
  factory UserProfile.fromMap(Map<String, dynamic> data, [String? id]) => UserProfile(
    id: id ?? data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    role: _parseUserRole(data['role']),
    bio: data['bio'] ?? '',
    avatarUrl: data['avatarUrl'] ?? '',
    coverUrl: data['coverUrl'] ?? '',
    city: data['city'] ?? '',
    photos: List<String>.from(data['photos'] ?? []),
    videos: List<String>.from(data['videos'] ?? []),
    stories: List<String>.from(data['stories'] ?? []),
    services:
        (data['services'] as List<dynamic>?)
            ?.map((service) => ServicePrice.fromMap(service as Map<String, dynamic>))
            .toList() ??
        [],
    rating: (data['rating'] as num? ?? 0.0).toDouble(),
    followers: data['followers'] as int? ?? 0,
    following: data['following'] as int? ?? 0,
    phone: data['phone'] ?? '',
    email: data['email'] ?? '',
    favoriteSpecialists: List<String>.from(data['favoriteSpecialists'] ?? []),
    recentBookings: List<String>.from(data['recentBookings'] ?? []),
    isVerified: data['isVerified'] as bool? ?? false,
    isPrivate: data['isPrivate'] as bool? ?? false,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt'].toString()))
        : DateTime.now(),
    additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
  );

  /// Создать профиль из AppUser
  factory UserProfile.fromAppUser(AppUser user) => UserProfile(
    id: user.id,
    name: user.displayName ?? user.email.split('@').first,
    role: user.role,
    bio: user.bio ?? '',
    avatarUrl: user.photoURL ?? '',
    phone: user.phone ?? '',
    email: user.email,
    isVerified: user.isVerified,
    createdAt: user.createdAt,
    updatedAt: DateTime.now(),
    additionalData: user.additionalData ?? {},
  );
  final String id;
  final String name;
  final UserRole role;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final String city;
  final List<String> photos;
  final List<String> videos;
  final List<String> stories;
  final List<ServicePrice> services;
  final double rating;
  final int followers;
  final int following;
  final String phone;
  final String email;
  final List<String> favoriteSpecialists;
  final List<String> recentBookings;
  final bool isVerified;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> additionalData;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role.name,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'coverUrl': coverUrl,
    'city': city,
    'photos': photos,
    'videos': videos,
    'stories': stories,
    'services': services.map((service) => service.toMap()).toList(),
    'rating': rating,
    'followers': followers,
    'following': following,
    'phone': phone,
    'email': email,
    'favoriteSpecialists': favoriteSpecialists,
    'recentBookings': recentBookings,
    'isVerified': isVerified,
    'isPrivate': isPrivate,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'additionalData': additionalData,
  };

  /// Копировать с изменениями
  UserProfile copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? city,
    List<String>? photos,
    List<String>? videos,
    List<String>? stories,
    List<ServicePrice>? services,
    double? rating,
    int? followers,
    int? following,
    String? phone,
    String? email,
    List<String>? favoriteSpecialists,
    List<String>? recentBookings,
    bool? isVerified,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    city: city ?? this.city,
    photos: photos ?? this.photos,
    videos: videos ?? this.videos,
    stories: stories ?? this.stories,
    services: services ?? this.services,
    rating: rating ?? this.rating,
    followers: followers ?? this.followers,
    following: following ?? this.following,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    favoriteSpecialists: favoriteSpecialists ?? this.favoriteSpecialists,
    recentBookings: recentBookings ?? this.recentBookings,
    isVerified: isVerified ?? this.isVerified,
    isPrivate: isPrivate ?? this.isPrivate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    additionalData: additionalData ?? this.additionalData,
  );

  /// Проверить, является ли пользователь специалистом
  bool get isSpecialist => role == UserRole.specialist;

  /// Проверить, является ли пользователь заказчиком
  bool get isCustomer => role == UserRole.customer;

  /// Получить количество постов
  int get postsCount => photos.length + videos.length;

  /// Получить количество активных сторис
  int get activeStoriesCount => stories.length;

  /// Получить отображаемое имя роли
  String get roleDisplayName => role.roleDisplayName;

  /// Парсинг роли из строки
  static UserRole _parseUserRole(roleData) {
    if (roleData == null) return UserRole.customer;

    final roleString = roleData.toString().toLowerCase();
    switch (roleString) {
      case 'specialist':
        return UserRole.specialist;
      case 'organizer':
        return UserRole.organizer;
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      case 'guest':
        return UserRole.guest;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    bio,
    avatarUrl,
    coverUrl,
    city,
    photos,
    videos,
    stories,
    services,
    rating,
    followers,
    following,
    phone,
    email,
    favoriteSpecialists,
    recentBookings,
    isVerified,
    isPrivate,
    createdAt,
    updatedAt,
    additionalData,
  ];

  @override
  String toString() => 'UserProfile(id: $id, name: $name, role: $role)';
}
