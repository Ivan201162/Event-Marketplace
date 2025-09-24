import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/contract.dart';
import '../models/specialist.dart';
import '../models/user.dart';
import '../models/work_act.dart';

/// Сервис для управления актами выполненных работ
class WorkActService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать акт выполненных работ
  Future<WorkAct> createWorkAct({
    required String contractId,
    required String bookingId,
    required String customerId,
    required String specialistId,
    required String workDescription,
    required String workResults,
    required double totalAmount,
    required DateTime workStartDate,
    required DateTime workEndDate,
    String? notes,
    List<String>? attachments,
  }) async {
    if (!FeatureFlags.contractGenerationEnabled) {
      throw Exception('Создание актов выполненных работ отключено');
    }

    try {
      // Получаем данные бронирования
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Генерируем номер акта
      final actNumber = _generateActNumber();

      // Создаем акт
      final workAct = WorkAct(
        id: '',
        actNumber: actNumber,
        contractId: contractId,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        status: WorkActStatus.draft,
        title: 'Акт выполненных работ № $actNumber',
        content: _generateActContent(
          actNumber: actNumber,
          booking: booking,
          workDescription: workDescription,
          workResults: workResults,
          totalAmount: totalAmount,
          workStartDate: workStartDate,
          workEndDate: workEndDate,
        ),
        workDescription: workDescription,
        workResults: workResults,
        totalAmount: totalAmount,
        currency: 'RUB',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workStartDate: workStartDate,
        workEndDate: workEndDate,
        attachments: attachments,
        notes: notes,
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('workActs').add(workAct.toMap());

      return workAct.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания акта выполненных работ: $e');
    }
  }

  /// Подписать акт выполненных работ
  Future<void> signWorkAct({
    required String workActId,
    required String userId,
    required String userName,
    required String signature,
    String? signatureType,
  }) async {
    try {
      final workAct = await _getWorkAct(workActId);
      if (workAct == null) {
        throw Exception('Акт выполненных работ не найден');
      }

      // Проверяем, что пользователь имеет право подписывать акт
      if (userId != workAct.customerId && userId != workAct.specialistId) {
        throw Exception('Недостаточно прав для подписания акта');
      }

      // Создаем подпись
      final signatureData = Signature(
        userId: userId,
        userName: userName,
        signature: signature,
        signedAt: DateTime.now(),
        signatureType: signatureType ?? 'drawn',
      );

      // Определяем, чья это подпись
      final isCustomer = userId == workAct.customerId;
      final isSpecialist = userId == workAct.specialistId;

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (isCustomer) {
        updateData['customerSignature'] = signatureData.toMap();
      }

      if (isSpecialist) {
        updateData['specialistSignature'] = signatureData.toMap();
      }

      // Проверяем, подписан ли акт обеими сторонами
      final hasCustomerSignature =
          isCustomer || workAct.customerSignature != null;
      final hasSpecialistSignature =
          isSpecialist || workAct.specialistSignature != null;

      if (hasCustomerSignature && hasSpecialistSignature) {
        updateData['status'] = WorkActStatus.signed.name;
        updateData['signedAt'] = Timestamp.fromDate(DateTime.now());
      } else {
        updateData['status'] = WorkActStatus.pending.name;
      }

      await _firestore.collection('workActs').doc(workActId).update(updateData);
    } catch (e) {
      throw Exception('Ошибка подписания акта выполненных работ: $e');
    }
  }

  /// Получить акт выполненных работ по ID
  Future<WorkAct?> getWorkAct(String workActId) async => _getWorkAct(workActId);

  /// Получить акты по договору
  Future<List<WorkAct>> getWorkActsByContract(String contractId) async {
    try {
      final snapshot = await _firestore
          .collection('workActs')
          .where('contractId', isEqualTo: contractId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов по договору: $e');
    }
  }

  /// Получить акты по бронированию
  Future<List<WorkAct>> getWorkActsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('workActs')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов по бронированию: $e');
    }
  }

  /// Получить акты пользователя
  Future<List<WorkAct>> getUserWorkActs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('workActs')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов пользователя: $e');
    }
  }

  /// Получить акты специалиста
  Future<List<WorkAct>> getSpecialistWorkActs(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('workActs')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов специалиста: $e');
    }
  }

  /// Оспорить акт выполненных работ
  Future<void> disputeWorkAct({
    required String workActId,
    required String userId,
    required String disputeReason,
  }) async {
    try {
      final workAct = await _getWorkAct(workActId);
      if (workAct == null) {
        throw Exception('Акт выполненных работ не найден');
      }

      // Проверяем, что пользователь имеет право оспаривать акт
      if (userId != workAct.customerId && userId != workAct.specialistId) {
        throw Exception('Недостаточно прав для оспаривания акта');
      }

      await _firestore.collection('workActs').doc(workActId).update({
        'status': WorkActStatus.disputed.name,
        'disputeReason': disputeReason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка оспаривания акта: $e');
    }
  }

  /// Разрешить спор по акту
  Future<void> resolveWorkActDispute({
    required String workActId,
    required String resolution,
  }) async {
    try {
      await _firestore.collection('workActs').doc(workActId).update({
        'status': WorkActStatus.completed.name,
        'resolution': resolution,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка разрешения спора: $e');
    }
  }

  /// Сгенерировать PDF акта
  Future<String> generateWorkActPDF(String workActId) async {
    try {
      // Получаем акт
      final workActDoc =
          await _firestore.collection('workActs').doc(workActId).get();

      if (!workActDoc.exists) {
        throw Exception('Акт выполненных работ не найден');
      }

      final workAct = WorkAct.fromDocument(workActDoc);

      // Здесь должна быть логика генерации PDF
      // Пока возвращаем заглушку
      return 'work_act_${workActId}.pdf';
    } catch (e) {
      throw Exception('Ошибка генерации PDF акта: $e');
    }
  }

  // Приватные методы

  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<WorkAct?> _getWorkAct(String workActId) async {
    try {
      final doc = await _firestore.collection('workActs').doc(workActId).get();
      if (doc.exists) {
        return WorkAct.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _generateActNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');

    return 'АВР-$year$month$day-$random';
  }

  String _generateActContent({
    required String actNumber,
    required Booking booking,
    required String workDescription,
    required String workResults,
    required double totalAmount,
    required DateTime workStartDate,
    required DateTime workEndDate,
  }) =>
      '''
АКТ ВЫПОЛНЕННЫХ РАБОТ № $actNumber

г. Москва                                    ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} г.

Мы, нижеподписавшиеся, составили настоящий акт о том, что:

ИСПОЛНИТЕЛЬ: ${booking.specialistName ?? 'Не указан'}
ЗАКАЗЧИК: ${booking.customerName ?? 'Не указан'}

ПРЕДМЕТ ДОГОВОРА:
- Наименование мероприятия: ${booking.eventTitle}
- Дата проведения: ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}
- Место проведения: ${booking.eventLocation ?? 'Не указано'}

ВЫПОЛНЕННЫЕ РАБОТЫ:
$workDescription

РЕЗУЛЬТАТЫ РАБОТ:
$workResults

ПЕРИОД ВЫПОЛНЕНИЯ:
- Начало работ: ${workStartDate.day}.${workStartDate.month}.${workStartDate.year}
- Окончание работ: ${workEndDate.day}.${workEndDate.month}.${workEndDate.year}

СТОИМОСТЬ ВЫПОЛНЕННЫХ РАБОТ:
${totalAmount.toStringAsFixed(2)} рублей

РАБОТЫ ВЫПОЛНЕНЫ В ПОЛНОМ ОБЪЕМЕ, В СООТВЕТСТВИИ С ДОГОВОРОМ.
КАЧЕСТВО РАБОТ СООТВЕТСТВУЕТ ТРЕБОВАНИЯМ ДОГОВОРА.

ПОДПИСИ СТОРОН:

Исполнитель: _________________ ${booking.specialistName ?? 'Не указан'}

Заказчик: _________________ ${booking.customerName ?? 'Не указан'}
''';
}
