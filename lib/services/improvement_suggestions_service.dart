import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';

/// Сервис для системы предложений по улучшению
class ImprovementSuggestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать предложение по улучшению
  Future<ImprovementSuggestion> createSuggestion({
    required String userId,
    required String title,
    required String description,
    required SuggestionCategory category,
    SuggestionPriority priority = SuggestionPriority.medium,
    List<String>? tags,
    String? contactEmail,
  }) async {
    if (!FeatureFlags.improvementSuggestionsEnabled) {
      throw Exception('Система предложений по улучшению отключена');
    }

    try {
      final suggestion = ImprovementSuggestion(
        id: '',
        userId: userId,
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: SuggestionStatus.submitted,
        tags: tags ?? [],
        contactEmail: contactEmail,
        votes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {},
      );

      final docRef = await _firestore
          .collection('improvement_suggestions')
          .add(suggestion.toMap());

      return suggestion.copyWith(id: docRef.id);
    } on Exception catch (e) {
      throw Exception('Ошибка создания предложения: $e');
    }
  }

  /// Получить предложения по улучшению
  Future<List<ImprovementSuggestion>> getSuggestions({
    SuggestionStatus? status,
    SuggestionCategory? category,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('improvement_suggestions');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('improvement_suggestions')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(ImprovementSuggestion.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка получения предложений: $e');
    }
  }

  /// Проголосовать за предложение
  Future<void> voteForSuggestion({
    required String suggestionId,
    required String userId,
    required bool isUpvote,
  }) async {
    try {
      final suggestion = await _getSuggestion(suggestionId);
      if (suggestion == null) {
        throw Exception('Предложение не найдено');
      }

      // Проверяем, не голосовал ли пользователь уже
      final voteDoc = await _firestore
          .collection('suggestion_votes')
          .where('suggestionId', isEqualTo: suggestionId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (voteDoc.docs.isNotEmpty) {
        final existingVote = voteDoc.docs.first.data();
        if (existingVote['isUpvote'] == isUpvote) {
          throw Exception('Вы уже проголосовали за это предложение');
        }
      }

      // Сохраняем голос
      await _firestore.collection('suggestion_votes').add({
        'suggestionId': suggestionId,
        'userId': userId,
        'isUpvote': isUpvote,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем счетчик голосов
      final voteChange = isUpvote ? 1 : -1;
      await _firestore
          .collection('improvement_suggestions')
          .doc(suggestionId)
          .update({
        'votes': FieldValue.increment(voteChange),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      throw Exception('Ошибка голосования: $e');
    }
  }

  /// Обновить статус предложения
  Future<void> updateSuggestionStatus({
    required String suggestionId,
    required SuggestionStatus status,
    String? adminComment,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == SuggestionStatus.reviewed) {
        updateData['reviewedAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == SuggestionStatus.implemented) {
        updateData['implementedAt'] = Timestamp.fromDate(DateTime.now());
      }

      if (adminComment != null) {
        updateData['adminComment'] = adminComment;
      }

      await _firestore
          .collection('improvement_suggestions')
          .doc(suggestionId)
          .update(updateData);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления статуса предложения: $e');
    }
  }

  /// Получить предложения пользователя
  Future<List<ImprovementSuggestion>> getUserSuggestions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('improvement_suggestions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(ImprovementSuggestion.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка получения предложений пользователя: $e');
    }
  }

  /// Получить популярные предложения
  Future<List<ImprovementSuggestion>> getPopularSuggestions(
      {int limit = 10,}) async {
    try {
      final snapshot = await _firestore
          .collection('improvement_suggestions')
          .where('status', isEqualTo: SuggestionStatus.submitted.name)
          .orderBy('votes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(ImprovementSuggestion.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка получения популярных предложений: $e');
    }
  }

  /// Получить статистику предложений
  Future<SuggestionStatistics> getSuggestionStatistics() async {
    try {
      final snapshot =
          await _firestore.collection('improvement_suggestions').get();
      final suggestions =
          snapshot.docs.map(ImprovementSuggestion.fromDocument).toList();

      final totalSuggestions = suggestions.length;
      final implementedSuggestions = suggestions
          .where((s) => s.status == SuggestionStatus.implemented)
          .length;
      final pendingSuggestions = suggestions
          .where((s) => s.status == SuggestionStatus.submitted)
          .length;
      final reviewedSuggestions = suggestions
          .where((s) => s.status == SuggestionStatus.reviewed)
          .length;

      final categoryStats = <SuggestionCategory, int>{};
      for (final category in SuggestionCategory.values) {
        categoryStats[category] =
            suggestions.where((s) => s.category == category).length;
      }

      return SuggestionStatistics(
        totalSuggestions: totalSuggestions,
        implementedSuggestions: implementedSuggestions,
        pendingSuggestions: pendingSuggestions,
        reviewedSuggestions: reviewedSuggestions,
        categoryStatistics: categoryStats,
      );
    } on Exception catch (e) {
      throw Exception('Ошибка получения статистики предложений: $e');
    }
  }

  // Приватные методы

  Future<ImprovementSuggestion?> _getSuggestion(String suggestionId) async {
    try {
      final doc = await _firestore
          .collection('improvement_suggestions')
          .doc(suggestionId)
          .get();
      if (doc.exists) {
        return ImprovementSuggestion.fromDocument(doc);
      }
      return null;
    } on Exception {
      return null;
    }
  }
}

/// Модель предложения по улучшению
class ImprovementSuggestion {
  const ImprovementSuggestion({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.tags,
    required this.votes, required this.createdAt, required this.updatedAt, required this.metadata, this.contactEmail,
    this.reviewedAt,
    this.implementedAt,
  });

  /// Создать из документа Firestore
  factory ImprovementSuggestion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ImprovementSuggestion(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: SuggestionCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => SuggestionCategory.general,
      ),
      priority: SuggestionPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => SuggestionPriority.medium,
      ),
      status: SuggestionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SuggestionStatus.submitted,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      contactEmail: data['contactEmail'],
      votes: data['votes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      implementedAt: data['implementedAt'] != null
          ? (data['implementedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final String title;
  final String description;
  final SuggestionCategory category;
  final SuggestionPriority priority;
  final SuggestionStatus status;
  final List<String> tags;
  final String? contactEmail;
  final int votes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final DateTime? implementedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'status': status.name,
        'tags': tags,
        'contactEmail': contactEmail,
        'votes': votes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'implementedAt':
            implementedAt != null ? Timestamp.fromDate(implementedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ImprovementSuggestion copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    SuggestionCategory? category,
    SuggestionPriority? priority,
    SuggestionStatus? status,
    List<String>? tags,
    String? contactEmail,
    int? votes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    DateTime? implementedAt,
    Map<String, dynamic>? metadata,
  }) =>
      ImprovementSuggestion(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        tags: tags ?? this.tags,
        contactEmail: contactEmail ?? this.contactEmail,
        votes: votes ?? this.votes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        implementedAt: implementedAt ?? this.implementedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Статистика предложений
class SuggestionStatistics {
  const SuggestionStatistics({
    required this.totalSuggestions,
    required this.implementedSuggestions,
    required this.pendingSuggestions,
    required this.reviewedSuggestions,
    required this.categoryStatistics,
  });
  final int totalSuggestions;
  final int implementedSuggestions;
  final int pendingSuggestions;
  final int reviewedSuggestions;
  final Map<SuggestionCategory, int> categoryStatistics;
}

/// Категории предложений
enum SuggestionCategory {
  general, // Общие улучшения
  ui, // Пользовательский интерфейс
  performance, // Производительность
  features, // Новые функции
  bugfix, // Исправление ошибок
  integration, // Интеграции
  security, // Безопасность
}

/// Приоритеты предложений
enum SuggestionPriority {
  low, // Низкий
  medium, // Средний
  high, // Высокий
  critical, // Критический
}

/// Статусы предложений
enum SuggestionStatus {
  submitted, // Отправлено
  reviewed, // Рассмотрено
  inProgress, // В работе
  implemented, // Реализовано
  rejected, // Отклонено
  duplicate, // Дубликат
}
