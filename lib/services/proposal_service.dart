import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/specialist_proposal.dart';
import 'notification_service.dart';

class ProposalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'specialist_proposals';

  // Создание нового предложения
  static Future<String> createProposal({
    required String customerId,
    required String eventId,
    required List<String> specialistIds,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final proposalId = _firestore.collection(_collection).doc().id;
      final proposal = SpecialistProposal(
        id: proposalId,
        organizerId: currentUser.uid,
        customerId: customerId,
        eventId: eventId,
        specialistIds: specialistIds,
        status: 'pending',
        createdAt: DateTime.now(),
        message: message,
        metadata: metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(proposalId)
          .set(proposal.toMap());

      // Отправляем уведомление заказчику
      await NotificationService.sendProposalNotification(
        customerId: customerId,
        organizerId: currentUser.uid,
        proposalId: proposalId,
        specialistCount: specialistIds.length,
      );

      return proposalId;
    } catch (e) {
      throw Exception('Ошибка создания предложения: $e');
    }
  }

  // Принятие предложения
  static Future<void> acceptProposal(String proposalId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_collection).doc(proposalId).update({
        'status': 'accepted',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Отправляем уведомление организатору
      final proposal = await getProposal(proposalId);
      if (proposal != null) {
        await NotificationService.sendProposalAcceptedNotification(
          organizerId: proposal.organizerId,
          customerId: currentUser.uid,
          proposalId: proposalId,
        );
      }
    } catch (e) {
      throw Exception('Ошибка принятия предложения: $e');
    }
  }

  // Отклонение предложения
  static Future<void> rejectProposal(String proposalId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _firestore.collection(_collection).doc(proposalId).update({
        'status': 'rejected',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Отправляем уведомление организатору
      final proposal = await getProposal(proposalId);
      if (proposal != null) {
        await NotificationService.sendProposalRejectedNotification(
          organizerId: proposal.organizerId,
          customerId: currentUser.uid,
          proposalId: proposalId,
        );
      }
    } catch (e) {
      throw Exception('Ошибка отклонения предложения: $e');
    }
  }

  // Получение предложения по ID
  static Future<SpecialistProposal?> getProposal(String proposalId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(proposalId).get();
      if (doc.exists) {
        return SpecialistProposal.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения предложения: $e');
    }
  }

  // Получение всех предложений для заказчика
  static Stream<List<SpecialistProposal>> getCustomerProposals(
    String customerId,
  ) =>
      _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(SpecialistProposal.fromFirestore).toList(),
          );

  // Получение всех предложений от организатора
  static Stream<List<SpecialistProposal>> getOrganizerProposals(
    String organizerId,
  ) =>
      _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(SpecialistProposal.fromFirestore).toList(),
          );

  // Получение предложений по статусу
  static Stream<List<SpecialistProposal>> getProposalsByStatus(
    String userId,
    String status, {
    bool isCustomer = true,
  }) {
    final field = isCustomer ? 'customerId' : 'organizerId';
    return _firestore
        .collection(_collection)
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(SpecialistProposal.fromFirestore).toList(),
        );
  }

  // Получение активных предложений (pending)
  static Stream<List<SpecialistProposal>> getActiveProposals(String userId) =>
      getProposalsByStatus(userId, 'pending');

  // Удаление предложения
  static Future<void> deleteProposal(String proposalId) async {
    try {
      await _firestore.collection(_collection).doc(proposalId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления предложения: $e');
    }
  }

  // Обновление предложения
  static Future<void> updateProposal(
    String proposalId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection(_collection).doc(proposalId).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления предложения: $e');
    }
  }

  // Получение статистики предложений
  static Future<Map<String, int>> getProposalStats(String userId) async {
    try {
      final organizerProposals = await _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: userId)
          .get();

      final customerProposals = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'totalSent': organizerProposals.docs.length,
        'totalReceived': customerProposals.docs.length,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
      };

      // Подсчет статусов для отправленных предложений
      for (final doc in organizerProposals.docs) {
        final status = doc.data()['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      // Подсчет статусов для полученных предложений
      for (final doc in customerProposals.docs) {
        final status = doc.data()['status'] as String;
        stats['received_$status'] = (stats['received_$status'] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }
}
