import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/proposal.dart';
import '../models/specialist.dart';

/// Сервис для работы с предложениями специалистов
class ProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Создать предложение специалистов
  Future<String> createProposal({
    required String chatId,
    required String organizerId,
    required String customerId,
    required List<ProposalSpecialist> specialists,
    String? message,
  }) async {
    try {
      final now = DateTime.now();

      final proposal = Proposal(
        id: '', // Будет сгенерирован Firestore
        chatId: chatId,
        organizerId: organizerId,
        customerId: customerId,
        specialists: specialists,
        status: ProposalStatus.pending,
        message: message,
        createdAt: now,
        metadata: {
          'expiresAt': now.add(const Duration(hours: 24)).toIso8601String(),
        },
      );

      final docRef =
          await _firestore.collection('proposals').add(proposal.toMap());

      // Отправляем уведомление клиенту
      await _sendProposalNotification(customerId, proposal);

      // Логируем создание предложения
      await _logProposalAction(docRef.id, 'created', organizerId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания предложения: $e');
    }
  }

  /// Принять предложение
  Future<void> acceptProposal({
    required String proposalId,
    required String customerId,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore.collection('proposals').doc(proposalId).update({
        'status': ProposalStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(now),
        'respondedBy': customerId,
      });

      // Получаем данные предложения
      final proposalDoc =
          await _firestore.collection('proposals').doc(proposalId).get();
      if (!proposalDoc.exists) throw Exception('Предложение не найдено');

      final proposal = Proposal.fromDocument(proposalDoc);

      // Создаем бронирования для каждого специалиста
      for (final specialist in proposal.specialists) {
        await _createBookingFromProposal(proposal, specialist);
      }

      // Отправляем уведомление организатору
      await _sendProposalAcceptedNotification(proposal.organizerId, proposal);

      // Логируем принятие предложения
      await _logProposalAction(proposalId, 'accepted', customerId);
    } catch (e) {
      throw Exception('Ошибка принятия предложения: $e');
    }
  }

  /// Отклонить предложение
  Future<void> rejectProposal({
    required String proposalId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore.collection('proposals').doc(proposalId).update({
        'status': ProposalStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(now),
        'respondedBy': customerId,
        'metadata.rejectionReason': reason,
      });

      // Получаем данные предложения
      final proposalDoc =
          await _firestore.collection('proposals').doc(proposalId).get();
      if (!proposalDoc.exists) throw Exception('Предложение не найдено');

      final proposal = Proposal.fromDocument(proposalDoc);

      // Отправляем уведомление организатору
      await _sendProposalRejectedNotification(
        proposal.organizerId,
        proposal,
        reason,
      );

      // Логируем отклонение предложения
      await _logProposalAction(proposalId, 'rejected', customerId);
    } catch (e) {
      throw Exception('Ошибка отклонения предложения: $e');
    }
  }

  /// Получить предложения для чата
  Future<List<Proposal>> getChatProposals(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Proposal.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения предложений чата: $e');
    }
  }

  /// Получить предложения организатора
  Future<List<Proposal>> getOrganizerProposals(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Proposal.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения предложений организатора: $e');
    }
  }

  /// Получить предложения клиента
  Future<List<Proposal>> getCustomerProposals(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Proposal.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения предложений клиента: $e');
    }
  }

  /// Получить предложение по ID
  Future<Proposal?> getProposal(String proposalId) async {
    try {
      final doc =
          await _firestore.collection('proposals').doc(proposalId).get();
      if (doc.exists) {
        return Proposal.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения предложения: $e');
    }
  }

  /// Получить специалистов для предложения
  Future<List<Specialist>> getSpecialistsForProposal({
    required List<String> categoryIds,
    String? location,
    int limit = 10,
  }) async {
    try {
      var query = _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('categories', arrayContainsAny: categoryIds);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения специалистов для предложения: $e');
    }
  }

  /// Получить статистику предложений
  Future<Map<String, dynamic>> getProposalStats(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      var totalProposals = 0;
      var acceptedProposals = 0;
      var rejectedProposals = 0;
      var pendingProposals = 0;
      double totalRevenue = 0;

      for (final doc in snapshot.docs) {
        final proposal = Proposal.fromDocument(doc);
        totalProposals++;

        switch (proposal.status) {
          case ProposalStatus.accepted:
            acceptedProposals++;
            totalRevenue += proposal.totalCost;
            break;
          case ProposalStatus.rejected:
            rejectedProposals++;
            break;
          case ProposalStatus.pending:
            pendingProposals++;
            break;
          case ProposalStatus.expired:
            break;
        }
      }

      return {
        'totalProposals': totalProposals,
        'acceptedProposals': acceptedProposals,
        'rejectedProposals': rejectedProposals,
        'pendingProposals': pendingProposals,
        'acceptanceRate':
            totalProposals > 0 ? (acceptedProposals / totalProposals) * 100 : 0,
        'totalRevenue': totalRevenue,
        'averageProposalValue':
            acceptedProposals > 0 ? totalRevenue / acceptedProposals : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики предложений: $e');
    }
  }

  /// Создать бронирование из предложения
  Future<void> _createBookingFromProposal(
    Proposal proposal,
    ProposalSpecialist specialist,
  ) async {
    try {
      final now = DateTime.now();

      final booking = {
        'customerId': proposal.customerId,
        'specialistId': specialist.specialistId,
        'organizerId': proposal.organizerId,
        'categoryId': specialist.categoryId,
        'status': 'pending',
        'totalPrice': specialist.estimatedPrice,
        'description': specialist.description ?? proposal.message,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'metadata': {
          'proposalId': proposal.id,
          'proposalSpecialist': specialist.toMap(),
        },
      };

      await _firestore.collection('bookings').add(booking);
    } catch (e) {
      throw Exception('Ошибка создания бронирования из предложения: $e');
    }
  }

  /// Отправить уведомление о предложении
  Future<void> _sendProposalNotification(
    String customerId,
    Proposal proposal,
  ) async {
    try {
      // Получаем FCM токены клиента
      final customerDoc =
          await _firestore.collection('users').doc(customerId).get();
      if (!customerDoc.exists) return;

      final customerData = customerDoc.data();
      final fcmTokens = List<String>.from(customerData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Новое предложение специалистов',
        'body':
            'Организатор предложил ${proposal.specialistCount} специалистов для вашего мероприятия',
        'data': {
          'type': 'proposal_created',
          'proposalId': proposal.id,
          'specialistCount': proposal.specialistCount.toString(),
          'totalCost': proposal.totalCost.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления о предложении: $e');
    }
  }

  /// Отправить уведомление о принятии предложения
  Future<void> _sendProposalAcceptedNotification(
    String organizerId,
    Proposal proposal,
  ) async {
    try {
      // Получаем FCM токены организатора
      final organizerDoc =
          await _firestore.collection('users').doc(organizerId).get();
      if (!organizerDoc.exists) return;

      final organizerData = organizerDoc.data();
      final fcmTokens = List<String>.from(organizerData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Предложение принято',
        'body':
            'Клиент принял ваше предложение ${proposal.specialistCount} специалистов',
        'data': {
          'type': 'proposal_accepted',
          'proposalId': proposal.id,
          'specialistCount': proposal.specialistCount.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления о принятии предложения: $e');
    }
  }

  /// Отправить уведомление об отклонении предложения
  Future<void> _sendProposalRejectedNotification(
    String organizerId,
    Proposal proposal,
    String? reason,
  ) async {
    try {
      // Получаем FCM токены организатора
      final organizerDoc =
          await _firestore.collection('users').doc(organizerId).get();
      if (!organizerDoc.exists) return;

      final organizerData = organizerDoc.data();
      final fcmTokens = List<String>.from(organizerData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Предложение отклонено',
        'body': 'Клиент отклонил ваше предложение специалистов',
        'data': {
          'type': 'proposal_rejected',
          'proposalId': proposal.id,
          'reason': reason,
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления об отклонении предложения: $e');
    }
  }

  /// Логировать действие с предложением
  Future<void> _logProposalAction(
    String proposalId,
    String action,
    String userId,
  ) async {
    try {
      await _firestore.collection('proposalLogs').add({
        'proposalId': proposalId,
        'action': action,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка логирования действия с предложением: $e');
    }
  }
}
