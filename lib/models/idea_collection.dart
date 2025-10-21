import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Idea collection model
class IdeaCollection extends Equatable {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final List<String> ideaIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final bool isPublic;
  final List<String> tags;
  final String? coverImageUrl;

  const IdeaCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.ideaIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.isPublic = true,
    this.tags = const [],
    this.coverImageUrl,
  });

  /// Create IdeaCollection from Firestore document
  factory IdeaCollection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IdeaCollection(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatarUrl: data['authorAvatarUrl'],
      ideaIds: List<String>.from(data['ideaIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isPublic: data['isPublic'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      coverImageUrl: data['coverImageUrl'],
    );
  }

  /// Convert IdeaCollection to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'ideaIds': ideaIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
      'isPublic': isPublic,
      'tags': tags,
      'coverImageUrl': coverImageUrl,
    };
  }

  /// Create a copy with updated fields
  IdeaCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    List<String>? ideaIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    bool? isPublic,
    List<String>? tags,
    String? coverImageUrl,
  }) {
    return IdeaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      ideaIds: ideaIds ?? this.ideaIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  /// Check if collection is liked by user
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        authorId,
        authorName,
        authorAvatarUrl,
        ideaIds,
        createdAt,
        updatedAt,
        likesCount,
        likedBy,
        isPublic,
        tags,
        coverImageUrl,
      ];

  @override
  String toString() {
    return 'IdeaCollection(id: $id, name: $name, authorId: $authorId)';
  }
}
