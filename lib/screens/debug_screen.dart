import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logger_service.dart';
import '../services/monitoring_service.dart';
import 'integration_test_screen.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MonitoringService _monitoring = MonitoringService();
  final LoggerService _logger = LoggerService();

  LogLevel _selectedLogLevel = LogLevel.info;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _isMonitoring = _monitoring._isMonitoring;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Отладка и мониторинг'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.analytics), text: 'Мониторинг'),
              Tab(icon: Icon(Icons.bug_report), text: 'Логи'),
              Tab(icon: Icon(Icons.settings), text: 'Настройки'),
              Tab(icon: Icon(Icons.info), text: 'Информация'),
              Tab(icon: Icon(Icons.integration_instructions), text: 'Тесты'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
              onPressed: _toggleMonitoring,
              tooltip: _isMonitoring
                  ? 'Остановить мониторинг'
                  : 'Запустить мониторинг',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Обновить данные',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMonitoringTab(),
            _buildLogsTab(),
            _buildSettingsTab(),
            _buildInfoTab(),
            _buildTestsTab(),
          ],
        ),
      );

  Widget _buildMonitoringTab() => RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonitoringStatus(),
              const SizedBox(height: 16),
              _buildPerformanceStats(),
              const SizedBox(height: 16),
              _buildErrorStats(),
              const SizedBox(height: 16),
              _buildMemoryStats(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildMonitoringStatus() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isMonitoring ? Icons.monitor : Icons.monitor_outlined,
                    color: _isMonitoring ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Статус мониторинга',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isMonitoring ? 'Мониторинг активен' : 'Мониторинг остановлен',
                style: TextStyle(
                  color: _isMonitoring ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPerformanceStats() {
    final stats = _monitoring.getPerformanceStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика производительности',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Нет данных о производительности');
                }
                final data = snapshot.data!;
                return Column(
                  children: data.entries
                      .map(
                        (entry) => _buildStatItem(
                          entry.key,
                          '${entry.value['count']} операций',
                          'Среднее время: ${entry.value['averageTime']?.toStringAsFixed(1)}ms',
                          Icons.speed,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStats() {
    final stats = _monitoring.getErrorStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика ошибок',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return const Text('Нет данных об ошибках');
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildStatItem(
                      'Всего ошибок',
                      '${data['totalErrors'] ?? 0}',
                      'За последние 5 минут: ${data['recentErrors'] ?? 0}',
                      Icons.error,
                      color: Colors.red,
                    ),
                    if (data['errorTypes'] != null)
                      ...(data['errorTypes'] as Map<String, int>).entries.map(
                            (entry) => _buildStatItem(
                              entry.key,
                              '${entry.value}',
                              '',
                              Icons.warning,
                              color: Colors.orange,
                            ),
                          ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryStats() {
    final stats = _monitoring.getMemoryStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика памяти',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Нет данных о памяти');
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildStatItem(
                      'Текущее использование',
                      '${(data['current'] / 1024 / 1024).toStringAsFixed(1)}MB',
                      '',
                      Icons.memory,
                    ),
                    _buildStatItem(
                      'Максимальное использование',
                      '${(data['max'] / 1024 / 1024).toStringAsFixed(1)}MB',
                      '',
                      Icons.trending_up,
                    ),
                    _buildStatItem(
                      'Среднее использование',
                      '${(data['average'] / 1024 / 1024).toStringAsFixed(1)}MB',
                      'Образцов: ${data['samples']}',
                      Icons.trending_flat,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    IconData icon, {
    Color? color,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color ?? Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Действия',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearMetrics,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Очистить метрики'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportMetrics,
                    icon: const Icon(Icons.download),
                    label: const Text('Экспорт метрик'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _testPerformance,
                    icon: const Icon(Icons.speed),
                    label: const Text('Тест производительности'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _testError,
                    icon: const Icon(Icons.error),
                    label: const Text('Тест ошибки'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildLogsTab() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Уровень логирования:'),
                const SizedBox(width: 16),
                DropdownButton<LogLevel>(
                  value: _selectedLogLevel,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLogLevel = newValue;
                      });
                      _logger.setMinLevel(newValue);
                    }
                  },
                  items: LogLevel.values
                      .map<DropdownMenuItem<LogLevel>>(
                        (level) => DropdownMenuItem<LogLevel>(
                          value: level,
                          child: Text(level.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildLogTestButton('Debug', LogLevel.debug, Icons.bug_report),
                _buildLogTestButton('Info', LogLevel.info, Icons.info),
                _buildLogTestButton('Warning', LogLevel.warning, Icons.warning),
                _buildLogTestButton('Error', LogLevel.error, Icons.error),
                _buildLogTestButton('Fatal', LogLevel.fatal, Icons.dangerous),
              ],
            ),
          ),
        ],
      );

  Widget _buildLogTestButton(String label, LogLevel level, IconData icon) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text('Тест ${level.name} сообщения'),
          onTap: () => _testLog(level),
        ),
      );

  Widget _buildSettingsTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Настройки мониторинга',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Автоматический мониторинг'),
                      subtitle: const Text(
                        'Запускать мониторинг при старте приложения',
                      ),
                      value: _isMonitoring,
                      onChanged: (value) => _toggleMonitoring(),
                    ),
                    SwitchListTile(
                      title: const Text('Мониторинг памяти'),
                      subtitle: const Text('Отслеживать использование памяти'),
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement memory monitoring toggle
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Мониторинг производительности'),
                      subtitle:
                          const Text('Отслеживать время выполнения операций'),
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement performance monitoring toggle
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Настройки логирования',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Уровень логирования'),
                      subtitle: Text(_selectedLogLevel.name.toUpperCase()),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Show log level selection dialog
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Логирование в консоль'),
                      subtitle:
                          const Text('Выводить логи в консоль разработчика'),
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement console logging toggle
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о приложении',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem('Версия', '1.0.0'),
                    _buildInfoItem('Сборка', '1'),
                    _buildInfoItem('Платформа', 'Flutter'),
                    _buildInfoItem('Режим отладки', kDebugMode ? 'Да' : 'Нет'),
                    _buildInfoItem(
                      'Профиль',
                      kProfileMode ? 'Профилирование' : 'Релиз',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о мониторинге',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      'Статус',
                      _isMonitoring ? 'Активен' : 'Остановлен',
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _monitoring.getPerformanceMetrics(),
                      builder: (context, snapshot) {
                        return _buildInfoItem(
                          'Метрики производительности',
                          snapshot.hasData ? '${snapshot.data!.length}' : '0',
                        );
                      },
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _monitoring.getErrorMetrics(),
                      builder: (context, snapshot) {
                        return _buildInfoItem(
                          'Метрики ошибок',
                          snapshot.hasData ? '${snapshot.data!.length}' : '0',
                        );
                      },
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _monitoring.getMemoryMetrics(),
                      builder: (context, snapshot) {
                        return _buildInfoItem(
                          'Метрики памяти',
                          snapshot.hasData ? '${snapshot.data!.length}' : '0',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoItem(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      _monitoring.startMonitoring();
    } else {
      _monitoring.stopMonitoring();
    }
  }

  void _refreshData() {
    setState(() {});
  }

  void _clearMetrics() {
    _monitoring.clearMetrics();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Метрики очищены')),
    );
    setState(() {});
  }

  void _exportMetrics() {
    final metrics = _monitoring.exportMetrics();
    final jsonString = metrics.toString();

    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Метрики скопированы в буфер обмена')),
    );
  }

  void _testPerformance() {
    _monitoring.startOperation('test_operation');

    // Симулируем работу
    Future.delayed(const Duration(milliseconds: 500), () {
      _monitoring.endOperation(
        'test_operation',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тест производительности выполнен')),
      );
      setState(() {});
    });
  }

  void _testError() {
    try {
      throw Exception('Тестовая ошибка для мониторинга');
    } catch (e, stack) {
      _monitoring._recordError('Test Error', e, stack);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тестовая ошибка записана')),
      );
      setState(() {});
    }
  }

  void _testLog(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        _logger.debug('Тестовое debug сообщение', tag: 'TEST');
        break;
      case LogLevel.info:
        _logger.info('Тестовое info сообщение', tag: 'TEST');
        break;
      case LogLevel.warning:
        _logger.warning('Тестовое warning сообщение', tag: 'TEST');
        break;
      case LogLevel.error:
        _logger.error('Тестовое error сообщение', tag: 'TEST');
        break;
      case LogLevel.fatal:
        _logger.fatal('Тестовое fatal сообщение', tag: 'TEST');
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${level.name} сообщение отправлено')),
    );
  }

  Widget _buildTestsTab() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тестирование интеграции',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Запустите тесты для проверки интеграции всех компонентов:',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const IntegrationTestScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Запустить тесты интеграции'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
