import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/specialist.dart';

/// Сервис для управления скидками
class DiscountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Предложить скидку специалистом
  Future<DiscountOffer> offerDiscount({
    required String bookingId,
    required String specialistId,
    required double discountAmount,
    required String reason,
    DateTime? validUntil,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      if (booking.specialistId != specialistId) {
        throw Exception('Только специалист может предложить скидку');
      }

      if (discountAmount >= booking.totalPrice) {
        throw Exception('Скидка не может быть больше или равна стоимости услуги');
      }

      final discountOffer = DiscountOffer(
        id: _generateDiscountId(),
        bookingId: bookingId,
        specialistId: specialistId,
        customerId: booking.userId,
        discountAmount: discountAmount,
        originalAmount: booking.totalPrice,
        finalAmount: booking.totalPrice - discountAmount,
        reason: reason,
        status: DiscountStatus.pending,
        validUntil: validUntil ?? DateTime.now().add(const Duration(days: 7)),
        conditions: conditions ?? {},
        createdAt: DateTime.now(),
      );

      await _db.collection('discount_offers').doc(discountOffer.id).set(discountOffer.toMap());

      // Создаем уведомление для заказчика
      await _createDiscountNotification(discountOffer, booking);

      return discountOffer;
    } catch (e) {
      debugPrint('Ошибка создания предложения скидки: $e');
      throw Exception('Не удалось предложить скидку: $e');
    }
  }

  /// Принять скидку заказчиком
  Future<DiscountAcceptanceResult> acceptDiscount({
    required String discountId,
    required String customerId,
  }) async {
    try {
      final discountOffer = await _getDiscountOffer(discountId);
      if (discountOffer == null) {
        throw Exception('Предложение скидки не найдено');
      }

      if (discountOffer.customerId != customerId) {
        throw Exception('Только заказчик может принять скидку');
      }

      if (discountOffer.status != DiscountStatus.pending) {
        throw Exception('Предложение скидки уже обработано');
      }

      if (DateTime.now().isAfter(discountOffer.validUntil)) {
        throw Exception('Предложение скидки истекло');
      }

      // Обновляем статус предложения
      await _db.collection('discount_offers').doc(discountId).update({
        'status': DiscountStatus.accepted.name,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем бронирование с информацией о скидке
      await _updateBookingWithDiscount(discountOffer);

      // Создаем уведомления
      await _createAcceptanceNotifications(discountOffer);

      return DiscountAcceptanceResult(
        success: true,
        message: 'Скидка успешно принята',
        discountOffer: discountOffer.copyWith(status: DiscountStatus.accepted),
      );
    } catch (e) {
      debugPrint('Ошибка принятия скидки: $e');
      return DiscountAcceptanceResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Отклонить скидку заказчиком
  Future<DiscountRejectionResult> rejectDiscount({
    required String discountId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final discountOffer = await _getDiscountOffer(discountId);
      if (discountOffer == null) {
        throw Exception('Предложение скидки не найдено');
      }

      if (discountOffer.customerId != customerId) {
        throw Exception('Только заказчик может отклонить скидку');
      }

      if (discountOffer.status != DiscountStatus.pending) {
        throw Exception('Предложение скидки уже обработано');
      }

      // Обновляем статус предложения
      await _db.collection('discount_offers').doc(discountId).update({
        'status': DiscountStatus.rejected.name,
        'rejectedAt': Timestamp.fromDate(DateTime.now()),
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Создаем уведомления
      await _createRejectionNotifications(discountOffer, reason);

      return DiscountRejectionResult(
        success: true,
        message: 'Скидка отклонена',
        discountOffer: discountOffer.copyWith(status: DiscountStatus.rejected),
      );
    } catch (e) {
      debugPrint('Ошибка отклонения скидки: $e');
      return DiscountRejectionResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Получить активные предложения скидок для заказчика
  Future<List<DiscountOffer>> getActiveDiscountOffers(String customerId) async {
    try {
      final query = await _db
          .collection('discount_offers')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: DiscountStatus.pending.name)
          .where('validUntil', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('validUntil')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => DiscountOffer.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Ошибка получения активных предложений скидок: $e');
      return [];
    }
  }

  /// Получить историю предложений скидок специалиста
  Future<List<DiscountOffer>> getSpecialistDiscountHistory({
    required String specialistId,
    int limit = 50,
  }) async {
    try {
      final query = await _db
          .collection('discount_offers')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => DiscountOffer.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории предложений скидок: $e');
      return [];
    }
  }

  /// Получить статистику скидок специалиста
  Future<DiscountStatistics> getSpecialistDiscountStatistics(String specialistId) async {
    try {
      final query = await _db
          .collection('discount_offers')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final offers = query.docs.map((doc) => DiscountOffer.fromDocument(doc)).toList();
      
      final totalOffers = offers.length;
      final acceptedOffers = offers.where((o) => o.status == DiscountStatus.accepted).length;
      final rejectedOffers = offers.where((o) => o.status == DiscountStatus.rejected).length;
      final pendingOffers = offers.where((o) => o.status == DiscountStatus.pending).length;
      
      final totalDiscountAmount = offers
          .where((o) => o.status == DiscountStatus.accepted)
          .fold<double>(0, (sum, offer) => sum + offer.discountAmount);
      
      final averageDiscountAmount = acceptedOffers > 0 
          ? totalDiscountAmount / acceptedOffers 
          : 0;

      return DiscountStatistics(
        totalOffers: totalOffers,
        acceptedOffers: acceptedOffers,
        rejectedOffers: rejectedOffers,
        pendingOffers: pendingOffers,
        totalDiscountAmount: totalDiscountAmount,
        averageDiscountAmount: averageDiscountAmount,
        acceptanceRate: totalOffers > 0 ? (acceptedOffers / totalOffers) * 100 : 0,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики скидок: $e');
      return DiscountStatistics.empty();
    }
  }

  /// Автоматически предложить скидку на основе условий
  Future<DiscountOffer?> autoOfferDiscount({
    required String bookingId,
    required String specialistId,
    required AutoDiscountConditions conditions,
  }) async {
    try {
      final booking = await _getBooking(bookingId);
      if (booking == null) return null;

      // Проверяем условия для автоматического предложения скидки
      double discountAmount = 0;
      String reason = '';

      // Скидка за раннее бронирование
      final daysUntilEvent = booking.eventDate.difference(DateTime.now()).inDays;
      if (daysUntilEvent >= conditions.earlyBookingDays && conditions.earlyBookingDiscount > 0) {
        discountAmount = booking.totalPrice * (conditions.earlyBookingDiscount / 100);
        reason = 'Скидка за раннее бронирование (${conditions.earlyBookingDays}+ дней)';
      }

      // Скидка за повторное обращение
      final customerBookings = await _getCustomerBookingCount(booking.userId, specialistId);
      if (customerBookings >= conditions.repeatCustomerMinBookings && conditions.repeatCustomerDiscount > 0) {
        final repeatDiscount = booking.totalPrice * (conditions.repeatCustomerDiscount / 100);
        if (repeatDiscount > discountAmount) {
          discountAmount = repeatDiscount;
          reason = 'Скидка постоянному клиенту';
        }
      }

      // Скидка за крупный заказ
      if (booking.totalPrice >= conditions.largeOrderMinAmount && conditions.largeOrderDiscount > 0) {
        final largeOrderDiscount = booking.totalPrice * (conditions.largeOrderDiscount / 100);
        if (largeOrderDiscount > discountAmount) {
          discountAmount = largeOrderDiscount;
          reason = 'Скидка за крупный заказ';
        }
      }

      // Скидка за сезонность
      final month = booking.eventDate.month;
      if (conditions.seasonalDiscounts.containsKey(month) && conditions.seasonalDiscounts[month]! > 0) {
        final seasonalDiscount = booking.totalPrice * (conditions.seasonalDiscounts[month]! / 100);
        if (seasonalDiscount > discountAmount) {
          discountAmount = seasonalDiscount;
          reason = 'Сезонная скидка';
        }
      }

      if (discountAmount > 0) {
        return await offerDiscount(
          bookingId: bookingId,
          specialistId: specialistId,
          discountAmount: discountAmount,
          reason: reason,
          validUntil: DateTime.now().add(Duration(days: conditions.validityDays)),
          conditions: {
            'autoOffered': true,
            'conditions': conditions.toMap(),
          },
        );
      }

      return null;
    } catch (e) {
      debugPrint('Ошибка автоматического предложения скидки: $e');
      return null;
    }
  }

  /// Получить бронирование
  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения бронирования: $e');
      return null;
    }
  }

  /// Получить предложение скидки
  Future<DiscountOffer?> _getDiscountOffer(String discountId) async {
    try {
      final doc = await _db.collection('discount_offers').doc(discountId).get();
      if (doc.exists) {
        return DiscountOffer.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения предложения скидки: $e');
      return null;
    }
  }

  /// Получить количество бронирований клиента у специалиста
  Future<int> _getCustomerBookingCount(String customerId, String specialistId) async {
    try {
      final query = await _db
          .collection('bookings')
          .where('userId', isEqualTo: customerId)
          .where('specialistId', isEqualTo: specialistId)
          .where('status', whereIn: [BookingStatus.confirmed.name, BookingStatus.completed.name])
          .get();

      return query.docs.length;
    } catch (e) {
      debugPrint('Ошибка получения количества бронирований: $e');
      return 0;
    }
  }

  /// Обновить бронирование с информацией о скидке
  Future<void> _updateBookingWithDiscount(DiscountOffer discountOffer) async {
    await _db.collection('bookings').doc(discountOffer.bookingId).update({
      'discountAmount': discountOffer.discountAmount,
      'discountReason': discountOffer.reason,
      'finalAmount': discountOffer.finalAmount,
      'discountOfferId': discountOffer.id,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Создать уведомление о предложении скидки
  Future<void> _createDiscountNotification(DiscountOffer discountOffer, Booking booking) async {
    await _db.collection('notifications').add({
      'userId': discountOffer.customerId,
      'type': 'discount_offered',
      'title': 'Предложение скидки',
      'message': 'Специалист предложил скидку ${discountOffer.discountAmount.toInt()} ₽ (${discountOffer.reason})',
      'data': {
        'discountId': discountOffer.id,
        'bookingId': discountOffer.bookingId,
        'discountAmount': discountOffer.discountAmount,
        'reason': discountOffer.reason,
      },
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Создать уведомления о принятии скидки
  Future<void> _createAcceptanceNotifications(DiscountOffer discountOffer) async {
    final notifications = [
      {
        'userId': discountOffer.customerId,
        'type': 'discount_accepted',
        'title': 'Скидка принята',
        'message': 'Вы приняли скидку ${discountOffer.discountAmount.toInt()} ₽',
        'data': {
          'discountId': discountOffer.id,
          'bookingId': discountOffer.bookingId,
          'discountAmount': discountOffer.discountAmount,
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'userId': discountOffer.specialistId,
        'type': 'discount_accepted',
        'title': 'Скидка принята',
        'message': 'Клиент принял ваше предложение скидки ${discountOffer.discountAmount.toInt()} ₽',
        'data': {
          'discountId': discountOffer.id,
          'bookingId': discountOffer.bookingId,
          'discountAmount': discountOffer.discountAmount,
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
    ];

    for (final notification in notifications) {
      await _db.collection('notifications').add(notification);
    }
  }

  /// Создать уведомления об отклонении скидки
  Future<void> _createRejectionNotifications(DiscountOffer discountOffer, String? reason) async {
    final notifications = [
      {
        'userId': discountOffer.specialistId,
        'type': 'discount_rejected',
        'title': 'Скидка отклонена',
        'message': 'Клиент отклонил ваше предложение скидки${reason != null ? ': $reason' : ''}',
        'data': {
          'discountId': discountOffer.id,
          'bookingId': discountOffer.bookingId,
          'rejectionReason': reason,
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
    ];

    for (final notification in notifications) {
      await _db.collection('notifications').add(notification);
    }
  }

  /// Генерировать ID для скидки
  String _generateDiscountId() {
    return 'discount_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}

/// Статусы предложений скидок
enum DiscountStatus {
  pending,   // Ожидает ответа
  accepted,  // Принято
  rejected,  // Отклонено
  expired,   // Истекло
}

/// Предложение скидки
class DiscountOffer {
  const DiscountOffer({
    required this.id,
    required this.bookingId,
    required this.specialistId,
    required this.customerId,
    required this.discountAmount,
    required this.originalAmount,
    required this.finalAmount,
    required this.reason,
    required this.status,
    required this.validUntil,
    required this.conditions,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  factory DiscountOffer.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return DiscountOffer(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      specialistId: data['specialistId'] as String,
      customerId: data['customerId'] as String,
      discountAmount: (data['discountAmount'] as num).toDouble(),
      originalAmount: (data['originalAmount'] as num).toDouble(),
      finalAmount: (data['finalAmount'] as num).toDouble(),
      reason: data['reason'] as String,
      status: DiscountStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DiscountStatus.pending,
      ),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      conditions: Map<String, dynamic>.from(data['conditions'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      rejectedAt: data['rejectedAt'] != null 
          ? (data['rejectedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  final String id;
  final String bookingId;
  final String specialistId;
  final String customerId;
  final double discountAmount;
  final double originalAmount;
  final double finalAmount;
  final String reason;
  final DiscountStatus status;
  final DateTime validUntil;
  final Map<String, dynamic> conditions;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  Map<String, dynamic> toMap() => {
    'bookingId': bookingId,
    'specialistId': specialistId,
    'customerId': customerId,
    'discountAmount': discountAmount,
    'originalAmount': originalAmount,
    'finalAmount': finalAmount,
    'reason': reason,
    'status': status.name,
    'validUntil': Timestamp.fromDate(validUntil),
    'conditions': conditions,
    'createdAt': Timestamp.fromDate(createdAt),
    'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
    'rejectionReason': rejectionReason,
  };

  DiscountOffer copyWith({
    String? id,
    String? bookingId,
    String? specialistId,
    String? customerId,
    double? discountAmount,
    double? originalAmount,
    double? finalAmount,
    String? reason,
    DiscountStatus? status,
    DateTime? validUntil,
    Map<String, dynamic>? conditions,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) => DiscountOffer(
    id: id ?? this.id,
    bookingId: bookingId ?? this.bookingId,
    specialistId: specialistId ?? this.specialistId,
    customerId: customerId ?? this.customerId,
    discountAmount: discountAmount ?? this.discountAmount,
    originalAmount: originalAmount ?? this.originalAmount,
    finalAmount: finalAmount ?? this.finalAmount,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    validUntil: validUntil ?? this.validUntil,
    conditions: conditions ?? this.conditions,
    createdAt: createdAt ?? this.createdAt,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    rejectedAt: rejectedAt ?? this.rejectedAt,
    rejectionReason: rejectionReason ?? this.rejectionReason,
  );

  /// Проверить, истекло ли предложение
  bool get isExpired => DateTime.now().isAfter(validUntil);

  /// Получить процент скидки
  double get discountPercentage => (discountAmount / originalAmount) * 100;
}

/// Условия для автоматического предложения скидок
class AutoDiscountConditions {
  const AutoDiscountConditions({
    this.earlyBookingDays = 14,
    this.earlyBookingDiscount = 10,
    this.repeatCustomerMinBookings = 3,
    this.repeatCustomerDiscount = 15,
    this.largeOrderMinAmount = 50000,
    this.largeOrderDiscount = 20,
    this.seasonalDiscounts = const {},
    this.validityDays = 7,
  });

  final int earlyBookingDays;
  final double earlyBookingDiscount;
  final int repeatCustomerMinBookings;
  final double repeatCustomerDiscount;
  final double largeOrderMinAmount;
  final double largeOrderDiscount;
  final Map<int, double> seasonalDiscounts; // месяц -> процент скидки
  final int validityDays;

  Map<String, dynamic> toMap() => {
    'earlyBookingDays': earlyBookingDays,
    'earlyBookingDiscount': earlyBookingDiscount,
    'repeatCustomerMinBookings': repeatCustomerMinBookings,
    'repeatCustomerDiscount': repeatCustomerDiscount,
    'largeOrderMinAmount': largeOrderMinAmount,
    'largeOrderDiscount': largeOrderDiscount,
    'seasonalDiscounts': seasonalDiscounts,
    'validityDays': validityDays,
  };
}

/// Результат принятия скидки
class DiscountAcceptanceResult {
  const DiscountAcceptanceResult({
    required this.success,
    this.message,
    this.errorMessage,
    this.discountOffer,
  });

  final bool success;
  final String? message;
  final String? errorMessage;
  final DiscountOffer? discountOffer;
}

/// Результат отклонения скидки
class DiscountRejectionResult {
  const DiscountRejectionResult({
    required this.success,
    this.message,
    this.errorMessage,
    this.discountOffer,
  });

  final bool success;
  final String? message;
  final String? errorMessage;
  final DiscountOffer? discountOffer;
}

/// Статистика скидок
class DiscountStatistics {
  const DiscountStatistics({
    required this.totalOffers,
    required this.acceptedOffers,
    required this.rejectedOffers,
    required this.pendingOffers,
    required this.totalDiscountAmount,
    required this.averageDiscountAmount,
    required this.acceptanceRate,
  });

  final int totalOffers;
  final int acceptedOffers;
  final int rejectedOffers;
  final int pendingOffers;
  final double totalDiscountAmount;
  final double averageDiscountAmount;
  final double acceptanceRate;

  factory DiscountStatistics.empty() => const DiscountStatistics(
    totalOffers: 0,
    acceptedOffers: 0,
    rejectedOffers: 0,
    pendingOffers: 0,
    totalDiscountAmount: 0,
    averageDiscountAmount: 0,
    acceptanceRate: 0,
  );
}