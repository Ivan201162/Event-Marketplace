import 'package:flutter/material.dart';
import 'responsive_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/offline_provider.dart';

/// Виджет для отображения статуса офлайн-режима
class OfflineStatusWidget extends ConsumerWidget {
  const OfflineStatusWidget({
    super.key,
    this.showDetails = false,
    this.padding,
    this.onTap,
  });
  final bool showDetails;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineModeProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(offlineState.statusColor).withValues(alpha: 0.1),
          border: Border.all(
            color: Color(offlineState.statusColor),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offlineState.statusIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            ResponsiveText(
              offlineState.connectionStatus,
              style: TextStyle(
                color: Color(offlineState.statusColor),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 16,
                color: Color(offlineState.statusColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения детальной информации об офлайн-режиме
class OfflineDetailsWidget extends ConsumerWidget {
  const OfflineDetailsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineModeProvider);
    final cacheInfo = ref.watch(cacheInfoProvider);
    final syncState = ref.watch(syncProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                offlineState.statusIcon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Статус подключения',
                  isTitle: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.read(offlineModeProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Статус подключения
          _buildStatusRow(
            'Подключение',
            offlineState.connectionStatus,
            Color(offlineState.statusColor),
          ),

          // Время последней синхронизации
          if (syncState.lastSyncTime != null)
            _buildStatusRow(
              'Последняя синхронизация',
              syncState.formattedLastSyncTime,
              Colors.grey[600]!,
            ),

          // Размер кэша
          _buildStatusRow(
            'Размер кэша',
            cacheInfo.formattedCacheSize,
            Colors.grey[600]!,
          ),

          // Количество элементов в кэше
          _buildStatusRow(
            'Элементов в кэше',
            '${cacheInfo.cacheItemsCount}',
            Colors.grey[600]!,
          ),

          // Статус кэша
          if (offlineState.isCacheStale)
            _buildStatusRow(
              'Статус кэша',
              'Требует обновления',
              Colors.orange,
            ),

          const SizedBox(height: 16),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: offlineState.isOfflineMode
                      ? () => ref
                          .read(offlineModeProvider.notifier)
                          .disableOfflineMode()
                      : () => ref
                          .read(offlineModeProvider.notifier)
                          .enableOfflineMode(),
                  icon: Icon(
                    offlineState.isOfflineMode ? Icons.wifi : Icons.wifi_off,
                  ),
                  label: Text(
                    offlineState.isOfflineMode
                        ? 'Включить онлайн'
                        : 'Включить офлайн',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncState.isSyncing
                      ? null
                      : () => ref.read(syncProvider.notifier).startSync(),
                  icon: syncState.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    syncState.isSyncing
                        ? 'Синхронизация...'
                        : 'Синхронизировать',
                  ),
                ),
              ),
            ],
          ),

          // Прогресс синхронизации
          if (syncState.isSyncing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: syncState.syncProgress / 100,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              syncState.currentOperation ?? 'Синхронизация...',
              isSubtitle: true,
            ),
          ],

          // Ошибки
          if (offlineState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      offlineState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              label,
              isSubtitle: true,
            ),
            ResponsiveText(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

/// Виджет для отображения информации о кэше
class CacheInfoWidget extends ConsumerWidget {
  const CacheInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheInfo = ref.watch(cacheInfoProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Информация о кэше',
                  isTitle: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(cacheInfoProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Размер кэша
          _buildInfoRow(
            'Размер кэша',
            cacheInfo.formattedCacheSize,
          ),

          // Количество элементов
          _buildInfoRow(
            'Элементов в кэше',
            '${cacheInfo.cacheItemsCount}',
          ),

          // Версия кэша
          _buildInfoRow(
            'Версия кэша',
            '${cacheInfo.cacheVersion}',
          ),

          const SizedBox(height: 16),

          // Кнопка очистки кэша
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cacheInfo.isLoading
                  ? null
                  : () => _showClearCacheDialog(context, ref),
              icon: cacheInfo.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep),
              label: const Text('Очистить кэш'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Ошибки
          if (cacheInfo.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      cacheInfo.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              label,
              isSubtitle: true,
            ),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш'),
        content: const Text(
          'Вы уверены, что хотите очистить весь кэш? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cacheInfoProvider.notifier).clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения ограничений офлайн-режима
class OfflineLimitationsWidget extends ConsumerWidget {
  const OfflineLimitationsWidget({
    super.key,
    required this.operation,
  });
  final String operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPerform = ref.watch(canPerformOperationProvider(operation));
    final limitationMessage = ref.watch(operationLimitationProvider(operation));

    if (canPerform || limitationMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: ResponsiveText(
              limitationMessage,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения рекомендаций офлайн-режима
class OfflineRecommendationsWidget extends ConsumerWidget {
  const OfflineRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(offlineRecommendationsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline),
              SizedBox(width: 12),
              ResponsiveText(
                'Рекомендации',
                isTitle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      recommendation,
                      isSubtitle: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения статуса синхронизации
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    if (!syncState.isSyncing && syncState.lastSyncTime == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                syncState.isSyncing ? Icons.sync : Icons.sync_alt,
                color: syncState.isSyncing ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveText(
                  syncState.isSyncing
                      ? 'Синхронизация...'
                      : 'Последняя синхронизация',
                  isTitle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (syncState.isSyncing) ...[
            LinearProgressIndicator(
              value: syncState.syncProgress / 100,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              syncState.currentOperation ?? 'Синхронизация...',
              isSubtitle: true,
            ),
          ] else ...[
            ResponsiveText(
              syncState.formattedLastSyncTime,
              isSubtitle: true,
            ),
          ],
        ],
      ),
    );
  }
}
