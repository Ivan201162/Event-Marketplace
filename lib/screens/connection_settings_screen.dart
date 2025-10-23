import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/integration_providers.dart';
import '../services/integration_service.dart';

/// Экран настроек подключения
class ConnectionSettingsScreen extends ConsumerStatefulWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  ConsumerState<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState
    extends ConsumerState<ConnectionSettingsScreen> {
  final IntegrationService _integrationService = IntegrationService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Настройки подключения'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshConnectionStatus)
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статус подключения
              _buildConnectionStatus(),

              const SizedBox(height: 24),

              // Тип подключения
              _buildConnectionType(),

              const SizedBox(height: 24),

              // Настройки синхронизации
              _buildSyncSettings(),

              const SizedBox(height: 24),

              // Диагностика
              _buildDiagnostics(),
            ],
          ),
        ),
      );

  Widget _buildConnectionStatus() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Статус подключения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final connectivityAsync =
                      ref.watch(connectivityStatusProvider);

                  return connectivityAsync.when(
                    data: (isConnected) => Row(
                      children: [
                        Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          size: 32,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected
                                    ? 'Подключено к интернету'
                                    : 'Нет подключения к интернету',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isConnected ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isConnected
                                    ? 'Все функции доступны'
                                    : 'Некоторые функции недоступны',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Row(
                      children: [
                        const Icon(Icons.error, size: 32, color: Colors.red),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ошибка проверки подключения',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ошибка: $error',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
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

  Widget _buildConnectionType() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Тип подключения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final connectionTypeAsync = ref.watch(connectionTypeProvider);

                  return connectionTypeAsync.when(
                    data: _buildConnectionTypeInfo,
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Ошибка: $error',
                        style: const TextStyle(color: Colors.red)),
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildConnectionTypeInfo(ConnectivityResult connectionType) {
    var icon = Icons.help;
    var title = 'Неизвестно';
    var description = 'Неизвестный тип подключения';
    Color color = Colors.grey;

    switch (connectionType) {
      case ConnectivityResult.wifi:
        icon = Icons.wifi;
        title = 'Wi-Fi';
        description = 'Быстрое подключение через Wi-Fi';
        color = Colors.green;
        break;
      case ConnectivityResult.mobile:
        icon = Icons.signal_cellular_4_bar;
        title = 'Мобильный интернет';
        description = 'Подключение через мобильную сеть';
        color = Colors.blue;
        break;
      case ConnectivityResult.ethernet:
        icon = Icons.cable;
        title = 'Ethernet';
        description = 'Проводное подключение';
        color = Colors.orange;
        break;
      case ConnectivityResult.bluetooth:
        icon = Icons.bluetooth;
        title = 'Bluetooth';
        description = 'Подключение через Bluetooth';
        color = Colors.purple;
        break;
      case ConnectivityResult.vpn:
        icon = Icons.vpn_lock;
        title = 'VPN';
        description = 'Подключение через VPN';
        color = Colors.indigo;
        break;
      case ConnectivityResult.other:
        icon = Icons.network_check;
        title = 'Другое';
        description = 'Неизвестный тип подключения';
        color = Colors.grey;
        break;
      case ConnectivityResult.none:
        icon = Icons.wifi_off;
        title = 'Нет подключения';
        description = 'Устройство не подключено к интернету';
        color = Colors.red;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: color),
              ),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Настройки синхронизации',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Автоматическая синхронизация
              SwitchListTile(
                title: const Text('Автоматическая синхронизация'),
                subtitle: const Text(
                    'Автоматически синхронизировать данные при подключении к Wi-Fi'),
                value: true, // TODO(developer): Получить из настроек
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Настройка сохранена')));
                },
              ),

              const Divider(),

              // Синхронизация только по Wi-Fi
              SwitchListTile(
                title: const Text('Синхронизация только по Wi-Fi'),
                subtitle: const Text(
                    'Синхронизировать данные только при подключении к Wi-Fi'),
                value: false, // TODO(developer): Получить из настроек
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Настройка сохранена')));
                },
              ),

              const Divider(),

              // Синхронизация в фоне
              SwitchListTile(
                title: const Text('Синхронизация в фоне'),
                subtitle: const Text(
                    'Разрешить синхронизацию данных в фоновом режиме'),
                value: true, // TODO(developer): Получить из настроек
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Настройка сохранена')));
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildDiagnostics() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Диагностика подключения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Проверить подключение
              ListTile(
                leading: const Icon(Icons.network_check, color: Colors.blue),
                title: const Text('Проверить подключение'),
                subtitle: const Text('Проверить доступность интернета'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _checkConnection,
              ),

              const Divider(),

              // Тест скорости
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.green),
                title: const Text('Тест скорости'),
                subtitle: const Text('Измерить скорость интернет-соединения'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _testSpeed,
              ),

              const Divider(),

              // Сброс сетевых настроек
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Сброс сетевых настроек'),
                subtitle:
                    const Text('Сбросить настройки сети и переподключиться'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _resetNetworkSettings,
              ),

              const Divider(),

              // Логи подключения
              ListTile(
                leading: const Icon(Icons.history, color: Colors.purple),
                title: const Text('Логи подключения'),
                subtitle: const Text('Просмотреть историю подключений'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showConnectionLogs,
              ),
            ],
          ),
        ),
      );

  void _refreshConnectionStatus() {
    // Обновляем провайдеры
    ref.invalidate(connectivityStatusProvider);
    ref.invalidate(connectionTypeProvider);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Статус подключения обновлен')));
  }

  void _checkConnection() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Проверка подключения'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Проверяем подключение к интернету...'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'))
        ],
      ),
    );

    // Имитация проверки подключения
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подключение к интернету работает нормально'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _testSpeed() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тест скорости'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Измеряем скорость интернет-соединения...'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'))
        ],
      ),
    );

    // Имитация теста скорости
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Результаты теста скорости'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Скорость загрузки: 25.6 Мбит/с'),
              Text('Скорость отдачи: 8.2 Мбит/с'),
              Text('Задержка: 45 мс'),
              Text('Качество: Отлично'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть')),
          ],
        ),
      );
    });
  }

  void _resetNetworkSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс сетевых настроек'),
        content: const Text(
          'Вы уверены, что хотите сбросить сетевые настройки? Это может потребовать переподключения к Wi-Fi.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать сброс сетевых настроек
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Сетевые настройки сброшены'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _showConnectionLogs() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Логи подключения'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('14:30:25 - Подключение к Wi-Fi "HomeNetwork"'),
            Text('14:30:26 - IP адрес: 192.168.1.100'),
            Text('14:30:27 - DNS: 8.8.8.8'),
            Text('14:30:28 - Подключение установлено'),
            Text('14:35:12 - Синхронизация данных'),
            Text('14:35:15 - Синхронизация завершена'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }
}
