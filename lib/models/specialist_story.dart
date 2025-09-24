import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип медиа в сторис
enum StoryMediaType {
  image,
  video,
}

/// Статус сторис
enum StoryStatus {
  active,
  expired,
  archived,
}

/// Модель сторис специалиста
class SpecialistStory {
  const SpecialistStory({
    required this.id,
    required this.specialistId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    this.expiresAt,
    this.caption,
    this.location,
    this.tags = const [],
    this.viewers = const [],
    this.views = 0,
    this.likes = 0,
    this.replies = 0,
    this.isPublic = true,
    this.status = StoryStatus.active,
    this.duration = 15, // секунды
    this.priceInfo,
    this.serviceInfo,
  });

  /// Создать из документа Firestore
  factory SpecialistStory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistStory(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      mediaUrl: data['mediaUrl'] as String,
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == data['mediaType'],
        orElse: () => StoryMediaType.image,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      caption: data['caption'] as String?,
      location: data['location'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      viewers: List<String>.from(data['viewers'] ?? []),
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
      replies: data['replies'] as int? ?? 0,
      isPublic: data['isPublic'] as bool? ?? true,
      status: StoryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StoryStatus.active,
      ),
      duration: data['duration'] as int? ?? 15,
      priceInfo: data['priceInfo'] != null
          ? StoryPriceInfo.fromMap(data['priceInfo'] as Map<String, dynamic>)
          : null,
      serviceInfo: data['serviceInfo'] != null
          ? StoryServiceInfo.fromMap(data['serviceInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String specialistId;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? caption;
  final String? location;
  final List<String> tags;
  final List<String> viewers;
  final int views;
  final int likes;
  final int replies;
  final bool isPublic;
  final StoryStatus status;
  final int duration;
  final StoryPriceInfo? priceInfo;
  final StoryServiceInfo? serviceInfo;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'caption': caption,
        'location': location,
        'tags': tags,
        'viewers': viewers,
        'views': views,
        'likes': likes,
        'replies': replies,
        'isPublic': isPublic,
        'status': status.name,
        'duration': duration,
        'priceInfo': priceInfo?.toMap(),
        'serviceInfo': serviceInfo?.toMap(),
      };

  /// Копировать с изменениями
  SpecialistStory copyWith({
    String? id,
    String? specialistId,
    String? mediaUrl,
    StoryMediaType? mediaType,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? caption,
    String? location,
    List<String>? tags,
    List<String>? viewers,
    int? views,
    int? likes,
    int? replies,
    bool? isPublic,
    StoryStatus? status,
    int? duration,
    StoryPriceInfo? priceInfo,
    StoryServiceInfo? serviceInfo,
  }) =>
      SpecialistStory(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        mediaType: mediaType ?? this.mediaType,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        caption: caption ?? this.caption,
        location: location ?? this.location,
        tags: tags ?? this.tags,
        viewers: viewers ?? this.viewers,
        views: views ?? this.views,
        likes: likes ?? this.likes,
        replies: replies ?? this.replies,
        isPublic: isPublic ?? this.isPublic,
        status: status ?? this.status,
        duration: duration ?? this.duration,
        priceInfo: priceInfo ?? this.priceInfo,
        serviceInfo: serviceInfo ?? this.serviceInfo,
      );

  /// Проверить, просмотрел ли пользователь сторис
  bool isViewedBy(String userId) => viewers.contains(userId);

  /// Проверить, истекла ли сторис
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Получить время до истечения
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Получить отформатированное время создания
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  /// Получить отформатированное количество просмотров
  String get formattedViews {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  /// Получить отформатированное количество лайков
  String get formattedLikes {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }
}

/// Информация о цене в сторис
class StoryPriceInfo {
  const StoryPriceInfo({
    required this.serviceName,
    required this.price,
    this.originalPrice,
    this.discount,
    this.currency = '₽',
    this.isLimitedTime = false,
  });

  factory StoryPriceInfo.fromMap(Map<String, dynamic> data) => StoryPriceInfo(
        serviceName: data['serviceName'] as String,
        price: (data['price'] as num).toDouble(),
        originalPrice: data['originalPrice'] != null
            ? (data['originalPrice'] as num).toDouble()
            : null,
        discount: data['discount'] as int?,
        currency: data['currency'] as String? ?? '₽',
        isLimitedTime: data['isLimitedTime'] as bool? ?? false,
      );

  final String serviceName;
  final double price;
  final double? originalPrice;
  final int? discount;
  final String currency;
  final bool isLimitedTime;

  Map<String, dynamic> toMap() => {
        'serviceName': serviceName,
        'price': price,
        'originalPrice': originalPrice,
        'discount': discount,
        'currency': currency,
        'isLimitedTime': isLimitedTime,
      };

  /// Получить отформатированную цену
  String get formattedPrice => '$price $currency';

  /// Получить отформатированную оригинальную цену
  String? get formattedOriginalPrice =>
      originalPrice != null ? '$originalPrice $currency' : null;

  /// Проверить, есть ли скидка
  bool get hasDiscount => discount != null && discount! > 0;
}

/// Информация об услуге в сторис
class StoryServiceInfo {
  const StoryServiceInfo({
    required this.serviceId,
    required this.serviceName,
    this.description,
    this.category,
    this.isAvailable = true,
  });

  factory StoryServiceInfo.fromMap(Map<String, dynamic> data) => StoryServiceInfo(
        serviceId: data['serviceId'] as String,
        serviceName: data['serviceName'] as String,
        description: data['description'] as String?,
        category: data['category'] as String?,
        isAvailable: data['isAvailable'] as bool? ?? true,
      );

  final String serviceId;
  final String serviceName;
  final String? description;
  final String? category;
  final bool isAvailable;

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'serviceName': serviceName,
        'description': description,
        'category': category,
        'isAvailable': isAvailable,
      };
}
