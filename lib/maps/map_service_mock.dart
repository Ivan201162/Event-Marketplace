import 'package:flutter/material.dart';
import '../models/event.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import 'map_service.dart';

/// Mock-реализация сервиса карт
class MapServiceMock implements MapService {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Maps are disabled via feature flag');
      return;
    }

    SafeLog.info('MapServiceMock: Initializing mock map service');
    _isInitialized = true;
  }

  @override
  bool get isAvailable => FeatureFlags.mapsEnabled && _isInitialized;

  @override
  Widget buildMap({
    required MapCoordinates center,
    double zoom = 15.0,
    List<MapMarker> markers = const [],
    bool showUserLocation = true,
    bool showTraffic = false,
    Function(MapMarker)? onMarkerTap,
    Function(MapCoordinates)? onMapTap,
    Function(MapCoordinates, double)? onCameraMove,
  }) {
    if (!FeatureFlags.mapsEnabled) {
      return _buildDisabledMap();
    }

    return _buildMockMap(
      center: center,
      zoom: zoom,
      markers: markers,
      onMarkerTap: onMarkerTap,
      onMapTap: onMapTap,
    );
  }

  @override
  Widget buildEventsMap({
    required List<Event> events,
    MapCoordinates? center,
    double zoom = 12.0,
    Function(Event)? onEventTap,
    Function(MapCoordinates)? onMapTap,
  }) {
    if (!FeatureFlags.mapsEnabled) {
      return _buildDisabledMap();
    }

    final markers = events.map((event) => createEventMarker(event)).toList();
    final mapCenter = center ?? _getEventsCenter(events);

    return _buildMockMap(
      center: mapCenter,
      zoom: zoom,
      markers: markers,
      onMarkerTap: (marker) {
        final event = events.firstWhere((e) => e.id == marker.id);
        onEventTap?.call(event);
      },
      onMapTap: onMapTap,
    );
  }

  @override
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Place search disabled');
      return [];
    }

    SafeLog.info('MapServiceMock: Searching places for "$query"');
    
    // Mock данные для поиска мест
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      PlaceSearchResult(
        id: '1',
        name: 'Москва, Красная площадь',
        address: 'Красная площадь, 1, Москва',
        coordinates: const MapCoordinates(latitude: 55.7539, longitude: 37.6208),
        placeId: 'mock_place_1',
      ),
      PlaceSearchResult(
        id: '2',
        name: 'Санкт-Петербург, Дворцовая площадь',
        address: 'Дворцовая площадь, Санкт-Петербург',
        coordinates: const MapCoordinates(latitude: 59.9386, longitude: 30.3141),
        placeId: 'mock_place_2',
      ),
    ];
  }

  @override
  Future<MapCoordinates?> geocodeAddress(String address) async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Geocoding disabled');
      return null;
    }

    SafeLog.info('MapServiceMock: Geocoding address "$address"');
    
    // Mock геокодирование
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (address.toLowerCase().contains('москва')) {
      return const MapCoordinates(latitude: 55.7558, longitude: 37.6176);
    } else if (address.toLowerCase().contains('санкт-петербург')) {
      return const MapCoordinates(latitude: 59.9311, longitude: 30.3609);
    }
    
    return const MapCoordinates(latitude: 55.7558, longitude: 37.6176); // Москва по умолчанию
  }

  @override
  Future<String?> reverseGeocode(MapCoordinates coordinates) async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Reverse geocoding disabled');
      return null;
    }

    SafeLog.info('MapServiceMock: Reverse geocoding coordinates $coordinates');
    
    // Mock обратное геокодирование
    await Future.delayed(const Duration(milliseconds: 300));
    
    return 'Москва, ул. Примерная, д. 1';
  }

  @override
  Future<List<MapCoordinates>?> getRoute(
    MapCoordinates start,
    MapCoordinates end, {
    String? travelMode,
  }) async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Route calculation disabled');
      return null;
    }

    SafeLog.info('MapServiceMock: Calculating route from $start to $end');
    
    // Mock маршрут
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      start,
      MapCoordinates(
        latitude: (start.latitude + end.latitude) / 2,
        longitude: (start.longitude + end.longitude) / 2,
      ),
      end,
    ];
  }

  @override
  Future<double?> getDistance(
    MapCoordinates start,
    MapCoordinates end,
  ) async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Distance calculation disabled');
      return null;
    }

    SafeLog.info('MapServiceMock: Calculating distance from $start to $end');
    
    // Mock расстояние (простая формула)
    await Future.delayed(const Duration(milliseconds: 200));
    
    final latDiff = start.latitude - end.latitude;
    final lngDiff = start.longitude - end.longitude;
    final distance = (latDiff * latDiff + lngDiff * lngDiff).abs() * 111000; // Примерно в метрах
    
    return distance;
  }

  @override
  Future<MapCoordinates?> getCurrentLocation() async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Current location disabled');
      return null;
    }

    SafeLog.info('MapServiceMock: Getting current location');
    
    // Mock текущее местоположение
    await Future.delayed(const Duration(milliseconds: 1000));
    
    return const MapCoordinates(latitude: 55.7558, longitude: 37.6176); // Москва
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Location permission disabled');
      return false;
    }

    SafeLog.info('MapServiceMock: Requesting location permission');
    
    // Mock разрешение
    await Future.delayed(const Duration(milliseconds: 500));
    
    return true;
  }

  @override
  Future<bool> hasLocationPermission() async {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Location permission check disabled');
      return false;
    }

    SafeLog.info('MapServiceMock: Checking location permission');
    
    // Mock проверка разрешения
    await Future.delayed(const Duration(milliseconds: 100));
    
    return true;
  }

  @override
  MapMarker createEventMarker(Event event) {
    return MapMarker(
      id: event.id,
      coordinates: _parseEventLocation(event.location),
      title: event.title,
      description: event.description,
      icon: Icons.event,
      color: Colors.blue,
      data: {'event': event},
    );
  }

  @override
  MapMarker createUserMarker(MapCoordinates coordinates, String title) {
    return MapMarker(
      id: 'user_${coordinates.latitude}_${coordinates.longitude}',
      coordinates: coordinates,
      title: title,
      icon: Icons.person,
      color: Colors.red,
    );
  }

  @override
  void animateToLocation(MapCoordinates coordinates, {double? zoom}) {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Camera animation disabled');
      return;
    }

    SafeLog.info('MapServiceMock: Animating to $coordinates');
  }

  @override
  void setMapStyle(String style) {
    if (!FeatureFlags.mapsEnabled) {
      SafeLog.info('MapServiceMock: Map style setting disabled');
      return;
    }

    SafeLog.info('MapServiceMock: Setting map style to $style');
  }

  @override
  List<String> getAvailableStyles() {
    if (!FeatureFlags.mapsEnabled) {
      return [];
    }

    return ['normal', 'satellite', 'terrain', 'hybrid'];
  }

  @override
  void dispose() {
    SafeLog.info('MapServiceMock: Disposing mock map service');
    _isInitialized = false;
  }

  /// Построить отключенную карту
  Widget _buildDisabledMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Карты отключены',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Функция карт временно недоступна',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить mock карту
  Widget _buildMockMap({
    required MapCoordinates center,
    required double zoom,
    required List<MapMarker> markers,
    Function(MapMarker)? onMarkerTap,
    Function(MapCoordinates)? onMapTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Stack(
        children: [
          // Mock карта
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Colors.green[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mock Карта',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Центр: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  'Масштаб: ${zoom.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
                if (markers.isNotEmpty)
                  Text(
                    'Маркеров: ${markers.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
          ),
          
          // Маркеры
          ...markers.map((marker) => Positioned(
            left: 50 + (marker.coordinates.longitude - center.longitude) * 100,
            top: 50 + (marker.coordinates.latitude - center.latitude) * 100,
            child: GestureDetector(
              onTap: () => onMarkerTap?.call(marker),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: marker.color ?? Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  marker.icon ?? Icons.place,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// Получить центр событий
  MapCoordinates _getEventsCenter(List<Event> events) {
    if (events.isEmpty) {
      return const MapCoordinates(latitude: 55.7558, longitude: 37.6176); // Москва по умолчанию
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final event in events) {
      final coords = _parseEventLocation(event.location);
      totalLat += coords.latitude;
      totalLng += coords.longitude;
      count++;
    }

    return MapCoordinates(
      latitude: totalLat / count,
      longitude: totalLng / count,
    );
  }

  /// Парсить местоположение события в координаты
  MapCoordinates _parseEventLocation(String location) {
    // Простой парсинг адреса в координаты
    if (location.toLowerCase().contains('москва')) {
      return const MapCoordinates(latitude: 55.7558, longitude: 37.6176);
    } else if (location.toLowerCase().contains('санкт-петербург')) {
      return const MapCoordinates(latitude: 59.9311, longitude: 30.3609);
    } else if (location.toLowerCase().contains('екатеринбург')) {
      return const MapCoordinates(latitude: 56.8431, longitude: 60.6454);
    } else if (location.toLowerCase().contains('новосибирск')) {
      return const MapCoordinates(latitude: 55.0084, longitude: 82.9357);
    }
    
    // По умолчанию Москва
    return const MapCoordinates(latitude: 55.7558, longitude: 37.6176);
  }
}
