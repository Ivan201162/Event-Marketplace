import 'package:flutter/material.dart';

/// Виджет для отображения прайс-листа специалиста
class PriceListWidget extends StatelessWidget {
  const PriceListWidget({
    super.key,
    required this.servicesWithPrices,
    required this.hourlyRate,
    required this.price,
    this.onEditPrices,
  });
  final Map<String, double> servicesWithPrices;
  final double hourlyRate;
  final double price;
  final VoidCallback? onEditPrices;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой редактирования
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Услуги и цены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onEditPrices != null)
                TextButton.icon(
                  onPressed: onEditPrices,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Редактировать'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Основная цена за час
          _buildPriceCard(
            title: 'Базовая ставка',
            price: hourlyRate,
            description: 'За час работы',
            isMain: true,
          ),

          const SizedBox(height: 12),

          // Общая цена
          if (price != hourlyRate)
            _buildPriceCard(
              title: 'Общая цена',
              price: price,
              description: 'За полный заказ',
              isMain: false,
            ),

          const SizedBox(height: 16),

          // Список услуг с ценами
          if (servicesWithPrices.isNotEmpty) ...[
            const Text(
              'Дополнительные услуги',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...servicesWithPrices.entries.map(
              (entry) => _buildServiceItem(entry.key, entry.value),
            ),
          ] else ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.list_alt, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Дополнительные услуги не указаны',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Специалист может добавить услуги с ценами',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Информация о ценах
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Цены могут варьироваться в зависимости от сложности заказа и дополнительных услуг',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildPriceCard({
    required String title,
    required double price,
    required String description,
    required bool isMain,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMain ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMain ? Colors.green.shade200 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isMain ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${price.toInt()}₽',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isMain ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _buildServiceItem(String serviceName, double price) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${price.toInt()}₽',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
}
