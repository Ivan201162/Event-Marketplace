import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/specialist.dart';
import '../models/tax_info.dart';
import '../utils/logger.dart';

/// Сервис для работы с налогами специалистов
class TaxService {
  factory TaxService() => _instance;
  TaxService._internal();
  static final TaxService _instance = TaxService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Рассчитать налог для специалиста
  Future<TaxInfo> calculateTax({
    required String userId,
    required String specialistId,
    required TaxType taxType,
    required double income,
    required String period,
    double? customTaxRate,
  }) async {
    try {
      AppLogger.logI('Начинаем расчёт налога для специалиста $specialistId', 'tax_service');

      // Определяем налоговую ставку
      final taxRate = customTaxRate ?? _getTaxRate(taxType, income);

      // Рассчитываем сумму налога
      final taxAmount = income * taxRate;

      // Создаём запись о налоге
      final taxInfo = TaxInfo(
        id: _uuid.v4(),
        userId: userId,
        specialistId: specialistId,
        taxType: taxType,
        taxRate: taxRate,
        income: income,
        taxAmount: taxAmount,
        period: period,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      AppLogger.logI('Налог рассчитан: ${taxInfo.formattedTaxAmount}', 'tax_service');
      return taxInfo;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка расчёта налога', 'tax_service', e);
      throw Exception('Не удалось рассчитать налог: $e');
    }
  }

  /// Получить налоговую ставку для типа налогообложения
  double _getTaxRate(TaxType taxType, double income) {
    switch (taxType) {
      case TaxType.individual:
        // НДФЛ 13%
        return 0.13;

      case TaxType.selfEmployed:
        // Самозанятые: 4% с физлиц, 6% с ИП/юрлиц
        // Для упрощения используем 4%
        return 0.04;

      case TaxType.individualEntrepreneur:
        // ИП на УСН "доходы" - 6%
        // ИП на УСН "доходы минус расходы" - 15%
        // Для упрощения используем 6%
        return 0.06;

      case TaxType.government:
        // Государственные учреждения освобождены
        return 0;
    }
  }

  /// Сохранить информацию о налоге
  Future<void> saveTaxInfo(TaxInfo taxInfo) async {
    try {
      AppLogger.logI('Сохраняем информацию о налоге ${taxInfo.id}', 'tax_service');

      await _db.collection('tax_info').doc(taxInfo.id).set(taxInfo.toMap());

      AppLogger.logI('Информация о налоге сохранена', 'tax_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка сохранения информации о налоге', 'tax_service', e);
      throw Exception('Не удалось сохранить информацию о налоге: $e');
    }
  }

  /// Получить налоговую информацию специалиста
  Future<List<TaxInfo>> getTaxInfoForSpecialist(String specialistId) async {
    try {
      AppLogger.logI('Получаем налоговую информацию для специалиста $specialistId', 'tax_service');

      final querySnapshot = await _db
          .collection('tax_info')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      final taxInfoList = querySnapshot.docs.map(TaxInfo.fromDocument).toList();

      AppLogger.logI('Получено ${taxInfoList.length} записей о налогах', 'tax_service');
      return taxInfoList;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения налоговой информации', 'tax_service', e);
      throw Exception('Не удалось получить налоговую информацию: $e');
    }
  }

  /// Получить налоговую сводку за период
  Future<TaxSummary> getTaxSummary({required String specialistId, required String period}) async {
    try {
      AppLogger.logI('Получаем налоговую сводку за период $period', 'tax_service');

      final taxRecords = await _db
          .collection('tax_info')
          .where('specialistId', isEqualTo: specialistId)
          .where('period', isEqualTo: period)
          .get();

      final taxInfoList = taxRecords.docs.map(TaxInfo.fromDocument).toList();

      // Рассчитываем суммы
      double totalIncome = 0;
      double totalTaxAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;
      double overdueAmount = 0;

      for (final taxInfo in taxInfoList) {
        totalIncome += taxInfo.income;
        totalTaxAmount += taxInfo.taxAmount;

        if (taxInfo.isPaid) {
          paidAmount += taxInfo.taxAmount;
        } else {
          unpaidAmount += taxInfo.taxAmount;
          if (taxInfo.isOverdue) {
            overdueAmount += taxInfo.taxAmount;
          }
        }
      }

      final summary = TaxSummary(
        period: period,
        totalIncome: totalIncome,
        totalTaxAmount: totalTaxAmount,
        taxRecords: taxInfoList,
        paidAmount: paidAmount,
        unpaidAmount: unpaidAmount,
        overdueAmount: overdueAmount,
      );

      AppLogger.logI('Налоговая сводка создана: ${summary.formattedTotalTaxAmount}', 'tax_service');
      return summary;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения налоговой сводки', 'tax_service', e);
      throw Exception('Не удалось получить налоговую сводку: $e');
    }
  }

  /// Отметить налог как оплаченный
  Future<void> markTaxAsPaid({
    required String taxInfoId,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      AppLogger.logI('Отмечаем налог $taxInfoId как оплаченный', 'tax_service');

      await _db.collection('tax_info').doc(taxInfoId).update({
        'isPaid': true,
        'paidAt': Timestamp.fromDate(DateTime.now()),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Налог отмечен как оплаченный', 'tax_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка отметки налога как оплаченного', 'tax_service', e);
      throw Exception('Не удалось отметить налог как оплаченный: $e');
    }
  }

  /// Получить напоминания о налогах
  Future<List<TaxInfo>> getTaxReminders() async {
    try {
      AppLogger.logI('Получаем напоминания о налогах', 'tax_service');

      final now = DateTime.now();
      final querySnapshot = await _db
          .collection('tax_info')
          .where('isPaid', isEqualTo: false)
          .where('nextReminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final reminders = querySnapshot.docs.map(TaxInfo.fromDocument).toList();

      AppLogger.logI('Получено ${reminders.length} напоминаний', 'tax_service');
      return reminders;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения напоминаний', 'tax_service', e);
      throw Exception('Не удалось получить напоминания: $e');
    }
  }

  /// Отправить напоминание о налоге
  Future<void> sendTaxReminder(String taxInfoId) async {
    try {
      AppLogger.logI('Отправляем напоминание о налоге $taxInfoId', 'tax_service');

      // Обновляем статус напоминания
      await _db.collection('tax_info').doc(taxInfoId).update({
        'reminderSent': true,
        'nextReminderDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Здесь можно добавить отправку push-уведомления или email
      AppLogger.logI('Напоминание отправлено', 'tax_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка отправки напоминания', 'tax_service', e);
      throw Exception('Не удалось отправить напоминание: $e');
    }
  }

  /// Рассчитать налог на основе дохода специалиста за период
  Future<TaxInfo> calculateTaxFromEarnings({
    required String userId,
    required String specialistId,
    required TaxType taxType,
    required String period,
    required double earnings,
  }) async {
    try {
      AppLogger.logI('Рассчитываем налог с дохода $earnings за период $period', 'tax_service');

      final taxInfo = await calculateTax(
        userId: userId,
        specialistId: specialistId,
        taxType: taxType,
        income: earnings,
        period: period,
      );

      // Сохраняем информацию о налоге
      await saveTaxInfo(taxInfo);

      return taxInfo;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка расчёта налога с дохода', 'tax_service', e);
      throw Exception('Не удалось рассчитать налог с дохода: $e');
    }
  }

  /// Получить статистику по налогам специалиста
  Future<Map<String, dynamic>> getTaxStatistics(String specialistId) async {
    try {
      AppLogger.logI('Получаем статистику по налогам для специалиста $specialistId', 'tax_service');

      final taxRecords = await getTaxInfoForSpecialist(specialistId);

      if (taxRecords.isEmpty) {
        return {
          'totalIncome': 0.0,
          'totalTaxAmount': 0.0,
          'paidAmount': 0.0,
          'unpaidAmount': 0.0,
          'overdueAmount': 0.0,
          'paymentPercentage': 0.0,
          'recordsCount': 0,
        };
      }

      double totalIncome = 0;
      double totalTaxAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;
      double overdueAmount = 0;

      for (final taxInfo in taxRecords) {
        totalIncome += taxInfo.income;
        totalTaxAmount += taxInfo.taxAmount;

        if (taxInfo.isPaid) {
          paidAmount += taxInfo.taxAmount;
        } else {
          unpaidAmount += taxInfo.taxAmount;
          if (taxInfo.isOverdue) {
            overdueAmount += taxInfo.taxAmount;
          }
        }
      }

      final paymentPercentage = totalTaxAmount > 0 ? (paidAmount / totalTaxAmount) * 100 : 0.0;

      final statistics = {
        'totalIncome': totalIncome,
        'totalTaxAmount': totalTaxAmount,
        'paidAmount': paidAmount,
        'unpaidAmount': unpaidAmount,
        'overdueAmount': overdueAmount,
        'paymentPercentage': paymentPercentage,
        'recordsCount': taxRecords.length,
      };

      AppLogger.logI('Статистика получена: ${statistics['recordsCount']} записей', 'tax_service');
      return statistics;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения статистики', 'tax_service', e);
      throw Exception('Не удалось получить статистику: $e');
    }
  }

  /// Обновить налоговую информацию
  Future<void> updateTaxInfo(TaxInfo taxInfo) async {
    try {
      AppLogger.logI('Обновляем налоговую информацию ${taxInfo.id}', 'tax_service');

      final updatedTaxInfo = taxInfo.copyWith(updatedAt: DateTime.now());

      await _db.collection('tax_info').doc(taxInfo.id).update(updatedTaxInfo.toMap());

      AppLogger.logI('Налоговая информация обновлена', 'tax_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка обновления налоговой информации', 'tax_service', e);
      throw Exception('Не удалось обновить налоговую информацию: $e');
    }
  }

  /// Удалить налоговую информацию
  Future<void> deleteTaxInfo(String taxInfoId) async {
    try {
      AppLogger.logI('Удаляем налоговую информацию $taxInfoId', 'tax_service');

      await _db.collection('tax_info').doc(taxInfoId).delete();

      AppLogger.logI('Налоговая информация удалена', 'tax_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка удаления налоговой информации', 'tax_service', e);
      throw Exception('Не удалось удалить налоговую информацию: $e');
    }
  }
}
