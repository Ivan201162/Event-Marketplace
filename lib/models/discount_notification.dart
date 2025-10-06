import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления о скидке
class DiscountNotification {
  const DiscountNotification({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.bookingId,
    required this.originalPrice,
    required this.newPrice,
    required this.discountPercent,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.specialistName,
    this.specialistAvatar,
    this.customerName,
    this.customerAvatar,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory DiscountNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return DiscountNotification(
      id: doc.id,
      customerId: data['customerId']?.toString() ?? '',
      specialistId: data['specialistId']?.toString() ?? '',
      bookingId: data['bookingId']?.toString() ?? '',
      originalPrice: (data['originalPrice'] as num).toDouble(),
      newPrice: (data['newPrice'] as num).toDouble(),
      discountPercent: (data['discountPercent'] as num).toDouble(),
      message: data['message']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] == true,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      specialistName: data['specialistName']?.toString(),
      specialistAvatar: data['specialistAvatar']?.toString(),
      customerName: data['customerName']?.toString(),
      customerAvatar: data['customerAvatar']?.toString(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory DiscountNotification.fromMap(Map<String, dynamic> data) =>
      DiscountNotification(
        id: data['id']?.toString() ?? '',
        customerId: data['customerId']?.toString() ?? '',
        specialistId: data['specialistId']?.toString() ?? '',
        bookingId: data['bookingId']?.toString() ?? '',
        originalPrice: (data['originalPrice'] as num).toDouble(),
        newPrice: (data['newPrice'] as num).toDouble(),
        discountPercent: (data['discountPercent'] as num).toDouble(),
        message: data['message']?.toString() ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        isRead: data['isRead'] == true,
        readAt: data['readAt'] != null
            ? (data['readAt'] as Timestamp).toDate()
            : null,
        specialistName: data['specialistName']?.toString(),
        specialistAvatar: data['specialistAvatar']?.toString(),
        customerName: data['customerName']?.toString(),
        customerAvatar: data['customerAvatar']?.toString(),
        metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      );

  final String id;
  final String customerId;
  final String specialistId;
  final String bookingId;
  final double originalPrice;
  final double newPrice;
  final double discountPercent;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? specialistName;
  final String? specialistAvatar;
  final String? customerName;
  final String? customerAvatar;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'specialistId': specialistId,
        'bookingId': bookingId,
        'originalPrice': originalPrice,
        'newPrice': newPrice,
        'discountPercent': discountPercent,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
        'specialistName': specialistName,
        'specialistAvatar': specialistAvatar,
        'customerName': customerName,
        'customerAvatar': customerAvatar,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  DiscountNotification copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? bookingId,
    double? originalPrice,
    double? newPrice,
    double? discountPercent,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? specialistName,
    String? specialistAvatar,
    String? customerName,
    String? customerAvatar,
    Map<String, dynamic>? metadata,
  }) =>
      DiscountNotification(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        bookingId: bookingId ?? this.bookingId,
        originalPrice: originalPrice ?? this.originalPrice,
        newPrice: newPrice ?? this.newPrice,
        discountPercent: discountPercent ?? this.discountPercent,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        specialistName: specialistName ?? this.specialistName,
        specialistAvatar: specialistAvatar ?? this.specialistAvatar,
        customerName: customerName ?? this.customerName,
        customerAvatar: customerAvatar ?? this.customerAvatar,
        metadata: metadata ?? this.metadata,
      );

  /// Получить сумму скидки
  double get discountAmount => originalPrice - newPrice;

  /// Проверить, является ли уведомление новым
  bool get isNew => !isRead;

  /// Получить время в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${(difference.inDays / 7).floor()}н назад';
    }
  }

  /// Получить отформатированную цену
  String get formattedOriginalPrice => '${originalPrice.toStringAsFixed(0)} ₽';
  String get formattedNewPrice => '${newPrice.toStringAsFixed(0)} ₽';
  String get formattedDiscountAmount =>
      '${discountAmount.toStringAsFixed(0)} ₽';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscountNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DiscountNotification(id: $id, discountPercent: $discountPercent%, isRead: $isRead)';
}

/// Модель для создания уведомления о скидке
class CreateDiscountNotification {
  const CreateDiscountNotification({
    required this.customerId,
    required this.specialistId,
    required this.bookingId,
    required this.originalPrice,
    required this.newPrice,
    required this.message,
    this.specialistName,
    this.specialistAvatar,
    this.customerName,
    this.customerAvatar,
    this.metadata = const {},
  });

  final String customerId;
  final String specialistId;
  final String bookingId;
  final double originalPrice;
  final double newPrice;
  final String message;
  final String? specialistName;
  final String? specialistAvatar;
  final String? customerName;
  final String? customerAvatar;
  final Map<String, dynamic> metadata;

  /// Вычислить процент скидки
  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - newPrice) / originalPrice) * 100;
  }

  bool get isValid =>
      customerId.isNotEmpty &&
      specialistId.isNotEmpty &&
      bookingId.isNotEmpty &&
      originalPrice > 0 &&
      newPrice > 0 &&
      newPrice < originalPrice &&
      message.isNotEmpty;

  List<String> get validationErrors {
    final errors = <String>[];
    if (customerId.isEmpty) errors.add('ID клиента обязателен');
    if (specialistId.isEmpty) errors.add('ID специалиста обязателен');
    if (bookingId.isEmpty) errors.add('ID бронирования обязателен');
    if (originalPrice <= 0) errors.add('Исходная цена должна быть больше 0');
    if (newPrice <= 0) errors.add('Новая цена должна быть больше 0');
    if (newPrice >= originalPrice) {
      errors.add('Новая цена должна быть меньше исходной');
    }
    if (message.isEmpty) errors.add('Сообщение обязательно');
    return errors;
  }
}
