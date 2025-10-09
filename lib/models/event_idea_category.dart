/// Категория идеи мероприятия
class EventIdeaCategory {
  const EventIdeaCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    this.color,
    this.isActive = true,
  });

  /// Создать из Map
  factory EventIdeaCategory.fromMap(Map<String, dynamic> data) =>
      EventIdeaCategory(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        emoji: data['emoji']?.toString() ?? '',
        description: data['description']?.toString(),
        color: data['color']?.toString(),
        isActive: data['isActive'] != false,
      );

  final String id;
  final String name;
  final String emoji;
  final String? description;
  final String? color;
  final bool isActive;

  /// Отображаемое имя
  String get displayName => name;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'color': color,
        'isActive': isActive,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventIdeaCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EventIdeaCategory(id: $id, name: $name, emoji: $emoji)';
}
