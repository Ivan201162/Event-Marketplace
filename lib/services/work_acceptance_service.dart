import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/contract.dart';

/// Сервис для подписания актов выполненных работ
class WorkAcceptanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать акт выполненных работ
  Future<WorkAcceptanceAct> createWorkAcceptanceAct({
    required String bookingId,
    required String contractId,
    required String specialistId,
    required String customerId,
    List<String>? completedServices,
    String? notes,
    List<String>? attachments,
  }) async {
    if (!FeatureFlags.workAcceptanceEnabled) {
      throw Exception('Подписание актов выполненных работ отключено');
    }

    try {
      // Получаем данные бронирования
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Получаем данные договора
      final contract = await _getContract(contractId);
      if (contract == null) {
        throw Exception('Договор не найден');
      }

      // Проверяем, что договор подписан
      if (contract.status != ContractStatus.signed) {
        throw Exception('Договор должен быть подписан перед созданием акта');
      }

      // Генерируем номер акта
      final actNumber = _generateActNumber();

      // Создаем акт
      final act = WorkAcceptanceAct(
        id: '',
        actNumber: actNumber,
        bookingId: bookingId,
        contractId: contractId,
        specialistId: specialistId,
        customerId: customerId,
        status: WorkAcceptanceStatus.draft,
        completedServices: completedServices ?? _getDefaultServices(booking),
        notes: notes ?? '',
        attachments: attachments ?? [],
        totalAmount: booking.totalPrice,
        advanceAmount: booking.prepayment ?? 0.0,
        finalAmount: booking.totalPrice - (booking.prepayment ?? 0.0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'eventTitle': booking.eventTitle,
          'eventDate': booking.eventDate.toIso8601String(),
          'eventLocation': booking.eventLocation,
          'participantsCount': booking.participantsCount,
        },
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('work_acceptance_acts').add(act.toMap());

      return act.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания акта выполненных работ: $e');
    }
  }

  /// Подписать акт специалистом
  Future<void> signActBySpecialist({
    required String actId,
    required String specialistId,
    required String signature,
    String? notes,
  }) async {
    try {
      final act = await _getAct(actId);
      if (act == null) {
        throw Exception('Акт не найден');
      }

      if (act.specialistId != specialistId) {
        throw Exception('Недостаточно прав для подписания акта');
      }

      await _firestore.collection('work_acceptance_acts').doc(actId).update({
        'specialistSignedAt': Timestamp.fromDate(DateTime.now()),
        'specialistSignature': signature,
        'specialistNotes': notes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка подписания акта специалистом: $e');
    }
  }

  /// Подписать акт заказчиком
  Future<void> signActByCustomer({
    required String actId,
    required String customerId,
    required String signature,
    String? notes,
  }) async {
    try {
      final act = await _getAct(actId);
      if (act == null) {
        throw Exception('Акт не найден');
      }

      if (act.customerId != customerId) {
        throw Exception('Недостаточно прав для подписания акта');
      }

      // Обновляем статус акта
      final newStatus = act.specialistSignedAt != null
          ? WorkAcceptanceStatus.completed
          : WorkAcceptanceStatus.pendingCustomer;

      await _firestore.collection('work_acceptance_acts').doc(actId).update({
        'customerSignedAt': Timestamp.fromDate(DateTime.now()),
        'customerSignature': signature,
        'customerNotes': notes,
        'status': newStatus.name,
        'signedAt': newStatus == WorkAcceptanceStatus.completed
            ? Timestamp.fromDate(DateTime.now())
            : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Если акт полностью подписан, обновляем статус бронирования
      if (newStatus == WorkAcceptanceStatus.completed) {
        await _updateBookingStatus(act.bookingId, 'completed');
      }
    } catch (e) {
      throw Exception('Ошибка подписания акта заказчиком: $e');
    }
  }

  /// Получить акт по ID
  Future<WorkAcceptanceAct?> getAct(String actId) async => _getAct(actId);

  /// Получить акты по бронированию
  Future<List<WorkAcceptanceAct>> getActsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acceptance_acts')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAcceptanceAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов: $e');
    }
  }

  /// Получить акты пользователя
  Future<List<WorkAcceptanceAct>> getUserActs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acceptance_acts')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAcceptanceAct.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения актов пользователя: $e');
    }
  }

  /// Отклонить акт
  Future<void> rejectAct({
    required String actId,
    required String userId,
    required String reason,
  }) async {
    try {
      final act = await _getAct(actId);
      if (act == null) {
        throw Exception('Акт не найден');
      }

      if (userId != act.customerId && userId != act.specialistId) {
        throw Exception('Недостаточно прав для отклонения акта');
      }

      await _firestore.collection('work_acceptance_acts').doc(actId).update({
        'status': WorkAcceptanceStatus.rejected.name,
        'rejectedAt': Timestamp.fromDate(DateTime.now()),
        'rejectedBy': userId,
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отклонения акта: $e');
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

  Future<WorkAcceptanceAct?> _getAct(String actId) async {
    try {
      final doc =
          await _firestore.collection('work_acceptance_acts').doc(actId).get();
      if (doc.exists) {
        return WorkAcceptanceAct.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки обновления
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

  List<String> _getDefaultServices(Booking booking) => [
        'Организация мероприятия: ${booking.eventTitle}',
        'Проведение мероприятия ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}',
        'Обслуживание ${booking.participantsCount} участников',
      ];
}

/// Модель акта выполненных работ
class WorkAcceptanceAct {
  const WorkAcceptanceAct({
    required this.id,
    required this.actNumber,
    required this.bookingId,
    required this.contractId,
    required this.specialistId,
    required this.customerId,
    required this.status,
    required this.completedServices,
    required this.notes,
    required this.attachments,
    required this.totalAmount,
    required this.advanceAmount,
    required this.finalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    this.specialistSignedAt,
    this.customerSignedAt,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory WorkAcceptanceAct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkAcceptanceAct(
      id: doc.id,
      actNumber: data['actNumber'] ?? '',
      bookingId: data['bookingId'] ?? '',
      contractId: data['contractId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      customerId: data['customerId'] ?? '',
      status: WorkAcceptanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WorkAcceptanceStatus.draft,
      ),
      completedServices: List<String>.from(data['completedServices'] ?? []),
      notes: data['notes'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (data['finalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      specialistSignedAt: data['specialistSignedAt'] != null
          ? (data['specialistSignedAt'] as Timestamp).toDate()
          : null,
      customerSignedAt: data['customerSignedAt'] != null
          ? (data['customerSignedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String actNumber;
  final String bookingId;
  final String contractId;
  final String specialistId;
  final String customerId;
  final WorkAcceptanceStatus status;
  final List<String> completedServices;
  final String notes;
  final List<String> attachments;
  final double totalAmount;
  final double advanceAmount;
  final double finalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final DateTime? specialistSignedAt;
  final DateTime? customerSignedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'actNumber': actNumber,
        'bookingId': bookingId,
        'contractId': contractId,
        'specialistId': specialistId,
        'customerId': customerId,
        'status': status.name,
        'completedServices': completedServices,
        'notes': notes,
        'attachments': attachments,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'finalAmount': finalAmount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
        'specialistSignedAt': specialistSignedAt != null
            ? Timestamp.fromDate(specialistSignedAt!)
            : null,
        'customerSignedAt': customerSignedAt != null
            ? Timestamp.fromDate(customerSignedAt!)
            : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  WorkAcceptanceAct copyWith({
    String? id,
    String? actNumber,
    String? bookingId,
    String? contractId,
    String? specialistId,
    String? customerId,
    WorkAcceptanceStatus? status,
    List<String>? completedServices,
    String? notes,
    List<String>? attachments,
    double? totalAmount,
    double? advanceAmount,
    double? finalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? signedAt,
    DateTime? specialistSignedAt,
    DateTime? customerSignedAt,
    Map<String, dynamic>? metadata,
  }) =>
      WorkAcceptanceAct(
        id: id ?? this.id,
        actNumber: actNumber ?? this.actNumber,
        bookingId: bookingId ?? this.bookingId,
        contractId: contractId ?? this.contractId,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        status: status ?? this.status,
        completedServices: completedServices ?? this.completedServices,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        totalAmount: totalAmount ?? this.totalAmount,
        advanceAmount: advanceAmount ?? this.advanceAmount,
        finalAmount: finalAmount ?? this.finalAmount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        signedAt: signedAt ?? this.signedAt,
        specialistSignedAt: specialistSignedAt ?? this.specialistSignedAt,
        customerSignedAt: customerSignedAt ?? this.customerSignedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Статусы актов выполненных работ
enum WorkAcceptanceStatus {
  draft, // Черновик
  pendingSpecialist, // Ожидает подписания специалистом
  pendingCustomer, // Ожидает подписания заказчиком
  completed, // Завершен
  rejected, // Отклонен
}
