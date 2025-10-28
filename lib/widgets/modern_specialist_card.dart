import 'package:event_marketplace_app/models/specialist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Современная карточка специалиста в едином стиле
class ModernSpecialistCard extends ConsumerWidget {
  const ModernSpecialistCard({
    required this.specialist, super.key,
    this.onTap,
    this.showFavoriteButton = true,
    this.showQuickActions = true,
    this.isCompact = false,
  });

  final Specialist specialist;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool showQuickActions;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap ?? () => _navigateToProfile(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с аватаром и основной информацией
                Row(
                  children: [
                    _buildAvatar(context),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSpecialistInfo(context)),
                    if (showFavoriteButton) _buildFavoriteButton(),
                  ],
                ),

                if (!isCompact) ...[
                  const SizedBox(height: 16),
                  _buildDescription(context),
                  const SizedBox(height: 16),
                  _buildStatsAndActions(context),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildAvatar(BuildContext context) => Stack(
        children: [
          CircleAvatar(
            radius: isCompact ? 25 : 32,
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            backgroundImage: specialist.imageUrlValue != null
                ? NetworkImage(specialist.imageUrlValue!)
                : null,
            child: specialist.imageUrlValue == null
                ? Text(
                    specialist.name.isNotEmpty
                        ? specialist.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : null,
          ),
          if (specialist.isVerified)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.verified, size: 12, color: Colors.white),
              ),
            ),
        ],
      );

  Widget _buildSpecialistInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  specialist.name,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            specialist.category?.name ?? 'Категория',
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  specialist.city,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildFavoriteButton() => IconButton(
        icon: const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
        onPressed: () {
          // TODO: Реализовать добавление в избранное
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );

  Widget _buildDescription(BuildContext context) => Text(
        (specialist.description?.isNotEmpty ?? false)
            ? specialist.description!
            : 'Опытный специалист в области ${specialist.category?.name.toLowerCase() ?? 'услуг'}',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildStatsAndActions(BuildContext context) => Row(
        children: [
          // Рейтинг
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  specialist.rating.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Количество отзывов
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${specialist.reviewCount} отзывов',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          const Spacer(),

          // Цена
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(specialist.pricePerHour ?? specialist.hourlyRate ?? 0).toInt()}₽/ч',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      );

  void _navigateToProfile(BuildContext context) {
    context.push('/specialist/${specialist.id}');
  }
}

/// Компактная версия карточки для списков
class CompactSpecialistCard extends StatelessWidget {
  const CompactSpecialistCard(
      {required this.specialist, super.key, this.onTap,});

  final Specialist specialist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ModernSpecialistCard(
        specialist: specialist,
        onTap: onTap,
        isCompact: true,
        showFavoriteButton: false,
        showQuickActions: false,
      );
}
