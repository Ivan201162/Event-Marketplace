import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../components/app_card.dart';
import '../components/outlined_button_x.dart';
import '../components/chip_badge.dart';
import '../../models/specialist_enhanced.dart';
import 'package:go_router/go_router.dart';

/// Карточка специалиста вариант A: большая широкая карточка
class SpecialistCard extends StatelessWidget {
  const SpecialistCard({
    required this.specialist,
    super.key,
  });

  final SpecialistEnhanced specialist;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/profile/${specialist.id}'),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото слева
          CircleAvatar(
            radius: 40,
            backgroundImage: specialist.avatarUrl != null && specialist.avatarUrl!.isNotEmpty
                ? NetworkImage(specialist.avatarUrl!)
                : null,
            child: specialist.avatarUrl == null || specialist.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          // Контент справа
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Имя Фамилия крупно
                Text(
                  specialist.name,
                  style: AppTypography.titleLg.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Город
                if (specialist.city != null && specialist.city!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        specialist.city!,
                        style: AppTypography.bodyMd.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Роли (до 3 бейджей)
                if (specialist.categories.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: specialist.categories.take(3).map((cat) {
                      return ChipBadge(label: cat);
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                // Рейтинг (звёзды + число)
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      specialist.rating.toStringAsFixed(1),
                      style: AppTypography.bodyMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Три кнопки в обводке
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButtonX(
                        text: 'Профиль',
                        onTap: () => context.push('/profile/${specialist.id}'),
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButtonX(
                        text: 'Связаться',
                        onTap: () {
                          // TODO: Открыть чат
                        },
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButtonX(
                        text: 'Заказ',
                        onTap: () {
                          // TODO: Открыть форму заказа
                        },
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
