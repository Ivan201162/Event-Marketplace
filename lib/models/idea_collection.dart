class IdeaCollection {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final List<String> ideaIds;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final int likesCount;
  final int viewsCount;
  final Map<String, dynamic>? metadata;

  const IdeaCollection({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    this.ideaIds = const [],
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isPublic = false,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.metadata,
  });

  factory IdeaCollection.fromMap(Map<String, dynamic> map) {
    return IdeaCollection(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      coverImage: map['coverImage']?.toString(),
      ideaIds: (map['ideaIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      userId: map['userId']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']?.toString() ?? '') 
          : null,
      isPublic: map['isPublic'] as bool? ?? false,
      likesCount: map['likesCount'] as int? ?? 0,
      viewsCount: map['viewsCount'] as int? ?? 0,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'ideaIds': ideaIds,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublic': isPublic,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'metadata': metadata,
    };
  }

  IdeaCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    List<String>? ideaIds,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    int? likesCount,
    int? viewsCount,
    Map<String, dynamic>? metadata,
  }) {
    return IdeaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      ideaIds: ideaIds ?? this.ideaIds,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
