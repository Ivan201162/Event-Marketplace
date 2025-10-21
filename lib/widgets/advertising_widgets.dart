import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/advertisement.dart';
import '../providers/advertising_providers.dart';

/// Виджет рекламного объявления
class AdvertisementWidget extends ConsumerWidget {
  const AdvertisementWidget({
    super.key,
    required this.advertisement,
    required this.userId,
    required this.context,
    this.onTap,
  });
  final Advertisement advertisement;
  final String userId;
  final String context;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () {
            // Зафиксировать клик
            ref.read(advertisingStateProvider.notifier).recordClick(advertisement.id);

            // Выполнить действие
            onTap?.call();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение или видео
              _buildMedia(context),

              // Контент
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      advertisement.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    // Описание
                    Text(
                      advertisement.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Метка "Реклама"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Реклама',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMedia(BuildContext context) {
    if (advertisement.videoUrl != null && advertisement.videoUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.play_circle_outline, size: 48, color: Colors.grey)),
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          advertisement.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            ),
          ),
        ),
      );
    }
  }
}

/// Виджет баннера рекламы
class AdvertisementBannerWidget extends ConsumerWidget {
  const AdvertisementBannerWidget({
    super.key,
    required this.advertisement,
    required this.userId,
    required this.context,
  });
  final Advertisement advertisement;
  final String userId;
  final String context;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () {
            // Зафиксировать клик
            ref.read(advertisingStateProvider.notifier).recordClick(advertisement.id);
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                // Фоновое изображение
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    advertisement.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Градиент для читаемости текста
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),

                // Контент
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advertisement.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        advertisement.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Метка "Реклама"
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Реклама',
                      style:
                          TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Виджет создания рекламы
class CreateAdvertisementWidget extends ConsumerStatefulWidget {
  const CreateAdvertisementWidget({super.key, required this.advertiserId, this.onCreated});
  final String advertiserId;
  final VoidCallback? onCreated;

  @override
  ConsumerState<CreateAdvertisementWidget> createState() => _CreateAdvertisementWidgetState();
}

class _CreateAdvertisementWidgetState extends ConsumerState<CreateAdvertisementWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _budgetController = TextEditingController();

  AdvertisementType _selectedType = AdvertisementType.feed;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  final List<String> _targetAudience = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _targetUrlController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advertisingState = ref.watch(advertisingStateProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Создать рекламное объявление',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Тип рекламы
          DropdownButtonFormField<AdvertisementType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип рекламы',
              border: OutlineInputBorder(),
            ),
            items: AdvertisementType.values
                .map((type) => DropdownMenuItem(value: type, child: Text(type.displayName)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // Заголовок
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите заголовок';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Описание
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите описание';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // URL изображения
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'URL изображения',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите URL изображения';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // URL видео (опционально)
          TextFormField(
            controller: _videoUrlController,
            decoration: const InputDecoration(
              labelText: 'URL видео (опционально)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Целевой URL
          TextFormField(
            controller: _targetUrlController,
            decoration: const InputDecoration(
              labelText: 'Целевой URL',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите целевой URL';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Бюджет
          TextFormField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Бюджет (₽)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите бюджет';
              }
              final budget = double.tryParse(value);
              if (budget == null || budget <= 0) {
                return 'Введите корректный бюджет';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Даты
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Дата начала'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Дата окончания'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Кнопка создания
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: advertisingState.isLoading ? null : _createAdvertisement,
              child: advertisingState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Создать рекламу'),
            ),
          ),

          if (advertisingState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(advertisingState.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _createAdvertisement() {
    if (!_formKey.currentState!.validate()) return;

    final budget = double.parse(_budgetController.text);

    ref.read(advertisingStateProvider.notifier).createAdvertisement(
          advertiserId: widget.advertiserId,
          type: _selectedType,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          targetUrl: _targetUrlController.text.trim(),
          budget: budget,
          startDate: _startDate,
          endDate: _endDate,
          targetAudience: _targetAudience,
          videoUrl:
              _videoUrlController.text.trim().isNotEmpty ? _videoUrlController.text.trim() : null,
        );

    widget.onCreated?.call();
  }
}

/// Виджет статистики рекламы
class AdvertisementStatsWidget extends ConsumerWidget {
  const AdvertisementStatsWidget({super.key, required this.adId});
  final String adId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(advertisementStatsProvider(adId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика рекламы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _buildStatRow('Показы', stats['impressions'].toString(), Icons.visibility),
                  _buildStatRow('Клики', stats['clicks'].toString(), Icons.mouse),
                  _buildStatRow('Конверсии', stats['conversions'].toString(), Icons.trending_up),
                  _buildStatRow('CTR', '${stats['ctr'].toStringAsFixed(2)}%', Icons.percent),
                  _buildStatRow('CPM', '${stats['cpm'].toStringAsFixed(2)}₽', Icons.attach_money),
                  _buildStatRow('CPC', '${stats['cpc'].toStringAsFixed(2)}₽', Icons.mouse),
                  _buildStatRow(
                    'Бюджет',
                    NumberFormat.currency(
                      locale: 'ru',
                      symbol: '₽',
                      decimalDigits: 0,
                    ).format(stats['budget']),
                    Icons.account_balance_wallet,
                  ),
                  _buildStatRow(
                    'Потрачено',
                    NumberFormat.currency(
                      locale: 'ru',
                      symbol: '₽',
                      decimalDigits: 0,
                    ).format(stats['spentAmount']),
                    Icons.money_off,
                  ),
                  _buildStatRow(
                    'Остаток',
                    NumberFormat.currency(
                      locale: 'ru',
                      symbol: '₽',
                      decimalDigits: 0,
                    ).format(stats['remainingBudget']),
                    Icons.savings,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Ошибка: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );
}
