import 'package:flutter/material.dart';
import '../../theme/typography.dart';

/// Заголовок секции
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.text,
    this.action,
    super.key,
  });

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTypography.titleLg.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

