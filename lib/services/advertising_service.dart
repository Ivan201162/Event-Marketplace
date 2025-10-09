import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/advertisement.dart';
import '../models/pro_subscription.dart';

/// Сервис для работы с рекламой
class AdvertisingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать рекламное объявление
  Future<Advertisement> createAdvertisement({
    required String advertiserId,
    required AdvertisementType type,
    required String title,
    required String description,
    required String imageUrl,
    required String targetUrl,
    required double budget,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> targetAudience,
    String? videoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adId = _firestore.collection('advertisements').doc().id;
      final now = DateTime.now();

      final advertisement = Advertisement(
        id: adId,
        advertiserId: advertiserId,
        type: type,
        title: title,
        description: description,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        targetUrl: targetUrl,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience,
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('advertisements')
          .doc(adId)
          .set(advertisement.toMap());

      return advertisement;
    } catch (e) {
      throw Exception('Ошибка создания рекламы: $e');
    }
  }

  /// Получить рекламные объявления
  Future<List<Advertisement>> getAdvertisements({
    AdvertisementStatus? status,
    AdvertisementType? type,
    String? advertiserId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('advertisements');

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }
      if (advertiserId != null) {
        query = query.where('advertiserId', isEqualTo: advertiserId);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      final advertisements = <Advertisement>[];

      for (final doc in snapshot.docs) {
        final advertisement = Advertisement.fromMap(
          doc.data()! as Map<String, dynamic>,
        );
        advertisements.add(advertisement);
      }

      return advertisements;
    } catch (e) {
      throw Exception('Ошибка получения рекламы: $e');
    }
  }

  /// Получить рекламу для показа
  Future<List<Advertisement>> getAdvertisementsForDisplay({
    required String userId,
    required String context, // 'feed', 'ideas', 'search'
    int limit = 3,
  }) async {
    try {
      final now = DateTime.now();

      final QuerySnapshot snapshot = await _firestore
          .collection('advertisements')
          .where('status', isEqualTo: AdvertisementStatus.active.value)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .where('budget', isGreaterThan: 0)
          .orderBy('budget', descending: true)
          .limit(limit * 2) // Получаем больше для фильтрации
          .get();

      final availableAds = <Advertisement>[];

      for (final doc in snapshot.docs) {
        final advertisement = Advertisement.fromMap(
          doc.data()! as Map<String, dynamic>,
        );

        // Проверяем, подходит ли реклама для контекста
        if (_isAdSuitableForContext(advertisement, context)) {
          availableAds.add(advertisement);
        }
      }

      // Сортируем по релевантности и возвращаем лимит
      availableAds.sort((a, b) => _calculateRelevance(b, userId)
          .compareTo(_calculateRelevance(a, userId)));

      return availableAds.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекламы для показа: $e');
    }
  }

  /// Обновить рекламу
  Future<void> updateAdvertisement({
    required String adId,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? targetUrl,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    AdvertisementStatus? status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (videoUrl != null) updates['videoUrl'] = videoUrl;
      if (targetUrl != null) updates['targetUrl'] = targetUrl;
      if (budget != null) updates['budget'] = budget;
      if (startDate != null)
        updates['startDate'] = startDate.millisecondsSinceEpoch;
      if (endDate != null) updates['endDate'] = endDate.millisecondsSinceEpoch;
      if (targetAudience != null) updates['targetAudience'] = targetAudience;
      if (status != null) updates['status'] = status.value;
      if (metadata != null) updates['metadata'] = metadata;

      await _firestore.collection('advertisements').doc(adId).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления рекламы: $e');
    }
  }

  /// Удалить рекламу
  Future<void> deleteAdvertisement(String adId) async {
    try {
      await _firestore.collection('advertisements').doc(adId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления рекламы: $e');
    }
  }

  /// Зафиксировать показ рекламы
  Future<void> recordImpression({
    required String adId,
    required String userId,
    required String context,
  }) async {
    try {
      final now = DateTime.now();

      // Обновить статистику рекламы
      await _firestore.collection('advertisements').doc(adId).update({
        'impressions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Записать показ
      await _firestore.collection('ad_impressions').add({
        'adId': adId,
        'userId': userId,
        'context': context,
        'timestamp': now.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка записи показа: $e');
    }
  }

  /// Зафиксировать клик по рекламе
  Future<void> recordClick({
    required String adId,
    required String userId,
    required String context,
  }) async {
    try {
      final now = DateTime.now();

      // Обновить статистику рекламы
      await _firestore.collection('advertisements').doc(adId).update({
        'clicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Записать клик
      await _firestore.collection('ad_clicks').add({
        'adId': adId,
        'userId': userId,
        'context': context,
        'timestamp': now.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка записи клика: $e');
    }
  }

  /// Зафиксировать конверсию
  Future<void> recordConversion({
    required String adId,
    required String userId,
    required String context,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();

      // Обновить статистику рекламы
      await _firestore.collection('advertisements').doc(adId).update({
        'conversions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Записать конверсию
      await _firestore.collection('ad_conversions').add({
        'adId': adId,
        'userId': userId,
        'context': context,
        'value': value,
        'metadata': metadata ?? {},
        'timestamp': now.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка записи конверсии: $e');
    }
  }

  /// Получить статистику рекламы
  Future<Map<String, dynamic>> getAdvertisementStats(String adId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('advertisements').doc(adId).get();

      if (!doc.exists) {
        throw Exception('Реклама не найдена');
      }

      final data = doc.data()! as Map<String, dynamic>;
      final impressions = data['impressions'] as int? ?? 0;
      final clicks = data['clicks'] as int? ?? 0;
      final conversions = data['conversions'] as int? ?? 0;
      final budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
      final spentAmount = (data['spentAmount'] as num?)?.toDouble() ?? 0.0;

      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;
      final cpm = impressions > 0 ? (spentAmount / impressions) * 1000 : 0.0;
      final cpc = clicks > 0 ? spentAmount / clicks : 0.0;

      return {
        'impressions': impressions,
        'clicks': clicks,
        'conversions': conversions,
        'budget': budget,
        'spentAmount': spentAmount,
        'remainingBudget': budget - spentAmount,
        'ctr': ctr,
        'cpm': cpm,
        'cpc': cpc,
        'conversionRate': clicks > 0 ? (conversions / clicks) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Получить общую статистику рекламы
  Future<Map<String, dynamic>> getOverallStats() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('advertisements').get();

      var totalAds = 0;
      var activeAds = 0;
      var totalBudget = 0;
      var totalSpent = 0;
      var totalImpressions = 0;
      var totalClicks = 0;
      var totalConversions = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        totalAds++;

        final status = AdvertisementStatus.fromString(data['status'] as String);
        if (status == AdvertisementStatus.active) {
          activeAds++;
        }

        totalBudget += (data['budget'] as num?)?.toDouble() ?? 0.0;
        totalSpent += (data['spentAmount'] as num?)?.toDouble() ?? 0.0;
        totalImpressions += data['impressions'] as int? ?? 0;
        totalClicks += data['clicks'] as int? ?? 0;
        totalConversions += data['conversions'] as int? ?? 0;
      }

      final overallCtr =
          totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;
      final overallCpm =
          totalImpressions > 0 ? (totalSpent / totalImpressions) * 1000 : 0.0;
      final overallCpc = totalClicks > 0 ? totalSpent / totalClicks : 0.0;

      return {
        'totalAds': totalAds,
        'activeAds': activeAds,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'totalConversions': totalConversions,
        'overallCtr': overallCtr,
        'overallCpm': overallCpm,
        'overallCpc': overallCpc,
        'conversionRate':
            totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Ошибка получения общей статистики: $e');
    }
  }

  /// Проверить, подходит ли реклама для контекста
  bool _isAdSuitableForContext(Advertisement ad, String context) {
    // Простая логика фильтрации по контексту
    switch (context) {
      case 'feed':
        return ad.type == AdvertisementType.feed ||
            ad.type == AdvertisementType.banner;
      case 'ideas':
        return ad.type == AdvertisementType.ideas ||
            ad.type == AdvertisementType.banner;
      case 'search':
        return ad.type == AdvertisementType.search ||
            ad.type == AdvertisementType.banner;
      default:
        return true;
    }
  }

  /// Рассчитать релевантность рекламы для пользователя
  double _calculateRelevance(Advertisement ad, String userId) {
    // Простой алгоритм релевантности
    var relevance = 0;

    // Базовый рейтинг по бюджету
    relevance += ad.budget / 1000.0;

    // Бонус за высокий CTR
    relevance += ad.ctr * 0.1;

    // Штраф за низкий CTR
    if (ad.ctr < 1.0) {
      relevance -= 0.5;
    }

    return relevance;
  }

  /// Создать платеж за рекламу
  Future<Payment> createAdPayment({
    required double amount,
    required String currency,
    required String paymentMethodId,
  }) async {
    try {
      // Создать платеж в Stripe (заглушка)
      // TODO: Интегрировать с реальным Stripe API
      final paymentIntent = Payment(
        id: 'mock_payment_${DateTime.now().millisecondsSinceEpoch}',
        subscriptionId: 'mock_subscription',
        amount: amount,
        currency: currency,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
        paymentMethod: paymentMethodId,
        transactionId:
            'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
      );

      return paymentIntent;
    } catch (e) {
      throw Exception('Ошибка создания платежа: $e');
    }
  }

  /// Пополнить бюджет рекламы
  Future<void> topUpAdBudget({
    required String adId,
    required double amount,
    required String paymentMethodId,
  }) async {
    try {
      // Создать платеж
      final paymentIntent = await createAdPayment(
        amount: amount,
        currency: 'RUB',
        paymentMethodId: paymentMethodId,
      );

      if (paymentIntent.status != PaymentStatus.completed) {
        throw Exception('Платеж не был завершен');
      }

      // Обновить бюджет рекламы
      await _firestore.collection('advertisements').doc(adId).update({
        'budget': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка пополнения бюджета: $e');
    }
  }
}
