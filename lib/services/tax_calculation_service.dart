import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';

class TaxCalculationService {
  final Uuid _uuid = const Uuid();

  /// Calculate tax for a payment based on specialist's tax status
  Future<TaxCalculation> calculateTax({
    required String paymentId,
    required double grossAmount,
    required TaxStatus taxStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final taxRate = _getTaxRate(taxStatus);
      final taxAmount = grossAmount * taxRate;
      final netAmount = grossAmount - taxAmount;

      final calculationDetails = {
        'taxStatus': taxStatus.toString().split('.').last,
        'taxRate': taxRate,
        'grossAmount': grossAmount,
        'taxAmount': taxAmount,
        'netAmount': netAmount,
        'calculationDate': DateTime.now().toIso8601String(),
        'additionalData': additionalData ?? {},
      };

      final taxCalculation = TaxCalculation(
        id: _uuid.v4(),
        paymentId: paymentId,
        taxStatus: taxStatus,
        grossAmount: grossAmount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        netAmount: netAmount,
        calculationDetails: calculationDetails,
        calculatedAt: DateTime.now(),
      );

      debugPrint('Tax calculated: ${taxCalculation.id}');
      return taxCalculation;
    } catch (e) {
      debugPrint('Error calculating tax: $e');
      throw Exception('Ошибка расчета налогов: $e');
    }
  }

  /// Get tax rate based on tax status
  double _getTaxRate(TaxStatus taxStatus) {
    switch (taxStatus) {
      case TaxStatus.individual:
        // Физическое лицо - НДФЛ 13%
        return 0.13;
      case TaxStatus.individualEntrepreneur:
        // ИП - зависит от системы налогообложения
        // УСН 6% (упрощенная система налогообложения)
        return 0.06;
      case TaxStatus.selfEmployed:
        // Самозанятый - 4% с физлиц, 6% с ИП/юрлиц
        return 0.04; // По умолчанию 4% для физлиц
      case TaxStatus.legalEntity:
        // Юридическое лицо - НДС 20% + налог на прибыль 20%
        return 0.20; // Упрощенный расчет
    }
  }

  /// Calculate tax for self-employed with different rates
  Future<TaxCalculation> calculateSelfEmployedTax({
    required String paymentId,
    required double grossAmount,
    required bool isFromIndividual, // true - от физлица (4%), false - от ИП/юрлица (6%)
  }) async {
    try {
      final taxRate = isFromIndividual ? 0.04 : 0.06;
      final taxAmount = grossAmount * taxRate;
      final netAmount = grossAmount - taxAmount;

      final calculationDetails = {
        'taxStatus': 'selfEmployed',
        'taxRate': taxRate,
        'isFromIndividual': isFromIndividual,
        'grossAmount': grossAmount,
        'taxAmount': taxAmount,
        'netAmount': netAmount,
        'calculationDate': DateTime.now().toIso8601String(),
        'note': isFromIndividual 
            ? 'Самозанятый: 4% с физлица' 
            : 'Самозанятый: 6% с ИП/юрлица',
      };

      final taxCalculation = TaxCalculation(
        id: _uuid.v4(),
        paymentId: paymentId,
        taxStatus: TaxStatus.selfEmployed,
        grossAmount: grossAmount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        netAmount: netAmount,
        calculationDetails: calculationDetails,
        calculatedAt: DateTime.now(),
      );

      debugPrint('Self-employed tax calculated: ${taxCalculation.id}');
      return taxCalculation;
    } catch (e) {
      debugPrint('Error calculating self-employed tax: $e');
      throw Exception('Ошибка расчета налогов для самозанятого: $e');
    }
  }

  /// Calculate tax for IP with different taxation systems
  Future<TaxCalculation> calculateIPTax({
    required String paymentId,
    required double grossAmount,
    required IPTaxationSystem taxationSystem,
  }) async {
    try {
      double taxRate;
      String systemName;

      switch (taxationSystem) {
        case IPTaxationSystem.usnIncome:
          // УСН "Доходы" - 6%
          taxRate = 0.06;
          systemName = 'УСН "Доходы"';
          break;
        case IPTaxationSystem.usnIncomeExpenses:
          // УСН "Доходы минус расходы" - 15%
          taxRate = 0.15;
          systemName = 'УСН "Доходы минус расходы"';
          break;
        case IPTaxationSystem.osn:
          // ОСН - НДС 20% + налог на прибыль 20%
          taxRate = 0.20;
          systemName = 'ОСН';
          break;
        case IPTaxationSystem.psn:
          // ПСН - патентная система
          taxRate = 0.06; // Упрощенный расчет
          systemName = 'ПСН';
          break;
        case IPTaxationSystem.eshn:
          // ЕСХН - единый сельскохозяйственный налог
          taxRate = 0.06; // Упрощенный расчет
          systemName = 'ЕСХН';
          break;
      }

      final taxAmount = grossAmount * taxRate;
      final netAmount = grossAmount - taxAmount;

      final calculationDetails = {
        'taxStatus': 'individualEntrepreneur',
        'taxationSystem': taxationSystem.toString().split('.').last,
        'systemName': systemName,
        'taxRate': taxRate,
        'grossAmount': grossAmount,
        'taxAmount': taxAmount,
        'netAmount': netAmount,
        'calculationDate': DateTime.now().toIso8601String(),
      };

      final taxCalculation = TaxCalculation(
        id: _uuid.v4(),
        paymentId: paymentId,
        taxStatus: TaxStatus.individualEntrepreneur,
        grossAmount: grossAmount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        netAmount: netAmount,
        calculationDetails: calculationDetails,
        calculatedAt: DateTime.now(),
      );

      debugPrint('IP tax calculated: ${taxCalculation.id}');
      return taxCalculation;
    } catch (e) {
      debugPrint('Error calculating IP tax: $e');
      throw Exception('Ошибка расчета налогов для ИП: $e');
    }
  }

  /// Calculate tax for legal entity
  Future<TaxCalculation> calculateLegalEntityTax({
    required String paymentId,
    required double grossAmount,
    required LegalEntityTaxationSystem taxationSystem,
  }) async {
    try {
      double taxRate;
      String systemName;

      switch (taxationSystem) {
        case LegalEntityTaxationSystem.osn:
          // ОСН - НДС 20% + налог на прибыль 20%
          taxRate = 0.20;
          systemName = 'ОСН';
          break;
        case LegalEntityTaxationSystem.usnIncome:
          // УСН "Доходы" - 6%
          taxRate = 0.06;
          systemName = 'УСН "Доходы"';
          break;
        case LegalEntityTaxationSystem.usnIncomeExpenses:
          // УСН "Доходы минус расходы" - 15%
          taxRate = 0.15;
          systemName = 'УСН "Доходы минус расходы"';
          break;
        case LegalEntityTaxationSystem.eshn:
          // ЕСХН - единый сельскохозяйственный налог
          taxRate = 0.06; // Упрощенный расчет
          systemName = 'ЕСХН';
          break;
      }

      final taxAmount = grossAmount * taxRate;
      final netAmount = grossAmount - taxAmount;

      final calculationDetails = {
        'taxStatus': 'legalEntity',
        'taxationSystem': taxationSystem.toString().split('.').last,
        'systemName': systemName,
        'taxRate': taxRate,
        'grossAmount': grossAmount,
        'taxAmount': taxAmount,
        'netAmount': netAmount,
        'calculationDate': DateTime.now().toIso8601String(),
      };

      final taxCalculation = TaxCalculation(
        id: _uuid.v4(),
        paymentId: paymentId,
        taxStatus: TaxStatus.legalEntity,
        grossAmount: grossAmount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        netAmount: netAmount,
        calculationDetails: calculationDetails,
        calculatedAt: DateTime.now(),
      );

      debugPrint('Legal entity tax calculated: ${taxCalculation.id}');
      return taxCalculation;
    } catch (e) {
      debugPrint('Error calculating legal entity tax: $e');
      throw Exception('Ошибка расчета налогов для юрлица: $e');
    }
  }

  /// Get tax rate for specific tax status
  double getTaxRate(TaxStatus taxStatus) {
    return _getTaxRate(taxStatus);
  }

  /// Get tax rate for IP with specific taxation system
  double getIPTaxRate(IPTaxationSystem taxationSystem) {
    switch (taxationSystem) {
      case IPTaxationSystem.usnIncome:
        return 0.06;
      case IPTaxationSystem.usnIncomeExpenses:
        return 0.15;
      case IPTaxationSystem.osn:
        return 0.20;
      case IPTaxationSystem.psn:
        return 0.06;
      case IPTaxationSystem.eshn:
        return 0.06;
    }
  }

  /// Get tax rate for legal entity with specific taxation system
  double getLegalEntityTaxRate(LegalEntityTaxationSystem taxationSystem) {
    switch (taxationSystem) {
      case LegalEntityTaxationSystem.osn:
        return 0.20;
      case LegalEntityTaxationSystem.usnIncome:
        return 0.06;
      case LegalEntityTaxationSystem.usnIncomeExpenses:
        return 0.15;
      case LegalEntityTaxationSystem.eshn:
        return 0.06;
    }
  }

  /// Calculate monthly tax summary for specialist
  Future<MonthlyTaxSummary> calculateMonthlyTaxSummary({
    required String specialistId,
    required int year,
    required int month,
    required TaxStatus taxStatus,
  }) async {
    try {
      // This would typically fetch payments from Firestore
      // For now, return a mock calculation
      final totalGrossAmount = 100000.0; // Mock amount
      final taxRate = _getTaxRate(taxStatus);
      final totalTaxAmount = totalGrossAmount * taxRate;
      final totalNetAmount = totalGrossAmount - totalTaxAmount;

      return MonthlyTaxSummary(
        specialistId: specialistId,
        year: year,
        month: month,
        taxStatus: taxStatus,
        totalGrossAmount: totalGrossAmount,
        totalTaxAmount: totalTaxAmount,
        totalNetAmount: totalNetAmount,
        paymentCount: 10, // Mock count
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error calculating monthly tax summary: $e');
      throw Exception('Ошибка расчета месячной налоговой сводки: $e');
    }
  }

  /// Generate tax report for specialist
  Future<TaxReport> generateTaxReport({
    required String specialistId,
    required int year,
    required TaxStatus taxStatus,
  }) async {
    try {
      final monthlySummaries = <MonthlyTaxSummary>[];
      
      // Generate monthly summaries for the year
      for (int month = 1; month <= 12; month++) {
        final summary = await calculateMonthlyTaxSummary(
          specialistId: specialistId,
          year: year,
          month: month,
          taxStatus: taxStatus,
        );
        monthlySummaries.add(summary);
      }

      final totalGrossAmount = monthlySummaries.fold(0.0, (sum, summary) => sum + summary.totalGrossAmount);
      final totalTaxAmount = monthlySummaries.fold(0.0, (sum, summary) => sum + summary.totalTaxAmount);
      final totalNetAmount = monthlySummaries.fold(0.0, (sum, summary) => sum + summary.totalNetAmount);
      final totalPaymentCount = monthlySummaries.fold(0, (sum, summary) => sum + summary.paymentCount);

      return TaxReport(
        id: _uuid.v4(),
        specialistId: specialistId,
        year: year,
        taxStatus: taxStatus,
        monthlySummaries: monthlySummaries,
        totalGrossAmount: totalGrossAmount,
        totalTaxAmount: totalTaxAmount,
        totalNetAmount: totalNetAmount,
        totalPaymentCount: totalPaymentCount,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating tax report: $e');
      throw Exception('Ошибка генерации налогового отчета: $e');
    }
  }
}

// Enums for taxation systems
enum IPTaxationSystem {
  usnIncome, // УСН "Доходы"
  usnIncomeExpenses, // УСН "Доходы минус расходы"
  osn, // ОСН
  psn, // ПСН
  eshn, // ЕСХН
}

enum LegalEntityTaxationSystem {
  osn, // ОСН
  usnIncome, // УСН "Доходы"
  usnIncomeExpenses, // УСН "Доходы минус расходы"
  eshn, // ЕСХН
}

// Additional models for tax reporting
class MonthlyTaxSummary {
  final String specialistId;
  final int year;
  final int month;
  final TaxStatus taxStatus;
  final double totalGrossAmount;
  final double totalTaxAmount;
  final double totalNetAmount;
  final int paymentCount;
  final DateTime calculatedAt;

  MonthlyTaxSummary({
    required this.specialistId,
    required this.year,
    required this.month,
    required this.taxStatus,
    required this.totalGrossAmount,
    required this.totalTaxAmount,
    required this.totalNetAmount,
    required this.paymentCount,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'year': year,
      'month': month,
      'taxStatus': taxStatus.toString().split('.').last,
      'totalGrossAmount': totalGrossAmount,
      'totalTaxAmount': totalTaxAmount,
      'totalNetAmount': totalNetAmount,
      'paymentCount': paymentCount,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory MonthlyTaxSummary.fromMap(Map<String, dynamic> map) {
    return MonthlyTaxSummary(
      specialistId: map['specialistId'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['taxStatus'] as String,
      ),
      totalGrossAmount: (map['totalGrossAmount'] as num).toDouble(),
      totalTaxAmount: (map['totalTaxAmount'] as num).toDouble(),
      totalNetAmount: (map['totalNetAmount'] as num).toDouble(),
      paymentCount: map['paymentCount'] as int,
      calculatedAt: DateTime.parse(map['calculatedAt'] as String),
    );
  }
}

class TaxReport {
  final String id;
  final String specialistId;
  final int year;
  final TaxStatus taxStatus;
  final List<MonthlyTaxSummary> monthlySummaries;
  final double totalGrossAmount;
  final double totalTaxAmount;
  final double totalNetAmount;
  final int totalPaymentCount;
  final DateTime generatedAt;

  TaxReport({
    required this.id,
    required this.specialistId,
    required this.year,
    required this.taxStatus,
    required this.monthlySummaries,
    required this.totalGrossAmount,
    required this.totalTaxAmount,
    required this.totalNetAmount,
    required this.totalPaymentCount,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'specialistId': specialistId,
      'year': year,
      'taxStatus': taxStatus.toString().split('.').last,
      'monthlySummaries': monthlySummaries.map((summary) => summary.toMap()).toList(),
      'totalGrossAmount': totalGrossAmount,
      'totalTaxAmount': totalTaxAmount,
      'totalNetAmount': totalNetAmount,
      'totalPaymentCount': totalPaymentCount,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory TaxReport.fromMap(Map<String, dynamic> map) {
    return TaxReport(
      id: map['id'] as String,
      specialistId: map['specialistId'] as String,
      year: map['year'] as int,
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['taxStatus'] as String,
      ),
      monthlySummaries: (map['monthlySummaries'] as List<dynamic>)
          .map((summary) => MonthlyTaxSummary.fromMap(summary as Map<String, dynamic>))
          .toList(),
      totalGrossAmount: (map['totalGrossAmount'] as num).toDouble(),
      totalTaxAmount: (map['totalTaxAmount'] as num).toDouble(),
      totalNetAmount: (map['totalNetAmount'] as num).toDouble(),
      totalPaymentCount: map['totalPaymentCount'] as int,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }
}
