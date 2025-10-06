import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organizer_proposal.dart';

/// Сервис для управления предложениями организаторов
class OrganizerProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать предложение организатора
  Future<String> createProposal(OrganizerProposal proposal) async {
    try {
      final docRef = await _firestore
          .collection('organizer_proposals')
          .add(proposal.toMap());
      return docRef.id;
    } catch (e) {
      print('Ошибка создания предложения: $e');
      throw Exception('Ошибка создания предложения: $e');
    }
  }

  /// Получить предложение по ID
  Future<OrganizerProposal?> getProposal(String proposalId) async {
    try {
      final doc = await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .get();

      if (doc.exists) {
        return OrganizerProposal.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения предложения: $e');
      return null;
    }
  }

  /// Получить все предложения организатора
  Future<List<OrganizerProposal>> getOrganizerProposals(
    String organizerId, {
    ProposalStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения предложений организатора: $e');
      return [];
    }
  }

  /// Получить все предложения для заказчика
  Future<List<OrganizerProposal>> getCustomerProposals(
    String customerId, {
    ProposalStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения предложений заказчика: $e');
      return [];
    }
  }

  /// Получить предложения по событию
  Future<List<OrganizerProposal>> getEventProposals(
    String eventId, {
    ProposalStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения предложений по событию: $e');
      return [];
    }
  }

  /// Обновить предложение
  Future<void> updateProposal(OrganizerProposal proposal) async {
    try {
      final updatedProposal = proposal.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('organizer_proposals')
          .doc(proposal.id)
          .update(updatedProposal.toMap());
    } catch (e) {
      print('Ошибка обновления предложения: $e');
      throw Exception('Ошибка обновления предложения: $e');
    }
  }

  /// Принять предложение
  Future<void> acceptProposal(
    String proposalId,
    String customerResponse,
  ) async {
    try {
      await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .update({
        'status': ProposalStatus.accepted.name,
        'customerResponse': customerResponse,
        'customerResponseAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка принятия предложения: $e');
      throw Exception('Ошибка принятия предложения: $e');
    }
  }

  /// Отклонить предложение
  Future<void> rejectProposal(
    String proposalId,
    String customerResponse,
  ) async {
    try {
      await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .update({
        'status': ProposalStatus.rejected.name,
        'customerResponse': customerResponse,
        'customerResponseAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка отклонения предложения: $e');
      throw Exception('Ошибка отклонения предложения: $e');
    }
  }

  /// Отменить предложение
  Future<void> cancelProposal(String proposalId) async {
    try {
      await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .update({
        'status': ProposalStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка отмены предложения: $e');
      throw Exception('Ошибка отмены предложения: $e');
    }
  }

  /// Завершить предложение
  Future<void> completeProposal(String proposalId) async {
    try {
      await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .update({
        'status': ProposalStatus.completed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка завершения предложения: $e');
      throw Exception('Ошибка завершения предложения: $e');
    }
  }

  /// Удалить предложение
  Future<void> deleteProposal(String proposalId) async {
    try {
      await _firestore
          .collection('organizer_proposals')
          .doc(proposalId)
          .delete();
    } catch (e) {
      print('Ошибка удаления предложения: $e');
      throw Exception('Ошибка удаления предложения: $e');
    }
  }

  /// Получить статистику предложений организатора
  Future<Map<String, int>> getOrganizerProposalStats(String organizerId) async {
    try {
      final proposals = await getOrganizerProposals(organizerId);

      final stats = <String, int>{
        'total': proposals.length,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'cancelled': 0,
        'completed': 0,
      };

      for (final proposal in proposals) {
        stats[proposal.status.name] = (stats[proposal.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Ошибка получения статистики предложений: $e');
      return {};
    }
  }

  /// Получить статистику предложений заказчика
  Future<Map<String, int>> getCustomerProposalStats(String customerId) async {
    try {
      final proposals = await getCustomerProposals(customerId);

      final stats = <String, int>{
        'total': proposals.length,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'cancelled': 0,
        'completed': 0,
      };

      for (final proposal in proposals) {
        stats[proposal.status.name] = (stats[proposal.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Ошибка получения статистики предложений: $e');
      return {};
    }
  }

  /// Поиск предложений по тексту
  Future<List<OrganizerProposal>> searchProposals(
    String searchQuery, {
    String? organizerId,
    String? customerId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .orderBy('title')
          .limit(limit);

      if (organizerId != null) {
        query = query.where('organizerId', isEqualTo: organizerId);
      }

      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }

      final querySnapshot = await query.get();
      final allProposals =
          querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();

      // Фильтруем результаты на клиенте
      final searchLower = searchQuery.toLowerCase();
      return allProposals
          .where(
            (proposal) =>
                proposal.title.toLowerCase().contains(searchLower) ||
                proposal.description.toLowerCase().contains(searchLower),
          )
          .toList();
    } catch (e) {
      print('Ошибка поиска предложений: $e');
      return [];
    }
  }

  /// Получить активные предложения (pending)
  Future<List<OrganizerProposal>> getActiveProposals({
    String? organizerId,
    String? customerId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .where('status', isEqualTo: ProposalStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (organizerId != null) {
        query = query.where('organizerId', isEqualTo: organizerId);
      }

      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения активных предложений: $e');
      return [];
    }
  }

  /// Получить принятые предложения
  Future<List<OrganizerProposal>> getAcceptedProposals({
    String? organizerId,
    String? customerId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_proposals')
          .where('status', isEqualTo: ProposalStatus.accepted.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (organizerId != null) {
        query = query.where('organizerId', isEqualTo: organizerId);
      }

      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProposal.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения принятых предложений: $e');
      return [];
    }
  }
}
