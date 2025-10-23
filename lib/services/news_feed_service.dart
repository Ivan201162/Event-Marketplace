import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для управления лентой новостей
class NewsFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить ленту новостей
  Future<List<NewsItem>> getNewsFeed({
    String? userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('news_items')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final newsItems = snapshot.docs.map(NewsItem.fromDocument).toList();

      // Если указан пользователь, фильтруем по подпискам
      if (userId != null) {
        final subscriptions = await _getUserSubscriptions(userId);
        return newsItems
            .where((item) =>
                item.isPublic || subscriptions.contains(item.authorId))
            .toList();
      }

      return newsItems;
    } on Exception catch (e) {
      debugPrint('Ошибка получения ленты новостей: $e');
      return [];
    }
  }

  /// Получить новости специалиста
  Future<List<NewsItem>> getSpecialistNews({
    required String specialistId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('news_items')
          .where('authorId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(NewsItem.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения новостей специалиста: $e');
      return [];
    }
  }

  /// Создать новость
  Future<NewsItem> createNewsItem({
    required String authorId,
    required String authorName,
    required NewsType type,
    required String title,
    required String content,
    String? imageUrl,
    String? linkUrl,
    Map<String, dynamic>? metadata,
    bool isPublic = true,
  }) async {
    try {
      final newsItem = NewsItem(
        id: '', // Будет сгенерирован Firestore
        authorId: authorId,
        authorName: authorName,
        type: type,
        title: title,
        content: content,
        imageUrl: imageUrl,
        linkUrl: linkUrl,
        metadata: metadata ?? {},
        isPublic: isPublic,
        likes: 0,
        shares: 0,
        views: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('news_items').add(newsItem.toMap());

      return newsItem.copyWith(id: docRef.id);
    } on Exception catch (e) {
      debugPrint('Ошибка создания новости: $e');
      rethrow;
    }
  }

  /// Обновить новость
  Future<void> updateNewsItem({
    required String newsItemId,
    String? title,
    String? content,
    String? imageUrl,
    String? linkUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (linkUrl != null) updateData['linkUrl'] = linkUrl;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore
          .collection('news_items')
          .doc(newsItemId)
          .update(updateData);
    } on Exception catch (e) {
      debugPrint('Ошибка обновления новости: $e');
      rethrow;
    }
  }

  /// Удалить новость
  Future<void> deleteNewsItem(String newsItemId) async {
    try {
      await _firestore.collection('news_items').doc(newsItemId).delete();
    } on Exception catch (e) {
      debugPrint('Ошибка удаления новости: $e');
      rethrow;
    }
  }

  /// Лайкнуть новость
  Future<void> likeNewsItem(String newsItemId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Добавляем лайк в коллекцию лайков
      batch.set(
          _firestore.collection('news_likes').doc('${newsItemId}_$userId'), {
        'newsItemId': newsItemId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Увеличиваем счетчик лайков
      batch.update(_firestore.collection('news_items').doc(newsItemId), {
        'likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('Ошибка лайка новости: $e');
      rethrow;
    }
  }

  /// Убрать лайк с новости
  Future<void> unlikeNewsItem(String newsItemId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Удаляем лайк из коллекции лайков
      batch.delete(
          _firestore.collection('news_likes').doc('${newsItemId}_$userId'));

      // Уменьшаем счетчик лайков
      batch.update(_firestore.collection('news_items').doc(newsItemId), {
        'likes': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('Ошибка удаления лайка: $e');
      rethrow;
    }
  }

  /// Поделиться новостью
  Future<void> shareNewsItem(String newsItemId) async {
    try {
      await _firestore.collection('news_items').doc(newsItemId).update({
        'shares': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка шаринга новости: $e');
      rethrow;
    }
  }

  /// Отметить новость как просмотренную
  Future<void> markAsViewed(String newsItemId, String userId) async {
    try {
      await _firestore
          .collection('news_views')
          .doc('${newsItemId}_$userId')
          .set({
        'newsItemId': newsItemId,
        'userId': userId,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      // Увеличиваем счетчик просмотров
      await _firestore.collection('news_items').doc(newsItemId).update({
        'views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отметки просмотра: $e');
    }
  }

  /// Подписаться на специалиста
  Future<void> subscribeToSpecialist(String userId, String specialistId) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc('${userId}_$specialistId')
          .set({
        'userId': userId,
        'specialistId': specialistId,
        'subscribedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка подписки на специалиста: $e');
      rethrow;
    }
  }

  /// Отписаться от специалиста
  Future<void> unsubscribeFromSpecialist(
      String userId, String specialistId) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc('${userId}_$specialistId')
          .delete();
    } on Exception catch (e) {
      debugPrint('Ошибка отписки от специалиста: $e');
      rethrow;
    }
  }

  /// Получить подписки пользователя
  Future<List<String>> _getUserSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['specialistId'] as String)
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения подписок: $e');
      return [];
    }
  }

  /// Получить подписки пользователя
  Future<List<String>> getUserSubscriptions(String userId) async =>
      _getUserSubscriptions(userId);

  /// Проверить, подписан ли пользователь на специалиста
  Future<bool> isSubscribed(String userId, String specialistId) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc('${userId}_$specialistId')
          .get();

      return doc.exists;
    } on Exception catch (e) {
      debugPrint('Ошибка проверки подписки: $e');
      return false;
    }
  }

  /// Получить статистику новостей
  Future<NewsStats> getNewsStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('news_items')
          .where('authorId', isEqualTo: specialistId)
          .get();

      final newsItems = snapshot.docs.map(NewsItem.fromDocument).toList();

      final totalNews = newsItems.length;
      final totalLikes =
          newsItems.fold<int>(0, (sum, item) => sum + item.likes);
      final totalShares =
          newsItems.fold<int>(0, (sum, item) => sum + item.shares);
      final totalViews =
          newsItems.fold<int>(0, (sum, item) => sum + item.views);

      // Получаем количество подписчиков
      final subscribersSnapshot = await _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final subscribersCount = subscribersSnapshot.docs.length;

      return NewsStats(
        specialistId: specialistId,
        totalNews: totalNews,
        totalLikes: totalLikes,
        totalShares: totalShares,
        totalViews: totalViews,
        subscribersCount: subscribersCount,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики новостей: $e');
      return NewsStats.empty();
    }
  }

  /// Создать тестовые новости
  Future<void> createTestNews() async {
    try {
      final testNews = [
        {
          'authorId': 'test_specialist_1',
          'authorName': 'Анна Фотограф',
          'type': NewsType.idea,
          'title': 'Новые идеи для свадебной фотосессии',
          'content':
              'Представляю вам новые креативные идеи для свадебной фотосессии. Включают в себя необычные ракурсы, игры со светом и современные тренды.',
          'imageUrl': 'https://example.com/wedding_photo.jpg',
          'isPublic': true,
        },
        {
          'authorId': 'test_specialist_2',
          'authorName': 'Михаил DJ',
          'type': NewsType.promotion,
          'title': 'Скидка 20% на диджейские услуги',
          'content':
              'Специальное предложение! Скидка 20% на все диджейские услуги при заказе до конца месяца. Успейте забронировать!',
          'isPublic': true,
        },
        {
          'authorId': 'test_specialist_3',
          'authorName': 'Елена Декоратор',
          'type': NewsType.story,
          'title': 'История успеха: Свадьба в стиле "Винтаж"',
          'content':
              'Рассказываю о том, как мы создали незабываемую свадьбу в винтажном стиле. Много интересных деталей и секретов декора.',
          'imageUrl': 'https://example.com/vintage_wedding.jpg',
          'isPublic': true,
        },
      ];

      for (final newsData in testNews) {
        await createNewsItem(
          authorId: newsData['authorId']! as String,
          authorName: newsData['authorName']! as String,
          type: newsData['type']! as NewsType,
          title: newsData['title']! as String,
          content: newsData['content']! as String,
          imageUrl: newsData['imageUrl'] as String?,
          isPublic: newsData['isPublic']! as bool,
        );
      }
    } on Exception catch (e) {
      debugPrint('Ошибка создания тестовых новостей: $e');
    }
  }
}

/// Тип новости
enum NewsType { idea, story, promotion, announcement, tip }

/// Модель новости
class NewsItem {
  const NewsItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
    this.linkUrl,
    this.metadata = const {},
    required this.isPublic,
    required this.likes,
    required this.shares,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return NewsItem(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      type: NewsType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => NewsType.idea,
      ),
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      linkUrl: data['linkUrl'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      isPublic: data['isPublic'] as bool? ?? true,
      likes: data['likes'] as int? ?? 0,
      shares: data['shares'] as int? ?? 0,
      views: data['views'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final NewsType type;
  final String title;
  final String content;
  final String? imageUrl;
  final String? linkUrl;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final int likes;
  final int shares;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsItem copyWith({
    String? id,
    String? authorId,
    String? authorName,
    NewsType? type,
    String? title,
    String? content,
    String? imageUrl,
    String? linkUrl,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    int? likes,
    int? shares,
    int? views,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      NewsItem(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        type: type ?? this.type,
        title: title ?? this.title,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        linkUrl: linkUrl ?? this.linkUrl,
        metadata: metadata ?? this.metadata,
        isPublic: isPublic ?? this.isPublic,
        likes: likes ?? this.likes,
        shares: shares ?? this.shares,
        views: views ?? this.views,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'type': type.name,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'metadata': metadata,
        'isPublic': isPublic,
        'likes': likes,
        'shares': shares,
        'views': views,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  String get typeDisplayName {
    switch (type) {
      case NewsType.idea:
        return 'Идея';
      case NewsType.story:
        return 'История';
      case NewsType.promotion:
        return 'Акция';
      case NewsType.announcement:
        return 'Объявление';
      case NewsType.tip:
        return 'Совет';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}

/// Статистика новостей
class NewsStats {
  const NewsStats({
    required this.specialistId,
    required this.totalNews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalViews,
    required this.subscribersCount,
    required this.lastUpdated,
  });

  factory NewsStats.empty() => NewsStats(
        specialistId: '',
        totalNews: 0,
        totalLikes: 0,
        totalShares: 0,
        totalViews: 0,
        subscribersCount: 0,
        lastUpdated: DateTime.now(),
      );

  final String specialistId;
  final int totalNews;
  final int totalLikes;
  final int totalShares;
  final int totalViews;
  final int subscribersCount;
  final DateTime lastUpdated;

  double get averageLikes => totalNews > 0 ? totalLikes / totalNews : 0.0;
  double get averageShares => totalNews > 0 ? totalShares / totalNews : 0.0;
  double get averageViews => totalNews > 0 ? totalViews / totalNews : 0.0;
}
