import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/integration.dart';

/// Сервис интеграций
class IntegrationService {
  static final IntegrationService _instance = IntegrationService._internal();
  factory IntegrationService() => _instance;
  IntegrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все доступные интеграции
  Stream<List<Integration>> getAvailableIntegrations() {
    return _firestore
        .collection('integrations')
        .where('isEnabled', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Integration.fromDocument(doc)).toList();
    });
  }

  /// Получить интеграции пользователя
  Stream<List<IntegrationSettings>> getUserIntegrations(String userId) {
    return _firestore
        .collection('user_integrations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IntegrationSettings.fromDocument(doc))
          .toList();
    });
  }

  /// Подключить интеграцию
  Future<bool> connectIntegration(String integrationId, String userId,
      Map<String, dynamic> settings) async {
    try {
      final docRef = _firestore.collection('user_integrations').doc();

      final integrationSettings = IntegrationSettings(
        integrationId: integrationId,
        userId: userId,
        settings: settings,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(integrationSettings.toMap());

      // Создаем событие интеграции
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.connect,
        status: IntegrationEventStatus.success,
      );

      return true;
    } catch (e) {
      print('Ошибка подключения интеграции: $e');

      // Создаем событие ошибки
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.connect,
        status: IntegrationEventStatus.failed,
        errorMessage: e.toString(),
      );

      return false;
    }
  }

  /// Отключить интеграцию
  Future<bool> disconnectIntegration(
      String integrationId, String userId) async {
    try {
      final query = await _firestore
          .collection('user_integrations')
          .where('integrationId', isEqualTo: integrationId)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      // Создаем событие интеграции
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.disconnect,
        status: IntegrationEventStatus.success,
      );

      return true;
    } catch (e) {
      print('Ошибка отключения интеграции: $e');

      // Создаем событие ошибки
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.disconnect,
        status: IntegrationEventStatus.failed,
        errorMessage: e.toString(),
      );

      return false;
    }
  }

  /// Обновить настройки интеграции
  Future<bool> updateIntegrationSettings(String integrationId, String userId,
      Map<String, dynamic> settings) async {
    try {
      final query = await _firestore
          .collection('user_integrations')
          .where('integrationId', isEqualTo: integrationId)
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'settings': settings,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      return true;
    } catch (e) {
      print('Ошибка обновления настроек интеграции: $e');
      return false;
    }
  }

  /// Получить текущую геолокацию
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Получаем текущую позицию
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка получения геолокации: $e');
      return null;
    }
  }

  /// Получить адрес по координатам
  Future<AddressData?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return AddressData(
          street: placemark.street,
          city: placemark.locality,
          state: placemark.administrativeArea,
          country: placemark.country,
          postalCode: placemark.postalCode,
          formattedAddress:
              '${placemark.street}, ${placemark.locality}, ${placemark.country}',
        );
      }

      return null;
    } catch (e) {
      print('Ошибка получения адреса: $e');
      return null;
    }
  }

  /// Получить координаты по адресу
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Ошибка получения координат: $e');
      return null;
    }
  }

  /// Проверить подключение к интернету
  Future<bool> isConnectedToInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Ошибка проверки подключения: $e');
      return false;
    }
  }

  /// Получить тип подключения
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (e) {
      print('Ошибка получения типа подключения: $e');
      return ConnectivityResult.none;
    }
  }

  /// Поделиться контентом
  Future<bool> shareContent(String content, {String? subject}) async {
    try {
      await Share.share(
        content,
        subject: subject,
      );
      return true;
    } catch (e) {
      print('Ошибка шаринга: $e');
      return false;
    }
  }

  /// Поделиться файлом
  Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
      );
      return true;
    } catch (e) {
      print('Ошибка шаринга файла: $e');
      return false;
    }
  }

  /// Открыть URL
  Future<bool> openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка открытия URL: $e');
      return false;
    }
  }

  /// Отправить email
  Future<bool> sendEmail(String email, {String? subject, String? body}) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка отправки email: $e');
      return false;
    }
  }

  /// Совершить звонок
  Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка звонка: $e');
      return false;
    }
  }

  /// Отправить SMS
  Future<bool> sendSMS(String phoneNumber, {String? message}) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        query: message != null ? 'body=${Uri.encodeComponent(message)}' : null,
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка отправки SMS: $e');
      return false;
    }
  }

  /// Создать событие интеграции
  Future<void> _createIntegrationEvent({
    required String integrationId,
    required String userId,
    required IntegrationEventType type,
    required IntegrationEventStatus status,
    String? errorMessage,
  }) async {
    try {
      final eventRef = _firestore.collection('integration_events').doc();

      final event = IntegrationEvent(
        id: eventRef.id,
        integrationId: integrationId,
        userId: userId,
        type: type,
        status: status,
        errorMessage: errorMessage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await eventRef.set(event.toMap());
    } catch (e) {
      print('Ошибка создания события интеграции: $e');
    }
  }

  /// Кодировать параметры запроса
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Получить события интеграции пользователя
  Stream<List<IntegrationEvent>> getUserIntegrationEvents(String userId) {
    return _firestore
        .collection('integration_events')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IntegrationEvent.fromDocument(doc))
          .toList();
    });
  }

  /// Синхронизировать данные интеграции
  Future<bool> syncIntegrationData(String integrationId, String userId) async {
    try {
      // Создаем событие синхронизации
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.sync,
        status: IntegrationEventStatus.pending,
      );

      // TODO: Реализовать логику синхронизации для каждой интеграции
      // Это будет зависеть от типа интеграции

      // Обновляем статус события
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.sync,
        status: IntegrationEventStatus.success,
      );

      return true;
    } catch (e) {
      print('Ошибка синхронизации интеграции: $e');

      // Создаем событие ошибки
      await _createIntegrationEvent(
        integrationId: integrationId,
        userId: userId,
        type: IntegrationEventType.sync,
        status: IntegrationEventStatus.failed,
        errorMessage: e.toString(),
      );

      return false;
    }
  }

  /// Получить статистику интеграций
  Future<Map<String, dynamic>> getIntegrationStats(String userId) async {
    try {
      final events = await _firestore
          .collection('integration_events')
          .where('userId', isEqualTo: userId)
          .get();

      final totalEvents = events.docs.length;
      final successfulEvents = events.docs
          .where((doc) =>
              doc.data()['status'] == IntegrationEventStatus.success.name)
          .length;
      final failedEvents = events.docs
          .where((doc) =>
              doc.data()['status'] == IntegrationEventStatus.failed.name)
          .length;

      return {
        'totalEvents': totalEvents,
        'successfulEvents': successfulEvents,
        'failedEvents': failedEvents,
        'successRate':
            totalEvents > 0 ? (successfulEvents / totalEvents * 100) : 0.0,
      };
    } catch (e) {
      print('Ошибка получения статистики интеграций: $e');
      return {
        'totalEvents': 0,
        'successfulEvents': 0,
        'failedEvents': 0,
        'successRate': 0.0,
      };
    }
  }
}
