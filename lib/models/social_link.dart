/// Социальная ссылка специалиста
class SocialLink {
  const SocialLink({
    required this.id,
    required this.specialistId,
    required this.platform,
    required this.url,
    required this.username,
    required this.isVerified,
    required this.isPublic,
    this.followersCount,
    this.createdAt,
  });

  /// Уникальный идентификатор
  final String id;

  /// ID специалиста
  final String specialistId;

  /// Платформа
  final SocialPlatform platform;

  /// URL профиля
  final String url;

  /// Имя пользователя
  final String username;

  /// Верифицирован ли аккаунт
  final bool isVerified;

  /// Публичный доступ
  final bool isPublic;

  /// Количество подписчиков
  final int? followersCount;

  /// Дата добавления
  final DateTime? createdAt;

  /// Создать из Map
  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      id: map['id'] as String,
      specialistId: map['specialistId'] as String,
      platform: SocialPlatform.fromString(map['platform'] as String),
      url: map['url'] as String,
      username: map['username'] as String,
      isVerified: (map['isVerified'] as bool?) ?? false,
      isPublic: (map['isPublic'] as bool?) ?? true,
      followersCount: map['followersCount'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'specialistId': specialistId,
      'platform': platform.value,
      'url': url,
      'username': username,
      'isVerified': isVerified,
      'isPublic': isPublic,
      'followersCount': followersCount,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  /// Создать копию с изменениями
  SocialLink copyWith({
    String? id,
    String? specialistId,
    SocialPlatform? platform,
    String? url,
    String? username,
    bool? isVerified,
    bool? isPublic,
    int? followersCount,
    DateTime? createdAt,
  }) {
    return SocialLink(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Платформы социальных сетей
enum SocialPlatform {
  instagram('instagram'),
  vk('vk'),
  telegram('telegram'),
  youtube('youtube'),
  tiktok('tiktok'),
  facebook('facebook'),
  twitter('twitter'),
  linkedin('linkedin'),
  website('website');

  const SocialPlatform(this.value);
  final String value;

  static SocialPlatform fromString(String value) {
    switch (value) {
      case 'instagram':
        return SocialPlatform.instagram;
      case 'vk':
        return SocialPlatform.vk;
      case 'telegram':
        return SocialPlatform.telegram;
      case 'youtube':
        return SocialPlatform.youtube;
      case 'tiktok':
        return SocialPlatform.tiktok;
      case 'facebook':
        return SocialPlatform.facebook;
      case 'twitter':
        return SocialPlatform.twitter;
      case 'linkedin':
        return SocialPlatform.linkedin;
      case 'website':
        return SocialPlatform.website;
      default:
        return SocialPlatform.website;
    }
  }

  /// Получить иконку для платформы
  String get icon {
    switch (this) {
      case SocialPlatform.instagram:
        return '📷';
      case SocialPlatform.vk:
        return '🔵';
      case SocialPlatform.telegram:
        return '✈️';
      case SocialPlatform.youtube:
        return '📺';
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.linkedin:
        return '💼';
      case SocialPlatform.website:
        return '🌐';
    }
  }

  /// Получить цвет для платформы
  String get color {
    switch (this) {
      case SocialPlatform.instagram:
        return '#E4405F';
      case SocialPlatform.vk:
        return '#0077FF';
      case SocialPlatform.telegram:
        return '#0088CC';
      case SocialPlatform.youtube:
        return '#FF0000';
      case SocialPlatform.tiktok:
        return '#000000';
      case SocialPlatform.facebook:
        return '#1877F2';
      case SocialPlatform.twitter:
        return '#1DA1F2';
      case SocialPlatform.linkedin:
        return '#0077B5';
      case SocialPlatform.website:
        return '#6B7280';
    }
  }
}

