import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.type, this.isActive = true});
  final PremiumType type;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            _getBadgeText(),
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getBadgeText() {
    switch (type) {
      case PremiumType.topBanner:
        return 'В ТОПЕ';
      case PremiumType.highlight:
        return 'ПРЕМИУМ';
      case PremiumType.prioritySearch:
        return 'ПРИОРИТЕТ';
    }
  }
}

enum PremiumType { topBanner, highlight, prioritySearch }
