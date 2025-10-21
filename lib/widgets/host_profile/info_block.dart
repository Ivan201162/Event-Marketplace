import 'package:flutter/material.dart';
import '../../models/host_profile.dart';

/// Компонент информационного блока ведущего
class InfoBlock extends StatelessWidget {
  const InfoBlock({super.key, required this.host});
  final HostProfile host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Информация',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 20),

          // Категории мероприятий
          _buildInfoRow(
            context,
            icon: Icons.event,
            title: 'Категории мероприятий',
            content: _buildCategoriesChips(context),
          ),

          const SizedBox(height: 16),

          // Ценовой диапазон
          _buildInfoRow(
            context,
            icon: Icons.attach_money,
            title: 'Ценовой диапазон',
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                host.priceRangeText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // О себе
          _buildInfoRow(
            context,
            icon: Icons.person_outline,
            title: 'О себе',
            content: Text(
              host.about,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.primaryColor, size: isMobile ? 20 : 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesChips(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: host.eventCategories.map((category) {
        // Найти соответствующий enum для эмодзи
        final eventCategory = EventCategory.values.firstWhere(
          (ec) => ec.displayName == category,
          orElse: () => EventCategory.other,
        );

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eventCategory.emoji, style: TextStyle(fontSize: isMobile ? 14 : 16)),
              const SizedBox(width: 4),
              Text(
                category,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
