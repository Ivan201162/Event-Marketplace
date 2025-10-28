import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/idea_enhanced.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Расширенный сервис для работы с идеями
class IdeaServiceEnhanced {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание идеи
  static Future<String> createIdea({
    required String title,
    required String description,
    required String content,
    required IdeaType type,
    required IdeaPrivacy privacy,
    required List<String> attachments,
    required List<String> tags,
    required List<String> categories,
    required List<String> mentions,
    required List<String> hashtags,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? pollData,
    Map<String, dynamic>? location,
    String? language,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final ideaId = _firestore.collection('ideas').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final idea = IdeaEnhanced(
        id: ideaId,
        title: title,
        description: description,
        content: content,
        type: type,
        status: IdeaStatus.published,
        privacy: privacy,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        attachments: attachments,
        tags: tags,
        categories: categories,
        mentions: mentions,
        hashtags: hashtags,
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        bookmarks: 0,
        rating: 0,
        isVerified: userData['isVerified'] ?? false,
        isPinned: false,
        isFeatured: false,
        isTrending: false,
        collaborators: const [],
        followers: const [],
        analytics: {
          'createdAt': now.toIso8601String(),
          'authorId': user.uid,
          'type': type.value,
          'categories': categories,
          'tags': tags,
        },
        aiRecommendations: await _generateAIRecommendations(
          title: title,
          content: content,
          categories: categories,
          tags: tags,
        ),
        commentsList: const [],
        reactions: const [],
        pollData: pollData ?? {},
        childIdeas: const [],
        location: location ?? {},
        language: language ?? 'ru',
        sharedWith: const [],
        monetization: const {},
      );

      await _firestore.collection('ideas').doc(ideaId).set(idea.toFirestore());

      // Создаем уведомления для упомянутых пользователей
      for (final mentionId in mentions) {
        await _createNotification(
          userId: mentionId,
          title: 'Вас упомянули в идее',
          body:
              '${userData['name'] ?? 'Пользователь'} упомянул вас в идее "$title"',
          data: {'ideaId': ideaId, 'type': 'idea_mention'},
        );
      }

      // Добавляем в аналитику
      await _updateAnalytics('idea_created', {
        'ideaId': ideaId,
        'type': type.value,
        'categories': categories,
        'tags': tags,
        'authorId': user.uid,
      });

      return ideaId;
    } catch (e) {
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Получение идей с фильтрами
  static Future<List<IdeaEnhanced>> getIdeas({
    IdeaFilters? filters,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('ideas');

      // Применяем фильтры
      if (filters != null) {
        if (filters.type != null) {
          query = query.where('type', isEqualTo: filters.type!.value);
        }
        if (filters.status != null) {
          query = query.where('status', isEqualTo: filters.status!.value);
        }
        if (filters.privacy != null) {
          query = query.where('privacy', isEqualTo: filters.privacy!.value);
        }
        if (filters.authorId != null) {
          query = query.where('authorId', isEqualTo: filters.authorId);
        }
        if (filters.isVerified != null) {
          query = query.where('isVerified', isEqualTo: filters.isVerified);
        }
        if (filters.isFeatured != null) {
          query = query.where('isFeatured', isEqualTo: filters.isFeatured);
        }
        if (filters.isTrending != null) {
          query = query.where('isTrending', isEqualTo: filters.isTrending);
        }
        if (filters.language != null) {
          query = query.where('language', isEqualTo: filters.language);
        }
        if (filters.minRating != null) {
          query =
              query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
        }
        if (filters.maxRating != null) {
          query = query.where('rating', isLessThanOrEqualTo: filters.maxRating);
        }
        if (filters.startDate != null) {
          query = query.where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!),);
        }
        if (filters.endDate != null) {
          query = query.where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!),);
        }
      }

      // Сортировка
      query = query.orderBy('createdAt', descending: true);

      // Пагинация
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(IdeaEnhanced.fromFirestore)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения идей: $e');
    }
  }

  /// Получение идеи по ID
  static Future<IdeaEnhanced?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (doc.exists) {
        return IdeaEnhanced.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения идеи: $e');
    }
  }

  /// Обновление идеи
  static Future<void> updateIdea(
      String ideaId, Map<String, dynamic> updates,) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверяем права на редактирование
      final idea = await getIdeaById(ideaId);
      if (idea == null) throw Exception('Идея не найдена');
      if (idea.authorId != user.uid) {
        throw Exception('Нет прав на редактирование');
      }

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection('ideas').doc(ideaId).update(updates);

      // Добавляем в аналитику
      await _updateAnalytics('idea_updated', {
        'ideaId': ideaId,
        'authorId': user.uid,
      });
    } catch (e) {
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удаление идеи
  static Future<void> deleteIdea(String ideaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверяем права на удаление
      final idea = await getIdeaById(ideaId);
      if (idea == null) throw Exception('Идея не найдена');
      if (idea.authorId != user.uid) throw Exception('Нет прав на удаление');

      await _firestore.collection('ideas').doc(ideaId).delete();

      // Добавляем в аналитику
      await _updateAnalytics('idea_deleted', {
        'ideaId': ideaId,
        'authorId': user.uid,
      });
    } catch (e) {
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Лайк идеи
  static Future<void> likeIdea(String ideaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final idea = await getIdeaById(ideaId);
      if (idea == null) throw Exception('Идея не найдена');

      // Проверяем, не лайкнул ли уже пользователь
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final likedIdeas = List<String>.from(userData['likedIdeas'] ?? []);

      if (likedIdeas.contains(ideaId)) {
        // Убираем лайк
        await _firestore.collection('ideas').doc(ideaId).update({
          'likes': FieldValue.increment(-1),
        });

        await _firestore.collection('users').doc(user.uid).update({
          'likedIdeas': FieldValue.arrayRemove([ideaId]),
        });
      } else {
        // Добавляем лайк
        await _firestore.collection('ideas').doc(ideaId).update({
          'likes': FieldValue.increment(1),
        });

        await _firestore.collection('users').doc(user.uid).update({
          'likedIdeas': FieldValue.arrayUnion([ideaId]),
        });

        // Создаем уведомление для автора
        if (idea.authorId != user.uid) {
          await _createNotification(
            userId: idea.authorId,
            title: 'Новый лайк',
            body: 'Кто-то поставил лайк вашей идее "${idea.title}"',
            data: {'ideaId': ideaId, 'type': 'idea_like'},
          );
        }
      }

      // Добавляем в аналитику
      await _updateAnalytics('idea_like', {
        'ideaId': ideaId,
        'userId': user.uid,
        'action': likedIdeas.contains(ideaId) ? 'unlike' : 'like',
      });
    } catch (e) {
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Комментирование идеи
  static Future<String> commentIdea({
    required String ideaId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final commentId = _firestore.collection('comments').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final comment = IdeaComment(
        id: commentId,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        content: content,
        createdAt: now,
        likes: const [],
        replies: const [],
        parentCommentId: parentCommentId,
        metadata: const {},
      );

      // Сохраняем комментарий
      await _firestore
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      // Обновляем счетчик комментариев в идее
      await _firestore.collection('ideas').doc(ideaId).update({
        'comments': FieldValue.increment(1),
        'commentsList': FieldValue.arrayUnion([comment.toMap()]),
      });

      // Создаем уведомление для автора идеи
      final idea = await getIdeaById(ideaId);
      if (idea != null && idea.authorId != user.uid) {
        await _createNotification(
          userId: idea.authorId,
          title: 'Новый комментарий',
          body: 'Кто-то прокомментировал вашу идею "${idea.title}"',
          data: {
            'ideaId': ideaId,
            'commentId': commentId,
            'type': 'idea_comment',
          },
        );
      }

      // Добавляем в аналитику
      await _updateAnalytics('idea_comment', {
        'ideaId': ideaId,
        'commentId': commentId,
        'userId': user.uid,
      });

      return commentId;
    } catch (e) {
      throw Exception('Ошибка комментирования идеи: $e');
    }
  }

  /// Репост идеи
  static Future<String> repostIdea(String ideaId, String? comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final originalIdea = await getIdeaById(ideaId);
      if (originalIdea == null) throw Exception('Идея не найдена');

      // Создаем новую идею-репост
      final repostId = await createIdea(
        title: 'Репост: ${originalIdea.title}',
        description: comment ?? originalIdea.description,
        content: originalIdea.content,
        type: originalIdea.type,
        privacy: IdeaPrivacy.public,
        attachments: originalIdea.attachments,
        tags: originalIdea.tags,
        categories: originalIdea.categories,
        mentions: [],
        hashtags: originalIdea.hashtags,
        metadata: {
          'isRepost': true,
          'originalIdeaId': ideaId,
          'repostComment': comment,
        },
      );

      // Обновляем счетчик репостов в оригинальной идее
      await _firestore.collection('ideas').doc(ideaId).update({
        'shares': FieldValue.increment(1),
      });

      // Создаем уведомление для автора оригинальной идеи
      if (originalIdea.authorId != user.uid) {
        await _createNotification(
          userId: originalIdea.authorId,
          title: 'Вашу идею репостнули',
          body: 'Кто-то поделился вашей идеей "${originalIdea.title}"',
          data: {'ideaId': ideaId, 'repostId': repostId, 'type': 'idea_repost'},
        );
      }

      // Добавляем в аналитику
      await _updateAnalytics('idea_repost', {
        'originalIdeaId': ideaId,
        'repostId': repostId,
        'userId': user.uid,
      });

      return repostId;
    } catch (e) {
      throw Exception('Ошибка репоста идеи: $e');
    }
  }

  /// Добавление в закладки
  static Future<void> bookmarkIdea(String ideaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final bookmarkedIdeas =
          List<String>.from(userData['bookmarkedIdeas'] ?? []);

      if (bookmarkedIdeas.contains(ideaId)) {
        // Убираем из закладок
        await _firestore.collection('users').doc(user.uid).update({
          'bookmarkedIdeas': FieldValue.arrayRemove([ideaId]),
        });

        await _firestore.collection('ideas').doc(ideaId).update({
          'bookmarks': FieldValue.increment(-1),
        });
      } else {
        // Добавляем в закладки
        await _firestore.collection('users').doc(user.uid).update({
          'bookmarkedIdeas': FieldValue.arrayUnion([ideaId]),
        });

        await _firestore.collection('ideas').doc(ideaId).update({
          'bookmarks': FieldValue.increment(1),
        });
      }

      // Добавляем в аналитику
      await _updateAnalytics('idea_bookmark', {
        'ideaId': ideaId,
        'userId': user.uid,
        'action': bookmarkedIdeas.contains(ideaId) ? 'remove' : 'add',
      });
    } catch (e) {
      throw Exception('Ошибка добавления в закладки: $e');
    }
  }

  /// Получение идей пользователя
  static Future<List<IdeaEnhanced>> getUserIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(IdeaEnhanced.fromFirestore)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения идей пользователя: $e');
    }
  }

  /// Получение трендовых идей
  static Future<List<IdeaEnhanced>> getTrendingIdeas({
    int limit = 20,
    String? category,
  }) async {
    try {
      Query query = _firestore
          .collection('ideas')
          .where('isTrending', isEqualTo: true)
          .where('status', isEqualTo: IdeaStatus.published.value);

      if (category != null) {
        query = query.where('categories', arrayContains: category);
      }

      query = query.orderBy('likes', descending: true);
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(IdeaEnhanced.fromFirestore)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения трендовых идей: $e');
    }
  }

  /// Получение рекомендуемых идей
  static Future<List<IdeaEnhanced>> getRecommendedIdeas({
    required String userId,
    int limit = 20,
  }) async {
    try {
      // Получаем интересы пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final interests = List<String>.from(userData['interests'] ?? []);
      final likedCategories =
          List<String>.from(userData['likedCategories'] ?? []);

      // Получаем идеи на основе интересов
      final recommendedIdeas = <IdeaEnhanced>[];

      for (final interest in interests) {
        final snapshot = await _firestore
            .collection('ideas')
            .where('categories', arrayContains: interest)
            .where('status', isEqualTo: IdeaStatus.published.value)
            .orderBy('rating', descending: true)
            .limit(5)
            .get();

        recommendedIdeas.addAll(
          snapshot.docs.map(IdeaEnhanced.fromFirestore),
        );
      }

      // Сортируем по рейтингу и возвращаем лимит
      recommendedIdeas.sort((a, b) => b.rating.compareTo(a.rating));
      return recommendedIdeas.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендуемых идей: $e');
    }
  }

  /// Поиск идей
  static Future<List<IdeaEnhanced>> searchIdeas({
    required String query,
    IdeaFilters? filters,
    int limit = 20,
  }) async {
    try {
      // Firestore не поддерживает полнотекстовый поиск
      // Получаем все идеи и фильтруем локально
      final allIdeas = await getIdeas(filters: filters, limit: 1000);

      return allIdeas.where((idea) {
        return idea.title.toLowerCase().contains(query.toLowerCase()) ||
            idea.description.toLowerCase().contains(query.toLowerCase()) ||
            idea.content.toLowerCase().contains(query.toLowerCase()) ||
            idea.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),) ||
            idea.hashtags.any((hashtag) =>
                hashtag.toLowerCase().contains(query.toLowerCase()),);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска идей: $e');
    }
  }

  /// AI рекомендации для идеи
  static Future<Map<String, dynamic>> _generateAIRecommendations({
    required String title,
    required String content,
    required List<String> categories,
    required List<String> tags,
  }) async {
    // Здесь можно интегрировать с AI сервисом
    // Пока возвращаем базовые рекомендации
    return {
      'suggestedTags': _getSuggestedTags(title, content, categories),
      'suggestedCategories': _getSuggestedCategories(title, content, tags),
      'trendingKeywords': _getTrendingKeywords(categories),
      'similarIdeas': _getSimilarIdeas(categories, tags),
      'engagementPrediction':
          _getEngagementPrediction(title, content, categories),
    };
  }

  /// Получение рекомендуемых тегов
  static List<String> _getSuggestedTags(
      String title, String content, List<String> categories,) {
    final allTags = <String>[];

    // Извлекаем теги из заголовка и контента
    final words = '$title $content'.toLowerCase().split(' ');
    for (final word in words) {
      if (word.length > 3 && !allTags.contains(word)) {
        allTags.add(word);
      }
    }

    // Добавляем теги на основе категорий
    for (final category in categories) {
      allTags.add(category.toLowerCase());
    }

    return allTags.take(10).toList();
  }

  /// Получение рекомендуемых категорий
  static List<String> _getSuggestedCategories(
      String title, String content, List<String> tags,) {
    final categories = <String>[];

    // Анализируем теги и контент для определения категорий
    final text = '$title $content ${tags.join(' ')}'.toLowerCase();

    if (text.contains('фото') || text.contains('фотография')) {
      categories.add('Фотография');
    }
    if (text.contains('музыка') || text.contains('песня')) {
      categories.add('Музыка');
    }
    if (text.contains('еда') || text.contains('кулинария')) {
      categories.add('Кулинария');
    }
    if (text.contains('путешествие') || text.contains('туризм')) {
      categories.add('Путешествия');
    }
    if (text.contains('технологии') || text.contains('программирование')) {
      categories.add('Технологии');
    }

    return categories;
  }

  /// Получение трендовых ключевых слов
  static List<String> _getTrendingKeywords(List<String> categories) {
    final keywords = <String>[];

    for (final category in categories) {
      switch (category.toLowerCase()) {
        case 'фотография':
          keywords.addAll(['портрет', 'пейзаж', 'студия', 'свет']);
        case 'музыка':
          keywords.addAll(['концерт', 'инструмент', 'вокал', 'звук']);
        case 'кулинария':
          keywords.addAll(['рецепт', 'ингредиенты', 'вкус', 'повар']);
        case 'путешествия':
          keywords.addAll(
              ['отель', 'достопримечательности', 'культура', 'традиции'],);
        case 'технологии':
          keywords.addAll([
            'инновации',
            'разработка',
            'программирование',
            'искусственный интеллект',
          ]);
      }
    }

    return keywords;
  }

  /// Получение похожих идей
  static List<String> _getSimilarIdeas(
      List<String> categories, List<String> tags,) {
    // Здесь можно реализовать поиск похожих идей
    // Пока возвращаем пустой список
    return [];
  }

  /// Предсказание вовлеченности
  static double _getEngagementPrediction(
      String title, String content, List<String> categories,) {
    final random = Random();
    var score = 0.5; // Базовый балл

    // Анализируем заголовок
    if (title.length > 10 && title.length < 100) score += 0.1;
    if (title.contains('?')) score += 0.05; // Вопросы привлекают внимание

    // Анализируем контент
    if (content.length > 100) score += 0.1;
    if (content.contains('!')) score += 0.05; // Восклицания привлекают внимание

    // Анализируем категории
    if (categories.isNotEmpty) score += 0.1;

    // Добавляем случайность
    score += random.nextDouble() * 0.2;

    return score.clamp(0.0, 1.0);
  }

  /// Создание уведомления
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка создания уведомления: $e');
    }
  }

  /// Обновление аналитики
  static Future<void> _updateAnalytics(
      String event, Map<String, dynamic> data,) async {
    try {
      await _firestore.collection('analytics').add({
        'event': event,
        'data': data,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления аналитики: $e');
    }
  }
}
