import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/review_extended.dart';

/// Сервис для работы с расширенными отзывами
class ReviewExtendedService {
  factory ReviewExtendedService() => _instance;
  ReviewExtendedService._internal();
  static final ReviewExtendedService _instance =
      ReviewExtendedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Создать расширенный отзыв
  Future<String?> createReview({
    required String specialistId,
    required String customerId,
    required String customerName,
    required String customerPhotoUrl,
    required String bookingId,
    required int rating,
    required String comment,
    List<ReviewMedia>? media,
    List<String>? tags,
    ReviewStats? stats,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews_extended').doc();

      final review = ReviewExtended(
        id: reviewRef.id,
        specialistId: specialistId,
        customerId: customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        media: media ?? [],
        tags: tags ?? [],
        stats: stats ?? const ReviewStats(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await reviewRef.set(review.toMap());
      return reviewRef.id;
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      return null;
    }
  }

  /// Получить отзывы специалиста
  Stream<List<ReviewExtended>> getSpecialistReviews(
    String specialistId,
    ReviewFilter filter,
  ) {
    var query = _firestore
        .collection('reviews_extended')
        .where('specialistId', isEqualTo: specialistId)
        .where('isApproved', isEqualTo: true);

    // Применяем фильтры
    if (filter.minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: filter.minRating);
    }

    if (filter.maxRating != null) {
      query = query.where('rating', isLessThanOrEqualTo: filter.maxRating);
    }

    if (filter.hasMedia != null && filter.hasMedia!) {
      // Фильтр по наличию медиа будет применен в коде
    }

    if (filter.isVerified != null) {
      query = query.where('isVerified', isEqualTo: filter.isVerified);
    }

    if (filter.startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
      );
    }

    if (filter.endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!),
      );
    }

    // Сортировка
    switch (filter.sortBy) {
      case ReviewSortBy.date:
        query = query.orderBy('createdAt', descending: !filter.sortAscending);
        break;
      case ReviewSortBy.rating:
        query = query.orderBy('rating', descending: !filter.sortAscending);
        break;
      case ReviewSortBy.likes:
        query = query.orderBy(
          'stats.likesCount',
          descending: !filter.sortAscending,
        );
        break;
      case ReviewSortBy.helpfulness:
        query = query.orderBy(
          'stats.helpfulnessScore',
          descending: !filter.sortAscending,
        );
        break;
    }

    return query.snapshots().map((snapshot) {
      var reviews = snapshot.docs.map(ReviewExtended.fromDocument).toList();

      // Применяем фильтры, которые нельзя применить в Firestore
      if (filter.hasMedia != null) {
        reviews = reviews
            .where(
              (review) => filter.hasMedia!
                  ? review.media.isNotEmpty
                  : review.media.isEmpty,
            )
            .toList();
      }

      if (filter.tags != null && filter.tags!.isNotEmpty) {
        reviews = reviews
            .where(
              (review) => review.tags.any((tag) => filter.tags!.contains(tag)),
            )
            .toList();
      }

      return reviews;
    });
  }

  /// Получить отзыв по ID
  Future<ReviewExtended?> getReview(String reviewId) async {
    try {
      final doc =
          await _firestore.collection('reviews_extended').doc(reviewId).get();
      if (doc.exists) {
        return ReviewExtended.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения отзыва: $e');
      return null;
    }
  }

  /// Обновить отзыв
  Future<bool> updateReview(ReviewExtended review) async {
    try {
      await _firestore
          .collection('reviews_extended')
          .doc(review.id)
          .update(review.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления отзыва: $e');
      return false;
    }
  }

  /// Удалить отзыв
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews_extended').doc(reviewId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления отзыва: $e');
      return false;
    }
  }

  /// Добавить лайк к отзыву
  Future<bool> likeReview(
    String reviewId,
    String userId,
    String userName,
    String userPhotoUrl,
  ) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      // Проверяем, не лайкнул ли уже пользователь
      if (review.isLikedBy(userId)) {
        return await unlikeReview(reviewId, userId);
      }

      final like = ReviewLike(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        createdAt: DateTime.now(),
      );

      final updatedLikes = [...review.likes, like];
      final updatedStats =
          review.stats.copyWith(likesCount: updatedLikes.length);

      final updatedReview = review.copyWith(
        likes: updatedLikes,
        stats: updatedStats,
        updatedAt: DateTime.now(),
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка добавления лайка: $e');
      return false;
    }
  }

  /// Убрать лайк с отзыва
  Future<bool> unlikeReview(String reviewId, String userId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      final updatedLikes =
          review.likes.where((like) => like.userId != userId).toList();
      final updatedStats =
          review.stats.copyWith(likesCount: updatedLikes.length);

      final updatedReview = review.copyWith(
        likes: updatedLikes,
        stats: updatedStats,
        updatedAt: DateTime.now(),
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка удаления лайка: $e');
      return false;
    }
  }

  /// Добавить медиа к отзыву
  Future<bool> addMediaToReview(
    String reviewId,
    List<ReviewMedia> media,
  ) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      final updatedMedia = [...review.media, ...media];
      final updatedReview = review.copyWith(
        media: updatedMedia,
        updatedAt: DateTime.now(),
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка добавления медиа: $e');
      return false;
    }
  }

  /// Удалить медиа из отзыва
  Future<bool> removeMediaFromReview(String reviewId, String mediaId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      final updatedMedia = review.media.where((m) => m.id != mediaId).toList();
      final updatedReview = review.copyWith(
        media: updatedMedia,
        updatedAt: DateTime.now(),
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка удаления медиа: $e');
      return false;
    }
  }

  /// Загрузить фото
  Future<ReviewMedia?> uploadPhoto(XFile imageFile) async {
    try {
      final fileName =
          'review_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('review_photos/$fileName');

      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return ReviewMedia(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: downloadUrl,
        thumbnailUrl: downloadUrl, // Для фото thumbnail = оригинал
        type: MediaType.photo,
        fileName: fileName,
        fileSize: await File(imageFile.path).length(),
      );
    } catch (e) {
      print('Ошибка загрузки фото: $e');
      return null;
    }
  }

  /// Загрузить видео
  Future<ReviewMedia?> uploadVideo(XFile videoFile) async {
    try {
      final fileName =
          'review_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('review_videos/$fileName');

      final uploadTask = ref.putFile(File(videoFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем thumbnail для видео
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: '/tmp',
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      String? thumbnailUrl;
      if (thumbnailPath != null) {
        final thumbnailRef = _storage
            .ref()
            .child('review_videos/thumbnails/${fileName}_thumb.jpg');
        final thumbnailUploadTask = thumbnailRef.putFile(File(thumbnailPath));
        final thumbnailSnapshot = await thumbnailUploadTask;
        thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
      }

      return ReviewMedia(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: downloadUrl,
        thumbnailUrl: thumbnailUrl ?? downloadUrl,
        type: MediaType.video,
        fileName: fileName,
        fileSize: await File(videoFile.path).length(),
        duration: await _getVideoDuration(videoFile.path),
      );
    } catch (e) {
      print('Ошибка загрузки видео: $e');
      return null;
    }
  }

  /// Получить длительность видео
  Future<Duration?> _getVideoDuration(String videoPath) async {
    try {
      // TODO: Реализовать получение длительности видео
      return null;
    } catch (e) {
      print('Ошибка получения длительности видео: $e');
      return null;
    }
  }

  /// Выбрать фото из галереи
  Future<List<XFile>> pickPhotos({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images.take(maxImages).toList();
    } catch (e) {
      print('Ошибка выбора фото: $e');
      return [];
    }
  }

  /// Выбрать видео из галереи
  Future<XFile?> pickVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Ошибка выбора видео: $e');
      return null;
    }
  }

  /// Снять фото
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print('Ошибка съемки фото: $e');
      return null;
    }
  }

  /// Снять видео
  Future<XFile?> takeVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Ошибка съемки видео: $e');
      return null;
    }
  }

  /// Получить статистику отзывов специалиста
  Future<SpecialistReviewStats> getSpecialistReviewStats(
    String specialistId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('reviews_extended')
          .where('specialistId', isEqualTo: specialistId)
          .where('isApproved', isEqualTo: true)
          .get();

      final reviews = snapshot.docs.map(ReviewExtended.fromDocument).toList();

      if (reviews.isEmpty) {
        return SpecialistReviewStats.empty();
      }

      // Подсчитываем статистику
      var totalRating = 0;
      final int totalReviews = reviews.length;
      final ratingDistribution = <int, int>{};
      var totalLikes = 0;
      var totalViews = 0;
      var totalHelpfulness = 0;
      final tagCounts = <String, int>{};
      final categoryRatings = <String, List<double>>{};

      for (final review in reviews) {
        totalRating += review.rating;
        ratingDistribution[review.rating] =
            (ratingDistribution[review.rating] ?? 0) + 1;
        totalLikes += review.likesCount;
        totalViews += review.stats.viewsCount;
        totalHelpfulness += review.stats.helpfulnessScore;

        // Подсчитываем теги
        for (final tag in review.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }

        // Подсчитываем рейтинги по категориям
        if (review.stats.quality > 0) {
          categoryRatings['quality'] = (categoryRatings['quality'] ?? [])
            ..add(review.stats.quality);
        }
        if (review.stats.communication > 0) {
          categoryRatings['communication'] =
              (categoryRatings['communication'] ?? [])
                ..add(review.stats.communication);
        }
        if (review.stats.punctuality > 0) {
          categoryRatings['punctuality'] = (categoryRatings['punctuality'] ??
              [])
            ..add(review.stats.punctuality);
        }
        if (review.stats.value > 0) {
          categoryRatings['value'] = (categoryRatings['value'] ?? [])
            ..add(review.stats.value);
        }
      }

      final averageRating = totalRating / totalReviews;
      final averageHelpfulness = totalHelpfulness / totalReviews;

      // Топ теги
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTags = sortedTags.take(5).map((e) => e.key).toList();

      // Средние рейтинги по категориям
      final averageCategoryRatings = <String, double>{};
      for (final entry in categoryRatings.entries) {
        final average =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        averageCategoryRatings[entry.key] = average;
      }

      return SpecialistReviewStats(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        totalLikes: totalLikes,
        totalViews: totalViews,
        averageHelpfulness: averageHelpfulness,
        topTags: topTags,
        categoryRatings: averageCategoryRatings,
      );
    } catch (e) {
      print('Ошибка получения статистики отзывов: $e');
      return SpecialistReviewStats.empty();
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViewsCount(String reviewId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return;

      final updatedStats = review.stats.copyWith(
        viewsCount: review.stats.viewsCount + 1,
      );

      final updatedReview = review.copyWith(
        stats: updatedStats,
        updatedAt: DateTime.now(),
      );

      await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка увеличения счетчика просмотров: $e');
    }
  }

  /// Поделиться отзывом
  Future<void> shareReview(String reviewId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return;

      final updatedStats = review.stats.copyWith(
        sharesCount: review.stats.sharesCount + 1,
      );

      final updatedReview = review.copyWith(
        stats: updatedStats,
        updatedAt: DateTime.now(),
      );

      await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка увеличения счетчика репостов: $e');
    }
  }

  /// Пожаловаться на отзыв
  Future<bool> reportReview(
    String reviewId,
    String reason,
    String reporterId,
  ) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      final updatedStats = review.stats.copyWith(
        reportsCount: review.stats.reportsCount + 1,
      );

      final updatedReview = review.copyWith(
        stats: updatedStats,
        updatedAt: DateTime.now(),
        metadata: {
          ...review.metadata,
          'reports': [
            ...(review.metadata['reports'] as List<dynamic>? ?? []),
            {
              'reporterId': reporterId,
              'reason': reason,
              'reportedAt': DateTime.now().toIso8601String(),
            }
          ],
        },
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка жалобы на отзыв: $e');
      return false;
    }
  }

  /// Модерировать отзыв
  Future<bool> moderateReview(
    String reviewId,
    bool approved,
    String? comment,
    String moderatorId,
  ) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return false;

      final updatedReview = review.copyWith(
        isModerated: true,
        isApproved: approved,
        moderationComment: comment,
        updatedAt: DateTime.now(),
        metadata: {
          ...review.metadata,
          'moderatedBy': moderatorId,
          'moderatedAt': DateTime.now().toIso8601String(),
        },
      );

      return await updateReview(updatedReview);
    } catch (e) {
      print('Ошибка модерации отзыва: $e');
      return false;
    }
  }
}
