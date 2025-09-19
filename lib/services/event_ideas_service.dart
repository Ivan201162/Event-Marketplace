import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/feature_flags.dart';

/// Сервис для раздела идей мероприятий
class EventIdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать идею мероприятия
  Future<EventIdea> createEventIdea({
    required String userId,
    required String title,
    required String description,
    required EventIdeaCategory category,
    required EventIdeaType type,
    List<String>? tags,
    String? targetAudience,
    int? estimatedParticipants,
    Duration? estimatedDuration,
    String? location,
    double? estimatedBudget,
    List<String>? requiredServices,
    String? inspiration,
  }) async {
    if (!FeatureFlags.eventIdeasEnabled) {
      throw Exception('Раздел идей мероприятий отключен');
    }

    try {
      final idea = EventIdea(
        id: '',
        userId: userId,
        title: title,
        description: description,
        category: category,
        type: type,
        tags: tags ?? [],
        targetAudience: targetAudience,
        estimatedParticipants: estimatedParticipants,
        estimatedDuration: estimatedDuration,
        location: location,
        estimatedBudget: estimatedBudget,
        requiredServices: requiredServices ?? [],
        inspiration: inspiration,
        status: EventIdeaStatus.draft,
        likes: 0,
        views: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {},
      );

      final docRef =
          await _firestore.collection('event_ideas').add(idea.toMap());

      return idea.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания идеи мероприятия: $e');
    }
  }

  /// Опубликовать идею мероприятия
  Future<void> publishEventIdea(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'status': EventIdeaStatus.published.name,
        'publishedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка публикации идеи: $e');
    }
  }

  /// Получить идеи мероприятий
  Future<List<EventIdea>> getEventIdeas({
    EventIdeaCategory? category,
    EventIdeaType? type,
    EventIdeaStatus? status,
    String? searchQuery,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('event_ideas');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      } else {
        query =
            query.where('status', isEqualTo: EventIdeaStatus.published.name);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('event_ideas')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      var ideas = snapshot.docs.map(EventIdea.fromDocument).toList();

      // Фильтрация по поисковому запросу
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        ideas = ideas
            .where(
              (idea) =>
                  idea.title.toLowerCase().contains(queryLower) ||
                  idea.description.toLowerCase().contains(queryLower) ||
                  idea.tags
                      .any((tag) => tag.toLowerCase().contains(queryLower)),
            )
            .toList();
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка получения идей мероприятий: $e');
    }
  }

  /// Получить популярные идеи
  Future<List<EventIdea>> getPopularEventIdeas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('status', isEqualTo: EventIdeaStatus.published.name)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(EventIdea.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения популярных идей: $e');
    }
  }

  /// Получить идеи пользователя
  Future<List<EventIdea>> getUserEventIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(EventIdea.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения идей пользователя: $e');
    }
  }

  /// Лайкнуть идею
  Future<void> likeEventIdea({
    required String ideaId,
    required String userId,
  }) async {
    try {
      // Проверяем, не лайкнул ли пользователь уже
      final likeDoc = await _firestore
          .collection('event_idea_likes')
          .where('ideaId', isEqualTo: ideaId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (likeDoc.docs.isNotEmpty) {
        throw Exception('Вы уже лайкнули эту идею');
      }

      // Сохраняем лайк
      await _firestore.collection('event_idea_likes').add({
        'ideaId': ideaId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Увеличиваем счетчик лайков
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'likes': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Убрать лайк с идеи
  Future<void> unlikeEventIdea({
    required String ideaId,
    required String userId,
  }) async {
    try {
      // Находим лайк
      final likeDoc = await _firestore
          .collection('event_idea_likes')
          .where('ideaId', isEqualTo: ideaId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (likeDoc.docs.isEmpty) {
        throw Exception('Вы не лайкали эту идею');
      }

      // Удаляем лайк
      await _firestore
          .collection('event_idea_likes')
          .doc(likeDoc.docs.first.id)
          .delete();

      // Уменьшаем счетчик лайков
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'likes': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViews(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'views': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки обновления просмотров
    }
  }

  /// Получить идею по ID
  Future<EventIdea?> getEventIdea(String ideaId) async {
    try {
      final doc = await _firestore.collection('event_ideas').doc(ideaId).get();
      if (doc.exists) {
        return EventIdea.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения идеи: $e');
    }
  }

  /// Получить похожие идеи
  Future<List<EventIdea>> getSimilarEventIdeas({
    required String ideaId,
    int limit = 5,
  }) async {
    try {
      final idea = await getEventIdea(ideaId);
      if (idea == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('event_ideas')
          .where('category', isEqualTo: idea.category.name)
          .where('status', isEqualTo: EventIdeaStatus.published.name)
          .where(FieldPath.documentId, isNotEqualTo: ideaId)
          .limit(limit)
          .get();

      return snapshot.docs.map(EventIdea.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения похожих идей: $e');
    }
  }

  /// Получить статистику идей
  Future<EventIdeasStatistics> getEventIdeasStatistics() async {
    try {
      final snapshot = await _firestore.collection('event_ideas').get();
      final ideas = snapshot.docs.map(EventIdea.fromDocument).toList();

      final totalIdeas = ideas.length;
      final publishedIdeas =
          ideas.where((i) => i.status == EventIdeaStatus.published).length;
      final draftIdeas =
          ideas.where((i) => i.status == EventIdeaStatus.draft).length;

      final categoryStats = <EventIdeaCategory, int>{};
      for (final category in EventIdeaCategory.values) {
        categoryStats[category] =
            ideas.where((i) => i.category == category).length;
      }

      final totalLikes = ideas.fold(0, (sum, idea) => sum + idea.likes);
      final totalViews = ideas.fold(0, (sum, idea) => sum + idea.views);

      return EventIdeasStatistics(
        totalIdeas: totalIdeas,
        publishedIdeas: publishedIdeas,
        draftIdeas: draftIdeas,
        categoryStatistics: categoryStats,
        totalLikes: totalLikes,
        totalViews: totalViews,
      );
    } catch (e) {
      throw Exception('Ошибка получения статистики идей: $e');
    }
  }
}

/// Модель идеи мероприятия
class EventIdea {
  const EventIdea({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.tags,
    this.targetAudience,
    this.estimatedParticipants,
    this.estimatedDuration,
    this.location,
    this.estimatedBudget,
    required this.requiredServices,
    this.inspiration,
    required this.status,
    required this.likes,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventIdea(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: EventIdeaCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => EventIdeaCategory.general,
      ),
      type: EventIdeaType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => EventIdeaType.public,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      targetAudience: data['targetAudience'],
      estimatedParticipants: data['estimatedParticipants'],
      estimatedDuration: data['estimatedDuration'] != null
          ? Duration(seconds: data['estimatedDuration'])
          : null,
      location: data['location'],
      estimatedBudget: (data['estimatedBudget'] as num?)?.toDouble(),
      requiredServices: List<String>.from(data['requiredServices'] ?? []),
      inspiration: data['inspiration'],
      status: EventIdeaStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EventIdeaStatus.draft,
      ),
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final String title;
  final String description;
  final EventIdeaCategory category;
  final EventIdeaType type;
  final List<String> tags;
  final String? targetAudience;
  final int? estimatedParticipants;
  final Duration? estimatedDuration;
  final String? location;
  final double? estimatedBudget;
  final List<String> requiredServices;
  final String? inspiration;
  final EventIdeaStatus status;
  final int likes;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'type': type.name,
        'tags': tags,
        'targetAudience': targetAudience,
        'estimatedParticipants': estimatedParticipants,
        'estimatedDuration': estimatedDuration?.inSeconds,
        'location': location,
        'estimatedBudget': estimatedBudget,
        'requiredServices': requiredServices,
        'inspiration': inspiration,
        'status': status.name,
        'likes': likes,
        'views': views,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'publishedAt':
            publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EventIdea copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    EventIdeaCategory? category,
    EventIdeaType? type,
    List<String>? tags,
    String? targetAudience,
    int? estimatedParticipants,
    Duration? estimatedDuration,
    String? location,
    double? estimatedBudget,
    List<String>? requiredServices,
    String? inspiration,
    EventIdeaStatus? status,
    int? likes,
    int? views,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    Map<String, dynamic>? metadata,
  }) =>
      EventIdea(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        type: type ?? this.type,
        tags: tags ?? this.tags,
        targetAudience: targetAudience ?? this.targetAudience,
        estimatedParticipants:
            estimatedParticipants ?? this.estimatedParticipants,
        estimatedDuration: estimatedDuration ?? this.estimatedDuration,
        location: location ?? this.location,
        estimatedBudget: estimatedBudget ?? this.estimatedBudget,
        requiredServices: requiredServices ?? this.requiredServices,
        inspiration: inspiration ?? this.inspiration,
        status: status ?? this.status,
        likes: likes ?? this.likes,
        views: views ?? this.views,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        publishedAt: publishedAt ?? this.publishedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Статистика идей мероприятий
class EventIdeasStatistics {
  const EventIdeasStatistics({
    required this.totalIdeas,
    required this.publishedIdeas,
    required this.draftIdeas,
    required this.categoryStatistics,
    required this.totalLikes,
    required this.totalViews,
  });
  final int totalIdeas;
  final int publishedIdeas;
  final int draftIdeas;
  final Map<EventIdeaCategory, int> categoryStatistics;
  final int totalLikes;
  final int totalViews;
}

/// Категории идей мероприятий
enum EventIdeaCategory {
  general, // Общие
  corporate, // Корпоративные
  wedding, // Свадьбы
  birthday, // Дни рождения
  conference, // Конференции
  festival, // Фестивали
  exhibition, // Выставки
  charity, // Благотворительные
  educational, // Образовательные
  entertainment, // Развлекательные
}

/// Типы идей
enum EventIdeaType {
  public, // Публичная
  private, // Приватная
  template, // Шаблон
}

/// Статусы идей
enum EventIdeaStatus {
  draft, // Черновик
  published, // Опубликована
  archived, // Архивирована
}
