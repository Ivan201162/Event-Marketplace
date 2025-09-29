import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../maps/map_service.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';
import '../providers/map_providers.dart';

/// Экран карты событий
class EventsMapPage extends ConsumerStatefulWidget {
  const EventsMapPage({super.key});

  @override
  ConsumerState<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends ConsumerState<EventsMapPage> {
  MapCoordinates? _currentLocation;
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Загружаем события
      final eventsAsync = ref.read(eventsProvider.future);
      final events = await eventsAsync;

      // Загружаем текущее местоположение, если карты включены
      MapCoordinates? currentLocation;
      if (FeatureFlags.mapsEnabled) {
        final locationAsync = ref.read(currentLocationProvider.future);
        currentLocation = await locationAsync;
      }

      setState(() {
        _events = events;
        _currentLocation = currentLocation;
        _isLoading = false;
      });

      SafeLog.info('EventsMapPage: Loaded ${events.length} events');
    } catch (e, stackTrace) {
      SafeLog.error('EventsMapPage: Error loading data', e, stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Карта событий'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
            if (FeatureFlags.mapsEnabled)
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _requestLocationPermission,
              ),
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка карты...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (!FeatureFlags.mapsEnabled) {
      return _buildMapsDisabledState();
    }

    return _buildMapContent();
  }

  Widget _buildMapsDisabledState() => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 120,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 32),
            Text(
              'Карты временно недоступны',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Функция карт отключена в настройках приложения. Вы можете просматривать события в списке.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.list),
              label: const Text('Просмотреть список событий'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
      );

  Widget _buildErrorState() => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 32),
            Text(
              'Ошибка загрузки карты',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Неизвестная ошибка',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
          ],
        ),
      );

  Widget _buildMapContent() {
    final mapService = ref.read(mapServiceProvider);

    if (!mapService.isAvailable) {
      return _buildMapsDisabledState();
    }

    return Column(
      children: [
        // Панель фильтров
        _buildFiltersPanel(),

        // Карта
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mapService.buildEventsMap(
                events: _events,
                center: _currentLocation,
                onEventTap: _onEventTap,
                onMapTap: _onMapTap,
              ),
            ),
          ),
        ),

        // Панель информации
        _buildInfoPanel(),
      ],
    );
  }

  Widget _buildFiltersPanel() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Поиск событий на карте...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.filter_list),
              tooltip: 'Фильтры',
            ),
          ],
        ),
      );

  Widget _buildInfoPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Информация о карте',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Событий на карте',
                    '${_events.length}',
                    Icons.event,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Текущее местоположение',
                    _currentLocation != null ? 'Определено' : 'Не определено',
                    Icons.my_location,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Статус карт',
                    FeatureFlags.mapsEnabled ? 'Включены' : 'Отключены',
                    FeatureFlags.mapsEnabled ? Icons.map : Icons.map_outlined,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Тип карты',
                    'Mock карта',
                    Icons.map,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInfoItem(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _onEventTap(Event event) {
    SafeLog.info('EventsMapPage: Event tapped: ${event.title}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty) ...[
              Text(
                'Описание:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(event.description),
              const SizedBox(height: 12),
            ],
            Text(
              'Местоположение:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(event.location),
            const SizedBox(height: 12),
            Text(
              'Дата:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text('${event.date.day}.${event.date.month}.${event.date.year}'),
            const SizedBox(height: 12),
            Text(
              'Цена:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text('${event.price} ₽'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Переход к детальной странице события
            },
            child: const Text('Подробнее'),
          ),
        ],
      ),
    );
  }

  void _onMapTap(MapCoordinates coordinates) {
    SafeLog.info('EventsMapPage: Map tapped at $coordinates');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Координаты: ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSearchChanged(String query) {
    SafeLog.info('EventsMapPage: Search query changed: $query');
    // TODO: Реализовать поиск событий на карте
  }

  void _showFilters() {
    SafeLog.info('EventsMapPage: Showing filters');

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фильтры карты',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('Фильтры будут добавлены в следующих версиях'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      final mapService = ref.read(mapServiceProvider);
      final hasPermission = await mapService.requestLocationPermission();

      if (hasPermission) {
        final location = await mapService.getCurrentLocation();
        setState(() {
          _currentLocation = location;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Местоположение определено'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на местоположение не предоставлено'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error('EventsMapPage: Error requesting location', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка определения местоположения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
