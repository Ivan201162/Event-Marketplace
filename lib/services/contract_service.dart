import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/contract.dart';
import '../models/specialist.dart';
import '../models/user.dart';

/// Сервис для автоматического формирования договоров
class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать договор на оказание услуг
  Future<Contract> createServiceContract({
    required String bookingId,
    required String customerId,
    required String specialistId,
    Map<String, dynamic>? customTerms,
  }) async {
    if (!FeatureFlags.contractGenerationEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      // Получаем данные бронирования
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Получаем данные заказчика
      final customer = await _getUser(customerId);
      if (customer == null) {
        throw Exception('Заказчик не найден');
      }

      // Получаем данные специалиста
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) {
        throw Exception('Специалист не найден');
      }

      // Генерируем номер договора
      final contractNumber = _generateContractNumber();

      // Создаем договор
      final contract = Contract(
        id: '',
        contractNumber: contractNumber,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        type: ContractType.service,
        status: ContractStatus.draft,
        title: 'Договор на оказание услуг',
        content: _generateContractContent(
          contractNumber: contractNumber,
          booking: booking,
          customer: customer,
          specialist: specialist,
          customTerms: customTerms,
        ),
        terms: _generateDefaultTerms(booking, customTerms),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: booking.eventDate.add(const Duration(days: 30)),
        metadata: {
          'eventTitle': booking.eventTitle,
          'eventDate': booking.eventDate.toIso8601String(),
          'totalAmount': booking.totalPrice,
          'advanceAmount': booking.prepayment ?? 0.0,
        },
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('contracts').add(contract.toMap());

      return contract.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания договора: $e');
    }
  }

  /// Подписать договор
  Future<void> signContract({
    required String contractId,
    required String userId,
    required String signature,
  }) async {
    try {
      final contract = await _getContract(contractId);
      if (contract == null) {
        throw Exception('Договор не найден');
      }

      // Проверяем, что пользователь имеет право подписывать договор
      if (userId != contract.customerId && userId != contract.specialistId) {
        throw Exception('Недостаточно прав для подписания договора');
      }

      // Обновляем статус договора
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.signed.name,
        'signedAt': Timestamp.fromDate(DateTime.now()),
        'signatures': FieldValue.arrayUnion([
          {
            'userId': userId,
            'signature': signature,
            'signedAt': Timestamp.fromDate(DateTime.now()),
          }
        ]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка подписания договора: $e');
    }
  }

  /// Получить договор по ID
  Future<Contract?> getContract(String contractId) async =>
      _getContract(contractId);

  /// Получить договоры по бронированию
  Future<List<Contract>> getContractsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('contracts')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Contract.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения договоров: $e');
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

  Future<User?> _getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Specialist?> _getSpecialist(String specialistId) async {
    try {
      final doc =
          await _firestore.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Contract?> _getContract(String contractId) async {
    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (doc.exists) {
        return Contract.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _generateContractNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');

    return 'ДУ-$year$month$day-$random';
  }

  String _generateContractContent({
    required String contractNumber,
    required Booking booking,
    required User customer,
    required Specialist specialist,
    Map<String, dynamic>? customTerms,
  }) =>
      '''
ДОГОВОР НА ОКАЗАНИЕ УСЛУГ № $contractNumber

г. Москва                                    ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} г.

ИСПОЛНИТЕЛЬ: ${specialist.name}
Адрес: ${specialist.address ?? 'Не указан'}
Телефон: ${specialist.phone ?? 'Не указан'}
Email: ${specialist.email ?? 'Не указан'}

ЗАКАЗЧИК: ${customer.name}
Адрес: ${customer.address ?? 'Не указан'}
Телефон: ${customer.phone ?? 'Не указан'}
Email: ${customer.email ?? 'Не указан'}

ПРЕДМЕТ ДОГОВОРА

1. Исполнитель обязуется оказать услуги по организации и проведению мероприятия:
   - Наименование: ${booking.eventTitle}
   - Дата проведения: ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}
   - Количество участников: ${booking.participantsCount}
   - Место проведения: ${booking.eventLocation ?? 'Не указано'}

2. Заказчик обязуется принять и оплатить оказанные услуги.

СТОИМОСТЬ УСЛУГ И ПОРЯДОК РАСЧЕТОВ

1. Общая стоимость услуг составляет: ${booking.totalPrice.toStringAsFixed(2)} рублей.

2. Аванс составляет: ${(booking.prepayment ?? 0.0).toStringAsFixed(2)} рублей.

3. Окончательный расчет производится после оказания услуг.

ОТВЕТСТВЕННОСТЬ СТОРОН

1. За неисполнение или ненадлежащее исполнение обязательств по настоящему договору стороны несут ответственность в соответствии с действующим законодательством РФ.

2. Исполнитель несет ответственность за качество оказанных услуг.

3. Заказчик несет ответственность за своевременную оплату услуг.

ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ

1. Настоящий договор вступает в силу с момента подписания и действует до полного исполнения сторонами своих обязательств.

2. Все споры решаются путем переговоров, а при недостижении согласия - в судебном порядке.

3. Договор составлен в двух экземплярах, имеющих одинаковую юридическую силу.

ПОДПИСИ СТОРОН:

Исполнитель: _________________ ${specialist.name}

Заказчик: _________________ ${customer.name}
''';

  Map<String, dynamic> _generateDefaultTerms(
    Booking booking,
    Map<String, dynamic>? customTerms,
  ) {
    final defaultTerms = {
      'paymentTerms': {
        'advanceRequired': true,
        'advancePercentage': 30,
        'finalPaymentDue': 'before_event',
      },
      'cancellationPolicy': {
        'customerCanCancel': true,
        'refundPercentage': {
          'more_than_7_days': 100,
          '3_to_7_days': 50,
          'less_than_3_days': 0,
        },
      },
      'liability': {
        'specialistLiability': 'limited_to_service_cost',
        'customerLiability': 'damage_to_equipment',
      },
      'forceMajeure': {
        'includes': [
          'natural_disasters',
          'government_restrictions',
          'pandemics',
        ],
        'resolution': 'reschedule_or_refund',
      },
    };

    if (customTerms != null) {
      defaultTerms.addAll(customTerms);
    }

    return defaultTerms;
  }
}
