import 'package:flutter/material.dart';
import '../models/integration.dart';

/// Виджет интеграции
class IntegrationWidget extends StatelessWidget {
  const IntegrationWidget({super.key, required this.integration, this.onTap});
  final Integration integration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и статус
                Row(
                  children: [
                    // Иконка
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: integration.typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(integration.typeIcon, color: integration.typeColor, size: 24),
                    ),

                    const SizedBox(width: 12),

                    // Название и описание
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            integration.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            integration.description,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Статус
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: integration.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: integration.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        integration.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: integration.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Тип и разрешения
                Row(
                  children: [
                    // Тип
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: integration.typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(integration.typeIcon, size: 14, color: integration.typeColor),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeText(integration.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: integration.typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Разрешения
                    if (integration.permissions.isNotEmpty) ...[
                      Icon(Icons.security, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${integration.permissions.length} разрешений',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Дополнительная информация
                Row(
                  children: [
                    if (integration.isRequired) ...[
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Обязательная',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (integration.websiteUrl != null) ...[
                      Icon(Icons.language, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Сайт', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ],
            ),
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
}

/// Виджет для отображения интеграции в списке
class IntegrationListTile extends StatelessWidget {
  const IntegrationListTile({super.key, required this.integration, this.onTap});
  final Integration integration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: integration.typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(integration.typeIcon, color: integration.typeColor, size: 24),
        ),
        title: Text(integration.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(integration.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: integration.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    integration.statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: integration.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: integration.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeText(integration.type),
                    style: TextStyle(
                      fontSize: 10,
                      color: integration.typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (integration.isRequired) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
}

/// Виджет для отображения интеграции в сетке
class IntegrationGridTile extends StatelessWidget {
  const IntegrationGridTile({super.key, required this.integration, this.onTap});
  final Integration integration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка и статус
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: integration.typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(integration.typeIcon, color: integration.typeColor, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: integration.statusColor, shape: BoxShape.circle),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Название
                Text(
                  integration.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Описание
                Text(
                  integration.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Статус и тип
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        integration.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: integration.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (integration.isRequired)
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
