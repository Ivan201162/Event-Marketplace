import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи мероприятия
class EventIdea {
  const EventIdea({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.images,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    this.tags = const [],
    this.category,
    this.budget,
    this.duration,
    this.guests,
    this.location,
    this.isPublic = true,
    this.isFeatured = false,
    this.metadata = const {},
    this.imageUrl,
    this.guestCount,
    this.season,
    this.style,
    this.colorScheme,
    this.inspiration,
    this.createdBy,
    this.commentsCount,
    this.mediaUrl,
    this.isVideo,
    this.price,
    this.priceCurrency,
    this.requiredSkills,
    this.likesCount,
    this.savesCount,
    this.sharesCount,
  });

  /// Создать из документа Firestore
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventIdea(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      images: (data['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorName: data['authorName']?.toString(),
      authorAvatar: data['authorAvatar']?.toString(),
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      shares: (data['shares'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      category: data['category']?.toString(),
      budget: (data['budget'] as num?)?.toDouble(),
      duration: (data['duration'] as num?)?.toInt(),
      guests: (data['guests'] as num?)?.toInt(),
      location: data['location']?.toString(),
      isPublic: data['isPublic'] != false,
      isFeatured: data['isFeatured'] == true,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      imageUrl: data['imageUrl']?.toString(),
      guestCount: (data['guestCount'] as num?)?.toInt(),
      season: data['season']?.toString(),
      style: data['style']?.toString(),
      colorScheme: (data['colorScheme'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      inspiration: data['inspiration']?.toString(),
      createdBy: data['createdBy']?.toString(),
      commentsCount: (data['commentsCount'] as num?)?.toInt(),
      mediaUrl: data['mediaUrl']?.toString(),
      isVideo: data['isVideo'] as bool?,
      price: (data['price'] as num?)?.toDouble(),
      priceCurrency: data['priceCurrency']?.toString(),
      requiredSkills: (data['requiredSkills'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      likesCount: (data['likesCount'] as num?)?.toInt(),
      savesCount: (data['savesCount'] as num?)?.toInt(),
      sharesCount: (data['sharesCount'] as num?)?.toInt(),
    );
  }

  /// Создать из Map
  factory EventIdea.fromMap(Map<String, dynamic> data) => EventIdea(
        id: data['id']?.toString() ?? '',
        authorId: data['authorId']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        images: (data['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        authorName: data['authorName']?.toString(),
        authorAvatar: data['authorAvatar']?.toString(),
        likes: (data['likes'] as num?)?.toInt() ?? 0,
        comments: (data['comments'] as num?)?.toInt() ?? 0,
        shares: (data['shares'] as num?)?.toInt() ?? 0,
        views: (data['views'] as num?)?.toInt() ?? 0,
        tags: (data['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        category: data['category']?.toString(),
        budget: (data['budget'] as num?)?.toDouble(),
        duration: (data['duration'] as num?)?.toInt(),
        guests: (data['guests'] as num?)?.toInt(),
        location: data['location']?.toString(),
        isPublic: data['isPublic'] != false,
        isFeatured: data['isFeatured'] == true,
        metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
        imageUrl: data['imageUrl']?.toString(),
        guestCount: (data['guestCount'] as num?)?.toInt(),
        season: data['season']?.toString(),
        style: data['style']?.toString(),
        colorScheme: (data['colorScheme'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        inspiration: data['inspiration']?.toString(),
        createdBy: data['createdBy']?.toString(),
        commentsCount: (data['commentsCount'] as num?)?.toInt(),
        mediaUrl: data['mediaUrl']?.toString(),
        isVideo: data['isVideo'] as bool?,
        price: (data['price'] as num?)?.toDouble(),
        priceCurrency: data['priceCurrency']?.toString(),
        requiredSkills: (data['requiredSkills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        likesCount: (data['likesCount'] as num?)?.toInt(),
        savesCount: (data['savesCount'] as num?)?.toInt(),
        sharesCount: (data['sharesCount'] as num?)?.toInt(),
      );

  final String id;
  final String authorId;
  final String title;
  final String description;
  final List<String> images;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final List<String> tags;
  final String? category;
  final double? budget;
  final int? duration; // в часах
  final int? guests;
  final String? location;
  final bool isPublic;
  final bool isFeatured;
  final Map<String, dynamic> metadata;
  final String? imageUrl;
  final int? guestCount;
  final String? season;
  final String? style;
  final List<String>? colorScheme;
  final String? inspiration;
  final String? createdBy;
  final int? commentsCount;
  final String? mediaUrl;
  final bool? isVideo;
  final double? price;
  final String? priceCurrency;
  final List<String>? requiredSkills;
  final int? likesCount;
  final int? savesCount;
  final int? sharesCount;

  /// Get author photo URL (alias for authorAvatar)
  String? get authorPhotoUrl => authorAvatar;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'title': title,
        'description': description,
        'images': images,
        'createdAt': Timestamp.fromDate(createdAt),
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'views': views,
        'tags': tags,
        'category': category,
        'budget': budget,
        'duration': duration,
        'guests': guests,
        'location': location,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'metadata': metadata,
        'imageUrl': imageUrl,
        'guestCount': guestCount,
        'season': season,
        'style': style,
        'colorScheme': colorScheme,
        'inspiration': inspiration,
        'createdBy': createdBy,
        'commentsCount': commentsCount,
        'mediaUrl': mediaUrl,
        'isVideo': isVideo,
        'price': price,
        'priceCurrency': priceCurrency,
        'requiredSkills': requiredSkills,
        'likesCount': likesCount,
        'savesCount': savesCount,
        'sharesCount': sharesCount,
      };

  /// Создать копию с изменениями
  EventIdea copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    List<String>? images,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatar,
    int? likes,
    int? comments,
    int? shares,
    int? views,
    List<String>? tags,
    String? category,
    double? budget,
    int? duration,
    int? guests,
    String? location,
    bool? isPublic,
    bool? isFeatured,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    int? guestCount,
    String? season,
    String? style,
    List<String>? colorScheme,
    String? inspiration,
    String? createdBy,
    int? commentsCount,
    String? mediaUrl,
    bool? isVideo,
    double? price,
    String? priceCurrency,
    List<String>? requiredSkills,
    int? likesCount,
    int? savesCount,
    int? sharesCount,
  }) =>
      EventIdea(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        title: title ?? this.title,
        description: description ?? this.description,
        images: images ?? this.images,
        createdAt: createdAt ?? this.createdAt,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        views: views ?? this.views,
        tags: tags ?? this.tags,
        category: category ?? this.category,
        budget: budget ?? this.budget,
        duration: duration ?? this.duration,
        guests: guests ?? this.guests,
        location: location ?? this.location,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        metadata: metadata ?? this.metadata,
        imageUrl: imageUrl ?? this.imageUrl,
        guestCount: guestCount ?? this.guestCount,
        season: season ?? this.season,
        style: style ?? this.style,
        colorScheme: colorScheme ?? this.colorScheme,
        inspiration: inspiration ?? this.inspiration,
        createdBy: createdBy ?? this.createdBy,
        commentsCount: commentsCount ?? this.commentsCount,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        isVideo: isVideo ?? this.isVideo,
        price: price ?? this.price,
        priceCurrency: priceCurrency ?? this.priceCurrency,
        requiredSkills: requiredSkills ?? this.requiredSkills,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        sharesCount: sharesCount ?? this.sharesCount,
      );

  /// Проверить, есть ли изображения
  bool get hasImages => images.isNotEmpty;

  /// Получить первое изображение
  String? get firstImage => images.isNotEmpty ? images.first : null;

  /// Получить время в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${(difference.inDays / 7).floor()}н назад';
    }
  }

  /// Получить бюджет в читаемом формате
  String get formattedBudget {
    if (budget == null) return '';

    if (budget! < 1000) {
      return '${budget!.toInt()} ₽';
    } else if (budget! < 1000000) {
      return '${(budget! / 1000).toStringAsFixed(1)}К ₽';
    } else {
      return '${(budget! / 1000000).toStringAsFixed(1)}М ₽';
    }
  }

  /// Получить длительность в читаемом формате
  String get formattedDuration {
    if (duration == null) return '';

    if (duration! < 60) {
      return '${duration!} мин';
    } else {
      final hours = duration! ~/ 60;
      final minutes = duration! % 60;
      if (minutes == 0) {
        return '$hoursч';
      } else {
        return '$hoursч $minutesм';
      }
    }
  }

  /// Получить количество гостей в читаемом формате
  String get formattedGuests {
    if (guests == null) return '';

    if (guests! < 1000) {
      return '${guests!} чел';
    } else {
      return '${(guests! / 1000).toStringAsFixed(1)}К чел';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventIdea(id: $id, title: $title, authorId: $authorId, likes: $likes)';
}

/// Модель для создания идеи
class CreateEventIdea {
  const CreateEventIdea({
    required this.authorId,
    required this.title,
    required this.description,
    this.images = const [],
    this.authorName,
    this.authorAvatar,
    this.tags = const [],
    this.category,
    this.budget,
    this.duration,
    this.guests,
    this.location,
    this.metadata = const {},
  });

  final String authorId;
  final String title;
  final String description;
  final List<String> images;
  final String? authorName;
  final String? authorAvatar;
  final List<String> tags;
  final String? category;
  final double? budget;
  final int? duration;
  final int? guests;
  final String? location;
  final Map<String, dynamic> metadata;

  bool get isValid =>
      authorId.isNotEmpty && title.isNotEmpty && description.isNotEmpty;

  List<String> get validationErrors {
    final errors = <String>[];
    if (authorId.isEmpty) errors.add('ID автора обязателен');
    if (title.isEmpty) errors.add('Заголовок обязателен');
    if (description.isEmpty) errors.add('Описание обязательно');
    return errors;
  }
}

/// Модель комментария к идее
class IdeaComment {
  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.likes = 0,
    this.replies = 0,
    this.parentId,
    this.isPublic = true,
  });

  factory IdeaComment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return IdeaComment(
      id: doc.id,
      ideaId: data['ideaId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorName: data['authorName']?.toString(),
      authorAvatar: data['authorAvatar']?.toString(),
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      replies: (data['replies'] as num?)?.toInt() ?? 0,
      parentId: data['parentId']?.toString(),
      isPublic: data['isPublic'] != false,
    );
  }

  factory IdeaComment.fromMap(Map<String, dynamic> data) => IdeaComment(
        id: data['id']?.toString() ?? '',
        ideaId: data['ideaId']?.toString() ?? '',
        authorId: data['authorId']?.toString() ?? '',
        text: data['text']?.toString() ?? '',
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        authorName: data['authorName']?.toString(),
        authorAvatar: data['authorAvatar']?.toString(),
        likes: (data['likes'] as num?)?.toInt() ?? 0,
        replies: (data['replies'] as num?)?.toInt() ?? 0,
        parentId: data['parentId']?.toString(),
        isPublic: data['isPublic'] != false,
      );

  final String id;
  final String ideaId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;
  final int likes;
  final int replies;
  final String? parentId;
  final bool isPublic;

  Map<String, dynamic> toMap() => {
        'ideaId': ideaId,
        'authorId': authorId,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likes': likes,
        'replies': replies,
        'parentId': parentId,
        'isPublic': isPublic,
      };

  /// Проверить, является ли комментарий ответом
  bool get isReply => parentId != null;

  /// Получить время в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inDays}д назад';
    }
  }
}
