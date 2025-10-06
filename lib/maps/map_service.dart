import 'package:flutter/material.dart';
import '../models/event.dart';

/// Координаты на карте
class MapCoordinates {
  const MapCoordinates({
    required this.latitude,
    required this.longitude,
  });
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapCoordinates &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'MapCoordinates(lat: $latitude, lng: $longitude)';
}

/// Маркер на карте
class MapMarker {
  const MapMarker({
    required this.id,
    required this.coordinates,
    required this.title,
    this.description,
    this.icon,
    this.color,
    this.data,
  });
  final String id;
  final MapCoordinates coordinates;
  final String title;
  final String? description;
  final IconData? icon;
  final Color? color;
  final Map<String, dynamic>? data;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapMarker &&
        other.id == id &&
        other.coordinates == coordinates &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, coordinates, title);
}

/// Результат поиска мест
class PlaceSearchResult {
  const PlaceSearchResult({
    required this.id,
    required this.name,
    this.address,
    required this.coordinates,
    this.placeId,
  });
  final String id;
  final String name;
  final String? address;
  final MapCoordinates coordinates;
  final String? placeId;
}

/// Абстрактный сервис для работы с картами
abstract class MapService {
  /// Инициализация сервиса карт
  Future<void> initialize();

  /// Проверить, доступны ли карты
  bool get isAvailable;

  /// Получить виджет карты
  Widget buildMap({
    required MapCoordinates center,
    double zoom = 15.0,
    List<MapMarker> markers = const [],
    bool showUserLocation = true,
    bool showTraffic = false,
    void Function(MapMarker)? onMarkerTap,
    void Function(MapCoordinates)? onMapTap,
    void Function(MapCoordinates, double)? onCameraMove,
  });

  /// Получить виджет карты для событий
  Widget buildEventsMap({
    required List<Event> events,
    MapCoordinates? center,
    double zoom = 12.0,
    void Function(Event)? onEventTap,
    void Function(MapCoordinates)? onMapTap,
  });

  /// Поиск мест по запросу
  Future<List<PlaceSearchResult>> searchPlaces(String query);

  /// Получить координаты по адресу (геокодирование)
  Future<MapCoordinates?> geocodeAddress(String address);

  /// Получить адрес по координатам (обратное геокодирование)
  Future<String?> reverseGeocode(MapCoordinates coordinates);

  /// Получить маршрут между двумя точками
  Future<List<MapCoordinates>?> getRoute(
    MapCoordinates start,
    MapCoordinates end, {
    String? travelMode,
  });

  /// Получить расстояние между двумя точками
  Future<double?> getDistance(
    MapCoordinates start,
    MapCoordinates end,
  );

  /// Получить текущее местоположение пользователя
  Future<MapCoordinates?> getCurrentLocation();

  /// Запросить разрешение на доступ к местоположению
  Future<bool> requestLocationPermission();

  /// Проверить разрешение на доступ к местоположению
  Future<bool> hasLocationPermission();

  /// Создать маркер для события
  MapMarker createEventMarker(Event event);

  /// Создать маркер для пользователя
  MapMarker createUserMarker(MapCoordinates coordinates, String title);

  /// Анимировать камеру к координатам
  void animateToLocation(MapCoordinates coordinates, {double? zoom});

  /// Установить стиль карты
  void setMapStyle(String style);

  /// Получить доступные стили карты
  List<String> getAvailableStyles();

  /// Очистить ресурсы
  void dispose();
}
