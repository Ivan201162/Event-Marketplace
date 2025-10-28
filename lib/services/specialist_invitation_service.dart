import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist_invitation.dart';
import 'package:event_marketplace_app/services/error_logging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для работы с приглашениями специалистов
class SpecialistInvitationService {
  factory SpecialistInvitationService() => _instance;
  SpecialistInvitationService._internal();
  static final SpecialistInvitationService _instance =
      SpecialistInvitationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  /// Создать приглашение специалиста
  Future<SpecialistInvitation?> createInvitation({
    required String orderId,
    required String specialistId,
    required String message,
    Duration? expirationDuration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await _errorLogger.logError(
          error: 'User not authenticated',
          stackTrace: StackTrace.current.toString(),
          action: 'create_invitation',
        );
        return null;
      }

      // Проверяем, не отправлено ли уже приглашение этому специалисту на этот заказ
      final existingInvitation = await _firestore
          .collection('specialist_invitations')
          .where('orderId', isEqualTo: orderId)
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: InvitationStatus.pending.name)
          .limit(1)
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        await _errorLogger.logWarning(
          warning: 'Invitation already exists for this specialist and order',
          action: 'create_invitation',
          additionalData: {'orderId': orderId, 'specialistId': specialistId},
        );
        return null;
      }

      final invitationId =
          _firestore.collection('specialist_invitations').doc().id;
      final now = DateTime.now();
      final expiresAt = expirationDuration != null
          ? now.add(expirationDuration)
          : now.add(const Duration(days: 7)); // По умолчанию 7 дней

      final invitation = SpecialistInvitation(
        id: invitationId,
        orderId: orderId,
        specialistId: specialistId,
        customerId: user.uid,
        message: message,
        status: InvitationStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
        metadata: metadata,
      );

      await _firestore
          .collection('specialist_invitations')
          .doc(invitationId)
          .set(invitation.toMap());

      await _errorLogger.logInfo(
        message: 'Specialist invitation created',
        userId: user.uid,
        action: 'create_invitation',
        additionalData: {
          'invitationId': invitationId,
          'orderId': orderId,
          'specialistId': specialistId,
        },
      );

      return invitation;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create invitation: $e',
        stackTrace: stackTrace.toString(),
        action: 'create_invitation',
        additionalData: {'orderId': orderId, 'specialistId': specialistId},
      );
      return null;
    }
  }

  /// Ответить на приглашение
  Future<bool> respondToInvitation(
    String invitationId, {
    required InvitationStatus status,
    String? responseMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.serverTimestamp(),
      };

      if (responseMessage != null && responseMessage.isNotEmpty) {
        updates['responseMessage'] = responseMessage;
      }

      await _firestore
          .collection('specialist_invitations')
          .doc(invitationId)
          .update(updates);

      // Обновляем статистику специалиста
      final invitation = await getInvitationById(invitationId);
      if (invitation != null) {
        await _updateSpecialistInvitationStats(invitation.specialistId);
      }

      await _errorLogger.logInfo(
        message: 'Invitation response recorded',
        userId: user.uid,
        action: 'respond_to_invitation',
        additionalData: {'invitationId': invitationId, 'status': status.name},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to respond to invitation: $e',
        stackTrace: stackTrace.toString(),
        action: 'respond_to_invitation',
        additionalData: {'invitationId': invitationId},
      );
      return false;
    }
  }

  /// Получить приглашения специалиста
  Future<List<SpecialistInvitation>> getSpecialistInvitations(
    String specialistId, {
    InvitationStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('specialist_invitations')
          .where('specialistId', isEqualTo: specialistId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(SpecialistInvitation.fromDoc).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get specialist invitations: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_specialist_invitations',
        additionalData: {'specialistId': specialistId},
      );
      return [];
    }
  }

  /// Получить приглашения заказчика
  Future<List<SpecialistInvitation>> getCustomerInvitations(
    String customerId, {
    InvitationStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('specialist_invitations')
          .where('customerId', isEqualTo: customerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(SpecialistInvitation.fromDoc).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get customer invitations: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_customer_invitations',
        additionalData: {'customerId': customerId},
      );
      return [];
    }
  }

  /// Получить приглашение по ID
  Future<SpecialistInvitation?> getInvitationById(String invitationId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('specialist_invitations')
          .doc(invitationId)
          .get();

      if (doc.exists) {
        return SpecialistInvitation.fromDoc(doc);
      }
      return null;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get invitation by ID: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_invitation_by_id',
        additionalData: {'invitationId': invitationId},
      );
      return null;
    }
  }

  /// Отменить приглашение
  Future<bool> cancelInvitation(String invitationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('specialist_invitations')
          .doc(invitationId)
          .update({
        'status': InvitationStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Обновляем статистику специалиста
      final invitation = await getInvitationById(invitationId);
      if (invitation != null) {
        await _updateSpecialistInvitationStats(invitation.specialistId);
      }

      await _errorLogger.logInfo(
        message: 'Invitation cancelled',
        userId: user.uid,
        action: 'cancel_invitation',
        additionalData: {'invitationId': invitationId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to cancel invitation: $e',
        stackTrace: stackTrace.toString(),
        action: 'cancel_invitation',
        additionalData: {'invitationId': invitationId},
      );
      return false;
    }
  }

  /// Получить статистику приглашений специалиста
  Future<InvitationStats?> getSpecialistInvitationStats(
      String specialistId,) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('invitation_stats')
          .doc(specialistId)
          .get();

      if (doc.exists) {
        return InvitationStats.fromMap(doc.data()! as Map<String, dynamic>);
      }

      // Если статистики нет, создаем ее
      return await _calculateAndSaveInvitationStats(specialistId);
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get specialist invitation stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_specialist_invitation_stats',
        additionalData: {'specialistId': specialistId},
      );
      return null;
    }
  }

  /// Массовое приглашение специалистов
  Future<List<SpecialistInvitation>> createBulkInvitations({
    required String orderId,
    required List<String> specialistIds,
    required String message,
    Duration? expirationDuration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await _errorLogger.logError(
          error: 'User not authenticated',
          stackTrace: StackTrace.current.toString(),
          action: 'create_bulk_invitations',
        );
        return [];
      }

      final invitations = <SpecialistInvitation>[];
      final batch = _firestore.batch();

      for (final specialistId in specialistIds) {
        // Проверяем, не отправлено ли уже приглашение
        final existingInvitation = await _firestore
            .collection('specialist_invitations')
            .where('orderId', isEqualTo: orderId)
            .where('specialistId', isEqualTo: specialistId)
            .where('status', isEqualTo: InvitationStatus.pending.name)
            .limit(1)
            .get();

        if (existingInvitation.docs.isNotEmpty) continue;

        final invitationId =
            _firestore.collection('specialist_invitations').doc().id;
        final now = DateTime.now();
        final expiresAt = expirationDuration != null
            ? now.add(expirationDuration)
            : now.add(const Duration(days: 7));

        final invitation = SpecialistInvitation(
          id: invitationId,
          orderId: orderId,
          specialistId: specialistId,
          customerId: user.uid,
          message: message,
          status: InvitationStatus.pending,
          createdAt: now,
          updatedAt: now,
          expiresAt: expiresAt,
          metadata: metadata,
        );

        invitations.add(invitation);
        batch.set(
          _firestore.collection('specialist_invitations').doc(invitationId),
          invitation.toMap(),
        );
      }

      if (invitations.isNotEmpty) {
        await batch.commit();
      }

      await _errorLogger.logInfo(
        message: 'Bulk invitations created',
        userId: user.uid,
        action: 'create_bulk_invitations',
        additionalData: {
          'orderId': orderId,
          'specialistIds': specialistIds,
          'createdCount': invitations.length,
        },
      );

      return invitations;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create bulk invitations: $e',
        stackTrace: stackTrace.toString(),
        action: 'create_bulk_invitations',
        additionalData: {'orderId': orderId, 'specialistIds': specialistIds},
      );
      return [];
    }
  }

  /// Поиск приглашений
  Future<List<SpecialistInvitation>> searchInvitations({
    String? query,
    String? specialistId,
    String? customerId,
    String? orderId,
    InvitationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('specialist_invitations');

      // Базовые фильтры
      if (specialistId != null) {
        firestoreQuery =
            firestoreQuery.where('specialistId', isEqualTo: specialistId);
      }
      if (customerId != null) {
        firestoreQuery =
            firestoreQuery.where('customerId', isEqualTo: customerId);
      }
      if (orderId != null) {
        firestoreQuery = firestoreQuery.where('orderId', isEqualTo: orderId);
      }
      if (status != null) {
        firestoreQuery = firestoreQuery.where('status', isEqualTo: status.name);
      }

      // Сортировка
      firestoreQuery = firestoreQuery
          .orderBy('createdAt', descending: true)
          .limit(limit * 2);

      final snapshot = await firestoreQuery.get();
      var invitations =
          snapshot.docs.map(SpecialistInvitation.fromDoc).toList();

      // Дополнительная фильтрация на клиенте
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        invitations = invitations
            .where(
              (invitation) =>
                  invitation.message.toLowerCase().contains(lowerQuery) ||
                  (invitation.responseMessage
                          ?.toLowerCase()
                          .contains(lowerQuery) ??
                      false),
            )
            .toList();
      }

      if (startDate != null) {
        invitations = invitations
            .where((invitation) => invitation.createdAt.isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        invitations = invitations
            .where((invitation) => invitation.createdAt.isBefore(endDate))
            .toList();
      }

      return invitations.take(limit).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to search invitations: $e',
        stackTrace: stackTrace.toString(),
        action: 'search_invitations',
        additionalData: {
          'query': query,
          'specialistId': specialistId,
          'customerId': customerId,
          'orderId': orderId,
          'status': status?.name,
        },
      );
      return [];
    }
  }

  /// Обновить статистику приглашений специалиста
  Future<void> _updateSpecialistInvitationStats(String specialistId) async {
    try {
      await _calculateAndSaveInvitationStats(specialistId);
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update specialist invitation stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_specialist_invitation_stats',
        additionalData: {'specialistId': specialistId},
      );
    }
  }

  /// Вычислить и сохранить статистику приглашений
  Future<InvitationStats?> _calculateAndSaveInvitationStats(
      String specialistId,) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('specialist_invitations')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final invitations =
          snapshot.docs.map(SpecialistInvitation.fromDoc).toList();

      if (invitations.isEmpty) return null;

      // Вычисляем статистику
      final totalInvitations = invitations.length;
      final acceptedInvitations = invitations
          .where((i) => i.status == InvitationStatus.accepted)
          .length;
      final declinedInvitations = invitations
          .where((i) => i.status == InvitationStatus.declined)
          .length;
      final pendingInvitations =
          invitations.where((i) => i.status == InvitationStatus.pending).length;
      final expiredInvitations =
          invitations.where((i) => i.status == InvitationStatus.expired).length;

      final respondedInvitations = acceptedInvitations + declinedInvitations;
      final acceptanceRate =
          totalInvitations > 0 ? acceptedInvitations / totalInvitations : 0.0;
      final responseRate =
          totalInvitations > 0 ? respondedInvitations / totalInvitations : 0.0;

      final stats = InvitationStats(
        specialistId: specialistId,
        totalInvitations: totalInvitations,
        acceptedInvitations: acceptedInvitations,
        declinedInvitations: declinedInvitations,
        pendingInvitations: pendingInvitations,
        expiredInvitations: expiredInvitations,
        acceptanceRate: acceptanceRate,
        responseRate: responseRate,
        lastUpdated: DateTime.now(),
      );

      // Сохраняем статистику
      await _firestore
          .collection('invitation_stats')
          .doc(specialistId)
          .set(stats.toMap());

      return stats;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to calculate and save invitation stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'calculate_and_save_invitation_stats',
        additionalData: {'specialistId': specialistId},
      );
      return null;
    }
  }

  /// Проверить истечение приглашений
  Future<void> checkExpiredInvitations() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot = await _firestore
          .collection('specialist_invitations')
          .where('status', isEqualTo: InvitationStatus.pending.name)
          .where('expiresAt', isLessThan: now)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {
            'status': InvitationStatus.expired.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        await _errorLogger.logInfo(
          message: 'Expired invitations updated',
          action: 'check_expired_invitations',
          additionalData: {'expiredCount': snapshot.docs.length},
        );
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to check expired invitations: $e',
        stackTrace: stackTrace.toString(),
        action: 'check_expired_invitations',
      );
    }
  }
}
