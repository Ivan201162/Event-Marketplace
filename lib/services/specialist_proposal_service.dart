import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/specialist_proposal.dart';
import 'fcm_service.dart';

/// Сервис для работы с предложениями специалистов
class SpecialistProposalService {
  static const String _collection = 'specialist_proposals';
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  /// Создать предложение специалистов
  Future<SpecialistProposal> createProposal(
    CreateSpecialistProposal data,
  ) async {
    if (!data.isValid) {
      throw Exception('Неверные данные: ${data.validationErrors.join(', ')}');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    // Получить данные организатора
    final organizerDoc = await _firestore.collection(_usersCollection).doc(data.organizerId).get();

    if (!organizerDoc.exists) {
      throw Exception('Организатор не найден');
    }

    final organizerData = organizerDoc.data()!;
    final organizer = AppUser.fromMap(organizerData);

    // Получить данные клиента
    final customerDoc = await _firestore.collection(_usersCollection).doc(data.customerId).get();

    if (!customerDoc.exists) {
      throw Exception('Клиент не найден');
    }

    final customerData = customerDoc.data()!;
    final customer = AppUser.fromMap(customerData);

    // Создать предложение
    final proposal = SpecialistProposal(
      id: '', // Будет установлен Firestore
      organizerId: data.organizerId,
      customerId: data.customerId,
      specialistIds: data.specialistIds,
      title: data.title,
      description: data.description,
      createdAt: DateTime.now(),
      organizerName: organizer.displayName,
      organizerAvatar: organizer.photoURL,
      customerName: customer.displayName,
      customerAvatar: customer.photoURL,
      metadata: data.metadata,
    );

    // Сохранить в Firestore
    final docRef = await _firestore.collection(_collection).add(proposal.toMap());

    // Обновить ID
    final createdProposal = proposal.copyWith(id: docRef.id);

    // Отправить уведомление клиенту
    await _fcmService.sendProposalNotification(
      customerId: data.customerId,
      organizerName: organizer.displayName,
      proposalTitle: data.title,
      specialistCount: data.specialistIds.length,
    );

    return createdProposal;
  }

  /// Получить предложения для клиента
  Future<List<SpecialistProposal>> getCustomerProposals(
    String customerId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(SpecialistProposal.fromDocument).toList();
  }

  /// Получить предложения от организатора
  Future<List<SpecialistProposal>> getOrganizerProposals(
    String organizerId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(SpecialistProposal.fromDocument).toList();
  }

  /// Получить предложение по ID
  Future<SpecialistProposal?> getProposal(String proposalId) async {
    final doc = await _firestore.collection(_collection).doc(proposalId).get();
    if (!doc.exists) return null;
    return SpecialistProposal.fromDocument(doc);
  }

  /// Принять предложение (выбрать специалиста)
  Future<void> acceptProposal(String proposalId, String specialistId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final proposal = await getProposal(proposalId);
    if (proposal == null) {
      throw Exception('Предложение не найдено');
    }

    if (proposal.customerId != currentUser.uid) {
      throw Exception('Только клиент может принять предложение');
    }

    if (!proposal.isActive) {
      throw Exception('Предложение уже обработано');
    }

    if (!proposal.specialistIds.contains(specialistId)) {
      throw Exception('Выбранный специалист не входит в предложение');
    }

    // Обновить предложение
    await _firestore.collection(_collection).doc(proposalId).update({
      'isAccepted': true,
      'acceptedSpecialistId': specialistId,
      'acceptedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Отправить уведомление организатору
    await _fcmService.sendProposalAcceptedNotification(
      organizerId: proposal.organizerId,
      customerName: proposal.customerName ?? 'Клиент',
      specialistId: specialistId,
    );
  }

  /// Отклонить предложение
  Future<void> rejectProposal(String proposalId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final proposal = await getProposal(proposalId);
    if (proposal == null) {
      throw Exception('Предложение не найдено');
    }

    if (proposal.customerId != currentUser.uid) {
      throw Exception('Только клиент может отклонить предложение');
    }

    if (!proposal.isActive) {
      throw Exception('Предложение уже обработано');
    }

    // Обновить предложение
    await _firestore.collection(_collection).doc(proposalId).update({
      'isRejected': true,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Отправить уведомление организатору
    await _fcmService.sendProposalRejectedNotification(
      organizerId: proposal.organizerId,
      customerName: proposal.customerName ?? 'Клиент',
    );
  }

  /// Удалить предложение (только организатор)
  Future<void> deleteProposal(String proposalId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final proposal = await getProposal(proposalId);
    if (proposal == null) {
      throw Exception('Предложение не найдено');
    }

    if (proposal.organizerId != currentUser.uid) {
      throw Exception('Только организатор может удалить предложение');
    }

    await _firestore.collection(_collection).doc(proposalId).delete();
  }

  /// Получить активные предложения для клиента
  Future<List<SpecialistProposal>> getActiveCustomerProposals(
    String customerId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .where('isAccepted', isEqualTo: false)
        .where('isRejected', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(SpecialistProposal.fromDocument).toList();
  }

  /// Получить статистику предложений организатора
  Future<Map<String, int>> getOrganizerStats(String organizerId) async {
    final snapshot =
        await _firestore.collection(_collection).where('organizerId', isEqualTo: organizerId).get();

    var total = 0;
    var accepted = 0;
    var rejected = 0;
    var pending = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      total++;

      if (data['isAccepted'] == true) {
        accepted++;
      } else if (data['isRejected'] == true) {
        rejected++;
      } else {
        pending++;
      }
    }

    return {
      'total': total,
      'accepted': accepted,
      'rejected': rejected,
      'pending': pending,
    };
  }

  /// Подписаться на изменения предложений для клиента
  Stream<List<SpecialistProposal>> watchCustomerProposals(String customerId) => _firestore
      .collection(_collection)
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(SpecialistProposal.fromDocument).toList(),
      );

  /// Подписаться на изменения предложений организатора
  Stream<List<SpecialistProposal>> watchOrganizerProposals(
    String organizerId,
  ) =>
      _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(SpecialistProposal.fromDocument).toList(),
          );
}
