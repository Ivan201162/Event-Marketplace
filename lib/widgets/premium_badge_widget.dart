import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';

class PremiumBadgeWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final double size;
  final bool showText;

  const PremiumBadgeWidget({
    super.key,
    required this.tier,
    this.size = 24.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.free) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: _getGradient(tier),
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: _getColor(tier).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(_getIcon(tier), color: Colors.white, size: size * 0.6),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            _getText(tier),
            style: TextStyle(color: _getColor(tier), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ],
    );
  }

  LinearGradient _getGradient(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const LinearGradient(colors: [Colors.grey, Colors.grey]);
      case SubscriptionTier.premium:
        return const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SubscriptionTier.pro:
        return const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.premium:
        return Colors.amber;
      case SubscriptionTier.pro:
        return Colors.deepPurple;
    }
  }

  IconData _getIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person;
      case SubscriptionTier.premium:
        return Icons.star;
      case SubscriptionTier.pro:
        return Icons.diamond;
    }
  }

  String _getText(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Бесплатно';
      case SubscriptionTier.premium:
        return 'Премиум';
      case SubscriptionTier.pro:
        return 'PRO';
    }
  }
}

class PremiumBorderWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final Widget child;
  final double borderWidth;

  const PremiumBorderWidget({
    super.key,
    required this.tier,
    required this.child,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.free) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor(tier), width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: _getColor(tier).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Color _getColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.premium:
        return Colors.amber;
      case SubscriptionTier.pro:
        return Colors.deepPurple;
    }
  }
}

class PremiumCardWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PremiumCardWidget({super.key, required this.tier, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.free) {
      return Card(child: child);
    }

    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getColor(tier).withValues(alpha: 0.1),
              _getColor(tier).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _getColor(tier).withValues(alpha: 0.3)),
        ),
        child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Color _getColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.premium:
        return Colors.amber;
      case SubscriptionTier.pro:
        return Colors.deepPurple;
    }
  }
}

class PremiumTextWidget extends StatelessWidget {
  final SubscriptionTier tier;
  final String text;
  final TextStyle? style;

  const PremiumTextWidget({super.key, required this.tier, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        color: tier == SubscriptionTier.free ? null : _getColor(tier),
        fontWeight: tier == SubscriptionTier.free ? null : FontWeight.bold,
      ),
    );
  }

  Color _getColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.premium:
        return Colors.amber;
      case SubscriptionTier.pro:
        return Colors.deepPurple;
    }
  }
}
