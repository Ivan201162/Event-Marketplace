import 'package:flutter/material.dart';

class PromotedPostBadge extends StatelessWidget {
  final bool isPromoted;

  const PromotedPostBadge({
    Key? key,
    required this.isPromoted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isPromoted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          const Text(
            'РЕКЛАМА',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
