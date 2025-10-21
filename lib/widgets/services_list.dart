import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';

/// Виджет для отображения прайс-листа специалиста
class ServicesList extends ConsumerWidget {
  const ServicesList({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return profileAsync.when(
      data: (profile) => profile != null
          ? _buildServicesList(context, profile.services)
          : _buildErrorWidget(context, 'Профиль не найден'),
      loading: _buildLoadingList,
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildServicesList(BuildContext context, List<ServicePrice> services) {
    if (services.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO(developer): Обновить прайс-лист
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceItem(context, service);
        },
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, ServicePrice service) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: service.isActive
            ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок услуги
        Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: service.isActive ? null : Colors.grey[600],
                ),
              ),
            ),
            // Статус активности
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: service.isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                service.isActive ? 'Активно' : 'Неактивно',
                style: TextStyle(
                  color: service.isActive ? Colors.green : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Описание услуги
        if (service.description.isNotEmpty)
          Text(
            service.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: service.isActive ? null : Colors.grey[600]),
          ),
        const SizedBox(height: 12),
        // Цена и длительность
        Row(
          children: [
            // Цена
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${service.price.toStringAsFixed(0)} ${service.currency ?? 'RUB'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Длительность
            if (service.duration != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(service.duration!),
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _buildLoadingList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (context, index) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(width: double.infinity, height: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Container(width: 60, height: 20, color: Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 16, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 80, height: 32, color: Colors.white),
                const SizedBox(width: 12),
                Container(width: 100, height: 32, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.attach_money, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Прайс-лист пуст',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Специалист еще не добавил\nсвои услуги и цены',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Ошибка загрузки прайс-листа',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutesм';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hoursч';
      } else {
        return '$hoursч $remainingMinutesм';
      }
    }
  }
}
