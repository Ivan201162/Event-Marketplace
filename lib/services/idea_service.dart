import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/idea.dart';

/// Сервис для работы с идеями
class IdeaService {
  factory IdeaService() => _instance;
  IdeaService._internal();
  static final IdeaService _instance = IdeaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ideas';

  /// Получить все идеи
  Future<List<Idea>> getAllIdeas() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map(Idea.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestIdeas();
    }
  }

  /// Получить идеи по категории
  Future<List<Idea>> getIdeasByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Idea.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestIdeas().where((idea) => idea.category == category).toList();
    }
  }

  /// Получить идеи автора
  Future<List<Idea>> getIdeasByAuthor(String authorId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Idea.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestIdeas().where((idea) => idea.authorId == authorId).toList();
    }
  }

  /// Получить популярные идеи
  Future<List<Idea>> getTrendingIdeas() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map(Idea.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestIdeas()..sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }
  }

  /// Создать идею
  Future<String> createIdea(Idea idea) async {
    try {
      final docRef = await _firestore.collection(_collection).add(idea.toMap());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Обновить идею
  Future<void> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).update(updates);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Лайкнуть идею
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      final ideaRef = _firestore.collection(_collection).doc(ideaId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ideaRef);
        if (!snapshot.exists) return;

        final idea = Idea.fromDocument(snapshot);
        final likedBy = List<String>.from(idea.likedBy);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        transaction.update(ideaRef, {
          'likedBy': likedBy,
          'likesCount': likedBy.length,
        });
      });
    } on Exception catch (e) {
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId, String userId) async {
    try {
      final ideaRef = _firestore.collection(_collection).doc(ideaId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ideaRef);
        if (!snapshot.exists) return;

        final idea = Idea.fromDocument(snapshot);
        final savedBy = List<String>.from(idea.savedBy);

        if (savedBy.contains(userId)) {
          savedBy.remove(userId);
        } else {
          savedBy.add(userId);
        }

        transaction.update(ideaRef, {
          'savedBy': savedBy,
          'savesCount': savedBy.length,
        });
      });
    } on Exception catch (e) {
      throw Exception('Ошибка сохранения идеи: $e');
    }
  }

  /// Поделиться идеей
  Future<void> shareIdea(String ideaId) async {
    try {
      final ideaRef = _firestore.collection(_collection).doc(ideaId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ideaRef);
        if (!snapshot.exists) return;

        final idea = Idea.fromDocument(snapshot);
        transaction.update(ideaRef, {
          'sharesCount': idea.sharesCount + 1,
        });
      });
    } on Exception catch (e) {
      throw Exception('Ошибка репоста идеи: $e');
    }
  }

  /// Поиск идей
  Future<List<Idea>> searchIdeas(String query) async {
    try {
      // Простой поиск по заголовку и описанию
      final titleSnapshot = await _firestore
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .get();

      final descriptionSnapshot = await _firestore
          .collection(_collection)
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '${query}z')
          .get();

      final ideas = <Idea>[];
      ideas.addAll(titleSnapshot.docs.map(Idea.fromDocument));
      ideas.addAll(descriptionSnapshot.docs.map(Idea.fromDocument));

      // Убираем дубликаты
      final uniqueIdeas = <String, Idea>{};
      for (final idea in ideas) {
        uniqueIdeas[idea.id] = idea;
      }

      return uniqueIdeas.values.toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestIdeas()
          .where(
            (idea) =>
                idea.title.toLowerCase().contains(query.toLowerCase()) ||
                idea.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  /// Тестовые данные
  List<Idea> _getTestIdeas() {
    final now = DateTime.now();
    return [
      Idea(
        id: '1',
        title: 'Свадебная фотосессия в парке',
        description:
            'Романтическая фотосессия молодоженов среди цветущих деревьев. Идеально для весенних свадеб.',
        imageUrl: 'https://placehold.co/400x300/FF6B6B/white?text=Wedding+Photo',
        category: 'Свадьбы',
        authorId: 'specialist1',
        authorName: 'Анна Петрова',
        authorAvatar: 'https://placehold.co/100x100/4CAF50/white?text=AP',
        createdAt: now.subtract(const Duration(days: 1)),
        likesCount: 42,
        savesCount: 15,
        sharesCount: 8,
        tags: ['свадьба', 'фотосессия', 'парк', 'романтика'],
      ),
      Idea(
        id: '2',
        title: 'Корпоративный тимбилдинг',
        description:
            'Активные игры и квесты для сплочения команды. Отличный способ улучшить командную работу.',
        imageUrl: 'https://placehold.co/400x300/4ECDC4/white?text=Team+Building',
        category: 'Корпоративы',
        authorId: 'specialist2',
        authorName: 'Михаил Соколов',
        authorAvatar: 'https://placehold.co/100x100/2196F3/white?text=MS',
        createdAt: now.subtract(const Duration(days: 2)),
        likesCount: 28,
        savesCount: 12,
        sharesCount: 5,
        tags: ['корпоратив', 'тимбилдинг', 'команда', 'активность'],
      ),
      Idea(
        id: '3',
        title: 'Детский день рождения в стиле пиратов',
        description: 'Приключенческая вечеринка с поиском сокровищ, костюмами и пиратскими играми.',
        imageUrl: 'https://placehold.co/400x300/45B7D1/white?text=Pirate+Party',
        category: 'Детские праздники',
        authorId: 'specialist3',
        authorName: 'Елена Козлова',
        authorAvatar: 'https://placehold.co/100x100/FF9800/white?text=EK',
        createdAt: now.subtract(const Duration(days: 3)),
        likesCount: 67,
        savesCount: 23,
        sharesCount: 12,
        tags: ['дети', 'день рождения', 'пираты', 'приключения'],
      ),
      Idea(
        id: '4',
        title: 'Портретная съемка в студии',
        description: 'Профессиональная портретная съемка с качественным освещением и реквизитом.',
        imageUrl: 'https://placehold.co/400x300/96CEB4/white?text=Portrait',
        category: 'Фотосессии',
        authorId: 'specialist1',
        authorName: 'Анна Петрова',
        authorAvatar: 'https://placehold.co/100x100/4CAF50/white?text=AP',
        createdAt: now.subtract(const Duration(days: 4)),
        likesCount: 35,
        savesCount: 18,
        sharesCount: 7,
        tags: ['портрет', 'студия', 'профессиональная съемка'],
      ),
      Idea(
        id: '5',
        title: 'Видеосъемка свадебного танца',
        description: 'Кинематографическая съемка первого танца молодоженов с красивыми ракурсами.',
        imageUrl: 'https://placehold.co/400x300/FFEAA7/white?text=Wedding+Dance',
        category: 'Видеосъемка',
        authorId: 'specialist4',
        authorName: 'Дмитрий Волков',
        authorAvatar: 'https://placehold.co/100x100/9C27B0/white?text=DV',
        createdAt: now.subtract(const Duration(days: 5)),
        likesCount: 89,
        savesCount: 31,
        sharesCount: 15,
        tags: ['видео', 'свадьба', 'танец', 'кинематограф'],
      ),
      Idea(
        id: '6',
        title: 'Тематическая вечеринка в стиле 80-х',
        description: 'Ретро-вечеринка с музыкой, костюмами и атмосферой 1980-х годов.',
        imageUrl: 'https://placehold.co/400x300/FF7675/white?text=80s+Party',
        category: 'Дни рождения',
        authorId: 'specialist2',
        authorName: 'Михаил Соколов',
        authorAvatar: 'https://placehold.co/100x100/2196F3/white?text=MS',
        createdAt: now.subtract(const Duration(days: 6)),
        likesCount: 54,
        savesCount: 19,
        sharesCount: 9,
        tags: ['80-е', 'ретро', 'вечеринка', 'музыка'],
      ),
      Idea(
        id: '7',
        title: 'Семейная фотосессия на природе',
        description:
            'Теплые семейные фотографии на фоне осеннего леса. Идеально для семейных альбомов.',
        imageUrl: 'https://placehold.co/400x300/74B9FF/white?text=Family+Photo',
        category: 'Фотосессии',
        authorId: 'specialist3',
        authorName: 'Елена Козлова',
        authorAvatar: 'https://placehold.co/100x100/FF9800/white?text=EK',
        createdAt: now.subtract(const Duration(days: 7)),
        likesCount: 76,
        savesCount: 27,
        sharesCount: 11,
        tags: ['семья', 'природа', 'осень', 'тепло'],
      ),
      Idea(
        id: '8',
        title: 'Корпоративная новогодняя вечеринка',
        description: 'Праздничное мероприятие с конкурсами, подарками и новогодней атмосферой.',
        imageUrl: 'https://placehold.co/400x300/00B894/white?text=New+Year+Party',
        category: 'Корпоративы',
        authorId: 'specialist4',
        authorName: 'Дмитрий Волков',
        authorAvatar: 'https://placehold.co/100x100/9C27B0/white?text=DV',
        createdAt: now.subtract(const Duration(days: 8)),
        likesCount: 43,
        savesCount: 16,
        sharesCount: 6,
        tags: ['новый год', 'корпоратив', 'праздник', 'подарки'],
      ),
    ];
  }
}
