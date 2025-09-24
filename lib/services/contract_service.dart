import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../models/contract_models.dart';
import '../models/payment_models.dart';

/// Сервис для управления контрактами
class ContractService {
  factory ContractService() => _instance;
  ContractService._internal();
  static final ContractService _instance = ContractService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создать контракт
  Future<Contract> createContract({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double amount,
    required PaymentScheme paymentScheme,
    String? terms,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final contractId = _uuid.v4();
      final now = DateTime.now();

      // Рассчитываем суммы в зависимости от схемы оплаты
      double prepaymentAmount;
      double finalAmount;
      
      switch (paymentScheme) {
        case PaymentScheme.partialPrepayment:
          prepaymentAmount = amount * 0.3; // 30%
          finalAmount = amount * 0.7; // 70%
          break;
        case PaymentScheme.fullPrepayment:
          prepaymentAmount = amount; // 100%
          finalAmount = 0.0; // 0%
          break;
        case PaymentScheme.postPayment:
          prepaymentAmount = 0.0; // 0%
          finalAmount = amount; // 100%
          break;
      }

      final contract = Contract(
        id: contractId,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        status: ContractStatus.draft,
        createdAt: now,
        terms: terms ?? _getDefaultTerms(paymentScheme),
        amount: amount,
        prepaymentAmount: prepaymentAmount,
        finalAmount: finalAmount,
        metadata: metadata,
      );

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .set(contract.toMap());

      AppLogger.logI('Контракт создан: $contractId', 'contract_service');
      return contract;
    } catch (e) {
      AppLogger.logE('Ошибка создания контракта: $e', 'contract_service');
      rethrow;
    }
  }

  /// Обновить статус контракта
  Future<void> updateContractStatus({
    required String contractId,
    required ContractStatus status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      final now = DateTime.now();
      switch (status) {
        case ContractStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(now);
          break;
        case ContractStatus.cancelled:
          updateData['cancelledAt'] = Timestamp.fromDate(now);
          break;
        default:
          break;
      }

      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update(updateData);

      AppLogger.logI('Статус контракта обновлён: $contractId -> $status', 'contract_service');
    } catch (e) {
      AppLogger.logE('Ошибка обновления статуса контракта: $e', 'contract_service');
      rethrow;
    }
  }

  /// Подписать контракт клиентом
  Future<void> signContractByCustomer({
    required String contractId,
    required String signature,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
        'signedByCustomer': Timestamp.fromDate(now),
        'customerSignature': signature,
        'status': ContractStatus.pending.name, // Ожидает подписания специалистом
      });

      AppLogger.logI('Контракт подписан клиентом: $contractId', 'contract_service');
    } catch (e) {
      AppLogger.logE('Ошибка подписания контракта клиентом: $e', 'contract_service');
      rethrow;
    }
  }

  /// Подписать контракт специалистом
  Future<void> signContractBySpecialist({
    required String contractId,
    required String signature,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
        'signedBySpecialist': Timestamp.fromDate(now),
        'specialistSignature': signature,
        'status': ContractStatus.signed.name, // Контракт подписан
      });

      AppLogger.logI('Контракт подписан специалистом: $contractId', 'contract_service');
    } catch (e) {
      AppLogger.logE('Ошибка подписания контракта специалистом: $e', 'contract_service');
      rethrow;
    }
  }

  /// Завершить контракт
  Future<void> completeContract({
    required String contractId,
    String? actUrl,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
        'status': ContractStatus.completed.name,
        'completedAt': Timestamp.fromDate(now),
        if (actUrl != null) 'actUrl': actUrl,
      });

      AppLogger.logI('Контракт завершён: $contractId', 'contract_service');
    } catch (e) {
      AppLogger.logE('Ошибка завершения контракта: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить контракт по ID
  Future<Contract?> getContractById(String contractId) async {
    try {
      final doc = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Contract.fromMap(doc.data()!);
    } catch (e) {
      AppLogger.logE('Ошибка получения контракта: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить контракт по бронированию
  Future<Contract?> getContractByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Contract.fromMap(snapshot.docs.first.data());
    } catch (e) {
      AppLogger.logE('Ошибка получения контракта по бронированию: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить контракты по специалисту
  Future<List<Contract>> getContractsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      final contracts = snapshot.docs
          .map((doc) => Contract.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено контрактов для специалиста $specialistId: ${contracts.length}', 'contract_service');
      return contracts;
    } catch (e) {
      AppLogger.logE('Ошибка получения контрактов специалиста: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить контракты по клиенту
  Future<List<Contract>> getContractsByCustomer(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      final contracts = snapshot.docs
          .map((doc) => Contract.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено контрактов для клиента $customerId: ${contracts.length}', 'contract_service');
      return contracts;
    } catch (e) {
      AppLogger.logE('Ошибка получения контрактов клиента: $e', 'contract_service');
      rethrow;
    }
  }

  /// Создать документ
  Future<Document> createDocument({
    required String contractId,
    required DocumentType type,
    required String url,
    required String fileName,
    required int fileSize,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final documentId = _uuid.v4();
      final now = DateTime.now();

      final document = Document(
        id: documentId,
        contractId: contractId,
        type: type,
        url: url,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: now,
        metadata: metadata,
      );

      await _firestore
          .collection('documents')
          .doc(documentId)
          .set(document.toMap());

      AppLogger.logI('Документ создан: $documentId', 'contract_service');
      return document;
    } catch (e) {
      AppLogger.logE('Ошибка создания документа: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить документы по контракту
  Future<List<Document>> getDocumentsByContract(String contractId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('contractId', isEqualTo: contractId)
          .orderBy('createdAt', descending: true)
          .get();

      final documents = snapshot.docs
          .map((doc) => Document.fromMap(doc.data()))
          .toList();

      AppLogger.logI('Получено документов для контракта $contractId: ${documents.length}', 'contract_service');
      return documents;
    } catch (e) {
      AppLogger.logE('Ошибка получения документов: $e', 'contract_service');
      rethrow;
    }
  }

  /// Отметить документ как скачанный
  Future<void> markDocumentAsDownloaded(String documentId) async {
    try {
      await _firestore
          .collection('documents')
          .doc(documentId)
          .update({
        'downloadedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Документ отмечен как скачанный: $documentId', 'contract_service');
    } catch (e) {
      AppLogger.logE('Ошибка отметки документа как скачанного: $e', 'contract_service');
      rethrow;
    }
  }

  /// Получить стандартные условия договора
  String _getDefaultTerms(PaymentScheme scheme) {
    switch (scheme) {
      case PaymentScheme.partialPrepayment:
        return '''
УСЛОВИЯ ДОГОВОРА:

1. ОБЩИЕ ПОЛОЖЕНИЯ
1.1. Исполнитель обязуется оказать услуги, а Заказчик принять и оплатить их на условиях настоящего договора.

2. ПРЕДМЕТ ДОГОВОРА
2.1. Предметом договора является оказание услуг в соответствии с техническим заданием.

3. СТОИМОСТЬ И ПОРЯДОК РАСЧЕТОВ
3.1. Общая стоимость услуг составляет сумму, указанную в заявке.
3.2. Заказчик производит предоплату в размере 30% от общей стоимости услуг в течение 3 дней с момента подписания договора.
3.3. Оставшиеся 70% оплачиваются в течение 5 дней после подписания акта выполненных работ.

4. СРОКИ ВЫПОЛНЕНИЯ
4.1. Услуги должны быть выполнены в сроки, указанные в техническом задании.

5. ОТВЕТСТВЕННОСТЬ СТОРОН
5.1. За неисполнение или ненадлежащее исполнение обязательств по договору стороны несут ответственность в соответствии с действующим законодательством РФ.
        ''';
      case PaymentScheme.fullPrepayment:
        return '''
УСЛОВИЯ ДОГОВОРА:

1. ОБЩИЕ ПОЛОЖЕНИЯ
1.1. Исполнитель обязуется оказать услуги, а Заказчик принять и оплатить их на условиях настоящего договора.

2. ПРЕДМЕТ ДОГОВОРА
2.1. Предметом договора является оказание услуг в соответствии с техническим заданием.

3. СТОИМОСТЬ И ПОРЯДОК РАСЧЕТОВ
3.1. Общая стоимость услуг составляет сумму, указанную в заявке.
3.2. Заказчик производит полную предоплату в течение 3 дней с момента подписания договора.

4. СРОКИ ВЫПОЛНЕНИЯ
4.1. Услуги должны быть выполнены в сроки, указанные в техническом задании.

5. ОТВЕТСТВЕННОСТЬ СТОРОН
5.1. За неисполнение или ненадлежащее исполнение обязательств по договору стороны несут ответственность в соответствии с действующим законодательством РФ.
        ''';
      case PaymentScheme.postPayment:
        return '''
УСЛОВИЯ ДОГОВОРА:

1. ОБЩИЕ ПОЛОЖЕНИЯ
1.1. Исполнитель обязуется оказать услуги, а Заказчик принять и оплатить их на условиях настоящего договора.

2. ПРЕДМЕТ ДОГОВОРА
2.1. Предметом договора является оказание услуг в соответствии с техническим заданием.

3. СТОИМОСТЬ И ПОРЯДОК РАСЧЕТОВ
3.1. Общая стоимость услуг составляет сумму, указанную в заявке.
3.2. Заказчик производит оплату в полном размере в течение 30 дней после подписания акта выполненных работ.

4. СРОКИ ВЫПОЛНЕНИЯ
4.1. Услуги должны быть выполнены в сроки, указанные в техническом задании.

5. ОТВЕТСТВЕННОСТЬ СТОРОН
5.1. За неисполнение или ненадлежащее исполнение обязательств по договору стороны несут ответственность в соответствии с действующим законодательством РФ.
        ''';
    }
  }

  /// Генерировать PDF договора
  Future<String> generateContractPDF(Contract contract) async {
    try {
      // Здесь должна быть логика генерации PDF
      // Для демонстрации возвращаем URL
      final pdfUrl = 'https://storage.googleapis.com/contracts/${contract.id}.pdf';
      
      // Обновляем контракт с URL договора
      await _firestore
          .collection('contracts')
          .doc(contract.id)
          .update({
        'contractUrl': pdfUrl,
      });

      AppLogger.logI('PDF договора сгенерирован: $pdfUrl', 'contract_service');
      return pdfUrl;
    } catch (e) {
      AppLogger.logE('Ошибка генерации PDF договора: $e', 'contract_service');
      rethrow;
    }
  }

  /// Генерировать PDF акта выполненных работ
  Future<String> generateActPDF(Contract contract) async {
    try {
      // Здесь должна быть логика генерации PDF акта
      // Для демонстрации возвращаем URL
      final actUrl = 'https://storage.googleapis.com/acts/${contract.id}_act.pdf';
      
      // Обновляем контракт с URL акта
      await _firestore
          .collection('contracts')
          .doc(contract.id)
          .update({
        'actUrl': actUrl,
      });

      AppLogger.logI('PDF акта сгенерирован: $actUrl', 'contract_service');
      return actUrl;
    } catch (e) {
      AppLogger.logE('Ошибка генерации PDF акта: $e', 'contract_service');
      rethrow;
    }
  }
}