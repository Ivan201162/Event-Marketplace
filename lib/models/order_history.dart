import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';

/// Модель истории заказа для портфолио заказчика
class OrderHistory {
  const OrderHistory({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    required this.serviceName,
    required this.date,
    required this.price,
    required this.status,
    required this.createdAt, required this.updatedAt, this.eventType,
    this.location,
    this.notes,
    this.reviewId,
    this.rating,
    this.additionalData,
  });

  /// Создать из документа Firestore
  factory OrderHistory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return OrderHistory.fromMap(data, doc.id);
  }

  /// Создать из Map
  factory OrderHistory.fromMap(Map<String, dynamic> data, [String? id]) =>
      OrderHistory(
        id: id ?? data['id'] ?? '',
        specialistId: data['specialistId'] ?? '',
        specialistName: data['specialistName'] ?? '',
        serviceName: data['serviceName'] ?? '',
        date: data['date'] != null
            ? (data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString()))
            : DateTime.now(),
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        status: data['status'] ?? 'completed',
        eventType: data['eventType'],
        location: data['location'],
        notes: data['notes'],
        reviewId: data['reviewId'],
        rating: (data['rating'] as num?)?.toDouble(),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt'].toString()))
            : DateTime.now(),
        additionalData: data['additionalData'],
      );

  /// Создать из Booking
  factory OrderHistory.fromBooking(Booking booking) => OrderHistory(
        id: booking.id,
        specialistId: booking.specialistId ?? '',
        specialistName: booking.specialistName ?? 'Неизвестный специалист',
        serviceName: booking.serviceName ?? booking.eventTitle,
        date: booking.eventDate,
        price: booking.effectivePrice,
        status: booking.status.name,
        eventType: booking.eventType,
        location: booking.location ?? booking.eventLocation,
        notes: booking.notes ?? booking.specialRequests,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        additionalData: {
          'bookingId': booking.id,
          'participantsCount': booking.participantsCount,
          'originalPrice': booking.totalPrice,
          'discount': booking.discount,
          'finalPrice': booking.finalPrice,
        },
      );
  final String id;
  final String specialistId;
  final String specialistName;
  final String serviceName;
  final DateTime date;
  final double price;
  final String status;
  final String? eventType;
  final String? location;
  final String? notes;
  final String? reviewId;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'serviceName': serviceName,
        'date': Timestamp.fromDate(date),
        'price': price,
        'status': status,
        'eventType': eventType,
        'location': location,
        'notes': notes,
        'reviewId': reviewId,
        'rating': rating,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'additionalData': additionalData,
      };

  /// Копировать с изменениями
  OrderHistory copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? serviceName,
    DateTime? date,
    double? price,
    String? status,
    String? eventType,
    String? location,
    String? notes,
    String? reviewId,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) =>
      OrderHistory(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        specialistName: specialistName ?? this.specialistName,
        serviceName: serviceName ?? this.serviceName,
        date: date ?? this.date,
        price: price ?? this.price,
        status: status ?? this.status,
        eventType: eventType ?? this.eventType,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        reviewId: reviewId ?? this.reviewId,
        rating: rating ?? this.rating,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        additionalData: additionalData ?? this.additionalData,
      );

  /// Получить цвет статуса
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'blue';
      default:
        return 'grey';
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Завершено';
      case 'cancelled':
        return 'Отменено';
      case 'pending':
        return 'Ожидает';
      case 'confirmed':
        return 'Подтверждено';
      default:
        return status;
    }
  }

  /// Проверить, есть ли отзыв
  bool get hasReview => reviewId != null && reviewId!.isNotEmpty;

  /// Проверить, есть ли рейтинг
  bool get hasRating => rating != null && rating! > 0;

  /// Получить отформатированную дату
  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  /// Получить отформатированную цену
  String get formattedPrice => '${price.toStringAsFixed(0)} ₽';

  /// Получить количество участников из дополнительных данных
  int get participantsCount => additionalData?['participantsCount'] ?? 1;

  /// Получить оригинальную цену из дополнительных данных
  double get originalPrice => additionalData?['originalPrice'] ?? price;

  /// Проверить, была ли скидка
  bool get hadDiscount =>
      additionalData?['discount'] != null && additionalData!['discount'] > 0;

  /// Получить размер скидки
  double get discountAmount {
    if (!hadDiscount) return 0;
    return originalPrice - price;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderHistory(id: $id, specialist: $specialistName, service: $serviceName, date: $date, price: $price)';
}

// Импорт для Booking
