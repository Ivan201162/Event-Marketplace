import 'package:flutter/material.dart';

import '../models/payment.dart';

class PaymentSummaryWidget extends StatelessWidget {
  final double totalAmount;
  final double prepaymentAmount;
  final double taxAmount;
  final double taxRate;
  final TaxType taxType;
  final PaymentType paymentType;
  final OrganizationType organizationType;

  const PaymentSummaryWidget({
    Key? key,
    required this.totalAmount,
    required this.prepaymentAmount,
    required this.taxAmount,
    required this.taxRate,
    required this.taxType,
    required this.paymentType,
    required this.organizationType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сводка по платежу',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Общая сумма
            _buildSummaryRow(
              context,
              'Общая стоимость услуг',
              '${totalAmount.toStringAsFixed(2)} ₽',
              isTotal: true,
            ),
            
            // Аванс
            if (prepaymentAmount > 0)
              _buildSummaryRow(
                context,
                'Аванс (${(prepaymentAmount / totalAmount * 100).toStringAsFixed(0)}%)',
                '${prepaymentAmount.toStringAsFixed(2)} ₽',
              ),
            
            // Налог
            if (taxAmount > 0)
              _buildSummaryRow(
                context,
                '${TaxCalculator.getTaxName(taxType)} (${taxRate.toStringAsFixed(1)}%)',
                '${taxAmount.toStringAsFixed(2)} ₽',
                isTax: true,
              ),
            
            const Divider(),
            
            // Сумма к оплате
            _buildSummaryRow(
              context,
              _getPaymentTypeDescription(),
              '${_getPaymentAmount().toStringAsFixed(2)} ₽',
              isPayment: true,
            ),
            
            const SizedBox(height: 8),
            
            // Информация о типе организации
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getOrganizationTypeDescription(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isTax = false,
    bool isPayment = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isTax ? Colors.red.shade600 : null,
              fontWeight: isTotal || isPayment ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isTax ? Colors.red.shade600 : null,
              fontWeight: isTotal || isPayment ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  double _getPaymentAmount() {
    switch (paymentType) {
      case PaymentType.advance:
        return prepaymentAmount;
      case PaymentType.finalPayment:
        return totalAmount - prepaymentAmount;
      case PaymentType.fullPayment:
        return totalAmount;
      case PaymentType.refund:
        return totalAmount;
    }
  }

  String _getPaymentTypeDescription() {
    switch (paymentType) {
      case PaymentType.advance:
        return 'К доплате (аванс)';
      case PaymentType.finalPayment:
        return 'К доплате (остаток)';
      case PaymentType.fullPayment:
        return 'К доплате (полная сумма)';
      case PaymentType.refund:
        return 'К возврату';
    }
  }

  String _getOrganizationTypeDescription() {
    switch (organizationType) {
      case OrganizationType.individual:
        return 'Физическое лицо: аванс 30%, остаток после выполнения';
      case OrganizationType.commercial:
        return 'Коммерческая организация: аванс 30%, НДС 20%';
      case OrganizationType.government:
        return 'Государственное учреждение: постоплата 100%';
      case OrganizationType.nonProfit:
        return 'Некоммерческая организация: аванс 20%, остаток после выполнения';
      case OrganizationType.selfEmployed:
        return 'Самозанятый: налог на профдоход 4%';
      case OrganizationType.entrepreneur:
        return 'ИП: УСН 6%';
    }
  }
}
