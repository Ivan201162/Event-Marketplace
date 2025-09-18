import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/studio_recommendation.dart';
import '../models/photo_studio.dart';
import '../services/studio_recommendation_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения рекомендации студии
class StudioRecommendationWidget extends ConsumerWidget {
  final StudioRecommendation recommendation;
  final VoidCallback? onRecommendationTapped;

  const StudioRecommendationWidget({
    super.key,
    required this.recommendation,
    this.onRecommendationTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      onTap: onRecommendationTapped,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(Icons.photo_library, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  'Рекомендуем студию',
                  isTitle: true,
                ),
              ),
              if (recommendation.isExpired) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Истекло',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Информация о студии
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  recommendation.studioName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openStudioUrl(recommendation.studioUrl),
                        child: Text(
                          'Открыть студию',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Сообщение фотографа
          if (recommendation.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.message, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      recommendation.message!,
                      isSubtitle: true,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Информация о времени
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              ResponsiveText(
                'Создано: ${_formatDate(recommendation.createdAt)}',
                isSubtitle: true,
              ),
              if (recommendation.expiresAt != null) ...[
                const Spacer(),
                ResponsiveText(
                  'Действует до: ${_formatDate(recommendation.expiresAt!)}',
                  isSubtitle: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _openStudioUrl(String url) {
    // TODO: Реализовать открытие URL
    print('Открытие URL: $url');
  }
}

/// Виджет для создания рекомендации студии
class CreateStudioRecommendationWidget extends ConsumerStatefulWidget {
  final String photographerId;
  final VoidCallback? onRecommendationCreated;

  const CreateStudioRecommendationWidget({
    super.key,
    required this.photographerId,
    this.onRecommendationCreated,
  });

  @override
  ConsumerState<CreateStudioRecommendationWidget> createState() =>
      _CreateStudioRecommendationWidgetState();
}

class _CreateStudioRecommendationWidgetState
    extends ConsumerState<CreateStudioRecommendationWidget> {
  final _messageController = TextEditingController();
  final _studioUrlController = TextEditingController();
  PhotoStudio? _selectedStudio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendedStudios();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _studioUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, color: Colors.blue),
              const SizedBox(width: 8),
              ResponsiveText(
                'Рекомендовать студию',
                isTitle: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Рекомендуйте клиенту фотостудию для съемки. Это поможет создать полный пакет услуг.',
          ),

          const SizedBox(height: 16),

          // Выбор студии
          DropdownButtonFormField<PhotoStudio>(
            initialValue: _selectedStudio,
            decoration: const InputDecoration(
              labelText: 'Выберите студию',
              border: OutlineInputBorder(),
            ),
            items: _getStudioDropdownItems(),
            onChanged: (value) {
              setState(() {
                _selectedStudio = value;
                if (value != null) {
                  _studioUrlController.text =
                      'https://example.com/studio/${value.id}';
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // URL студии
          TextField(
            controller: _studioUrlController,
            decoration: const InputDecoration(
              labelText: 'URL студии',
              border: OutlineInputBorder(),
              hintText: 'https://example.com/studio/...',
            ),
          ),

          const SizedBox(height: 16),

          // Сообщение
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Сообщение клиенту (необязательно)',
              border: OutlineInputBorder(),
              hintText: 'Добавьте комментарий к рекомендации...',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Кнопка создания рекомендации
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _canCreateRecommendation() ? _createRecommendation : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label:
                      Text(_isLoading ? 'Создание...' : 'Создать рекомендацию'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<PhotoStudio>> _getStudioDropdownItems() {
    return ref.watch(recommendedStudiosProvider(widget.photographerId)).when(
          data: (studios) => studios.map((studio) {
            return DropdownMenuItem(
              value: studio,
              child: Text(studio.name),
            );
          }).toList(),
          loading: () => [const DropdownMenuItem(child: Text('Загрузка...'))],
          error: (error, stack) =>
              [DropdownMenuItem(child: Text('Ошибка: $error'))],
        );
  }

  bool _canCreateRecommendation() {
    return _selectedStudio != null &&
        _studioUrlController.text.isNotEmpty &&
        !_isLoading;
  }

  void _loadRecommendedStudios() {
    // Загружаем рекомендуемые студии через провайдер
    ref.read(recommendedStudiosProvider(widget.photographerId));
  }

  void _createRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(studioRecommendationServiceProvider);
      await service.createStudioRecommendation(
        photographerId: widget.photographerId,
        studioId: _selectedStudio!.id,
        studioName: _selectedStudio!.name,
        studioUrl: _studioUrlController.text.trim(),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        expiresIn: const Duration(days: 7),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Рекомендация создана'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onRecommendationCreated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Виджет для двойного бронирования
class DualBookingWidget extends ConsumerWidget {
  final DualBooking booking;
  final VoidCallback? onBookingTapped;

  const DualBookingWidget({
    super.key,
    required this.booking,
    this.onBookingTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      onTap: onBookingTapped,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(Icons.photo_camera, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  'Двойное бронирование',
                  isTitle: true,
                ),
              ),
              _buildStatusChip(),
            ],
          ),

          const SizedBox(height: 12),

          // Информация о бронировании
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Дата и время:',
                      isSubtitle: true,
                    ),
                    ResponsiveText(
                      '${_formatDateTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Продолжительность:',
                      isSubtitle: true,
                    ),
                    ResponsiveText(
                      '${booking.durationInHours.toStringAsFixed(1)} ч',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Общая стоимость:',
                      isSubtitle: true,
                    ),
                    ResponsiveText(
                      '${booking.totalPrice.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (booking.savings > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'Экономия:',
                        isSubtitle: true,
                      ),
                      ResponsiveText(
                        '-${booking.savings.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Детализация стоимости
          const SizedBox(height: 12),
          ResponsiveText(
            'Детализация:',
            isTitle: true,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildPriceItem(
                  'Фотограф',
                  '${booking.photographerPrice.toStringAsFixed(0)} ₽',
                  Icons.person,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildPriceItem(
                  'Студия',
                  '${booking.studioPrice.toStringAsFixed(0)} ₽',
                  Icons.photo_library,
                  Colors.green,
                ),
              ),
            ],
          ),

          // Заметки
          if (booking.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      booking.notes!,
                      isSubtitle: true,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Информация о времени
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              ResponsiveText(
                'Создано: ${_formatDate(booking.createdAt)}',
                isSubtitle: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;

    switch (booking.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Ожидает';
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Подтверждено';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'В процессе';
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Завершено';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Отменено';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Неизвестно';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceItem(
      String label, String price, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Провайдер для сервиса рекомендаций студий
final studioRecommendationServiceProvider =
    Provider<StudioRecommendationService>((ref) {
  return StudioRecommendationService();
});

/// Провайдер для рекомендуемых студий
final recommendedStudiosProvider =
    FutureProvider.family<List<PhotoStudio>, String>(
        (ref, photographerId) async {
  final service = ref.read(studioRecommendationServiceProvider);
  return await service.getRecommendedStudiosForPhotographer(photographerId);
});
