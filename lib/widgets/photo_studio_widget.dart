import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/photo_studio.dart';
import '../services/photo_studio_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения карточки фотостудии
class PhotoStudioCard extends ConsumerWidget {
  const PhotoStudioCard({super.key, required this.studio, this.onTap});
  final PhotoStudio studio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: onTap,
    child: ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с рейтингом
          Row(
            children: [
              Expanded(child: Text(studio.name, style: Theme.of(context).textTheme.headlineSmall)),
              ...[
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  studio.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${studio.reviewCount})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Описание
          Text(
            studio.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 8),

          // Адрес
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  studio.address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Цены и опции
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (studio.priceRange != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    studio.priceRange!.formattedRange,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  const Icon(Icons.photo_library, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${studio.photosCount} фото',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Опции студии
          if (studio.studioOptions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: studio.studioOptions.take(3).map(_buildOptionChip).toList(),
            ),
            if (studio.studioOptions.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+${studio.studioOptions.length - 3} еще',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _buildOptionChip(StudioOption option) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      option.name,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue),
    ),
  );
}

/// Виджет для отображения детальной информации о фотостудии
class PhotoStudioDetailWidget extends ConsumerWidget {
  const PhotoStudioDetailWidget({super.key, required this.studioId});
  final String studioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
    builder: (context, ref, child) => ref
        .watch(photoStudioProvider(studioId))
        .when(
          data: (studio) {
            if (studio == null) {
              return const Center(child: Text('Фотостудия не найдена'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  ResponsiveCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                studio.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            ...[
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                studio.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${studio.reviewCount} отзывов)',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          studio.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                studio.address,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Опции студии
                  ResponsiveCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Опции студии', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        ...studio.studioOptions.map((option) => _buildOptionCard(context, option)),
                      ],
                    ),
                  ),

                  // Фотографии
                  ResponsiveCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Фотографии', style: Theme.of(context).textTheme.headlineSmall),
                            const Spacer(),
                            Text(
                              '${studio.photosCount} фото',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (studio.photos.isEmpty) ...[
                          const Center(child: Text('Фотографии не загружены')),
                        ] else ...[
                          _buildPhotosGrid(studio.photos),
                        ],
                      ],
                    ),
                  ),

                  // Кнопка бронирования
                  ResponsiveCard(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showBookingDialog(context, ref, studio),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Забронировать студию'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ошибка: $error')),
        ),
  );

  Widget _buildOptionCard(BuildContext context, StudioOption option) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${option.price.toStringAsFixed(0)} ₽/час',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          option.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // TODO(developer): Добавить поддержку фотографий для опций студии
        // if (option.photos.isNotEmpty) ...[
        //   const SizedBox(height: 8),
        //   _buildOptionPhotos(option.photos),
        // ],
      ],
    ),
  );

  Widget _buildOptionPhotos(List<String> photos) => SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(right: 8),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photos[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    ),
  );

  Widget _buildPhotosGrid(List<String> photos) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: photos.length,
    itemBuilder: (context, index) => GestureDetector(
      onTap: () => _showPhotoPreview(context, photos[index]),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photos[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    ),
  );

  void _showPhotoPreview(BuildContext context, String photoUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Просмотр фото'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, WidgetRef ref, PhotoStudio studio) {
    showDialog<void>(
      context: context,
      builder: (context) => _BookingDialog(
        studio: studio,
        onBookingCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Бронирование создано'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }
}

/// Виджет для списка фотостудий
class PhotoStudioListWidget extends ConsumerWidget {
  const PhotoStudioListWidget({
    super.key,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.onStudioSelected,
  });
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final void Function(PhotoStudio)? onStudioSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
    builder: (context, ref, child) => ref
        .watch(
          photoStudiosProvider({'location': location, 'minPrice': minPrice, 'maxPrice': maxPrice}),
        )
        .when(
          data: (studios) {
            if (studios.isEmpty) {
              return const Center(child: Text('Фотостудии не найдены'));
            }

            return ListView.builder(
              itemCount: studios.length,
              itemBuilder: (context, index) {
                final studio = studios[index];
                return PhotoStudioCard(studio: studio, onTap: () => onStudioSelected?.call(studio));
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ошибка: $error')),
        ),
  );
}

/// Диалог бронирования
class _BookingDialog extends ConsumerStatefulWidget {
  const _BookingDialog({required this.studio, required this.onBookingCreated});
  final PhotoStudio studio;
  final VoidCallback onBookingCreated;

  @override
  ConsumerState<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<_BookingDialog> {
  StudioOption? _selectedOption;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _calculateDuration() {
    if (_startTime == null || _endTime == null) {
      return 1;
    }
    final start = _startTime!;
    final end = _endTime!;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endMinutes - startMinutes;
    return (durationMinutes / 60).clamp(1.0, 24.0);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Бронирование ${widget.studio.name}'),
    content: SizedBox(
      width: double.maxFinite,
      height: 400,
      child: Column(
        children: [
          // Выбор опции
          DropdownButtonFormField<StudioOption>(
            initialValue: _selectedOption,
            decoration: const InputDecoration(
              labelText: 'Выберите опцию',
              border: OutlineInputBorder(),
            ),
            items: widget.studio.studioOptions
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text('${option.name} - ${option.price.toStringAsFixed(0)} ₽/час'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedOption = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Выбор даты
          ListTile(
            title: const Text('Дата'),
            subtitle: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                  : 'Выберите дату',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),

          // Выбор времени
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Начало'),
                  subtitle: Text(
                    _startTime != null
                        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                        : 'Выберите время',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectStartTime,
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Окончание'),
                  subtitle: Text(
                    _endTime != null
                        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                        : 'Выберите время',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectEndTime,
                ),
              ),
            ],
          ),

          // Заметки
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Заметки (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        onPressed: _canCreateBooking() ? _createBooking : null,
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Забронировать'),
      ),
    ],
  );

  bool _canCreateBooking() =>
      _selectedOption != null &&
      _selectedDate != null &&
      _startTime != null &&
      _endTime != null &&
      !_isLoading;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _createBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {

      // await service.createStudioBooking(
      //   studioId: widget.studio.id,
      //   customerId: 'current_user_id', // TODO(developer): Получить из контекста
      //   startTime: startDateTime,
      //   endTime: endDateTime,
      //   // totalPrice: _selectedOption!.price * _calculateDuration(),
      //   // notes: _notesController.text.trim().isEmpty
      //   //     ? null
      //   //     : _notesController.text.trim(),
      // );

      widget.onBookingCreated();
    } on Exception catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Провайдер для фотостудии
final photoStudioProvider = FutureProvider.family<PhotoStudio?, String>((ref, studioId) async {
  final service = ref.read(photoStudioServiceProvider);
  return service.getPhotoStudio(studioId);
});

/// Провайдер для списка фотостудий
final photoStudiosProvider = FutureProvider.family<List<PhotoStudio>, Map<String, dynamic>>((
  ref,
  params,
) async {
  final service = ref.read(photoStudioServiceProvider);
  return service.getPhotoStudios(limit: params['limit'] as int? ?? 20);
});

/// Провайдер для сервиса фотостудий
final photoStudioServiceProvider = Provider<PhotoStudioService>((ref) => PhotoStudioService());
