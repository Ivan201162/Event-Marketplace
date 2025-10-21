import 'package:flutter/material.dart';

enum EventIdeaCategory {
  photography('photography', 'Фотография', 'Фотосессии и портреты', 0xFF6366F1, '📸'),
  videography('videography', 'Видеосъёмка', 'Видеоролики и клипы', 0xFF8B5CF6, '🎥'),
  music('music', 'Музыка', 'Музыкальные выступления', 0xFFEC4899, '🎵'),
  dance('dance', 'Танцы', 'Танцевальные номера', 0xFFF59E0B, '💃'),
  art('art', 'Искусство', 'Художественные работы', 0xFF10B981, '🎨'),
  design('design', 'Дизайн', 'Графический и веб-дизайн', 0xFF3B82F6, '🎨'),
  fashion('fashion', 'Мода', 'Модные показы и стилизация', 0xFFEF4444, '👗'),
  food('food', 'Кулинария', 'Кулинарные мастер-классы', 0xFFF97316, '🍳'),
  sports('sports', 'Спорт', 'Спортивные мероприятия', 0xFF84CC16, '⚽'),
  education('education', 'Образование', 'Образовательные мероприятия', 0xFF06B6D4, '📚'),
  technology('technology', 'Технологии', 'IT и технологические события', 0xFF6366F1, '💻'),
  business('business', 'Бизнес', 'Деловые мероприятия', 0xFF6B7280, '💼'),
  health('health', 'Здоровье', 'Медицинские и оздоровительные события', 0xFF10B981, '🏥'),
  entertainment('entertainment', 'Развлечения', 'Развлекательные мероприятия', 0xFFEC4899, '🎪'),
  other('other', 'Другое', 'Прочие мероприятия', 0xFF9CA3AF, '📋');

  const EventIdeaCategory(this.id, this.name, this.description, this.color, this.icon);

  final String id;
  final String name;
  final String description;
  final Color color;
  final String icon;

  factory EventIdeaCategory.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    return EventIdeaCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => EventIdeaCategory.other,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'color': color.value, 'icon': icon};
  }

  String get displayName => name;
  String get emoji => icon;
}
