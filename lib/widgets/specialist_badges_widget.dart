import 'package:flutter/material.dart';

/// Виджет для отображения бейджей специалистов
class SpecialistBadgesWidget extends StatelessWidget {
  const SpecialistBadgesWidget({
    super.key,
    required this.badges,
    this.size = 20.0,
    this.showText = true,
  });
  final List<SpecialistBadge> badges;
  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges.map(_buildBadge).toList(),
    );
  }

  Widget _buildBadge(SpecialistBadge badge) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: showText ? 8.0 : 4.0,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: badge.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.borderColor ?? badge.color,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.icon,
              size: size,
              color: badge.textColor,
            ),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                badge.text,
                style: TextStyle(
                  color: badge.textColor,
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
}

/// Модель бейджа специалиста
class SpecialistBadge {
  const SpecialistBadge({
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    this.borderColor,
  });
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  /// Топ специалист
  static const SpecialistBadge topSpecialist = SpecialistBadge(
    text: 'ТОП',
    icon: Icons.star,
    color: Color(0xFFFFD700),
    textColor: Color(0xFF8B4513),
    borderColor: Color(0xFFFFA500),
  );

  /// Новичок
  static const SpecialistBadge newcomer = SpecialistBadge(
    text: 'Новичок',
    icon: Icons.new_releases,
    color: Color(0xFF4CAF50),
    textColor: Colors.white,
  );

  /// Проверенный
  static const SpecialistBadge verified = SpecialistBadge(
    text: 'Проверен',
    icon: Icons.verified,
    color: Color(0xFF2196F3),
    textColor: Colors.white,
  );

  /// Быстрый ответ
  static const SpecialistBadge fastResponse = SpecialistBadge(
    text: 'Быстрый ответ',
    icon: Icons.flash_on,
    color: Color(0xFFFF9800),
    textColor: Colors.white,
  );

  /// Популярный
  static const SpecialistBadge popular = SpecialistBadge(
    text: 'Популярный',
    icon: Icons.trending_up,
    color: Color(0xFFE91E63),
    textColor: Colors.white,
  );

  /// Онлайн
  static const SpecialistBadge online = SpecialistBadge(
    text: 'Онлайн',
    icon: Icons.circle,
    color: Color(0xFF4CAF50),
    textColor: Colors.white,
  );

  /// Скидка
  static const SpecialistBadge discount = SpecialistBadge(
    text: 'Скидка',
    icon: Icons.local_offer,
    color: Color(0xFFFF5722),
    textColor: Colors.white,
  );

  /// Премиум
  static const SpecialistBadge premium = SpecialistBadge(
    text: 'Премиум',
    icon: Icons.diamond,
    color: Color(0xFF9C27B0),
    textColor: Colors.white,
  );

  /// Создать бейдж на основе данных специалиста
  static List<SpecialistBadge> fromSpecialistData(Map<String, dynamic> data) {
    final badges = <SpecialistBadge>[];

    // Проверяем рейтинг
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    if (rating >= 4.8) {
      badges.add(topSpecialist);
    }

    // Проверяем количество отзывов
    final reviewsCount = (data['reviewsCount'] as int?) ?? 0;
    if (reviewsCount >= 50) {
      badges.add(popular);
    } else if (reviewsCount < 5) {
      badges.add(newcomer);
    }

    // Проверяем статус верификации
    final isVerified = data['isVerified'] as bool? ?? false;
    if (isVerified) {
      badges.add(verified);
    }

    // Проверяем время ответа
    final avgResponseTime = (data['avgResponseTime'] as int?) ?? 0;
    if (avgResponseTime <= 30) {
      // 30 минут
      badges.add(fastResponse);
    }

    // Проверяем онлайн статус
    final isOnline = data['isOnline'] as bool? ?? false;
    if (isOnline) {
      badges.add(online);
    }

    // Проверяем наличие скидки
    final hasDiscount = data['hasDiscount'] as bool? ?? false;
    if (hasDiscount) {
      badges.add(discount);
    }

    // Проверяем премиум статус
    final isPremium = data['isPremium'] as bool? ?? false;
    if (isPremium) {
      badges.add(premium);
    }

    return badges;
  }
}

