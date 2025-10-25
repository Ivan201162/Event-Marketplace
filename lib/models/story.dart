/// Модель истории
class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String text;
  final List<String> media;
  final bool isViewed;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.text,
    required this.media,
    required this.isViewed,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Story.fromMap(Map<String, dynamic> map, String id) {
    return Story(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'],
      text: map['text'] ?? '',
      media: List<String>.from(map['media'] ?? []),
      isViewed: map['isViewed'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(map['expiresAt'] ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'media': media,
      'isViewed': isViewed,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  Story copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? text,
    List<String>? media,
    bool? isViewed,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Story(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      media: media ?? this.media,
      isViewed: isViewed ?? this.isViewed,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}