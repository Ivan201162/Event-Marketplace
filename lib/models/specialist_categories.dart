import 'package:flutter/material.dart';

/// Информация о категории специалиста
class SpecialistCategoryInfo {
  const SpecialistCategoryInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    this.isPopular = false,
  });
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final bool isPopular;

  /// Популярные категории
  static const List<SpecialistCategoryInfo> popularCategories = [
    SpecialistCategoryInfo(
      id: 'host',
      name: 'Ведущие',
      emoji: '🎤',
      description: 'Профессиональные ведущие для любых мероприятий',
      color: Color(0xFF2196F3),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'photographer',
      name: 'Фотографы',
      emoji: '📸',
      description: 'Свадебная, портретная и событийная фотография',
      color: Color(0xFF4CAF50),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'dj',
      name: 'Диджеи',
      emoji: '🎧',
      description: 'Музыкальное сопровождение мероприятий',
      color: Color(0xFF9C27B0),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'animator',
      name: 'Аниматоры',
      emoji: '🎭',
      description: 'Развлекательные программы для детей и взрослых',
      color: Color(0xFFFF9800),
      isPopular: true,
    ),
  ];

  /// Все категории специалистов
  static const List<SpecialistCategoryInfo> all = [
    // Популярные категории
    SpecialistCategoryInfo(
      id: 'host',
      name: 'Ведущие',
      emoji: '🎤',
      description: 'Профессиональные ведущие для любых мероприятий',
      color: Color(0xFF2196F3),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'photographer',
      name: 'Фотографы',
      emoji: '📸',
      description: 'Свадебная, портретная и событийная фотография',
      color: Color(0xFF4CAF50),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'dj',
      name: 'Диджеи',
      emoji: '🎧',
      description: 'Музыкальное сопровождение мероприятий',
      color: Color(0xFF9C27B0),
      isPopular: true,
    ),
    SpecialistCategoryInfo(
      id: 'animator',
      name: 'Аниматоры',
      emoji: '🎭',
      description: 'Развлекательные программы для детей и взрослых',
      color: Color(0xFFFF9800),
      isPopular: true,
    ),

    // Дополнительные категории
    SpecialistCategoryInfo(
      id: 'videographer',
      name: 'Видеографы',
      emoji: '🎬',
      description: 'Создание видеороликов и фильмов',
      color: Color(0xFF607D8B),
    ),
    SpecialistCategoryInfo(
      id: 'cover_band',
      name: 'Кавер-группы',
      emoji: '🎸',
      description: 'Живая музыка и кавер-группы',
      color: Color(0xFF795548),
    ),
    SpecialistCategoryInfo(
      id: 'musician',
      name: 'Музыканты',
      emoji: '🎵',
      description: 'Сольные музыканты и инструменталисты',
      color: Color(0xFF3F51B5),
    ),
    SpecialistCategoryInfo(
      id: 'dancer',
      name: 'Танцоры',
      emoji: '💃',
      description: 'Танцевальные номера и шоу',
      color: Color(0xFFE91E63),
    ),
    SpecialistCategoryInfo(
      id: 'content_creator',
      name: 'Контент-мейкеры',
      emoji: '📱',
      description: 'Создание контента для соцсетей',
      color: Color(0xFF00BCD4),
    ),
    SpecialistCategoryInfo(
      id: 'decorator',
      name: 'Оформители/Декораторы',
      emoji: '🎨',
      description: 'Декоративное оформление мероприятий',
      color: Color(0xFFFF5722),
    ),
    SpecialistCategoryInfo(
      id: 'florist',
      name: 'Флористы',
      emoji: '🌸',
      description: 'Цветочное оформление и букеты',
      color: Color(0xFF8BC34A),
    ),
    SpecialistCategoryInfo(
      id: 'catering',
      name: 'Кейтеринг',
      emoji: '🍽️',
      description: 'Организация питания на мероприятиях',
      color: Color(0xFFFFC107),
    ),
    SpecialistCategoryInfo(
      id: 'cleaning',
      name: 'Клининг',
      emoji: '🧹',
      description: 'Уборка до и после мероприятий',
      color: Color(0xFF9E9E9E),
    ),
    SpecialistCategoryInfo(
      id: 'fire_show',
      name: 'Фаер-шоу/Световые шоу/Салюты',
      emoji: '🔥',
      description: 'Огненные и световые представления',
      color: Color(0xFFFF6B35),
    ),
    SpecialistCategoryInfo(
      id: 'equipment_rental',
      name: 'Аренда оборудования',
      emoji: '🔧',
      description: 'Аренда звукового и светового оборудования',
      color: Color(0xFF455A64),
    ),
    SpecialistCategoryInfo(
      id: 'costume_rental',
      name: 'Аренда платьев/Костюмов',
      emoji: '👗',
      description: 'Аренда нарядов для мероприятий',
      color: Color(0xFF673AB7),
    ),
    SpecialistCategoryInfo(
      id: 'venue',
      name: 'Рестораны и площадки',
      emoji: '🏛️',
      description: 'Аренда залов и площадок для мероприятий',
      color: Color(0xFF009688),
    ),
    SpecialistCategoryInfo(
      id: 'event_organizer',
      name: 'Организаторы мероприятий',
      emoji: '📋',
      description: 'Полная организация мероприятий под ключ',
      color: Color(0xFF1976D2),
    ),
    SpecialistCategoryInfo(
      id: 'photo_studio',
      name: 'Фотостудии',
      emoji: '📷',
      description: 'Аренда фотостудий для съемок',
      color: Color(0xFF5D4037),
    ),
    SpecialistCategoryInfo(
      id: 'teambuilding',
      name: 'Тимбилдинг агентства',
      emoji: '🤝',
      description: 'Командные игры и корпоративные мероприятия',
      color: Color(0xFF388E3C),
    ),
  ];

  /// Получить категорию по ID
  static SpecialistCategoryInfo? getById(String id) {
    try {
      return all.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить все категории по популярности
  static List<SpecialistCategoryInfo> getByPopularity(bool isPopular) =>
      all.where((category) => category.isPopular == isPopular).toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistCategoryInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SpecialistCategoryInfo(id: $id, name: $name)';
}
