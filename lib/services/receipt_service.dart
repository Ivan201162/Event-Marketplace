import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/receipt_system.dart';

class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Автоматическое создание чека после успешного платежа
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
      // Получаем настройки пользователя
      final ReceiptSettings? settings = await _getUserReceiptSettings(userId);

      if (settings != null && !settings.autoGenerate) {
        debugdebugPrint('INFO: [ReceiptService] Auto-generate disabled for user $userId');
        return '';
      }

      // Создаем чек
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

      // Генерируем чек
      await _generateReceipt(receipt);

      debugdebugPrint('INFO: [ReceiptService] Receipt created: ${receipt.id}');
      return receipt.id;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to create receipt: $e');
      rethrow;
    }
  }

  /// Генерация чека
  Future<void> _generateReceipt(Receipt receipt) async {
    try {
      // Получаем шаблон чека
      final ReceiptTemplate? template = await _getReceiptTemplate(receipt.type);

      if (template == null) {
        await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, 'Template not found');
        return;
      }

      // Генерируем данные чека
      final Map<String, dynamic> receiptData = await _generateReceiptData(receipt, template);

      // Создаем фискальный чек (если требуется)
      final FiscalReceipt? fiscalReceipt = await _createFiscalReceipt(receipt, receiptData);

      // Обновляем чек
      await _firestore.collection('receipts').doc(receipt.id).update({
        'status': ReceiptStatus.generated.toString().split('.').last,
        'receiptData': receiptData,
        'fiscalData': fiscalReceipt?.toMap(),
        'qrCode': fiscalReceipt?.qrCode,
        'receiptUrl': await _generateReceiptUrl(receipt.id),
      });

      // Отправляем чек пользователю
      await _sendReceipt(receipt);

      debugdebugPrint('INFO: [ReceiptService] Receipt generated: ${receipt.id}');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to generate receipt: $e');
      await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, e.toString());
    }
  }

  /// Получение настроек пользователя
  Future<ReceiptSettings?> _getUserReceiptSettings(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('receipt_settings').doc(userId).get();

      if (doc.exists) {
        return ReceiptSettings.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to get user receipt settings: $e');
      return null;
    }
  }

  /// Получение шаблона чека
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
      debugdebugPrint('ERROR: [ReceiptService] Failed to get receipt template: $e');
      return null;
    }
  }

  /// Генерация данных чека
  Future<Map<String, dynamic>> _generateReceiptData(
    Receipt receipt,
    ReceiptTemplate template,
  ) async {
    try {
      // Получаем данные транзакции
      final Map<String, dynamic> transactionData = await _getTransactionData(receipt.transactionId);

      // Получаем данные пользователя
      final Map<String, dynamic> userData = await _getUserData(receipt.userId);

      // Заполняем шаблон
      final Map<String, dynamic> receiptData = {
        'receiptId': receipt.id,
        'transactionId': receipt.transactionId,
        'amount': receipt.amount,
        'currency': receipt.currency,
        'type': receipt.type.toString().split('.').last,
        'date': receipt.createdAt.toIso8601String(),
        'userName': userData['name'] ?? 'Пользователь',
        'userEmail': receipt.email ?? userData['email'],
        'userPhone': receipt.phone ?? userData['phone'],
        'paymentMethod': transactionData['paymentMethod'] ?? 'Банковская карта',
        'paymentProvider': receipt.paymentProvider?.toString().split('.').last ?? 'yookassa',
        'description': _getReceiptDescription(receipt.type, transactionData),
        'items': _getReceiptItems(receipt.type, transactionData),
        'taxes': _calculateTaxes(receipt.amount),
        'total': receipt.amount,
        'template': template.template,
      };

      return receiptData;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to generate receipt data: $e');
      return {};
    }
  }

  /// Получение данных транзакции
  Future<Map<String, dynamic>> _getTransactionData(String transactionId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to get transaction data: $e');
      return {};
    }
  }

  /// Получение данных пользователя
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to get user data: $e');
      return {};
    }
  }

  /// Получение описания чека
  String _getReceiptDescription(ReceiptType type, Map<String, dynamic> transactionData) {
    switch (type) {
      case ReceiptType.payment:
        return 'Оплата услуг';
      case ReceiptType.subscription:
        return 'Подписка на сервис';
      case ReceiptType.promotion:
        return 'Продвижение профиля';
      case ReceiptType.advertisement:
        return 'Рекламная кампания';
      case ReceiptType.refund:
        return 'Возврат средств';
    }
  }

  /// Получение позиций чека
  List<Map<String, dynamic>> _getReceiptItems(
    ReceiptType type,
    Map<String, dynamic> transactionData,
  ) {
    switch (type) {
      case ReceiptType.payment:
        return [
          {
            'name': 'Оплата услуг',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.subscription:
        return [
          {
            'name': 'Подписка ${transactionData['planName'] ?? 'Premium'}',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.promotion:
        return [
          {
            'name': 'Продвижение профиля',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.advertisement:
        return [
          {
            'name': 'Рекламная кампания',
            'quantity': 1,
            'price': transactionData['amount'] ?? 0.0,
            'total': transactionData['amount'] ?? 0.0,
          }
        ];
      case ReceiptType.refund:
        return [
          {
            'name': 'Возврат средств',
            'quantity': 1,
            'price': -(transactionData['amount'] ?? 0.0),
            'total': -(transactionData['amount'] ?? 0.0),
          }
        ];
    }
  }

  /// Расчет налогов
  Map<String, dynamic> _calculateTaxes(double amount) {
    // Упрощенный расчет НДС (20%)
    const double vatRate = 0.20;
    final double vatAmount = amount * vatRate;
    final double amountWithoutVat = amount - vatAmount;

    return {
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'amountWithoutVat': amountWithoutVat,
    };
  }

  /// Создание фискального чека
  Future<FiscalReceipt?> _createFiscalReceipt(
    Receipt receipt,
    Map<String, dynamic> receiptData,
  ) async {
    try {
      // Интеграция с 54-ФЗ (онлайн-касса)
      // В реальном приложении здесь будет вызов API фискального оператора

      final FiscalReceipt fiscalReceipt = FiscalReceipt(
        id: _uuid.v4(),
        receiptId: receipt.id,
        fiscalDocumentNumber: _generateFiscalDocumentNumber(),
        fiscalSign: _generateFiscalSign(),
        fiscalDriveNumber: '0000000000000000',
        fiscalDocumentId: _generateFiscalDocumentId(),
        fiscalTimestamp: DateTime.now(),
        operator: 'Event Marketplace',
        inn: '1234567890', // ИНН организации
        kktRegNumber: '0000000000000000', // Регистрационный номер ККТ
        createdAt: DateTime.now(),
        fiscalData: receiptData,
        qrCode: _generateQRCode(receipt.id),
        ofdUrl: 'https://ofd.example.com/receipt/${receipt.id}',
      );

      await _firestore
          .collection('fiscal_receipts')
          .doc(fiscalReceipt.id)
          .set(fiscalReceipt.toMap());

      debugdebugPrint('INFO: [ReceiptService] Fiscal receipt created: ${fiscalReceipt.id}');
      return fiscalReceipt;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to create fiscal receipt: $e');
      return null;
    }
  }

  /// Генерация номера фискального документа
  String _generateFiscalDocumentNumber() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Генерация фискального признака
  String _generateFiscalSign() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
  }

  /// Генерация ID фискального документа
  String _generateFiscalDocumentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Генерация QR-кода
  String _generateQRCode(String receiptId) {
    return 't=20240101T120000&s=1000.00&fn=1234567890&i=1&fp=1234567890&n=1';
  }

  /// Генерация URL чека
  Future<String> _generateReceiptUrl(String receiptId) async {
    // В реальном приложении здесь будет генерация URL для просмотра чека
    return 'https://eventmarketplace.app/receipts/$receiptId';
  }

  /// Отправка чека пользователю
  Future<void> _sendReceipt(Receipt receipt) async {
    try {
      final ReceiptSettings? settings = await _getUserReceiptSettings(receipt.userId);

      if (settings == null) return;

      bool sent = false;

      // Отправка по email
      if (settings.sendByEmail && receipt.email != null) {
        await _sendReceiptByEmail(receipt);
        sent = true;
      }

      // Отправка по SMS
      if (settings.sendBySms && receipt.phone != null) {
        await _sendReceiptBySms(receipt);
        sent = true;
      }

      if (sent) {
        await _updateReceiptStatus(receipt.id, ReceiptStatus.sent);
      }

      debugdebugPrint('INFO: [ReceiptService] Receipt sent: ${receipt.id}');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to send receipt: $e');
      await _updateReceiptStatus(receipt.id, ReceiptStatus.failed, e.toString());
    }
  }

  /// Отправка чека по email
  Future<void> _sendReceiptByEmail(Receipt receipt) async {
    try {
      // Интеграция с email сервисом
      // В реальном приложении здесь будет вызов API email сервиса

      debugdebugPrint('INFO: [ReceiptService] Receipt sent by email to ${receipt.email}');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to send receipt by email: $e');
      rethrow;
    }
  }

  /// Отправка чека по SMS
  Future<void> _sendReceiptBySms(Receipt receipt) async {
    try {
      // Интеграция с SMS сервисом
      // В реальном приложении здесь будет вызов API SMS сервиса

      debugdebugPrint('INFO: [ReceiptService] Receipt sent by SMS to ${receipt.phone}');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to send receipt by SMS: $e');
      rethrow;
    }
  }

  /// Обновление статуса чека
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
      debugdebugPrint('ERROR: [ReceiptService] Failed to update receipt status: $e');
    }
  }

  /// Получение чеков пользователя
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
      debugdebugPrint('ERROR: [ReceiptService] Failed to get user receipts: $e');
      return [];
    }
  }

  /// Получение чека по ID
  Future<Receipt?> getReceipt(String receiptId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('receipts').doc(receiptId).get();

      if (doc.exists) {
        return Receipt.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to get receipt: $e');
      return null;
    }
  }

  /// Обновление настроек чеков пользователя
  Future<void> updateReceiptSettings(ReceiptSettings settings) async {
    try {
      await _firestore.collection('receipt_settings').doc(settings.userId).set(settings.toMap());

      debugdebugPrint(
          'INFO: [ReceiptService] Receipt settings updated for user ${settings.userId}');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to update receipt settings: $e');
      rethrow;
    }
  }

  /// Создание шаблона чека
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

      debugdebugPrint('INFO: [ReceiptService] Receipt template created: $templateId');
      return templateId;
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to create receipt template: $e');
      rethrow;
    }
  }

  /// Повторная отправка чека
  Future<void> resendReceipt(String receiptId) async {
    try {
      final Receipt? receipt = await getReceipt(receiptId);
      if (receipt == null) {
        throw Exception('Receipt not found');
      }

      await _sendReceipt(receipt);
      debugdebugPrint('INFO: [ReceiptService] Receipt resent: $receiptId');
    } catch (e) {
      debugdebugPrint('ERROR: [ReceiptService] Failed to resend receipt: $e');
      rethrow;
    }
  }
}
