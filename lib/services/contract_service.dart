import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/booking.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../core/feature_flags.dart';

/// Тип договора
enum ContractType {
  service,
  event,
  rental,
  custom,
}

/// Статус договора
enum ContractStatus {
  draft,
  pending,
  signed,
  active,
  completed,
  cancelled,
  expired,
}

/// Модель договора
class Contract {
  final String id;
  final String bookingId;
  final ContractType type;
  final ContractStatus status;
  final String title;
  final String content;
  final Map<String, dynamic> terms;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String specialistId;
  final String specialistName;
  final String specialistEmail;
  final double totalAmount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? signedAt;
  final String? signedBy;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contract({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.status,
    required this.title,
    required this.content,
    required this.terms,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.specialistId,
    required this.specialistName,
    required this.specialistEmail,
    required this.totalAmount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    this.signedAt,
    this.signedBy,
    required this.attachments,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory Contract.fromMap(Map<String, dynamic> data) {
    return Contract(
      id: data['id'] ?? '',
      bookingId: data['bookingId'] ?? '',
      type: ContractType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ContractType.service,
      ),
      status: ContractStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ContractStatus.draft,
      ),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      terms: Map<String, dynamic>.from(data['terms'] ?? {}),
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistEmail: data['specialistEmail'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'RUB',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      signedBy: data['signedBy'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'type': type.name,
      'status': status.name,
      'title': title,
      'content': content,
      'terms': terms,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistEmail': specialistEmail,
      'totalAmount': totalAmount,
      'currency': currency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'signedBy': signedBy,
      'attachments': attachments,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Копировать с изменениями
  Contract copyWith({
    String? id,
    String? bookingId,
    ContractType? type,
    ContractStatus? status,
    String? title,
    String? content,
    Map<String, dynamic>? terms,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? specialistId,
    String? specialistName,
    String? specialistEmail,
    double? totalAmount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? signedAt,
    String? signedBy,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      content: content ?? this.content,
      terms: terms ?? this.terms,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistEmail: specialistEmail ?? this.specialistEmail,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      signedAt: signedAt ?? this.signedAt,
      signedBy: signedBy ?? this.signedBy,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.pending:
        return Colors.orange;
      case ContractStatus.signed:
        return Colors.blue;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.completed:
        return Colors.green[700]!;
      case ContractStatus.cancelled:
        return Colors.red;
      case ContractStatus.expired:
        return Colors.red[700]!;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.pending:
        return 'Ожидает подписания';
      case ContractStatus.signed:
        return 'Подписан';
      case ContractStatus.active:
        return 'Активен';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
      case ContractStatus.expired:
        return 'Истек';
    }
  }

  /// Проверить, может ли пользователь подписать
  bool canSign(String userId) {
    return (userId == customerId || userId == specialistId) &&
        status == ContractStatus.pending;
  }

  /// Проверить, может ли пользователь редактировать
  bool canEdit(String userId) {
    return userId == specialistId && status == ContractStatus.draft;
  }
}

/// Сервис для работы с договорами
class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать договор из бронирования
  Future<String> createContractFromBooking(Booking booking) async {
    if (!FeatureFlags.contractsEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      // Получаем данные события
      final eventDoc =
          await _firestore.collection('events').doc(booking.eventId).get();

      if (!eventDoc.exists) {
        throw Exception('Событие не найдено');
      }

      final event = Event.fromMap({
        'id': eventDoc.id,
        ...eventDoc.data()!,
      });

      // Получаем данные специалиста
      final specialistDoc =
          await _firestore.collection('users').doc(event.specialistId).get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = AppUser.fromMap({
        'id': specialistDoc.id,
        ...specialistDoc.data()!,
      });

      // Получаем данные заказчика
      final customerDoc =
          await _firestore.collection('users').doc(booking.userId).get();

      if (!customerDoc.exists) {
        throw Exception('Заказчик не найден');
      }

      final customer = AppUser.fromMap({
        'id': customerDoc.id,
        ...customerDoc.data()!,
      });

      // Генерируем содержимое договора
      final contractContent = _generateContractContent(
        booking,
        event,
        specialist,
        customer,
      );

      final now = DateTime.now();

      final contract = Contract(
        id: '', // Будет установлен Firestore
        bookingId: booking.id,
        type: ContractType.service,
        status: ContractStatus.draft,
        title: 'Договор на оказание услуг: ${event.title}',
        content: contractContent,
        terms: _generateDefaultTerms(booking, event),
        customerId: customer.id,
        customerName: customer.displayName,
        customerEmail: customer.email,
        specialistId: specialist.id,
        specialistName: specialist.displayName,
        specialistEmail: specialist.email,
        totalAmount: booking.totalPrice,
        currency: 'RUB',
        startDate: booking.eventDate,
        endDate: booking.eventDate.add(const Duration(hours: 8)),
        attachments: [],
        metadata: {
          'eventId': event.id,
          'eventTitle': event.title,
          'eventDescription': event.description,
          'eventLocation': event.location,
          'participantsCount': booking.participantsCount,
          'notes': booking.notes,
        },
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('contracts').add(contract.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating contract: $e');
      throw Exception('Ошибка создания договора: $e');
    }
  }

  /// Получить договор по ID
  Future<Contract?> getContractById(String contractId) async {
    if (!FeatureFlags.contractsEnabled) {
      return null;
    }

    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();

      if (!doc.exists) {
        return null;
      }

      return Contract.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting contract: $e');
      return null;
    }
  }

  /// Получить договоры пользователя
  Stream<List<Contract>> getUserContracts(String userId) {
    if (!FeatureFlags.contractsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('contracts')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Contract.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  /// Получить договоры специалиста
  Stream<List<Contract>> getSpecialistContracts(String specialistId) {
    if (!FeatureFlags.contractsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('contracts')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Contract.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  /// Обновить статус договора
  Future<void> updateContractStatus(
    String contractId,
    ContractStatus status, {
    String? signedBy,
  }) async {
    if (!FeatureFlags.contractsEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ContractStatus.signed && signedBy != null) {
        updates['signedAt'] = FieldValue.serverTimestamp();
        updates['signedBy'] = signedBy;
      }

      await _firestore.collection('contracts').doc(contractId).update(updates);
    } catch (e) {
      debugPrint('Error updating contract status: $e');
      throw Exception('Ошибка обновления статуса договора: $e');
    }
  }

  /// Подписать договор
  Future<void> signContract(String contractId, String userId) async {
    if (!FeatureFlags.contractsEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      final contract = await getContractById(contractId);
      if (contract == null) {
        throw Exception('Договор не найден');
      }

      if (!contract.canSign(userId)) {
        throw Exception('Вы не можете подписать этот договор');
      }

      await updateContractStatus(
        contractId,
        ContractStatus.signed,
        signedBy: userId,
      );
    } catch (e) {
      debugPrint('Error signing contract: $e');
      throw Exception('Ошибка подписания договора: $e');
    }
  }

  /// Сгенерировать PDF договора
  Future<Uint8List> generateContractPDF(String contractId) async {
    if (!FeatureFlags.contractsEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      final contract = await getContractById(contractId);
      if (contract == null) {
        throw Exception('Договор не найден');
      }

      // TODO: Реализовать генерацию PDF
      // Здесь должен быть код для создания PDF документа
      // Можно использовать пакет pdf или printing

      return _generateMockPDF(contract);
    } catch (e) {
      debugPrint('Error generating contract PDF: $e');
      throw Exception('Ошибка генерации PDF: $e');
    }
  }

  /// Сгенерировать акт выполненных работ
  Future<Uint8List> generateCompletionAct(String contractId) async {
    if (!FeatureFlags.contractsEnabled) {
      throw Exception('Автоматическое формирование договоров отключено');
    }

    try {
      final contract = await getContractById(contractId);
      if (contract == null) {
        throw Exception('Договор не найден');
      }

      // TODO: Реализовать генерацию акта
      return _generateMockPDF(contract);
    } catch (e) {
      debugPrint('Error generating completion act: $e');
      throw Exception('Ошибка генерации акта: $e');
    }
  }

  /// Сгенерировать содержимое договора
  String _generateContractContent(
    Booking booking,
    Event event,
    AppUser specialist,
    AppUser customer,
  ) {
    return '''
ДОГОВОР НА ОКАЗАНИЕ УСЛУГ

г. ${event.location}                                    ${_formatDate(DateTime.now())}

${specialist.displayName}, именуемый в дальнейшем "Исполнитель", с одной стороны, 
и ${customer.displayName}, именуемый в дальнейшем "Заказчик", с другой стороны, 
заключили настоящий договор о нижеследующем:

1. ПРЕДМЕТ ДОГОВОРА
1.1. Исполнитель обязуется оказать услуги по организации и проведению мероприятия "${event.title}", 
а Заказчик обязуется принять и оплатить эти услуги.

1.2. Описание услуги: ${event.description}

1.3. Место оказания услуг: ${event.location}

1.4. Дата и время оказания услуг: ${_formatDateTime(booking.eventDate)}

1.5. Количество участников: ${booking.participantsCount}

2. СТОИМОСТЬ УСЛУГ И ПОРЯДОК РАСЧЕТОВ
2.1. Общая стоимость услуг составляет ${booking.totalPrice} ${booking.currency}.

2.2. Оплата производится в следующем порядке:
- Аванс 30% (${booking.totalPrice * 0.3} ${booking.currency}) - при подписании договора
- Остаток 70% (${booking.totalPrice * 0.7} ${booking.currency}) - после выполнения услуг

3. ОБЯЗАННОСТИ СТОРОН
3.1. Исполнитель обязуется:
- Оказать услуги в полном объеме и в установленные сроки
- Обеспечить качественное выполнение работ
- Соблюдать требования безопасности

3.2. Заказчик обязуется:
- Своевременно оплачивать услуги
- Предоставить необходимые условия для оказания услуг
- Соблюдать требования Исполнителя

4. ОТВЕТСТВЕННОСТЬ СТОРОН
4.1. За неисполнение или ненадлежащее исполнение обязательств по настоящему договору 
стороны несут ответственность в соответствии с действующим законодательством.

5. ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ
5.1. Настоящий договор вступает в силу с момента подписания и действует до полного исполнения обязательств.

5.2. Все споры решаются путем переговоров, а при недостижении согласия - в судебном порядке.

5.3. Настоящий договор составлен в двух экземплярах, имеющих одинаковую юридическую силу.

ИСПОЛНИТЕЛЬ:                    ЗАКАЗЧИК:
${specialist.displayName}        ${customer.displayName}
${specialist.email}              ${customer.email}

Подпись: _______________         Подпись: _______________
Дата: _______________           Дата: _______________
''';
  }

  /// Сгенерировать стандартные условия
  Map<String, dynamic> _generateDefaultTerms(Booking booking, Event event) {
    return {
      'paymentTerms': {
        'advance': 30,
        'final': 70,
        'currency': booking.currency,
      },
      'cancellationPolicy': {
        'freeCancellationDays': 7,
        'penaltyPercentage': 20,
      },
      'liability': {
        'specialistLiability': 'Ограничена стоимостью услуги',
        'customerLiability': 'Ограничена стоимостью услуги',
      },
      'forceMajeure': {
        'includes': ['стихийные бедствия', 'военные действия', 'эпидемии'],
        'consequences': 'Перенос или возврат средств',
      },
    };
  }

  /// Сгенерировать mock PDF
  Uint8List _generateMockPDF(Contract contract) {
    // TODO: Заменить на реальную генерацию PDF
    final content = contract.content;
    return Uint8List.fromList(content.codeUnits);
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Форматировать дату и время
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} в ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
