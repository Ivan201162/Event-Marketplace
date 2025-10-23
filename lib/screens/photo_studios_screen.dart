import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo_studio.dart';
import '../providers/auth_providers.dart';
import '../services/photo_studio_service.dart';
import '../widgets/photo_studio_card.dart';

/// Экран просмотра фотостудий
class PhotoStudiosScreen extends ConsumerStatefulWidget {
  const PhotoStudiosScreen({super.key});

  @override
  ConsumerState<PhotoStudiosScreen> createState() => _PhotoStudiosScreenState();
}

class _PhotoStudiosScreenState extends ConsumerState<PhotoStudiosScreen> {
  final PhotoStudioService _photoStudioService = PhotoStudioService();
  final TextEditingController _searchController = TextEditingController();

  List<PhotoStudio> _photoStudios = [];
  List<PhotoStudio> _filteredPhotoStudios = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPhotoStudios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotoStudios() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final studios = await _photoStudioService.getPhotoStudios();

      if (mounted) {
        setState(() {
          _photoStudios = studios;
          _filteredPhotoStudios = studios;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _filterPhotoStudios(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPhotoStudios = _photoStudios;
      } else {
        _filteredPhotoStudios = _photoStudios
            .where(
              (studio) =>
                  studio.name.toLowerCase().contains(query.toLowerCase()) ||
                  studio.description
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  studio.address.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фотостудии'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO(developer): Переход к созданию фотостудии
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Создание фотостудии будет реализовано позже')),
              );
            },
            tooltip: 'Добавить фотостудию',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск фотостудий...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterPhotoStudios('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _filterPhotoStudios,
            ),
          ),

          // Список фотостудий
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPhotoStudios.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPhotoStudios,
                        child: ListView.builder(
                          itemCount: _filteredPhotoStudios.length,
                          itemBuilder: (context, index) {
                            final photoStudio = _filteredPhotoStudios[index];
                            return PhotoStudioCard(
                              photoStudio: photoStudio,
                              onTap: () => _showPhotoStudioDetails(photoStudio),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.photo_camera,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Фотостудии не найдены'
                  : 'Нет доступных фотостудий',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Попробуйте изменить поисковый запрос'
                  : 'Фотостудии появятся здесь, когда владельцы их добавят',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _filterPhotoStudios('');
                },
                child: const Text('Очистить поиск'),
              ),
            ],
          ],
        ),
      );

  void _showPhotoStudioDetails(PhotoStudio photoStudio) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      photoStudio.name,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Контент
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Изображения
                      if (photoStudio.hasImages) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photoStudio.images.length,
                            itemBuilder: (context, index) => Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[300],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photoStudio.images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 48),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Информация
                      _buildInfoSection(photoStudio),
                      const SizedBox(height: 16),

                      // Удобства
                      if (photoStudio.hasAmenities) ...[
                        _buildAmenitiesSection(photoStudio),
                        const SizedBox(height: 16),
                      ],

                      // Цены
                      _buildPricingSection(photoStudio),
                      const SizedBox(height: 16),

                      // Рабочие часы
                      _buildWorkingHoursSection(photoStudio),
                      const SizedBox(height: 16),

                      // Кнопка бронирования
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showBookingDialog(photoStudio);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Забронировать'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(PhotoStudio photoStudio) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.location_on, 'Адрес', photoStudio.address),
        _buildInfoRow(Icons.phone, 'Телефон', photoStudio.phone),
        _buildInfoRow(Icons.email, 'Email', photoStudio.email),
        if (photoStudio.rating > 0)
          _buildInfoRow(
            Icons.star,
            'Рейтинг',
            '${photoStudio.rating.toStringAsFixed(1)} (${photoStudio.reviewCount} отзывов)',
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildAmenitiesSection(PhotoStudio photoStudio) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Удобства',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: photoStudio.amenities
              .map(
                (amenity) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Text(amenity, style: theme.textTheme.bodySmall),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPricingSection(PhotoStudio photoStudio) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Цены',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (photoStudio.hourlyRate != null)
          _buildPricingRow('За час', photoStudio.getFormattedHourlyRate()),
        if (photoStudio.dailyRate != null)
          _buildPricingRow('За день', photoStudio.getFormattedDailyRate()),
      ],
    );
  }

  Widget _buildPricingRow(String label, String price) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              price,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildWorkingHoursSection(PhotoStudio photoStudio) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Рабочие часы',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...photoStudio.workingHours.keys.map((day) {
          final hours = photoStudio.workingHours[day];
          if (hours is Map) {
            final open = hours['open'] ?? 'Закрыто';
            final close = hours['close'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day),
                  Text(open == 'Закрыто' ? 'Закрыто' : '$open - $close')
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  void _showBookingDialog(PhotoStudio photoStudio) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Бронирование ${photoStudio.name}'),
        content: const Text('Функция бронирования будет реализована позже'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }
}
