import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы бейджей
enum BadgeType {
  // Бейджи для специалистов
  firstBooking, // Первое бронирование
  tenBookings, // 10 успешных заказов
  fiftyBookings, // 50 успешных заказов
  hundredBookings, // 100 успешных заказов
  fiveStarRating, // Рейтинг 5.0
  topRated, // Топ-рейтинг
  quickResponder, // Быстрый ответ
  popularSpecialist, // Популярный специалист
  qualityMaster, // Мастер качества
  customerFavorite, // Любимец клиентов
  // Бейджи для заказчиков
  firstEvent, // Первое мероприятие
  regularCustomer, // Постоянный клиент
  eventOrganizer, // Организатор мероприятий
  reviewWriter, // Активный рецензент
  earlyBird, // Ранняя пташка (бронирование за месяц)
  loyalCustomer, // Лояльный клиент
  socialButterfly, // Социальная бабочка (много мероприятий)
  trendsetter, // Трендсеттер (популярные категории)
  // Общие бейджи
  earlyAdopter, // Ранний пользователь
  communityHelper, // Помощник сообщества
  feedbackProvider, // Поставщик обратной связи
}

/// Модель бейджа
class Badge {
  const Badge({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
    this.isVisible = true,
    this.metadata = const {},
  });

  /// Создаёт бейдж из документа Firestore
  factory Badge.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Badge(
      id: doc.id,
      userId: data['userId'] as String,
      type: BadgeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BadgeType.firstBooking,
      ),
      title: data['title'] as String,
      description: data['description'] as String,
      icon: data['icon'] as String,
      color: data['color'] as String,
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      isVisible: data['isVisible'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }
  final String id;
  final String userId;
  final BadgeType type;
  final String title;
  final String description;
  final String icon;
  final String color;
  final DateTime earnedAt;
  final bool isVisible;
  final Map<String, dynamic> metadata;

  /// Преобразует бейдж в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'description': description,
    'icon': icon,
    'color': color,
    'earnedAt': Timestamp.fromDate(earnedAt),
    'isVisible': isVisible,
    'metadata': metadata,
  };

  /// Создаёт копию бейджа с обновлёнными полями
  Badge copyWith({
    String? id,
    String? userId,
    BadgeType? type,
    String? title,
    String? description,
    String? icon,
    String? color,
    DateTime? earnedAt,
    bool? isVisible,
    Map<String, dynamic>? metadata,
  }) => Badge(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    earnedAt: earnedAt ?? this.earnedAt,
    isVisible: isVisible ?? this.isVisible,
    metadata: metadata ?? this.metadata,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Badge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Badge(id: $id, type: $type, title: $title)';
}

/// Расширение для BadgeType
extension BadgeTypeExtension on BadgeType {
  /// Получает информацию о бейдже
  BadgeInfo get info {
    switch (this) {
      // Бейджи для специалистов
      case BadgeType.firstBooking:
        return const BadgeInfo(
          title: 'Первое бронирование',
          description: 'Получили первое бронирование',
          icon: '🎯',
          color: '#4CAF50',
          category: BadgeCategory.specialist,
        );
      case BadgeType.tenBookings:
        return const BadgeInfo(
          title: '10 успешных заказов',
          description: 'Выполнили 10 успешных заказов',
          icon: '⭐',
          color: '#FFD700',
          category: BadgeCategory.specialist,
        );
      case BadgeType.fiftyBookings:
        return const BadgeInfo(
          title: '50 успешных заказов',
          description: 'Выполнили 50 успешных заказов',
          icon: '🏆',
          color: '#FF9800',
          category: BadgeCategory.specialist,
        );
      case BadgeType.hundredBookings:
        return const BadgeInfo(
          title: '100 успешных заказов',
          description: 'Выполнили 100 успешных заказов',
          icon: '👑',
          color: '#9C27B0',
          category: BadgeCategory.specialist,
        );
      case BadgeType.fiveStarRating:
        return const BadgeInfo(
          title: 'Идеальный рейтинг',
          description: 'Поддерживаете рейтинг 5.0',
          icon: '✨',
          color: '#E91E63',
          category: BadgeCategory.specialist,
        );
      case BadgeType.topRated:
        return const BadgeInfo(
          title: 'Топ-рейтинг',
          description: 'Входите в топ-10 специалистов',
          icon: '🥇',
          color: '#FF5722',
          category: BadgeCategory.specialist,
        );
      case BadgeType.quickResponder:
        return const BadgeInfo(
          title: 'Быстрый ответ',
          description: 'Отвечаете на сообщения в течение часа',
          icon: '⚡',
          color: '#00BCD4',
          category: BadgeCategory.specialist,
        );
      case BadgeType.popularSpecialist:
        return const BadgeInfo(
          title: 'Популярный специалист',
          description: 'Популярны среди клиентов',
          icon: '🔥',
          color: '#F44336',
          category: BadgeCategory.specialist,
        );
      case BadgeType.qualityMaster:
        return const BadgeInfo(
          title: 'Мастер качества',
          description: 'Всегда получаете отличные отзывы',
          icon: '🎨',
          color: '#3F51B5',
          category: BadgeCategory.specialist,
        );
      case BadgeType.customerFavorite:
        return const BadgeInfo(
          title: 'Любимец клиентов',
          description: 'Клиенты часто возвращаются к вам',
          icon: '💖',
          color: '#E91E63',
          category: BadgeCategory.specialist,
        );

      // Бейджи для заказчиков
      case BadgeType.firstEvent:
        return const BadgeInfo(
          title: 'Первое мероприятие',
          description: 'Организовали первое мероприятие',
          icon: '🎉',
          color: '#4CAF50',
          category: BadgeCategory.customer,
        );
      case BadgeType.regularCustomer:
        return const BadgeInfo(
          title: 'Постоянный клиент',
          description: 'Регулярно пользуетесь услугами',
          icon: '🔄',
          color: '#2196F3',
          category: BadgeCategory.customer,
        );
      case BadgeType.eventOrganizer:
        return const BadgeInfo(
          title: 'Организатор мероприятий',
          description: 'Организовали 5+ мероприятий',
          icon: '📅',
          color: '#FF9800',
          category: BadgeCategory.customer,
        );
      case BadgeType.reviewWriter:
        return const BadgeInfo(
          title: 'Активный рецензент',
          description: 'Оставляете отзывы после каждого заказа',
          icon: '✍️',
          color: '#9C27B0',
          category: BadgeCategory.customer,
        );
      case BadgeType.earlyBird:
        return const BadgeInfo(
          title: 'Ранняя пташка',
          description: 'Бронируете услуги заранее',
          icon: '🐦',
          color: '#00BCD4',
          category: BadgeCategory.customer,
        );
      case BadgeType.loyalCustomer:
        return const BadgeInfo(
          title: 'Лояльный клиент',
          description: 'Пользуетесь услугами более года',
          icon: '💎',
          color: '#607D8B',
          category: BadgeCategory.customer,
        );
      case BadgeType.socialButterfly:
        return const BadgeInfo(
          title: 'Социальная бабочка',
          description: 'Организуете много мероприятий',
          icon: '🦋',
          color: '#E91E63',
          category: BadgeCategory.customer,
        );
      case BadgeType.trendsetter:
        return const BadgeInfo(
          title: 'Трендсеттер',
          description: 'Выбираете популярные категории',
          icon: '📈',
          color: '#4CAF50',
          category: BadgeCategory.customer,
        );

      // Общие бейджи
      case BadgeType.earlyAdopter:
        return const BadgeInfo(
          title: 'Ранний пользователь',
          description: 'Одни из первых пользователей приложения',
          icon: '🚀',
          color: '#FF5722',
          category: BadgeCategory.general,
        );
      case BadgeType.communityHelper:
        return const BadgeInfo(
          title: 'Помощник сообщества',
          description: 'Помогаете другим пользователям',
          icon: '🤝',
          color: '#4CAF50',
          category: BadgeCategory.general,
        );
      case BadgeType.feedbackProvider:
        return const BadgeInfo(
          title: 'Поставщик обратной связи',
          description: 'Активно участвуете в улучшении приложения',
          icon: '💡',
          color: '#FF9800',
          category: BadgeCategory.general,
        );
    }
  }
}

/// Информация о бейдже
class BadgeInfo {
  const BadgeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
  final String title;
  final String description;
  final String icon;
  final String color;
  final BadgeCategory category;
}

/// Категории бейджей
enum BadgeCategory { specialist, customer, general }

/// Статистика бейджей пользователя
class BadgeStats {
  const BadgeStats({
    required this.totalBadges,
    required this.earnedBadges,
    required this.availableBadges,
    required this.recentBadges,
    required this.badgesByCategory,
    this.specialistBadges = 0,
    this.customerBadges = 0,
    this.generalBadges = 0,
  });

  final int totalBadges;
  final int earnedBadges;
  final int availableBadges;
  final List<Badge> recentBadges;
  final Map<BadgeCategory, int> badgesByCategory;
  final int specialistBadges;
  final int customerBadges;
  final int generalBadges;

  static const BadgeStats empty = BadgeStats(
    totalBadges: 0,
    earnedBadges: 0,
    availableBadges: 0,
    recentBadges: [],
    badgesByCategory: {},
  );
}

/// Запись в таблице лидеров по бейджам
class BadgeLeaderboardEntry {
  const BadgeLeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.badgeCount,
    required this.rank,
    required this.recentBadges,
  });

  final String userId;
  final String userName;
  final String? userAvatar;
  final int badgeCount;
  final int rank;
  final List<Badge> recentBadges;
}

/// Расширение для работы с бейджами
extension BadgeListExtension on List<Badge> {
  /// Получает бейджи по категории
  List<Badge> byCategory(BadgeCategory category) =>
      where((badge) => badge.type.info.category == category).toList();

  /// Получает последние бейджи
  List<Badge> get recent => toList()..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));

  /// Получает видимые бейджи
  List<Badge> get visible => where((badge) => badge.isVisible).toList();

  /// Группирует бейджи по категориям
  Map<BadgeCategory, List<Badge>> get groupedByCategory {
    final grouped = <BadgeCategory, List<Badge>>{};
    for (final badge in this) {
      final category = badge.type.info.category;
      grouped.putIfAbsent(category, () => []).add(badge);
    }
    return grouped;
  }
}
