import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/contract.dart' as contract_model;
import '../models/work_act.dart' as work_act_model;
import '../models/booking.dart';
import '../models/app_user.dart';

/// Сервис для работы с договорами и актами
class ContractService {
  static final ContractService _instance = ContractService._internal();
  factory ContractService() => _instance;
  ContractService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать договор при подтверждении бронирования
  Future<contract_model.Contract?> createContractFromBooking({
    required Booking booking,
    required AppUser customer,
    required AppUser specialist,
    required List<contract_model.ContractService> services,
    required double totalAmount,
    required double advanceAmount,
    required double finalAmount,
    required String currency,
  }) async {
    try {
      AppLogger.logI('Создание договора для бронирования ${booking.id}', 'contract_service');

      final contractId = 'contract_${booking.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      final contract = contract_model.Contract(
        id: contractId,
        bookingId: booking.id,
        customerId: customer.id,
        specialistId: specialist.id,
        customerName: customer.displayName ?? 'Не указано',
        specialistName: specialist.displayName ?? 'Не указано',
        customerType: _getOrganizationType(customer),
        specialistType: _getOrganizationType(specialist),
        customerDetails: _getCustomerDetails(customer),
        specialistDetails: _getSpecialistDetails(specialist),
        services: services,
        totalAmount: totalAmount,
        advanceAmount: advanceAmount,
        finalAmount: finalAmount,
        currency: currency,
        eventDate: booking.eventDate,
        eventLocation: booking.location,
        status: contract_model.ContractStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем договор в Firestore
      await _firestore.collection('contracts').doc(contractId).set(contract.toMap());
      
      AppLogger.logI('Договор $contractId создан успешно', 'contract_service');
      return contract;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка создания договора', 'contract_service', e, stackTrace);
      return null;
    }
  }

  /// Создать акт выполненных работ
  Future<work_act_model.WorkAct?> createWorkActFromContract({
    required contract_model.Contract contract,
    required String description,
    List<String>? photos,
  }) async {
    try {
      AppLogger.logI('Создание акта выполненных работ для договора ${contract.id}', 'contract_service');

      final workActId = 'workact_${contract.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      final workAct = work_act_model.WorkAct(
        id: workActId,
        contractId: contract.id,
        bookingId: contract.bookingId,
        customerId: contract.customerId,
        specialistId: contract.specialistId,
        customerName: contract.customerName,
        specialistName: contract.specialistName,
        services: contract.services.map((service) => WorkActService(
          name: service.name,
          description: service.description,
          price: service.price,
          currency: service.currency,
          quantity: service.quantity,
          unit: service.unit,
          isCompleted: true,
        )).toList(),
        totalAmount: contract.totalAmount,
        currency: contract.currency,
        eventDate: contract.eventDate,
        eventLocation: contract.eventLocation,
        description: description,
        photos: photos,
        status: work_act_model.WorkActStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем акт в Firestore
      await _firestore.collection('work_acts').doc(workActId).set(workAct.toMap());
      
      AppLogger.logI('Акт выполненных работ $workActId создан успешно', 'contract_service');
      return workAct;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка создания акта выполненных работ', 'contract_service', e, stackTrace);
      return null;
    }
  }

  /// Подписать договор
  Future<bool> signContract({
    required String contractId,
    required String signature,
    required bool isCustomer,
  }) async {
    try {
      final updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCustomer) {
        updateData['customerSignature'] = signature;
      } else {
        updateData['specialistSignature'] = signature;
      }

      await _firestore.collection('contracts').doc(contractId).update(updateData);

      // Проверяем, подписан ли договор обеими сторонами
      final contractDoc = await _firestore.collection('contracts').doc(contractId).get();
      if (contractDoc.exists) {
        final data = contractDoc.data()!;
        final customerSignature = data['customerSignature'] as String?;
        final specialistSignature = data['specialistSignature'] as String?;

        if (customerSignature != null && specialistSignature != null) {
          // Договор полностью подписан
          await _firestore.collection('contracts').doc(contractId).update({
            'status': contract_model.ContractStatus.signed.name,
            'signedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      AppLogger.logI('Договор $contractId подписан', 'contract_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка подписания договора', 'contract_service', e, stackTrace);
      return false;
    }
  }

  /// Подписать акт выполненных работ
  Future<bool> signWorkAct({
    required String workActId,
    required String signature,
    required bool isCustomer,
  }) async {
    try {
      final updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCustomer) {
        updateData['customerSignature'] = signature;
      } else {
        updateData['specialistSignature'] = signature;
      }

      await _firestore.collection('work_acts').doc(workActId).update(updateData);

      // Проверяем, подписан ли акт обеими сторонами
      final workActDoc = await _firestore.collection('work_acts').doc(workActId).get();
      if (workActDoc.exists) {
        final data = workActDoc.data()!;
        final customerSignature = data['customerSignature'] as String?;
        final specialistSignature = data['specialistSignature'] as String?;

        if (customerSignature != null && specialistSignature != null) {
          // Акт полностью подписан
          await _firestore.collection('work_acts').doc(workActId).update({
            'status': work_act_model.WorkActStatus.signed.name,
            'signedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      AppLogger.logI('Акт выполненных работ $workActId подписан', 'contract_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка подписания акта выполненных работ', 'contract_service', e, stackTrace);
      return false;
    }
  }

  /// Получить договоры пользователя
  Future<List<contract_model.Contract>> getUserContracts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('contracts')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => contract_model.Contract.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения договоров пользователя', 'contract_service', e, stackTrace);
      return [];
    }
  }

  /// Получить акты пользователя
  Future<List<work_act_model.WorkAct>> getUserWorkActs(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('work_acts')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => work_act_model.WorkAct.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения актов пользователя', 'contract_service', e, stackTrace);
      return [];
    }
  }

  /// Определить тип организации пользователя
  contract_model.OrganizationType _getOrganizationType(AppUser user) {
    // Здесь можно добавить логику определения типа организации
    // на основе данных пользователя
    return contract_model.OrganizationType.individual;
  }

  /// Получить реквизиты заказчика
  String _getCustomerDetails(AppUser customer) {
    // Здесь можно добавить логику получения реквизитов
    return 'Email: ${customer.email}';
  }

  /// Получить реквизиты исполнителя
  String _getSpecialistDetails(AppUser specialist) {
    // Здесь можно добавить логику получения реквизитов
    return 'Email: ${specialist.email}';
  }
}