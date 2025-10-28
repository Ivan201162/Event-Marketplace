import 'package:event_marketplace_app/models/host_profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Демо-страница для тестирования профиля ведущего
class HostProfileDemoScreen extends StatelessWidget {
  const HostProfileDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Демо: Профиль ведущего'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тестирование страницы профиля ведущего',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(
              'Нажмите на кнопку ниже, чтобы открыть профиль ведущего с mock-данными:',
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 24),

            // Кнопка для открытия профиля ведущего
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Переход к профилю ведущего с mock ID
                  context.go('/host/host_001');
                },
                icon: const Icon(Icons.person),
                label: const Text('Открыть профиль ведущего'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),),
              ),
            ),

            const SizedBox(height: 32),

            // Информация о mock-данных
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mock-данные ведущего:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMockInfoRow('Имя', MockHostData.sampleHost.fullName),
                  _buildMockInfoRow('Город', MockHostData.sampleHost.city),
                  _buildMockInfoRow(
                      'Рейтинг', '${MockHostData.sampleHost.rating}/5.0',),
                  _buildMockInfoRow(
                      'Отзывы', '${MockHostData.sampleHost.totalReviews}',),
                  _buildMockInfoRow(
                      'Цена', MockHostData.sampleHost.priceRangeText,),
                  _buildMockInfoRow(
                    'Категории',
                    MockHostData.sampleHost.eventCategories.join(', '),
                  ),
                  _buildMockInfoRow(
                    'Доступные даты',
                    '${MockHostData.sampleHost.availableDates.length} дат',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TODO комментарии
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20,),
                      const SizedBox(width: 8),
                      Text(
                        'TODO: Интеграция с реальными данными',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Заменить MockHostData на реальные данные из Firebase\n'
                    '• Добавить загрузку данных по hostId\n'
                    '• Реализовать функционал "Откликнуться"\n'
                    '• Добавить чат с ведущим\n'
                    '• Реализовать добавление в избранное\n'
                    '• Добавить шаринг профиля',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey,),
              ),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w400),),
            ),
          ],
        ),
      );
}
