import 'package:flutter/material.dart';

import '../models/city_region.dart';

/// Виджет списка городов
class CityListWidget extends StatelessWidget {
  const CityListWidget({
    super.key,
    required this.cities,
    this.onCitySelected,
    this.showDistance = false,
    this.userLocation,
    this.emptyMessage = 'Города не найдены',
  });

  final List<CityRegion> cities;
  final Function(CityRegion)? onCitySelected;
  final bool showDistance;
  final Coordinates? userLocation;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return _buildCityCard(context, city);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_city_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(BuildContext context, CityRegion city) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildCityIcon(city, theme),
        title: Text(
          city.cityName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: city.isCapital ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              city.regionName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _buildCityInfo(city, theme),
            if (showDistance && userLocation != null)
              _buildDistanceInfo(city, theme),
          ],
        ),
        trailing: _buildTrailingInfo(city, theme),
        onTap: () => onCitySelected?.call(city),
      ),
    );
  }

  Widget _buildCityIcon(CityRegion city, ThemeData theme) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getCityColor(city, theme).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getCityColor(city, theme).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            city.citySize.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );

  Widget _buildCityInfo(CityRegion city, ThemeData theme) => Row(
        children: [
          if (city.population > 0) ...[
            Icon(
              Icons.people,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatPopulation(city.population),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (city.totalSpecialists > 0) ...[
            Icon(
              Icons.work,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${city.totalSpecialists} специалистов',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );

  Widget _buildDistanceInfo(CityRegion city, ThemeData theme) {
    if (userLocation == null) return const SizedBox.shrink();

    final distance = city.coordinates.distanceTo(userLocation!);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDistance(distance),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingInfo(CityRegion city, ThemeData theme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (city.isCapital)
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            )
          else if (city.isMajorCity)
            Icon(
              Icons.star_border,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          if (city.avgSpecialistRating > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rate,
                  size: 14,
                  color: Colors.amber,
                ),
                const SizedBox(width: 2),
                Text(
                  city.avgSpecialistRating.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      );

  Color _getCityColor(CityRegion city, ThemeData theme) {
    if (city.isCapital) return Colors.amber;
    if (city.isMajorCity) return theme.colorScheme.primary;

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

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}М';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}К';
    } else {
      return population.toString();
    }
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} м';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} км';
    } else {
      return '${distanceKm.round()} км';
    }
  }
}
