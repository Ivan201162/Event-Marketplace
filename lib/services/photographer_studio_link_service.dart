import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/photo_studio.dart';
import '../models/photographer_studio_link.dart';
import 'fcm_service.dart';

/// Сервис для работы со связками фотографов и фотостудий
class PhotographerStudioLinkService {
  static const String _linksCollection = 'photographer_studio_links';
  static const String _suggestionsCollection = 'studio_suggestions';
  static const String _usersCollection = 'users';
  static const String _studiosCollection = 'photo_studios';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  /// Создать связку фотографа и фотостудии
  Future<PhotographerStudioLink> createLink(
      CreatePhotographerStudioLink data) async {
    if (!data.isValid) {
      throw Exception('Неверные данные: ${data.validationErrors.join(', ')}');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (data.photographerId != currentUser.uid) {
      throw Exception('Только фотограф может создавать связки');
    }

    // Проверить, не существует ли уже связка
    final existingLink = await _getLinkByPhotographerAndStudio(
        data.photographerId, data.studioId);
    if (existingLink != null) {
      throw Exception('Связка с этой фотостудией уже существует');
    }

    // Получить данные фотографа
    final photographerDoc = await _firestore
        .collection(_usersCollection)
        .doc(data.photographerId)
        .get();

    if (!photographerDoc.exists) {
      throw Exception('Фотограф не найден');
    }

    final photographerData = photographerDoc.data()!;
    final photographer = AppUser.fromMap(photographerData);

    // Получить данные фотостудии
    final studioDoc = await _firestore
        .collection(_studiosCollection)
        .doc(data.studioId)
        .get();

    if (!studioDoc.exists) {
      throw Exception('Фотостудия не найдена');
    }

    final studioData = studioDoc.data()!;
    final studio = PhotoStudio.fromMap(studioData);

    // Создать связку
    final link = PhotographerStudioLink(
      id: '', // Будет установлен Firestore
      photographerId: data.photographerId,
      studioId: data.studioId,
      status: 'pending',
      createdAt: DateTime.now(),
      photographerName: photographer.displayName,
      photographerAvatar: photographer.photoURL,
      studioName: studio.name,
      studioAvatar: studio.avatarUrl,
      notes: data.notes,
      commissionRate: data.commissionRate,
      metadata: data.metadata,
    );

    // Сохранить в Firestore
    final docRef =
        await _firestore.collection(_linksCollection).add(link.toMap());

    // Обновить ID
    final createdLink = link.copyWith(id: docRef.id);

    // Отправить уведомление владельцу фотостудии
    await _fcmService.sendStudioLinkRequestNotification(
      studioOwnerId: studio.ownerId,
      photographerName: photographer.displayName,
      studioName: studio.name,
    );

    return createdLink;
  }

  /// Получить связку по ID
  Future<PhotographerStudioLink?> getLink(String linkId) async {
    final doc = await _firestore.collection(_linksCollection).doc(linkId).get();
    if (!doc.exists) return null;
    return PhotographerStudioLink.fromDocument(doc);
  }

  /// Получить связку по фотографу и фотостудии
  Future<PhotographerStudioLink?> _getLinkByPhotographerAndStudio(
    String photographerId,
    String studioId,
  ) async {
    final snapshot = await _firestore
        .collection(_linksCollection)
        .where('photographerId', isEqualTo: photographerId)
        .where('studioId', isEqualTo: studioId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PhotographerStudioLink.fromDocument(snapshot.docs.first);
  }

  /// Получить связки фотографа
  Future<List<PhotographerStudioLink>> getPhotographerLinks(
      String photographerId) async {
    final snapshot = await _firestore
        .collection(_linksCollection)
        .where('photographerId', isEqualTo: photographerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(PhotographerStudioLink.fromDocument).toList();
  }

  /// Получить связки фотостудии
  Future<List<PhotographerStudioLink>> getStudioLinks(String studioId) async {
    final snapshot = await _firestore
        .collection(_linksCollection)
        .where('studioId', isEqualTo: studioId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(PhotographerStudioLink.fromDocument).toList();
  }

  /// Обновить статус связки
  Future<void> updateLinkStatus(String linkId, String status) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final link = await getLink(linkId);
    if (link == null) {
      throw Exception('Связка не найдена');
    }

    // Проверить права доступа
    final studio = await _firestore
        .collection(_studiosCollection)
        .doc(link.studioId)
        .get();
    if (!studio.exists) {
      throw Exception('Фотостудия не найдена');
    }

    final studioData = studio.data()!;
    final studioOwnerId = studioData['ownerId'] as String;

    if (currentUser.uid != studioOwnerId) {
      throw Exception(
          'Только владелец фотостудии может изменять статус связки');
    }

    await _firestore.collection(_linksCollection).doc(linkId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Отправить уведомление фотографу
    await _fcmService.sendStudioLinkStatusNotification(
      photographerId: link.photographerId,
      studioName: link.studioName ?? 'Фотостудия',
      status: status,
    );
  }

  /// Удалить связку
  Future<void> deleteLink(String linkId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final link = await getLink(linkId);
    if (link == null) {
      throw Exception('Связка не найдена');
    }

    if (currentUser.uid != link.photographerId) {
      throw Exception('Только фотограф может удалять связку');
    }

    await _firestore.collection(_linksCollection).doc(linkId).delete();
  }

  /// Создать предложение фотостудии для заказа
  Future<StudioSuggestion> createStudioSuggestion({
    required String bookingId,
    required String photographerId,
    required String studioId,
    String? notes,
    double? suggestedPrice,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (photographerId != currentUser.uid) {
      throw Exception('Только фотограф может создавать предложения');
    }

    // Проверить, что связка активна
    final link =
        await _getLinkByPhotographerAndStudio(photographerId, studioId);
    if (link == null || !link.isActive) {
      throw Exception('Связка с фотостудией не активна');
    }

    // Получить данные фотографа
    final photographerDoc =
        await _firestore.collection(_usersCollection).doc(photographerId).get();

    if (!photographerDoc.exists) {
      throw Exception('Фотограф не найден');
    }

    final photographerData = photographerDoc.data()!;
    final photographer = AppUser.fromMap(photographerData);

    // Получить данные фотостудии
    final studioDoc =
        await _firestore.collection(_studiosCollection).doc(studioId).get();

    if (!studioDoc.exists) {
      throw Exception('Фотостудия не найдена');
    }

    final studioData = studioDoc.data()!;
    final studio = PhotoStudio.fromMap(studioData);

    // Создать предложение
    final suggestion = StudioSuggestion(
      id: '', // Будет установлен Firestore
      bookingId: bookingId,
      photographerId: photographerId,
      studioId: studioId,
      suggestedAt: DateTime.now(),
      photographerName: photographer.displayName,
      photographerAvatar: photographer.photoURL,
      studioName: studio.name,
      studioAvatar: studio.avatarUrl,
      studioAddress: studio.address,
      studioPhone: studio.phone,
      studioEmail: studio.email,
      suggestedPrice: suggestedPrice,
      notes: notes,
    );

    // Сохранить в Firestore
    final docRef = await _firestore
        .collection(_suggestionsCollection)
        .add(suggestion.toMap());

    // Обновить ID
    final createdSuggestion = StudioSuggestion(
      id: docRef.id,
      bookingId: suggestion.bookingId,
      photographerId: suggestion.photographerId,
      studioId: suggestion.studioId,
      suggestedAt: suggestion.suggestedAt,
      photographerName: suggestion.photographerName,
      photographerAvatar: suggestion.photographerAvatar,
      studioName: suggestion.studioName,
      studioAvatar: suggestion.studioAvatar,
      studioAddress: suggestion.studioAddress,
      studioPhone: suggestion.studioPhone,
      studioEmail: suggestion.studioEmail,
      suggestedPrice: suggestion.suggestedPrice,
      notes: suggestion.notes,
    );

    // Отправить уведомление клиенту
    // TODO(developer): Получить ID клиента из бронирования
    // await _fcmService.sendStudioSuggestionNotification(
    //   customerId: customerId,
    //   photographerName: photographer.displayName,
    //   studioName: studio.name,
    //   suggestedPrice: suggestedPrice,
    // );

    return createdSuggestion;
  }

  /// Получить предложения для заказа
  Future<List<StudioSuggestion>> getBookingSuggestions(String bookingId) async {
    final snapshot = await _firestore
        .collection(_suggestionsCollection)
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('suggestedAt', descending: true)
        .get();

    return snapshot.docs.map(StudioSuggestion.fromDocument).toList();
  }

  /// Принять предложение фотостудии
  Future<void> acceptStudioSuggestion(String suggestionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final suggestionDoc = await _firestore
        .collection(_suggestionsCollection)
        .doc(suggestionId)
        .get();
    if (!suggestionDoc.exists) {
      throw Exception('Предложение не найдено');
    }

    final suggestion = StudioSuggestion.fromDocument(suggestionDoc);

    // TODO(developer): Проверить, что текущий пользователь - клиент заказа
    // if (currentUser.uid != customerId) {
    //   throw Exception('Только клиент может принимать предложения');
    // }

    await _firestore
        .collection(_suggestionsCollection)
        .doc(suggestionId)
        .update({
      'isAccepted': true,
      'acceptedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Отправить уведомление фотографу
    await _fcmService.sendStudioSuggestionAcceptedNotification(
      photographerId: suggestion.photographerId,
      studioName: suggestion.studioName ?? 'Фотостудия',
    );
  }

  /// Отклонить предложение фотостудии
  Future<void> rejectStudioSuggestion(String suggestionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final suggestionDoc = await _firestore
        .collection(_suggestionsCollection)
        .doc(suggestionId)
        .get();
    if (!suggestionDoc.exists) {
      throw Exception('Предложение не найдено');
    }

    final suggestion = StudioSuggestion.fromDocument(suggestionDoc);

    // TODO(developer): Проверить, что текущий пользователь - клиент заказа
    // if (currentUser.uid != customerId) {
    //   throw Exception('Только клиент может отклонять предложения');
    // }

    await _firestore
        .collection(_suggestionsCollection)
        .doc(suggestionId)
        .update({
      'isRejected': true,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Получить рекомендуемые фотостудии для фотографа
  Future<List<PhotoStudio>> getRecommendedStudios(String photographerId) async {
    // Получить все активные связки фотографа
    final links = await getPhotographerLinks(photographerId);
    final linkedStudioIds = links.map((link) => link.studioId).toList();

    // Получить все фотостудии, исключая уже связанные
    final snapshot = await _firestore
        .collection(_studiosCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(10)
        .get();

    final allStudios = snapshot.docs.map(PhotoStudio.fromDocument).toList();

    // Исключить уже связанные студии
    return allStudios
        .where((studio) => !linkedStudioIds.contains(studio.id))
        .toList();
  }

  /// Подписаться на изменения связок фотографа
  Stream<List<PhotographerStudioLink>> watchPhotographerLinks(
          String photographerId) =>
      _firestore
          .collection(_linksCollection)
          .where('photographerId', isEqualTo: photographerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(PhotographerStudioLink.fromDocument).toList());

  /// Подписаться на изменения связок фотостудии
  Stream<List<PhotographerStudioLink>> watchStudioLinks(String studioId) =>
      _firestore
          .collection(_linksCollection)
          .where('studioId', isEqualTo: studioId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(PhotographerStudioLink.fromDocument).toList());

  /// Подписаться на изменения предложений для заказа
  Stream<List<StudioSuggestion>> watchBookingSuggestions(String bookingId) =>
      _firestore
          .collection(_suggestionsCollection)
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('suggestedAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(StudioSuggestion.fromDocument).toList());
}
