import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion_boost.dart';
import '../models/transaction.dart' as transaction_model;
import '../services/payment_service.dart';

class PromotionService {
  static final PromotionService _instance = PromotionService._internal();
  factory PromotionService() => _instance;
  PromotionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  /// Получение всех доступных пакетов продвижения
  Future<List<PromotionPackage>> getAvailablePackages() async {
    try {
      debugdebugPrint('INFO: [promotion_service] Получение доступных пакетов продвижения');

      final snapshot = await _firestore
          .collection('promotion_packages')
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();

      return snapshot.docs
          .map((doc) => PromotionPackage.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения пакетов: $e');
      return [];
    }
  }

  /// Получение пакета продвижения по ID
  Future<PromotionPackage?> getPackageById(String packageId) async {
    try {
      final doc = await _firestore.collection('promotion_packages').doc(packageId).get();

      if (doc.exists) {
        return PromotionPackage.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения пакета: $e');
      return null;
    }
  }

  /// Получение активных продвижений пользователя
  Future<List<PromotionBoost>> getActivePromotions(String userId) async {
    try {
      debugdebugPrint(
          'INFO: [promotion_service] Получение активных продвижений для пользователя $userId');

      final snapshot = await _firestore
          .collection('promotions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PromotionBoost.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения активных продвижений: $e');
      return [];
    }
  }

  /// Получение всех продвижений пользователя
  Future<List<PromotionBoost>> getUserPromotions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PromotionBoost.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения продвижений пользователя: $e');
      return [];
    }
  }

  /// Покупка продвижения
  Future<PaymentResult> purchasePromotion({
    required String userId,
    required String packageId,
    required PaymentMethod paymentMethod,
    String? targetId,
    String? region,
    String? city,
    String? category,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugdebugPrint(
          'INFO: [promotion_service] Покупка продвижения $packageId для пользователя $userId');

      // Получаем пакет продвижения
      final package = await getPackageById(packageId);
      if (package == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'Пакет продвижения не найден',
        );
      }

      // Создаем платеж
      final paymentResult = await _paymentService.createPromotionPayment(
        userId: userId,
        package: package,
        paymentMethod: paymentMethod,
        provider: provider,
      );

      if (paymentResult.success) {
        // Создаем транзакцию
        final transaction = transaction_model.Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: transaction_model.TransactionType.promotion,
          amount: package.price,
          currency: 'RUB',
          status: transaction_model.TransactionStatus.pending,
          timestamp: DateTime.now(),
          description: 'Продвижение ${package.name}',
          promotionId: packageId,
          paymentMethod: paymentMethod.toString().split('.').last,
          paymentProvider: provider.toString().split('.').last,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );

        // Сохраняем транзакцию
        await _firestore.collection('transactions').doc(transaction.id).set(transaction.toMap());

        return PaymentResult(
          success: true,
          transactionId: transaction.id,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );
      }

      return paymentResult;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка покупки продвижения: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Активация продвижения после успешной оплаты
  Future<bool> activatePromotion({
    required String userId,
    required String packageId,
    required String transactionId,
    String? targetId,
    String? region,
    String? city,
    String? category,
  }) async {
    try {
      debugdebugPrint('INFO: [promotion_service] Активация продвижения для пользователя $userId');

      final package = await getPackageById(packageId);
      if (package == null) {
        debugdebugPrint('ERROR: [promotion_service] Пакет продвижения не найден');
        return false;
      }

      // Создаем продвижение
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: package.durationDays));

      final promotion = PromotionBoost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: package.type,
        startDate: startDate,
        endDate: endDate,
        status: PromotionStatus.active,
        priorityLevel: package.priorityLevel,
        price: package.price,
        targetId: targetId,
        region: region,
        city: city,
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем продвижение
      await _firestore.collection('promotions').doc(promotion.id).set(promotion.toMap());

      // Обновляем статус транзакции
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': transaction_model.TransactionStatus.success.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugdebugPrint('INFO: [promotion_service] Продвижение успешно активировано');
      return true;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка активации продвижения: $e');
      return false;
    }
  }

  /// Отмена продвижения
  Future<bool> cancelPromotion(String promotionId) async {
    try {
      debugdebugPrint('INFO: [promotion_service] Отмена продвижения $promotionId');

      await _firestore.collection('promotions').doc(promotionId).update({
        'status': PromotionStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugdebugPrint('INFO: [promotion_service] Продвижение успешно отменено');
      return true;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка отмены продвижения: $e');
      return false;
    }
  }

  /// Пауза продвижения
  Future<bool> pausePromotion(String promotionId) async {
    try {
      debugdebugPrint('INFO: [promotion_service] Пауза продвижения $promotionId');

      await _firestore.collection('promotions').doc(promotionId).update({
        'status': PromotionStatus.paused.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugdebugPrint('INFO: [promotion_service] Продвижение успешно поставлено на паузу');
      return true;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка паузы продвижения: $e');
      return false;
    }
  }

  /// Возобновление продвижения
  Future<bool> resumePromotion(String promotionId) async {
    try {
      debugdebugPrint('INFO: [promotion_service] Возобновление продвижения $promotionId');

      await _firestore.collection('promotions').doc(promotionId).update({
        'status': PromotionStatus.active.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugdebugPrint('INFO: [promotion_service] Продвижение успешно возобновлено');
      return true;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка возобновления продвижения: $e');
      return false;
    }
  }

  /// Обновление статистики продвижения
  Future<bool> updatePromotionStats({
    required String promotionId,
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

      // Пересчитываем CTR
      if (impressions != null || clicks != null) {
        final doc = await _firestore.collection('promotions').doc(promotionId).get();

        if (doc.exists) {
          final data = doc.data()!;
          final currentImpressions = (data['impressions'] as int? ?? 0) + (impressions ?? 0);
          final currentClicks = (data['clicks'] as int? ?? 0) + (clicks ?? 0);

          if (currentImpressions > 0) {
            updateData['ctr'] = (currentClicks / currentImpressions) * 100;
          }
        }
      }

      await _firestore.collection('promotions').doc(promotionId).update(updateData);

      return true;
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка обновления статистики: $e');
      return false;
    }
  }

  /// Проверка истечения продвижений
  Future<void> checkExpiredPromotions() async {
    try {
      debugdebugPrint('INFO: [promotion_service] Проверка истекших продвижений');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': PromotionStatus.expired.toString().split('.').last,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();

      debugdebugPrint(
          'INFO: [promotion_service] Обработано ${snapshot.docs.length} истекших продвижений');
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка проверки истекших продвижений: $e');
    }
  }

  /// Получение продвинутых профилей для отображения в топе
  Future<List<PromotionBoost>> getPromotedProfiles({
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      debugdebugPrint('INFO: [promotion_service] Получение продвинутых профилей');

      Query query = _firestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .where('type', isEqualTo: 'profileBoost')
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

      final snapshot = await query
          .orderBy('priorityLevel', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PromotionBoost.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения продвинутых профилей: $e');
      return [];
    }
  }

  /// Проверка, имеет ли пользователь активное продвижение
  Future<bool> hasActivePromotion(String userId, PromotionType type) async {
    try {
      final promotions = await getActivePromotions(userId);
      return promotions.any((promotion) => promotion.type == type);
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка проверки активного продвижения: $e');
      return false;
    }
  }

  /// Получение статистики продвижений
  Future<Map<String, dynamic>> getPromotionStats() async {
    try {
      final snapshot = await _firestore.collection('promotions').get();

      int activeCount = 0;
      int expiredCount = 0;
      int cancelledCount = 0;
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
          case 'cancelled':
            cancelledCount++;
            break;
        }
        totalRevenue += price;
        totalImpressions += impressions;
        totalClicks += clicks;
      }

      final ctr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

      return {
        'totalPromotions': snapshot.docs.length,
        'activePromotions': activeCount,
        'expiredPromotions': expiredCount,
        'cancelledPromotions': cancelledCount,
        'totalRevenue': totalRevenue,
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'averageCtr': ctr,
      };
    } catch (e) {
      debugdebugPrint('ERROR: [promotion_service] Ошибка получения статистики: $e');
      return {};
    }
  }
}
