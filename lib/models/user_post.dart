/// Модель поста пользователя с поддержкой видео
class UserPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String text;
  final List<String> media;
  final List<String> tags;
  final String city;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVideo;
  final String? videoUrl;
  final String? thumbnailUrl;

  const UserPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.text,
    required this.media,
    required this.tags,
    required this.city,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    required this.updatedAt,
    this.isVideo = false,
    this.videoUrl,
    this.thumbnailUrl,
  });

  factory UserPost.fromMap(Map<String, dynamic> map, String id) {
    return UserPost(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'],
      text: map['text'] ?? '',
      media: List<String>.from(map['media'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      city: map['city'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isSaved: map['isSaved'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isVideo: map['isVideo'] ?? false,
      videoUrl: map['videoUrl'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'media': media,
      'tags': tags,
      'city': city,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVideo': isVideo,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  UserPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? text,
    List<String>? media,
    List<String>? tags,
    String? city,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVideo,
    String? videoUrl,
    String? thumbnailUrl,
  }) {
    return UserPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      media: media ?? this.media,
      tags: tags ?? this.tags,
      city: city ?? this.city,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVideo: isVideo ?? this.isVideo,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
