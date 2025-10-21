import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder.dart';
import '../services/anniversary_service.dart';
import '../services/reminder_service.dart';

class TestRemindersScreen extends ConsumerStatefulWidget {
  const TestRemindersScreen({super.key});

  @override
  ConsumerState<TestRemindersScreen> createState() => _TestRemindersScreenState();
}

class _TestRemindersScreenState extends ConsumerState<TestRemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  final AnniversaryService _anniversaryService = AnniversaryService();

  List<Reminder> _reminders = [];
  List<Anniversary> _anniversaries = [];
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка данных...';
    });

    try {
      const testUserId = 'test_user_123';

      // Загружаем напоминания
      final reminders = await _reminderService.getUserReminders(testUserId);

      // Загружаем годовщины
      final anniversaries = await _anniversaryService.getUserAnniversaries(testUserId);

      setState(() {
        _reminders = reminders;
        _anniversaries = anniversaries;
        _isLoading = false;
        _statusMessage =
            'Загружено напоминаний: ${reminders.length}, годовщин: ${anniversaries.length}';
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка загрузки: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест напоминаний'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Обновить'),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  'Тестирование системы напоминаний',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_statusMessage, style: theme.textTheme.bodySmall),
              ],
            ),
          ),

          // Кнопки управления
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestEventReminder,
                  icon: const Icon(Icons.event),
                  label: const Text('Создать напоминание о событии'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestAnniversary,
                  icon: const Icon(Icons.cake),
                  label: const Text('Создать годовщину'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestCustomReminder,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Создать пользовательское напоминание'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _processPendingReminders,
                  icon: const Icon(Icons.send),
                  label: const Text('Обработать ожидающие'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearAllData,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Очистить все'),
                ),
              ],
            ),
          ),

          // Контент
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Загрузка...')],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Напоминания', icon: Icon(Icons.alarm)),
              Tab(text: 'Годовщины', icon: Icon(Icons.cake)),
            ],
          ),
          Expanded(child: TabBarView(children: [_buildRemindersTab(), _buildAnniversariesTab()])),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет напоминаний', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Создайте тестовые напоминания для проверки функционала',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildAnniversariesTab() {
    if (_anniversaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cake_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет годовщин', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Создайте тестовые годовщины для проверки функционала',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anniversaries.length,
      itemBuilder: (context, index) {
        final anniversary = _anniversaries[index];
        return _buildAnniversaryCard(anniversary);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(reminder.typeIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        reminder.typeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(reminder.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(reminder.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(reminder.scheduledTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (reminder.isActive) ...[
                  TextButton(
                    onPressed: () => _sendReminder(reminder),
                    child: const Text('Отправить'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _cancelReminder(reminder.id),
                    child: const Text('Отменить'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnniversaryCard(Anniversary anniversary) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _anniversaryService.getAnniversaryTypeIcon(anniversary.type),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anniversary.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _anniversaryService.getAnniversaryTypeName(anniversary.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(anniversary.isRecurring ? 'Повторяющаяся' : 'Одноразовая'),
                  backgroundColor: anniversary.isRecurring ? Colors.green[100] : Colors.blue[100],
                ),
              ],
            ),
            if (anniversary.description != null) ...[
              const SizedBox(height: 12),
              Text(anniversary.description!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(anniversary.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _deleteAnniversary(anniversary.id),
                  child: const Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    Color backgroundColor;
    String label;

    switch (status) {
      case ReminderStatus.scheduled:
        backgroundColor = Colors.blue[100]!;
        label = 'Запланировано';
        break;
      case ReminderStatus.sent:
        backgroundColor = Colors.green[100]!;
        label = 'Отправлено';
        break;
      case ReminderStatus.cancelled:
        backgroundColor = Colors.grey[100]!;
        label = 'Отменено';
        break;
      case ReminderStatus.failed:
        backgroundColor = Colors.red[100]!;
        label = 'Ошибка';
        break;
    }

    return Chip(label: Text(label), backgroundColor: backgroundColor);
  }

  // Методы для создания тестовых данных

  Future<void> _createTestEventReminder() async {
    try {
      setState(() => _isLoading = true);

      await _reminderService.createEventReminder(
        userId: 'test_user_123',
        eventTitle: 'Тестовое событие',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        eventId: 'test_event_123',
        bookingId: 'test_booking_123',
      );

      await _loadData();
      _showSuccessSnackBar('Напоминание о событии создано');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка создания напоминания: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestAnniversary() async {
    try {
      setState(() => _isLoading = true);

      await _anniversaryService.addAnniversary(
        userId: 'test_user_123',
        title: 'День рождения',
        date: DateTime.now().add(const Duration(days: 5)),
        type: AnniversaryType.birthday,
        description: 'День рождения любимого человека',
      );

      await _loadData();
      _showSuccessSnackBar('Годовщина создана');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка создания годовщины: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestCustomReminder() async {
    try {
      setState(() => _isLoading = true);

      await _reminderService.createCustomReminder(
        userId: 'test_user_123',
        title: 'Пользовательское напоминание',
        message: 'Не забыть сделать важное дело',
        scheduledTime: DateTime.now().add(const Duration(minutes: 5)),
      );

      await _loadData();
      _showSuccessSnackBar('Пользовательское напоминание создано');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка создания напоминания: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPendingReminders() async {
    try {
      setState(() => _isLoading = true);

      await _reminderService.processPendingReminders();

      await _loadData();
      _showSuccessSnackBar('Ожидающие напоминания обработаны');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка обработки напоминаний: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReminder(Reminder reminder) async {
    try {
      await _reminderService.sendReminder(reminder);
      await _loadData();
      _showSuccessSnackBar('Напоминание отправлено');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка отправки напоминания: $e');
    }
  }

  Future<void> _cancelReminder(String reminderId) async {
    try {
      await _reminderService.cancelReminder(reminderId);
      await _loadData();
      _showSuccessSnackBar('Напоминание отменено');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка отмены напоминания: $e');
    }
  }

  Future<void> _deleteAnniversary(String anniversaryId) async {
    try {
      await _anniversaryService.deleteAnniversary(anniversaryId);
      await _loadData();
      _showSuccessSnackBar('Годовщина удалена');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка удаления годовщины: $e');
    }
  }

  Future<void> _clearAllData() async {
    try {
      setState(() => _isLoading = true);

      // Удаляем все напоминания
      for (final reminder in _reminders) {
        await _reminderService.deleteReminder(reminder.id);
      }

      // Удаляем все годовщины
      for (final anniversary in _anniversaries) {
        await _anniversaryService.deleteAnniversary(anniversary.id);
      }

      await _loadData();
      _showSuccessSnackBar('Все данные очищены');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка очистки данных: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
}
