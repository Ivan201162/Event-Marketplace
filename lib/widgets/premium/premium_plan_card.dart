import 'package:flutter/material.dart';

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });
  final String plan;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.purple : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.purple.withOpacity(0.05) : Colors.white,
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? Colors.purple : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Plan info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPlanTitle(plan),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.purple : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlanDescription(plan),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${price.toInt()} ₽',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : Colors.black,
                    ),
                  ),
                  Text(
                    _getPricePerDay(plan, price),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  String _getPlanTitle(String plan) {
    switch (plan) {
      case '7_days':
        return 'Неделя';
      case '14_days':
        return '2 недели';
      case '30_days':
        return 'Месяц';
      default:
        return 'Неизвестный план';
    }
  }

  String _getPlanDescription(String plan) {
    switch (plan) {
      case '7_days':
        return '7 дней премиум-размещения';
      case '14_days':
        return '14 дней премиум-размещения';
      case '30_days':
        return '30 дней премиум-размещения';
      default:
        return '';
    }
  }

  String _getPricePerDay(String plan, double price) {
    int days;
    switch (plan) {
      case '7_days':
        days = 7;
        break;
      case '14_days':
        days = 14;
        break;
      case '30_days':
        days = 30;
        break;
      default:
        days = 1;
    }

    final pricePerDay = (price / days).round();
    return '$pricePerDay ₽/день';
  }
}
