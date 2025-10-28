import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Сервис для управления актами выполненных работ
class WorkActService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать акт выполненных работ
  Future<WorkAct> createWorkAct({
    required String bookingId,
    required String specialistId,
    required String customerId,
    required String eventName,
    required String eventDate,
    required String eventLocation,
    required List<ServiceItem> services,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final workAct = WorkAct(
        id: '', // Будет сгенерирован Firestore
        bookingId: bookingId,
        specialistId: specialistId,
        customerId: customerId,
        eventName: eventName,
        eventDate: eventDate,
        eventLocation: eventLocation,
        services: services,
        totalAmount: totalAmount,
        notes: notes,
        status: WorkActStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('work_acts').add(workAct.toMap());

      return workAct.copyWith(id: docRef.id);
    } on Exception {
      // Логирование:'Ошибка создания акта выполненных работ: $e');
      rethrow;
    }
  }

  /// Получить акт выполненных работ
  Future<WorkAct?> getWorkAct(String workActId) async {
    try {
      final doc = await _firestore.collection('work_acts').doc(workActId).get();

      if (!doc.exists) return null;

      return WorkAct.fromDocument(doc);
    } on Exception {
      // Логирование:'Ошибка получения акта выполненных работ: $e');
      return null;
    }
  }

  /// Получить акты по заказу
  Future<List<WorkAct>> getWorkActsByBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acts')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка получения актов по заказу: $e');
      return [];
    }
  }

  /// Получить акты специалиста
  Future<List<WorkAct>> getWorkActsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acts')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка получения актов специалиста: $e');
      return [];
    }
  }

  /// Получить акты заказчика
  Future<List<WorkAct>> getWorkActsByCustomer(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acts')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(WorkAct.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка получения актов заказчика: $e');
      return [];
    }
  }

  /// Подписать акт выполненных работ
  Future<void> signWorkAct({
    required String workActId,
    required String signedBy,
    required String signature,
  }) async {
    try {
      await _firestore.collection('work_acts').doc(workActId).update({
        'status': WorkActStatus.signed.name,
        'signedAt': FieldValue.serverTimestamp(),
        'signedBy': signedBy,
        'signature': signature,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception {
      // Логирование:'Ошибка подписания акта: $e');
      rethrow;
    }
  }

  /// Отклонить акт выполненных работ
  Future<void> rejectWorkAct(
      {required String workActId, required String reason,}) async {
    try {
      await _firestore.collection('work_acts').doc(workActId).update({
        'status': WorkActStatus.rejected.name,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception {
      // Логирование:'Ошибка отклонения акта: $e');
      rethrow;
    }
  }

  /// Обновить акт выполненных работ
  Future<void> updateWorkAct({
    required String workActId,
    String? eventName,
    String? eventDate,
    String? eventLocation,
    List<ServiceItem>? services,
    double? totalAmount,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (eventName != null) updateData['eventName'] = eventName;
      if (eventDate != null) updateData['eventDate'] = eventDate;
      if (eventLocation != null) updateData['eventLocation'] = eventLocation;
      if (services != null) {
        updateData['services'] = services.map((s) => s.toMap()).toList();
      }
      if (totalAmount != null) updateData['totalAmount'] = totalAmount;
      if (notes != null) updateData['notes'] = notes;

      await _firestore
          .collection('work_acts')
          .doc(workActId)
          .update(updateData);
    } on Exception {
      // Логирование:'Ошибка обновления акта: $e');
      rethrow;
    }
  }

  /// Создать PDF акта выполненных работ
  Future<Uint8List> generateWorkActPDF(WorkAct workAct) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => _buildWorkActContent(workAct),),
      );

      return await pdf.save();
    } on Exception {
      // Логирование:'Ошибка создания PDF: $e');
      rethrow;
    }
  }

  /// Содержимое акта выполненных работ
  pw.Widget _buildWorkActContent(WorkAct workAct) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildTitle(),
          pw.SizedBox(height: 20),
          _buildEventInfo(workAct),
          pw.SizedBox(height: 20),
          _buildServicesTable(workAct),
          pw.SizedBox(height: 20),
          _buildTotalAmount(workAct),
          pw.SizedBox(height: 20),
          _buildNotes(workAct),
          pw.SizedBox(height: 40),
          _buildSignatures(workAct),
        ],
      );

  pw.Widget _buildHeader() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'АКТ ВЫПОЛНЕННЫХ РАБОТ',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '№ ${DateTime.now().millisecondsSinceEpoch}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      );

  pw.Widget _buildTitle() => pw.Center(
        child: pw.Text(
          'АКТ ВЫПОЛНЕННЫХ РАБОТ',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _buildEventInfo(WorkAct workAct) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Информация о мероприятии:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Название:', workAct.eventName),
          _buildInfoRow('Дата:', workAct.eventDate),
          _buildInfoRow('Место проведения:', workAct.eventLocation),
          _buildInfoRow('Дата составления:', _formatDate(workAct.createdAt)),
        ],
      );

  pw.Widget _buildInfoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
                width: 120,
                child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),),
            pw.Expanded(
                child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),),
          ],
        ),
      );

  pw.Widget _buildServicesTable(WorkAct workAct) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Выполненные работы:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(),
              3: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('№', isHeader: true),
                  _buildTableCell('Наименование работы', isHeader: true),
                  _buildTableCell('Количество', isHeader: true),
                  _buildTableCell('Стоимость', isHeader: true),
                ],
              ),
              ...workAct.services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell('${index + 1}'),
                    _buildTableCell(service.name),
                    _buildTableCell(service.quantity.toString()),
                    _buildTableCell('${service.price.toStringAsFixed(2)} ₽'),
                  ],
                );
              }),
            ],
          ),
        ],
      );

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 12 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  pw.Widget _buildTotalAmount(WorkAct workAct) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Итого: ${workAct.totalAmount.toStringAsFixed(2)} ₽',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      );

  pw.Widget _buildNotes(WorkAct workAct) {
    if (workAct.notes == null || workAct.notes!.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Примечания:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),),
        pw.SizedBox(height: 8),
        pw.Text(workAct.notes!, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildSignatures(WorkAct workAct) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Исполнитель:', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 40),
              pw.Text('_________________',
                  style: const pw.TextStyle(fontSize: 12),),
              pw.Text('Подпись', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Заказчик:', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 40),
              pw.Text('_________________',
                  style: const pw.TextStyle(fontSize: 12),),
              pw.Text('Подпись', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      );

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  /// Получить статистику актов
  Future<WorkActStats> getWorkActStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('work_acts')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final acts = snapshot.docs.map(WorkAct.fromDocument).toList();

      final totalActs = acts.length;
      final signedActs =
          acts.where((act) => act.status == WorkActStatus.signed).length;
      final draftActs =
          acts.where((act) => act.status == WorkActStatus.draft).length;
      final rejectedActs =
          acts.where((act) => act.status == WorkActStatus.rejected).length;
      final totalAmount = acts
          .where((act) => act.status == WorkActStatus.signed)
          .fold<double>(0, (sum, act) => sum + act.totalAmount);

      return WorkActStats(
        specialistId: specialistId,
        totalActs: totalActs,
        signedActs: signedActs,
        draftActs: draftActs,
        rejectedActs: rejectedActs,
        totalAmount: totalAmount,
        lastUpdated: DateTime.now(),
      );
    } on Exception {
      // Логирование:'Ошибка получения статистики актов: $e');
      return WorkActStats.empty();
    }
  }
}

/// Статус акта выполненных работ
enum WorkActStatus { draft, signed, rejected }

/// Модель акта выполненных работ
class WorkAct {
  const WorkAct({
    required this.id,
    required this.bookingId,
    required this.specialistId,
    required this.customerId,
    required this.eventName,
    required this.eventDate,
    required this.eventLocation,
    required this.services,
    required this.totalAmount,
    required this.status, required this.createdAt, required this.updatedAt, this.notes,
    this.signedAt,
    this.signedBy,
    this.signature,
    this.rejectionReason,
  });

  factory WorkAct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkAct(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      eventName: data['eventName'] as String? ?? '',
      eventDate: data['eventDate'] as String? ?? '',
      eventLocation: data['eventLocation'] as String? ?? '',
      services: (data['services'] as List<dynamic>?)
              ?.map((item) => ServiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      status: WorkActStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => WorkActStatus.draft,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      signedBy: data['signedBy'] as String?,
      signature: data['signature'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  final String id;
  final String bookingId;
  final String specialistId;
  final String customerId;
  final String eventName;
  final String eventDate;
  final String eventLocation;
  final List<ServiceItem> services;
  final double totalAmount;
  final String? notes;
  final WorkActStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final String? signedBy;
  final String? signature;
  final String? rejectionReason;

  WorkAct copyWith({
    String? id,
    String? bookingId,
    String? specialistId,
    String? customerId,
    String? eventName,
    String? eventDate,
    String? eventLocation,
    List<ServiceItem>? services,
    double? totalAmount,
    String? notes,
    WorkActStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? signedAt,
    String? signedBy,
    String? signature,
    String? rejectionReason,
  }) =>
      WorkAct(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        eventName: eventName ?? this.eventName,
        eventDate: eventDate ?? this.eventDate,
        eventLocation: eventLocation ?? this.eventLocation,
        services: services ?? this.services,
        totalAmount: totalAmount ?? this.totalAmount,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        signedAt: signedAt ?? this.signedAt,
        signedBy: signedBy ?? this.signedBy,
        signature: signature ?? this.signature,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'specialistId': specialistId,
        'customerId': customerId,
        'eventName': eventName,
        'eventDate': eventDate,
        'eventLocation': eventLocation,
        'services': services.map((s) => s.toMap()).toList(),
        'totalAmount': totalAmount,
        'notes': notes,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
        'signedBy': signedBy,
        'signature': signature,
        'rejectionReason': rejectionReason,
      };

  bool get isSigned => status == WorkActStatus.signed;
  bool get isDraft => status == WorkActStatus.draft;
  bool get isRejected => status == WorkActStatus.rejected;
}

/// Элемент услуги в акте
class ServiceItem {
  const ServiceItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.description,
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) => ServiceItem(
        name: map['name'] as String? ?? '',
        quantity: map['quantity'] as int? ?? 1,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        description: map['description'] as String?,
      );

  final String name;
  final int quantity;
  final double price;
  final String? description;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'description': description,
      };

  double get totalPrice => quantity * price;
}

/// Статистика актов выполненных работ
class WorkActStats {
  const WorkActStats({
    required this.specialistId,
    required this.totalActs,
    required this.signedActs,
    required this.draftActs,
    required this.rejectedActs,
    required this.totalAmount,
    required this.lastUpdated,
  });

  factory WorkActStats.empty() => WorkActStats(
        specialistId: '',
        totalActs: 0,
        signedActs: 0,
        draftActs: 0,
        rejectedActs: 0,
        totalAmount: 0,
        lastUpdated: DateTime.now(),
      );

  final String specialistId;
  final int totalActs;
  final int signedActs;
  final int draftActs;
  final int rejectedActs;
  final double totalAmount;
  final DateTime lastUpdated;

  double get signedPercentage =>
      totalActs > 0 ? (signedActs / totalActs) * 100 : 0.0;
}

/// Сервис для управления актами выполненных работ (расширенная версия)
class WorkActServiceExtended {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить акты выполненных работ по бронированию
  Future<List<WorkAct>> getWorkActsByBooking(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('work_acts')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkAct.fromMap(doc.data(), doc.id))
          .toList();
    } on Exception {
      // Логирование:'Ошибка получения актов выполненных работ по бронированию: $e');
      return [];
    }
  }

  /// Сгенерировать акт выполненных работ
  Future<WorkAct> generateWorkAct(String bookingId) async {
    try {
      // Получить данные бронирования
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Бронирование не найдено');
      }

      final bookingData = bookingDoc.data()!;

      // Создать акт выполненных работ
      final workAct = WorkAct(
        id: '',
        actNumber: _generateActNumber(),
        bookingId: bookingId,
        customerId: bookingData['userId'] ?? '',
        specialistId: bookingData['specialistId'] ?? '',
        status: WorkActStatus.pending,
        title: 'Акт выполненных работ',
        totalAmount: (bookingData['totalPrice'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: null,
        workDescription: 'Выполненные работы по заказу',
        workStartDate: null,
        workEndDate: null,
        customerSignature: null,
        specialistSignature: null,
        metadata: const {},
        currency: 'RUB',
      );

      final docRef =
          await _firestore.collection('work_acts').add(workAct.toMap());

      return workAct.copyWith(id: docRef.id);
    } on Exception {
      // Логирование:'Ошибка генерации акта выполненных работ: $e');
      rethrow;
    }
  }

  /// Подтвердить акт выполненных работ
  Future<void> approveWorkAct(String workActId) async {
    try {
      await _firestore.collection('work_acts').doc(workActId).update({
        'status': WorkActStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception {
      // Логирование:'Ошибка подтверждения акта выполненных работ: $e');
      rethrow;
    }
  }

  /// Сгенерировать номер акта
  String _generateActNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');

    return 'АВР-$year$month$day-$random';
  }
}
