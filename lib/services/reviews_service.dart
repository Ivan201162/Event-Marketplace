import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ РѕС‚Р·С‹РІР°РјРё Рё СЂРµР№С‚РёРЅРіР°РјРё
class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Р”РѕР±Р°РІРёС‚СЊ РѕС‚Р·С‹РІ
  Future<String> addReview({
    required String specialistId,
    required String customerId,
    required String customerName,
    required double rating,
    required String text,
    List<String> photos = const [],
    String? bookingId,
    String? eventTitle,
    String? customerAvatar,
    String? specialistName,
  }) async {
    try {
      // Р’Р°Р»РёРґР°С†РёСЏ
      if (text.length < 20) {
        throw Exception('РћС‚Р·С‹РІ РґРѕР»Р¶РµРЅ СЃРѕРґРµСЂР¶Р°С‚СЊ РјРёРЅРёРјСѓРј 20 СЃРёРјРІРѕР»РѕРІ');
      }
      if (rating < 1 || rating > 5) {
        throw Exception('Р РµР№С‚РёРЅРі РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РѕС‚ 1 РґРѕ 5');
      }

      // РЎРѕР·РґР°РµРј РѕС‚Р·С‹РІ
      final review = Review(
        id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ Firestore
        specialistId: specialistId,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        text: text,
        date: DateTime.now(),
        photos: photos,
        responses: [],
        bookingId: bookingId,
        eventTitle: eventTitle,
        customerAvatar: customerAvatar,
        specialistName: specialistName,
        metadata: {},
      );

      // Р”РѕР±Р°РІР»СЏРµРј РІ Firestore
      final docRef = await _firestore.collection('reviews').add(review.toMap());

      // РћР±РЅРѕРІР»СЏРµРј СЂРµР№С‚РёРЅРі СЃРїРµС†РёР°Р»РёСЃС‚Р°
      await _updateSpecialistRating(specialistId);

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'add_review',
        parameters: {
          'specialist_id': specialistId,
          'rating': rating,
          'has_photos': photos.isNotEmpty,
          'text_length': text.length,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё РґРѕР±Р°РІР»РµРЅРёРё РѕС‚Р·С‹РІР°: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РѕС‚Р·С‹РІС‹ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<List<Review>> getSpecialistReviews(
    String specialistId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
    ReviewSortType sortType = ReviewSortType.newest,
    ReviewFilter? filter,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false);

      // РџСЂРёРјРµРЅСЏРµРј С„РёР»СЊС‚СЂС‹
      if (filter != null) {
        if (filter.minRating != null) {
          query = query.where('rating', isGreaterThanOrEqualTo: filter.minRating);
        }
        if (filter.hasPhotos) {
          query = query.where('photos', isNotEqualTo: []);
        }
      }

      // РџСЂРёРјРµРЅСЏРµРј СЃРѕСЂС‚РёСЂРѕРІРєСѓ
      switch (sortType) {
        case ReviewSortType.newest:
          query = query.orderBy('date', descending: true);
          break;
        case ReviewSortType.oldest:
          query = query.orderBy('date', descending: false);
          break;
        case ReviewSortType.highest:
          query = query.orderBy('rating', descending: true);
          break;
        case ReviewSortType.lowest:
          query = query.orderBy('rating', descending: false);
          break;
        case ReviewSortType.mostLiked:
          query = query.orderBy('likes', descending: true);
          break;
      }

      // РџР°РіРёРЅР°С†РёСЏ
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map(Review.fromDocument).toList();
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё РѕС‚Р·С‹РІРѕРІ: $e');
    }
  }

  /// Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ РѕС‚Р·С‹РІ
  Future<void> editReview({
    required String reviewId,
    required String text,
    double? rating,
    List<String>? photos,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final review = Review.fromDocument(reviewDoc);

      // РџСЂРѕРІРµСЂСЏРµРј, С‡С‚Рѕ РїСЂРѕС€Р»Рѕ РЅРµ Р±РѕР»РµРµ 24 С‡Р°СЃРѕРІ
      final hoursSinceCreation = DateTime.now().difference(review.date).inHours;
      if (hoursSinceCreation > 24) {
        throw Exception('РћС‚Р·С‹РІ РјРѕР¶РЅРѕ СЂРµРґР°РєС‚РёСЂРѕРІР°С‚СЊ С‚РѕР»СЊРєРѕ РІ С‚РµС‡РµРЅРёРµ 24 С‡Р°СЃРѕРІ');
      }

      // Р’Р°Р»РёРґР°С†РёСЏ
      if (text.length < 20) {
        throw Exception('РћС‚Р·С‹РІ РґРѕР»Р¶РµРЅ СЃРѕРґРµСЂР¶Р°С‚СЊ РјРёРЅРёРјСѓРј 20 СЃРёРјРІРѕР»РѕРІ');
      }
      if (rating != null && (rating < 1 || rating > 5)) {
        throw Exception('Р РµР№С‚РёРЅРі РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РѕС‚ 1 РґРѕ 5');
      }

      // РћР±РЅРѕРІР»СЏРµРј РѕС‚Р·С‹РІ
      await reviewRef.update({
        'text': text,
        if (rating != null) 'rating': rating,
        if (photos != null) 'photos': photos,
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });

      // РћР±РЅРѕРІР»СЏРµРј СЂРµР№С‚РёРЅРі СЃРїРµС†РёР°Р»РёСЃС‚Р°
      await _updateSpecialistRating(review.specialistId);

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'edit_review',
        parameters: {
          'review_id': reviewId,
          'specialist_id': review.specialistId,
          'hours_since_creation': hoursSinceCreation,
        },
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёРё РѕС‚Р·С‹РІР°: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ РѕС‚Р·С‹РІ
  Future<void> deleteReview(String reviewId) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final review = Review.fromDocument(reviewDoc);

      // РџСЂРѕРІРµСЂСЏРµРј, С‡С‚Рѕ РїСЂРѕС€Р»Рѕ РЅРµ Р±РѕР»РµРµ 24 С‡Р°СЃРѕРІ
      final hoursSinceCreation = DateTime.now().difference(review.date).inHours;
      if (hoursSinceCreation > 24) {
        throw Exception('РћС‚Р·С‹РІ РјРѕР¶РЅРѕ СѓРґР°Р»РёС‚СЊ С‚РѕР»СЊРєРѕ РІ С‚РµС‡РµРЅРёРµ 24 С‡Р°СЃРѕРІ');
      }

      // РџРѕРјРµС‡Р°РµРј РєР°Рє СѓРґР°Р»РµРЅРЅС‹Р№
      await reviewRef.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // РћР±РЅРѕРІР»СЏРµРј СЂРµР№С‚РёРЅРі СЃРїРµС†РёР°Р»РёСЃС‚Р°
      await _updateSpecialistRating(review.specialistId);

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'delete_review',
        parameters: {
          'review_id': reviewId,
          'specialist_id': review.specialistId,
          'hours_since_creation': hoursSinceCreation,
        },
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё СѓРґР°Р»РµРЅРёРё РѕС‚Р·С‹РІР°: $e');
    }
  }

  /// РџРѕСЃС‚Р°РІРёС‚СЊ Р»Р°Р№Рє РѕС‚Р·С‹РІСѓ
  Future<void> likeReview(
    String reviewId,
    String userId,
    String userName,
  ) async {
    try {
      final likeRef =
          _firestore.collection('reviews').doc(reviewId).collection('likes').doc(userId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // РЈР±РёСЂР°РµРј Р»Р°Р№Рє
        await likeRef.delete();
        await _firestore.collection('reviews').doc(reviewId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // РЎС‚Р°РІРёРј Р»Р°Р№Рє
        await likeRef.set(
          ReviewLike(
            userId: userId,
            userName: userName,
            date: DateTime.now(),
          ).toMap(),
        );
        await _firestore.collection('reviews').doc(reviewId).update({
          'likes': FieldValue.increment(1),
        });
      }

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'like_review',
        parameters: {
          'review_id': reviewId,
          'user_id': userId,
        },
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё Р»Р°Р№РєРµ РѕС‚Р·С‹РІР°: $e');
    }
  }

  /// РћС‚РІРµС‚РёС‚СЊ РЅР° РѕС‚Р·С‹РІ
  Future<void> respondToReview({
    required String reviewId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final response = ReviewResponse(
        authorId: authorId,
        authorName: authorName,
        text: text,
        date: DateTime.now(),
      );

      // Р”РѕР±Р°РІР»СЏРµРј РѕС‚РІРµС‚
      await reviewRef.update({
        'responses': FieldValue.arrayUnion([response.toMap()]),
      });

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'respond_review',
        parameters: {
          'review_id': reviewId,
          'author_id': authorId,
        },
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё РѕС‚РІРµС‚Рµ РЅР° РѕС‚Р·С‹РІ: $e');
    }
  }

  /// РџРѕР¶Р°Р»РѕРІР°С‚СЊСЃСЏ РЅР° РѕС‚Р·С‹РІ
  Future<void> reportReview({
    required String reviewId,
    required String reporterId,
    required String reporterName,
    required ReviewReportReason reason,
    String? description,
  }) async {
    try {
      final report = ReviewReport(
        id: '',
        reviewId: reviewId,
        reporterId: reporterId,
        reporterName: reporterName,
        reason: reason.value,
        description: description,
        date: DateTime.now(),
      );

      // Р”РѕР±Р°РІР»СЏРµРј Р¶Р°Р»РѕР±Сѓ
      await _firestore.collection('review_reports').add(report.toMap());

      // РЈРІРµР»РёС‡РёРІР°РµРј СЃС‡РµС‚С‡РёРє Р¶Р°Р»РѕР±
      await _firestore.collection('reviews').doc(reviewId).update({
        'reportCount': FieldValue.increment(1),
        'isReported': true,
      });

      // Р›РѕРіРёСЂСѓРµРј СЃРѕР±С‹С‚РёРµ
      await _analytics.logEvent(
        name: 'report_review',
        parameters: {
          'review_id': reviewId,
          'reporter_id': reporterId,
          'reason': reason.value,
        },
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё Р¶Р°Р»РѕР±Рµ РЅР° РѕС‚Р·С‹РІ: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЂРµРїСѓС‚Р°С†РёСЋ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<SpecialistReputation> getSpecialistReputation(
    String specialistId,
  ) async {
    try {
      final doc = await _firestore.collection('userStats').doc(specialistId).get();

      if (doc.exists) {
        return SpecialistReputation.fromMap(doc.data()!);
      } else {
        // РЎРѕР·РґР°РµРј РЅРѕРІСѓСЋ Р·Р°РїРёСЃСЊ СЂРµРїСѓС‚Р°С†РёРё
        return SpecialistReputation(
          specialistId: specialistId,
          ratingAverage: 0,
          reviewsCount: 0,
          positiveReviews: 0,
          negativeReviews: 0,
          reputationScore: 0,
          status: ReputationStatus.needsExperience,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СЂРµРїСѓС‚Р°С†РёРё: $e');
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЂРµР№С‚РёРЅРі СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµ РѕС‚Р·С‹РІС‹ СЃРїРµС†РёР°Р»РёСЃС‚Р°
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return;
      }

      final reviews = reviewsSnapshot.docs.map(Review.fromDocument).toList();

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      final totalReviews = reviews.length;
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / totalReviews;

      final positiveReviews = reviews.where((r) => r.rating >= 4).length;
      final negativeReviews = reviews.where((r) => r.rating <= 2).length;

      final reputationScore = SpecialistReputation.calculateReputationScore(
        positiveReviews,
        negativeReviews,
      );

      final status = SpecialistReputation.getReputationStatus(reputationScore);

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      final reputation = SpecialistReputation(
        specialistId: specialistId,
        ratingAverage: averageRating,
        reviewsCount: totalReviews,
        positiveReviews: positiveReviews,
        negativeReviews: negativeReviews,
        reputationScore: reputationScore,
        status: status,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('userStats')
          .doc(specialistId)
          .set(reputation.toMap(), SetOptions(merge: true));

      // РћР±РЅРѕРІР»СЏРµРј СЂРµР№С‚РёРЅРі РІ РїСЂРѕС„РёР»Рµ СЃРїРµС†РёР°Р»РёСЃС‚Р°
      await _firestore.collection('specialists').doc(specialistId).update({
        'rating': averageRating,
        'reviewCount': totalReviews,
        'reputationScore': reputationScore,
        'reputationStatus': status.value,
      });
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРё РѕР±РЅРѕРІР»РµРЅРёРё СЂРµР№С‚РёРЅРіР°: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРёС‚СЊ С„РёР»СЊС‚СЂС‹ РѕС‚Р·С‹РІРѕРІ
  Future<void> saveReviewFilters(ReviewFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_filters', filter.toJson());
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ С„РёР»СЊС‚СЂС‹ РѕС‚Р·С‹РІРѕРІ
  Future<ReviewFilter?> loadReviewFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filtersJson = prefs.getString('review_filters');
    if (filtersJson != null) {
      return ReviewFilter.fromJson(filtersJson);
    }
    return null;
  }

  /// РЎРѕС…СЂР°РЅРёС‚СЊ С‚РёРї СЃРѕСЂС‚РёСЂРѕРІРєРё РѕС‚Р·С‹РІРѕРІ
  Future<void> saveReviewSortType(ReviewSortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_sort_type', sortType.name);
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ С‚РёРї СЃРѕСЂС‚РёСЂРѕРІРєРё РѕС‚Р·С‹РІРѕРІ
  Future<ReviewSortType> loadReviewSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final sortTypeName = prefs.getString('review_sort_type');
    if (sortTypeName != null) {
      return ReviewSortType.values.firstWhere(
        (type) => type.name == sortTypeName,
        orElse: () => ReviewSortType.newest,
      );
    }
    return ReviewSortType.newest;
  }
}

/// РўРёРїС‹ СЃРѕСЂС‚РёСЂРѕРІРєРё РѕС‚Р·С‹РІРѕРІ
enum ReviewSortType {
  newest('newest', 'РЎРЅР°С‡Р°Р»Р° РЅРѕРІС‹Рµ'),
  oldest('oldest', 'РЎРЅР°С‡Р°Р»Р° СЃС‚Р°СЂС‹Рµ'),
  highest('highest', 'РЎРЅР°С‡Р°Р»Р° Р»СѓС‡С€РёРµ'),
  lowest('lowest', 'РЎРЅР°С‡Р°Р»Р° С…СѓРґС€РёРµ'),
  mostLiked('most_liked', 'Р‘РѕР»СЊС€Рµ Р»Р°Р№РєРѕРІ');

  const ReviewSortType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Р¤РёР»СЊС‚СЂ РѕС‚Р·С‹РІРѕРІ
class ReviewFilter {
  const ReviewFilter({
    this.minRating,
    this.hasPhotos = false,
    this.fromDate,
    this.toDate,
  });

  factory ReviewFilter.fromJson(String json) {
    // РџСЂРѕСЃС‚Р°СЏ СЂРµР°Р»РёР·Р°С†РёСЏ РїР°СЂСЃРёРЅРіР° JSON
    final hasPhotos = json.contains('"hasPhotos": true');
    final minRatingMatch = RegExp(r'"minRating": (\d+(?:\.\d+)?)').firstMatch(json);
    final minRating = minRatingMatch != null ? double.tryParse(minRatingMatch.group(1)!) : null;

    return ReviewFilter(
      minRating: minRating,
      hasPhotos: hasPhotos,
    );
  }
  final double? minRating;
  final bool hasPhotos;
  final DateTime? fromDate;
  final DateTime? toDate;

  String toJson() => '''
    {
      "minRating": ${minRating ?? 'null'},
      "hasPhotos": $hasPhotos,
      "fromDate": ${fromDate?.millisecondsSinceEpoch ?? 'null'},
      "toDate": ${toDate?.millisecondsSinceEpoch ?? 'null'}
    }
    ''';
}

