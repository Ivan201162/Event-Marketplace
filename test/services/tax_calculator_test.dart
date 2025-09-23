import 'package:event_marketplace_app/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxCalculator Tests', () {
    group('Professional Income Tax', () {
      test('should calculate 4% tax for individuals', () {
        const amount = 10000.0;
        final tax = TaxCalculator.calculateProfessionalIncomeTax(amount);
        expect(tax, equals(400)); // 4% of 10000
      });

      test('should calculate 6% tax for legal entities', () {
        final amount = 10000.0;
        final tax = TaxCalculator.calculateTax(
          amount,
          TaxType.professionalIncome,
          isFromLegalEntity: true,
        );
        expect(tax, equals(600.0)); // 6% of 10000
      });

      test('should return 0 for zero amount', () {
        final amount = 0.0;
        final tax = TaxCalculator.calculateProfessionalIncomeTax(amount);
        expect(tax, equals(0.0));
      });
    });

    group('Simplified Tax (USN)', () {
      test('should calculate 6% simplified tax', () {
        final amount = 10000.0;
        final tax = TaxCalculator.calculateSimplifiedTax(amount);
        expect(tax, equals(600.0)); // 6% of 10000
      });

      test('should handle decimal amounts correctly', () {
        const amount = 12345.67;
        final tax = TaxCalculator.calculateSimplifiedTax(amount);
        expect(tax, closeTo(740.74, 0.01)); // 6% of 12345.67, with tolerance
      });
    });

    group('VAT', () {
      test('should calculate 20% VAT', () {
        final amount = 10000.0;
        final tax = TaxCalculator.calculateVAT(amount);
        expect(tax, equals(2000.0)); // 20% of 10000
      });

      test('should handle large amounts', () {
        final amount = 1000000.0;
        final tax = TaxCalculator.calculateVAT(amount);
        expect(tax, equals(200000.0)); // 20% of 1000000
      });
    });

    group('Tax Type Calculation', () {
      test('should return 0 for none tax type', () {
        final amount = 10000.0;
        final tax = TaxCalculator.calculateTax(amount, TaxType.none);
        expect(tax, equals(0.0));
      });

      test('should calculate correct tax for each type', () {
        final amount = 10000.0;
        
        final professionalTax = TaxCalculator.calculateTax(amount, TaxType.professionalIncome);
        expect(professionalTax, equals(400.0));
        
        final simplifiedTax = TaxCalculator.calculateTax(amount, TaxType.simplifiedTax);
        expect(simplifiedTax, equals(600.0));
        
        final vatTax = TaxCalculator.calculateTax(amount, TaxType.vat);
        expect(vatTax, equals(2000.0));
      });
    });

    group('Tax Rate', () {
      test('should return correct tax rates', () {
        expect(TaxCalculator.getTaxRate(TaxType.none), equals(0.0));
        expect(TaxCalculator.getTaxRate(TaxType.professionalIncome), equals(4.0));
        expect(TaxCalculator.getTaxRate(TaxType.professionalIncome, isFromLegalEntity: true), equals(6.0));
        expect(TaxCalculator.getTaxRate(TaxType.simplifiedTax), equals(6.0));
        expect(TaxCalculator.getTaxRate(TaxType.vat), equals(20.0));
      });
    });

    group('Tax Names', () {
      test('should return correct tax names', () {
        expect(TaxCalculator.getTaxName(TaxType.none), equals('Без налога'));
        expect(TaxCalculator.getTaxName(TaxType.professionalIncome), equals('Налог на профессиональный доход'));
        expect(TaxCalculator.getTaxName(TaxType.simplifiedTax), equals('УСН (6%)'));
        expect(TaxCalculator.getTaxName(TaxType.vat), equals('НДС (20%)'));
      });
    });

    group('Edge Cases', () {
      test('should handle very small amounts', () {
        const amount = 0.01;
        final tax = TaxCalculator.calculateTax(amount, TaxType.professionalIncome);
        expect(tax, closeTo(0.0, 0.001)); // Should be very close to 0
      });

      test('should handle negative amounts', () {
        final amount = -1000.0;
        final tax = TaxCalculator.calculateTax(amount, TaxType.professionalIncome);
        expect(tax, equals(-40.0)); // 4% of -1000
      });

      test('should handle very large amounts', () {
        const amount = 999999999.99;
        final tax = TaxCalculator.calculateTax(amount, TaxType.vat);
        expect(tax, closeTo(199999999.998, 0.01)); // 20% of 999999999.99
      });
    });

    group('Integration Tests', () {
      test('should calculate complete payment breakdown for self-employed', () {
        final totalAmount = 10000.0;
        final taxAmount = TaxCalculator.calculateTax(totalAmount, TaxType.professionalIncome);
        final netAmount = totalAmount - taxAmount;
        
        expect(taxAmount, equals(400.0));
        expect(netAmount, equals(9600.0));
      });

      test('should calculate complete payment breakdown for entrepreneur', () {
        final totalAmount = 10000.0;
        final taxAmount = TaxCalculator.calculateTax(totalAmount, TaxType.simplifiedTax);
        final netAmount = totalAmount - taxAmount;
        
        expect(taxAmount, equals(600.0));
        expect(netAmount, equals(9400.0));
      });

      test('should calculate complete payment breakdown for commercial organization', () {
        final totalAmount = 10000.0;
        final taxAmount = TaxCalculator.calculateTax(totalAmount, TaxType.vat);
        final netAmount = totalAmount - taxAmount;
        
        expect(taxAmount, equals(2000.0));
        expect(netAmount, equals(8000.0));
      });
    });
  });
}
