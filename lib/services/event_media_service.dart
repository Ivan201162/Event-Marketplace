import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/event_media.dart';

/// Сервис для работы с медиа-центром мероприятия
class EventMediaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Загрузить медиафайл в мероприятие
  Future<String> uploadMediaToEvent({
    required String eventId,
    required String uploadedBy,
    required String uploadedByName,
    required String fileName, required String fileUrl, required MediaType type, required int fileSize, String? uploadedByPhoto,
    String? thumbnailUrl,
    String? mimeType,
    Duration? duration,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool isPublic = true,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw Exception('Загрузка файлов отключена');
    }

    try {
      final mediaData = {
        'eventId': eventId,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'uploadedByPhoto': uploadedByPhoto,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'thumbnailUrl': thumbnailUrl,
        'type': type.name,
        'status': MediaStatus.uploading.name,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'duration': duration?.inMilliseconds,
        'metadata': metadata,
        'tags': tags ?? [],
        'isPublic': isPublic,
        'isFeatured': false,
        'likesCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .add(mediaData);

      // Обновляем статус на "готов"
      await docRef.update({
        'status': MediaStatus.ready.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Uploaded media to event $eventId: $fileName');
      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      throw Exception('Ошибка загрузки медиафайла: $e');
    }
  }

  /// Получить медиафайлы мероприятия
  Stream<List<EventMedia>> getEventMedia(String eventId) => _firestore
      .collection('events')
      .doc(eventId)
      .collection('media')
      .where('status', isEqualTo: MediaStatus.ready.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
            .toList(),
      );

  /// Получить медиафайлы по типу
  Stream<List<EventMedia>> getEventMediaByType(
          String eventId, MediaType type,) =>
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .where('type', isEqualTo: type.name)
          .where('status', isEqualTo: MediaStatus.ready.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
                .toList(),
          );

  /// Получить публичные медиафайлы
  Stream<List<EventMedia>> getPublicEventMedia(String eventId) => _firestore
      .collection('events')
      .doc(eventId)
      .collection('media')
      .where('isPublic', isEqualTo: true)
      .where('status', isEqualTo: MediaStatus.ready.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
            .toList(),
      );

  /// Получить рекомендуемые медиафайлы
  Stream<List<EventMedia>> getFeaturedEventMedia(String eventId) => _firestore
      .collection('events')
      .doc(eventId)
      .collection('media')
      .where('isFeatured', isEqualTo: true)
      .where('status', isEqualTo: MediaStatus.ready.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
            .toList(),
      );

  /// Получить медиафайлы пользователя в мероприятии
  Stream<List<EventMedia>> getUserEventMedia(String eventId, String userId) =>
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .where('uploadedBy', isEqualTo: userId)
          .where('status', isEqualTo: MediaStatus.ready.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
                .toList(),
          );

  /// Лайкнуть медиафайл
  Future<void> likeMedia(String eventId, String mediaId, String userId) async {
    try {
      final mediaRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId);

      await _firestore.runTransaction((transaction) async {
        final mediaDoc = await transaction.get(mediaRef);
        if (!mediaDoc.exists) {
          throw Exception('Медиафайл не найден');
        }

        final media =
            EventMedia.fromMap({'id': mediaDoc.id, ...mediaDoc.data()!});

        if (media.likedBy.contains(userId)) {
          // Убираем лайк
          transaction.update(mediaRef, {
            'likesCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Добавляем лайк
          transaction.update(mediaRef, {
            'likesCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('Toggled like for media $mediaId');
    } catch (e) {
      debugPrint('Error liking media: $e');
      throw Exception('Ошибка лайка медиафайла: $e');
    }
  }

  /// Добавить теги к медиафайлу
  Future<void> addTagsToMedia(
      String eventId, String mediaId, List<String> tags,) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .update({
        'tags': FieldValue.arrayUnion(tags),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Added tags to media $mediaId');
    } catch (e) {
      debugPrint('Error adding tags to media: $e');
      throw Exception('Ошибка добавления тегов: $e');
    }
  }

  /// Удалить теги из медиафайла
  Future<void> removeTagsFromMedia(
      String eventId, String mediaId, List<String> tags,) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .update({
        'tags': FieldValue.arrayRemove(tags),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Removed tags from media $mediaId');
    } catch (e) {
      debugPrint('Error removing tags from media: $e');
      throw Exception('Ошибка удаления тегов: $e');
    }
  }

  /// Сделать медиафайл рекомендуемым
  Future<void> setMediaFeatured(
      String eventId, String mediaId, bool isFeatured,) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Set media $mediaId featured: $isFeatured');
    } catch (e) {
      debugPrint('Error setting media featured: $e');
      throw Exception('Ошибка изменения статуса медиафайла: $e');
    }
  }

  /// Изменить публичность медиафайла
  Future<void> setMediaPublic(
      String eventId, String mediaId, bool isPublic,) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .update({
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Set media $mediaId public: $isPublic');
    } catch (e) {
      debugPrint('Error setting media public: $e');
      throw Exception('Ошибка изменения публичности медиафайла: $e');
    }
  }

  /// Удалить медиафайл
  Future<void> deleteMedia(String eventId, String mediaId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .update({
        'status': MediaStatus.deleted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Deleted media $mediaId');
    } catch (e) {
      debugPrint('Error deleting media: $e');
      throw Exception('Ошибка удаления медиафайла: $e');
    }
  }

  /// Получить статистику медиафайлов мероприятия
  Future<Map<String, dynamic>> getEventMediaStats(String eventId) async {
    try {
      final mediaQuery = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .where('status', isEqualTo: MediaStatus.ready.name)
          .get();

      final media = mediaQuery.docs
          .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      final totalCount = media.length;
      final publicCount = media.where((m) => m.isPublic).length;
      final featuredCount = media.where((m) => m.isFeatured).length;

      final typeCounts = <MediaType, int>{};
      for (final type in MediaType.values) {
        typeCounts[type] = media.where((m) => m.type == type).length;
      }

      final totalSize = media.fold(0, (sum, m) => sum + m.fileSize);
      final totalLikes = media.fold(0, (sum, m) => sum + m.likesCount);

      return {
        'totalCount': totalCount,
        'publicCount': publicCount,
        'featuredCount': featuredCount,
        'typeCounts': typeCounts.map((k, v) => MapEntry(k.name, v)),
        'totalSize': totalSize,
        'totalLikes': totalLikes,
        'lastUpdated': media.isNotEmpty
            ? media
                .map((m) => m.updatedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      debugPrint('Error getting media stats: $e');
      return {};
    }
  }

  /// Поиск медиафайлов по тегам
  Stream<List<EventMedia>> searchMediaByTags(
          String eventId, List<String> tags,) =>
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .where('tags', arrayContainsAny: tags)
          .where('status', isEqualTo: MediaStatus.ready.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => EventMedia.fromMap({'id': doc.id, ...doc.data()}))
                .toList(),
          );

  /// Получить популярные теги мероприятия
  Future<List<String>> getPopularTags(String eventId) async {
    try {
      final mediaQuery = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('media')
          .where('status', isEqualTo: MediaStatus.ready.name)
          .get();

      final tagCounts = <String, int>{};

      for (final doc in mediaQuery.docs) {
        final tags = List<String>.from(doc.data()['tags'] ?? []);
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(10).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error getting popular tags: $e');
      return [];
    }
  }
}
