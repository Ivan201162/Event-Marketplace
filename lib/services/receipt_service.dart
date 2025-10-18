import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/receipt_system.dart';
import 'package:flutter/foundation.dart';

class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РђРІС‚РѕРјР°С‚РёС‡РµСЃРєРѕРµ СЃРѕР·РґР°РЅРёРµ С‡РµРєР° РїРѕСЃР»Рµ СѓСЃРїРµС€РЅРѕРіРѕ РїР»Р°С‚РµР¶Р°
  Future<String> createReceipt({
    required String userId,
    required String transactionId,
    required double amount,
    required String currency,
    required ReceiptType type,
    PaymentProvider? paymentProvider,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РЅР°СЃС‚СЂРѕР№РєРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final ReceiptSettings? settings = await _getUserReceiptSettings(userId);

      if (settings != null && !settings.autoGenerate) {
        debugPrint('INFO: [ReceiptService] Auto-generate disabled for user $userId');
        return '';
      }

      // РЎРѕР·РґР°РµРј С‡РµРє
      final Receipt receipt = Receipt(
        id: _uuid.v4(),
        userId: userId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        type: type,
        status: ReceiptStatus.pending,
        createdAt: DateTime.now(),
        paymentProvider: paymentProvider,
        email: email ?? settings?.email,
        phone: phone ?? settings?.phone,
        metadata: metadata,
      );

      await _firestore.collection('receipts').doc(receipt.id).set(receipt.toMap());

      // Р“РµРЅРµСЂРёСЂСѓРµРј С‡РµРє
      await _generateReceipt(receipt);

      debugPrint('INFO: [ReceiptService] Receipt created: ${receipt.id}');
      return receipt.id;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to create receipt: $e');
      rethrow;
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ С‡РµРєР°
  Future<void> _generateReceipt(Receipt receipt) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј С€Р°Р±Р»РѕРЅ С‡РµРєР°
      final ReceiptTemplate? template = await _getReceiptTemplate(receipt.type);

      if (template == null) {
        await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, 'Template not found');
        return;
      }

      // Р“РµРЅРµСЂРёСЂСѓРµРј РґР°РЅРЅС‹Рµ С‡РµРєР°
      final Map<String, dynamic> receiptData = await _generateReceiptData(receipt, template);

      // РЎРѕР·РґР°РµРј С„РёСЃРєР°Р»СЊРЅС‹Р№ С‡РµРє (РµСЃР»Рё С‚СЂРµР±СѓРµС‚СЃСЏ)
      final FiscalReceipt? fiscalReceipt = await _createFiscalReceipt(receipt, receiptData);

      // РћР±РЅРѕРІР»СЏРµРј С‡РµРє
      await _firestore.collection('receipts').doc(receipt.id).update({
        'status': ReceiptStatus.generated.toString().split('.').last,
        'receiptData': receiptData,
        'fiscalData': fiscalReceipt?.toMap(),
        'qrCode': fiscalReceipt?.qrCode,
        'receiptUrl': await _generateReceiptUrl(receipt.id),
      });

      // РћС‚РїСЂР°РІР»СЏРµРј С‡РµРє РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
      await _sendReceipt(receipt);

      debugPrint('INFO: [ReceiptService] Receipt generated: ${receipt.id}');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to generate receipt: $e');
      await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, e.toString());
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РЅР°СЃС‚СЂРѕРµРє РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<ReceiptSettings?> _getUserReceiptSettings(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('receipt_settings').doc(userId).get();

      if (doc.exists) {
        return ReceiptSettings.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get user receipt settings: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С€Р°Р±Р»РѕРЅР° С‡РµРєР°
  Future<ReceiptTemplate?> _getReceiptTemplate(ReceiptType type) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('receipt_templates')
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReceiptTemplate.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get receipt template: $e');
      return null;
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РґР°РЅРЅС‹С… С‡РµРєР°
  Future<Map<String, dynamic>> _generateReceiptData(
    Receipt receipt,
    ReceiptTemplate template,
  ) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РґР°РЅРЅС‹Рµ С‚СЂР°РЅР·Р°РєС†РёРё
      final Map<String, dynamic> transactionData = await _getTransactionData(receipt.transactionId);

      // РџРѕР»СѓС‡Р°РµРј РґР°РЅРЅС‹Рµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final Map<String, dynamic> userData = await _getUserData(receipt.userId);

      // Р—Р°РїРѕР»РЅСЏРµРј С€Р°Р±Р»РѕРЅ
      final Map<String, dynamic> receiptData = {
        'receiptId': receipt.id,
        'transactionId': receipt.transactionId,
        'amount': receipt.amount,
        'currency': receipt.currency,
        'type': receipt.type.toString().split('.').last,
        'date': receipt.createdAt.toIso8601String(),
        'userName': userData['name'] ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        'userEmail': receipt.email ?? userData['email'],
        'userPhone': receipt.phone ?? userData['phone'],
        'paymentMethod': transactionData['paymentMethod'] ?? 'Р‘Р°РЅРєРѕРІСЃРєР°СЏ РєР°СЂС‚Р°',
        'paymentProvider': receipt.paymentProvider?.toString().split('.').last ?? 'yookassa',
        'description': _getReceiptDescription(receipt.type, transactionData),
        'items': _getReceiptItems(receipt.type, transactionData),
        'taxes': _calculateTaxes(receipt.amount),
        'total': receipt.amount,
        'template': template.template,
      };

      return receiptData;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to generate receipt data: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РґР°РЅРЅС‹С… С‚СЂР°РЅР·Р°РєС†РёРё
  Future<Map<String, dynamic>> _getTransactionData(String transactionId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get transaction data: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РґР°РЅРЅС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get user data: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РѕРїРёСЃР°РЅРёСЏ С‡РµРєР°
  String _getReceiptDescription(ReceiptType type, Map<String, dynamic> transactionData) {
    switch (type) {
      case ReceiptType.payment:
        return 'РћРїР»Р°С‚Р° СѓСЃР»СѓРі';
      case ReceiptType.subscription:
        return 'РџРѕРґРїРёСЃРєР° РЅР° СЃРµСЂРІРёСЃ';
      case ReceiptType.promotion:
        return 'РџСЂРѕРґРІРёР¶РµРЅРёРµ РїСЂРѕС„РёР»СЏ';
      case ReceiptType.advertisement:
        return 'Р РµРєР»Р°РјРЅР°СЏ РєР°РјРїР°РЅРёСЏ';
      case ReceiptType.refund:
        return 'Р’РѕР·РІСЂР°С‚ СЃСЂРµРґСЃС‚РІ';
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РїРѕР·РёС†РёР№ С‡РµРєР°
  List<Map<String, dynamic>> _getReceiptItems(
    ReceiptType type,
    Map<String, dynamic> transactionData,
  ) {
    switch (type) {
      case ReceiptType.payment:
        return [
          {
            'name': 'РћРїР»Р°С‚Р° СѓСЃР»СѓРі',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.subscription:
        return [
          {
            'name': 'РџРѕРґРїРёСЃРєР° ${transactionData['planName'] ?? 'Premium'}',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.promotion:
        return [
          {
            'name': 'РџСЂРѕРґРІРёР¶РµРЅРёРµ РїСЂРѕС„РёР»СЏ',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.advertisement:
        return [
          {
            'name': 'Р РµРєР»Р°РјРЅР°СЏ РєР°РјРїР°РЅРёСЏ',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.refund:
        return [
          {
            'name': 'Р’РѕР·РІСЂР°С‚ СЃСЂРµРґСЃС‚РІ',
            'quantity': 1,
            'price': -(transactionData['amount'] ?? 0.0),
            'total': -(transactionData['amount'] ?? 0.0),
          }
        ];
    }
  }

  /// Р Р°СЃС‡РµС‚ РЅР°Р»РѕРіРѕРІ
  Map<String, dynamic> _calculateTaxes(double amount) {
    // РЈРїСЂРѕС‰РµРЅРЅС‹Р№ СЂР°СЃС‡РµС‚ РќР”РЎ (20%)
    final double vatRate = 0.20;
    final double vatAmount = amount * vatRate;
    final double amountWithoutVat = amount - vatAmount;

    return {
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'amountWithoutVat': amountWithoutVat,
    };
  }

  /// РЎРѕР·РґР°РЅРёРµ С„РёСЃРєР°Р»СЊРЅРѕРіРѕ С‡РµРєР°
  Future<FiscalReceipt?> _createFiscalReceipt(
    Receipt receipt,
    Map<String, dynamic> receiptData,
  ) async {
    try {
      // РРЅС‚РµРіСЂР°С†РёСЏ СЃ 54-Р¤Р— (РѕРЅР»Р°Р№РЅ-РєР°СЃСЃР°)
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±СѓРґРµС‚ РІС‹Р·РѕРІ API С„РёСЃРєР°Р»СЊРЅРѕРіРѕ РѕРїРµСЂР°С‚РѕСЂР°

      final FiscalReceipt fiscalReceipt = FiscalReceipt(
        id: _uuid.v4(),
        receiptId: receipt.id,
        fiscalDocumentNumber: _generateFiscalDocumentNumber(),
        fiscalSign: _generateFiscalSign(),
        fiscalDriveNumber: '0000000000000000',
        fiscalDocumentId: _generateFiscalDocumentId(),
        fiscalTimestamp: DateTime.now(),
        operator: 'Event Marketplace',
        inn: '1234567890', // РРќРќ РѕСЂРіР°РЅРёР·Р°С†РёРё
        kktRegNumber: '0000000000000000', // Р РµРіРёСЃС‚СЂР°С†РёРѕРЅРЅС‹Р№ РЅРѕРјРµСЂ РљРљРў
        createdAt: DateTime.now(),
        fiscalData: receiptData,
        qrCode: _generateQRCode(receipt.id),
        ofdUrl: 'https://ofd.example.com/receipt/${receipt.id}',
      );

      await _firestore
          .collection('fiscal_receipts')
          .doc(fiscalReceipt.id)
          .set(fiscalReceipt.toMap());

      debugPrint('INFO: [ReceiptService] Fiscal receipt created: ${fiscalReceipt.id}');
      return fiscalReceipt;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to create fiscal receipt: $e');
      return null;
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РЅРѕРјРµСЂР° С„РёСЃРєР°Р»СЊРЅРѕРіРѕ РґРѕРєСѓРјРµРЅС‚Р°
  String _generateFiscalDocumentNumber() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ С„РёСЃРєР°Р»СЊРЅРѕРіРѕ РїСЂРёР·РЅР°РєР°
  String _generateFiscalSign() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ ID С„РёСЃРєР°Р»СЊРЅРѕРіРѕ РґРѕРєСѓРјРµРЅС‚Р°
  String _generateFiscalDocumentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ QR-РєРѕРґР°
  String _generateQRCode(String receiptId) {
    return 't=20240101T120000&s=1000.00&fn=1234567890&i=1&fp=1234567890&n=1';
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ URL С‡РµРєР°
  Future<String> _generateReceiptUrl(String receiptId) async {
    // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±СѓРґРµС‚ РіРµРЅРµСЂР°С†РёСЏ URL РґР»СЏ РїСЂРѕСЃРјРѕС‚СЂР° С‡РµРєР°
    return 'https://eventmarketplace.app/receipts/$receiptId';
  }

  /// РћС‚РїСЂР°РІРєР° С‡РµРєР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
  Future<void> _sendReceipt(Receipt receipt) async {
    try {
      final ReceiptSettings? settings = await _getUserReceiptSettings(receipt.userId);

      if (settings == null) return;

      bool sent = false;

      // РћС‚РїСЂР°РІРєР° РїРѕ email
      if (settings.sendByEmail && receipt.email != null) {
        await _sendReceiptByEmail(receipt);
        sent = true;
      }

      // РћС‚РїСЂР°РІРєР° РїРѕ SMS
      if (settings.sendBySms && receipt.phone != null) {
        await _sendReceiptBySms(receipt);
        sent = true;
      }

      if (sent) {
        await _updateReceiptStatus(receipt.id, ReceiptStatus.sent);
      }

      debugPrint('INFO: [ReceiptService] Receipt sent: ${receipt.id}');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to send receipt: $e');
      await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, e.toString());
    }
  }

  /// РћС‚РїСЂР°РІРєР° С‡РµРєР° РїРѕ email
  Future<void> _sendReceiptByEmail(Receipt receipt) async {
    try {
      // РРЅС‚РµРіСЂР°С†РёСЏ СЃ email СЃРµСЂРІРёСЃРѕРј
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±СѓРґРµС‚ РІС‹Р·РѕРІ API email СЃРµСЂРІРёСЃР°

      debugPrint('INFO: [ReceiptService] Receipt sent by email to ${receipt.email}');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to send receipt by email: $e');
      rethrow;
    }
  }

  /// РћС‚РїСЂР°РІРєР° С‡РµРєР° РїРѕ SMS
  Future<void> _sendReceiptBySms(Receipt receipt) async {
    try {
      // РРЅС‚РµРіСЂР°С†РёСЏ СЃ SMS СЃРµСЂРІРёСЃРѕРј
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±СѓРґРµС‚ РІС‹Р·РѕРІ API SMS СЃРµСЂРІРёСЃР°

      debugPrint('INFO: [ReceiptService] Receipt sent by SMS to ${receipt.phone}');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to send receipt by SMS: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ СЃС‚Р°С‚СѓСЃР° С‡РµРєР°
  Future<void> _updateReceiptStatus(
    String receiptId,
    ReceiptStatus status, [
    String? failedReason,
  ]) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ReceiptStatus.sent) {
        updateData['sentAt'] = FieldValue.serverTimestamp();
      }

      if (status == ReceiptStatus.failed && failedReason != null) {
        updateData['failedReason'] = failedReason;
      }

      await _firestore.collection('receipts').doc(receiptId).update(updateData);
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to update receipt status: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‡РµРєРѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<Receipt>> getUserReceipts(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('receipts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Receipt.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get user receipts: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‡РµРєР° РїРѕ ID
  Future<Receipt?> getReceipt(String receiptId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('receipts').doc(receiptId).get();

      if (doc.exists) {
        return Receipt.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to get receipt: $e');
      return null;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РЅР°СЃС‚СЂРѕРµРє С‡РµРєРѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<void> updateReceiptSettings(ReceiptSettings settings) async {
    try {
      await _firestore.collection('receipt_settings').doc(settings.userId).set(settings.toMap());

      debugPrint('INFO: [ReceiptService] Receipt settings updated for user ${settings.userId}');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to update receipt settings: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ С€Р°Р±Р»РѕРЅР° С‡РµРєР°
  Future<String> createReceiptTemplate(ReceiptTemplate template) async {
    try {
      final String templateId = _uuid.v4();
      final ReceiptTemplate newTemplate = ReceiptTemplate(
        id: templateId,
        name: template.name,
        type: template.type,
        template: template.template,
        isActive: template.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: template.description,
        variables: template.variables,
        metadata: template.metadata,
      );

      await _firestore.collection('receipt_templates').doc(templateId).set(newTemplate.toMap());

      debugPrint('INFO: [ReceiptService] Receipt template created: $templateId');
      return templateId;
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to create receipt template: $e');
      rethrow;
    }
  }

  /// РџРѕРІС‚РѕСЂРЅР°СЏ РѕС‚РїСЂР°РІРєР° С‡РµРєР°
  Future<void> resendReceipt(String receiptId) async {
    try {
      final Receipt? receipt = await getReceipt(receiptId);
      if (receipt == null) {
        throw Exception('Receipt not found');
      }

      await _sendReceipt(receipt);
      debugPrint('INFO: [ReceiptService] Receipt resent: $receiptId');
    } catch (e) {
      debugPrint('ERROR: [ReceiptService] Failed to resend receipt: $e');
      rethrow;
    }
  }
}

