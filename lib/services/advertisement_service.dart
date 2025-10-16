import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/advertisement.dart';
import '../models/transaction.dart' as transaction_model;
import '../services/payment_service.dart';

class AdvertisementService {
  static final AdvertisementService _instance =
      AdvertisementService._internal();
  factory AdvertisementService() => _instance;
  AdvertisementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  /// Получение всех активных рекламных кампаний
  Future<List<AdCampaign>> getActiveCampaigns() async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Получение активных рекламных кампаний');

      final snapshot = await _firestore
          .collection('ad_campaigns')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => AdCampaign.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка получения кампаний: $e');
      return [];
    }
  }

  /// Получение рекламных кампаний пользователя
  Future<List<AdCampaign>> getUserCampaigns(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ad_campaigns')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdCampaign.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка получения кампаний пользователя: $e');
      return [];
    }
  }

  /// Получение активных рекламных объявлений
  Future<List<Advertisement>> getActiveAdvertisements({
    AdType? type,
    AdPlacement? placement,
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Получение активных рекламных объявлений');

      Query query = _firestore
          .collection('advertisements')
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()));

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (placement != null) {
        query = query.where('placement',
            isEqualTo: placement.toString().split('.').last);
      }

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => Advertisement.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка получения рекламных объявлений: $e');
      return [];
    }
  }

  /// Создание рекламной кампании
  Future<String?> createCampaign({
    required String userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    String? description,
    String? targetAudience,
    String? region,
    String? city,
    String? category,
  }) async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Создание рекламной кампании для пользователя $userId');

      final campaign = AdCampaign(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        isActive: true,
        description: description,
        targetAudience: targetAudience,
        region: region,
        city: city,
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('ad_campaigns')
          .doc(campaign.id)
          .set(campaign.toMap());

      debugPrint(
          'INFO: [advertisement_service] Рекламная кампания успешно создана');
      return campaign.id;
    } catch (e) {
      debugPrint('ERROR: [advertisement_service] Ошибка создания кампании: $e');
      return null;
    }
  }

  /// Создание рекламного объявления
  Future<String?> createAdvertisement({
    required String userId,
    required AdType type,
    required AdPlacement placement,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    String? title,
    String? description,
    String? contentUrl,
    String? imageUrl,
    String? videoUrl,
    String? targetUrl,
    String? region,
    String? city,
    String? category,
    String? targetAudience,
    double? budget,
    String? campaignId,
  }) async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Создание рекламного объявления для пользователя $userId');

      final advertisement = Advertisement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        placement: placement,
        startDate: startDate,
        endDate: endDate,
        status: AdStatus.pending,
        price: price,
        title: title,
        description: description,
        contentUrl: contentUrl,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        targetUrl: targetUrl,
        region: region,
        city: city,
        category: category,
        targetAudience: targetAudience,
        budget: budget,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: campaignId != null ? {'campaignId': campaignId} : null,
      );

      await _firestore
          .collection('advertisements')
          .doc(advertisement.id)
          .set(advertisement.toMap());

      debugPrint(
          'INFO: [advertisement_service] Рекламное объявление успешно создано');
      return advertisement.id;
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка создания объявления: $e');
      return null;
    }
  }

  /// Покупка рекламы
  Future<PaymentResult> purchaseAdvertisement({
    required String userId,
    required String adId,
    required PaymentMethod paymentMethod,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Покупка рекламы $adId для пользователя $userId');

      // Получаем рекламное объявление
      final doc = await _firestore.collection('advertisements').doc(adId).get();

      if (!doc.exists) {
        return PaymentResult(
          success: false,
          errorMessage: 'Рекламное объявление не найдено',
        );
      }

      final ad = Advertisement.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      // Создаем платеж
      final paymentResult = await _paymentService.createAdvertisementPayment(
        userId: userId,
        ad: ad,
        paymentMethod: paymentMethod,
        provider: provider,
      );

      if (paymentResult.success) {
        // Создаем транзакцию
        final transaction = transaction_model.Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: transaction_model.TransactionType.advertisement,
          amount: ad.price,
          currency: 'RUB',
          status: transaction_model.TransactionStatus.pending,
          timestamp: DateTime.now(),
          description: 'Реклама ${ad.title ?? 'Без названия'}',
          adId: adId,
          paymentMethod: paymentMethod.toString().split('.').last,
          paymentProvider: provider.toString().split('.').last,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );

        // Сохраняем транзакцию
        await _firestore
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toMap());

        return PaymentResult(
          success: true,
          transactionId: transaction.id,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );
      }

      return paymentResult;
    } catch (e) {
      debugPrint('ERROR: [advertisement_service] Ошибка покупки рекламы: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Активация рекламы после успешной оплаты
  Future<bool> activateAdvertisement({
    required String adId,
    required String transactionId,
  }) async {
    try {
      debugPrint('INFO: [advertisement_service] Активация рекламы $adId');

      // Активируем рекламу
      await _firestore.collection('advertisements').doc(adId).update({
        'status': AdStatus.active.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем статус транзакции
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'success',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('INFO: [advertisement_service] Реклама успешно активирована');
      return true;
    } catch (e) {
      debugPrint('ERROR: [advertisement_service] Ошибка активации рекламы: $e');
      return false;
    }
  }

  /// Пауза рекламы
  Future<bool> pauseAdvertisement(String adId) async {
    try {
      debugPrint('INFO: [advertisement_service] Пауза рекламы $adId');

      await _firestore.collection('advertisements').doc(adId).update({
        'status': AdStatus.paused.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint(
          'INFO: [advertisement_service] Реклама успешно поставлена на паузу');
      return true;
    } catch (e) {
      debugPrint('ERROR: [advertisement_service] Ошибка паузы рекламы: $e');
      return false;
    }
  }

  /// Возобновление рекламы
  Future<bool> resumeAdvertisement(String adId) async {
    try {
      debugPrint('INFO: [advertisement_service] Возобновление рекламы $adId');

      await _firestore.collection('advertisements').doc(adId).update({
        'status': AdStatus.active.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('INFO: [advertisement_service] Реклама успешно возобновлена');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка возобновления рекламы: $e');
      return false;
    }
  }

  /// Отклонение рекламы
  Future<bool> rejectAdvertisement(String adId, String reason) async {
    try {
      debugPrint('INFO: [advertisement_service] Отклонение рекламы $adId');

      await _firestore.collection('advertisements').doc(adId).update({
        'status': AdStatus.rejected.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'rejectionReason': reason,
        },
      });

      debugPrint('INFO: [advertisement_service] Реклама успешно отклонена');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка отклонения рекламы: $e');
      return false;
    }
  }

  /// Обновление статистики рекламы
  Future<bool> updateAdvertisementStats({
    required String adId,
    int? impressions,
    int? clicks,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (impressions != null) {
        updateData['impressions'] = FieldValue.increment(impressions);
      }

      if (clicks != null) {
        updateData['clicks'] = FieldValue.increment(clicks);
      }

      // Пересчитываем CTR, CPC, CPM
      if (impressions != null || clicks != null) {
        final doc =
            await _firestore.collection('advertisements').doc(adId).get();

        if (doc.exists) {
          final data = doc.data()!;
          final currentImpressions =
              (data['impressions'] as int? ?? 0) + (impressions ?? 0);
          final currentClicks = (data['clicks'] as int? ?? 0) + (clicks ?? 0);
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;

          if (currentImpressions > 0) {
            updateData['ctr'] = (currentClicks / currentImpressions) * 100;
            updateData['cpm'] = (price / currentImpressions) * 1000;
          }

          if (currentClicks > 0) {
            updateData['cpc'] = price / currentClicks;
          }
        }
      }

      await _firestore
          .collection('advertisements')
          .doc(adId)
          .update(updateData);

      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка обновления статистики: $e');
      return false;
    }
  }

  /// Проверка истечения рекламы
  Future<void> checkExpiredAdvertisements() async {
    try {
      debugPrint('INFO: [advertisement_service] Проверка истекшей рекламы');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('advertisements')
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': AdStatus.expired.toString().split('.').last,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();

      debugPrint(
          'INFO: [advertisement_service] Обработано ${snapshot.docs.length} истекших рекламных объявлений');
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка проверки истекшей рекламы: $e');
    }
  }

  /// Получение рекламы для отображения
  Future<List<Advertisement>> getAdvertisementsForDisplay({
    required AdPlacement placement,
    String? region,
    String? city,
    String? category,
    int limit = 5,
  }) async {
    try {
      debugPrint(
          'INFO: [advertisement_service] Получение рекламы для отображения в $placement');

      Query query = _firestore
          .collection('advertisements')
          .where('status', isEqualTo: 'active')
          .where('placement', isEqualTo: placement.toString().split('.').last)
          .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()));

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => Advertisement.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка получения рекламы для отображения: $e');
      return [];
    }
  }

  /// Получение статистики рекламы
  Future<Map<String, dynamic>> getAdvertisementStats() async {
    try {
      final snapshot = await _firestore.collection('advertisements').get();

      int activeCount = 0;
      int expiredCount = 0;
      int pausedCount = 0;
      int rejectedCount = 0;
      double totalRevenue = 0.0;
      int totalImpressions = 0;
      int totalClicks = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final impressions = data['impressions'] as int? ?? 0;
        final clicks = data['clicks'] as int? ?? 0;

        switch (status) {
          case 'active':
            activeCount++;
            break;
          case 'expired':
            expiredCount++;
            break;
          case 'paused':
            pausedCount++;
            break;
          case 'rejected':
            rejectedCount++;
            break;
        }
        totalRevenue += price;
        totalImpressions += impressions;
        totalClicks += clicks;
      }

      final ctr =
          totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

      return {
        'totalAdvertisements': snapshot.docs.length,
        'activeAdvertisements': activeCount,
        'expiredAdvertisements': expiredCount,
        'pausedAdvertisements': pausedCount,
        'rejectedAdvertisements': rejectedCount,
        'totalRevenue': totalRevenue,
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'averageCtr': ctr,
      };
    } catch (e) {
      debugPrint(
          'ERROR: [advertisement_service] Ошибка получения статистики: $e');
      return {};
    }
  }
}
