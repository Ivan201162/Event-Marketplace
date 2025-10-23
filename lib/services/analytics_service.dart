import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для аналитики
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Отслеживание просмотра профиля
  Future<void> trackProfileView({
    required String specialistId,
    String? source, // 'search', 'recommendations', 'direct'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('profile_views').add({
        'specialistId': specialistId,
        'viewerId': user.uid,
        'source': source ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания просмотра профиля: $e');
    }
  }

  /// Отслеживание поиска
  Future<void> trackSearch({
    required String query,
    List<String>? filters,
    int? resultsCount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('search_analytics').add({
        'query': query,
        'filters': filters ?? [],
        'resultsCount': resultsCount ?? 0,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания поиска: $e');
    }
  }

  /// Отслеживание создания заявки
  Future<void> trackRequestCreation({
    required String requestId,
    required String specialistId,
    String? category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('request_analytics').add({
        'requestId': requestId,
        'specialistId': specialistId,
        'category': category,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания создания заявки: $e');
    }
  }

  /// Отслеживание отправки сообщения
  Future<void> trackMessageSent({
    required String chatId,
    required String recipientId,
    String? messageType, // 'text', 'image', 'file'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('message_analytics').add({
        'chatId': chatId,
        'recipientId': recipientId,
        'messageType': messageType ?? 'text',
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания отправки сообщения: $e');
    }
  }

  /// Отслеживание создания идеи
  Future<void> trackIdeaCreation({
    required String ideaId,
    String? category,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('idea_analytics').add({
        'ideaId': ideaId,
        'category': category,
        'tags': tags ?? [],
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания создания идеи: $e');
    }
  }

  /// Отслеживание лайка
  Future<void> trackLike({
    required String targetId,
    required String targetType, // 'post', 'idea', 'profile'
    required bool isLiked,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('like_analytics').add({
        'targetId': targetId,
        'targetType': targetType,
        'isLiked': isLiked,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания лайка: $e');
    }
  }

  /// Отслеживание комментария
  Future<void> trackComment({
    required String targetId,
    required String targetType, // 'post', 'idea'
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('comment_analytics').add({
        'targetId': targetId,
        'targetType': targetType,
        'commentId': commentId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания комментария: $e');
    }
  }

  /// Отслеживание подписки
  Future<void> trackSubscription({
    required String targetId,
    required String targetType, // 'specialist', 'category'
    required bool isSubscribed,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('subscription_analytics').add({
        'targetId': targetId,
        'targetType': targetType,
        'isSubscribed': isSubscribed,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка отслеживания подписки: $e');
    }
  }

  /// Получение аналитики пользователя
  Future<Map<String, dynamic>> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Аналитика просмотров профилей
      final viewsQuery = _firestore
          .collection('profile_views')
          .where('viewerId', isEqualTo: user.uid);

      if (startDate != null) {
        viewsQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        viewsQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final viewsSnapshot = await viewsQuery.get();

      // Аналитика поиска
      final searchQuery = _firestore
          .collection('search_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        searchQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        searchQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final searchSnapshot = await searchQuery.get();

      // Аналитика заявок
      final requestsQuery = _firestore
          .collection('request_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        requestsQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        requestsQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final requestsSnapshot = await requestsQuery.get();

      // Аналитика сообщений
      final messagesQuery = _firestore
          .collection('message_analytics')
          .where('senderId', isEqualTo: user.uid);

      if (startDate != null) {
        messagesQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        messagesQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final messagesSnapshot = await messagesQuery.get();

      // Аналитика идей
      final ideasQuery = _firestore
          .collection('idea_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        ideasQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        ideasQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final ideasSnapshot = await ideasQuery.get();

      // Аналитика лайков
      final likesQuery = _firestore
          .collection('like_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        likesQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        likesQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final likesSnapshot = await likesQuery.get();

      // Аналитика комментариев
      final commentsQuery = _firestore
          .collection('comment_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        commentsQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        commentsQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final commentsSnapshot = await commentsQuery.get();

      // Аналитика подписок
      final subscriptionsQuery = _firestore
          .collection('subscription_analytics')
          .where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        subscriptionsQuery.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        subscriptionsQuery.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final subscriptionsSnapshot = await subscriptionsQuery.get();

      return {
        'profileViews': viewsSnapshot.docs.length,
        'searches': searchSnapshot.docs.length,
        'requests': requestsSnapshot.docs.length,
        'messages': messagesSnapshot.docs.length,
        'ideas': ideasSnapshot.docs.length,
        'likes': likesSnapshot.docs.length,
        'comments': commentsSnapshot.docs.length,
        'subscriptions': subscriptionsSnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения аналитики пользователя: $e');
      return {};
    }
  }

  /// Получение популярных поисковых запросов
  Future<List<Map<String, dynamic>>> getPopularSearches({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('search_analytics');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      Map<String, int> searchCounts = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final query = data['query'] as String;
        searchCounts[query] = (searchCounts[query] ?? 0) + 1;
      }

      final sortedSearches = searchCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSearches
          .take(limit)
          .map((entry) => {
                'query': entry.key,
                'count': entry.value,
              })
          .toList();
    } catch (e) {
      print('Ошибка получения популярных поисков: $e');
      return [];
    }
  }

  /// Получение статистики по категориям
  Future<Map<String, dynamic>> getCategoryStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('request_analytics');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      Map<String, int> categoryCounts = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      return {
        'categoryCounts': categoryCounts,
        'totalRequests': querySnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения статистики по категориям: $e');
      return {};
    }
  }

  /// Получение статистики по времени
  Future<Map<String, dynamic>> getTimeStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('profile_views');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      Map<int, int> hourCounts = {};
      Map<int, int> dayCounts = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        final hour = timestamp.hour;
        final day = timestamp.weekday;

        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }

      return {
        'hourCounts': hourCounts,
        'dayCounts': dayCounts,
        'totalViews': querySnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения статистики по времени: $e');
      return {};
    }
  }

  /// Получение статистики по источникам
  Future<Map<String, dynamic>> getSourceStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('profile_views');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      Map<String, int> sourceCounts = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final source = data['source'] as String;
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }

      return {
        'sourceCounts': sourceCounts,
        'totalViews': querySnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения статистики по источникам: $e');
      return {};
    }
  }

  /// Получение общей статистики приложения
  Future<Map<String, dynamic>> getAppStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Статистика пользователей
      final usersQuery = _firestore.collection('users');
      final usersSnapshot = await usersQuery.get();

      // Статистика заявок
      final requestsQuery = _firestore.collection('requests');
      if (startDate != null) {
        requestsQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        requestsQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      final requestsSnapshot = await requestsQuery.get();

      // Статистика сообщений
      final messagesQuery = _firestore.collection('chats');
      if (startDate != null) {
        messagesQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        messagesQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      final messagesSnapshot = await messagesQuery.get();

      // Статистика идей
      final ideasQuery = _firestore.collection('ideas');
      if (startDate != null) {
        ideasQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        ideasQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      final ideasSnapshot = await ideasQuery.get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalRequests': requestsSnapshot.docs.length,
        'totalMessages': messagesSnapshot.docs.length,
        'totalIdeas': ideasSnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения общей статистики: $e');
      return {};
    }
  }
}
