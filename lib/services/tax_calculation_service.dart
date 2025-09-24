import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_models.dart';

/// Сервис для расчета налогов
class TaxCalculationService {
  final Uuid _uuid = const Uuid();

  /// Рассчитать налоги для платежа
  Future<TaxCalculation> calculateTax({
    required String paymentId,
    required double grossAmount,
    required TaxStatus taxStatus,
  }) async {
    try {
      final taxRate = _getTaxRate(taxStatus);
      final taxAmount = grossAmount * taxRate / 100;
      final netAmount = grossAmount - taxAmount;

      return TaxCalculation(
        id: _uuid.v4(),
        paymentId: paymentId,
        grossAmount: grossAmount,
        taxAmount: taxAmount,
        netAmount: netAmount,
        taxRate: taxRate,
        taxStatus: taxStatus,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error calculating tax: $e');
      throw Exception('Ошибка расчета налогов: $e');
    }
  }

  /// Получить ставку налога
  double _getTaxRate(TaxStatus taxStatus) {
    switch (taxStatus) {
      case TaxStatus.none:
        return 0.0;
      case TaxStatus.professionalIncome:
        return 4.0; // НПД для самозанятых
      case TaxStatus.simplifiedTax:
        return 6.0; // УСН 6%
      case TaxStatus.vat:
        return 20.0; // НДС 20%
    }
  }

  /// Получить рекомендуемый статус налогообложения
  TaxStatus getRecommendedTaxStatus({
    required bool isIndividual,
    required bool isSelfEmployed,
    required bool isEntrepreneur,
    required double amount,
  }) {
    if (isIndividual && !isSelfEmployed && !isEntrepreneur) {
      return TaxStatus.none; // Физическое лицо без статуса
    }

    if (isSelfEmployed) {
      return TaxStatus.professionalIncome; // Самозанятый
    }

    if (isEntrepreneur) {
      if (amount < 100000) {
        return TaxStatus.simplifiedTax; // УСН для малых сумм
      } else {
        return TaxStatus.vat; // НДС для больших сумм
      }
    }

    return TaxStatus.none;
  }

  /// Рассчитать налоги для нескольких платежей
  Future<List<TaxCalculation>> calculateTaxesForPayments({
    required List<Map<String, dynamic>> payments,
  }) async {
    try {
      final calculations = <TaxCalculation>[];

      for (final payment in payments) {
        final calculation = await calculateTax(
          paymentId: payment['paymentId'] as String,
          grossAmount: (payment['amount'] as num).toDouble(),
          taxStatus: TaxStatus.values.firstWhere(
            (e) => e.name == payment['taxStatus'],
            orElse: () => TaxStatus.none,
          ),
        );
        calculations.add(calculation);
      }

      return calculations;
    } catch (e) {
      debugPrint('Error calculating taxes for payments: $e');
      throw Exception('Ошибка расчета налогов для платежей: $e');
    }
  }

  /// Получить статистику по налогам
  Future<Map<String, dynamic>> getTaxStatistics({
    required List<TaxCalculation> calculations,
  }) async {
    try {
      double totalGrossAmount = 0;
      double totalTaxAmount = 0;
      double totalNetAmount = 0;

      final taxStatusCounts = <TaxStatus, int>{};

      for (final calculation in calculations) {
        totalGrossAmount += calculation.grossAmount;
        totalTaxAmount += calculation.taxAmount;
        totalNetAmount += calculation.netAmount;

        taxStatusCounts[calculation.taxStatus] =
            (taxStatusCounts[calculation.taxStatus] ?? 0) + 1;
      }

      return {
        'totalGrossAmount': totalGrossAmount,
        'totalTaxAmount': totalTaxAmount,
        'totalNetAmount': totalNetAmount,
        'averageTaxRate': totalGrossAmount > 0
            ? (totalTaxAmount / totalGrossAmount) * 100
            : 0,
        'taxStatusCounts': taxStatusCounts.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'calculationsCount': calculations.length,
      };
    } catch (e) {
      debugPrint('Error getting tax statistics: $e');
      throw Exception('Ошибка получения статистики по налогам: $e');
    }
  }
}
