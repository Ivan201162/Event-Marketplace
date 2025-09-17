import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/photo_studio.dart';
import '../services/photo_studio_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения карточки фотостудии
class PhotoStudioCard extends ConsumerWidget {
  final PhotoStudio studio;
  final VoidCallback? onTap;

  const PhotoStudioCard({
    super.key,
    required this.studio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с рейтингом
          Row(
            children: [
              Expanded(
                child: ResponsiveText(
                  studio.name,
                  isTitle: true,
                ),
              ),
              if (studio.rating != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  studio.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                if (studio.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${studio.reviewCount})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Описание
          ResponsiveText(
            studio.description,
            isSubtitle: true,
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    studio.priceRange!,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
              children: studio.studioOptions
                  .take(3)
                  .map((option) => _buildOptionChip(option))
                  .toList(),
            ),
            if (studio.studioOptions.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+${studio.studioOptions.length - 3} еще',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOptionChip(StudioOption option) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        option.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }
}

/// Виджет для отображения детальной информации о фотостудии
class PhotoStudioDetailWidget extends ConsumerWidget {
  final String studioId;

  const PhotoStudioDetailWidget({
    super.key,
    required this.studioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(photoStudioProvider(studioId)).when(
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
                                  child: ResponsiveText(
                                    studio.name,
                                    isTitle: true,
                                  ),
                                ),
                                if (studio.rating != null) ...[
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    studio.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  if (studio.reviewCount != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${studio.reviewCount} отзывов)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            ResponsiveText(
                              studio.description,
                              isSubtitle: true,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    studio.address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
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
                            ResponsiveText(
                              'Опции студии',
                              isTitle: true,
                            ),
                            const SizedBox(height: 12),
                            ...studio.studioOptions
                                .map((option) => _buildOptionCard(option)),
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
                                ResponsiveText(
                                  'Фотографии',
                                  isTitle: true,
                                ),
                                const Spacer(),
                                Text(
                                  '${studio.photosCount} фото',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (studio.photos.isEmpty) ...[
                              const Center(
                                child: Text('Фотографии не загружены'),
                              ),
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
                              onPressed: () =>
                                  _showBookingDialog(context, ref, studio),
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
            );
      },
    );
  }

  Widget _buildOptionCard(StudioOption option) {
    return Container(
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
                child: ResponsiveText(
                  option.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${option.pricePerHour.toStringAsFixed(0)} ₽/час',
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
          ResponsiveText(
            option.description,
            isSubtitle: true,
          ),
          if (option.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildOptionPhotos(option.photos),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionPhotos(List<String> photos) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photos[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showPhotoPreview(context, photos[index]),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photos[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl) {
    showDialog(
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
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(
      BuildContext context, WidgetRef ref, PhotoStudio studio) {
    showDialog(
      context: context,
      builder: (context) => _BookingDialog(
        studio: studio,
        onBookingCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Бронирование создано'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

/// Виджет для списка фотостудий
class PhotoStudioListWidget extends ConsumerWidget {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final Function(PhotoStudio)? onStudioSelected;

  const PhotoStudioListWidget({
    super.key,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.onStudioSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return ref
            .watch(photoStudiosProvider(
              location: location,
              minPrice: minPrice,
              maxPrice: maxPrice,
            ))
            .when(
              data: (studios) {
                if (studios.isEmpty) {
                  return const Center(
                    child: Text('Фотостудии не найдены'),
                  );
                }

                return ListView.builder(
                  itemCount: studios.length,
                  itemBuilder: (context, index) {
                    final studio = studios[index];
                    return PhotoStudioCard(
                      studio: studio,
                      onTap: () => onStudioSelected?.call(studio),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка: $error')),
            );
      },
    );
  }
}

/// Диалог бронирования
class _BookingDialog extends StatefulWidget {
  final PhotoStudio studio;
  final VoidCallback onBookingCreated;

  const _BookingDialog({
    required this.studio,
    required this.onBookingCreated,
  });

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Бронирование ${widget.studio.name}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Выбор опции
            DropdownButtonFormField<StudioOption>(
              value: _selectedOption,
              decoration: const InputDecoration(
                labelText: 'Выберите опцию',
                border: OutlineInputBorder(),
              ),
              items: widget.studio.studioOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                      '${option.name} - ${option.pricePerHour.toStringAsFixed(0)} ₽/час'),
                );
              }).toList(),
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
              subtitle: Text(_selectedDate != null
                  ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                  : 'Выберите дату'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),

            // Выбор времени
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Начало'),
                    subtitle: Text(_startTime != null
                        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                        : 'Выберите время'),
                    trailing: const Icon(Icons.access_time),
                    onTap: _selectStartTime,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Окончание'),
                    subtitle: Text(_endTime != null
                        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                        : 'Выберите время'),
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
  }

  bool _canCreateBooking() {
    return _selectedOption != null &&
        _selectedDate != null &&
        _startTime != null &&
        _endTime != null &&
        !_isLoading;
  }

  void _selectDate() async {
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

  void _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  void _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _createBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(photoStudioServiceProvider);

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      await service.createStudioBooking(
        studioId: widget.studio.id,
        customerId: 'current_user_id', // TODO: Получить из контекста
        optionId: _selectedOption!.id,
        startTime: startDateTime,
        endTime: endDateTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      widget.onBookingCreated();
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

/// Провайдер для фотостудии
final photoStudioProvider =
    FutureProvider.family<PhotoStudio?, String>((ref, studioId) async {
  final service = ref.read(photoStudioServiceProvider);
  return await service.getPhotoStudio(studioId);
});

/// Провайдер для списка фотостудий
final photoStudiosProvider =
    FutureProvider.family<List<PhotoStudio>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(photoStudioServiceProvider);
  return await service.getPhotoStudios(
    location: params['location'],
    minPrice: params['minPrice'],
    maxPrice: params['maxPrice'],
    limit: params['limit'] ?? 20,
  );
});

/// Провайдер для сервиса фотостудий
final photoStudioServiceProvider = Provider<PhotoStudioService>((ref) {
  return PhotoStudioService();
});
