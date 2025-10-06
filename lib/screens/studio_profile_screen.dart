import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo_studio.dart';
import '../providers/auth_providers.dart';
import '../services/photo_studio_service.dart';

/// Экран профиля фотостудии
class StudioProfileScreen extends ConsumerStatefulWidget {
  const StudioProfileScreen({
    super.key,
    required this.studioId,
  });

  final String studioId;

  @override
  ConsumerState<StudioProfileScreen> createState() =>
      _StudioProfileScreenState();
}

class _StudioProfileScreenState extends ConsumerState<StudioProfileScreen>
    with TickerProviderStateMixin {
  final PhotoStudioService _photoStudioService = PhotoStudioService();

  PhotoStudio? _photoStudio;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPhotoStudio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotoStudio() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final studio = await _photoStudioService.getPhotoStudio(widget.studioId);

      if (mounted) {
        setState(() {
          _photoStudio = studio;
          _isLoading = false;
          if (studio == null) {
            _error = 'Фотостудия не найдена';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка загрузки: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Загрузка...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _photoStudio == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Фотостудия не найдена',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPhotoStudio,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            _photoStudio!.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          background: Stack(
            fit: StackFit.expand,
            children: [
              if (_photoStudio!.coverImageUrl != null)
                Image.network(
                  _photoStudio!.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImage(),
                )
              else
                _buildPlaceholderImage(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStudio,
            tooltip: 'Поделиться',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: 'В избранное',
          ),
        ],
      );

  Widget _buildPlaceholderImage() => Container(
        color: Theme.of(context).colorScheme.primary,
        child: const Center(
          child: Icon(
            Icons.photo_camera,
            size: 64,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название и статус
          Row(
            children: [
              Expanded(
                child: Text(
                  _photoStudio!.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_photoStudio!.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Проверено',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Рейтинг и отзывы
          Row(
            children: [
              if (_photoStudio!.rating > 0) ...[
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  _photoStudio!.rating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_photoStudio!.reviewCount} отзывов)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ] else ...[
                Text(
                  'Нет отзывов',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Адрес
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _photoStudio!.address,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Описание
          Text(
            _photoStudio!.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Container(
        color: Theme.of(context).colorScheme.surface,
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Галерея'),
            Tab(text: 'Цены'),
            Tab(text: 'Расписание'),
            Tab(text: 'Отзывы'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      );

  Widget _buildTabContent() => SizedBox(
        height: 400,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGalleryTab(),
            _buildPricingTab(),
            _buildScheduleTab(),
            _buildReviewsTab(),
          ],
        ),
      );

  Widget _buildGalleryTab() {
    if (!_photoStudio!.hasImages) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Галерея пуста',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photoStudio!.images.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _photoStudio!.images[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildPricingTab() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цены',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_photoStudio!.hourlyRate != null) ...[
            _buildPricingCard(
              'За час',
              _photoStudio!.getFormattedHourlyRate(),
              Icons.access_time,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          if (_photoStudio!.dailyRate != null) ...[
            _buildPricingCard(
              'За день',
              _photoStudio!.getFormattedDailyRate(),
              Icons.calendar_today,
              Colors.green,
            ),
            const SizedBox(height: 12),
          ],

          // Пакеты
          if (_photoStudio!.pricing.containsKey('packages')) ...[
            Text(
              'Пакеты',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._photoStudio!.pricing['packages'].keys.map((packageName) {
              final price = _photoStudio!.pricing['packages'][packageName];
              return _buildPricingCard(
                packageName,
                '${price.toStringAsFixed(0)} ₽',
                Icons.inventory,
                Colors.orange,
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            price,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Рабочие часы',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._photoStudio!.workingHours.keys.map((day) {
            final hours = _photoStudio!.workingHours[day];
            if (hours is Map) {
              final open = hours['open'] ?? 'Закрыто';
              final close = hours['close'] ?? '';
              final isOpen = open != 'Закрыто';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDayDisplayName(day),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      isOpen ? '$open - $close' : 'Закрыто',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  String _getDayDisplayName(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Понедельник';
      case 'tuesday':
        return 'Вторник';
      case 'wednesday':
        return 'Среда';
      case 'thursday':
        return 'Четверг';
      case 'friday':
        return 'Пятница';
      case 'saturday':
        return 'Суббота';
      case 'sunday':
        return 'Воскресенье';
      default:
        return day;
    }
  }

  Widget _buildReviewsTab() {
    // TODO(developer): Реализовать отзывы
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Отзывы будут добавлены позже',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Цена
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'От',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _photoStudio!.hourlyRate != null
                        ? _photoStudio!.getFormattedHourlyRate()
                        : 'Цена не указана',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Кнопка бронирования
            ElevatedButton(
              onPressed: _showBookingDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Забронировать'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareStudio() {
    // TODO(developer): Реализовать поделиться
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция поделиться будет реализована позже'),
      ),
    );
  }

  void _toggleFavorite() {
    // TODO(developer): Реализовать избранное
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция избранного будет реализована позже'),
      ),
    );
  }

  void _showBookingDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Бронирование ${_photoStudio!.name}'),
        content: const Text('Функция бронирования будет реализована позже'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
