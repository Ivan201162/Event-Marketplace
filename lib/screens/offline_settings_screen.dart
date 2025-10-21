import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/offline_provider.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/responsive_layout.dart';

/// Экран настроек офлайн-режима
class OfflineSettingsScreen extends ConsumerWidget {
  const OfflineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveLayout(
    mobile: _buildMobileLayout(context, ref),
    tablet: _buildTabletLayout(context, ref),
    desktop: _buildDesktopLayout(context, ref),
    largeDesktop: _buildLargeDesktopLayout(context, ref),
  );

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Офлайн-режим'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          OfflineDetailsWidget(),
          SizedBox(height: 24),
          CacheInfoWidget(),
          SizedBox(height: 24),
          OfflineRecommendationsWidget(),
          SizedBox(height: 24),
          SyncStatusWidget(),
        ],
      ),
    ),
  );

  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Офлайн-режим'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: const ResponsiveContainer(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            OfflineDetailsWidget(),
            SizedBox(height: 24),
            CacheInfoWidget(),
            SizedBox(height: 24),
            OfflineRecommendationsWidget(),
            SizedBox(height: 24),
            SyncStatusWidget(),
          ],
        ),
      ),
    ),
  );

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Офлайн-режим'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: ResponsiveContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая панель
          const SizedBox(
            width: 400,
            child: Column(
              children: [
                SizedBox(height: 20),
                OfflineDetailsWidget(),
                SizedBox(height: 24),
                CacheInfoWidget(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Правая панель
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const OfflineRecommendationsWidget(),
                const SizedBox(height: 24),
                const SyncStatusWidget(),
                const SizedBox(height: 24),
                _buildOfflineActions(context, ref),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLargeDesktopLayout(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Офлайн-режим'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: ResponsiveContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая панель
          const SizedBox(
            width: 450,
            child: Column(
              children: [
                SizedBox(height: 20),
                OfflineDetailsWidget(),
                SizedBox(height: 24),
                CacheInfoWidget(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Центральная панель
          const Expanded(
            child: Column(
              children: [
                SizedBox(height: 20),
                OfflineRecommendationsWidget(),
                SizedBox(height: 24),
                SyncStatusWidget(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Правая панель
          SizedBox(
            width: 300,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildOfflineActions(context, ref),
                const SizedBox(height: 24),
                _buildQuickSettings(context, ref),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildOfflineActions(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineModeProvider);
    final syncState = ref.watch(syncProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText('Действия', isTitle: true),
          const SizedBox(height: 16),

          // Переключение офлайн-режима
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(offlineModeProvider.notifier).toggleOfflineMode(),
              icon: Icon(offlineState.isOfflineMode ? Icons.wifi : Icons.wifi_off),
              label: Text(offlineState.isOfflineMode ? 'Включить онлайн' : 'Включить офлайн'),
              style: ElevatedButton.styleFrom(
                backgroundColor: offlineState.isOfflineMode ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Синхронизация
          SizedBox(
            width: double.infinity,
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
              label: Text(syncState.isSyncing ? 'Синхронизация...' : 'Синхронизировать'),
            ),
          ),

          const SizedBox(height: 12),

          // Очистка кэша
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showClearCacheDialog(context, ref),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Очистить кэш'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings(BuildContext context, WidgetRef ref) => ResponsiveCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveText('Быстрые настройки', isTitle: true),
        const SizedBox(height: 16),

        // Автоматическая синхронизация
        SwitchListTile(
          title: const Text('Автосинхронизация'),
          subtitle: const Text('Автоматическая синхронизация при подключении'),
          value: true, // TODO(developer): Получить из настроек
          onChanged: (value) {
            // TODO(developer): Сохранить настройку
          },
        ),

        // Кэширование изображений
        SwitchListTile(
          title: const Text('Кэш изображений'),
          subtitle: const Text('Сохранять изображения локально'),
          value: true, // TODO(developer): Получить из настроек
          onChanged: (value) {
            // TODO(developer): Сохранить настройку
          },
        ),

        // Кэширование видео
        SwitchListTile(
          title: const Text('Кэш видео'),
          subtitle: const Text('Сохранять видео локально'),
          value: false, // TODO(developer): Получить из настроек
          onChanged: (value) {
            // TODO(developer): Сохранить настройку
          },
        ),

        // Уведомления о статусе
        SwitchListTile(
          title: const Text('Уведомления'),
          subtitle: const Text('Уведомления о статусе подключения'),
          value: true, // TODO(developer): Получить из настроек
          onChanged: (value) {
            // TODO(developer): Сохранить настройку
          },
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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

/// Виджет для отображения статистики офлайн-режима
class OfflineStatsWidget extends ConsumerWidget {
  const OfflineStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineModeProvider);
    final cacheInfo = ref.watch(cacheInfoProvider);
    final syncState = ref.watch(syncProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText('Статистика', isTitle: true),
          const SizedBox(height: 16),

          // Время в офлайн-режиме
          _buildStatRow('Время в офлайн-режиме', '2 ч. 30 мин.', Icons.access_time),

          // Размер кэша
          _buildStatRow('Размер кэша', cacheInfo.formattedCacheSize, Icons.storage),

          // Элементов в кэше
          _buildStatRow('Элементов в кэше', '${cacheInfo.cacheItemsCount}', Icons.folder),

          // Последняя синхронизация
          if (syncState.lastSyncTime != null)
            _buildStatRow('Последняя синхронизация', syncState.formattedLastSyncTime, Icons.sync),

          // Статус кэша
          _buildStatRow(
            'Статус кэша',
            offlineState.isCacheStale ? 'Требует обновления' : 'Актуален',
            offlineState.isCacheStale ? Icons.warning : Icons.check_circle,
            color: offlineState.isCacheStale ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: ResponsiveText(label, isSubtitle: true)),
        ResponsiveText(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
      ],
    ),
  );
}
