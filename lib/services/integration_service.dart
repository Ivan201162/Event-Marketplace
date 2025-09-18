import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/external_integration.dart';

/// Сервис интеграций с внешними сервисами
class IntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final IntegrationService _instance = IntegrationService._internal();
  factory IntegrationService() => _instance;
  IntegrationService._internal();

  final Map<String, ExternalIntegration> _integrations = {};
  final Map<String, Timer> _syncTimers = {};

  /// Инициализация сервиса интеграций
  Future<void> initialize() async {
    try {
      await _loadIntegrations();
      await _startActiveIntegrations();

      if (kDebugMode) {
        print('Integration service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса интеграций: $e');
      }
    }
  }

  /// Создать интеграцию
  Future<String> createIntegration({
    required String name,
    required String description,
    required IntegrationType type,
    required String baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? configuration,
    AuthenticationType authType = AuthenticationType.none,
    Map<String, String>? credentials,
    String? createdBy,
  }) async {
    try {
      final integrationId = _uuid.v4();
      final now = DateTime.now();

      final integration = ExternalIntegration(
        id: integrationId,
        name: name,
        description: description,
        type: type,
        baseUrl: baseUrl,
        headers: headers ?? {},
        configuration: configuration ?? {},
        authType: authType,
        credentials: credentials ?? {},
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .set(integration.toMap());
      _integrations[integrationId] = integration;

      if (kDebugMode) {
        print('Integration created: $name');
      }

      return integrationId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания интеграции: $e');
      }
      rethrow;
    }
  }

  /// Активировать интеграцию
  Future<void> activateIntegration(String integrationId) async {
    try {
      final integration = _integrations[integrationId];
      if (integration == null) {
        throw Exception('Интеграция не найдена');
      }

      // Тестируем подключение
      await _testConnection(integration);

      // Обновляем статус
      final updatedIntegration = integration.copyWith(
        status: IntegrationStatus.active,
        updatedAt: DateTime.now(),
        lastError: null,
      );

      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .update({
        'status': IntegrationStatus.active.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastError': null,
      });

      _integrations[integrationId] = updatedIntegration;

      // Запускаем синхронизацию
      await _startIntegrationSync(integrationId);

      if (kDebugMode) {
        print('Integration activated: ${integration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка активации интеграции: $e');
      }
      rethrow;
    }
  }

  /// Деактивировать интеграцию
  Future<void> deactivateIntegration(String integrationId) async {
    try {
      final integration = _integrations[integrationId];
      if (integration == null) return;

      // Останавливаем синхронизацию
      _stopIntegrationSync(integrationId);

      // Обновляем статус
      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .update({
        'status': IntegrationStatus.inactive.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _integrations[integrationId] = integration.copyWith(
        status: IntegrationStatus.inactive,
        updatedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Integration deactivated: ${integration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка деактивации интеграции: $e');
      }
      rethrow;
    }
  }

  /// Тестировать подключение
  Future<void> _testConnection(ExternalIntegration integration) async {
    try {
      final url = Uri.parse('${integration.baseUrl}/health');
      final headers = Map<String, String>.from(integration.headers);

      // Добавляем аутентификацию
      _addAuthentication(headers, integration);

      final response = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }

  /// Добавить аутентификацию в заголовки
  void _addAuthentication(
      Map<String, String> headers, ExternalIntegration integration) {
    switch (integration.authType) {
      case AuthenticationType.apiKey:
        final apiKey = integration.credentials['apiKey'];
        if (apiKey != null) {
          headers['X-API-Key'] = apiKey;
        }
        break;
      case AuthenticationType.basic:
        final username = integration.credentials['username'];
        final password = integration.credentials['password'];
        if (username != null && password != null) {
          final credentials = base64.encode(utf8.encode('$username:$password'));
          headers['Authorization'] = 'Basic $credentials';
        }
        break;
      case AuthenticationType.bearer:
        final token = integration.credentials['token'];
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        break;
      case AuthenticationType.oauth2:
        final token = integration.credentials['accessToken'];
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        break;
      case AuthenticationType.custom:
        // Пользовательская аутентификация
        for (final entry in integration.credentials.entries) {
          headers[entry.key] = entry.value;
        }
        break;
      case AuthenticationType.none:
        // Без аутентификации
        break;
    }
  }

  /// Запустить синхронизацию интеграции
  Future<void> _startIntegrationSync(String integrationId) async {
    try {
      final integration = _integrations[integrationId];
      if (integration == null || !integration.isActive) return;

      // Останавливаем существующий таймер
      _stopIntegrationSync(integrationId);

      // Получаем интервал синхронизации
      final syncInterval = integration.configuration['syncInterval'] as int? ??
          300; // 5 минут по умолчанию

      // Создаем новый таймер
      final timer = Timer.periodic(Duration(seconds: syncInterval), (_) {
        _performSync(integrationId);
      });

      _syncTimers[integrationId] = timer;

      if (kDebugMode) {
        print('Sync started for integration: ${integration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запуска синхронизации: $e');
      }
    }
  }

  /// Остановить синхронизацию интеграции
  void _stopIntegrationSync(String integrationId) {
    final timer = _syncTimers[integrationId];
    if (timer != null) {
      timer.cancel();
      _syncTimers.remove(integrationId);
    }
  }

  /// Выполнить синхронизацию
  Future<void> _performSync(String integrationId) async {
    try {
      final integration = _integrations[integrationId];
      if (integration == null || !integration.isActive) return;

      // Обновляем время последней синхронизации
      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .update({
        'lastSyncAt': Timestamp.fromDate(DateTime.now()),
        'lastError': null,
      });

      // Выполняем синхронизацию в зависимости от типа
      switch (integration.type) {
        case IntegrationType.api:
          await _syncApiData(integration);
          break;
        case IntegrationType.webhook:
          // Webhook не требует активной синхронизации
          break;
        case IntegrationType.sftp:
          await _syncSftpData(integration);
          break;
        case IntegrationType.email:
          await _syncEmailData(integration);
          break;
        case IntegrationType.sms:
          await _syncSmsData(integration);
          break;
        case IntegrationType.payment:
          await _syncPaymentData(integration);
          break;
        case IntegrationType.calendar:
          await _syncCalendarData(integration);
          break;
        case IntegrationType.social:
          await _syncSocialData(integration);
          break;
        case IntegrationType.analytics:
          await _syncAnalyticsData(integration);
          break;
        case IntegrationType.crm:
          await _syncCrmData(integration);
          break;
        case IntegrationType.erp:
          await _syncErpData(integration);
          break;
        case IntegrationType.other:
          await _syncOtherData(integration);
          break;
      }

      if (kDebugMode) {
        print('Sync completed for integration: ${integration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка синхронизации: $e');
      }

      // Обновляем ошибку
      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .update({
        'lastError': e.toString(),
        'status': IntegrationStatus.error.toString().split('.').last,
      });

      _integrations[integrationId] = _integrations[integrationId]!.copyWith(
        lastError: e.toString(),
        status: IntegrationStatus.error,
      );
    }
  }

  /// Синхронизация API данных
  Future<void> _syncApiData(ExternalIntegration integration) async {
    try {
      final endpoints =
          integration.configuration['endpoints'] as List<dynamic>? ?? [];

      for (final endpoint in endpoints) {
        final endpointData = endpoint as Map<String, dynamic>;
        final url = endpointData['url'] as String;
        final method = endpointData['method'] as String? ?? 'GET';
        final dataType = endpointData['dataType'] as String? ?? 'json';

        final fullUrl = Uri.parse('${integration.baseUrl}$url');
        final headers = Map<String, String>.from(integration.headers);
        _addAuthentication(headers, integration);

        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(fullUrl, headers: headers);
            break;
          case 'POST':
            final body = endpointData['body'] as String?;
            response = await http.post(fullUrl, headers: headers, body: body);
            break;
          case 'PUT':
            final body = endpointData['body'] as String?;
            response = await http.put(fullUrl, headers: headers, body: body);
            break;
          case 'DELETE':
            response = await http.delete(fullUrl, headers: headers);
            break;
          default:
            throw Exception('Неподдерживаемый HTTP метод: $method');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Обрабатываем ответ
          await _processApiResponse(integration, endpointData, response);
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка синхронизации API: $e');
      }
      rethrow;
    }
  }

  /// Обработать ответ API
  Future<void> _processApiResponse(
    ExternalIntegration integration,
    Map<String, dynamic> endpointData,
    http.Response response,
  ) async {
    try {
      final dataType = endpointData['dataType'] as String? ?? 'json';
      final syncDirection = endpointData['direction'] as String? ?? 'inbound';

      if (dataType == 'json') {
        final data = json.decode(response.body);
        await _processJsonData(integration, endpointData, data, syncDirection);
      } else if (dataType == 'xml') {
        // TODO: Обработка XML
      } else if (dataType == 'csv') {
        // TODO: Обработка CSV
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обработки ответа API: $e');
      }
      rethrow;
    }
  }

  /// Обработать JSON данные
  Future<void> _processJsonData(
    ExternalIntegration integration,
    Map<String, dynamic> endpointData,
    dynamic data,
    String syncDirection,
  ) async {
    try {
      final collection = endpointData['collection'] as String?;
      if (collection == null) return;

      if (syncDirection == 'inbound') {
        // Входящая синхронизация - сохраняем данные в Firestore
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              await _firestore.collection(collection).add({
                ...item,
                'integrationId': integration.id,
                'syncedAt': Timestamp.fromDate(DateTime.now()),
              });
            }
          }
        } else if (data is Map<String, dynamic>) {
          await _firestore.collection(collection).add({
            ...data,
            'integrationId': integration.id,
            'syncedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      } else if (syncDirection == 'outbound') {
        // Исходящая синхронизация - отправляем данные из Firestore
        final snapshot = await _firestore
            .collection(collection)
            .where('integrationId', isEqualTo: integration.id)
            .get();

        for (final doc in snapshot.docs) {
          final docData = doc.data();
          docData.remove('integrationId');
          docData.remove('syncedAt');

          // Отправляем данные
          await _sendDataToExternalService(integration, endpointData, docData);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обработки JSON данных: $e');
      }
      rethrow;
    }
  }

  /// Отправить данные во внешний сервис
  Future<void> _sendDataToExternalService(
    ExternalIntegration integration,
    Map<String, dynamic> endpointData,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = endpointData['url'] as String;
      final method = endpointData['method'] as String? ?? 'POST';

      final fullUrl = Uri.parse('${integration.baseUrl}$url');
      final headers = Map<String, String>.from(integration.headers);
      _addAuthentication(headers, integration);

      final body = json.encode(data);
      headers['Content-Type'] = 'application/json';

      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(fullUrl, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(fullUrl, headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(fullUrl, headers: headers, body: body);
          break;
        default:
          throw Exception('Неподдерживаемый HTTP метод для отправки: $method');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки данных: $e');
      }
      rethrow;
    }
  }

  /// Синхронизация SFTP данных
  Future<void> _syncSftpData(ExternalIntegration integration) async {
    // TODO: Реализовать SFTP синхронизацию
    if (kDebugMode) {
      print('SFTP sync not implemented yet');
    }
  }

  /// Синхронизация Email данных
  Future<void> _syncEmailData(ExternalIntegration integration) async {
    // TODO: Реализовать Email синхронизацию
    if (kDebugMode) {
      print('Email sync not implemented yet');
    }
  }

  /// Синхронизация SMS данных
  Future<void> _syncSmsData(ExternalIntegration integration) async {
    // TODO: Реализовать SMS синхронизацию
    if (kDebugMode) {
      print('SMS sync not implemented yet');
    }
  }

  /// Синхронизация платежных данных
  Future<void> _syncPaymentData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию платежей
    if (kDebugMode) {
      print('Payment sync not implemented yet');
    }
  }

  /// Синхронизация календарных данных
  Future<void> _syncCalendarData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию календаря
    if (kDebugMode) {
      print('Calendar sync not implemented yet');
    }
  }

  /// Синхронизация социальных данных
  Future<void> _syncSocialData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию социальных сетей
    if (kDebugMode) {
      print('Social sync not implemented yet');
    }
  }

  /// Синхронизация аналитических данных
  Future<void> _syncAnalyticsData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию аналитики
    if (kDebugMode) {
      print('Analytics sync not implemented yet');
    }
  }

  /// Синхронизация CRM данных
  Future<void> _syncCrmData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию CRM
    if (kDebugMode) {
      print('CRM sync not implemented yet');
    }
  }

  /// Синхронизация ERP данных
  Future<void> _syncErpData(ExternalIntegration integration) async {
    // TODO: Реализовать синхронизацию ERP
    if (kDebugMode) {
      print('ERP sync not implemented yet');
    }
  }

  /// Синхронизация других данных
  Future<void> _syncOtherData(ExternalIntegration integration) async {
    // TODO: Реализовать пользовательскую синхронизацию
    if (kDebugMode) {
      print('Other sync not implemented yet');
    }
  }

  /// Загрузить интеграции
  Future<void> _loadIntegrations() async {
    try {
      final snapshot =
          await _firestore.collection('externalIntegrations').get();

      for (final doc in snapshot.docs) {
        final integration = ExternalIntegration.fromDocument(doc);
        _integrations[integration.id] = integration;
      }

      if (kDebugMode) {
        print('Loaded ${_integrations.length} integrations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки интеграций: $e');
      }
    }
  }

  /// Запустить активные интеграции
  Future<void> _startActiveIntegrations() async {
    try {
      for (final integration in _integrations.values) {
        if (integration.isActive) {
          await _startIntegrationSync(integration.id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запуска активных интеграций: $e');
      }
    }
  }

  /// Получить интеграции
  List<ExternalIntegration> getIntegrations() {
    return _integrations.values.toList();
  }

  /// Получить интеграцию по ID
  ExternalIntegration? getIntegration(String integrationId) {
    return _integrations[integrationId];
  }

  /// Получить активные интеграции
  List<ExternalIntegration> getActiveIntegrations() {
    return _integrations.values
        .where((integration) => integration.isActive)
        .toList();
  }

  /// Получить интеграции по типу
  List<ExternalIntegration> getIntegrationsByType(IntegrationType type) {
    return _integrations.values
        .where((integration) => integration.type == type)
        .toList();
  }

  /// Обновить интеграцию
  Future<void> updateIntegration(
      String integrationId, ExternalIntegration updatedIntegration) async {
    try {
      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .update({
        ...updatedIntegration.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _integrations[integrationId] = updatedIntegration;

      if (kDebugMode) {
        print('Integration updated: ${updatedIntegration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления интеграции: $e');
      }
      rethrow;
    }
  }

  /// Удалить интеграцию
  Future<void> deleteIntegration(String integrationId) async {
    try {
      final integration = _integrations[integrationId];
      if (integration == null) return;

      // Останавливаем синхронизацию
      _stopIntegrationSync(integrationId);

      // Удаляем из Firestore
      await _firestore
          .collection('externalIntegrations')
          .doc(integrationId)
          .delete();

      // Удаляем из локального кэша
      _integrations.remove(integrationId);

      if (kDebugMode) {
        print('Integration deleted: ${integration.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления интеграции: $e');
      }
      rethrow;
    }
  }

  /// Выполнить ручную синхронизацию
  Future<void> performManualSync(String integrationId) async {
    try {
      await _performSync(integrationId);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка ручной синхронизации: $e');
      }
      rethrow;
    }
  }

  /// Получить статистику синхронизации
  Future<List<DataSync>> getSyncHistory(String integrationId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('dataSyncs')
          .where('integrationId', isEqualTo: integrationId)
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => DataSync.fromDocument(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения истории синхронизации: $e');
      }
      return [];
    }
  }

  /// Закрыть сервис
  void dispose() {
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    _integrations.clear();
  }
}
