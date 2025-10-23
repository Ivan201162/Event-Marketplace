/// Статистика профиля специалиста
class ProfileStatistics {
  const ProfileStatistics({
    required this.views,
    required this.likes,
    required this.rating,
    required this.reviewsCount,
    required this.averagePrice,
    required this.completedOrders,
    required this.responseTime,
    required this.onlineStatus,
    this.lastActive,
    required this.portfolioItems,
    required this.socialLinks,
    required this.pinnedPosts,
  });

  /// Создать из Map
  factory ProfileStatistics.fromMap(Map<String, dynamic> map) =>
      ProfileStatistics(
        views: (map['views'] as int?) ?? 0,
        likes: (map['likes'] as int?) ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: (map['reviewsCount'] as int?) ?? 0,
        averagePrice: (map['averagePrice'] as num?)?.toDouble() ?? 0.0,
        completedOrders: (map['completedOrders'] as int?) ?? 0,
        responseTime: (map['responseTime'] as num?)?.toDouble() ?? 0.0,
        onlineStatus: (map['onlineStatus'] as bool?) ?? false,
        lastActive: map['lastActive'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'] as int)
            : DateTime.now(),
        portfolioItems: (map['portfolioItems'] as int?) ?? 0,
        socialLinks: (map['socialLinks'] as int?) ?? 0,
        pinnedPosts: (map['pinnedPosts'] as int?) ?? 0,
      );

  /// Количество просмотров профиля
  final int views;

  /// Количество лайков
  final int likes;

  /// Средний рейтинг
  final double rating;

  /// Количество отзывов
  final int reviewsCount;

  /// Средняя цена услуг
  final double averagePrice;

  /// Количество выполненных заказов
  final int completedOrders;

  /// Время ответа в часах
  final double responseTime;

  /// Статус онлайн
  final bool onlineStatus;

  /// Последняя активность
  final DateTime? lastActive;

  /// Количество элементов портфолио
  final int portfolioItems;

  /// Количество социальных ссылок
  final int socialLinks;

  /// Количество закреплённых постов
  final int pinnedPosts;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'views': views,
        'likes': likes,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'averagePrice': averagePrice,
        'completedOrders': completedOrders,
        'responseTime': responseTime,
        'onlineStatus': onlineStatus,
        if (lastActive != null)
          'lastActive': lastActive!.millisecondsSinceEpoch,
        'portfolioItems': portfolioItems,
        'socialLinks': socialLinks,
        'pinnedPosts': pinnedPosts,
      };

  /// Создать копию с изменениями
  ProfileStatistics copyWith({
    int? views,
    int? likes,
    double? rating,
    int? reviewsCount,
    double? averagePrice,
    int? completedOrders,
    double? responseTime,
    bool? onlineStatus,
    DateTime? lastActive,
    int? portfolioItems,
    int? socialLinks,
    int? pinnedPosts,
  }) =>
      ProfileStatistics(
        views: views ?? this.views,
        likes: likes ?? this.likes,
        rating: rating ?? this.rating,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        averagePrice: averagePrice ?? this.averagePrice,
        completedOrders: completedOrders ?? this.completedOrders,
        responseTime: responseTime ?? this.responseTime,
        onlineStatus: onlineStatus ?? this.onlineStatus,
        lastActive: lastActive ?? this.lastActive,
        portfolioItems: portfolioItems ?? this.portfolioItems,
        socialLinks: socialLinks ?? this.socialLinks,
        pinnedPosts: pinnedPosts ?? this.pinnedPosts,
      );
}
