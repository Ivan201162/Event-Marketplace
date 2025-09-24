import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/proposal.dart';
import '../models/booking.dart';
import '../core/logger.dart';

/// Сервис для работы с предложениями специалистов
class ProposalService {
  factory ProposalService() => _instance;
  ProposalService._internal();
  static final ProposalService _instance = ProposalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создать предложение с скидкой
  Future<Proposal> createProposal({
    required String bookingId,
    required String specialistId,
    required String customerId,
    required double originalPrice,
    required double discountPercent,
    String? message,
    String? notes,
    Duration? expiresIn,
  }) async {
    try {
      AppLogger.logI('Создание предложения с скидкой $discountPercent%',
          'proposal_service');

      final finalPrice = originalPrice * (1 - discountPercent / 100);
      final expiresAt = expiresIn != null
          ? DateTime.now().add(expiresIn)
          : DateTime.now().add(const Duration(days: 7)); // По умолчанию 7 дней

      final proposal = Proposal(
        id: _uuid.v4(),
        bookingId: bookingId,
        specialistId: specialistId,
        customerId: customerId,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        finalPrice: finalPrice,
        status: ProposalStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        message: message,
        notes: notes,
      );

      await _firestore
          .collection('proposals')
          .doc(proposal.id)
          .set(proposal.toMap());

      AppLogger.logI('Предложение создано: ${proposal.id}', 'proposal_service');
      return proposal;
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка создания предложения', 'proposal_service', e, stackTrace);
      rethrow;
    }
  }

  /// Получить предложения по бронированию
  Future<List<Proposal>> getProposalsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Proposal.fromDocument(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка получения предложений', 'proposal_service', e, stackTrace);
      return [];
    }
  }

  /// Получить предложения специалиста
  Future<List<Proposal>> getProposalsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Proposal.fromDocument(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения предложений специалиста',
          'proposal_service', e, stackTrace);
      return [];
    }
  }

  /// Получить предложения заказчика
  Future<List<Proposal>> getProposalsByCustomer(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Proposal.fromDocument(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения предложений заказчика',
          'proposal_service', e, stackTrace);
      return [];
    }
  }

  /// Принять предложение
  Future<void> acceptProposal(String proposalId) async {
    try {
      AppLogger.logI('Принятие предложения: $proposalId', 'proposal_service');

      await _firestore.collection('proposals').doc(proposalId).update({
        'status': ProposalStatus.accepted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем бронирование с финальной ценой
      final proposalDoc =
          await _firestore.collection('proposals').doc(proposalId).get();
      if (proposalDoc.exists) {
        final proposal = Proposal.fromDocument(proposalDoc);
        await _firestore.collection('bookings').doc(proposal.bookingId).update({
          'totalPrice': proposal.finalPrice,
          'discountPercent': proposal.discountPercent,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      AppLogger.logI('Предложение принято: $proposalId', 'proposal_service');
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка принятия предложения', 'proposal_service', e, stackTrace);
      rethrow;
    }
  }

  /// Отклонить предложение
  Future<void> rejectProposal(String proposalId) async {
    try {
      AppLogger.logI('Отклонение предложения: $proposalId', 'proposal_service');

      await _firestore.collection('proposals').doc(proposalId).update({
        'status': ProposalStatus.rejected.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Предложение отклонено: $proposalId', 'proposal_service');
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка отклонения предложения', 'proposal_service', e, stackTrace);
      rethrow;
    }
  }

  /// Получить активные предложения (не истекшие)
  Future<List<Proposal>> getActiveProposals(String customerId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('proposals')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: ProposalStatus.pending.name)
          .get();

      return snapshot.docs
          .map((doc) => Proposal.fromDocument(doc))
          .where((proposal) =>
              proposal.expiresAt == null || proposal.expiresAt!.isAfter(now))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения активных предложений',
          'proposal_service', e, stackTrace);
      return [];
    }
  }

  /// Очистить истекшие предложения
  Future<void> cleanupExpiredProposals() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('proposals')
          .where('status', isEqualTo: ProposalStatus.pending.name)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final proposal = Proposal.fromDocument(doc);
        if (proposal.expiresAt != null && proposal.expiresAt!.isBefore(now)) {
          batch.update(doc.reference, {
            'status': ProposalStatus.expired.name,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      await batch.commit();
      AppLogger.logI('Истекшие предложения очищены', 'proposal_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка очистки истекших предложений', 'proposal_service',
          e, stackTrace);
    }
  }

  /// Получить статистику предложений специалиста
  Future<Map<String, dynamic>> getSpecialistProposalStats(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final proposals =
          snapshot.docs.map((doc) => Proposal.fromDocument(doc)).toList();

      final totalProposals = proposals.length;
      final acceptedProposals =
          proposals.where((p) => p.status == ProposalStatus.accepted).length;
      final rejectedProposals =
          proposals.where((p) => p.status == ProposalStatus.rejected).length;
      final pendingProposals =
          proposals.where((p) => p.status == ProposalStatus.pending).length;
      final expiredProposals =
          proposals.where((p) => p.status == ProposalStatus.expired).length;

      final avgDiscount = proposals.isNotEmpty
          ? proposals.map((p) => p.discountPercent).reduce((a, b) => a + b) /
              proposals.length
          : 0.0;

      return {
        'totalProposals': totalProposals,
        'acceptedProposals': acceptedProposals,
        'rejectedProposals': rejectedProposals,
        'pendingProposals': pendingProposals,
        'expiredProposals': expiredProposals,
        'acceptanceRate': totalProposals > 0
            ? (acceptedProposals / totalProposals) * 100
            : 0.0,
        'avgDiscount': avgDiscount,
      };
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения статистики предложений',
          'proposal_service', e, stackTrace);
      return {};
    }
  }
}
