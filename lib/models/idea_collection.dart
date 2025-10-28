import 'package:equatable/equatable.dart';

/// Model for idea collections
class IdeaCollection extends Equatable {

  const IdeaCollection({
    required this.id,
    required this.name,
    required this.ideaIds, required this.authorId, required this.authorName, required this.createdAt, required this.updatedAt, this.description,
    this.imageUrl,
    this.isPublic = true,
    this.likesCount = 0,
    this.viewsCount = 0,
  });

  factory IdeaCollection.fromMap(Map<String, dynamic> map) {
    return IdeaCollection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      ideaIds: List<String>.from(map['ideaIds'] ?? []),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      isPublic: map['isPublic'] ?? true,
      likesCount: map['likesCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> ideaIds;
  final String authorId;
  final String authorName;
  final bool isPublic;
  final int likesCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ideaIds': ideaIds,
      'authorId': authorId,
      'authorName': authorName,
      'isPublic': isPublic,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  IdeaCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? ideaIds,
    String? authorId,
    String? authorName,
    bool? isPublic,
    int? likesCount,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdeaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ideaIds: ideaIds ?? this.ideaIds,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        ideaIds,
        authorId,
        authorName,
        isPublic,
        likesCount,
        viewsCount,
        createdAt,
        updatedAt,
      ];
}
