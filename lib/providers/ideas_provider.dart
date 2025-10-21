import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';

/// Провайдер для идей с тестовыми данными
final ideasProvider = StreamProvider<List<Idea>>((ref) async* {
  // Сначала пытаемся загрузить из Firestore
  try {
    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('ideas')
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final ideas = snapshot.docs.map(Idea.fromFirestore).toList();

      // Если нет данных, добавляем тестовые
      if (ideas.isEmpty) {
        yield _getTestIdeas();
      } else {
        yield ideas;
      }
    }
  } catch (e) {
    // В случае ошибки возвращаем тестовые данные
    yield _getTestIdeas();
  }
});

/// Тестовые данные для идей
List<Idea> _getTestIdeas() => [
  Idea(
    id: 'idea_1',
    title: 'Свадьба в стиле бохо',
    description:
        'Романтичная свадьба с элементами бохо-шика: натуральные материалы, пастельные тона, цветочные композиции',
    imageUrl: 'https://picsum.photos/400/600?random=10',
    category: 'Свадьбы',
    authorId: 'author_1',
    authorName: 'Анна Фотограф',
    authorAvatar: 'https://picsum.photos/200/200?random=1',
    likesCount: 27,
    // commentCount: 8,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  Idea(
    id: 'idea_2',
    title: 'Детский день рождения',
    description: 'Веселая вечеринка для детей с аниматорами, конкурсами и вкусными угощениями',
    imageUrl: 'https://picsum.photos/400/600?random=11',
    category: 'Детские праздники',
    authorId: 'author_2',
    authorName: 'Максим Ведущий',
    authorAvatar: 'https://picsum.photos/200/200?random=2',
    likesCount: 15,
    // commentCount: 3,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Idea(
    id: 'idea_3',
    title: 'Корпоратив в стиле 80-х',
    description: 'Ретро-вечеринка с музыкой 80-х, яркими костюмами и атмосферой диско',
    imageUrl: 'https://picsum.photos/400/600?random=12',
    category: 'Корпоративы',
    authorId: 'author_3',
    authorName: 'Елена Декор',
    authorAvatar: 'https://picsum.photos/200/200?random=3',
    likesCount: 33,
    // commentCount: 12,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  Idea(
    id: 'idea_4',
    title: 'Романтический ужин',
    description: 'Интимный ужин при свечах с изысканными блюдами и вином',
    imageUrl: 'https://picsum.photos/400/600?random=13',
    category: 'Романтика',
    authorId: 'author_4',
    authorName: 'Дмитрий Диджей',
    authorAvatar: 'https://picsum.photos/200/200?random=4',
    likesCount: 19,
    // commentCount: 5,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Idea(
    id: 'idea_5',
    title: 'Пикник на природе',
    description: 'Семейный пикник с играми, барбекю и активными развлечениями на свежем воздухе',
    imageUrl: 'https://picsum.photos/400/600?random=14',
    category: 'Пикники',
    authorId: 'author_5',
    authorName: 'Ольга Кейтеринг',
    authorAvatar: 'https://picsum.photos/200/200?random=5',
    likesCount: 41,
    // commentCount: 16,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Idea(
    id: 'idea_6',
    title: 'Выпускной вечер',
    description: 'Торжественный выпускной с награждениями, танцами и праздничным ужином',
    imageUrl: 'https://picsum.photos/400/600?random=15',
    category: 'Выпускные',
    authorId: 'author_1',
    authorName: 'Анна Фотограф',
    authorAvatar: 'https://picsum.photos/200/200?random=1',
    likesCount: 22,
    // commentCount: 7,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Idea(
    id: 'idea_7',
    title: 'Хэллоуин-вечеринка',
    description: 'Страшная вечеринка с костюмами, украшениями и тематическими угощениями',
    imageUrl: 'https://picsum.photos/400/600?random=16',
    category: 'Хэллоуин',
    authorId: 'author_2',
    authorName: 'Максим Ведущий',
    authorAvatar: 'https://picsum.photos/200/200?random=2',
    likesCount: 38,
    // commentCount: 14,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Idea(
    id: 'idea_8',
    title: 'Новогодняя ночь',
    description: 'Встреча Нового года с фейерверками, подарками и праздничным настроением',
    imageUrl: 'https://picsum.photos/400/600?random=17',
    category: 'Новый год',
    authorId: 'author_3',
    authorName: 'Елена Декор',
    authorAvatar: 'https://picsum.photos/200/200?random=3',
    likesCount: 56,
    // commentCount: 23,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

/// Провайдер для управления идеями (мигрирован с StateNotifier)
class IdeasNotifier extends Notifier<AsyncValue<List<Idea>>> {
  @override
  AsyncValue<List<Idea>> build() {
    _loadIdeas();
    return const AsyncValue.loading();
  }

  void _loadIdeas() {
    FirebaseFirestore.instance
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final ideas = snapshot.docs.map(Idea.fromDocument).toList();
          state = AsyncValue.data(ideas);
        });
  }

  /// Создать новую идею
  Future<void> createIdea({
    required String title,
    required String description,
    String? imageUrl,
    required String authorId,
    required String authorName,
    String? authorAvatar,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('ideas').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likeCount': 0,
        'commentCount': 0,
        'isLiked': false,
        'isSaved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка при создании идеи: $e');
    }
  }

  /// Поставить/убрать лайк
  Future<void> toggleLike(String ideaId, bool isLiked) async {
    try {
      final ideaRef = FirebaseFirestore.instance.collection('ideas').doc(ideaId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (ideaDoc.exists) {
          final currentLikes = ideaDoc.data()?['likeCount'] ?? 0;
          final newLikes = isLiked ? currentLikes - 1 : currentLikes + 1;
          transaction.update(ideaRef, {'likeCount': newLikes, 'isLiked': !isLiked});
        }
      });
    } on Exception catch (e) {
      debugPrint('Ошибка при изменении лайка: $e');
    }
  }

  /// Сохранить/убрать из сохранённых
  Future<void> toggleSave(String ideaId, bool isSaved) async {
    try {
      await FirebaseFirestore.instance.collection('ideas').doc(ideaId).update({
        'isSaved': !isSaved,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка при изменении сохранения: $e');
    }
  }

  /// Добавить комментарий
  Future<void> addComment(String ideaId, String comment) async {
    try {
      final ideaRef = FirebaseFirestore.instance.collection('ideas').doc(ideaId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (ideaDoc.exists) {
          final currentComments = ideaDoc.data()?['commentCount'] ?? 0;
          transaction.update(ideaRef, {'commentCount': currentComments + 1});
        }
      });

      // Добавляем комментарий в подколлекцию
      await FirebaseFirestore.instance.collection('ideas').doc(ideaId).collection('comments').add({
        'text': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка при добавлении комментария: $e');
    }
  }
}

final ideasNotifierProvider = NotifierProvider<IdeasNotifier, AsyncValue<List<Idea>>>(
  IdeasNotifier.new,
);
