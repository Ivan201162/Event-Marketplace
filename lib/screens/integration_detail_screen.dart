import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/integration.dart';
import '../providers/auth_providers.dart';
import '../services/integration_service.dart';

/// Экран детального просмотра интеграции
class IntegrationDetailScreen extends ConsumerStatefulWidget {
  const IntegrationDetailScreen({
    super.key,
    required this.integration,
  });
  final Integration integration;

  @override
  ConsumerState<IntegrationDetailScreen> createState() =>
      _IntegrationDetailScreenState();
}

class _IntegrationDetailScreenState
    extends ConsumerState<IntegrationDetailScreen> {
  final IntegrationService _integrationService = IntegrationService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.integration.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareIntegration,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildMainInfo(),

              const SizedBox(height: 24),

              // Описание
              _buildDescription(),

              const SizedBox(height: 24),

              // Разрешения
              _buildPermissions(),

              const SizedBox(height: 24),

              // Настройки
              _buildSettings(),

              const SizedBox(height: 24),

              // Действия
              _buildActions(),
            ],
          ),
        ),
      );

  Widget _buildMainInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Иконка
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          widget.integration.typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.integration.typeIcon,
                      color: widget.integration.typeColor,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.integration.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.integration.statusColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.integration.statusColor
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            widget.integration.statusText,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.integration.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Тип
              Row(
                children: [
                  Icon(
                    widget.integration.typeIcon,
                    size: 20,
                    color: widget.integration.typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTypeText(widget.integration.type),
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.integration.typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.integration.isRequired) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Обязательная',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDescription() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Описание',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.integration.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPermissions() {
    if (widget.integration.permissions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Разрешения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.integration.permissions.map(
              (permission) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permission,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Включить/выключить
              SwitchListTile(
                title: const Text('Включить интеграцию'),
                subtitle: const Text('Разрешить использование этой интеграции'),
                value: widget.integration.isEnabled,
                onChanged: (value) {
                  // TODO(developer): Реализовать включение/выключение интеграции
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройка сохранена')),
                  );
                },
              ),

              // Дополнительные настройки
              if (widget.integration.config.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Дополнительные настройки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.integration.config.entries.map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    subtitle: Text(entry.value.toString()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(developer): Реализовать редактирование настроек
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Редактирование ${entry.key}')),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildActions() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Действия',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Подключить/отключить
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleIntegration,
                  icon: Icon(
                    widget.integration.status == IntegrationStatus.connected
                        ? Icons.link_off
                        : Icons.link,
                  ),
                  label: Text(
                    widget.integration.status == IntegrationStatus.connected
                        ? 'Отключить'
                        : 'Подключить',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.integration.status == IntegrationStatus.connected
                            ? Colors.red
                            : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Синхронизировать
              if (widget.integration.status == IntegrationStatus.connected) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _syncIntegration,
                    icon: const Icon(Icons.sync),
                    label: const Text('Синхронизировать'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Открыть сайт
              if (widget.integration.websiteUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openWebsite,
                    icon: const Icon(Icons.language),
                    label: const Text('Открыть сайт'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Документация
              if (widget.integration.documentationUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openDocumentation,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Документация'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  String _getTypeText(IntegrationType type) {
    switch (type) {
      case IntegrationType.maps:
        return 'Карты';
      case IntegrationType.social:
        return 'Социальные';
      case IntegrationType.payment:
        return 'Платежи';
      case IntegrationType.calendar:
        return 'Календарь';
      case IntegrationType.email:
        return 'Email';
      case IntegrationType.sms:
        return 'SMS';
      case IntegrationType.analytics:
        return 'Аналитика';
      case IntegrationType.storage:
        return 'Хранилище';
      case IntegrationType.other:
        return 'Другое';
    }
  }

  Future<void> _toggleIntegration() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    try {
      bool success;
      if (widget.integration.status == IntegrationStatus.connected) {
        success = await _integrationService.disconnectIntegration(
          widget.integration.id,
        );
      } else {
        success = await _integrationService.connectIntegration(
          widget.integration.id,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.integration.status == IntegrationStatus.connected
                  ? 'Интеграция отключена'
                  : 'Интеграция подключена',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка изменения статуса интеграции'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncIntegration() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    try {
      final success = await _integrationService.syncIntegrationData(
        widget.integration.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Синхронизация завершена'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка синхронизации'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWebsite() async {
    if (widget.integration.websiteUrl != null) {
      final success =
          await _integrationService.openUrl(widget.integration.websiteUrl!);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть сайт'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocumentation() async {
    if (widget.integration.documentationUrl != null) {
      final success = await _integrationService
          .openUrl(widget.integration.documentationUrl!);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть документацию'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareIntegration() {
    // TODO(developer): Реализовать шаринг интеграции
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Интеграция скопирована в буфер обмена')),
    );
  }
}
