import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';
import 'payment_service.dart';

class DisputeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final Uuid _uuid = const Uuid();

  /// Creates a dispute
  Future<Dispute> createDispute({
    required String paymentId,
    required String reason,
    required String description,
    required String raisedBy, // User ID who raised the dispute
    DisputeType type = DisputeType.payment,
    List<String>? attachments, // URLs to supporting documents
  }) async {
    try {
      // Get the original payment
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Check if payment is eligible for dispute
      if (!_isPaymentEligibleForDispute(payment)) {
        throw Exception('Платеж не может быть оспорен');
      }

      final disputeId = _uuid.v4();
      final dispute = Dispute(
        id: disputeId,
        paymentId: paymentId,
        reason: reason,
        description: description,
        type: type,
        status: DisputeStatus.open,
        raisedBy: raisedBy,
        attachments: attachments ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save dispute to Firestore
      await _firestore
          .collection('disputes')
          .doc(disputeId)
          .set(dispute.toMap());

      // Update payment status to disputed
      await _paymentService.updatePaymentStatus(
        paymentId,
        PaymentStatus.disputed,
      );

      debugPrint('Dispute created: $disputeId');
      return dispute;
    } catch (e) {
      debugPrint('Error creating dispute: $e');
      throw Exception('Ошибка создания спора: $e');
    }
  }

  /// Updates dispute status
  Future<void> updateDisputeStatus(
    String disputeId,
    DisputeStatus status, {
    String? resolution,
    String? resolvedBy,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      if (resolvedBy != null) {
        updateData['resolvedBy'] = resolvedBy;
      }

      if (status == DisputeStatus.resolved) {
        updateData['resolvedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore.collection('disputes').doc(disputeId).update(updateData);

      // If dispute is resolved, update payment status
      if (status == DisputeStatus.resolved) {
        final dispute = await getDispute(disputeId);
        if (dispute != null) {
          await _paymentService.updatePaymentStatus(
            dispute.paymentId,
            PaymentStatus.completed,
          );
        }
      }

      debugPrint('Dispute status updated: $disputeId to $status');
    } catch (e) {
      debugPrint('Error updating dispute status: $e');
      throw Exception('Ошибка обновления статуса спора: $e');
    }
  }

  /// Adds a comment to a dispute
  Future<void> addDisputeComment({
    required String disputeId,
    required String comment,
    required String authorId,
    required String authorName,
  }) async {
    try {
      final commentId = _uuid.v4();
      final disputeComment = DisputeComment(
        id: commentId,
        disputeId: disputeId,
        comment: comment,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('disputes')
          .doc(disputeId)
          .collection('comments')
          .doc(commentId)
          .set(disputeComment.toMap());

      // Update dispute's updatedAt timestamp
      await _firestore.collection('disputes').doc(disputeId).update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Dispute comment added: $commentId');
    } catch (e) {
      debugPrint('Error adding dispute comment: $e');
      throw Exception('Ошибка добавления комментария к спору: $e');
    }
  }

  /// Gets dispute by ID
  Future<Dispute?> getDispute(String disputeId) async {
    try {
      final doc = await _firestore.collection('disputes').doc(disputeId).get();
      if (!doc.exists) return null;
      return Dispute.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting dispute: $e');
      return null;
    }
  }

  /// Gets disputes for a payment
  Future<List<Dispute>> getPaymentDisputes(String paymentId) async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .where('paymentId', isEqualTo: paymentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Dispute.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting payment disputes: $e');
      return [];
    }
  }

  /// Gets disputes for a user
  Future<List<Dispute>> getUserDisputes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .where('raisedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Dispute.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting user disputes: $e');
      return [];
    }
  }

  /// Gets all open disputes (for admin)
  Future<List<Dispute>> getOpenDisputes() async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Dispute.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting open disputes: $e');
      return [];
    }
  }

  /// Gets dispute comments
  Future<List<DisputeComment>> getDisputeComments(String disputeId) async {
    try {
      final snapshot = await _firestore
          .collection('disputes')
          .doc(disputeId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => DisputeComment.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting dispute comments: $e');
      return [];
    }
  }

  /// Escalates a dispute to admin
  Future<void> escalateDispute(String disputeId, String escalatedBy) async {
    try {
      await _firestore.collection('disputes').doc(disputeId).update({
        'status': 'escalated',
        'escalatedBy': escalatedBy,
        'escalatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Dispute escalated: $disputeId');
    } catch (e) {
      debugPrint('Error escalating dispute: $e');
      throw Exception('Ошибка эскалации спора: $e');
    }
  }

  /// Checks if payment is eligible for dispute
  bool _isPaymentEligibleForDispute(Payment payment) {
    // Only completed payments can be disputed
    if (payment.status != PaymentStatus.completed) {
      return false;
    }

    // Check if payment is within dispute window (typically 60 days)
    final daysSincePayment =
        DateTime.now().difference(payment.completedAt!).inDays;
    if (daysSincePayment > 60) {
      return false;
    }

    return true;
  }

  /// Gets dispute statistics
  Future<DisputeStatistics> getDisputeStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('disputes');

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();
      final disputes =
          snapshot.docs.map((doc) => Dispute.fromMap(doc.data())).toList();

      var openCount = 0;
      var resolvedCount = 0;
      var escalatedCount = 0;
      var closedCount = 0;

      for (final dispute in disputes) {
        switch (dispute.status) {
          case DisputeStatus.open:
            openCount++;
            break;
          case DisputeStatus.resolved:
            resolvedCount++;
            break;
          case DisputeStatus.escalated:
            escalatedCount++;
            break;
          case DisputeStatus.closed:
            closedCount++;
            break;
        }
      }

      return DisputeStatistics(
        totalDisputes: disputes.length,
        openDisputes: openCount,
        resolvedDisputes: resolvedCount,
        escalatedDisputes: escalatedCount,
        closedDisputes: closedCount,
        averageResolutionTime: _calculateAverageResolutionTime(disputes),
      );
    } catch (e) {
      debugPrint('Error getting dispute statistics: $e');
      return DisputeStatistics(
        totalDisputes: 0,
        openDisputes: 0,
        resolvedDisputes: 0,
        escalatedDisputes: 0,
        closedDisputes: 0,
        averageResolutionTime: 0,
      );
    }
  }

  /// Calculates average resolution time in days
  double _calculateAverageResolutionTime(List<Dispute> disputes) {
    final resolvedDisputes = disputes
        .where(
          (d) => d.status == DisputeStatus.resolved && d.resolvedAt != null,
        )
        .toList();

    if (resolvedDisputes.isEmpty) return 0;

    final totalDays = resolvedDisputes.fold(0, (sum, dispute) {
      final resolutionTime =
          dispute.resolvedAt!.difference(dispute.createdAt).inDays;
      return sum + resolutionTime;
    });

    return totalDays / resolvedDisputes.length;
  }
}

/// Dispute model
class Dispute {
  Dispute({
    required this.id,
    required this.paymentId,
    required this.reason,
    required this.description,
    required this.type,
    required this.status,
    required this.raisedBy,
    required this.attachments,
    this.resolution,
    this.resolvedBy,
    this.escalatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.escalatedAt,
  });

  factory Dispute.fromMap(Map<String, dynamic> map) => Dispute(
        id: map['id'] as String,
        paymentId: map['paymentId'] as String,
        reason: map['reason'] as String,
        description: map['description'] as String,
        type: DisputeType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'] as String,
        ),
        status: DisputeStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['status'] as String,
        ),
        raisedBy: map['raisedBy'] as String,
        attachments: List<String>.from(map['attachments'] as List<dynamic>),
        resolution: map['resolution'] as String?,
        resolvedBy: map['resolvedBy'] as String?,
        escalatedBy: map['escalatedBy'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
        escalatedAt: (map['escalatedAt'] as Timestamp?)?.toDate(),
      );
  final String id;
  final String paymentId;
  final String reason;
  final String description;
  final DisputeType type;
  final DisputeStatus status;
  final String raisedBy;
  final List<String> attachments;
  final String? resolution;
  final String? resolvedBy;
  final String? escalatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? escalatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'paymentId': paymentId,
        'reason': reason,
        'description': description,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'raisedBy': raisedBy,
        'attachments': attachments,
        'resolution': resolution,
        'resolvedBy': resolvedBy,
        'escalatedBy': escalatedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'escalatedAt':
            escalatedAt != null ? Timestamp.fromDate(escalatedAt!) : null,
      };
}

/// Dispute comment model
class DisputeComment {
  DisputeComment({
    required this.id,
    required this.disputeId,
    required this.comment,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory DisputeComment.fromMap(Map<String, dynamic> map) => DisputeComment(
        id: map['id'] as String,
        disputeId: map['disputeId'] as String,
        comment: map['comment'] as String,
        authorId: map['authorId'] as String,
        authorName: map['authorName'] as String,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
  final String id;
  final String disputeId;
  final String comment;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'disputeId': disputeId,
        'comment': comment,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Dispute types
enum DisputeType {
  payment, // Спор по платежу
  service, // Спор по услуге
  quality, // Спор по качеству
  other, // Другое
}

/// Dispute statuses
enum DisputeStatus {
  open, // Открыт
  escalated, // Эскалирован
  resolved, // Решен
  closed, // Закрыт
}

/// Dispute statistics
class DisputeStatistics {
  // in days

  DisputeStatistics({
    required this.totalDisputes,
    required this.openDisputes,
    required this.resolvedDisputes,
    required this.escalatedDisputes,
    required this.closedDisputes,
    required this.averageResolutionTime,
  });
  final int totalDisputes;
  final int openDisputes;
  final int resolvedDisputes;
  final int escalatedDisputes;
  final int closedDisputes;
  final double averageResolutionTime;
}
