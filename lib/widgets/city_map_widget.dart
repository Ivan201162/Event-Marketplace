import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/city_region.dart';

/// Виджет карты с городами
class CityMapWidget extends StatefulWidget {
  const CityMapWidget({
    super.key,
    this.selectedCity,
    this.onCitySelected,
    this.currentLocation,
    this.nearbyCities = const [],
    this.onLocationRequested,
    this.initialZoom = 6.0,
  });

  final CityRegion? selectedCity;
  final Function(CityRegion)? onCitySelected;
  final Position? currentLocation;
  final List<CityRegion> nearbyCities;
  final VoidCallback? onLocationRequested;
  final double initialZoom;

  @override
  State<CityMapWidget> createState() => _CityMapWidgetState();
}

class _CityMapWidgetState extends State<CityMapWidget> {
  late MapController _mapController;
  LatLng? _currentCenter;
  double _currentZoom = 6;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  void _initializeMap() {
    // Устанавливаем центр карты
    if (widget.selectedCity != null) {
      _currentCenter = LatLng(
        widget.selectedCity!.coordinates.latitude,
        widget.selectedCity!.coordinates.longitude,
      );
      _currentZoom = 10.0;
    } else if (widget.currentLocation != null) {
      _currentCenter = LatLng(widget.currentLocation!.latitude, widget.currentLocation!.longitude);
      _currentZoom = 8.0;
    } else {
      // Центр России
      _currentCenter = const LatLng(64.6863, 97.7453);
      _currentZoom = widget.initialZoom;
    }
  }

  @override
  void didUpdateWidget(CityMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedCity != oldWidget.selectedCity ||
        widget.currentLocation != oldWidget.currentLocation) {
      _updateMapCenter();
    }
  }

  void _updateMapCenter() {
    if (widget.selectedCity != null) {
      final newCenter = LatLng(
        widget.selectedCity!.coordinates.latitude,
        widget.selectedCity!.coordinates.longitude,
      );
      _mapController.move(newCenter, 10);
    } else if (widget.currentLocation != null) {
      final newCenter = LatLng(widget.currentLocation!.latitude, widget.currentLocation!.longitude);
      _mapController.move(newCenter, 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Карта
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter ?? const LatLng(64.6863, 97.7453),
            initialZoom: _currentZoom,
            minZoom: 3,
            maxZoom: 18,
            onTap: (tapPosition, point) {
              // Можно добавить логику для выбора точки на карте
            },
          ),
          children: [
            // Плитки карты (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eventmarketplace.app',
              maxZoom: 18,
            ),

            // Маркеры городов
            MarkerLayer(markers: _buildCityMarkers()),

            // Маркер текущего местоположения
            if (widget.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.currentLocation!.latitude,
                      widget.currentLocation!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Кнопки управления
        _buildMapControls(theme),

        // Индикатор загрузки
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  List<Marker> _buildCityMarkers() {
    final markers = <Marker>[];

    // Добавляем маркеры для ближайших городов
    for (final city in widget.nearbyCities) {
      markers.add(
        Marker(
          point: LatLng(city.coordinates.latitude, city.coordinates.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => widget.onCitySelected?.call(city),
            child: Container(
              decoration: BoxDecoration(
                color: _getCityMarkerColor(city),
                shape: BoxShape.circle,
                border: Border.all(
                  color: city == widget.selectedCity ? Colors.amber : Colors.white,
                  width: city == widget.selectedCity ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: Text(city.citySize.icon, style: const TextStyle(fontSize: 16))),
            ),
          ),
        ),
      );
    }

    // Добавляем маркер для выбранного города, если он не в списке ближайших
    if (widget.selectedCity != null &&
        !widget.nearbyCities.any((city) => city.id == widget.selectedCity!.id)) {
      markers.add(
        Marker(
          point: LatLng(
            widget.selectedCity!.coordinates.latitude,
            widget.selectedCity!.coordinates.longitude,
          ),
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: Icon(Icons.location_city, color: Colors.white, size: 24)),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildMapControls(ThemeData theme) => Positioned(
    right: 16,
    top: 16,
    child: Column(
      children: [
        // Кнопка "Мое местоположение"
        FloatingActionButton.small(
          onPressed: widget.onLocationRequested,
          backgroundColor: theme.cardColor,
          child: Icon(Icons.my_location, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),

        // Кнопка "Центр России"
        FloatingActionButton.small(
          onPressed: _centerOnRussia,
          backgroundColor: theme.cardColor,
          child: Icon(Icons.public, color: theme.colorScheme.primary),
        ),
      ],
    ),
  );

  void _centerOnRussia() {
    setState(() {
      _isLoading = true;
    });

    _mapController.move(const LatLng(64.6863, 97.7453), 4);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Color _getCityMarkerColor(CityRegion city) {
    if (city.isCapital) return Colors.amber;
    if (city.isMajorCity) return Colors.blue;

    switch (city.citySize) {
      case CitySize.megapolis:
        return Colors.purple;
      case CitySize.large:
        return Colors.blue;
      case CitySize.medium:
        return Colors.green;
      case CitySize.small:
        return Colors.orange;
      case CitySize.town:
        return Colors.grey;
    }
  }
}
