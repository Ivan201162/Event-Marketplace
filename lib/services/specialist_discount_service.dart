import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/booking.dart';

/// Сервис для управления скидками специалистов
class SpecialistDiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Предложить скидку при отклике на заявку
  Future<String> offerDiscount({
    required String specialistId,
    required String bookingId,
    required double discountPercent,
    String? message,
    DateTime? expiresAt,
  }) async {
    try {
      final now = DateTime.now();
      final discountExpiresAt = expiresAt ?? now.add(const Duration(days: 7));

      final discount = SpecialistDiscount(
        id: '', // Будет сгенерирован Firestore
        specialistId: specialistId,
        bookingId: bookingId,
        discountPercent: discountPercent,
        message: message,
        isActive: true,
        isAccepted: false,
        createdAt: now,
        expiresAt: discountExpiresAt,
      );

      final docRef = await _firestore
          .collection('specialist_discounts')
          .add(discount.toMap());

      // Отправляем уведомление заказчику
      await _sendDiscountNotification(bookingId, docRef.id);

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка предложения скидки: $e');
      rethrow;
    }
  }

  /// Получить скидки для заказа
  Future<List<SpecialistDiscount>> getDiscountsForBooking(
      String bookingId,) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_discounts')
          .where('bookingId', isEqualTo: bookingId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(SpecialistDiscount.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения скидок для заказа: $e');
      return [];
    }
  }

  /// Получить активные скидки специалиста
  Future<List<SpecialistDiscount>> getActiveDiscountsForSpecialist(
      String specialistId,) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_discounts')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(SpecialistDiscount.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения активных скидок специалиста: $e');
      return [];
    }
  }

  /// Принять скидку
  Future<void> acceptDiscount(String discountId) async {
    try {
      await _firestore
          .collection('specialist_discounts')
          .doc(discountId)
          .update({
        'isAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });

      // Получаем информацию о скидке для обновления заказа
      final discountDoc = await _firestore
          .collection('specialist_discounts')
          .doc(discountId)
          .get();

      if (discountDoc.exists) {
        final discount = SpecialistDiscount.fromDocument(discountDoc);
        await _updateBookingWithDiscount(discount);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка принятия скидки: $e');
      rethrow;
    }
  }

  /// Отклонить скидку
  Future<void> rejectDiscount(String discountId) async {
    try {
      await _firestore
          .collection('specialist_discounts')
          .doc(discountId)
          .update({
        'isRejected': true,
        'rejectedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отклонения скидки: $e');
      rethrow;
    }
  }

  /// Отменить скидку (специалистом)
  Future<void> cancelDiscount(String discountId) async {
    try {
      await _firestore
          .collection('specialist_discounts')
          .doc(discountId)
          .update({
        'isCancelled': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отмены скидки: $e');
      rethrow;
    }
  }

  /// Получить статистику скидок специалиста
  Future<SpecialistDiscountStats> getSpecialistDiscountStats(
      String specialistId,) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_discounts')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final discounts =
          snapshot.docs.map(SpecialistDiscount.fromDocument).toList();

      final totalOffers = discounts.length;
      final acceptedOffers = discounts.where((d) => d.isAccepted).length;
      final rejectedOffers = discounts.where((d) => d.isRejected).length;
      final expiredOffers = discounts
          .where((d) =>
              d.expiresAt.isBefore(DateTime.now()) &&
              !d.isAccepted &&
              !d.isRejected,)
          .length;

      final averageDiscount = discounts.isNotEmpty
          ? discounts.fold<double>(0, (sum, d) => sum + d.discountPercent) /
              discounts.length
          : 0.0;

      return SpecialistDiscountStats(
        specialistId: specialistId,
        totalOffers: totalOffers,
        acceptedOffers: acceptedOffers,
        rejectedOffers: rejectedOffers,
        expiredOffers: expiredOffers,
        averageDiscount: averageDiscount,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики скидок: $e');
      return SpecialistDiscountStats.empty();
    }
  }

  /// Проверить, может ли специалист предложить скидку
  Future<bool> canOfferDiscount(String specialistId, String bookingId) async {
    try {
      // Проверяем, не предложил ли уже специалист скидку для этого заказа
      final existingDiscount = await _firestore
          .collection('specialist_discounts')
          .where('specialistId', isEqualTo: specialistId)
          .where('bookingId', isEqualTo: bookingId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return existingDiscount.docs.isEmpty;
    } on Exception catch (e) {
      debugPrint('Ошибка проверки возможности предложения скидки: $e');
      return false;
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Отправить уведомление о скидке
  Future<void> _sendDiscountNotification(
      String bookingId, String discountId,) async {
    try {
      // Получаем информацию о заказе
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) return;

      final booking = Booking.fromDocument(bookingDoc);

      // Создаем уведомление
      await _firestore.collection('notifications').add({
        'userId': booking.customerId ?? booking.userId,
        'type': 'discount_offer',
        'title': 'Предложение скидки',
        'body': 'Специалист предложил скидку на ваш заказ',
        'data': {'bookingId': bookingId, 'discountId': discountId},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отправки уведомления о скидке: $e');
    }
  }

  /// Обновить заказ с учетом скидки
  Future<void> _updateBookingWithDiscount(SpecialistDiscount discount) async {
    try {
      // Получаем заказ
      final bookingDoc =
          await _firestore.collection('bookings').doc(discount.bookingId).get();

      if (!bookingDoc.exists) return;

      final booking = Booking.fromDocument(bookingDoc);
      final discountAmount =
          booking.totalPrice * (discount.discountPercent / 100);
      final finalPrice = booking.totalPrice - discountAmount;

      // Обновляем заказ
      await _firestore.collection('bookings').doc(discount.bookingId).update({
        'totalPrice': finalPrice,
        'discountPercent': discount.discountPercent,
        'discountAmount': discountAmount,
        'originalPrice': booking.totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления заказа со скидкой: $e');
    }
  }
}

/// Модель скидки специалиста
class SpecialistDiscount {
  const SpecialistDiscount({
    required this.id,
    required this.specialistId,
    required this.bookingId,
    required this.discountPercent,
    required this.isActive, required this.isAccepted, required this.createdAt, required this.expiresAt, this.message,
    this.isRejected = false,
    this.isCancelled = false,
    this.acceptedAt,
    this.rejectedAt,
    this.cancelledAt,
  });

  factory SpecialistDiscount.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistDiscount(
      id: doc.id,
      specialistId: data['specialistId'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      message: data['message'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isAccepted: data['isAccepted'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRejected: data['isRejected'] as bool? ?? false,
      isCancelled: data['isCancelled'] as bool? ?? false,
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String specialistId;
  final String bookingId;
  final double discountPercent;
  final String? message;
  final bool isActive;
  final bool isAccepted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRejected;
  final bool isCancelled;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'bookingId': bookingId,
        'discountPercent': discountPercent,
        'message': message,
        'isActive': isActive,
        'isAccepted': isAccepted,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isRejected': isRejected,
        'isCancelled': isCancelled,
        'acceptedAt':
            acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'rejectedAt':
            rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
        'cancelledAt':
            cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      };
}

/// Статистика скидок специалиста
class SpecialistDiscountStats {
  const SpecialistDiscountStats({
    required this.specialistId,
    required this.totalOffers,
    required this.acceptedOffers,
    required this.rejectedOffers,
    required this.expiredOffers,
    required this.averageDiscount,
    required this.lastUpdated,
  });

  factory SpecialistDiscountStats.empty() => SpecialistDiscountStats(
        specialistId: '',
        totalOffers: 0,
        acceptedOffers: 0,
        rejectedOffers: 0,
        expiredOffers: 0,
        averageDiscount: 0,
        lastUpdated: DateTime.now(),
      );

  final String specialistId;
  final int totalOffers;
  final int acceptedOffers;
  final int rejectedOffers;
  final int expiredOffers;
  final double averageDiscount;
  final DateTime lastUpdated;

  double get acceptanceRate =>
      totalOffers > 0 ? acceptedOffers / totalOffers : 0.0;
}
