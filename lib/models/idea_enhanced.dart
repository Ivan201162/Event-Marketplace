import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Типы идей
enum IdeaType {
  text('text', 'Текст'),
  image('image', 'Изображение'),
  video('video', 'Видео'),
  audio('audio', 'Аудио'),
  link('link', 'Ссылка'),
  poll('poll', 'Опрос'),
  event('event', 'Событие'),
  project('project', 'Проект');

  const IdeaType(this.value, this.label);
  final String value;
  final String label;
}

/// Статусы идей
enum IdeaStatus {
  draft('draft', 'Черновик'),
  published('published', 'Опубликовано'),
  featured('featured', 'Рекомендуемое'),
  trending('trending', 'Тренд'),
  archived('archived', 'Архив');

  const IdeaStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Приватность идей
enum IdeaPrivacy {
  public('public', 'Публичная'),
  friends('friends', 'Друзья'),
  private('private', 'Приватная');

  const IdeaPrivacy(this.value, this.label);
  final String value;
  final String label;
}

/// Расширенная модель идеи
class IdeaEnhanced extends Equatable {

  const IdeaEnhanced({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    required this.status,
    required this.privacy,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.attachments,
    required this.tags,
    required this.categories,
    required this.mentions,
    required this.hashtags,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.views, required this.likes, required this.comments, required this.shares, required this.bookmarks, required this.rating, required this.isVerified, required this.isPinned, required this.isFeatured, required this.isTrending, required this.collaborators, required this.followers, required this.analytics, required this.aiRecommendations, required this.commentsList, required this.reactions, required this.pollData, required this.childIdeas, required this.location, required this.sharedWith, required this.monetization, this.publishedAt,
    this.originalIdeaId,
    this.parentIdeaId,
    this.language,
  });

  /// Создание из Firestore документа
  factory IdeaEnhanced.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return IdeaEnhanced(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      type: IdeaType.values.firstWhere(
        (e) => e.value == data['type'],
        orElse: () => IdeaType.text,
      ),
      status: IdeaStatus.values.firstWhere(
        (e) => e.value == data['status'],
        orElse: () => IdeaStatus.published,
      ),
      privacy: IdeaPrivacy.values.firstWhere(
        (e) => e.value == data['privacy'],
        orElse: () => IdeaPrivacy.public,
      ),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      bookmarks: data['bookmarks'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      isPinned: data['isPinned'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isTrending: data['isTrending'] ?? false,
      collaborators: List<String>.from(data['collaborators'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
      aiRecommendations:
          Map<String, dynamic>.from(data['aiRecommendations'] ?? {}),
      commentsList: (data['commentsList'] as List<dynamic>?)
              ?.map((e) => IdeaComment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      reactions: (data['reactions'] as List<dynamic>?)
              ?.map((e) => IdeaReaction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      pollData: Map<String, dynamic>.from(data['pollData'] ?? {}),
      originalIdeaId: data['originalIdeaId'],
      parentIdeaId: data['parentIdeaId'],
      childIdeas: List<String>.from(data['childIdeas'] ?? []),
      location: Map<String, dynamic>.from(data['location'] ?? {}),
      language: data['language'],
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      monetization: Map<String, dynamic>.from(data['monetization'] ?? {}),
    );
  }
  final String id;
  final String title;
  final String description;
  final String content;
  final IdeaType type;
  final IdeaStatus status;
  final IdeaPrivacy privacy;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final List<String> attachments;
  final List<String> tags;
  final List<String> categories;
  final List<String> mentions;
  final List<String> hashtags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final double rating;
  final bool isVerified;
  final bool isPinned;
  final bool isFeatured;
  final bool isTrending;
  final List<String> collaborators;
  final List<String> followers;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> aiRecommendations;
  final List<IdeaComment> commentsList;
  final List<IdeaReaction> reactions;
  final Map<String, dynamic> pollData;
  final String? originalIdeaId;
  final String? parentIdeaId;
  final List<String> childIdeas;
  final Map<String, dynamic> location;
  final String? language;
  final List<String> sharedWith;
  final Map<String, dynamic> monetization;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'type': type.value,
      'status': status.value,
      'privacy': privacy.value,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'attachments': attachments,
      'tags': tags,
      'categories': categories,
      'mentions': mentions,
      'hashtags': hashtags,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt':
          publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'bookmarks': bookmarks,
      'rating': rating,
      'isVerified': isVerified,
      'isPinned': isPinned,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'collaborators': collaborators,
      'followers': followers,
      'analytics': analytics,
      'aiRecommendations': aiRecommendations,
      'commentsList': commentsList.map((e) => e.toMap()).toList(),
      'reactions': reactions.map((e) => e.toMap()).toList(),
      'pollData': pollData,
      'originalIdeaId': originalIdeaId,
      'parentIdeaId': parentIdeaId,
      'childIdeas': childIdeas,
      'location': location,
      'language': language,
      'sharedWith': sharedWith,
      'monetization': monetization,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        content,
        type,
        status,
        privacy,
        authorId,
        authorName,
        authorAvatar,
        attachments,
        tags,
        categories,
        mentions,
        hashtags,
        metadata,
        createdAt,
        updatedAt,
        publishedAt,
        views,
        likes,
        comments,
        shares,
        bookmarks,
        rating,
        isVerified,
        isPinned,
        isFeatured,
        isTrending,
        collaborators,
        followers,
        analytics,
        aiRecommendations,
        commentsList,
        reactions,
        pollData,
        originalIdeaId,
        parentIdeaId,
        childIdeas,
        location,
        language,
        sharedWith,
        monetization,
      ];
}

/// Комментарий к идее
class IdeaComment extends Equatable {

  const IdeaComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.likes, required this.replies, required this.metadata, this.editedAt,
    this.parentCommentId,
  });

  factory IdeaComment.fromMap(Map<String, dynamic> map) {
    return IdeaComment(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      replies: (map['replies'] as List<dynamic>?)
              ?.map((e) => IdeaComment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      parentCommentId: map['parentCommentId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final List<String> likes;
  final List<IdeaComment> replies;
  final String? parentCommentId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'likes': likes,
      'replies': replies.map((e) => e.toMap()).toList(),
      'parentCommentId': parentCommentId,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        content,
        createdAt,
        editedAt,
        likes,
        replies,
        parentCommentId,
        metadata,
      ];
}

/// Реакция на идею
class IdeaReaction extends Equatable {

  const IdeaReaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.createdAt,
  });

  factory IdeaReaction.fromMap(Map<String, dynamic> map) {
    return IdeaReaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      emoji: map['emoji'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, userName, emoji, createdAt];
}

/// Фильтры для идей
class IdeaFilters extends Equatable {

  const IdeaFilters({
    this.type,
    this.status,
    this.privacy,
    this.authorId,
    this.categories,
    this.tags,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.minRating,
    this.maxRating,
    this.isVerified,
    this.isFeatured,
    this.isTrending,
    this.language,
    this.location,
    this.radius,
  });
  final IdeaType? type;
  final IdeaStatus? status;
  final IdeaPrivacy? privacy;
  final String? authorId;
  final List<String>? categories;
  final List<String>? tags;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minRating;
  final double? maxRating;
  final bool? isVerified;
  final bool? isFeatured;
  final bool? isTrending;
  final String? language;
  final Map<String, dynamic>? location;
  final double? radius;

  @override
  List<Object?> get props => [
        type,
        status,
        privacy,
        authorId,
        categories,
        tags,
        searchQuery,
        startDate,
        endDate,
        minRating,
        maxRating,
        isVerified,
        isFeatured,
        isTrending,
        language,
        location,
        radius,
      ];
}
