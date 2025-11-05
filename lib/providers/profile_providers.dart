import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для профиля пользователя
final userProfileProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  });
});

/// Провайдер для постов пользователя с пагинацией
final userPostsProvider = StreamProvider.family<List<DocumentSnapshot>, (String, int)>((ref, params) {
  final (uid, limit) = params;
  return FirebaseFirestore.instance
      .collection('posts')
      .where('authorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Провайдер для рилсов пользователя с пагинацией
final userReelsProvider = StreamProvider.family<List<DocumentSnapshot>, (String, int)>((ref, params) {
  final (uid, limit) = params;
  return FirebaseFirestore.instance
      .collection('reels')
      .where('authorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Провайдер для отзывов специалиста с пагинацией
final userReviewsProvider = StreamProvider.family<List<DocumentSnapshot>, (String, int)>((ref, params) {
  final (specialistId, limit) = params;
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Провайдер для среднего рейтинга специалиста
final userRatingProvider = FutureProvider.family<double, String>((ref, specialistId) async {
  final reviews = await FirebaseFirestore.instance
      .collection('reviews')
      .where('specialistId', isEqualTo: specialistId)
      .get();
  
  if (reviews.docs.isEmpty) return 0.0;
  
  final sum = reviews.docs.fold<double>(
    0.0,
    (sum, doc) => sum + ((doc.data()['rating'] as num? ?? 0).toDouble()),
  );
  
  return sum / reviews.docs.length;
});
