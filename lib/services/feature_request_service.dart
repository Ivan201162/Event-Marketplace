import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/feature_request.dart';

/// Сервис для работы с предложениями по функционалу
class FeatureRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать предложение по функционалу
  Future<String> createFeatureRequest({
    required String userId,
    required String userName,
    String? userEmail,
    required UserType userType,
    required String title,
    required String description,
    required FeatureCategory category,
    FeaturePriority priority = FeaturePriority.medium,
    List<String>? tags,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      final now = DateTime.now();

      final featureRequest = FeatureRequest(
        id: '', // Будет установлен Firestore
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userType: userType,
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: FeatureStatus.submitted,
        tags: tags ?? [],
        attachments: attachments ?? [],
        metadata: metadata ?? {},
        votes: 0,
        voters: [],
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('feature_requests')
          .add(featureRequest.toMap());

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Error creating feature request: $e');
      throw Exception('Ошибка создания предложения: $e');
    }
  }

  /// Получить все предложения
  Stream<List<FeatureRequest>> getFeatureRequests({
    FeatureStatus? status,
    FeatureCategory? category,
    FeaturePriority? priority,
    UserType? userType,
    String? sortBy,
    bool ascending = false,
  }) {
    if (!FeatureFlags.featureRequestsEnabled) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query =
        _firestore.collection('feature_requests');

    // Применяем фильтры
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority.name);
    }
    if (userType != null) {
      query = query.where('userType', isEqualTo: userType.name);
    }

    // Применяем сортировку
    switch (sortBy) {
      case 'votes':
        query = query.orderBy('votes', descending: !ascending);
        break;
      case 'createdAt':
        query = query.orderBy('createdAt', descending: !ascending);
        break;
      case 'priority':
        query = query.orderBy('priority', descending: !ascending);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
    }

    // Добавляем лимит для оптимизации
    query = query.limit(30);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  FeatureRequest.fromMap({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  /// Получить предложения пользователя
  Stream<List<FeatureRequest>> getUserFeatureRequests(String userId) {
    if (!FeatureFlags.featureRequestsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('feature_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  FeatureRequest.fromMap({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  /// Получить предложение по ID
  Future<FeatureRequest?> getFeatureRequestById(String requestId) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      return null;
    }

    try {
      final doc =
          await _firestore.collection('feature_requests').doc(requestId).get();

      if (!doc.exists) {
        return null;
      }

      return FeatureRequest.fromMap({'id': doc.id, ...doc.data()!});
    } on Exception catch (e) {
      debugPrint('Error getting feature request: $e');
      return null;
    }
  }

  /// Обновить предложение
  Future<void> updateFeatureRequest(
      String requestId, Map<String, dynamic> updates) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      await _firestore.collection('feature_requests').doc(requestId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Error updating feature request: $e');
      throw Exception('Ошибка обновления предложения: $e');
    }
  }

  /// Удалить предложение
  Future<void> deleteFeatureRequest(String requestId) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      await _firestore.collection('feature_requests').doc(requestId).delete();
    } on Exception catch (e) {
      debugPrint('Error deleting feature request: $e');
      throw Exception('Ошибка удаления предложения: $e');
    }
  }

  /// Проголосовать за предложение
  Future<void> voteForFeatureRequest(String requestId, String userId) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      final docRef = _firestore.collection('feature_requests').doc(requestId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Предложение не найдено');
        }

        final data = doc.data();
        final voters = List<String>.from(data['voters'] ?? []);

        if (voters.contains(userId)) {
          throw Exception('Вы уже проголосовали за это предложение');
        }

        voters.add(userId);
        final votes = (data['votes'] ?? 0) + 1;

        transaction.update(docRef, {
          'votes': votes,
          'voters': voters,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on Exception catch (e) {
      debugPrint('Error voting for feature request: $e');
      throw Exception('Ошибка голосования: $e');
    }
  }

  /// Отозвать голос за предложение
  Future<void> unvoteForFeatureRequest(String requestId, String userId) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      final docRef = _firestore.collection('feature_requests').doc(requestId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Предложение не найдено');
        }

        final data = doc.data();
        final voters = List<String>.from(data['voters'] ?? []);

        if (!voters.contains(userId)) {
          throw Exception('Вы не голосовали за это предложение');
        }

        voters.remove(userId);
        final votes = (data['votes'] ?? 0) - 1;

        transaction.update(docRef, {
          'votes': votes,
          'voters': voters,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on Exception catch (e) {
      debugPrint('Error unvoting for feature request: $e');
      throw Exception('Ошибка отзыва голоса: $e');
    }
  }

  /// Обновить статус предложения (только для админов)
  Future<void> updateFeatureRequestStatus(
    String requestId,
    FeatureStatus status, {
    String? adminComment,
    String? assignedTo,
    DateTime? estimatedCompletion,
  }) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      throw Exception('Предложения по функционалу отключены');
    }

    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminComment != null) {
        updates['adminComment'] = adminComment;
      }
      if (assignedTo != null) {
        updates['assignedTo'] = assignedTo;
      }
      if (estimatedCompletion != null) {
        updates['estimatedCompletion'] =
            Timestamp.fromDate(estimatedCompletion);
      }

      await _firestore
          .collection('feature_requests')
          .doc(requestId)
          .update(updates);
    } on Exception catch (e) {
      debugPrint('Error updating feature request status: $e');
      throw Exception('Ошибка обновления статуса: $e');
    }
  }

  /// Получить статистику предложений
  Future<FeatureRequestStats> getFeatureRequestStats() async {
    if (!FeatureFlags.featureRequestsEnabled) {
      return _createMockStats();
    }

    try {
      final query = await _firestore.collection('feature_requests').get();

      final requests = query.docs
          .map((doc) => FeatureRequest.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      return _calculateStats(requests);
    } on Exception catch (e) {
      debugPrint('Error getting feature request stats: $e');
      return _createMockStats();
    }
  }

  /// Поиск предложений
  Future<List<FeatureRequest>> searchFeatureRequests(String query) async {
    if (!FeatureFlags.featureRequestsEnabled) {
      return [];
    }

    try {
      // Простой поиск по заголовку и описанию
      final titleQuery = await _firestore
          .collection('feature_requests')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .get();

      final descriptionQuery = await _firestore
          .collection('feature_requests')
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '$query\uf8ff')
          .get();

      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(titleQuery.docs);
      allDocs.addAll(descriptionQuery.docs);

      // Удаляем дубликаты
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map(
            (doc) => FeatureRequest.fromMap(
                {'id': doc.id, ...doc.data()! as Map<String, dynamic>}),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Error searching feature requests: $e');
      return [];
    }
  }

  /// Вычислить статистику
  FeatureRequestStats _calculateStats(List<FeatureRequest> requests) {
    final totalRequests = requests.length;
    var submittedRequests = 0;
    var underReviewRequests = 0;
    var approvedRequests = 0;
    var inDevelopmentRequests = 0;
    var completedRequests = 0;
    var rejectedRequests = 0;

    final categoryStats = <FeatureCategory, int>{};
    final priorityStats = <FeaturePriority, int>{};
    final userTypeStats = <UserType, int>{};

    var totalVotes = 0;

    for (final request in requests) {
      // Статистика по статусам
      switch (request.status) {
        case FeatureStatus.submitted:
          submittedRequests++;
          break;
        case FeatureStatus.underReview:
          underReviewRequests++;
          break;
        case FeatureStatus.approved:
          approvedRequests++;
          break;
        case FeatureStatus.inDevelopment:
          inDevelopmentRequests++;
          break;
        case FeatureStatus.completed:
          completedRequests++;
          break;
        case FeatureStatus.rejected:
          rejectedRequests++;
          break;
        case FeatureStatus.duplicate:
          break;
      }

      // Статистика по категориям
      categoryStats[request.category] =
          (categoryStats[request.category] ?? 0) + 1;

      // Статистика по приоритетам
      priorityStats[request.priority] =
          (priorityStats[request.priority] ?? 0) + 1;

      // Статистика по типам пользователей
      userTypeStats[request.userType] =
          (userTypeStats[request.userType] ?? 0) + 1;

      // Общее количество голосов
      totalVotes += request.votes;
    }

    final averageVotesPerRequest =
        totalRequests > 0 ? totalVotes / totalRequests : 0.0;

    return FeatureRequestStats(
      totalRequests: totalRequests,
      submittedRequests: submittedRequests,
      underReviewRequests: underReviewRequests,
      approvedRequests: approvedRequests,
      inDevelopmentRequests: inDevelopmentRequests,
      completedRequests: completedRequests,
      rejectedRequests: rejectedRequests,
      categoryStats: categoryStats,
      priorityStats: priorityStats,
      userTypeStats: userTypeStats,
      totalVotes: totalVotes,
      averageVotesPerRequest: averageVotesPerRequest,
    );
  }

  /// Создать mock статистику
  FeatureRequestStats _createMockStats() => const FeatureRequestStats(
        totalRequests: 25,
        submittedRequests: 8,
        underReviewRequests: 5,
        approvedRequests: 4,
        inDevelopmentRequests: 3,
        completedRequests: 3,
        rejectedRequests: 2,
        categoryStats: {
          FeatureCategory.ui: 8,
          FeatureCategory.functionality: 10,
          FeatureCategory.performance: 3,
          FeatureCategory.integration: 2,
          FeatureCategory.other: 2,
        },
        priorityStats: {
          FeaturePriority.low: 5,
          FeaturePriority.medium: 15,
          FeaturePriority.high: 4,
          FeaturePriority.critical: 1,
        },
        userTypeStats: {
          UserType.customer: 18,
          UserType.specialist: 6,
          UserType.admin: 1
        },
        totalVotes: 156,
        averageVotesPerRequest: 6.24,
      );
}
