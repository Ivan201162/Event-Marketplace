import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/partnership_program.dart';
import 'package:flutter/foundation.dart';

class PartnershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РЎРѕР·РґР°РЅРёРµ РЅРѕРІРѕРіРѕ РїР°СЂС‚РЅС‘СЂР°
  Future<String> createPartner({
    required String name,
    required String email,
    required String phone,
    required PartnershipType type,
    required double commissionRate,
    required CommissionType commissionType,
    String? description,
    String? website,
    String? contactPerson,
    String? companyName,
    String? inn,
    Map<String, dynamic>? socialMedia,
    Map<String, dynamic>? bankDetails,
    String? paymentMethod,
    double? minimumPayout,
    String? paymentSchedule,
    String? notes,
  }) async {
    try {
      final String partnerId = _uuid.v4();
      final String partnerCode = _generatePartnerCode();

      final Partner partner = Partner(
        id: partnerId,
        name: name,
        email: email,
        phone: phone,
        type: type,
        status: PartnershipStatus.pending,
        commissionRate: commissionRate,
        commissionType: commissionType,
        partnerCode: partnerCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: description,
        website: website,
        socialMedia: socialMedia,
        contactPerson: contactPerson,
        companyName: companyName,
        inn: inn,
        bankDetails: bankDetails,
        paymentMethod: paymentMethod,
        minimumPayout: minimumPayout ?? 1000.0,
        paymentSchedule: paymentSchedule,
        notes: notes,
      );

      await _firestore.collection('partners').doc(partnerId).set(partner.toMap());

      // РЎРѕР·РґР°РµРј РЅР°С‡Р°Р»СЊРЅСѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      await _createPartnerStats(partnerId);

      debugPrint('INFO: [PartnershipService] Partner created: $partnerId');
      return partnerId;
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to create partner: $e');
      rethrow;
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ СѓРЅРёРєР°Р»СЊРЅРѕРіРѕ РєРѕРґР° РїР°СЂС‚РЅС‘СЂР°
  String _generatePartnerCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    String code;
    bool isUnique = false;

    do {
      code = '';
      for (int i = 0; i < 8; i++) {
        code += chars[random.nextInt(chars.length)];
      }

      // РџСЂРѕРІРµСЂСЏРµРј СѓРЅРёРєР°Р»СЊРЅРѕСЃС‚СЊ (СѓРїСЂРѕС‰РµРЅРЅР°СЏ РїСЂРѕРІРµСЂРєР°)
      isUnique = true; // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅРѕ РїСЂРѕРІРµСЂРёС‚СЊ РІ Р‘Р”
    } while (!isUnique);

    return code;
  }

  /// РЎРѕР·РґР°РЅРёРµ РЅР°С‡Р°Р»СЊРЅРѕР№ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР°СЂС‚РЅС‘СЂР°
  Future<void> _createPartnerStats(String partnerId) async {
    try {
      final PartnerStats stats = PartnerStats(
        partnerId: partnerId,
        period: _getCurrentPeriod(),
        totalReferrals: 0,
        totalTransactions: 0,
        totalRevenue: 0.0,
        totalCommissions: 0.0,
        paidCommissions: 0.0,
        pendingCommissions: 0.0,
        conversionRate: 0.0,
        averageOrderValue: 0.0,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('partner_stats')
          .doc('${partnerId}_${_getCurrentPeriod()}')
          .set(stats.toMap());
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to create partner stats: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‚РµРєСѓС‰РµРіРѕ РїРµСЂРёРѕРґР°
  String _getCurrentPeriod() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// РђРєС‚РёРІР°С†РёСЏ РїР°СЂС‚РЅС‘СЂР°
  Future<void> activatePartner(String partnerId) async {
    try {
      await _firestore.collection('partners').doc(partnerId).update({
        'status': PartnershipStatus.active.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [PartnershipService] Partner activated: $partnerId');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to activate partner: $e');
      rethrow;
    }
  }

  /// РџСЂРёРѕСЃС‚Р°РЅРѕРІРєР° РїР°СЂС‚РЅС‘СЂР°
  Future<void> suspendPartner(String partnerId, String reason) async {
    try {
      await _firestore.collection('partners').doc(partnerId).update({
        'status': PartnershipStatus.suspended.toString().split('.').last,
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [PartnershipService] Partner suspended: $partnerId');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to suspend partner: $e');
      rethrow;
    }
  }

  /// Р РµРіРёСЃС‚СЂР°С†РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РїРѕ РїР°СЂС‚РЅС‘СЂСЃРєРѕР№ СЃСЃС‹Р»РєРµ
  Future<void> registerUserViaPartner({
    required String userId,
    required String partnerCode,
    required String transactionId,
    required double amount,
    required String currency,
  }) async {
    try {
      // РќР°С…РѕРґРёРј РїР°СЂС‚РЅС‘СЂР° РїРѕ РєРѕРґСѓ
      final QuerySnapshot partnerSnapshot = await _firestore
          .collection('partners')
          .where('partnerCode', isEqualTo: partnerCode)
          .where('status', isEqualTo: PartnershipStatus.active.toString().split('.').last)
          .limit(1)
          .get();

      if (partnerSnapshot.docs.isEmpty) {
        debugPrint('WARNING: [PartnershipService] Partner not found or inactive: $partnerCode');
        return;
      }

      final Partner partner =
          Partner.fromMap(partnerSnapshot.docs.first.data() as Map<String, dynamic>);

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј РєРѕРјРёСЃСЃРёСЋ
      final double commissionAmount = _calculateCommission(
        amount: amount,
        commissionRate: partner.commissionRate,
        commissionType: partner.commissionType,
      );

      // РЎРѕР·РґР°РµРј РїР°СЂС‚РЅС‘СЂСЃРєСѓСЋ С‚СЂР°РЅР·Р°РєС†РёСЋ
      final PartnerTransaction partnerTransaction = PartnerTransaction(
        id: _uuid.v4(),
        partnerId: partner.id,
        transactionId: transactionId,
        userId: userId,
        amount: amount,
        currency: currency,
        commissionAmount: commissionAmount,
        commissionRate: partner.commissionRate,
        commissionType: partner.commissionType,
        createdAt: DateTime.now(),
        description: 'Р РµРіРёСЃС‚СЂР°С†РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РїРѕ РїР°СЂС‚РЅС‘СЂСЃРєРѕР№ СЃСЃС‹Р»РєРµ',
      );

      await _firestore
          .collection('partner_transactions')
          .doc(partnerTransaction.id)
          .set(partnerTransaction.toMap());

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїР°СЂС‚РЅС‘СЂР°
      await _updatePartnerStats(partner.id, amount, commissionAmount);

      debugPrint(
          'INFO: [PartnershipService] User registered via partner: $userId -> ${partner.id}');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to register user via partner: $e');
    }
  }

  /// Р Р°СЃСЃС‡РµС‚ РєРѕРјРёСЃСЃРёРё
  double _calculateCommission({
    required double amount,
    required double commissionRate,
    required CommissionType commissionType,
  }) {
    switch (commissionType) {
      case CommissionType.percentage:
        return amount * (commissionRate / 100);
      case CommissionType.fixed:
        return commissionRate;
      case CommissionType.tiered:
        // РЈРїСЂРѕС‰РµРЅРЅР°СЏ Р»РѕРіРёРєР° РґР»СЏ РјРЅРѕРіРѕСѓСЂРѕРІРЅРµРІРѕР№ РєРѕРјРёСЃСЃРёРё
        if (amount >= 10000) {
          return amount * 0.15; // 15% РґР»СЏ РєСЂСѓРїРЅС‹С… Р·Р°РєР°Р·РѕРІ
        } else if (amount >= 5000) {
          return amount * 0.10; // 10% РґР»СЏ СЃСЂРµРґРЅРёС… Р·Р°РєР°Р·РѕРІ
        } else {
          return amount * 0.05; // 5% РґР»СЏ РјРµР»РєРёС… Р·Р°РєР°Р·РѕРІ
        }
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР°СЂС‚РЅС‘СЂР°
  Future<void> _updatePartnerStats(String partnerId, double amount, double commission) async {
    try {
      final String period = _getCurrentPeriod();
      final String statsId = '${partnerId}_$period';

      await _firestore.collection('partner_stats').doc(statsId).set({
        'partnerId': partnerId,
        'period': period,
        'totalTransactions': FieldValue.increment(1),
        'totalRevenue': FieldValue.increment(amount),
        'totalCommissions': FieldValue.increment(commission),
        'pendingCommissions': FieldValue.increment(commission),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('INFO: [PartnershipService] Partner stats updated: $partnerId');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to update partner stats: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РїР°СЂС‚РЅС‘СЂР° РїРѕ РєРѕРґСѓ
  Future<Partner?> getPartnerByCode(String partnerCode) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('partners')
          .where('partnerCode', isEqualTo: partnerCode)
          .where('status', isEqualTo: PartnershipStatus.active.toString().split('.').last)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Partner.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get partner by code: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР°СЂС‚РЅС‘СЂР°
  Future<PartnerStats?> getPartnerStats(String partnerId, {String? period}) async {
    try {
      final String statsPeriod = period ?? _getCurrentPeriod();
      final String statsId = '${partnerId}_$statsPeriod';

      final DocumentSnapshot doc = await _firestore.collection('partner_stats').doc(statsId).get();

      if (doc.exists) {
        return PartnerStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get partner stats: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‚СЂР°РЅР·Р°РєС†РёР№ РїР°СЂС‚РЅС‘СЂР°
  Future<List<PartnerTransaction>> getPartnerTransactions(
    String partnerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('partner_transactions')
          .where('partnerId', isEqualTo: partnerId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PartnerTransaction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get partner transactions: $e');
      return [];
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РІС‹РїР»Р°С‚С‹ РїР°СЂС‚РЅС‘СЂСѓ
  Future<String> createPartnerPayment({
    required String partnerId,
    required double amount,
    required String currency,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
    List<String>? transactionIds,
  }) async {
    try {
      final PartnerPayment payment = PartnerPayment(
        id: _uuid.v4(),
        partnerId: partnerId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        transactionIds: transactionIds ?? [],
      );

      await _firestore.collection('partner_payments').doc(payment.id).set(payment.toMap());

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚СѓСЃ С‚СЂР°РЅР·Р°РєС†РёР№
      if (transactionIds != null) {
        for (final transactionId in transactionIds) {
          await _firestore.collection('partner_transactions').doc(transactionId).update({
            'status': PaymentStatus.processed.toString().split('.').last,
            'paymentId': payment.id,
          });
        }
      }

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      await _firestore
          .collection('partner_stats')
          .doc('${partnerId}_${_getCurrentPeriod()}')
          .update({
        'paidCommissions': FieldValue.increment(amount),
        'pendingCommissions': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [PartnershipService] Partner payment created: ${payment.id}');
      return payment.id;
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to create partner payment: $e');
      rethrow;
    }
  }

  /// РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ РІС‹РїР»Р°С‚С‹
  Future<void> confirmPartnerPayment(String paymentId) async {
    try {
      await _firestore.collection('partner_payments').doc(paymentId).update({
        'status': PaymentStatus.paid.toString().split('.').last,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [PartnershipService] Partner payment confirmed: $paymentId');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to confirm partner payment: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РІС‹РїР»Р°С‚ РїР°СЂС‚РЅС‘СЂР°
  Future<List<PartnerPayment>> getPartnerPayments(
    String partnerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('partner_payments')
          .where('partnerId', isEqualTo: partnerId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PartnerPayment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get partner payments: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РІСЃРµС… РїР°СЂС‚РЅС‘СЂРѕРІ
  Future<List<Partner>> getAllPartners({
    PartnershipStatus? status,
    PartnershipType? type,
    int limit = 100,
  }) async {
    try {
      Query query =
          _firestore.collection('partners').orderBy('createdAt', descending: true).limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Partner.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get all partners: $e');
      return [];
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РїР°СЂС‚РЅС‘СЂР°
  Future<void> updatePartner(Partner partner) async {
    try {
      final Partner updatedPartner = partner.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('partners').doc(partner.id).set(updatedPartner.toMap());

      debugPrint('INFO: [PartnershipService] Partner updated: ${partner.id}');
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to update partner: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїР°СЂС‚РЅС‘СЂСЃРєРѕР№ СЃСЃС‹Р»РєРё
  String createPartnerLink(String partnerCode) {
    return 'https://eventmarketplace.app/partner/$partnerCode';
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РѕР±С‰РµР№ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР°СЂС‚РЅС‘СЂСЃРєРѕР№ РїСЂРѕРіСЂР°РјРјС‹
  Future<Map<String, dynamic>> getPartnershipProgramStats() async {
    try {
      final QuerySnapshot partnersSnapshot = await _firestore.collection('partners').get();

      final QuerySnapshot transactionsSnapshot =
          await _firestore.collection('partner_transactions').get();

      final QuerySnapshot paymentsSnapshot = await _firestore.collection('partner_payments').get();

      final int totalPartners = partnersSnapshot.docs.length;
      final int activePartners = partnersSnapshot.docs
          .where((doc) => Partner.fromMap(doc.data() as Map<String, dynamic>).isActive)
          .length;

      double totalCommissions = 0.0;
      double paidCommissions = 0.0;
      final int totalTransactions = transactionsSnapshot.docs.length;

      for (final doc in transactionsSnapshot.docs) {
        final PartnerTransaction transaction =
            PartnerTransaction.fromMap(doc.data() as Map<String, dynamic>);
        totalCommissions += transaction.commissionAmount;
      }

      for (final doc in paymentsSnapshot.docs) {
        final PartnerPayment payment = PartnerPayment.fromMap(doc.data() as Map<String, dynamic>);
        if (payment.isPaid) {
          paidCommissions += payment.amount;
        }
      }

      return {
        'totalPartners': totalPartners,
        'activePartners': activePartners,
        'totalTransactions': totalTransactions,
        'totalCommissions': totalCommissions,
        'paidCommissions': paidCommissions,
        'pendingCommissions': totalCommissions - paidCommissions,
        'averageCommissionPerTransaction':
            totalTransactions > 0 ? totalCommissions / totalTransactions : 0.0,
      };
    } catch (e) {
      debugPrint('ERROR: [PartnershipService] Failed to get partnership program stats: $e');
      return {};
    }
  }
}

