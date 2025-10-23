import 'package:flutter/material.dart';

class DonationAmountCard extends StatelessWidget {
  const DonationAmountCard({
    super.key,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.pink : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color:
                isSelected ? Colors.pink.withValues(alpha: 0.1) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite,
                  color: isSelected ? Colors.pink : Colors.grey[600], size: 24),
              const SizedBox(height: 8),
              Text(
                '${amount.toInt()} ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.pink : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
}
