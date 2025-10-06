import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integration.dart';
import '../providers/integration_providers.dart';
import '../services/integration_service.dart';

/// Экран настроек геолокации
class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() =>
      _LocationSettingsScreenState();
}

class _LocationSettingsScreenState
    extends ConsumerState<LocationSettingsScreen> {
  final IntegrationService _integrationService = IntegrationService();

  bool _locationEnabled = false;
  bool _autoLocationEnabled = false;
  double _locationAccuracy = 100; // в метрах

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Настройки геолокации'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основные настройки
              _buildMainSettings(),

              const SizedBox(height: 24),

              // Точность
              _buildAccuracySettings(),

              const SizedBox(height: 24),

              // Текущее местоположение
              _buildCurrentLocation(),

              const SizedBox(height: 24),

              // История местоположений
              _buildLocationHistory(),
            ],
          ),
        ),
      );

  Widget _buildMainSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Основные настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Включить геолокацию
              SwitchListTile(
                title: const Text('Включить геолокацию'),
                subtitle: const Text(
                  'Разрешить приложению использовать ваше местоположение',
                ),
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                  if (value) {
                    _requestLocationPermission();
                  }
                },
              ),

              const Divider(),

              // Автоматическое определение местоположения
              SwitchListTile(
                title: const Text('Автоматическое определение'),
                subtitle: const Text(
                  'Автоматически определять местоположение при создании событий',
                ),
                value: _autoLocationEnabled,
                onChanged: _locationEnabled
                    ? (value) {
                        setState(() {
                          _autoLocationEnabled = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      );

  Widget _buildAccuracySettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Точность определения',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Точность: ${_locationAccuracy.toInt()} метров',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _locationAccuracy,
                min: 10,
                max: 1000,
                divisions: 99,
                label: '${_locationAccuracy.toInt()} м',
                onChanged: _locationEnabled
                    ? (value) {
                        setState(() {
                          _locationAccuracy = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Высокая точность\n(10 м)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Низкая точность\n(1000 м)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildCurrentLocation() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Текущее местоположение',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final locationAsync = ref.watch(currentLocationProvider);

                  return locationAsync.when(
                    data: (location) {
                      if (location == null) {
                        return Column(
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Местоположение не определено',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Определить местоположение'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Местоположение определено',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLocationInfo(location),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _getAddressFromLocation(location),
                                  icon: const Icon(Icons.map),
                                  label: const Text('Показать на карте'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Обновить'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Column(
                      children: [
                        const Icon(
                          Icons.error,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildLocationInfo(LocationData location) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Широта', location.latitude.toStringAsFixed(6)),
            _buildInfoRow('Долгота', location.longitude.toStringAsFixed(6)),
            if (location.accuracy != null)
              _buildInfoRow('Точность', '${location.accuracy!.toInt()} м'),
            if (location.altitude != null)
              _buildInfoRow('Высота', '${location.altitude!.toInt()} м'),
            if (location.speed != null)
              _buildInfoRow('Скорость', '${location.speed!.toInt()} м/с'),
            _buildInfoRow('Время', _formatDateTime(location.timestamp)),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildLocationHistory() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'История местоположений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearLocationHistory,
                    child: const Text('Очистить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TODO(developer): Реализовать отображение истории местоположений
              const Center(
                child: Text(
                  'История местоположений пока не реализована',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _requestLocationPermission() async {
    try {
      final location = await _integrationService.getCurrentLocation();
      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на геолокацию получено'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить разрешение на геолокацию'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _integrationService.getCurrentLocation();
      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Местоположение обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось определить местоположение'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getAddressFromLocation(LocationData location) async {
    try {
      final address = await _integrationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Адрес'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Адрес: $address'),
              const SizedBox(height: 8),
              const Text(
                'Полный адрес:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(address),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearLocationHistory() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text(
          'Вы уверены, что хотите очистить историю местоположений?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать очистку истории
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('История очищена')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}
