import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Сервис для работы с отзывами 2.0 (только после подтверждённых броней)
class ReviewServiceV2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Проверить, есть ли подтверждённое бронирование между клиентом и специалистом
  Future<bool> hasConfirmedBooking(String clientId, String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.accepted.value)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking confirmed booking: $e');
      return false;
    }
  }

  /// Загрузить фото отзыва
  Future<List<String>> uploadReviewPhotos(String reviewId, List<String> photoPaths) async {
    final uploadedUrls = <String>[];
    
    for (int i = 0; i < photoPaths.length; i++) {
      try {
        final file = photoPaths[i];
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('uploads/reviews/$reviewId/$fileName');
        
        // Загружаем файл (предполагаем, что это путь к файлу)
        // В реальности нужно использовать File или XFile
        // final uploadTask = ref.putFile(File(file));
        // final snapshot = await uploadTask;
        // final url = await snapshot.ref.getDownloadURL();
        // uploadedUrls.add(url);
        
        // Заглушка - в реальности нужно загружать файлы
        debugPrint('Upload photo: $file -> reviews/$reviewId/$fileName');
      } catch (e) {
        debugPrint('Error uploading photo: $e');
      }
    }
    
    return uploadedUrls;
  }

  /// Создать отзыв (только если есть confirmed booking)
  Future<String> createReview({
    required String specialistId,
    required int rating,
    required String text,
    List<String>? photos,
    String? reply,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Валидация
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }
      if (text.trim().length < 5) {
        throw Exception('Text must be at least 5 characters');
      }

      // Проверка наличия confirmed booking
      final hasBooking = await hasConfirmedBooking(user.uid, specialistId);
      if (!hasBooking) {
        debugLog("REVIEW_ADD_ERR:no_confirmed_booking");
        throw Exception('You can only leave a review after a confirmed booking');
      }

      // Загружаем фото (если есть)
      List<String> photoUrls = [];
      if (photos != null && photos.isNotEmpty) {
        final reviewId = _firestore.collection('reviews').doc().id;
        photoUrls = await uploadReviewPhotos(reviewId, photos);
      }

      // Создаём отзыв
      final reviewData = {
        'specialistId': specialistId,
        'authorId': user.uid,
        'rating': rating,
        'text': text.trim(),
        'photos': photoUrls,
        'reply': reply != null ? {
          'text': reply,
          'createdAt': FieldValue.serverTimestamp(),
        } : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('reviews').add(reviewData);

      // Обновляем рейтинг специалиста
      await _updateSpecialistRating(specialistId);

      debugLog("REVIEW_ADD_OK:${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating review: $e');
      debugLog("REVIEW_ADD_ERR:${e.toString()}");
      rethrow;
    }
  }

  /// Получить отзывы специалиста
  Stream<List<Map<String, dynamic>>> getReviewsBySpecialist(
    String specialistId, {
    String? sortBy, // 'newest', 'highest', 'with_photos'
  }) {
    Query query = _firestore
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId);

    switch (sortBy) {
      case 'highest':
        query = query.orderBy('rating', descending: true);
        break;
      case 'with_photos':
        // Фильтр по наличию фото делается на клиенте
        break;
      case 'newest':
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      final reviews = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Фильтр "только с фото" на клиенте
      if (sortBy == 'with_photos') {
        return reviews.where((r) {
          final photos = r['photos'] as List?;
          return photos != null && photos.isNotEmpty;
        }).toList();
      }

      return reviews;
    });
  }

  /// Обновить рейтинг специалиста
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        await _firestore.collection('users').doc(specialistId).update({
          'rating': 0.0,
          'ratingCount': 0,
        });
        return;
      }

      double totalRating = 0;
      int count = 0;

      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 0;
        totalRating += rating;
        count++;
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;

      await _firestore.collection('users').doc(specialistId).update({
        'rating': averageRating,
        'ratingCount': count,
      });
    } catch (e) {
      debugPrint('Error updating specialist rating: $e');
    }
  }

  /// Добавить ответ специалиста на отзыв
  Future<void> addReply(String reviewId, String replyText) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) throw Exception('Review not found');

      final reviewData = reviewDoc.data()!;
      if (reviewData['specialistId'] != user.uid) {
        throw Exception('Only specialist can reply to their reviews');
      }

      await _firestore.collection('reviews').doc(reviewId).update({
        'reply': {
          'text': replyText,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
      rethrow;
    }
  }
}

