import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/idea.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для идей (только реальные данные из Firestore)
final ideasProvider = StreamProvider<List<Idea>>((ref) async* {
  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection('ideas')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()) {
      final ideas = snapshot.docs.map(Idea.fromFirestore).toList();
      yield ideas; // Только реальные данные, без fallback на тестовые
    }
  } catch (e) {
    debugPrint('Error loading ideas: $e');
    yield []; // Пустой список при ошибке
  }
});

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
        .where('status', isEqualTo: 'active')
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
    required String authorId, required String authorName, String? imageUrl,
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
        'status': 'active',
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
      await FirebaseFirestore.instance
          .collection('ideas')
          .doc(ideaId)
          .collection('comments')
          .add({
        'text': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка при добавлении комментария: $e');
    }
  }
}

final ideasNotifierProvider =
    NotifierProvider<IdeasNotifier, AsyncValue<List<Idea>>>(
  IdeasNotifier.new,
);
