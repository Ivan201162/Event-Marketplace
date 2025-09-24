import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../services/specialist_service.dart';

/// Виджет услуг специалиста
class SpecialistServicesWidget extends ConsumerWidget {
  const SpecialistServicesWidget({
    super.key,
    required this.specialistId,
    this.isOwnProfile = false,
    this.onEditService,
    this.onAddService,
    this.onBookService,
  });

  final String specialistId;
  final bool isOwnProfile;
  final Function(String)? onEditService;
  final VoidCallback? onAddService;
  final Function(String)? onBookService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<Specialist?>(
      future: ref.read(specialistServiceProvider).getSpecialist(specialistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Специалист не найден'),
          );
        }

        final specialist = snapshot.data!;
        final services = specialist.services ?? [];
        
        return Column(
          children: [
            // Заголовок с кнопкой добавления
            if (isOwnProfile)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Мои услуги',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddService,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
              ),
            
            // Список услуг
            if (services.isEmpty)
              _buildEmptyState(context, theme)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceItem(context, theme, service);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isOwnProfile ? 'У вас пока нет услуг' : 'У специалиста пока нет услуг',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isOwnProfile 
                ? 'Добавьте услуги, чтобы клиенты могли их заказать'
                : 'Специалист еще не добавил свои услуги',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddService,
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, ThemeData theme, Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок услуги
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (service.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwnProfile)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleServiceAction(value, service),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Редактировать'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Удалить', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Цена и длительность
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${service.price} ₽',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (service.duration != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${service.duration} мин',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!isOwnProfile)
                  ElevatedButton(
                    onPressed: () => onBookService?.call(service.id),
                    child: const Text('Заказать'),
                  ),
              ],
            ),
            
            // Дополнительная информация
            if (service.features != null && service.features!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: service.features!.map((feature) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      feature,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ).toList(),
              ),
            ],
            
            // Статистика услуги
            if (service.ordersCount != null && service.ordersCount! > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${service.ordersCount} заказов',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  if (service.rating != null) ...[
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.rating!.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleServiceAction(String action, Service service) {
    switch (action) {
      case 'edit':
        onEditService?.call(service.id);
        break;
      case 'delete':
        _deleteService(service);
        break;
    }
  }

  void _deleteService(Service service) {
    // В реальном приложении здесь была бы логика удаления услуги
    // showDialog для подтверждения удаления
  }
}
