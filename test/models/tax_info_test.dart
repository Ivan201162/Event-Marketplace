import 'package:event_marketplace_app/models/tax_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxType', () {
    test('should have correct display names', () {
      expect(TaxType.individual.displayName, 'Физическое лицо');
      expect(TaxType.selfEmployed.displayName, 'Самозанятый');
      expect(
        TaxType.individualEntrepreneur.displayName,
        'Индивидуальный предприниматель',
      );
      expect(TaxType.government.displayName, 'Государственное учреждение');
    });

    test('should have correct descriptions', () {
      expect(
        TaxType.individual.description,
        'Налог должен быть уплачен самостоятельно (13% НДФЛ)',
      );
      expect(
        TaxType.selfEmployed.description,
        'Налог на профессиональный доход (4-6%)',
      );
      expect(
        TaxType.individualEntrepreneur.description,
        'Упрощённая система налогообложения (6% или 15%)',
      );
      expect(TaxType.government.description, 'Освобождено от налогообложения');
    });

    test('should have correct icons', () {
      expect(TaxType.individual.icon, '👤');
      expect(TaxType.selfEmployed.icon, '💼');
      expect(TaxType.individualEntrepreneur.icon, '🏢');
      expect(TaxType.government.icon, '🏛️');
    });

    test('should have correct default tax rates', () {
      expect(TaxType.individual.defaultTaxRate, 0.13);
      expect(TaxType.selfEmployed.defaultTaxRate, 0.04);
      expect(TaxType.individualEntrepreneur.defaultTaxRate, 0.06);
      expect(TaxType.government.defaultTaxRate, 0.0);
    });
  });

  group('TaxInfo', () {
    late TaxInfo taxInfo;

    setUp(() {
      taxInfo = TaxInfo(
        id: 'test-id',
        userId: 'user-id',
        specialistId: 'specialist-id',
        taxType: TaxType.selfEmployed,
        taxRate: 0.04,
        income: 100000,
        taxAmount: 4000,
        period: '2024-01',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    });

    test('should create TaxInfo with correct values', () {
      expect(taxInfo.id, 'test-id');
      expect(taxInfo.userId, 'user-id');
      expect(taxInfo.specialistId, 'specialist-id');
      expect(taxInfo.taxType, TaxType.selfEmployed);
      expect(taxInfo.taxRate, 0.04);
      expect(taxInfo.income, 100000.0);
      expect(taxInfo.taxAmount, 4000.0);
      expect(taxInfo.period, '2024-01');
    });

    test('should format income correctly', () {
      expect(taxInfo.formattedIncome, '100000 ₽');
    });

    test('should format tax amount correctly', () {
      expect(taxInfo.formattedTaxAmount, '4000 ₽');
    });

    test('should format tax rate correctly', () {
      expect(taxInfo.formattedTaxRate, '4.0%');
    });

    test('should return correct payment status', () {
      expect(taxInfo.paymentStatus, 'Не оплачено');

      final paidTaxInfo = taxInfo.copyWith(isPaid: true);
      expect(paidTaxInfo.paymentStatus, 'Оплачено');
    });

    test('should detect overdue taxes correctly', () {
      final oldTaxInfo = taxInfo.copyWith(
        createdAt: DateTime(2023),
        period: '2023-01',
      );
      expect(oldTaxInfo.isOverdue, true);

      final recentTaxInfo = taxInfo.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        period: '2024-12',
      );
      expect(recentTaxInfo.isOverdue, false);
    });

    test('should calculate next reminder date correctly', () {
      final nextReminder = taxInfo.nextReminder;
      final expectedDate = taxInfo.createdAt.add(const Duration(days: 7));
      expect(nextReminder, expectedDate);
    });

    test('should convert to map correctly', () {
      final map = taxInfo.toMap();
      expect(map['userId'], 'user-id');
      expect(map['specialistId'], 'specialist-id');
      expect(map['taxType'], 'selfEmployed');
      expect(map['taxRate'], 0.04);
      expect(map['income'], 100000.0);
      expect(map['taxAmount'], 4000.0);
      expect(map['period'], '2024-01');
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'test-id',
        'userId': 'user-id',
        'specialistId': 'specialist-id',
        'taxType': 'selfEmployed',
        'taxRate': 0.04,
        'income': 100000.0,
        'taxAmount': 4000.0,
        'period': '2024-01',
        'createdAt': DateTime(2024),
        'updatedAt': DateTime(2024),
      };

      final createdTaxInfo = TaxInfo.fromMap(map);
      expect(createdTaxInfo.id, 'test-id');
      expect(createdTaxInfo.userId, 'user-id');
      expect(createdTaxInfo.specialistId, 'specialist-id');
      expect(createdTaxInfo.taxType, TaxType.selfEmployed);
      expect(createdTaxInfo.taxRate, 0.04);
      expect(createdTaxInfo.income, 100000.0);
      expect(createdTaxInfo.taxAmount, 4000.0);
      expect(createdTaxInfo.period, '2024-01');
    });
  });

  group('TaxSummary', () {
    late TaxSummary taxSummary;

    setUp(() {
      final taxRecords = [
        TaxInfo(
          id: '1',
          userId: 'user-id',
          specialistId: 'specialist-id',
          taxType: TaxType.selfEmployed,
          taxRate: 0.04,
          income: 50000,
          taxAmount: 2000,
          period: '2024-01',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          isPaid: true,
        ),
        TaxInfo(
          id: '2',
          userId: 'user-id',
          specialistId: 'specialist-id',
          taxType: TaxType.selfEmployed,
          taxRate: 0.04,
          income: 30000,
          taxAmount: 1200,
          period: '2024-01',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      taxSummary = TaxSummary(
        period: '2024-01',
        totalIncome: 80000,
        totalTaxAmount: 3200,
        taxRecords: taxRecords,
        paidAmount: 2000,
        unpaidAmount: 1200,
        overdueAmount: 0,
      );
    });

    test('should create TaxSummary with correct values', () {
      expect(taxSummary.period, '2024-01');
      expect(taxSummary.totalIncome, 80000.0);
      expect(taxSummary.totalTaxAmount, 3200.0);
      expect(taxSummary.paidAmount, 2000.0);
      expect(taxSummary.unpaidAmount, 1200.0);
      expect(taxSummary.overdueAmount, 0.0);
    });

    test('should format amounts correctly', () {
      expect(taxSummary.formattedTotalIncome, '80000 ₽');
      expect(taxSummary.formattedTotalTaxAmount, '3200 ₽');
      expect(taxSummary.formattedPaidAmount, '2000 ₽');
      expect(taxSummary.formattedUnpaidAmount, '1200 ₽');
      expect(taxSummary.formattedOverdueAmount, '0 ₽');
    });

    test('should calculate payment percentage correctly', () {
      expect(taxSummary.paymentPercentage, 62.5);
      expect(taxSummary.formattedPaymentPercentage, '62.5%');
    });
  });
}
