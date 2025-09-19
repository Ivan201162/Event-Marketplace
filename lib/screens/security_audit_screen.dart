import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/security.dart';
import '../providers/auth_providers.dart';
import '../services/security_service.dart';

/// Экран аудита безопасности
class SecurityAuditScreen extends ConsumerStatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  ConsumerState<SecurityAuditScreen> createState() =>
      _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends ConsumerState<SecurityAuditScreen> {
  final SecurityService _securityService = SecurityService();

  SecurityEventType? _selectedEventType;
  SecurityEventSeverity? _selectedSeverity;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Аудит безопасности'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: Column(
          children: [
            // Фильтры
            _buildFilters(),

            // Список событий
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
      );

  Widget _buildFilters() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поиск
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по описанию...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Фильтры
            Row(
              children: [
                // Тип события
                Expanded(
                  child: DropdownButtonFormField<SecurityEventType?>(
                    initialValue: _selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Тип события',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<SecurityEventType?>(
                        child: Text('Все типы'),
                      ),
                      ...SecurityEventType.values.map(
                        (type) => DropdownMenuItem<SecurityEventType?>(
                          value: type,
                          child: Text(_getEventTypeText(type)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEventType = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Серьезность
                Expanded(
                  child: DropdownButtonFormField<SecurityEventSeverity?>(
                    initialValue: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Серьезность',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<SecurityEventSeverity?>(
                        child: Text('Все уровни'),
                      ),
                      ...SecurityEventSeverity.values.map(
                        (severity) => DropdownMenuItem<SecurityEventSeverity?>(
                          value: severity,
                          child: Text(_getSeverityText(severity)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeverity = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildEventsList() => Consumer(
        builder: (context, ref, child) {
          final currentUser =
              await ref.watch(authServiceProvider).getCurrentUser();

          if (currentUser == null) {
            return const Center(
              child: Text('Пользователь не авторизован'),
            );
          }

          return StreamBuilder<List<SecurityAuditLog>>(
            stream: _securityService.getSecurityAuditLogs(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }

              final events = snapshot.data ?? [];
              final filteredEvents = _filterEvents(events);

              if (filteredEvents.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildEventItem(event);
                },
              );
            },
          );
        },
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет событий безопасности',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'События безопасности будут отображаться здесь',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEventItem(SecurityAuditLog event) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Row(
            children: [
              // Иконка типа события
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.eventType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEventTypeIcon(event.eventType),
                  color: _getEventTypeColor(event.eventType),
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // Описание
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(event.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Индикатор серьезности
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getSeverityColor(event.severity),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Основная информация
                  _buildInfoRow(
                    'Тип события',
                    _getEventTypeText(event.eventType),
                  ),
                  _buildInfoRow(
                    'Серьезность',
                    _getSeverityText(event.severity),
                  ),
                  _buildInfoRow('Время', _formatDateTime(event.timestamp)),

                  if (event.ipAddress != null)
                    _buildInfoRow('IP адрес', event.ipAddress!),

                  if (event.deviceId != null)
                    _buildInfoRow('ID устройства', event.deviceId!),

                  if (event.userAgent != null)
                    _buildInfoRow('User Agent', event.userAgent!),

                  // Метаданные
                  if (event.metadata != null && event.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Дополнительная информация:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.metadata.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const Text(': '),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  List<SecurityAuditLog> _filterEvents(List<SecurityAuditLog> events) {
    var filtered = events;

    // Фильтр по типу события
    if (_selectedEventType != null) {
      filtered = filtered
          .where((event) => event.eventType == _selectedEventType)
          .toList();
    }

    // Фильтр по серьезности
    if (_selectedSeverity != null) {
      filtered = filtered
          .where((event) => event.severity == _selectedSeverity)
          .toList();
    }

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((event) => event.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  String _getEventTypeText(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.login:
        return 'Вход в систему';
      case SecurityEventType.logout:
        return 'Выход из системы';
      case SecurityEventType.passwordChange:
        return 'Изменение пароля';
      case SecurityEventType.biometricAuth:
        return 'Биометрическая аутентификация';
      case SecurityEventType.pinAuth:
        return 'Аутентификация по PIN-коду';
      case SecurityEventType.twoFactorAuth:
        return 'Двухфакторная аутентификация';
      case SecurityEventType.deviceRegistration:
        return 'Регистрация устройства';
      case SecurityEventType.deviceBlocked:
        return 'Блокировка устройства';
      case SecurityEventType.suspiciousActivity:
        return 'Подозрительная активность';
      case SecurityEventType.dataAccess:
        return 'Доступ к данным';
      case SecurityEventType.dataModification:
        return 'Изменение данных';
      case SecurityEventType.securitySettingsChange:
        return 'Изменение настроек безопасности';
      case SecurityEventType.other:
        return 'Другое';
    }
  }

  String _getSeverityText(SecurityEventSeverity severity) {
    switch (severity) {
      case SecurityEventSeverity.info:
        return 'Информация';
      case SecurityEventSeverity.warning:
        return 'Предупреждение';
      case SecurityEventSeverity.error:
        return 'Ошибка';
      case SecurityEventSeverity.critical:
        return 'Критическое';
    }
  }

  IconData _getEventTypeIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.login:
        return Icons.login;
      case SecurityEventType.logout:
        return Icons.logout;
      case SecurityEventType.passwordChange:
        return Icons.lock;
      case SecurityEventType.biometricAuth:
        return Icons.fingerprint;
      case SecurityEventType.pinAuth:
        return Icons.pin;
      case SecurityEventType.twoFactorAuth:
        return Icons.security;
      case SecurityEventType.deviceRegistration:
        return Icons.devices;
      case SecurityEventType.deviceBlocked:
        return Icons.block;
      case SecurityEventType.suspiciousActivity:
        return Icons.warning;
      case SecurityEventType.dataAccess:
        return Icons.data_usage;
      case SecurityEventType.dataModification:
        return Icons.edit;
      case SecurityEventType.securitySettingsChange:
        return Icons.settings;
      case SecurityEventType.other:
        return Icons.info;
    }
  }

  Color _getEventTypeColor(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.login:
        return Colors.green;
      case SecurityEventType.logout:
        return Colors.blue;
      case SecurityEventType.passwordChange:
        return Colors.orange;
      case SecurityEventType.biometricAuth:
        return Colors.purple;
      case SecurityEventType.pinAuth:
        return Colors.teal;
      case SecurityEventType.twoFactorAuth:
        return Colors.indigo;
      case SecurityEventType.deviceRegistration:
        return Colors.cyan;
      case SecurityEventType.deviceBlocked:
        return Colors.red;
      case SecurityEventType.suspiciousActivity:
        return Colors.amber;
      case SecurityEventType.dataAccess:
        return Colors.blue;
      case SecurityEventType.dataModification:
        return Colors.orange;
      case SecurityEventType.securitySettingsChange:
        return Colors.grey;
      case SecurityEventType.other:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(SecurityEventSeverity severity) {
    switch (severity) {
      case SecurityEventSeverity.info:
        return Colors.blue;
      case SecurityEventSeverity.warning:
        return Colors.orange;
      case SecurityEventSeverity.error:
        return Colors.red;
      case SecurityEventSeverity.critical:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: const Text('Фильтры уже применены в интерфейсе'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
