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

  // Статические значения категорий
  static const List<EventIdeaCategory> values = [
    EventIdeaCategory(
      id: 'wedding',
      name: 'Свадьба',
      emoji: '💒',
      description: 'Свадебные мероприятия',
      color: '#FF69B4',
    ),
    EventIdeaCategory(
      id: 'corporate',
      name: 'Корпоратив',
      emoji: '🏢',
      description: 'Корпоративные мероприятия',
      color: '#4169E1',
    ),
    EventIdeaCategory(
      id: 'birthday',
      name: 'День рождения',
      emoji: '🎂',
      description: 'Дни рождения',
      color: '#FFD700',
    ),
    EventIdeaCategory(
      id: 'anniversary',
      name: 'Юбилей',
      emoji: '🎉',
      description: 'Юбилейные мероприятия',
      color: '#FF6347',
    ),
    EventIdeaCategory(
      id: 'graduation',
      name: 'Выпускной',
      emoji: '🎓',
      description: 'Выпускные мероприятия',
      color: '#32CD32',
    ),
    EventIdeaCategory(
      id: 'conference',
      name: 'Конференция',
      emoji: '📊',
      description: 'Конференции и семинары',
      color: '#9370DB',
    ),
    EventIdeaCategory(
      id: 'exhibition',
      name: 'Выставка',
      emoji: '🎨',
      description: 'Выставки и экспозиции',
      color: '#FF8C00',
    ),
    EventIdeaCategory(
      id: 'festival',
      name: 'Фестиваль',
      emoji: '🎪',
      description: 'Фестивали и праздники',
      color: '#FF1493',
    ),
    EventIdeaCategory(
      id: 'sports',
      name: 'Спорт',
      emoji: '⚽',
      description: 'Спортивные мероприятия',
      color: '#00CED1',
    ),
    EventIdeaCategory(
      id: 'charity',
      name: 'Благотворительность',
      emoji: '❤️',
      description: 'Благотворительные мероприятия',
      color: '#DC143C',
    ),
  ];

  /// Создать из Map
  factory EventIdeaCategory.fromMap(Map<String, dynamic> data) => EventIdeaCategory(
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
