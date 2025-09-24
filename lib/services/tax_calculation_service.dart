import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../models/specialist.dart';

/// Сервис для расчета налогов
class TaxCalculationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Рассчитать налоги для платежа
  Future<TaxCalculationResult> calculateTaxes({
    required double amount,
    required String specialistId,
    required OrganizationType customerType,
    String? region,
    DateTime? paymentDate,
  }) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) {
        throw Exception('Специалист не найден');
      }

      final specialistTaxType = await _getSpecialistTaxType(specialistId);
      final isFromLegalEntity = _isLegalEntity(customerType);

      // Рассчитываем налоги
      final taxAmount = TaxCalculator.calculateTax(
        amount,
        specialistTaxType,
        isFromLegalEntity: isFromLegalEntity,
      );

      final taxRate = TaxCalculator.getTaxRate(
        specialistTaxType,
        isFromLegalEntity: isFromLegalEntity,
      );

      final netAmount = amount - taxAmount;

      // Рассчитываем дополнительные налоги и взносы
      final additionalTaxes = await _calculateAdditionalTaxes(
        amount,
        specialistTaxType,
        specialist,
        region,
      );

      return TaxCalculationResult(
        grossAmount: amount,
        taxAmount: taxAmount,
        netAmount: netAmount,
        taxRate: taxRate,
        taxType: specialistTaxType,
        additionalTaxes: additionalTaxes,
        isFromLegalEntity: isFromLegalEntity,
        region: region,
        calculationDate: paymentDate ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка расчета налогов: $e');
      throw Exception('Не удалось рассчитать налоги: $e');
    }
  }

  /// Рассчитать налоги для двухэтапного платежа
  Future<TwoStageTaxCalculationResult> calculateTwoStageTaxes({
    required double totalAmount,
    required double advanceAmount,
    required String specialistId,
    required OrganizationType customerType,
    String? region,
    DateTime? paymentDate,
  }) async {
    try {
      // Рассчитываем налоги для аванса
      final advanceTaxes = await calculateTaxes(
        amount: advanceAmount,
        specialistId: specialistId,
        customerType: customerType,
        region: region,
        paymentDate: paymentDate,
      );

      // Рассчитываем налоги для финального платежа
      final finalAmount = totalAmount - advanceAmount;
      final finalTaxes = await calculateTaxes(
        amount: finalAmount,
        specialistId: specialistId,
        customerType: customerType,
        region: region,
        paymentDate: paymentDate,
      );

      return TwoStageTaxCalculationResult(
        totalAmount: totalAmount,
        advanceAmount: advanceAmount,
        finalAmount: finalAmount,
        advanceTaxes: advanceTaxes,
        finalTaxes: finalTaxes,
        totalTaxAmount: advanceTaxes.taxAmount + finalTaxes.taxAmount,
        totalNetAmount: advanceTaxes.netAmount + finalTaxes.netAmount,
      );
    } catch (e) {
      debugPrint('Ошибка расчета налогов для двухэтапного платежа: $e');
      throw Exception('Не удалось рассчитать налоги: $e');
    }
  }

  /// Получить налоговую декларацию для специалиста
  Future<TaxDeclaration> generateTaxDeclaration({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final payments = await _getPaymentsInPeriod(specialistId, startDate, endDate);
      
      double totalIncome = 0;
      double totalTaxes = 0;
      final paymentDetails = <PaymentTaxDetail>[];

      for (final payment in payments) {
        final taxCalculation = await calculateTaxes(
          amount: payment.amount,
          specialistId: specialistId,
          customerType: payment.organizationType,
          paymentDate: payment.createdAt,
        );

        totalIncome += payment.amount;
        totalTaxes += taxCalculation.taxAmount;

        paymentDetails.add(PaymentTaxDetail(
          payment: payment,
          taxCalculation: taxCalculation,
        ));
      }

      return TaxDeclaration(
        specialistId: specialistId,
        period: TaxPeriod(startDate: startDate, endDate: endDate),
        totalIncome: totalIncome,
        totalTaxes: totalTaxes,
        netIncome: totalIncome - totalTaxes,
        paymentDetails: paymentDetails,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка генерации налоговой декларации: $e');
      throw Exception('Не удалось сгенерировать налоговую декларацию: $e');
    }
  }

  /// Обновить налоговый тип специалиста
  Future<void> updateSpecialistTaxType({
    required String specialistId,
    required TaxType taxType,
    Map<String, dynamic>? taxDetails,
  }) async {
    try {
      await _db.collection('specialists').doc(specialistId).update({
        'taxType': taxType.name,
        'taxDetails': taxDetails ?? {},
        'taxUpdatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка обновления налогового типа специалиста: $e');
      throw Exception('Не удалось обновить налоговый тип: $e');
    }
  }

  /// Получить рекомендации по оптимизации налогов
  Future<TaxOptimizationRecommendations> getTaxOptimizationRecommendations({
    required String specialistId,
    required double monthlyIncome,
  }) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) {
        throw Exception('Специалист не найден');
      }

      final currentTaxType = await _getSpecialistTaxType(specialistId);
      final recommendations = <TaxOptimizationRecommendation>[];

      // Рассчитываем налоги для разных типов
      final currentTaxes = TaxCalculator.calculateTax(monthlyIncome, currentTaxType);
      
      // Рекомендации для самозанятых
      if (currentTaxType != TaxType.professionalIncome) {
        final selfEmployedTaxes = TaxCalculator.calculateTax(monthlyIncome, TaxType.professionalIncome);
        if (selfEmployedTaxes < currentTaxes) {
          recommendations.add(TaxOptimizationRecommendation(
            type: TaxOptimizationType.switchToSelfEmployed,
            title: 'Переход на самозанятость',
            description: 'При доходе ${monthlyIncome.toInt()} ₽/месяц самозанятость сэкономит ${(currentTaxes - selfEmployedTaxes).toInt()} ₽/месяц',
            potentialSavings: currentTaxes - selfEmployedTaxes,
            complexity: TaxOptimizationComplexity.low,
          ));
        }
      }

      // Рекомендации для ИП
      if (currentTaxType != TaxType.simplifiedTax) {
        final ipTaxes = TaxCalculator.calculateTax(monthlyIncome, TaxType.simplifiedTax);
        if (ipTaxes < currentTaxes) {
          recommendations.add(TaxOptimizationRecommendation(
            type: TaxOptimizationType.switchToIP,
            title: 'Открытие ИП',
            description: 'При доходе ${monthlyIncome.toInt()} ₽/месяц ИП с УСН сэкономит ${(currentTaxes - ipTaxes).toInt()} ₽/месяц',
            potentialSavings: currentTaxes - ipTaxes,
            complexity: TaxOptimizationComplexity.medium,
          ));
        }
      }

      // Рекомендации по расходам
      if (currentTaxType == TaxType.simplifiedTax) {
        recommendations.add(TaxOptimizationRecommendation(
          type: TaxOptimizationType.expenseOptimization,
          title: 'Оптимизация расходов',
          description: 'Учитывайте расходы на оборудование, рекламу и обучение для снижения налоговой базы',
          potentialSavings: monthlyIncome * 0.1, // Примерная экономия
          complexity: TaxOptimizationComplexity.low,
        ));
      }

      return TaxOptimizationRecommendations(
        specialistId: specialistId,
        currentTaxType: currentTaxType,
        monthlyIncome: monthlyIncome,
        currentMonthlyTaxes: currentTaxes,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций по оптимизации налогов: $e');
      throw Exception('Не удалось получить рекомендации: $e');
    }
  }

  /// Получить специалиста
  Future<Specialist?> _getSpecialist(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Получить налоговый тип специалиста
  Future<TaxType> _getSpecialistTaxType(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        final data = doc.data()! as Map<String, dynamic>;
        final taxTypeString = data['taxType'] as String?;
        if (taxTypeString != null) {
          return TaxType.values.firstWhere(
            (e) => e.name == taxTypeString,
            orElse: () => TaxType.none,
          );
        }
      }
      return TaxType.none;
    } catch (e) {
      debugPrint('Ошибка получения налогового типа специалиста: $e');
      return TaxType.none;
    }
  }

  /// Проверить, является ли организация юридическим лицом
  bool _isLegalEntity(OrganizationType type) {
    return type == OrganizationType.commercial || 
           type == OrganizationType.government || 
           type == OrganizationType.nonProfit;
  }

  /// Рассчитать дополнительные налоги и взносы
  Future<List<AdditionalTax>> _calculateAdditionalTaxes(
    double amount,
    TaxType taxType,
    Specialist specialist,
    String? region,
  ) async {
    final additionalTaxes = <AdditionalTax>[];

    // Взносы в ПФР и ФОМС для ИП
    if (taxType == TaxType.simplifiedTax) {
      // Минимальные взносы ИП (примерные значения на 2024 год)
      const minPensionContribution = 36500.0; // Минимальный взнос в ПФР
      const minHealthContribution = 8760.0;   // Минимальный взнос в ФОМС
      
      additionalTaxes.add(AdditionalTax(
        name: 'Взнос в ПФР',
        amount: minPensionContribution / 12, // Ежемесячно
        rate: 0,
        type: AdditionalTaxType.pensionContribution,
      ));
      
      additionalTaxes.add(AdditionalTax(
        name: 'Взнос в ФОМС',
        amount: minHealthContribution / 12, // Ежемесячно
        rate: 0,
        type: AdditionalTaxType.healthContribution,
      ));
    }

    // Региональные налоги (если применимо)
    if (region != null && _hasRegionalTaxes(region)) {
      final regionalTax = _calculateRegionalTax(amount, region);
      if (regionalTax > 0) {
        additionalTaxes.add(AdditionalTax(
          name: 'Региональный налог',
          amount: regionalTax,
          rate: 0,
          type: AdditionalTaxType.regionalTax,
        ));
      }
    }

    return additionalTaxes;
  }

  /// Проверить, есть ли региональные налоги
  bool _hasRegionalTaxes(String region) {
    // Примерные регионы с дополнительными налогами
    const regionsWithTaxes = ['Москва', 'Санкт-Петербург', 'Московская область'];
    return regionsWithTaxes.contains(region);
  }

  /// Рассчитать региональный налог
  double _calculateRegionalTax(double amount, String region) {
    // Примерные ставки региональных налогов
    switch (region) {
      case 'Москва':
        return amount * 0.01; // 1%
      case 'Санкт-Петербург':
        return amount * 0.005; // 0.5%
      default:
        return 0;
    }
  }

  /// Получить платежи за период
  Future<List<Payment>> _getPaymentsInPeriod(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _db
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: PaymentStatus.completed.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return query.docs.map((doc) => Payment.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Ошибка получения платежей за период: $e');
      return [];
    }
  }
}

/// Результат расчета налогов
class TaxCalculationResult {
  const TaxCalculationResult({
    required this.grossAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.taxRate,
    required this.taxType,
    required this.additionalTaxes,
    required this.isFromLegalEntity,
    this.region,
    required this.calculationDate,
  });

  final double grossAmount;
  final double taxAmount;
  final double netAmount;
  final double taxRate;
  final TaxType taxType;
  final List<AdditionalTax> additionalTaxes;
  final bool isFromLegalEntity;
  final String? region;
  final DateTime calculationDate;

  /// Общая сумма дополнительных налогов
  double get totalAdditionalTaxes => additionalTaxes.fold<double>(0, (sum, tax) => sum + tax.amount);

  /// Итоговая сумма к получению
  double get finalNetAmount => netAmount - totalAdditionalTaxes;
}

/// Результат расчета налогов для двухэтапного платежа
class TwoStageTaxCalculationResult {
  const TwoStageTaxCalculationResult({
    required this.totalAmount,
    required this.advanceAmount,
    required this.finalAmount,
    required this.advanceTaxes,
    required this.finalTaxes,
    required this.totalTaxAmount,
    required this.totalNetAmount,
  });

  final double totalAmount;
  final double advanceAmount;
  final double finalAmount;
  final TaxCalculationResult advanceTaxes;
  final TaxCalculationResult finalTaxes;
  final double totalTaxAmount;
  final double totalNetAmount;
}

/// Дополнительный налог
class AdditionalTax {
  const AdditionalTax({
    required this.name,
    required this.amount,
    required this.rate,
    required this.type,
  });

  final String name;
  final double amount;
  final double rate;
  final AdditionalTaxType type;
}

/// Типы дополнительных налогов
enum AdditionalTaxType {
  pensionContribution,  // Взнос в ПФР
  healthContribution,   // Взнос в ФОМС
  regionalTax,          // Региональный налог
  other,                // Прочие
}

/// Налоговая декларация
class TaxDeclaration {
  const TaxDeclaration({
    required this.specialistId,
    required this.period,
    required this.totalIncome,
    required this.totalTaxes,
    required this.netIncome,
    required this.paymentDetails,
    required this.generatedAt,
  });

  final String specialistId;
  final TaxPeriod period;
  final double totalIncome;
  final double totalTaxes;
  final double netIncome;
  final List<PaymentTaxDetail> paymentDetails;
  final DateTime generatedAt;
}

/// Налоговый период
class TaxPeriod {
  const TaxPeriod({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

/// Детали платежа с налогами
class PaymentTaxDetail {
  const PaymentTaxDetail({
    required this.payment,
    required this.taxCalculation,
  });

  final Payment payment;
  final TaxCalculationResult taxCalculation;
}

/// Рекомендации по оптимизации налогов
class TaxOptimizationRecommendations {
  const TaxOptimizationRecommendations({
    required this.specialistId,
    required this.currentTaxType,
    required this.monthlyIncome,
    required this.currentMonthlyTaxes,
    required this.recommendations,
    required this.generatedAt,
  });

  final String specialistId;
  final TaxType currentTaxType;
  final double monthlyIncome;
  final double currentMonthlyTaxes;
  final List<TaxOptimizationRecommendation> recommendations;
  final DateTime generatedAt;
}

/// Рекомендация по оптимизации налогов
class TaxOptimizationRecommendation {
  const TaxOptimizationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.complexity,
  });

  final TaxOptimizationType type;
  final String title;
  final String description;
  final double potentialSavings;
  final TaxOptimizationComplexity complexity;
}

/// Типы оптимизации налогов
enum TaxOptimizationType {
  switchToSelfEmployed,    // Переход на самозанятость
  switchToIP,              // Открытие ИП
  expenseOptimization,     // Оптимизация расходов
  incomeSplitting,         // Разделение доходов
  other,                   // Прочее
}

/// Сложность оптимизации
enum TaxOptimizationComplexity {
  low,     // Низкая
  medium,  // Средняя
  high,    // Высокая
}
