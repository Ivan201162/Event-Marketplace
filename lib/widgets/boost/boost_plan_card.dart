import 'package:flutter/material.dart';

class BoostPlanCard extends StatelessWidget {
  const BoostPlanCard({
    super.key,
    required this.days,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });
  final int days;
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
              color: isSelected ? Colors.orange : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.orange.withValues(alpha: 0.05) : Colors.white,
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
                    color: isSelected ? Colors.orange : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? Colors.orange : Colors.transparent,
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
                      _getDaysText(days),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.orange : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDescription(days),
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
                      color: isSelected ? Colors.orange : Colors.black,
                    ),
                  ),
                  Text(
                    '${(price / days).round()} ₽/день',
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

  String _getDaysText(int days) {
    if (days == 1) {
      return '1 день';
    }
    if (days < 5) {
      return '$days дня';
    }
    return '$days дней';
  }

  String _getDescription(int days) {
    switch (days) {
      case 1:
        return 'Быстрое продвижение на 1 день';
      case 3:
        return 'Краткосрочное продвижение';
      case 7:
        return 'Недельное продвижение';
      case 14:
        return 'Двухнедельное продвижение';
      default:
        return 'Продвижение на $days дней';
    }
  }
}
