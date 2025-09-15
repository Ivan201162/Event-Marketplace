import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/guest.dart';

/// Сервис для работы с гостями
class GuestService {
  static final GuestService _instance = GuestService._internal();
  factory GuestService() => _instance;
  GuestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Создать событие для гостей
  Future<String?> createGuestEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String organizerId,
    required String organizerName,
    required int maxGuests,
    String? organizerPhotoUrl,
    String? eventPhotoUrl,
    bool isPublic = true,
    bool allowGreetings = true,
  }) async {
    try {
      final eventRef = _firestore.collection('guest_events').doc();
      
      // Генерируем QR код и ссылку для приглашения
      final qrCode = await _generateQRCode(eventRef.id);
      final invitationLink = 'https://eventmarketplace.app/guest/${eventRef.id}';
      
      final event = GuestEvent(
        id: eventRef.id,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        organizerId: organizerId,
        organizerName: organizerName,
        organizerPhotoUrl: organizerPhotoUrl,
        eventPhotoUrl: eventPhotoUrl,
        maxGuests: maxGuests,
        currentGuests: 0,
        isPublic: isPublic,
        allowGreetings: allowGreetings,
        invitationLink: invitationLink,
        qrCode: qrCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await eventRef.set(event.toMap());
      return eventRef.id;
    } catch (e) {
      print('Ошибка создания события для гостей: $e');
      return null;
    }
  }

  /// Получить событие для гостей
  Future<GuestEvent?> getGuestEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('guest_events').doc(eventId).get();
      if (doc.exists) {
        return GuestEvent.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения события для гостей: $e');
      return null;
    }
  }

  /// Получить события организатора
  Stream<List<GuestEvent>> getOrganizerEvents(String organizerId) {
    return _firestore
        .collection('guest_events')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GuestEvent.fromDocument(doc))
          .toList();
    });
  }

  /// Получить публичные события
  Stream<List<GuestEvent>> getPublicEvents() {
    return _firestore
        .collection('guest_events')
        .where('isPublic', isEqualTo: true)
        .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GuestEvent.fromDocument(doc))
          .toList();
    });
  }

  /// Зарегистрировать гостя
  Future<String?> registerGuest({
    required String eventId,
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    String? guestPhotoUrl,
  }) async {
    try {
      // Проверяем, существует ли событие
      final event = await getGuestEvent(eventId);
      if (event == null) {
        throw Exception('Событие не найдено');
      }

      // Проверяем, есть ли свободные места
      if (!event.hasAvailableSpots) {
        throw Exception('Нет свободных мест');
      }

      // Проверяем, не зарегистрирован ли уже гость с таким email
      final existingGuest = await _getGuestByEmail(eventId, guestEmail);
      if (existingGuest != null) {
        throw Exception('Гость с таким email уже зарегистрирован');
      }

      final guestRef = _firestore.collection('guests').doc();
      
      // Генерируем QR код для гостя
      final qrCode = await _generateGuestQRCode(guestRef.id);
      final invitationCode = _generateInvitationCode();

      final guest = Guest(
        id: guestRef.id,
        eventId: eventId,
        eventTitle: event.title,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        guestPhotoUrl: guestPhotoUrl,
        status: GuestStatus.registered,
        registeredAt: DateTime.now(),
        qrCode: qrCode,
        invitationCode: invitationCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await guestRef.set(guest.toMap());

      // Обновляем счетчик гостей в событии
      await _updateEventGuestCount(eventId, 1);

      return guestRef.id;
    } catch (e) {
      print('Ошибка регистрации гостя: $e');
      return null;
    }
  }

  /// Получить гостей события
  Stream<List<Guest>> getEventGuests(String eventId, GuestFilter filter) {
    Query query = _firestore
        .collection('guests')
        .where('eventId', isEqualTo: eventId);

    // Применяем фильтры
    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      query = query.where('status', whereIn: filter.statuses!.map((s) => s.name).toList());
    }

    if (filter.startDate != null) {
      query = query.where('registeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
    }

    if (filter.endDate != null) {
      query = query.where('registeredAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
    }

    // Сортировка по времени регистрации
    query = query.orderBy('registeredAt', descending: true);

    return query.snapshots().map((snapshot) {
      var guests = snapshot.docs
          .map((doc) => Guest.fromDocument(doc))
          .toList();

      // Применяем фильтры, которые нельзя применить в Firestore
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        guests = guests.where((guest) => 
            guest.guestName.toLowerCase().contains(query) ||
            guest.guestEmail.toLowerCase().contains(query)).toList();
      }

      if (filter.hasGreetings != null) {
        guests = guests.where((guest) => 
            filter.hasGreetings! ? guest.greetings.isNotEmpty : guest.greetings.isEmpty).toList();
      }

      if (filter.isCheckedIn != null) {
        guests = guests.where((guest) => 
            filter.isCheckedIn! ? guest.isCheckedIn : !guest.isCheckedIn).toList();
      }

      if (filter.isCheckedOut != null) {
        guests = guests.where((guest) => 
            filter.isCheckedOut! ? guest.isCheckedOut : !guest.isCheckedOut).toList();
      }

      return guests;
    });
  }

  /// Получить гостя по ID
  Future<Guest?> getGuest(String guestId) async {
    try {
      final doc = await _firestore.collection('guests').doc(guestId).get();
      if (doc.exists) {
        return Guest.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения гостя: $e');
      return null;
    }
  }

  /// Получить гостя по email
  Future<Guest?> _getGuestByEmail(String eventId, String email) async {
    try {
      final snapshot = await _firestore
          .collection('guests')
          .where('eventId', isEqualTo: eventId)
          .where('guestEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Guest.fromDocument(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Ошибка получения гостя по email: $e');
      return null;
    }
  }

  /// Подтвердить участие гостя
  Future<bool> confirmGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': GuestStatus.confirmed.name,
        'confirmedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка подтверждения гостя: $e');
      return false;
    }
  }

  /// Отменить участие гостя
  Future<bool> cancelGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': GuestStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка отмены участия гостя: $e');
      return false;
    }
  }

  /// Регистрация на мероприятие (check-in)
  Future<bool> checkInGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': GuestStatus.checkedIn.name,
        'checkedInAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка регистрации на мероприятие: $e');
      return false;
    }
  }

  /// Выход с мероприятия (check-out)
  Future<bool> checkOutGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': GuestStatus.checkedOut.name,
        'checkedOutAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка выхода с мероприятия: $e');
      return false;
    }
  }

  /// Добавить поздравление от гостя
  Future<String?> addGuestGreeting({
    required String guestId,
    required String guestName,
    required String message,
    String? photoUrl,
    String? videoUrl,
    GreetingType type = GreetingType.text,
    bool isPublic = true,
  }) async {
    try {
      final greetingRef = _firestore.collection('guest_greetings').doc();
      
      final greeting = GuestGreeting(
        id: greetingRef.id,
        guestId: guestId,
        guestName: guestName,
        message: message,
        photoUrl: photoUrl,
        videoUrl: videoUrl,
        type: type,
        isPublic: isPublic,
        createdAt: DateTime.now(),
      );

      await greetingRef.set(greeting.toMap());

      // Добавляем поздравление к гостю
      await _firestore.collection('guests').doc(guestId).update({
        'greetings': FieldValue.arrayUnion([greeting.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return greetingRef.id;
    } catch (e) {
      print('Ошибка добавления поздравления: $e');
      return null;
    }
  }

  /// Получить поздравления события
  Stream<List<GuestGreeting>> getEventGreetings(String eventId) {
    return _firestore
        .collection('guest_greetings')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GuestGreeting.fromMap(doc.data()))
          .toList();
    });
  }

  /// Загрузить фото для поздравления
  Future<String?> uploadGreetingPhoto(XFile imageFile) async {
    try {
      final fileName = 'greeting_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('guest_greetings/$fileName');
      
      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки фото поздравления: $e');
      return null;
    }
  }

  /// Загрузить видео для поздравления
  Future<String?> uploadGreetingVideo(XFile videoFile) async {
    try {
      final fileName = 'greeting_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('guest_greetings/$fileName');
      
      final uploadTask = ref.putFile(File(videoFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки видео поздравления: $e');
      return null;
    }
  }

  /// Выбрать фото из галереи
  Future<List<XFile>> pickPhotos({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images.take(maxImages).toList();
    } catch (e) {
      print('Ошибка выбора фото: $e');
      return [];
    }
  }

  /// Выбрать видео из галереи
  Future<XFile?> pickVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Ошибка выбора видео: $e');
      return null;
    }
  }

  /// Снять фото
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print('Ошибка съемки фото: $e');
      return null;
    }
  }

  /// Снять видео
  Future<XFile?> takeVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Ошибка съемки видео: $e');
      return null;
    }
  }

  /// Поделиться ссылкой на событие
  Future<void> shareEventLink(String eventId) async {
    try {
      final event = await getGuestEvent(eventId);
      if (event != null && event.invitationLink != null) {
        await Share.share(
          'Приглашаю вас на мероприятие "${event.title}"!\n\n'
          'Дата: ${_formatDate(event.startTime)}\n'
          'Место: ${event.location}\n\n'
          'Регистрация: ${event.invitationLink}',
          subject: 'Приглашение на мероприятие "${event.title}"',
        );
      }
    } catch (e) {
      print('Ошибка шаринга ссылки на событие: $e');
    }
  }

  /// Получить статистику гостей
  Future<GuestStats> getGuestStats(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('guests')
          .where('eventId', isEqualTo: eventId)
          .get();

      final guests = snapshot.docs
          .map((doc) => Guest.fromDocument(doc))
          .toList();

      return _calculateGuestStats(guests);
    } catch (e) {
      print('Ошибка получения статистики гостей: $e');
      return GuestStats.empty();
    }
  }

  /// Обновить счетчик гостей в событии
  Future<void> _updateEventGuestCount(String eventId, int delta) async {
    try {
      await _firestore.collection('guest_events').doc(eventId).update({
        'currentGuests': FieldValue.increment(delta),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления счетчика гостей: $e');
    }
  }

  /// Генерировать QR код для события
  Future<String> _generateQRCode(String eventId) async {
    // TODO: Реализовать генерацию QR кода
    return 'event_$eventId';
  }

  /// Генерировать QR код для гостя
  Future<String> _generateGuestQRCode(String guestId) async {
    // TODO: Реализовать генерацию QR кода для гостя
    return 'guest_$guestId';
  }

  /// Генерировать код приглашения
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    
    for (int i = 0; i < 6; i++) {
      code.write(chars[random % chars.length]);
    }
    
    return code.toString();
  }

  /// Подсчитать статистику гостей
  GuestStats _calculateGuestStats(List<Guest> guests) {
    final totalGuests = guests.length;
    final invitedGuests = guests.where((g) => g.status == GuestStatus.invited).length;
    final registeredGuests = guests.where((g) => g.status == GuestStatus.registered).length;
    final confirmedGuests = guests.where((g) => g.status == GuestStatus.confirmed).length;
    final checkedInGuests = guests.where((g) => g.status == GuestStatus.checkedIn).length;
    final checkedOutGuests = guests.where((g) => g.status == GuestStatus.checkedOut).length;
    final cancelledGuests = guests.where((g) => g.status == GuestStatus.cancelled).length;
    
    final totalGreetings = guests.fold<int>(0, (sum, guest) => sum + guest.greetingsCount);
    
    final attendanceRate = totalGuests > 0 ? checkedInGuests / totalGuests : 0.0;
    final confirmationRate = totalGuests > 0 ? confirmedGuests / totalGuests : 0.0;

    return GuestStats(
      totalGuests: totalGuests,
      invitedGuests: invitedGuests,
      registeredGuests: registeredGuests,
      confirmedGuests: confirmedGuests,
      checkedInGuests: checkedInGuests,
      checkedOutGuests: checkedOutGuests,
      cancelledGuests: cancelledGuests,
      totalGreetings: totalGreetings,
      attendanceRate: attendanceRate,
      confirmationRate: confirmationRate,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
