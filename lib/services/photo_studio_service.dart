import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/photo_studio.dart';
import 'fcm_service.dart';

/// Сервис для работы с фотостудиями
class PhotoStudioService {
  static const String _collection = 'photo_studios';
  static const String _bookingsCollection = 'photo_studio_bookings';
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  /// Создать фотостудию
  Future<PhotoStudio> createPhotoStudio(CreatePhotoStudio data) async {
    if (!data.isValid) {
      throw Exception('Неверные данные: ${data.validationErrors.join(', ')}');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (data.ownerId != currentUser.uid) {
      throw Exception('Только владелец может создавать фотостудию');
    }

    // Создать фотостудию
    final photoStudio = PhotoStudio(
      id: '', // Будет установлен Firestore
      name: data.name,
      description: data.description,
      address: data.address,
      phone: data.phone,
      email: data.email,
      ownerId: data.ownerId,
      createdAt: DateTime.now(),
      avatarUrl: data.avatarUrl,
      coverImageUrl: data.coverImageUrl,
      images: data.images,
      amenities: data.amenities,
      pricing: data.pricing,
      workingHours: data.workingHours,
      location: data.location,
      metadata: data.metadata,
    );

    // Сохранить в Firestore
    final docRef = await _firestore.collection(_collection).add(photoStudio.toMap());

    // Обновить ID
    final createdPhotoStudio = photoStudio.copyWith(id: docRef.id);

    return createdPhotoStudio;
  }

  /// Получить фотостудию по ID
  Future<PhotoStudio?> getPhotoStudio(String studioId) async {
    final doc = await _firestore.collection(_collection).doc(studioId).get();
    if (!doc.exists) return null;
    return PhotoStudio.fromDocument(doc);
  }

  /// Получить все фотостудии
  Future<List<PhotoStudio>> getPhotoStudios({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(PhotoStudio.fromDocument).toList();
  }

  /// Поиск фотостудий
  Future<List<PhotoStudio>> searchPhotoStudios({
    String? query,
    String? location,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
    int limit = 20,
  }) async {
    Query firestoreQuery = _firestore.collection(_collection).where('isActive', isEqualTo: true);

    // Фильтр по местоположению
    if (location != null && location.isNotEmpty) {
      firestoreQuery = firestoreQuery.where('address', isGreaterThanOrEqualTo: location);
    }

    // Фильтр по цене
    if (minPrice != null) {
      firestoreQuery = firestoreQuery.where(
        'pricing.hourlyRate',
        isGreaterThanOrEqualTo: minPrice,
      );
    }

    if (maxPrice != null) {
      firestoreQuery = firestoreQuery.where(
        'pricing.hourlyRate',
        isLessThanOrEqualTo: maxPrice,
      );
    }

    firestoreQuery = firestoreQuery.limit(limit);

    final snapshot = await firestoreQuery.get();
    var studios = snapshot.docs.map(PhotoStudio.fromDocument).toList();

    // Фильтр по тексту (если указан)
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      studios = studios
          .where(
            (studio) =>
                studio.name.toLowerCase().contains(lowerQuery) ||
                studio.description.toLowerCase().contains(lowerQuery) ||
                studio.address.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }

    // Фильтр по удобствам (если указаны)
    if (amenities != null && amenities.isNotEmpty) {
      studios = studios
          .where(
            (studio) => amenities.every((amenity) => studio.amenities.contains(amenity)),
          )
          .toList();
    }

    return studios;
  }

  /// Получить фотостудии владельца
  Future<List<PhotoStudio>> getOwnerPhotoStudios(String ownerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(PhotoStudio.fromDocument).toList();
  }

  /// Обновить фотостудию
  Future<void> updatePhotoStudio(
    String studioId,
    Map<String, dynamic> updates,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final photoStudio = await getPhotoStudio(studioId);
    if (photoStudio == null) {
      throw Exception('Фотостудия не найдена');
    }

    if (photoStudio.ownerId != currentUser.uid) {
      throw Exception('Только владелец может обновлять фотостудию');
    }

    await _firestore.collection(_collection).doc(studioId).update(updates);
  }

  /// Удалить фотостудию
  Future<void> deletePhotoStudio(String studioId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final photoStudio = await getPhotoStudio(studioId);
    if (photoStudio == null) {
      throw Exception('Фотостудия не найдена');
    }

    if (photoStudio.ownerId != currentUser.uid) {
      throw Exception('Только владелец может удалять фотостудию');
    }

    await _firestore.collection(_collection).doc(studioId).delete();
  }

  /// Создать бронирование фотостудии
  Future<PhotoStudioBooking> createBooking({
    required String studioId,
    required String customerId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalPrice,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? packageName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (customerId != currentUser.uid) {
      throw Exception('Только владелец аккаунта может создавать бронирования');
    }

    // Проверить доступность времени
    final isAvailable = await _isTimeSlotAvailable(studioId, startTime, endTime);
    if (!isAvailable) {
      throw Exception('Выбранное время недоступно');
    }

    // Получить данные клиента
    final customerDoc = await _firestore.collection(_usersCollection).doc(customerId).get();

    if (!customerDoc.exists) {
      throw Exception('Клиент не найден');
    }

    final customerData = customerDoc.data()!;
    final customer = AppUser.fromMap(customerData);

    // Создать бронирование
    final booking = PhotoStudioBooking(
      id: '', // Будет установлен Firestore
      studioId: studioId,
      customerId: customerId,
      startTime: startTime,
      endTime: endTime,
      totalPrice: totalPrice,
      status: 'pending',
      createdAt: DateTime.now(),
      customerName: customerName ?? customer.displayName,
      customerPhone: customerPhone ?? customer.phoneNumber,
      customerEmail: customerEmail ?? customer.email,
      notes: notes,
      packageName: packageName,
    );

    // Сохранить в Firestore
    final docRef = await _firestore.collection(_bookingsCollection).add({
      'studioId': booking.studioId,
      'customerId': booking.customerId,
      'startTime': Timestamp.fromDate(booking.startTime),
      'endTime': Timestamp.fromDate(booking.endTime),
      'totalPrice': booking.totalPrice,
      'status': booking.status,
      'createdAt': Timestamp.fromDate(booking.createdAt),
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'customerEmail': booking.customerEmail,
      'notes': booking.notes,
      'packageName': booking.packageName,
    });

    // Обновить ID
    final createdBooking = PhotoStudioBooking(
      id: docRef.id,
      studioId: booking.studioId,
      customerId: booking.customerId,
      startTime: booking.startTime,
      endTime: booking.endTime,
      totalPrice: booking.totalPrice,
      status: booking.status,
      createdAt: booking.createdAt,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      customerEmail: booking.customerEmail,
      notes: booking.notes,
      packageName: booking.packageName,
    );

    // Отправить уведомление владельцу студии
    final photoStudio = await getPhotoStudio(studioId);
    if (photoStudio != null) {
      await _fcmService.sendPhotoStudioBookingNotification(
        ownerId: photoStudio.ownerId,
        customerName: customer.displayName,
        studioName: photoStudio.name,
        startTime: startTime,
        totalPrice: totalPrice,
      );
    }

    return createdBooking;
  }

  /// Получить бронирования клиента
  Future<List<PhotoStudioBooking>> getCustomerBookings(
    String customerId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs.map(PhotoStudioBooking.fromDocument).toList();
  }

  /// Получить бронирования фотостудии
  Future<List<PhotoStudioBooking>> getStudioBookings(String studioId) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('studioId', isEqualTo: studioId)
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs.map(PhotoStudioBooking.fromDocument).toList();
  }

  /// Обновить статус бронирования
  Future<void> updateBookingStatus(String bookingId, String status) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw Exception('Бронирование не найдено');
    }

    final booking = PhotoStudioBooking.fromDocument(bookingDoc);
    final photoStudio = await getPhotoStudio(booking.studioId);

    if (photoStudio == null) {
      throw Exception('Фотостудия не найдена');
    }

    // Проверить права доступа
    if (currentUser.uid != booking.customerId && currentUser.uid != photoStudio.ownerId) {
      throw Exception('Недостаточно прав для изменения статуса');
    }

    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'status': status,
    });

    // Отправить уведомление
    if (status == 'confirmed') {
      await _fcmService.sendBookingConfirmedNotification(
        customerId: booking.customerId,
        studioName: photoStudio.name,
        startTime: booking.startTime,
      );
    } else if (status == 'cancelled') {
      await _fcmService.sendBookingCancelledNotification(
        customerId: booking.customerId,
        studioName: photoStudio.name,
        startTime: booking.startTime,
      );
    }
  }

  /// Проверить доступность временного слота
  Future<bool> _isTimeSlotAvailable(
    String studioId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('studioId', isEqualTo: studioId)
        .where('status', whereIn: ['pending', 'confirmed']).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final existingStart = (data['startTime'] as Timestamp).toDate();
      final existingEnd = (data['endTime'] as Timestamp).toDate();

      // Проверить пересечение временных интервалов
      if (startTime.isBefore(existingEnd) && endTime.isAfter(existingStart)) {
        return false;
      }
    }

    return true;
  }

  /// Получить доступные временные слоты
  Future<List<Map<String, DateTime>>> getAvailableTimeSlots(
    String studioId,
    DateTime date,
    int durationHours,
  ) async {
    final photoStudio = await getPhotoStudio(studioId);
    if (photoStudio == null) {
      throw Exception('Фотостудия не найдена');
    }

    final day = _getDayName(date.weekday);
    final workingHours = photoStudio.getWorkingHoursForDay(day);

    if (workingHours == null) {
      return []; // Студия не работает в этот день
    }

    final openTime = _parseTimeOfDay(workingHours['open']!);
    final closeTime = _parseTimeOfDay(workingHours['close']!);

    final openDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      openTime.hour,
      openTime.minute,
    );
    final closeDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      closeTime.hour,
      closeTime.minute,
    );

    // Получить существующие бронирования
    final existingBookings = await _firestore
        .collection(_bookingsCollection)
        .where('studioId', isEqualTo: studioId)
        .where('status', whereIn: ['pending', 'confirmed']).get();

    final bookedSlots = <Map<String, DateTime>>[];
    for (final doc in existingBookings.docs) {
      final data = doc.data();
      final start = (data['startTime'] as Timestamp).toDate();
      final end = (data['endTime'] as Timestamp).toDate();

      if (_isSameDay(start, date)) {
        bookedSlots.add({'start': start, 'end': end});
      }
    }

    // Найти доступные слоты
    final availableSlots = <Map<String, DateTime>>[];
    final slotDuration = Duration(hours: durationHours);

    var currentTime = openDateTime;
    while (currentTime.add(slotDuration).isBefore(closeDateTime) ||
        currentTime.add(slotDuration).isAtSameMomentAs(closeDateTime)) {
      final slotEnd = currentTime.add(slotDuration);
      var isAvailable = true;

      // Проверить пересечение с существующими бронированиями
      for (final bookedSlot in bookedSlots) {
        if (currentTime.isBefore(bookedSlot['end']!) && slotEnd.isAfter(bookedSlot['start']!)) {
          isAvailable = false;
          break;
        }
      }

      if (isAvailable) {
        availableSlots.add({'start': currentTime, 'end': slotEnd});
      }

      currentTime = currentTime.add(const Duration(hours: 1));
    }

    return availableSlots;
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;

  /// Подписаться на изменения фотостудий
  Stream<List<PhotoStudio>> watchPhotoStudios() => _firestore
      .collection(_collection)
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(PhotoStudio.fromDocument).toList(),
      );

  /// Подписаться на изменения бронирований клиента
  Stream<List<PhotoStudioBooking>> watchCustomerBookings(String customerId) => _firestore
      .collection(_bookingsCollection)
      .where('customerId', isEqualTo: customerId)
      .orderBy('startTime', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(PhotoStudioBooking.fromDocument).toList(),
      );
}
