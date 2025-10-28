import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Сервис для работы с геолокацией
class GeolocationService {
  factory GeolocationService() => _instance;
  GeolocationService._internal();
  static final GeolocationService _instance = GeolocationService._internal();

  /// Получение текущего местоположения
  Future<Position?> getCurrentPosition() async {
    try {
      // Проверка разрешений
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Служба геолокации отключена');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Разрешение на геолокацию отклонено');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Разрешение на геолокацию отклонено навсегда');
      }

      // Получение местоположения
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Ошибка получения геолокации: $e');
      return null;
    }
  }

  /// Получение города по координатам
  Future<String?> getCityFromCoordinates(
      double latitude, double longitude,) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.locality ??
            placemark.administrativeArea ??
            'Неизвестный город';
      }

      return null;
    } catch (e) {
      print('Ошибка получения города: $e');
      return null;
    }
  }

  /// Получение города пользователя
  Future<String?> getUserCity() async {
    try {
      final position = await getCurrentPosition();
      if (position != null) {
        return await getCityFromCoordinates(
            position.latitude, position.longitude,);
      }
      return null;
    } catch (e) {
      print('Ошибка получения города пользователя: $e');
      return null;
    }
  }

  /// Расчет расстояния между двумя точками
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Получение ближайших специалистов
  Future<List<Map<String, dynamic>>> getNearbySpecialists(
    List<Map<String, dynamic>> specialists,
    double radiusKm,
  ) async {
    try {
      final userPosition = await getCurrentPosition();
      if (userPosition == null) return specialists;

      final nearbySpecialists = <Map<String, dynamic>>[];

      for (final specialist in specialists) {
        if (specialist['latitude'] != null && specialist['longitude'] != null) {
          final distance = calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            specialist['latitude'],
            specialist['longitude'],
          );

          if (distance <= radiusKm * 1000) {
            nearbySpecialists.add({
              ...specialist,
              'distance': distance / 1000, // в километрах
            });
          }
        }
      }

      // Сортировка по расстоянию
      nearbySpecialists.sort((a, b) => a['distance'].compareTo(b['distance']));

      return nearbySpecialists;
    } catch (e) {
      print('Ошибка получения ближайших специалистов: $e');
      return specialists;
    }
  }

  /// Проверка доступности геолокации
  Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      print('Ошибка проверки доступности геолокации: $e');
      return false;
    }
  }

  /// Запрос разрешения на геолокацию
  Future<bool> requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Ошибка запроса разрешения на геолокацию: $e');
      return false;
    }
  }
}
