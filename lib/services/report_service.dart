import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/report.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Сервис отчетов
class ReportService {
  factory ReportService() => _instance;
  ReportService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final ReportService _instance = ReportService._internal();

  /// Создать отчет
  Future<String> createReport({
    required String name,
    required String description,
    required ReportType type,
    required ReportCategory category,
    required Map<String, dynamic> parameters,
    String? generatedBy,
  }) async {
    try {
      final reportId = _uuid.v4();
      final now = DateTime.now();

      final report = Report(
        id: reportId,
        name: name,
        description: description,
        type: type,
        category: category,
        parameters: parameters,
        generatedBy: generatedBy,
        createdAt: now,
      );

      await _firestore.collection('reports').doc(reportId).set(report.toMap());

      // Запускаем генерацию отчета в фоне
      _generateReport(reportId);

      return reportId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания отчета: $e');
      }
      rethrow;
    }
  }

  /// Создать отчет по шаблону
  Future<String> createReportFromTemplate({
    required String templateId,
    required Map<String, dynamic> parameters,
    String? generatedBy,
  }) async {
    try {
      // Получаем шаблон
      final templateDoc =
          await _firestore.collection('reportTemplates').doc(templateId).get();

      if (!templateDoc.exists) {
        throw Exception('Шаблон отчета не найден');
      }

      final template = ReportTemplate.fromDocument(templateDoc);

      if (!template.isActive) {
        throw Exception('Шаблон отчета неактивен');
      }

      // Проверяем параметры
      if (!template.areParametersValid(parameters)) {
        throw Exception('Не все обязательные параметры указаны');
      }

      // Объединяем параметры с параметрами по умолчанию
      final finalParameters = {...template.defaultParameters, ...parameters};

      // Создаем отчет
      return await createReport(
        name: template.name,
        description: template.description,
        type: template.type,
        category: template.category,
        parameters: finalParameters,
        generatedBy: generatedBy,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания отчета по шаблону: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет
  Future<void> _generateReport(String reportId) async {
    try {
      // Обновляем статус на "генерируется"
      await _updateReportStatus(reportId, ReportStatus.generating);

      // Получаем отчет
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) return;

      final report = Report.fromDocument(reportDoc);

      // Генерируем данные в зависимости от типа отчета
      ReportData reportData;
      switch (report.type) {
        case ReportType.bookings:
          reportData = await _generateBookingsReport(report.parameters);
        case ReportType.payments:
          reportData = await _generatePaymentsReport(report.parameters);
        case ReportType.users:
          reportData = await _generateUsersReport(report.parameters);
        case ReportType.specialists:
          reportData = await _generateSpecialistsReport(report.parameters);
        case ReportType.analytics:
          reportData = await _generateAnalyticsReport(report.parameters);
        case ReportType.notifications:
          reportData = await _generateNotificationsReport(report.parameters);
        case ReportType.errors:
          reportData = await _generateErrorsReport(report.parameters);
        case ReportType.performance:
          reportData = await _generatePerformanceReport(report.parameters);
        default:
          reportData = await _generateCustomReport(report.parameters);
      }

      // Сохраняем данные отчета
      await _firestore
          .collection('reportData')
          .doc(reportId)
          .set(reportData.toMap());

      // Генерируем файл отчета
      final fileUrl = await _generateReportFile(reportId, reportData);

      // Обновляем статус на "завершено"
      await _updateReportStatus(reportId, ReportStatus.completed,
          fileUrl: fileUrl,);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета: $e');
      }

      // Обновляем статус на "ошибка"
      await _updateReportStatus(reportId, ReportStatus.failed,
          errorMessage: e.toString(),);
    }
  }

  /// Обновить статус отчета
  Future<void> _updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? fileUrl,
    String? errorMessage,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == ReportStatus.generating) {
        updateData['generatedAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == ReportStatus.completed && fileUrl != null) {
        updateData['fileUrl'] = fileUrl;
      } else if (status == ReportStatus.failed && errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore.collection('reports').doc(reportId).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления статуса отчета: $e');
      }
    }
  }

  /// Генерировать отчет по бронированиям
  Future<ReportData> _generateBookingsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final startDate = parameters['startDate'] as DateTime?;
      final endDate = parameters['endDate'] as DateTime?;
      final specialistId = parameters['specialistId'] as String?;
      final status = parameters['status'] as String?;

      Query<Map<String, dynamic>> query = _firestore.collection('bookings');

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }
      if (specialistId != null) {
        query = query.where('specialistId', isEqualTo: specialistId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      double totalRevenue = 0;
      var completedBookings = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'customerId': data['customerId'],
          'specialistId': data['specialistId'],
          'status': data['status'],
          'totalPrice': data['totalPrice'],
          'createdAt':
              (data['createdAt'] as Timestamp).toDate().toIso8601String(),
          'startTime': data['startTime'] != null
              ? (data['startTime'] as Timestamp).toDate().toIso8601String()
              : null,
          'endTime': data['endTime'] != null
              ? (data['endTime'] as Timestamp).toDate().toIso8601String()
              : null,
        };
        rows.add(row);

        if (data['status'] == 'completed') {
          totalRevenue += (data['totalPrice'] as num).toDouble();
          completedBookings++;
        }
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: [
          'id',
          'customerId',
          'specialistId',
          'status',
          'totalPrice',
          'createdAt',
          'startTime',
          'endTime',
        ],
        summary: {
          'totalBookings': rows.length,
          'completedBookings': completedBookings,
          'totalRevenue': totalRevenue,
          'averageBookingValue':
              rows.isNotEmpty ? totalRevenue / rows.length : 0,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по бронированиям: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по платежам
  Future<ReportData> _generatePaymentsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final startDate = parameters['startDate'] as DateTime?;
      final endDate = parameters['endDate'] as DateTime?;
      final paymentMethod = parameters['paymentMethod'] as String?;

      Query<Map<String, dynamic>> query = _firestore.collection('payments');

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }
      if (paymentMethod != null) {
        query = query.where('method', isEqualTo: paymentMethod);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      double totalAmount = 0;
      var successfulPayments = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'bookingId': data['bookingId'],
          'amount': data['amount'],
          'method': data['method'],
          'status': data['status'],
          'createdAt':
              (data['createdAt'] as Timestamp).toDate().toIso8601String(),
        };
        rows.add(row);

        if (data['status'] == 'completed') {
          totalAmount += (data['amount'] as num).toDouble();
          successfulPayments++;
        }
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: ['id', 'bookingId', 'amount', 'method', 'status', 'createdAt'],
        summary: {
          'totalPayments': rows.length,
          'successfulPayments': successfulPayments,
          'totalAmount': totalAmount,
          'averagePaymentAmount':
              rows.isNotEmpty ? totalAmount / rows.length : 0,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по платежам: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по пользователям
  Future<ReportData> _generateUsersReport(
      Map<String, dynamic> parameters,) async {
    try {
      final userType = parameters['userType'] as String?;
      final isActive = parameters['isActive'] as bool?;

      Query<Map<String, dynamic>> query = _firestore.collection('users');

      if (userType != null) {
        query = query.where('type', isEqualTo: userType);
      }
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      var activeUsers = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'name': data['name'],
          'email': data['email'],
          'type': data['type'],
          'isActive': data['isActive'],
          'createdAt':
              (data['createdAt'] as Timestamp).toDate().toIso8601String(),
          'lastLoginAt': data['lastLoginAt'] != null
              ? (data['lastLoginAt'] as Timestamp).toDate().toIso8601String()
              : null,
        };
        rows.add(row);

        if (data['isActive'] == true) {
          activeUsers++;
        }
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: [
          'id',
          'name',
          'email',
          'type',
          'isActive',
          'createdAt',
          'lastLoginAt',
        ],
        summary: {
          'totalUsers': rows.length,
          'activeUsers': activeUsers,
          'inactiveUsers': rows.length - activeUsers,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по пользователям: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по специалистам
  Future<ReportData> _generateSpecialistsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final category = parameters['category'] as String?;
      final isVerified = parameters['isVerified'] as bool?;

      Query<Map<String, dynamic>> query = _firestore.collection('specialists');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      var verifiedSpecialists = 0;
      double totalRating = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'name': data['name'],
          'email': data['email'],
          'category': data['category'],
          'rating': data['rating'],
          'reviewCount': data['reviewCount'],
          'isVerified': data['isVerified'],
          'createdAt':
              (data['createdAt'] as Timestamp).toDate().toIso8601String(),
        };
        rows.add(row);

        if (data['isVerified'] == true) {
          verifiedSpecialists++;
        }
        totalRating += (data['rating'] as num).toDouble();
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: [
          'id',
          'name',
          'email',
          'category',
          'rating',
          'reviewCount',
          'isVerified',
          'createdAt',
        ],
        summary: {
          'totalSpecialists': rows.length,
          'verifiedSpecialists': verifiedSpecialists,
          'averageRating': rows.isNotEmpty ? totalRating / rows.length : 0,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по специалистам: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по аналитике
  Future<ReportData> _generateAnalyticsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final startDate = parameters['startDate'] as DateTime?;
      final endDate = parameters['endDate'] as DateTime?;

      Query<Map<String, dynamic>> query =
          _firestore.collection('analyticsEvents');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      final eventCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'eventName': data['eventName'],
          'screen': data['screen'],
          'userId': data['userId'],
          'timestamp':
              (data['timestamp'] as Timestamp).toDate().toIso8601String(),
        };
        rows.add(row);

        final eventName = data['eventName'] as String;
        eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: ['id', 'eventName', 'screen', 'userId', 'timestamp'],
        summary: {
          'totalEvents': rows.length,
          'uniqueUsers': rows.map((r) => r['userId']).toSet().length,
          'eventCounts': eventCounts,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по аналитике: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по уведомлениям
  Future<ReportData> _generateNotificationsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final startDate = parameters['startDate'] as DateTime?;
      final endDate = parameters['endDate'] as DateTime?;
      final type = parameters['type'] as String?;

      Query<Map<String, dynamic>> query =
          _firestore.collection('sentNotifications');

      if (startDate != null) {
        query = query.where('sentAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('sentAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      var deliveredCount = 0;
      var readCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'title': data['title'],
          'type': data['type'],
          'channel': data['channel'],
          'status': data['status'],
          'sentAt': (data['sentAt'] as Timestamp).toDate().toIso8601String(),
          'deliveredAt': data['deliveredAt'] != null
              ? (data['deliveredAt'] as Timestamp).toDate().toIso8601String()
              : null,
          'readAt': data['readAt'] != null
              ? (data['readAt'] as Timestamp).toDate().toIso8601String()
              : null,
        };
        rows.add(row);

        if (data['status'] == 'delivered') {
          deliveredCount++;
        }
        if (data['readAt'] != null) {
          readCount++;
        }
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: [
          'id',
          'title',
          'type',
          'channel',
          'status',
          'sentAt',
          'deliveredAt',
          'readAt',
        ],
        summary: {
          'totalSent': rows.length,
          'deliveredCount': deliveredCount,
          'readCount': readCount,
          'deliveryRate':
              rows.isNotEmpty ? (deliveredCount / rows.length) * 100 : 0,
          'readRate':
              deliveredCount > 0 ? (readCount / deliveredCount) * 100 : 0,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по уведомлениям: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по ошибкам
  Future<ReportData> _generateErrorsReport(
      Map<String, dynamic> parameters,) async {
    try {
      final startDate = parameters['startDate'] as DateTime?;
      final endDate = parameters['endDate'] as DateTime?;
      final errorType = parameters['errorType'] as String?;

      Query<Map<String, dynamic>> query = _firestore.collection('appErrors');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }
      if (errorType != null) {
        query = query.where('errorType', isEqualTo: errorType);
      }

      final snapshot = await query.get();
      final rows = <Map<String, dynamic>>[];
      var resolvedCount = 0;
      final errorTypeCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final row = {
          'id': doc.id,
          'errorType': data['errorType'],
          'screen': data['screen'],
          'errorMessage': data['errorMessage'],
          'resolved': data['resolved'],
          'timestamp':
              (data['timestamp'] as Timestamp).toDate().toIso8601String(),
        };
        rows.add(row);

        if (data['resolved'] == true) {
          resolvedCount++;
        }

        final type = data['errorType'] as String;
        errorTypeCounts[type] = (errorTypeCounts[type] ?? 0) + 1;
      }

      return ReportData(
        reportId: '',
        rows: rows,
        columns: [
          'id',
          'errorType',
          'screen',
          'errorMessage',
          'resolved',
          'timestamp',
        ],
        summary: {
          'totalErrors': rows.length,
          'resolvedCount': resolvedCount,
          'unresolvedCount': rows.length - resolvedCount,
          'errorTypeCounts': errorTypeCounts,
        },
        generatedAt: DateTime.now(),
        totalRows: rows.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по ошибкам: $e');
      }
      rethrow;
    }
  }

  /// Генерировать отчет по производительности
  Future<ReportData> _generatePerformanceReport(
      Map<String, dynamic> parameters,) async {
    try {
      // TODO(developer): Реализовать сбор метрик производительности
      return ReportData(
        reportId: '',
        rows: [],
        columns: ['metric', 'value', 'timestamp'],
        summary: {'totalMetrics': 0},
        generatedAt: DateTime.now(),
        totalRows: 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации отчета по производительности: $e');
      }
      rethrow;
    }
  }

  /// Генерировать пользовательский отчет
  Future<ReportData> _generateCustomReport(
      Map<String, dynamic> parameters,) async {
    try {
      // TODO(developer): Реализовать генерацию пользовательских отчетов
      return ReportData(
        reportId: '',
        rows: [],
        columns: [],
        summary: {},
        generatedAt: DateTime.now(),
        totalRows: 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации пользовательского отчета: $e');
      }
      rethrow;
    }
  }

  /// Генерировать файл отчета
  Future<String> _generateReportFile(
      String reportId, ReportData reportData,) async {
    try {
      // Генерируем CSV файл
      final csv = StringBuffer();

      // Заголовки
      csv.writeln(reportData.columns.join(','));

      // Данные
      for (final row in reportData.rows) {
        final values = reportData.columns
            .map((col) => row[col]?.toString() ?? '')
            .toList();
        csv.writeln(values.join(','));
      }

      // TODO(developer): Сохранить файл в Firebase Storage и вернуть URL
      return 'https://storage.googleapis.com/reports/$reportId.csv';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка генерации файла отчета: $e');
      }
      rethrow;
    }
  }

  /// Получить отчет
  Future<Report?> getReport(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return Report.fromDocument(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения отчета: $e');
      }
      return null;
    }
  }

  /// Получить данные отчета
  Future<ReportData?> getReportData(String reportId) async {
    try {
      final doc = await _firestore.collection('reportData').doc(reportId).get();
      if (doc.exists) {
        return ReportData.fromDocument(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения данных отчета: $e');
      }
      return null;
    }
  }

  /// Получить список отчетов
  Future<List<Report>> getReports({
    String? generatedBy,
    ReportType? type,
    ReportStatus? status,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('reports');

      if (generatedBy != null) {
        query = query.where('generatedBy', isEqualTo: generatedBy);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map(Report.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения списка отчетов: $e');
      }
      return [];
    }
  }

  /// Получить шаблоны отчетов
  Future<List<ReportTemplate>> getReportTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('reportTemplates')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map(ReportTemplate.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения шаблонов отчетов: $e');
      }
      return [];
    }
  }

  /// Удалить отчет
  Future<void> deleteReport(String reportId) async {
    try {
      await Future.wait([
        _firestore.collection('reports').doc(reportId).delete(),
        _firestore.collection('reportData').doc(reportId).delete(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка удаления отчета: $e');
      }
      rethrow;
    }
  }

  /// Очистить старые отчеты
  Future<void> cleanupOldReports({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('reports')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        batch.delete(_firestore.collection('reportData').doc(doc.id));
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка очистки старых отчетов: $e');
      }
    }
  }
}
