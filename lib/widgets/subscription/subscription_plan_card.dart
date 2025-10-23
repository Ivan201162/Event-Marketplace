import 'package:flutter/material.dart';
import '../../models/subscription.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.price,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.onTap,
  });
  final SubscriptionPlan plan;
  final double price;
  final bool isSelected;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border:
                Border.all(color: _getBorderColor(), width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            color: _getBackgroundColor(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Plan Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getIconColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(_getPlanIcon(), color: _getIconColor(), size: 24),
                  ),
                  const SizedBox(width: 16),

                  // Plan Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getPlanName(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(),
                              ),
                            ),
                            if (isCurrentPlan) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'АКТИВЕН',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPlanDescription(),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price == 0 ? 'Бесплатно' : '${price.toInt()} ₽/мес',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                      if (price > 0)
                        Text(
                          '${(price / 30).round()} ₽/день',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Features
              ..._getPlanFeatures().map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: _getIconColor(), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Color _getBorderColor() {
    if (isCurrentPlan) {
      return Colors.green;
    }
    if (isSelected) {
      return _getIconColor();
    }
    return Colors.grey[300]!;
  }

  Color _getBackgroundColor() {
    if (isCurrentPlan) {
      return Colors.green.withValues(alpha: 0.05);
    }
    if (isSelected) {
      return _getIconColor().withValues(alpha: 0.05);
    }
    return Colors.white;
  }

  Color _getTextColor() {
    if (isCurrentPlan) {
      return Colors.green;
    }
    if (isSelected) {
      return _getIconColor();
    }
    return Colors.black;
  }

  Color _getIconColor() {
    switch (plan) {
      case SubscriptionPlan.standard:
        return Colors.grey;
      case SubscriptionPlan.pro:
        return Colors.blue;
      case SubscriptionPlan.elite:
        return Colors.purple;
    }
  }

  IconData _getPlanIcon() {
    switch (plan) {
      case SubscriptionPlan.standard:
        return Icons.person;
      case SubscriptionPlan.pro:
        return Icons.star;
      case SubscriptionPlan.elite:
        return Icons.diamond;
    }
  }

  String _getPlanName() {
    switch (plan) {
      case SubscriptionPlan.standard:
        return 'Standard';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.elite:
        return 'Elite';
    }
  }

  String _getPlanDescription() {
    switch (plan) {
      case SubscriptionPlan.standard:
        return 'Базовый функционал для всех пользователей';
      case SubscriptionPlan.pro:
        return 'Расширенные возможности для профессионалов';
      case SubscriptionPlan.elite:
        return 'Максимальный функционал для экспертов';
    }
  }

  List<String> _getPlanFeatures() {
    switch (plan) {
      case SubscriptionPlan.standard:
        return [
          'Базовый поиск специалистов',
          'Просмотр профилей',
          'Отправка заявок',
          'Календарь событий',
        ];
      case SubscriptionPlan.pro:
        return [
          'Все функции Standard',
          'Приоритет в поиске',
          'Расширенная аналитика',
          'Персональные рекомендации',
          'Приоритетная поддержка',
        ];
      case SubscriptionPlan.elite:
        return [
          'Все функции Pro',
          'Персональный менеджер',
          'Эксклюзивные события',
          'Прямые консультации',
          'VIP поддержка 24/7',
          'Специальные предложения',
        ];
    }
  }
}
