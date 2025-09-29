import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/app_update_provider.dart';
import '../services/app_update_service.dart';
import '../widgets/responsive_layout.dart';

/// Виджет для отображения уведомления об обновлении
class AppUpdateNotificationWidget extends ConsumerWidget {
  const AppUpdateNotificationWidget({
    super.key,
    this.onDismiss,
    this.onUpdate,
  });
  final VoidCallback? onDismiss;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowUpdateNotificationProvider);
    final updateState = ref.watch(appUpdateProvider);

    if (!shouldShow || updateState.updateInfo == null) {
      return const SizedBox.shrink();
    }

    final updateInfo = updateState.updateInfo!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(updateInfo.updateTypeColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(updateInfo.updateTypeColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                Icons.system_update,
                color: Color(updateInfo.updateTypeColor),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveText(
                  'Доступно обновление',
                  isTitle: true,
                  style: TextStyle(
                    color: Color(updateInfo.updateTypeColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(appUpdateProvider.notifier).dismissUpdate();
                  onDismiss?.call();
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Информация о версии
          ResponsiveText(
            '${updateInfo.updateTypeDescription}: v${updateInfo.latestVersion}',
            isSubtitle: true,
            style: TextStyle(
              color: Color(updateInfo.updateTypeColor),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(appUpdateProvider.notifier).dismissUpdate();
                    onDismiss?.call();
                  },
                  child: const Text('Позже'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(appUpdateProvider.notifier).openDownloadPage();
                    onUpdate?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(updateInfo.updateTypeColor),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Обновить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения настроек обновлений
class AppUpdateSettingsWidget extends ConsumerWidget {
  const AppUpdateSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);
    final versionDetails = ref.watch(versionDetailsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Обновления приложения',
                  isTitle: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.read(appUpdateProvider.notifier).forceCheckForUpdates(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Текущая версия
          if (versionDetails != null) ...[
            _buildInfoRow(
              'Текущая версия',
              'v${versionDetails.currentVersion}',
              Icons.info,
            ),
            _buildInfoRow(
              'Номер сборки',
              versionDetails.buildNumber,
              Icons.build,
            ),
            _buildInfoRow(
              'Имя приложения',
              versionDetails.appName,
              Icons.apps,
            ),
          ],

          // Статус обновления
          _buildStatusRow(
            'Статус обновления',
            updateState.updateStatus,
            Color(updateState.statusColor),
          ),

          // Информация об обновлении
          if (updateState.updateInfo != null) ...[
            _buildInfoRow(
              'Последняя версия',
              'v${updateState.updateInfo!.latestVersion}',
              Icons.new_releases,
            ),
            _buildInfoRow(
              'Тип обновления',
              updateState.updateInfo!.updateTypeDescription,
              Icons.category,
            ),
            _buildInfoRow(
              'Время проверки',
              updateState.updateInfo!.formattedCheckTime,
              Icons.access_time,
            ),
          ],

          const SizedBox(height: 16),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: updateState.isChecking
                      ? null
                      : () => ref
                          .read(appUpdateProvider.notifier)
                          .forceCheckForUpdates(),
                  icon: updateState.isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    updateState.isChecking
                        ? 'Проверка...'
                        : 'Проверить обновления',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: updateState.updateInfo?.downloadUrl != null
                      ? () => ref
                          .read(appUpdateProvider.notifier)
                          .openDownloadPage()
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Скачать'),
                ),
              ),
            ],
          ),

          // Ошибки
          if (updateState.error != null) ...[
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
                      updateState.error!,
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

  Widget _buildInfoRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResponsiveText(
                label,
                isSubtitle: true,
              ),
            ),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildStatusRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.info,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResponsiveText(
                label,
                isSubtitle: true,
              ),
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

/// Виджет для отображения информации о версии
class VersionInfoWidget extends ConsumerWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionDetails = ref.watch(versionDetailsProvider);

    if (versionDetails == null) {
      return const SizedBox.shrink();
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              ResponsiveText(
                'Информация о версии',
                isTitle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Полная информация о версии
          _buildInfoRow(
            'Версия приложения',
            versionDetails.fullVersionInfo,
            Icons.apps,
          ),

          // Статус обновления
          if (versionDetails.hasUpdateAvailable) ...[
            _buildInfoRow(
              'Статус обновления',
              versionDetails.updateDescription,
              Icons.system_update,
            ),
            if (versionDetails.updateType != null)
              _buildInfoRow(
                'Тип обновления',
                _getUpdateTypeDescription(versionDetails.updateType!),
                Icons.category,
              ),
          ] else ...[
            _buildInfoRow(
              'Статус обновления',
              'Приложение актуально',
              Icons.check_circle,
            ),
          ],

          const SizedBox(height: 16),

          // Кнопка проверки обновлений
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(appUpdateProvider.notifier).forceCheckForUpdates(),
              icon: const Icon(Icons.refresh),
              label: const Text('Проверить обновления'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    label,
                    isSubtitle: true,
                  ),
                  const SizedBox(height: 4),
                  ResponsiveText(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _getUpdateTypeDescription(UpdateType type) {
    switch (type) {
      case UpdateType.major:
        return 'Крупное обновление';
      case UpdateType.minor:
        return 'Обновление функций';
      case UpdateType.patch:
        return 'Исправления ошибок';
    }
  }
}

/// Виджет для отображения заметок о релизе
class ReleaseNotesWidget extends ConsumerWidget {
  const ReleaseNotesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);

    if (updateState.updateInfo?.releaseNotes.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes),
              SizedBox(width: 12),
              ResponsiveText(
                'Заметки о релизе',
                isTitle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ResponsiveText(
              updateState.updateInfo!.releaseNotes,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
